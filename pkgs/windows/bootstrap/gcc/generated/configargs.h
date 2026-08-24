/* Hand-written, not vendored verbatim from the off-chain reference build --
   see generated/README.md (or default.nix's "What generated/ actually is")
   for why: the reference build's own configargs.h embeds
   configuration_arguments as the literal argv of the off-chain `configure`
   invocation, which includes that scratch build's own /tmp/claude/... path
   (checked directly -- unlike every other file under generated/, this one
   is not purely a function of the gcc version and --target string, it also
   captures whatever path configure happened to run from). Only used for
   `gcc -v`/`--version`'s informational banner and lto-wrapper's
   COLLECT_GCC_OPTIONS passthrough -- nothing in cc1/cpp/gcc's actual
   compilation behavior reads configuration_arguments -- so a clean,
   descriptive string in its place is a cosmetic difference only, not a
   behavioral one. --target/--host/--build reflect this package's own
   choices (see default.nix): i686-pc-pe throughout, both host and build,
   since this is not a cross-compiler from another host's point of view --
   it *is* the host, being built the same way ar/ranlib/nm/objcopy were. */
static const char configuration_arguments[] = "configure --target=i686-pc-pe --host=i686-pc-pe --build=i686-pc-pe --enable-languages=c --disable-nls --disable-shared --disable-threads --disable-bootstrap --disable-multilib --without-headers --with-newlib --disable-decimal-float --disable-libssp --disable-libgomp --disable-libmudflap --disable-libquadmath --disable-lto";
static const char thread_model[] = "single";

static const struct {
  const char *name, *value;
} configure_default_options[] = { { "cpu", "generic" }, { "arch", "pentiumpro" } };
