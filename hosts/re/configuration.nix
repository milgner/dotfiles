# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  tuxedo = import (builtins.fetchTarball "https://github.com/blitz/tuxedo-nixos/archive/master.tar.gz");
  lanzaboote = import (builtins.fetchTarball "https://github.com/nix-community/lanzaboote/archive/master.tar.gz");
in {
  imports =
    [ # hardware scan can be rebuilt, all actual configuration happens here.
      ./hardware-configuration.nix
      tuxedo.module
      lanzaboote.nixosModules.lanzaboote
    ];

  hardware.tuxedo-control-center.enable = true;
  hardware.tuxedo-keyboard.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "i915.force_probe=a7a0" ];
  boot.initrd.luks.devices."luks-56486057-5f18-4bec-bdd3-4745df5da142".device = "/dev/disk/by-uuid/56486057-5f18-4bec-bdd3-4745df5da142";
  networking.hostName = "re-milgner";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Configure keymap in X11
  services.xserver = {
    enable = false;
    layout = "us";
    xkbVariant = "dvorak";

    displayManager.sddm = {
      enable = false;
      enableHidpi = true;
      # For > 23.05
      #wayland = {
      #  enable = true;
      #};
    };
  };
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
    ACTION=="add", SUBSYSTEM=="leds", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/leds/%k/brightness"
    ACTION=="add", SUBSYSTEM=="leds", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/leds/%k/brightness"
  '';

  # hardware.pulseaudio.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = false;
    alsa.support32Bit = false;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
       intel-media-driver
       vaapiIntel
    ];
    driSupport = true;
    #driSupport32Bit = true;
    #package = (pkgs.mesa.override { galliumDrivers = [ "iris" "i915" "swrast"]; }).drivers;
  };
  hardware.bluetooth.enable = true;

  # Configure console keymap
  console.keyMap = "dvorak";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.marcus = {
    isNormalUser = true;
    description = "Marcus Ilgner";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" "qemu-libvirtd" "libvirtd" "docker" ];
    packages = with pkgs; [];
  };

  users.defaultUserShell = pkgs.zsh;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  # Required for tuxedo control center
  nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1w" "nodejs-14.21.3" "electron-13.6.9"];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
    tailscale
    pinentry-curses
    sbctl
  ];

  environment.shells = with pkgs; [
    zsh
  ];
  nix.settings.allowed-users = [ "marcus" ];
  nix.settings.experimental-features = ["nix-command" "flakes" ];

  programs.zsh.enable = true;

  security.polkit = {
    enable = true;
    extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (
        subject.isInGroup("users")
          && (
            action.id == "org.freedesktop.login1.reboot" ||
            action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
            action.id == "org.freedesktop.login1.power-off" ||
            action.id == "org.freedesktop.login1.power-off-multiple-sessions"
          )
        )
      {
        return polkit.Result.YES;
      }
    })
  '';
  };
  security.pam.services.swaylock = {};

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  virtualisation = {
    libvirtd.enable = true;
    docker = {
      enable = true; # Docker is required for testcontainers
      rootless = {
        enable = true;
        setSocketVariable = true;
      };  
    };
  };

  # List services that you want to enable:
  services.tailscale = { enable = true; };
  services.fwupd.enable = true;

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  networking.firewall.checkReversePath = "loose";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
