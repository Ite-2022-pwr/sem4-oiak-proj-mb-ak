#include "polyvec.h"
#include "reduce.h"

#if (KYBER_POLYVECCOMPRESSEDBYTES == (KYBER_K * 352))

/*************************************************
* Name:        polyvec_compress
* 
* Description: Compress and serialize vector of polynomials
*
* Arguments:   - unsigned char *r: pointer to output byte array 
*              - const polyvec *a: pointer to input vector of polynomials
**************************************************/
void polyvec_compress(unsigned char *r, const polyvec *a)
{
  int i,j,k;
  uint16_t t[8];
  for(i=0;i<KYBER_K;i++)
  {
    for(j=0;j<KYBER_N/8;j++)
    {
      for(k=0;k<8;k++)
        t[k] = ((((uint32_t)freeze(a->vec[i].coeffs[8*j+k]) << 11) + KYBER_Q/2)/ KYBER_Q) & 0x7ff;

      r[11*j+ 0] =  t[0] & 0xff;
      r[11*j+ 1] = (t[0] >>  8) | ((t[1] & 0x1f) << 3);
      r[11*j+ 2] = (t[1] >>  5) | ((t[2] & 0x03) << 6);
      r[11*j+ 3] = (t[2] >>  2) & 0xff;
      r[11*j+ 4] = (t[2] >> 10) | ((t[3] & 0x7f) << 1);
      r[11*j+ 5] = (t[3] >>  7) | ((t[4] & 0x0f) << 4);
      r[11*j+ 6] = (t[4] >>  4) | ((t[5] & 0x01) << 7);
      r[11*j+ 7] = (t[5] >>  1) & 0xff;
      r[11*j+ 8] = (t[5] >>  9) | ((t[6] & 0x3f) << 2);
      r[11*j+ 9] = (t[6] >>  6) | ((t[7] & 0x07) << 5);
      r[11*j+10] = (t[7] >>  3);
    }
    r += 352;
  }
}

/*************************************************
* Name:        polyvec_decompress
* 
* Description: De-serialize and decompress vector of polynomials;
*              approximate inverse of polyvec_compress
*
* Arguments:   - polyvec *r:       pointer to output vector of polynomials
*              - unsigned char *a: pointer to input byte array
**************************************************/
void polyvec_decompress(polyvec *r, const unsigned char *a)
{
  int i,j;
  for(i=0;i<KYBER_K;i++)
  {
    for(j=0;j<KYBER_N/8;j++)
    {
      r->vec[i].coeffs[8*j+0] =  (((a[11*j+ 0]       | (((uint32_t)a[11*j+ 1] & 0x07) << 8)) * KYBER_Q) +1024) >> 11;
      r->vec[i].coeffs[8*j+1] = ((((a[11*j+ 1] >> 3) | (((uint32_t)a[11*j+ 2] & 0x3f) << 5)) * KYBER_Q) +1024) >> 11;
      r->vec[i].coeffs[8*j+2] = ((((a[11*j+ 2] >> 6) | (((uint32_t)a[11*j+ 3] & 0xff) << 2) |  (((uint32_t)a[11*j+ 4] & 0x01) << 10)) * KYBER_Q) + 1024) >> 11;
      r->vec[i].coeffs[8*j+3] = ((((a[11*j+ 4] >> 1) | (((uint32_t)a[11*j+ 5] & 0x0f) << 7)) * KYBER_Q) + 1024) >> 11;
      r->vec[i].coeffs[8*j+4] = ((((a[11*j+ 5] >> 4) | (((uint32_t)a[11*j+ 6] & 0x7f) << 4)) * KYBER_Q) + 1024) >> 11;
      r->vec[i].coeffs[8*j+5] = ((((a[11*j+ 6] >> 7) | (((uint32_t)a[11*j+ 7] & 0xff) << 1) |  (((uint32_t)a[11*j+ 8] & 0x03) <<  9)) * KYBER_Q) + 1024) >> 11;
      r->vec[i].coeffs[8*j+6] = ((((a[11*j+ 8] >> 2) | (((uint32_t)a[11*j+ 9] & 0x1f) << 6)) * KYBER_Q) + 1024) >> 11;
      r->vec[i].coeffs[8*j+7] = ((((a[11*j+ 9] >> 5) | (((uint32_t)a[11*j+10] & 0xff) << 3)) * KYBER_Q) + 1024) >> 11;
    }
    a += 352;
  }
}

#else 
  #error "Unsupported compression of polyvec"
#endif
