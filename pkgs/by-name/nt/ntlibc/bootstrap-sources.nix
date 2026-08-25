# The pinned ntlibc source: the C library the Windows chain targets once
# there is a real compiler to build it with.
#
# Mes's C library got the bootstrap as far as a self-hosting tcc and is not
# meant to go further -- it has no threads, no real signals, a bump
# allocator that never frees, and a POSIX surface thin enough that anything
# above tcc trips over it.  ntlibc is the counterpart of musl on the Linux
# side: the library everything after tcc is built against.
#
# Pinned the same way stage0-pe32 and Mes are -- one revision, fetched,
# nothing vendored.
#
# To move the pin: change `rev` (and `ref`, if it points somewhere other
# than the branch below), then re-evaluate -- fetchGit reports the new
# pin's own `rev`/`narHash`, there is nothing to prefetch by hand.
{ }:
rec {
  version = "0-unstable-2026-08-25";

  # ac08c2f0: fixes execve() calling exit() instead of _exit() -- the exec'ing
  # driver's own atexit-registered cleanup (e.g. gcc's delete_temp_files())
  # re-ran the moment the exec'd child (cc1) exited, deleting the driver's
  # own temp .s file before `as` could read it. This is the real cause of
  # ../../gc/gcc/windows/build.kaem's own hello3.c step stopping at -S instead of -c --
  # see that file's own comment, due for an update once this pin's rebuild
  # is verified. -pipe support is a separate, still-open item this rev does
  # NOT fix.
  rev = "ac08c2f0a45df264e03105e70fe84feebbc68500";
  ref = "main";

  src = builtins.fetchGit {
    url = "https://github.com/Pandapip1/ntlibc.git";
    inherit rev ref;
  };
}
