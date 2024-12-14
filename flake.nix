{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-linux" # 64-bit x86 Linux
        "aarch64-darwin" # 64-bit ARM macOS
        "x86_64-darwin" # 64-bit x86 macOS
      ];
      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        {
          config,
          system,
          pkgs,
          lib,
          ...
        }:
        {
          apps = {
            default = {
              program = pkgs.zenn-cli;
            };
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              actionlint.enable = true;
              nixfmt.enable = true;
              prettier.enable = true;
            };
          };
        };
    };
}
