{ inputs, config, pkgs, ... }:

let
  username = "todor";
in
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "${username}";
  home.homeDirectory = "/home/${username}";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Sway session
  systemd.user.targets.sway-session = {
    Unit = {
      Description = "Sway compositor session";
      Documentation = [ "man:systemd.special(7)" ];
      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
      BindsTo = [ "graphical-session.target" ];
    };
  };

  # Packages that should be installed to the user profile.
  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    networkmanagerapplet
    blueman
    firefox
    gnome.nautilus gnome.nautilus-python
    evince
    libreoffice-fresh
    gnome.sushi
    gnome.gnome-terminal
    gnome.file-roller
    kitty
    kupfer
    deja-dup
    gnome.gnome-system-monitor
    mpv-unwrapped
    gammastep
    pavucontrol
    lazygit
    recoll
    gsimplecal
    gnome.cheese
    xournalpp
    qbittorrent
    dconf-editor
  ];

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    defaultKeymap = "viins";
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "vi-mode" "fzf" ];
      theme = "af-magic";
    };
  };

  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      nodePackages.neovim
      lazygit
      ripgrep
      cargo
    ];
    extraPython3Packages = (python-packages: with python-packages; [ pynvim ]);
    withNodeJs = true;
    extraConfig = ''
      set number
      set relativenumber
      lua require('vapour')
    '';
  };
  xdg.configFile."nvim/lua" = {
    source = "${inputs.vapournvim}/lua";
    recursive = true;
  };

  programs.git = {
    enable = true;
    userName = "tmarkov";
    userEmail = "todormkv@gmail.com";
    extraConfig = { pager.branch = false; };
  };

  services = {
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 1800;
      enableSshSupport = true;
    };
    pulseeffects.enable = true;
    network-manager-applet.enable = true;
    blueman-applet.enable = true;
  };

  systemd.user.services.squeekboard = {
    Unit = {
      Description = "On-screen keyboard for Wayland";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.squeekboard}/bin/squeekboard";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "sway-session.target" ];
    };
  };

  xdg.configFile = {
    "sway".source = ./home/config/sway;
    "waybar".source = ./home/config/waybar;
    "mako".source = ./home/config/mako;
    "kitty".source = ./home/config/kitty;
    "gammastep".source = ./home/config/gammastep;
  };

  xdg.dataFile = {
    "fonts".source = ./home/data/fonts;
    "kupfer".source = ./home/data/kupfer;
    "nautilus-python".source = ./home/data/nautilus-python;
    "squeekboard".source = ./home/data/squeekboard;
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";
}

