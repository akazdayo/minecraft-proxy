{pkgs, ...}: {
  # Nix
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Networking
  networking.hostName = "digitalocean-nix-tf";
  networking.firewall.allowedTCPPorts = [22];

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # Timezone
  time.timeZone = "Asia/Tokyo";

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  # Swap
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 3 * 1024;
    }
  ];

  system.stateVersion = "26.05";
}
