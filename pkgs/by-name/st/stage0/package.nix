{
  platform,
  stage0-src,
  hex0,
  hex1,
  hex2-bootstrap,
  catm,
  M0,
  cc-x86,
  M2,
  blood-elf-bootstrap,
  M1_0,
  hex2_1,
  M1,
  hex2,
  M2_Mesoplanet,
  blood_elf,
  get_machine,
  M2_Planet,
  kaem,
  mescc-tools-extra,
}:
stage0-src
// {
  inherit
    stage0-src
    hex0
    hex1
    catm
    M0
    M2
    M1
    kaem
    mescc-tools-extra
    ;

  cc_x86 = cc-x86;

  # Compatibility names for consumers that still take the stage0 scope as a
  # single value.  Every value here is defined by its own by-name package.
  hex2_0 = hex2-bootstrap;
  blood_elf_0 = blood-elf-bootstrap;

  inherit
    M1_0
    hex2_1
    M2_Mesoplanet
    blood_elf
    get_machine
    M2_Planet
    ;
}
// (
  if platform == "windows" then
    {
      # On PE32 `hex2` names the early hand-written linker; the C-written
      # replacement is exposed as hex2-new.  The by-name value `hex2` is the
      # latter on both platforms.
      hex2 = hex2-bootstrap;
      hex2-new = hex2;
    }
  else
    { inherit hex2; }
)
