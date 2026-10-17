/* Scalar reference and helpers. Build WITHOUT the vector -march flag. */
#include "nv12conv.h"
#include <stdio.h>
#include <string.h>

const nv12conv_coef NV12CONV_BT601 = { 204, -50, -104, 258 };
const nv12conv_coef NV12CONV_BT709 = { 229, -27, -68, 270 };

static inline int clampi(int v, int lo, int hi) { return v < lo ? lo : (v > hi ? hi : v); }
static inline int sat16(int v) { return v > 32767 ? 32767 : (v < -32768 ? -32768 : v); }

static inline uint8_t chan(int yw, int chroma)
{
	int s = sat16(yw + chroma);
	if (s < 0)
		s = 0;
	s = (s + 64) >> 7;
	return s > 255 ? 255 : (uint8_t)s;
}

void nv12_to_bgrx_ref(const uint8_t *y, int ystride, const uint8_t *uv, int uvstride,
		      uint8_t *dst, int dstride, int w, int h, const nv12conv_coef *c)
{
	for (int j = 0; j < h; j++) {
		const uint8_t *yr = y + (long)j * ystride;
		const uint8_t *cr = uv + (long)(j >> 1) * uvstride;
		uint8_t *d = dst + (long)j * dstride;
		for (int i = 0; i < w; i++) {
			int yq = clampi(yr[i] - 16, 0, 219);
			int yw = yq * 149;
			int ud = clampi(cr[(i >> 1) * 2], 16, 240) - 128;
			int vd = clampi(cr[(i >> 1) * 2 + 1], 16, 240) - 128;
			int rr = vd * c->rv;
			int gg = vd * c->gv + ud * c->gu;
			int bb = ud * c->bu;
			d[4 * i + 0] = chan(yw, bb);
			d[4 * i + 1] = chan(yw, gg);
			d[4 * i + 2] = chan(yw, rr);
			d[4 * i + 3] = 0xff;
		}
	}
}

static inline int add_sat8(int v, int a) { return v + a > 255 ? 255 : v + a; }

void nv12_to_rgb565_ref(const uint8_t *y, int ystride, const uint8_t *uv, int uvstride,
			uint8_t *dst, int dstride, int w, int h, const nv12conv_coef *c)
{
	for (int j = 0; j < h; j++) {
		const uint8_t *yr = y + (long)j * ystride;
		const uint8_t *cr = uv + (long)(j >> 1) * uvstride;
		uint16_t *d = (uint16_t *)(dst + (long)j * dstride);
		for (int i = 0; i < w; i++) {
			int yw = clampi(yr[i] - 16, 0, 219) * 149;
			int ud = clampi(cr[(i >> 1) * 2], 16, 240) - 128;
			int vd = clampi(cr[(i >> 1) * 2 + 1], 16, 240) - 128;
			int r = chan(yw, vd * c->rv);
			int g = chan(yw, vd * c->gv + ud * c->gu);
			int b = chan(yw, ud * c->bu);
			d[i] = (uint16_t)(((add_sat8(r, 4) >> 3) << 11) | ((add_sat8(g, 2) >> 2) << 5) | (add_sat8(b, 4) >> 3));
		}
	}
}

int nv12conv_vector_usable(void)
{
	char buf[128] = "";
	FILE *f = fopen("/sys/devices/system/cpu/vulnerabilities/ghostwrite", "r");
	if (!f)
		return 0;
	if (!fgets(buf, sizeof buf, f))
		buf[0] = 0;
	fclose(f);
	return strncmp(buf, "Vulnerable", 10) == 0;
}
