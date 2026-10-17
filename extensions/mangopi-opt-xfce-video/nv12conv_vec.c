/* Vector kernel. Build with -march=rv64gc_xtheadvector -mabi=lp64d -O2. Keep this file small:
 * everything in it may use vector instructions.
 *
 * Memory order matters on this core. The first version wrote two output rows and read three
 * input rows at the same time. It ran 2.5 times slower than its compute time, because the
 * memory system loses its sequential read-ahead with that many streams. This version writes
 * one output row per pass. The chroma terms are computed again for the odd row, which costs
 * about 20% more compute. Total: 7.9 ms for a 720p frame against 16.9 ms before.
 * Two other tries were slower: keeping the chroma terms in a buffer, and early line touches.
 * Compile with -O2 and not -fno-schedule-insns. gcc then does not emit vmv2r.v, which the
 * T-Head assembler rejects. */
#include "nv12conv.h"
#include <riscv_vector.h>

static const uint8_t DUP_IDX[16] = { 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7 };

static inline vuint8m1_t clip7(vint16m2_t s, size_t vl)
{
	s = __riscv_vmax_vx_i16m2(s, 0, vl);
	return __riscv_vnclipu_wx_u8m1(__riscv_vreinterpret_v_i16m2_u16m2(s), 7, __RISCV_VXRM_RNU, vl);
}

void nv12_to_bgrx_vec(const uint8_t *y, int ystride, const uint8_t *uv, int uvstride,
		      uint8_t *dst, int dstride, int w, int h, const nv12conv_coef *c)
{
	size_t vl16 = __riscv_vsetvl_e8m1(16);
	vuint8m1_t idx = __riscv_vle8_v_u8m1(DUP_IDX, vl16);
	vuint8m1_t xff = __riscv_vmv_v_x_u8m1(0xff, vl16);

	for (int j = 0; j < h; j++) {
		const uint8_t *yr = y + (long)j * ystride;
		const uint8_t *cp = uv + (long)(j >> 1) * uvstride;
		uint8_t *d = dst + (long)j * dstride;

		for (int x = 0; x < w; x += 16) {
			size_t vl = __riscv_vsetvl_e8m1(w - x > 16 ? 16 : w - x);
			size_t cvl = (vl + 1) >> 1;

			/* chroma: load U,V pairs, clamp, copy each value to two pixels */
			vuint8m1x2_t p = __riscv_vlseg2e8_v_u8m1x2(cp + x, cvl);
			vuint8m1_t u = __riscv_vminu_vx_u8m1(__riscv_vmaxu_vx_u8m1(__riscv_vget_v_u8m1x2_u8m1(p, 0), 16, cvl), 240, cvl);
			vuint8m1_t v = __riscv_vminu_vx_u8m1(__riscv_vmaxu_vx_u8m1(__riscv_vget_v_u8m1x2_u8m1(p, 1), 16, cvl), 240, cvl);
			vuint8m1_t ug = __riscv_vrgather_vv_u8m1(u, idx, vl);
			vuint8m1_t vg = __riscv_vrgather_vv_u8m1(v, idx, vl);
			vint16m2_t ud = __riscv_vreinterpret_v_u16m2_i16m2(__riscv_vwsubu_vx_u16m2(ug, 128, vl));
			vint16m2_t vd = __riscv_vreinterpret_v_u16m2_i16m2(__riscv_vwsubu_vx_u16m2(vg, 128, vl));

			/* luma */
			vuint8m1_t yq = __riscv_vminu_vx_u8m1(__riscv_vssubu_vx_u8m1(__riscv_vle8_v_u8m1(yr + x, vl), 16, vl), 219, vl);
			vint16m2_t yw = __riscv_vreinterpret_v_u16m2_i16m2(__riscv_vwmulu_vx_u16m2(yq, 149, vl));

			vint16m2_t cr = __riscv_vmul_vx_i16m2(vd, c->rv, vl);
			vint16m2_t cg = __riscv_vmacc_vx_i16m2(__riscv_vmul_vx_i16m2(vd, c->gv, vl), c->gu, ud, vl);
			vint16m2_t cb = __riscv_vmul_vx_i16m2(ud, c->bu, vl);
			vuint8m1_t r = clip7(__riscv_vsadd_vv_i16m2(yw, cr, vl), vl);
			vuint8m1_t g = clip7(__riscv_vsadd_vv_i16m2(yw, cg, vl), vl);
			vuint8m1_t b = clip7(__riscv_vsadd_vv_i16m2(yw, cb, vl), vl);
			__riscv_vsseg4e8_v_u8m1x4(d + 4 * x, __riscv_vcreate_v_u8m1x4(b, g, r, xff), vl);
		}
	}
}

