{
  deploy-rs,
  self,
  ...
}: let
  deployConfig = {
    nodes.droplet = {
      hostname = "HOSTIP HERE";
      sshUser = "root";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.droplet;
      };
    };
  };
in
  deployConfig
  // {
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks deployConfig) deploy-rs.lib;
  }
