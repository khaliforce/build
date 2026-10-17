/* NV12 to BGRx converter for the T-Head C906 vector unit (XTheadVector, RVV 0.7.1).
 *
 * Fixed point, 7 fractional bits, 16-bit lanes. Limited range input (Y 16..235, UV 16..240).
 * The vector and the reference function give identical bytes.
 */
#ifndef NV12CONV_H
#define NV12CONV_H
#include <stdint.h>

typedef struct {
	int16_t rv;   /* R from V */
	int16_t gu;   /* G from U (negative) */
	int16_t gv;   /* G from V (negative) */
	int16_t bu;   /* B from U */
} nv12conv_coef;

extern const nv12conv_coef NV12CONV_BT601;
extern const nv12conv_coef NV12CONV_BT709;

/* Plane layout: y has h rows of w bytes. uv has (h+1)/2 rows of 2*((w+1)/2) bytes (U,V pairs).
 * dst has h rows of 4*w bytes in B,G,R,X order. Strides are in bytes. */
void nv12_to_bgrx_ref(const uint8_t *y, int ystride, const uint8_t *uv, int uvstride,
		      uint8_t *dst, int dstride, int w, int h, const nv12conv_coef *c);

/* Needs the vector unit. Check nv12conv_vector_usable() first. Compiled in nv12conv_vec.c. */
void nv12_to_bgrx_vec(const uint8_t *y, int ystride, const uint8_t *uv, int uvstride,
		      uint8_t *dst, int dstride, int w, int h, const nv12conv_coef *c);

/* Same conversion to RGB565 (16 bit, R in the high bits). The dst row is 2*w bytes. Each channel is
 * rounded to nearest: r5 = min(255, r + 4) >> 3, g6 = min(255, g + 2) >> 2, b5 = min(255, b + 4) >> 3. */
void nv12_to_rgb565_ref(const uint8_t *y, int ystride, const uint8_t *uv, int uvstride,
			uint8_t *dst, int dstride, int w, int h, const nv12conv_coef *c);
void nv12_to_rgb565_vec(const uint8_t *y, int ystride, const uint8_t *uv, int uvstride,
			uint8_t *dst, int dstride, int w, int h, const nv12conv_coef *c);

/* 1 if the kernel allows user space to run vector code (mitigations=off), else 0. */
int nv12conv_vector_usable(void);

#endif
