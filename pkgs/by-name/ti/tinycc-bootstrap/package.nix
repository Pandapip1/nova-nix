{
  callPackage,
  platform,
  stage0,
  blood-elf-bootstrap,
  mes,
  nyacc,
}:
if platform == "linux" then
  callPackage ./shared {
    inherit stage0 mes nyacc;
    bloodElf = blood-elf-bootstrap;
    tccTarget = "I386";
    mesArchInclude = "linux/x86";
  }
else
  callPackage ./windows {
    inherit stage0 mes nyacc;
  }
