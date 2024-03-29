{ lib
, stdenv
, fetchFromGitea
, testers
, makeWrapper
, coreutils
, fish
, nix
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "nixpkgs-whereis";
  version = "1.2.2";

  src = fetchFromGitea {
    domain = "git.envs.net";
    owner = "binarycat";
    repo = "nixpkgs-whereis";
    rev = finalAttrs.version;
    hash = "sha256-R74bshQjcbnDoVxULH0vRcxNYc3VTxQRvR7f+oxdKHs=";
  };

  nativeBuildInputs = [ makeWrapper fish nix coreutils ];

  passthru.tests.version = testers.testVersion {
    package = finalAttrs.finalPackage;
    command = "nixpkgs-whereis --version";
    inherit (finalAttrs) version;
  };

  makeFlags = [ "PREFIX=$(out)" ];

  postFixup = ''
    patchShebangs $out/bin/nixpkgs-whereis
    wrapProgram $out/bin/nixpkgs-whereis \
      --prefix PATH : ${lib.makeBinPath [ nix coreutils fish ]}
  '';

  meta = with lib; {
    description = "A simple command to check where in nixpkgs an attribute is defined";
    homepage = "https://git.envs.net/binarycat/nixpkgs-whereis";
    maintainer = with maintainers; [ binarycat ];
  };
})
