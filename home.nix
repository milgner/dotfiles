{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "marcus";
  home.homeDirectory = "/home/marcus";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.
  # For testing home manager changes
  home.enableNixpkgsReleaseCheck = false;

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # Core infrastructure...
    terminator
    starship
    sway
    swaybg
    swayidle
    light
    dunst
    swaylock-effects
    xdg-utils
    wl-clipboard
    
    # GUI utilities
    _1password-gui
    pavucontrol
    signal-desktop

    # CLI goodness
    jq
    jless
    dog
    nmap
    ripgrep
    pspg
    bat
    fend
    
    # web, office & entertainment ;)
    firefox
    ungoogled-chromium
    libreoffice
    spotify

    # Editors
    sublime4
    sublime-merge
    jetbrains.idea-ultimate
    
    # Development stuff
    git
    gnupg
    jdk17
    rustup
    gradle
    wireshark

    # Fonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    font-awesome

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # Simple shell script to lock sway, mostly avoids repetition in swayidle config
    (pkgs.writeShellScriptBin "lock-sway-session" ''
       ${pkgs.swaylock-effects}/bin/swaylock -fF -S --effect-pixelate 8 --effect-vignette 0:1
    '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    #".gradle/gradle.properties".text = ''
    #  org.gradle.console=verbose
    #  org.gradle.daemon.idletimeout=3600000
    #'';
  };

  home.sessionVariables = {
    EDITOR = "subl -nw";
    MOZ_ENABLE_WAYLAND="1";
  };

  fonts.fontconfig.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.swaylock = { 
    enable = true;
    package = pkgs.swaylock-effects;
  };

  systemd.user.services.sway-polkit-authentication-agent = {
    Unit = {
      Description = "Sway Polkit authentication agent";
      Documentation = "https://gitlab.freedesktop.org/polkit/polkit/";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "always";
      BusName = "org.freedesktop.PolicyKit1.Authority";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  services.swayidle = {
    enable = true;
    timeouts = [
      { timeout = 120; command = "/run/current-system/sw/bin/loginctl lock-session"; }
      { timeout = 180; command = "/home/marcus/.nix-profile/bin/swaymsg \"output * dpms off\""; resumeCommand = "/home/marcus/.nix-profile/bin/swaymsg \"output * dpms on\""; }
    ];
    events = [
      { event = "before-sleep"; command = "/run/current-system/sw/bin/loginctl lock-session"; }
      { event = "lock"; command = "/home/marcus/.nix-profile/bin/lock-sway-session"; }
    ];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;
    userName = "Marcus Ilgner";
    userEmail = "mail@marcusilgner.com";
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };

  wayland.windowManager.sway = {
    enable = true;
    config = rec {
      modifier = "Mod4";
      terminal = "terminator";
      #down = "n";
      #up = "t";
      #left = "h";
      #right = "s";
      #layoutStacking = ",";
      #layoutTabbed = ".";
      input = {
        "*" = {
          xkb_layout = "dvorak";
        };
      };
      
      workspaceLayout = "tabbed";
    };
    extraConfig = ''
      bindsym XF86TouchpadToggle input type:touchpad events toggle enabled disabled
      bindsym Mod4+less exec light -U 10
      bindsym Mod4+greater exec light -A 10
      bindsym XF86MonBrightnessDown exec light -U 10
      bindsym XF86MonBrightnessUp exec light -A 10
      bindsym XF86AudioRaiseVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ +1%'
      bindsym XF86AudioLowerVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ -1%'
      bindsym XF86AudioMute exec 'pactl set-sink-mute @DEFAULT_SINK@ toggle'

      bindsym Mod4+Shift+M exec loginctl lock-session
      exec swaybg -i /home/marcus/Pictures/wallpapers/cyberpunk-city-buildings-art.jpg
      exec dunst
      '';
  };
}
