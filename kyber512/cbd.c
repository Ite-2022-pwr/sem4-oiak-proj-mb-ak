#include "cbd.h"

/*************************************************
* Name:        load_littleendian
* 
* Description: load bytes into a 64-bit integer 
*              in little-endian order
*
* Arguments:   - const unsigned char *x: pointer to input byte array
*              - bytes:                  number of bytes to load, has to be <= 8
*
* Returns 64-bit unsigned integer loaded from x
**************************************************/
static uint64_t load_littleendian(const unsigned char *x, int bytes)
{
  int i;
  uint64_t r = x[0];
  for(i=1;i<bytes;i++)
    r |= (uint64_t)x[i] << (8*i);
  return r;
}

/*************************************************
* Name:        cbd
* 
* Description: Given an array of uniformly random bytes, compute 
*              polynomial with coefficients distributed according to
*              a centered binomial distribution with parameter KYBER_ETA
*
* Arguments:   - poly *r:                  pointer to output polynomial  
*              - const unsigned char *buf: pointer to input byte array
**************************************************/
void cbd(poly *r, const unsigned char *buf)
{
#if KYBER_ETA == 5
  uint64_t t,d, a[4], b[4];
  int i,j;

  for(i=0;i<KYBER_N/4;i++)
  {
    t = load_littleendian(buf+5*i,5);
    d = 0;
    for(j=0;j<5;j++)
      d += (t >> j) & 0x0842108421UL;

    a[0] =  d & 0x1f;
    b[0] = (d >>  5) & 0x1f;
    a[1] = (d >> 10) & 0x1f;
    b[1] = (d >> 15) & 0x1f;
    a[2] = (d >> 20) & 0x1f;
    b[2] = (d >> 25) & 0x1f;
    a[3] = (d >> 30) & 0x1f;
    b[3] = (d >> 35);

    r->coeffs[4*i+0] = a[0] + KYBER_Q - b[0];
    r->coeffs[4*i+1] = a[1] + KYBER_Q - b[1];
    r->coeffs[4*i+2] = a[2] + KYBER_Q - b[2];
    r->coeffs[4*i+3] = a[3] + KYBER_Q - b[3];
  }
#else
#error "poly_getnoise in poly.c only supports eta in {3,4,5}"
#endif
}
