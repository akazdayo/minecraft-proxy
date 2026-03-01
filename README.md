# Minecraft Server Infrastructure

Terranix + deploy-rs で Minecraft サーバーインフラをデプロイ

## アーキテクチャ

```
[Internet] → [DigitalOcean Droplet:25565 (Velocity Proxy)] →(Tailscale)→ [Proxmox LXC:25566 (Fabric Server)]
```

- **DigitalOcean Droplet**: Velocity Proxy (公開IP、ポート25565)
- **Proxmox LXC Container**: Minecraft Fabric Server (グローバルIPなし)
- **Tailscale**: 両ノード間のVPN接続

## 前提

- Nix (flakes有効)
- DigitalOcean アカウント
- Proxmox VE サーバー
- Tailscale アカウント + Auth Key
- SSH キー (DigitalOceanにアップロード済み)

## 準備

### 環境変数

```bash
export DIGITALOCEAN_TOKEN="dop_v1_xxxxxxxxxxxxx"
export TF_VAR_ssh_public_key="ssh-ed25519 AAAA..."

# Proxmox API認証 (トークンまたはユーザー/パスワード)
export PROXMOX_VE_API_TOKEN="root@pam!terraform=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

### Tailscale Auth Key

両ノードに Tailscale auth key を配置する必要があります。
[Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys) で reusable + preauthorized な auth key を作成してください。

初回デプロイ後、各ノードに SSH して配置:

```bash
# DigitalOcean Droplet
ssh root@<DROPLET_IP>
mkdir -p /var/lib/tailscale
echo "tskey-auth-xxxxx" > /var/lib/tailscale/authkey
chmod 600 /var/lib/tailscale/authkey
systemctl restart tailscaled

# Proxmox LXC (ローカルネットワーク経由)
ssh root@<LXC_IP>
mkdir -p /var/lib/tailscale
echo "tskey-auth-xxxxx" > /var/lib/tailscale/authkey
chmod 600 /var/lib/tailscale/authkey
systemctl restart tailscaled
```

### Forwarding Secret (Velocity ↔ Fabric)

Velocity の初回起動時にランダムな forwarding secret が自動生成されます (`/var/lib/minecraft-secret/forwarding.secret`)。
この secret を Fabric サーバーにもコピーしてください:

```bash
# Velocity (DigitalOcean) から secret を取得
ssh root@<DROPLET_IP> cat /var/lib/minecraft-secret/forwarding.secret

# Fabric (Proxmox LXC) に配置
ssh root@<LXC_IP>
mkdir -p /var/lib/minecraft-secret
echo "<取得したsecret>" > /var/lib/minecraft-secret/forwarding.secret
chmod 600 /var/lib/minecraft-secret/forwarding.secret
systemctl restart minecraft-server-fabric
```

## インフラ作成 (OpenTofu)

### DigitalOcean

```bash
nix run .#tf-plan
nix run .#tf-apply
```

### Proxmox

```bash
nix run .#tf-plan-proxmox
nix run .#tf-apply-proxmox
```

## NixOSデプロイ

`deploy/deployment.nix` の `hostname` を実際のIPアドレス/ホスト名に書き換えて:

```bash
nix run .#deploy
```

## Proxmox LXCイメージビルド

```bash
nix build .#proxmox-image
# result/ に tar.xz が生成される
```

テンプレートとして配置:

```bash
scp result/tarball/nixos-proxmox-lxc.tar.xz root@<PROXMOX_HOST>:/var/lib/vz/template/cache/
```

## 構成

| ファイル | 説明 |
|---------|------|
| `flake.nix` | メインFlake定義 (NixOS + Terranix + deploy-rs) |
| `terraform/terraform.nix` | Terranix設定 (DigitalOcean Droplet) |
| `terraform/proxmox.nix` | Terranix設定 (Proxmox LXC Container) |
| `terraform/do-image.nix` | DigitalOceanイメージビルド設定 |
| `terraform/proxmox-image.nix` | Proxmox LXCイメージビルド設定 |
| `deploy/nixos-configurations.nix` | NixOS設定ビルダー |
| `deploy/droplet-configuration.nix` | Dropletシステム設定 |
| `deploy/proxmox-configuration.nix` | Proxmox LXCシステム設定 |
| `deploy/deployment.nix` | deploy-rs設定 |
| `deploy/fabric-server.nix` | Minecraft Fabric Server設定 |
| `deploy/velocity-proxy.nix` | Velocity Proxy設定 |
| `deploy/tailscale.nix` | Tailscale VPN設定 |

## 削除

```bash
# DigitalOcean
nix run .#tf-destroy

# Proxmox
nix run .#tf-destroy-proxmox
```
