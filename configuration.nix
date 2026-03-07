{ inputs, ... }:
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

  # Users
  users.mutableUsers = false;
  users.users.mirror-admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keyFiles = [
      inputs.keys_tne
      inputs.keys_nico
      inputs.keys_a0xz
    ];
  };

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
}
