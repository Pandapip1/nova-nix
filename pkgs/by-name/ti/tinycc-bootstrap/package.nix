{
  callPackage,
  platform,
  stage0,
  mes,
  nyacc,
}:
if platform == "linux" then
  callPackage ./shared {
    inherit stage0 mes nyacc;
    bloodElf = stage0.blood-elf-bootstrap;
    tccTarget = "I386";
    mesArchInclude = "linux/x86";
  }
else
  callPackage ./windows {
    inherit stage0 mes nyacc;
  }
