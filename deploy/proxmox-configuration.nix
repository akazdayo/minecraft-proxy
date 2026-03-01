{ pkgs, ... }:
{
  # Nix
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # LXC containers don't need bootloader configuration
  # (boot settings are handled by proxmox-lxc.nix module)

  # Networking
  networking.hostName = "minecraft-fabric";
  networking.firewall.allowedTCPPorts = [ 22 ];

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

  system.stateVersion = "26.05";
}
