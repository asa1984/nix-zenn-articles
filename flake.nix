{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        nodeEnv = import "${nixpkgs}/pkgs/development/node-packages/node-env.nix" {
          inherit pkgs;
          inherit (pkgs)
            stdenv
            lib
            python2
            runCommand
            writeTextFile
            writeShellScript
            ;
          nodejs = pkgs.nodejs;
          libtool = null;
        };
        zenn-cli = nodeEnv.buildNodePackage rec {
          name = "zenn";
          packageName = "zenn-cli";
          version = "0.1.154";
          src = builtins.fetchurl {
            url = "https://registry.npmjs.com/zenn-cli/-/zenn-cli-${version}.tgz";
            sha256 = "sha256:0q3h1jxlihb2dmlqjrx8wr36mhcd2ppm1cmd6lp2i93hjjrsj0gc";
          };
          production = true;
          bypassCache = true;
          reconstructLock = true;
        };

        formatters = with pkgs; [
          prettier
          nixfmt-rfc-style
          treefmt
        ];
        format = pkgs.writeScriptBin "format" ''
          PATH=$PATH:${pkgs.lib.makeBinPath formatters}
          ${pkgs.treefmt}/bin/treefmt --config-file ${./treefmt.toml}
        '';
      in
      {
        packages = {
          default = zenn-cli;
          zenn-cli = zenn-cli;
        };
        devShells.default = pkgs.mkShell { packages = with pkgs; [ typos ]; };
        formatter = format;
      }
    );
}
