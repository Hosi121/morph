#!/usr/bin/env python3
"""Relink generated native benchmark C with a thread-CPU-time timer adapter.

Keep these results separate from the stock wall-clock benchmark. Run builds and
timing batches through the shared tools/measure mutex.
"""
import argparse
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("generated_c", type=Path)
parser.add_argument("output", type=Path)
parser.add_argument("--runtime", type=Path, default=Path("_build/native/release/bench/libruntime.a"))
args = parser.parse_args()
args.output.parent.mkdir(parents=True, exist_ok=True)
kernel_object = args.output.with_suffix(".kernel.o")
clock_object = args.output.with_suffix(".clock.o")
flags = ["-O2", "-fwrapv", "-fno-strict-aliasing", "-ffp-contract=off", "-DMOONBIT_ALLOCATOR=MOONBIT_ALLOCATOR_MIMALLOC"]
subprocess.run(["gcc", *flags, "-I", ".tools/moon/include", "-c", str(args.generated_c), "-o", str(kernel_object)], check=True)
subprocess.run(["gcc", *flags, "-c", str(Path(__file__).with_name("thread_clock.c")), "-o", str(clock_object)], check=True)
probe_source = args.output.with_suffix(".clock-probe.c")
probe_binary = args.output.with_suffix(".clock-probe.exe")
probe_source.write_text(r'''#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <time.h>
extern int __real_clock_gettime(clockid_t, struct timespec *);
static double seconds(struct timespec a, struct timespec b) {
  return (double)(b.tv_sec-a.tv_sec) + (double)(b.tv_nsec-a.tv_nsec)*1e-9;
}
int main(void) {
  struct timespec c0,c1,w0,w1,delay={0,20000000};
#ifdef CLOCK_MONOTONIC_RAW
  clockid_t id=CLOCK_MONOTONIC_RAW;
#else
  clockid_t id=CLOCK_MONOTONIC;
#endif
  if (__real_clock_gettime(id,&w0) || clock_gettime(id,&c0)) return 2;
  if (nanosleep(&delay,0)) return 3;
  if (clock_gettime(id,&c1) || __real_clock_gettime(id,&w1)) return 4;
  double cpu=seconds(c0,c1),wall=seconds(w0,w1);
  printf("timer probe: CPU=%.9f wall=%.9f seconds\n",cpu,wall);
  return !(wall>=0.01 && cpu>=0 && cpu<wall*0.25);
}
''')
subprocess.run(["gcc", *flags, str(probe_source), str(clock_object), "-Wl,--wrap=clock_gettime", "-o", str(probe_binary)], check=True)
subprocess.run([str(probe_binary.resolve())], check=True)
subprocess.run(["gcc", *flags, ".tools/moon/lib/libmoonbitrun.o", str(kernel_object), str(clock_object), str(args.runtime),
                "-Wl,--wrap=clock_gettime", "-lm", ".tools/moon/lib/libbacktrace.a", "-o", str(args.output)], check=True)
