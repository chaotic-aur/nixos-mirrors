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
      admin = "yumi@silky.network";

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
        # Big server
        fortaleza-br = makemirror "25.11" "x86_64-linux" "fortaleza-br.silky.network" "fortaleza-br" "/dev/vda" ./facter/fortaleza-br.json;

        amsterdam-nl = makemirror "25.11" "aarch64-linux" "amsterdam-nl.silky.network" "amsterdam-nl" "/dev/sda" ./facter/amsterdam-nl.json;

        apodaca-mx = makemirror "25.11" "aarch64-linux" "apodaca-mx.silky.network" "apodaca-mx" "/dev/sda" ./facter/apodaca-mx.json;

        auckland-nz = makemirror "25.11" "x86_64-linux" "auckland-nz.silky.network" "auckland-nz" "/dev/nvme0n1" ./facter/auckland-nz.json;

        bangkok-th = makemirror "25.11" "x86_64-linux" "bangkok-th.silky.network" "bangkok-th" "/dev/nvme0n1" ./facter/bangkok-th.json;

        buenos-aires-ar = makemirror "25.11" "x86_64-linux" "buenos-aires-ar.silky.network" "buenos-aires-ar" "/dev/nvme0n1" ./facter/buenos-aires-ar.json;

        calgary-ca = makemirror "25.11" "x86_64-linux" "calgary-ca.silky.network" "calgary-ca" "/dev/nvme0n1" ./facter/calgary-ca.json;

        cardiff-gb = makemirror "25.11" "x86_64-linux" "cardiff-gb.silky.network" "cardiff-gb" "/dev/sda" ./facter/cardiff-gb.json;

        chuncheon-kr = makemirror "25.11" "aarch64-linux" "chuncheon-kr.silky.network" "chuncheon-kr" "/dev/sda" ./facter/chuncheon-kr.json;

        dubai-ae = makemirror "25.11" "aarch64-linux" "dubai-ae.silky.network" "dubai-ae" "/dev/sda" ./facter/dubai-ae.json;

        frankfurt-de = makemirror "25.11" "aarch64-linux" "frankfurt-de.silky.network" "frankfurt-de" "/dev/sda" ./facter/frankfurt-de.json;

        guarulhos-br = makemirror "25.11" "aarch64-linux" "guarulhos-br.silky.network" "guarulhos-br" "/dev/sda" ./facter/guarulhos-br.json;

        hong-kong-hk = makemirror "25.11" "x86_64-linux" "hong-kong-hk.silky.network" "hong-kong-hk" "/dev/nvme0n1" ./facter/hong-kong-hk.json;

        honolulu-us = makemirror "25.11" "x86_64-linux" "honolulu-us.silky.network" "honolulu-us" "/dev/nvme0n1" ./facter/honolulu-us.json;

        hyderabad-in = makemirror "25.11" "aarch64-linux" "hyderabad-in.silky.network" "hyderabad-in" "/dev/sda" ./facter/hyderabad-in.json;

        jeddah-sa = makemirror "25.11" "aarch64-linux" "jeddah-sa.silky.network" "jeddah-sa" "/dev/sda" ./facter/jeddah-sa.json;

        jerusalem-il = makemirror "25.11" "aarch64-linux" "jerusalem-il.silky.network" "jerusalem-il" "/dev/sda" ./facter/jerusalem-il.json;

        johannesburg-za = makemirror "25.11" "aarch64-linux" "johannesburg-za.silky.network" "johannesburg-za" "/dev/sda" ./facter/johannesburg-za.json;

        la-canada-mx = makemirror "25.11" "aarch64-linux" "la-canada-mx.silky.network" "la-canada-mx" "/dev/sda" ./facter/la-canada-mx.json;

        lagos-ng = makemirror "25.11" "x86_64-linux" "lagos-ng.silky.network" "lagos-ng" "/dev/nvme0n1" ./facter/lagos-ng.json;

        las-vegas-us = makemirror "25.11" "x86_64-linux" "las-vegas-us.silky.network" "las-vegas-us" "/dev/nvme0n1" ./facter/las-vegas-us.json;

        lima-pe = makemirror "25.11" "x86_64-linux" "lima-pe.silky.network" "lima-pe" "/dev/nvme0n1" ./facter/lima-pe.json;

        london-gb = makemirror "25.11" "aarch64-linux" "london-gb.silky.network" "london-gb" "/dev/sda" ./facter/london-gb.json;

        madrid-es = makemirror "25.11" "aarch64-linux" "madrid-es.silky.network" "madrid-es" "/dev/sda" ./facter/madrid-es.json;

        marseille-fr = makemirror "25.11" "aarch64-linux" "marseille-fr.silky.network" "marseille-fr" "/dev/sda" ./facter/marseille-fr.json;

        masdar-city-ae = makemirror "25.11" "aarch64-linux" "masdar-city-ae.silky.network" "masdar-city-ae" "/dev/sda" ./facter/masdar-city-ae.json;

        melbourne-au = makemirror "25.11" "aarch64-linux" "melbourne-au.silky.network" "melbourne-au" "/dev/sda" ./facter/melbourne-au.json;

        miami-us = makemirror "25.11" "x86_64-linux" "miami-us.silky.network" "miami-us" "/dev/nvme0n1" ./facter/miami-us.json;

        montreal-ca = makemirror "25.11" "aarch64-linux" "montreal-ca.silky.network" "montreal-ca" "/dev/sda" ./facter/montreal-ca.json;

        mumbai-in = makemirror "25.11" "aarch64-linux" "mumbai-in.silky.network" "mumbai-in" "/dev/sda" ./facter/mumbai-in.json;

        new-york-us = makemirror "25.11" "x86_64-linux" "new-york-us.silky.network" "new-york-us" "/dev/nvme0n1" ./facter/new-york-us.json;

        osaka-jp = makemirror "25.11" "x86_64-linux" "osaka-jp.silky.network" "osaka-jp" "/dev/sda" ./facter/osaka-jp.json;

        paris-fr = makemirror "25.11" "aarch64-linux" "paris-fr.silky.network" "paris-fr" "/dev/sda" ./facter/paris-fr.json;

        phoenix-us = makemirror "25.11" "aarch64-linux" "phoenix-us.silky.network" "phoenix-us" "/dev/sda" ./facter/phoenix-us.json;

        portland-us = makemirror "25.11" "x86_64-linux" "portland-us.silky.network" "portland-us" "/dev/nvme0n1" ./facter/portland-us.json;

        san-jose-us = makemirror "25.11" "x86_64-linux" "san-jose-us.silky.network" "san-jose-us" "/dev/sda" ./facter/san-jose-us.json;

        santiago-cl = makemirror "25.11" "x86_64-linux" "santiago-cl.silky.network" "santiago-cl" "/dev/sda" ./facter/santiago-cl.json;

        sao-paulo-br = makemirror "25.11" "x86_64-linux" "sao-paulo-br.silky.network" "sao-paulo-br" "/dev/sda" ./facter/sao-paulo-br.json;

        seoul-kr = makemirror "25.11" "aarch64-linux" "seoul-kr.silky.network" "seoul-kr" "/dev/sda" ./facter/seoul-kr.json;

        singapore-sg = makemirror "25.11" "x86_64-linux" "singapore-sg.silky.network" "singapore-sg" "/dev/nvme0n1" ./facter/singapore-sg.json;

        siziano-it = makemirror "25.11" "aarch64-linux" "siziano-it.silky.network" "siziano-it" "/dev/sda" ./facter/siziano-it.json;

        stockholm-se = makemirror "25.11" "aarch64-linux" "stockholm-se.silky.network" "stockholm-se" "/dev/sda" ./facter/stockholm-se.json;

        sydney-au = makemirror "25.11" "aarch64-linux" "sydney-au.silky.network" "sydney-au" "/dev/sda" ./facter/sydney-au.json;

        taipei-tw = makemirror "25.11" "x86_64-linux" "taipei-tw.silky.network" "taipei-tw" "/dev/nvme0n1" ./facter/taipei-tw.json;

        tokyo-jp = makemirror "25.11" "x86_64-linux" "tokyo-jp.silky.network" "tokyo-jp" "/dev/sda" ./facter/tokyo-jp.json;

        toronto-ca = makemirror "25.11" "aarch64-linux" "toronto-ca.silky.network" "toronto-ca" "/dev/sda" ./facter/toronto-ca.json;

        vinhedo-br = makemirror "25.11" "x86_64-linux" "vinhedo-br.silky.network" "vinhedo-br" "/dev/sda" ./facter/vinhedo-br.json;

        zurich-ch = makemirror "25.11" "x86_64-linux" "zurich-ch.silky.network" "zurich-ch" "/dev/sda" ./facter/zurich-ch.json;
      };
    };
}
