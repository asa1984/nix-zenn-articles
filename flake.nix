{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nodeEnv =
          import "${nixpkgs}/pkgs/development/node-packages/node-env.nix" {
            inherit pkgs;
            inherit (pkgs)
              stdenv lib python2 runCommand writeTextFile writeShellScript;
            nodejs = pkgs.nodejs;
            libtool = null;
          };

        zenn-cli = nodeEnv.buildNodePackage rec {
          name = "zenn";
          packageName = "zenn-cli";
          version = "0.1.153";
          src = builtins.fetchurl {
            url =
              "https://registry.npmjs.com/zenn-cli/-/zenn-cli-${version}.tgz";
            sha256 =
              "sha256:0jnhxmbgzb2iz4wzgsh8v6p7n4j28lvpn4g0kl92iv84r6sqcz7r";
          };
          production = true;
          bypassCache = true;
          reconstructLock = true;
        };
        format-script = pkgs.writeScriptBin "format" ''
          ${pkgs.prettier}/bin/prettier --write .
        '';
      in {
        packages = {
          default = zenn-cli;
          format = format-script;
          zenn-cli = zenn-cli;
        };
        devShells.default = pkgs.mkShell { packages = with pkgs; [ typos ]; };
        formatter = pkgs.nixfmt;
      });
}
