{ ... }:
{
  system.primaryUser = "nicolasparis";
  users.users.nicolasparis.home = "/Users/nicolasparis";
  nix-homebrew.user = "nicolasparis";
  launchd.user.envVariables.SSL_CERT_FILE =
    "/Users/nicolasparis/.config/homelab/estate-ca-bundle.pem";
}
