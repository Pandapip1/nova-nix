{
  callPackage,
  isLinux,
  stage0,
  gcc_4_6_4,
  libc,
}:
if isLinux then
  callPackage ../gcc_4_6_4/linux/cxx.nix {
    inherit stage0 libc;
    inherit (stage0) system platforms;
    gcc = gcc_4_6_4;
  }
else
  # Windows: the same derivation, not a second one.
  #
  # On Linux this rung exists because it is a real second BUILD: the
  # C-only gcc that tcc produced is what compiles the C++-enabled one,
  # and libstdc++ needs a shared musl the first gcc was never configured
  # against -- two different configure runs, two different compilers,
  # necessarily two derivations (see ../gcc_4_6_4/linux/cxx.nix).
  #
  # The Windows side has no self-hosting step at all. There is no
  # ./configure and no `make`; ../gcc_4_6_4/windows/build.kaem names
  # every compile line explicitly and this chain's own tcc compiles all
  # of them, cc1plus.exe exactly as much as cc1.exe -- neither front end
  # is built by the other, so there is nothing for a second derivation to
  # be a second STAGE of. Splitting it would mean a second copy of that
  # file's ~1150 compile lines and a second copy of generated/ to produce
  # binaries byte-identical to the ones the first derivation already
  # produced.
  #
  # So this attribute is an alias.  The derivation it points at really
  # does build and install cc1plus.exe and g++.exe.
  #
  # THIS IS NOT YET A USABLE C++ RUNG, and naming it gcc-cxx should not
  # be read as saying it is.  Three separate things are still missing,
  # all of them measured rather than assumed, and none of them worked
  # around:
  #
  #   1. cc1plus.exe ICEs on a three-line program -- constructing an
  #      object of a class derived from one with a virtual function.
  #      Localized to a stale tree in the C++ front end, with a
  #      same-source same-configuration host-built control that does
  #      NOT ICE, so it is a defect in what this chain's tcc produces.
  #      See ../gcc_4_6_4/windows/build.kaem at the cc1plus functional
  #      test for the reproducer and the front-end dump divergence.
  #
  #   2. This chain's tcc cannot ASSEMBLE cc1plus's output in general.
  #      Every vague-linkage C++ entity goes into a COMDAT section, and
  #      tcc rejects the `.linkonce` directive that marks it ("unknown
  #      opcode '.linkonce'").  The COMDAT `.section NAME$SUFFIX,"x"`
  #      syntax itself is already accepted -- `.linkonce` is the single
  #      missing directive, measured with a control.
  #
  #   3. There is no C++ RUNTIME at all: no libsupc++, and libgcc's
  #      SJLJ unwinder (unwind-sjlj.c) is not among the compile units
  #      that package builds.  A `throw` needs __cxa_throw,
  #      __cxa_begin_catch, __cxa_end_catch, __cxa_allocate_exception,
  #      __gxx_personality_sj0 and _Unwind_SjLj_{Register,Unregister,
  #      Resume,RaiseException}; RTTI needs __dynamic_cast; a local
  #      static needs __cxa_guard_{acquire,release,abort}; new/delete
  #      need _Znwj/_ZdlPv.  All of those are absent, so such a
  #      translation unit fails to LINK with real undefined-reference
  #      errors rather than misbehaving quietly.
  #
  # The exception MODEL is settled and is good news: this target selects
  # SJLJ, not DWARF2, so no .cfi_* directives and no unwind tables are
  # emitted at all -- tcc's missing .cfi_* support, long listed as the
  # suspected hard gate on C++ exceptions here, is not one.
  gcc_4_6_4
