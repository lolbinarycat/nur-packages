{ pkgs, lib }:
let
  inherit (builtins) trace tryEval;
  inherit (pkgs.lib) recurseIntoAttrs;
  inherit (pkgs.lib.lists) flatten;
  inherit (pkgs.lib.attrsets) isDerivation foldlAttrs;
  inherit (lib.attrsets) withPrefix;
in rec {
  getMetaUrls = pkg:
    (if isDerivation pkg && (tryEval pkg.meta.available).value
     then flatten
       [ pkg.meta.homepage or [ ]
         pkg.meta.downloadPage or [ ]
         pkg.meta.changelog or [ ] ]
     else [ ]) ++
    (if (pkg).recurseForDerivations or false
     then foldlAttrs (acc: k: v: acc ++ getMetaUrls v) [ ] pkg
     else [ ]);

  urlExists = u: pkgs.runCommand "test-url-availible"
    {
      nativeBuildInputs = with pkgs; [ curl ];
      __noChroot = true;
    } ''
      echo "checking if url exists: ${u}"
      # disable ssl check because nix hides certs
      curl --insecure --fail -ILXHEAD ${u}
      touch $out
  '';

  checkMetaUrls = pkg: pkgs.linkFarmFromDrvs "check-meta-urls"
    (map urlExists (getMetaUrls pkg));

  # example usage: sudo nix-build --no-sandbox -E '(import ./. {}).lib.testers.checkMetaUrlsPkgPrefix "b"'
  checkMetaUrlsPkgPrefix = pre:
    checkMetaUrls (pkgs.lib.recurseIntoAttrs (withPrefix pre pkgs));
}
