# This imports the nix package collection,
# so we can access the `pkgs` and `stdenv` variables
with import <nixpkgs> {};

# Make a new "derivation" that represents our shell
stdenv.mkDerivation {
  name = "dev-env";

  buildInputs = [
    # see https://nixos.org/nixos/packages.html to search for more
    pkgs.nodejs-10_x
    pkgs.terraform_0_12
    pkgs.google-cloud-sdk
    pkgs.lolcat
    pkgs.figlet
  ];

  shellHook = ''
    figlet "Activated dev-env!" | lolcat --freq 0.5
    export GOOGLE_CLOUD_KEYFILE_JSON=$(pwd)/credentials.json
    export GOOGLE_CREDENTIALS=$(pwd)/credentials.json
    export GOOGLE_APPLICATION_CREDENTIALS=$(pwd)/credentials.json
  '';
}