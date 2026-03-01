{
  self,
  nixpkgs,
  ...
}: {
  droplet = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit self;};
    modules = [
      "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-config.nix"
      self.modules.dropletConfiguration
    ];
  };
}
