{ ... }:
{
  # Proxmox VE Provider (bpg/proxmox)
  terraform.required_providers.proxmox = {
    source = "bpg/proxmox";
    version = "~> 0.78";
  };

  # Provider設定 (環境変数 PROXMOX_VE_API_TOKEN or PROXMOX_VE_USERNAME/PASSWORD から取得)
  provider.proxmox = {
    endpoint = "https://192.168.11.12:8006/";
    insecure = true;
  };

  # SSH公開鍵 (環境変数 TF_VAR_ssh_public_key から取得)
  variable.ssh_public_key = {
    type = "string";
    description = "SSH public key for the container root user";
  };

  # NixOS LXC テンプレートをダウンロード
  resource.proxmox_virtual_environment_download_file.nixos-lxc = {
    content_type = "vztmpl";
    datastore_id = "local";
    node_name = "pve";
    url = "https://github.com/akazdayo/minecraft-server/releases/download/latest/nixos-proxmox-lxc.tar.xz";
  };

  # Proxmox LXC Container (NixOS)
  resource.proxmox_virtual_environment_container.minecraft = {
    description = "Minecraft Fabric Server (NixOS LXC)";
    node_name = "pve";

    # NixOS requires unprivileged=false or nesting for systemd
    unprivileged = true;
    features = {
      nesting = true;
    };

    operating_system = {
      template_file_id = "\${proxmox_virtual_environment_download_file.nixos-lxc.id}";
      type = "nixos";
    };

    initialization = {
      hostname = "minecraft-fabric";

      ip_config = [
        {
          ipv4 = {
            address = "dhcp";
          };
        }
      ];

      user_account = {
        keys = [ "\${var.ssh_public_key}" ];
      };
    };

    cpu = {
      cores = 2;
    };

    memory = {
      dedicated = 4096;
      swap = 2048;
    };

    disk = {
      datastore_id = "local-lvm";
      size = 20;
    };

    network_interface = [
      {
        name = "eth0";
        bridge = "vmbr0";
      }
    ];

    start_on_boot = true;
    started = true;

    # Tailscale requires /dev/net/tun access inside the LXC container
    device_passthrough = [
      {
        path = "/dev/net/tun";
        mode = "0666";
      }
    ];
  };

  # Outputs
  output.container_id = {
    value = "\${proxmox_virtual_environment_container.minecraft.vm_id}";
    description = "The ID of the Proxmox LXC Container";
  };
}
