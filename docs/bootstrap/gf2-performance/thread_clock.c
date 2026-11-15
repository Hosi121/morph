/* Benchmark adapter only: preserve kernel code, replace the monotonic timer
 * through GNU ld --wrap. Thread CPU time excludes descheduled wall time.
 * This does not exclude CPU-frequency, cache, or host-hypervisor effects. */
#define _POSIX_C_SOURCE 200809L
#include <time.h>

extern int __real_clock_gettime(clockid_t, struct timespec *);

int __wrap_clock_gettime(clockid_t id, struct timespec *out) {
  if (id == CLOCK_MONOTONIC
#ifdef CLOCK_MONOTONIC_RAW
      || id == CLOCK_MONOTONIC_RAW
#endif
  ) {
    return __real_clock_gettime(CLOCK_THREAD_CPUTIME_ID, out);
  }
  return __real_clock_gettime(id, out);
}
