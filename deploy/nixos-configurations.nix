{
  self,
  nixpkgs,
  nix-minecraft,
  ...
}:
{
  droplet = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit self; };
    modules = [
      "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-config.nix"
      nix-minecraft.nixosModules.minecraft-servers
      { nixpkgs.overlays = [ nix-minecraft.overlay ]; }
      self.modules.dropletConfiguration
      self.modules.velocityProxy
      self.modules.tailscale
    ];
  };

  proxmox = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit self; };
    modules = [
      "${nixpkgs}/nixos/modules/virtualisation/proxmox-lxc.nix"
      nix-minecraft.nixosModules.minecraft-servers
      {
        nixpkgs.overlays = [ nix-minecraft.overlay ];
        nixpkgs.config.allowUnfreePredicate =
          pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "minecraft-server"
          ];
      }
      self.modules.proxmoxConfiguration
      self.modules.fabricServer
      self.modules.tailscale
    ];
  };
}
