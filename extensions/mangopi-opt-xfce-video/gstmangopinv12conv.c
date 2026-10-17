/* GStreamer element "mangopinv12conv": NV12 to BGRx on the C906 vector unit.
 *
 * The stock videoconvert needs 355 ms for a 720p frame on this board. This element needs 8 ms.
 * Use it in front of ximagesink: ... v4l2slh264dec ! mangopinv12conv ! ximagesink
 * If the vector unit is off (no mitigations=off), the element uses the scalar reference code.
 * Limited range input only (the usual case for video). Full range input is converted as limited.
 */
#define PACKAGE "mangopi"
#include <gst/gst.h>
#include <gst/video/video.h>
#include <gst/video/gstvideofilter.h>
#include "nv12conv.h"

GST_DEBUG_CATEGORY_STATIC(mangopi_debug);
#define GST_CAT_DEFAULT mangopi_debug

#define GST_TYPE_MANGOPI_NV12CONV (gst_mangopi_nv12conv_get_type())
G_DECLARE_FINAL_TYPE(GstMangopiNv12Conv, gst_mangopi_nv12conv, GST, MANGOPI_NV12CONV, GstVideoFilter)

struct _GstMangopiNv12Conv {
	GstVideoFilter parent;
	gboolean use_vec;
	gboolean rgb565;	/* output is RGB16, else BGRx */
	const nv12conv_coef *coef;
};

G_DEFINE_TYPE(GstMangopiNv12Conv, gst_mangopi_nv12conv, GST_TYPE_VIDEO_FILTER)

static GstStaticPadTemplate sink_tmpl = GST_STATIC_PAD_TEMPLATE("sink", GST_PAD_SINK, GST_PAD_ALWAYS,
	GST_STATIC_CAPS("video/x-raw, format=(string)NV12, width=(int)[1,8192], height=(int)[1,8192], framerate=(fraction)[0/1,MAX]"));
static GstStaticPadTemplate src_tmpl = GST_STATIC_PAD_TEMPLATE("src", GST_PAD_SRC, GST_PAD_ALWAYS,
	GST_STATIC_CAPS("video/x-raw, format=(string){ BGRx, RGB16 }, width=(int)[1,8192], height=(int)[1,8192], framerate=(fraction)[0/1,MAX]"));

/* The default transform_caps keeps the format. This element changes NV12 to BGRx. */
static GstCaps *transform_caps(GstBaseTransform *bt, GstPadDirection dir, GstCaps *caps, GstCaps *filter)
{
	GstCaps *res = gst_caps_new_empty();

	for (guint i = 0; i < gst_caps_get_size(caps); i++) {
		GstStructure *st = gst_structure_copy(gst_caps_get_structure(caps, i));
		gst_structure_remove_fields(st, "colorimetry", "chroma-site", NULL);
		if (dir == GST_PAD_SINK) {
			/* NV12 in: offer both outputs. ximagesink picks the one that fits the screen depth. */
			GstStructure *st2 = gst_structure_copy(st);
			gst_structure_set(st, "format", G_TYPE_STRING, "BGRx", NULL);
			gst_structure_set(st2, "format", G_TYPE_STRING, "RGB16", NULL);
			gst_caps_append_structure(res, st);
			gst_caps_append_structure(res, st2);
		} else {
			gst_structure_set(st, "format", G_TYPE_STRING, "NV12", NULL);
			gst_caps_append_structure(res, st);
		}
	}
	if (filter) {
		GstCaps *tmp = gst_caps_intersect_full(filter, res, GST_CAPS_INTERSECT_FIRST);
		gst_caps_unref(res);
		res = tmp;
	}
	return res;
}

