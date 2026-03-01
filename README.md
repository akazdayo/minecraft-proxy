# NixOS on DigitalOcean with Terraform

Terranix + deploy-rs で NixOS Droplet をデプロイ

## 前提

- Nix (flakes有効)
- DigitalOcean アカウント
- SSH キー (という名前でDigitalOceanにアップロード済み)

## 準備

```bash
# 環境変数を設定
export DIGITALOCEAN_TOKEN="dop_v1_xxxxxxxxxxxxx"
```

## インフラ作成 (Terraform)

```bash
nix run .#tf-plan
nix run .#tf-apply
```

IPアドレスを確認:

```bash
tofu output droplet_ip
```

## NixOSデプロイ

`flake.nix` の `deploy.nodes.droplet.hostname` を実際のIPアドレスに書き換えて:

```bash
deploy
```

## 構成

| ファイル | 説明 |
|---------|------|
| `flake.nix` | メインFlake定義 (NixOS + Terranix + deploy-rs) |
| `terraform/terraform.nix` | Terranix設定 (DigitalOcean Droplet作成) |
| `terraform/do-image.nix` | DigitalOceanイメージビルド設定 |
| `deploy/nixos-configurations.nix` | NixOS設定ビルダー |
| `deploy/droplet-configuration.nix` | Dropletシステム設定 |
| `deploy/deployment.nix` | deploy-rs設定 |

## 削除

```bash
nix run .#tf-destroy
```
