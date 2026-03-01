{ ... }:
{
  services.tailscale = {
    enable = true;
    openFirewall = true;

    # Auth key for automatic authentication
    # Deploy時に /var/lib/tailscale/authkey にキーを配置する
    # または環境変数から deploy-rs の activate script で配置
    authKeyFile = "/var/lib/tailscale/authkey";
    authKeyParameters = {
      ephemeral = false;
      preauthorized = true;
    };
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
