{
  description = "Automated chaotic-aur mirrors";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";
    impermanence.inputs.nixpkgs.follows = "";
    impermanence.inputs.home-manager.follows = "";

    # SSH keys
    keys_tne.url = "https://github.com/justtne.keys";
    keys_tne.flake = false;
    keys_nico.url = "https://github.com/dr460nf1r3.keys";
    keys_nico.flake = false;
    keys_a0xz.url = "https://github.com/a0xz.keys";
    keys_a0xz.flake = false;
  };

  outputs = inputs:
    let
      nixpkgs = inputs.nixpkgs;
      admin = "team@garudalinux.org";

      makemirror = stateVersion: arch: fqdn: hostname: disk: facter: nixpkgs.lib.nixosSystem {
        system = arch;
        specialArgs = {
          inherit inputs;
        };
        modules = [
          inputs.disko.nixosModules.disko
          inputs.impermanence.nixosModules.impermanence
          ./mirror.nix
          ({ config, pkgs, ... }: {
            imports = [ ./configuration.nix ];

            chaotic.mirror = {
              enable = true;
              fqdn = fqdn;
              email = admin;
            };

            networking.hostName = hostname;
            system.stateVersion = stateVersion;

            disko.devices.disk.disk.device = disk;
            hardware.facter.reportPath = facter;
          })
        ];
      };
    in
    {
      nixosConfigurations = {
        testing = makemirror "25.11" "x86_64-linux" "test-mirror.silky.network" "testing" "/dev/vda" ./facter/testing.json;
      };
    };
}
