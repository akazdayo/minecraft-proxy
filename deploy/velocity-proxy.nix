{ pkgs, ... }:
{
  services.minecraft-servers = {
    enable = true;
    eula = true;
    openFirewall = true;

    servers.velocity = {
      enable = true;
      autoStart = true;
      package = pkgs.velocityServers.velocity;
      stopCommand = "end";
      jvmOpts = "-Xms256M -Xmx512M";

      symlinks."velocity.toml" = {
        value = {
          "config-version" = "2.7";
          bind = "0.0.0.0:25565";
          motd = "<#09add3>A Velocity Server";
          "show-max-players" = 500;
          "online-mode" = true;
          "force-key-authentication" = true;
          "prevent-client-proxy-connections" = false;
          "player-info-forwarding-mode" = "modern";
          "forwarding-secret-file" = "forwarding.secret";
          "announce-forge" = false;
          "kick-existing-players" = false;
          "ping-passthrough" = "DISABLED";

          servers = {
            lobby = "minecraft-fabric:25566";
            try = [ "lobby" ];
          };

          "forced-hosts" = { };

          advanced = {
            "compression-threshold" = 256;
            "compression-level" = -1;
            "login-ratelimit" = 3000;
            "connection-timeout" = 5000;
            "read-timeout" = 30000;
            "haproxy-protocol" = false;
            "tcp-fast-open" = false;
            "bungee-plugin-message-channel" = true;
            "show-ping-requests" = false;
            "failover-on-unexpected-server-disconnect" = true;
            "announce-proxy-commands" = true;
            "log-command-executions" = false;
            "log-player-connections" = true;
            "accepts-transfers" = false;
          };

          query = {
            enabled = false;
            port = 25565;
            map = "Velocity";
            "show-plugins" = false;
          };
        };
      };
    };
  };

  # Velocity の forwarding.secret を共有シークレットファイルからコピー
  # /var/lib/minecraft-secret/forwarding.secret に秘密鍵を配置する
  systemd.services.velocity-forwarding-secret = {
    description = "Copy forwarding secret for Velocity proxy";
    wantedBy = [ "minecraft-server-velocity.service" ];
    before = [ "minecraft-server-velocity.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      SECRET_FILE="/var/lib/minecraft-secret/forwarding.secret"
      VELOCITY_SECRET="/srv/minecraft/velocity/forwarding.secret"

      if [ ! -f "$SECRET_FILE" ]; then
        # 初回起動時: ランダムなシークレットを生成
        mkdir -p "$(dirname "$SECRET_FILE")"
        ${pkgs.openssl}/bin/openssl rand -hex 24 > "$SECRET_FILE"
        chmod 600 "$SECRET_FILE"
        chown root:root "$SECRET_FILE"
        echo "Generated new forwarding secret at $SECRET_FILE"
        echo "IMPORTANT: Copy this file to the Fabric server at the same path."
      fi

      mkdir -p "$(dirname "$VELOCITY_SECRET")"
      cp "$SECRET_FILE" "$VELOCITY_SECRET"
      chown minecraft:minecraft "$VELOCITY_SECRET"
    '';
  };
}