static gboolean set_info(GstVideoFilter *f, GstCaps *incaps, GstVideoInfo *in, GstCaps *outcaps, GstVideoInfo *out)
{
	GstMangopiNv12Conv *self = GST_MANGOPI_NV12CONV(f);
	GstVideoColorMatrix m = in->colorimetry.matrix;

	if (m == GST_VIDEO_COLOR_MATRIX_BT709)
		self->coef = &NV12CONV_BT709;
	else if (m == GST_VIDEO_COLOR_MATRIX_BT601 || m == GST_VIDEO_COLOR_MATRIX_SMPTE240M)
		self->coef = &NV12CONV_BT601;
	else  /* unknown: HD is BT.709, SD is BT.601 */
		self->coef = GST_VIDEO_INFO_HEIGHT(in) >= 720 ? &NV12CONV_BT709 : &NV12CONV_BT601;
	self->use_vec = nv12conv_vector_usable();
	self->rgb565 = GST_VIDEO_INFO_FORMAT(out) == GST_VIDEO_FORMAT_RGB16;
	GST_INFO_OBJECT(self, "%dx%d, %s, %s, %s code", GST_VIDEO_INFO_WIDTH(in), GST_VIDEO_INFO_HEIGHT(in),
			self->coef == &NV12CONV_BT709 ? "BT.709" : "BT.601", self->rgb565 ? "RGB16" : "BGRx", self->use_vec ? "vector" : "scalar");
	if (!self->use_vec)
		GST_WARNING_OBJECT(self, "vector unit is off (needs mitigations=off). Using the slow scalar code.");
	return TRUE;
}

static GstFlowReturn transform_frame(GstVideoFilter *f, GstVideoFrame *in, GstVideoFrame *out)
{
	GstMangopiNv12Conv *self = GST_MANGOPI_NV12CONV(f);
	int w = GST_VIDEO_FRAME_WIDTH(in), h = GST_VIDEO_FRAME_HEIGHT(in);
	const uint8_t *y = GST_VIDEO_FRAME_PLANE_DATA(in, 0), *uv = GST_VIDEO_FRAME_PLANE_DATA(in, 1);
	int ys = GST_VIDEO_FRAME_PLANE_STRIDE(in, 0), uvs = GST_VIDEO_FRAME_PLANE_STRIDE(in, 1);
	uint8_t *d = GST_VIDEO_FRAME_PLANE_DATA(out, 0);
	int ds = GST_VIDEO_FRAME_PLANE_STRIDE(out, 0);

	if (self->rgb565) {
		if (self->use_vec)
			nv12_to_rgb565_vec(y, ys, uv, uvs, d, ds, w, h, self->coef);
		else
			nv12_to_rgb565_ref(y, ys, uv, uvs, d, ds, w, h, self->coef);
	} else if (self->use_vec) {
		nv12_to_bgrx_vec(y, ys, uv, uvs, d, ds, w, h, self->coef);
	} else {
		nv12_to_bgrx_ref(y, ys, uv, uvs, d, ds, w, h, self->coef);
	}
	return GST_FLOW_OK;
}

static void gst_mangopi_nv12conv_class_init(GstMangopiNv12ConvClass *klass)
{
	GstElementClass *ec = GST_ELEMENT_CLASS(klass);
	GstVideoFilterClass *vc = GST_VIDEO_FILTER_CLASS(klass);

	gst_element_class_set_static_metadata(ec, "MangoPi NV12 to BGRx converter", "Filter/Converter/Video",
		"Convert NV12 to BGRx with the C906 vector unit", "khaliforce");
	gst_element_class_add_static_pad_template(ec, &sink_tmpl);
	gst_element_class_add_static_pad_template(ec, &src_tmpl);
	GST_BASE_TRANSFORM_CLASS(klass)->transform_caps = transform_caps;
	vc->set_info = set_info;
	vc->transform_frame = transform_frame;
}

static void gst_mangopi_nv12conv_init(GstMangopiNv12Conv *self) { }

static gboolean plugin_init(GstPlugin *p)
{
	GST_DEBUG_CATEGORY_INIT(mangopi_debug, "mangopinv12conv", 0, "MangoPi NV12 converter");
	return gst_element_register(p, "mangopinv12conv", GST_RANK_NONE, GST_TYPE_MANGOPI_NV12CONV);
}

GST_PLUGIN_DEFINE(GST_VERSION_MAJOR, GST_VERSION_MINOR, mangopinv12conv, "MangoPi vector NV12 converter",
	plugin_init, "1.0", "LGPL", "mangopi", "https://github.com/khaliforce/build")
