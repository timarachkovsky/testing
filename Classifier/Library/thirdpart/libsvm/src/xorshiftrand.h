#ifndef XORSHIFTRAND_H
#define XORSHIFTRAND_H

#include <cstdint>

#ifdef _MSC_VER
#include <intrin.h>
#pragma intrinsic(__rdtsc)
#else
#include <stdint.h>
// http://en.wikipedia.org/wiki/Time_Stamp_Counter
__inline__ uint64_t __rdtsc(void) {
	uint32_t lo, hi;
	__asm__ __volatile__(
		"        xorl %%eax,%%eax \n"
		"        cpuid"      // serialize
		::: "%rax", "%rbx", "%rcx", "%rdx");
	/* We cannot use "=A", since this would use %rax on x86_64 and return only the lower 32bits of the TSC */
	__asm__ __volatile__("rdtsc" : "=a" (lo), "=d" (hi));
	return (uint64_t)hi << 32 | lo;
}
#endif


// See https://en.wikipedia.org/wiki/Xorshift
class XorShift128Plus
{
	uint64_t s[2];
public:
	XorShift128Plus(uint64_t seedLo = 0, uint64_t seedHi = 0) {
		if (seedLo == 0 && seedHi == 0) {
			s[0] = __rdtsc();
			s[1] = __rdtsc();
		}
		else {
			s[0] = seedLo;
			s[1] = seedHi;
		}
	}

	void seed(uint64_t seedLo, uint64_t seedHi = 0) {
		s[0] = seedLo;
		s[1] = seedHi;
	}

	const uint64_t * state() const {
		return s;
	}

	uint64_t rand(void) {
		uint64_t x = s[0];
		uint64_t const y = s[1];
		s[0] = y;
		x ^= x << 23; // a
		s[1] = x ^ y ^ (x >> 17) ^ (y >> 26); // b, c
		return s[1] + y;
	}
};

#endif // XORSHIFTRAND_H
