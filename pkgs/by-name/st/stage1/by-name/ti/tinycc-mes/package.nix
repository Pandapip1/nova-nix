{
  callPackage,
  isLinux,
  stage0,
  mes,
  nyacc,
}:
if isLinux then
  callPackage ./shared {
    inherit stage0 mes nyacc;
    bloodElf = stage0.blood-elf;
    tccTarget = "I386";
    mesArchInclude = "linux/x86";
  }
else
  callPackage ./windows {
    inherit stage0 mes nyacc;
  }
