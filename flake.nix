{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, utils, ... }:
    utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      lib = pkgs.lib;
      stdenv = pkgs.clangStdenv;
      thousand = let
        cFlags = lib.concatStringsSep " " [
          "-std=c11"
          "-O2"
          "-g3"
          "-Wall"
          "-Wextra"
          "--target=riscv32"
          "-ffreestanding"
          "-nostdlib"
        ];
      in stdenv.mkDerivation
      {
        pname = "thousand-line";
        version = "dev";

        src = ./.;

        buildPhase = ''
          $CC ${cFlags} -Wl,-Tkernel.ld -Wl,-Map=kernel.map -o kernel.elf kernel.c
        '';
      };
      runner = pkgs.writeShellApplication {
        name = "runner";
        runtimeInputs = [
          pkgs.qemu_full
        ];

        text = ''
          qemu-system-riscv32 -machine virt -bios default -nographic -serial mon:stdio --no-reboot
        '';
      };
    in
    {
      packages = {
        default = thousand;
        inherit runner thousand;
      };

      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.clang
          pkgs.libllvm
          pkgs.qemu_full

          # Nix
          pkgs.nil
          pkgs.nixpkgs-fmt
        ];
      };
    });
}
