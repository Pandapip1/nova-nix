/* hello.cc -- the C++ counterpart of hello.c, for this package's own
   cc1plus.exe functional test.

   Exercises three things that make a C++ front end a C++ front end and
   that a C-only cc1 cannot compile at all: a class with a user-written
   constructor, a function template with an explicit instantiation, and
   a virtual call dispatched through a base pointer.

   Two deliberate omissions, both real and both documented in
   build.kaem's own comment at the functional test rather than quietly
   designed around here:

     - No throw/catch, no new/delete, no libstdc++ header.  This target
       has no C++ runtime yet -- no libsupc++, and libgcc's SJLJ
       unwinder is not among the compile units this package builds -- so
       any of those would fail to LINK, not to compile.

     - No DERIVED class is constructed.  Constructing one is exactly the
       reproducer for the open cc1plus ICE this package's own session
       found; see build.kaem for the three-line program and the measured
       front-end divergence.  A test that tripped it would fail the
       whole build, and a test that pretended the gap did not exist
       would be worse.

   -nostdinc is passed and no header is included, so this file depends
   on nothing outside itself. */

struct Base {
  virtual int value() const { return 1; }
};

struct Counter {
  int n;
  Counter(int v) : n(v) {}
  int get() const { return n; }
};

template <typename T>
static T twice(T x) {
  return x + x;
}

template int twice<int>(int);

int compute(const Base *b) {
  Counter c(20);
  return twice(b->value()) + c.get();
}