/* RGB565: same math as above, then each channel is rounded and packed into 16 bits. */
void nv12_to_rgb565_vec(const uint8_t *y, int ystride, const uint8_t *uv, int uvstride,
			uint8_t *dst, int dstride, int w, int h, const nv12conv_coef *c)
{
	size_t vl16 = __riscv_vsetvl_e8m1(16);
	vuint8m1_t idx = __riscv_vle8_v_u8m1(DUP_IDX, vl16);

	for (int j = 0; j < h; j++) {
		const uint8_t *yr = y + (long)j * ystride;
		const uint8_t *cp = uv + (long)(j >> 1) * uvstride;
		uint16_t *d = (uint16_t *)(dst + (long)j * dstride);

		for (int x = 0; x < w; x += 16) {
			size_t vl = __riscv_vsetvl_e8m1(w - x > 16 ? 16 : w - x);
			size_t cvl = (vl + 1) >> 1;

			vuint8m1x2_t p = __riscv_vlseg2e8_v_u8m1x2(cp + x, cvl);
			vuint8m1_t u = __riscv_vminu_vx_u8m1(__riscv_vmaxu_vx_u8m1(__riscv_vget_v_u8m1x2_u8m1(p, 0), 16, cvl), 240, cvl);
			vuint8m1_t v = __riscv_vminu_vx_u8m1(__riscv_vmaxu_vx_u8m1(__riscv_vget_v_u8m1x2_u8m1(p, 1), 16, cvl), 240, cvl);
			vuint8m1_t ug = __riscv_vrgather_vv_u8m1(u, idx, vl);
			vuint8m1_t vg = __riscv_vrgather_vv_u8m1(v, idx, vl);
			vint16m2_t ud = __riscv_vreinterpret_v_u16m2_i16m2(__riscv_vwsubu_vx_u16m2(ug, 128, vl));
			vint16m2_t vd = __riscv_vreinterpret_v_u16m2_i16m2(__riscv_vwsubu_vx_u16m2(vg, 128, vl));

			vuint8m1_t yq = __riscv_vminu_vx_u8m1(__riscv_vssubu_vx_u8m1(__riscv_vle8_v_u8m1(yr + x, vl), 16, vl), 219, vl);
			vint16m2_t yw = __riscv_vreinterpret_v_u16m2_i16m2(__riscv_vwmulu_vx_u16m2(yq, 149, vl));

			vint16m2_t cr = __riscv_vmul_vx_i16m2(vd, c->rv, vl);
			vint16m2_t cg = __riscv_vmacc_vx_i16m2(__riscv_vmul_vx_i16m2(vd, c->gv, vl), c->gu, ud, vl);
			vint16m2_t cb = __riscv_vmul_vx_i16m2(ud, c->bu, vl);
			vuint8m1_t r = clip7(__riscv_vsadd_vv_i16m2(yw, cr, vl), vl);
			vuint8m1_t g = clip7(__riscv_vsadd_vv_i16m2(yw, cg, vl), vl);
			vuint8m1_t b = clip7(__riscv_vsadd_vv_i16m2(yw, cb, vl), vl);

			/* Round to nearest and keep the top bits of each channel. A pixel is the 16 bit word
			 * RRRRRGGG GGGBBBBB. Build its high byte and low byte with 8 bit operations and store
			 * the two bytes interleaved. This avoids 16 bit vector operations and the vl problem
			 * of vsetvli zero,zero (VLMAX on the C906, "keep vl" in RVV 1.0). */
			vuint8m1_t r8 = __riscv_vand_vx_u8m1(__riscv_vsaddu_vx_u8m1(r, 4, vl), 0xf8, vl);	/* rrrrr000 */
			vuint8m1_t g8 = __riscv_vand_vx_u8m1(__riscv_vsaddu_vx_u8m1(g, 2, vl), 0xfc, vl);	/* gggggg00 */
			vuint8m1_t b8 = __riscv_vand_vx_u8m1(__riscv_vsaddu_vx_u8m1(b, 4, vl), 0xf8, vl);	/* bbbbb000 */
			vuint8m1_t hi = __riscv_vor_vv_u8m1(r8, __riscv_vsrl_vx_u8m1(g8, 5, vl), vl);		/* rrrrrggg */
			vuint8m1_t lo = __riscv_vor_vv_u8m1(__riscv_vsll_vx_u8m1(g8, 3, vl), __riscv_vsrl_vx_u8m1(b8, 3, vl), vl);	/* gggbbbbb */
			__riscv_vsseg2e8_v_u8m1x2((uint8_t *)(d + x), __riscv_vcreate_v_u8m1x2(lo, hi), vl);
		}
	}
}
