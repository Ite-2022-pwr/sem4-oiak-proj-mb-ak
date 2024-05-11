#include "indcpa.h"
#include "poly.h"
#include "polyvec.h"
#include "rng.h"
#include "fips202.h"

void pack_pk(unsigned char *r, const polyvec *pk, const unsigned char *seed);
void unpack_pk(polyvec *pk, unsigned char *seed, const unsigned char *packedpk);
void pack_ciphertext(unsigned char *r, const polyvec *b, const poly *v);
void unpack_ciphertext(polyvec *b, poly *v, const unsigned char *c);
void pack_sk(unsigned char *r, const polyvec *sk);
void unpack_sk(polyvec *sk, const unsigned char *packedsk);

#define gen_a(A,B)  gen_matrix(A,B,0)
#define gen_at(A,B) gen_matrix(A,B,1)

/*************************************************
* Name:        gen_matrix
* 
* Description: Deterministically generate matrix A (or the transpose of A)
*              from a seed. Entries of the matrix are polynomials that look
*              uniformly random. Performs rejection sampling on output of 
*              SHAKE-128
*
* Arguments:   - polyvec *a:                pointer to ouptput matrix A
*              - const unsigned char *seed: pointer to input seed
*              - int transposed:            boolean deciding whether A or A^T is generated
**************************************************/
void gen_matrix(polyvec *a, const unsigned char *seed, int transposed) // Not static for benchmarking
{
  unsigned int pos=0, ctr;
  uint16_t val;
  unsigned int nblocks=4;
  uint8_t buf[SHAKE128_RATE*nblocks];
  int i,j;
  uint64_t state[25]; // SHAKE state
  unsigned char extseed[KYBER_SYMBYTES+2];

  for(i=0;i<KYBER_SYMBYTES;i++)
    extseed[i] = seed[i];


  for(i=0;i<KYBER_K;i++)
  {
    for(j=0;j<KYBER_K;j++)
    {
      ctr = pos = 0;
      if(transposed) 
      {
        extseed[KYBER_SYMBYTES]   = i;
        extseed[KYBER_SYMBYTES+1] = j;
      }
      else
      {
        extseed[KYBER_SYMBYTES]   = j;
        extseed[KYBER_SYMBYTES+1] = i;
      }
        
      shake128_absorb(state,extseed,KYBER_SYMBYTES+2);
      shake128_squeezeblocks(buf,nblocks,state);

      while(ctr < KYBER_N)
      {
        val = (buf[pos] | ((uint16_t) buf[pos+1] << 8)) & 0x1fff;
        if(val < KYBER_Q)
        {
            a[i].vec[j].coeffs[ctr++] = val;
        }
        pos += 2;

        if(pos > SHAKE128_RATE*nblocks-2)
        {
          nblocks = 1;
          shake128_squeezeblocks(buf,nblocks,state);
          pos = 0;
        }
      }
    }
  }
}


/*************************************************
* Name:        indcpa_keypair
* 
* Description: Generates public and private key for the CPA-secure 
*              public-key encryption scheme underlying Kyber
*
* Arguments:   - unsigned char *pk: pointer to output public key
*              - unsigned char *sk: pointer to output private key
**************************************************/
// void indcpa_keypair(unsigned char *pk, 
//                    unsigned char *sk)
// {
//   polyvec a[KYBER_K], e, pkpv, skpv;
//   unsigned char buf[KYBER_SYMBYTES+KYBER_SYMBYTES];
//   unsigned char *publicseed = buf;
//   unsigned char *noiseseed = buf+KYBER_SYMBYTES;
//   int i;
//   unsigned char nonce=0;

//   randombytes(buf, KYBER_SYMBYTES);
//   sha3_512(buf, buf, KYBER_SYMBYTES);

//   gen_a(a, publicseed);

//   for(i=0;i<KYBER_K;i++)
//     poly_getnoise(skpv.vec+i,noiseseed,nonce++);

//   polyvec_ntt(&skpv);
  
//   for(i=0;i<KYBER_K;i++)
//     poly_getnoise(e.vec+i,noiseseed,nonce++);

//   // matrix-vector multiplication
//   for(i=0;i<KYBER_K;i++)
//     polyvec_pointwise_acc(&pkpv.vec[i],&skpv,a+i);

//   polyvec_invntt(&pkpv);
//   polyvec_add(&pkpv,&pkpv,&e);

//   pack_sk(sk, &skpv);
//   pack_pk(pk, &pkpv, publicseed);
// }

/*************************************************
* Name:        indcpa_dec
* 
* Description: Decryption function of the CPA-secure 
*              public-key encryption scheme underlying Kyber.
*
* Arguments:   - unsigned char *m:        pointer to output decrypted message
*              - const unsigned char *c:  pointer to input ciphertext
*              - const unsigned char *sk: pointer to input secret key
**************************************************/
// void indcpa_dec(unsigned char *m,
//                const unsigned char *c,
//                const unsigned char *sk)
// {
//   polyvec bp, skpv;
//   poly v, mp;

//   unpack_ciphertext(&bp, &v, c);
//   unpack_sk(&skpv, sk);

//   polyvec_ntt(&bp);

//   polyvec_pointwise_acc(&mp,&skpv,&bp);
//   poly_invntt(&mp);

//   poly_sub(&mp, &mp, &v);

//   poly_tomsg(m, &mp);
// }
