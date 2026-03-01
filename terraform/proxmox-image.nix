{
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/proxmox-lxc.nix"
  ];

  # LXC image base name
  image.baseName = lib.mkForce "nixos-proxmox-lxc";

  nix.settings.experimental-features = "nix-command flakes";

  system.stateVersion = "26.05";
}
