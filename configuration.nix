# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  my-python-packages = python-packages: with python-packages; [
    numpy
    pandas
    matplotlib
    statsmodels
    sympy
    ipykernel
    jupyter
    i3ipc
    recoll
    pynvim
    pygobject3
  ];
  python-with-packages = pkgs.python310.withPackages my-python-packages;
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Flakes
  nix = {
    package = pkgs.nixFlakes; # or versioned attributes like nixVersions.nix_2_8
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    autoOptimiseStore = true;
  };

  # Boot
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "i8042.dumbkbd=1" ];

    loader = {
      grub.enable = true;
      grub.version = 2;
      grub.device = "nodev";
      grub.efiSupport = true;
      efi.canTouchEfiVariables = true;
    };

    initrd.luks.devices.luksroot = {
      device = "/dev/disk/by-uuid/49711073-34fe-41d1-bc7f-00fb9c932bec";
      preLVM = true;
      allowDiscards = true;
    };
  };

  # Power
  services.tlp.enable = true;
  services.logind.lidSwitch = "lock";
  services.logind.extraConfig = ''
    HandlePowerKey=suspend
  '';

  # Impermanence
  environment.persistence."/nix/persist/system" = {
    directories = [
      "/etc/nixos" # bind mounted from /nix/persist/system/etc/nixos to /etc/nixos
      "/etc/NetworkManager"
      "/var/log"
      "/var/lib"
    ];
    files = [
      "/etc/machine-id"
      "/etc/nix/id_rsa"
    ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.

  users.mutableUsers = false;
  users.defaultUserShell = pkgs.zsh;
  users.users.root.hashedPassword = "!";
  users.users.todor = {
    isNormalUser = true;
    extraGroups = [ "wheel" "input" "video" "lp" "scanner" "audio" ]; # Enable ‘sudo’ for the user.
    passwordFile = "/nix/persist/todor/shadow";
  };
  security.sudo.extraConfig = ''
    # rollback results in sudo lectures after each reboot
    Defaults lecture = never
  '';

  # Locale
  time.timeZone = "Europe/Sofia";
  i18n.defaultLocale = "en_US.UTF-8";

  # Fonts
  fonts.enableDefaultFonts = true;
  fonts.fonts = with pkgs; [
    dejavu_fonts
    noto-fonts
    noto-fonts-emoji
    liberation_ttf
    open-fonts
    fira
    (nerdfonts.override { fonts = [ "JetBrainsMono" "Ubuntu" ]; })
  ];

  # Networking
  networking.hostName = "todor-spectre";
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.extraConfig = "unload-module module-suspend-on-idle";
  hardware.firmware = [ pkgs.sof-firmware pkgs.alsa-firmware ];

  # Display manager and desktop
  services.xserver.displayManager.gdm.enable = true;

  services.dbus.enable = true;
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # so that gtk works properly
    extraPackages = with pkgs; [
      swaylock
      swayidle
      swaybg
      wl-clipboard
      waybar
      mako
      brightnessctl
      glib
      squeekboard
      gnome3.adwaita-icon-theme
    ];
    extraSessionCommands = ''
      export SDL_VIDEODRIVER=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      export _JAVA_AWT_WM_NONREPARENTING=1
      export MOZ_ENABLE_WAYLAND=1
      export EDITOR="nvim"
    '';
  };

  services.pipewire.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    wlr.settings = { screencast.max_fps = 30; };
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    gtkUsePortal = true;
  };

  # System packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # Editor
    neovim
    nodePackages.neovim

    # Tools
    git
    wget
    fzf
    alsa-tools
    psmisc
    pciutils
    xdg-utils
    htop
    file
    ripgrep
    fd

    # Programming
    git
    gcc
    python-with-packages
  ];

  # Programs
  programs.zsh.enable = true;
  programs.dconf.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };
  environment.pathsToLink = [ "/share/zsh" ];


  # List services that you want to enable:
  services.printing.enable = true;
  services.xserver.libinput.enable = true; # touchpad
  services.openssh = {
    enable = true;
    passwordAuthentication = false; # default true
  };
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.jupyter = {
    enable = true;
    user = "todor";
    password = "'sha1:1b961dc713fb:88483270a63e57d18d43cf337e629539de1436ba'";
    kernels = {
      python3 =
        let
          env = python-with-packages;
        in
        {
          displayName = "Python 3";
          argv = [
            "${env.interpreter}"
            "-m"
            "ipykernel_launcher"
            "-f"
            "{connection_file}"
          ];
          language = "python";
        };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}

