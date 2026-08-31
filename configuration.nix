{  ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  # System Settings > General > Sharing > Remote Login
  services.openssh.enable = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = "nicolasparis";
  users.users.nicolasparis = {
    home = "/Users/nicolasparis";
  };

  launchd.user.envVariables.SSL_CERT_FILE =
    "/Users/nicolasparis/.config/homelab/estate-ca-bundle.pem";

  system.stateVersion = 6;

  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      _HIHideMenuBar = true;  # auto-hide the menu bar
      AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad.Clicking = true;              # tap to click
  };

  nix-homebrew = {
    enable = true;
    user = "nicolasparis";
    autoMigrate = true;
  };

  homebrew = {
    enable = true;

    taps = [
      "my-monkeys/tap"
    ];


    onActivation.autoUpdate = true;
    onActivation.cleanup = "zap";   # remove anything not listed here
    onActivation.extraFlags = [ "--force" ];
    casks = [
      "wezterm"
      "claude-code"
      "my-monkeys/tap/opensuperwhisper"
      "codex"
    ];
    brews = [
      "herdr"
      "apfel"
      "duckdb"
      "go"
      "pandoc"
      "rust"
      "unar"
      "bumpversion"
      "ffmpeg"
      "graphviz"
      "libxslt"
      "podman"
      "tailscale"
      "watchman"
      "certbot"
      "gemini-cli"
      "httpie"
      "telnet"
      "poppler"
      "wget"
      "cmake"
      "gh"
      "lua"
      "postgresql@18"
      "tmux"
      "zellij"
      "git-lfs"
      "iperf3"
      "ncdu"
      "redis"
      "tree"
      "just"

    ];
  };


}
