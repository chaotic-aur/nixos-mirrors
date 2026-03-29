{ inputs, pkgs, ... }:
let
  flake = "github:chaotic-aur/nixos-mirrors";
in
{
  imports = [
    ./disko.nix
  ];

  # Programs for admins
  programs.git.enable = true;
  programs.htop.enable = true;

  # Auto updates
  system.autoUpgrade = {
    enable = true;
    flake = flake;
    upgrade = false;
    allowReboot = true;
  };

  # Auto clean
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 2d";
      dates = "daily";
    };
    flake = flake;
  };

  nix = {
    settings = {
      # Allow using flakes
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

  environment.systemPackages = with pkgs; [
    btop
    vnstat
  ];

  # Users
  users.mutableUsers = false;
  users.users.mirror-admin = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keyFiles = [
      inputs.keys_tne
      inputs.keys_nico
      inputs.keys_a0xz
    ];
  };

  users.users.root.openssh.authorizedKeys.keyFiles = [
    inputs.keys_tne
    inputs.keys_nico
    inputs.keys_a0xz
  ];

  # Sudo configuration
  security.sudo.extraRules = [
    {
      users = [
        "mirror-admin"
      ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # SSH
  services.openssh.enable = true;

  # Bootloader
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # Statistics
  services.vnstat.enable = true;

  # Persistence
  services.openssh = {
    hostKeys = [
      {
        type = "ed25519";
        path = "/data/persistent/etc/ssh/ssh_host_ed25519_key";
      }
      {
        type = "rsa";
        bits = 4096;
        path = "/data/persistent/etc/ssh/ssh_host_rsa_key";
      }
    ];
  };

  environment.persistence."/data/persistent" = {
    enable = true;
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
      "/var/lib/vnstat"
      "/var/log"
      "/var/lib/docker"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';
}
