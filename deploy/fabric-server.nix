{ pkgs, ... }:
{
  services.minecraft-servers = {
    enable = true;
    eula = true;
    openFirewall = true;

    servers.fabric = {
      enable = true;
      autoStart = true;
      package = pkgs.fabricServers.fabric-1_21_4;
      jvmOpts = "-Xms2G -Xmx3G -XX:+UseG1GC";

      serverProperties = {
        online-mode = false;
        server-port = 25566;
        motd = "Fabric Server";
        difficulty = 2;
        gamemode = 0;
        max-players = 20;
        view-distance = 16;
        spawn-protection = 0;
      };

      # FabricProxy-Lite (Velocity modern forwarding対応)
      symlinks = {
        mods = pkgs.linkFarmFromDrvs "mods" [
          (pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/8dI2tmqs/versions/AQhF7kvw/FabricProxy-Lite-2.9.0.jar";
            sha256 = "sha256-wIQA86Uh6gIQgmr8uAJpfWY2QUIBlMrkFu0PhvQPoac=";
          })
        ];
      };
    };
  };

  # FabricProxy-Lite設定を forwarding secret ファイルから動的に生成
  # /var/lib/minecraft-secret/forwarding.secret に Velocity と同じ secret を配置する
  systemd.services.fabricproxy-lite-config = {
    description = "Generate FabricProxy-Lite config with forwarding secret";
    wantedBy = [ "minecraft-server-fabric.service" ];
    before = [ "minecraft-server-fabric.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      SECRET_FILE="/var/lib/minecraft-secret/forwarding.secret"
      CONFIG_DIR="/srv/minecraft/fabric/config"
      CONFIG_FILE="$CONFIG_DIR/FabricProxy-Lite.toml"

      if [ ! -f "$SECRET_FILE" ]; then
        echo "ERROR: $SECRET_FILE not found. Place the Velocity forwarding secret here."
        exit 1
      fi

      SECRET=$(cat "$SECRET_FILE")
      mkdir -p "$CONFIG_DIR"

      cat > "$CONFIG_FILE" <<EOF
      hackOnlineMode = true
      hackEarlySend = false
      hackMessageChain = true
      disconnectMessage = "This server requires Velocity proxy connection"
      secret = "$SECRET"
      EOF

      chown -R minecraft:minecraft "$CONFIG_DIR"
    '';
  };
}
