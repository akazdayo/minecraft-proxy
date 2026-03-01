{...}: {
  # DigitalOcean Provider
  terraform.required_providers.digitalocean = {
    source = "digitalocean/digitalocean";
    version = "~> 2.75";
  };

  # API Token (環境変数 DIGITALOCEAN_TOKEN から取得)
  provider.digitalocean = {};

  # SSH Key (既存のキーを参照)
  data.digitalocean_ssh_key.default = {
    name = "default";
  };

  # NixOS カスタムイメージ
  resource.digitalocean_custom_image.nixos = {
    name = "digitalocean-nix-tf";
    url = "https://github.com/akazdayo/digitalocean-nix-tf/releases/download/latest/nixos-digitalocean-do.qcow2.gz";
    regions = ["sgp1"];
  };

  # Droplet
  resource.digitalocean_droplet.digitalocean-nix-tf = {
    image = "\${digitalocean_custom_image.nixos.id}";
    name = "digitalocean-nix-tf";
    region = "sgp1";
    size = "s-1vcpu-1gb";
    ssh_keys = ["\${data.digitalocean_ssh_key.default.id}"];
  };

  # Outputs
  output.droplet_ip = {
    value = "\${digitalocean_droplet.digitalocean-nix-tf.ipv4_address}";
    description = "The public IPv4 address of the Droplet";
  };
}
