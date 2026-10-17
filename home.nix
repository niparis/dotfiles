{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  home.username = "nicolasparis";
  home.homeDirectory = "/Users/nicolasparis";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    neovim
    opencode
    # the font everything renders in
    nerd-fonts.hack
  ];

  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";

  # The estate's internal services (*.local.org) are signed by Caddy's local
  # authority. macOS trusts it, but Python ships its own root bundle and does
  # not — so `homelab memory` failed certificate verification and returned
  # nothing, silently, on every local agent session.
  #
  # This points Python at certifi's roots plus that CA. Rebuild the file after a
  # Python upgrade, or its public roots go stale:
  #   security find-certificate -a -c "Caddy Local Authority" -p \
  #     /Library/Keychains/System.keychain > /tmp/caddy.pem
  #   cat "$(python3 -c 'import certifi; print(certifi.where())')" /tmp/caddy.pem \
  #     > ~/.config/homelab/estate-ca-bundle.pem
  #
  # Certificate verification is never disabled to get past this.
  home.sessionVariables.SSL_CERT_FILE =
    "${config.home.homeDirectory}/.config/homelab/estate-ca-bundle.pem";


  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      eval "$(/opt/homebrew/bin/mise activate zsh)"
      bindkey '^f' autosuggest-accept

      # Run Reason without inherited certificate overrides
      reason() {
        local binary
        binary="$(whence -p reason)"
        env -u NODE_EXTRA_CA_CERTS -u SSL_CERT_FILE "$binary" "$@"
      }

      # Shortcut
      rereason() {
        reason "$@"
      }
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };


  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };


  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/mise/config.toml".text = ''
    [tools]
    node = "24"
  '';

  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";

  # WezTerm also uses this legacy/recommended path. Keep it declarative and
  # point it at the same repository-managed configuration.
  home.file.".wezterm.lua" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${dotfiles}/home/.config/wezterm/wezterm.lua";
    force = true;
  };

  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";

  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";

  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";

  # Referenced by statusLine in settings.json above. Invoked as `sh <path>`, so
  # it does not need the execute bit.
  home.file.".claude/statusline-command.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/statusline-command.sh";


  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".pi/agent/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";



}
