{lib, ...}: {
  nix.settings.experimental-features = "nix-command flakes";
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 3 * 1024;
    }
  ];

  # DigitalOceanイメージの名前を固定にする
  image.baseName = lib.mkForce "nixos-digitalocean-do";
  system.stateVersion = "26.05";
}
