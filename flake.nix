{
  description = "Deployment with NixOS, Terraform, and deploy-rs";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    terranix = {
      url = "github:terranix/terranix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    terranix,
    deploy-rs,
    ...
  }: let
    # --- NixOS Configurations ---
    nixosConfigurations = {
      # DigitalOcean image build用
      do = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-image.nix"
          ./terraform/do-image.nix
        ];
      };

      # Droplet用 NixOS Configuration
      droplet = (import ./deploy/nixos-configurations.nix {inherit self nixpkgs;}).droplet;
    };
  in
    {
      inherit nixosConfigurations;

      modules.dropletConfiguration = ./deploy/droplet-configuration.nix;

      # --- Deploy-RS ---
      deploy = import ./deploy/deployment.nix {
        inherit deploy-rs self;
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        terraform = pkgs.opentofu;
        terraformConfiguration = terranix.lib.terranixConfiguration {
          inherit system;
          modules = [./terraform/terraform.nix];
        };
      in {
        formatter = pkgs.alejandra;

        # DigitalOcean image build (既存)
        packages.do-image = nixosConfigurations.do.config.system.build.digitalOceanImage;

        # Terranix: Terraform JSON configuration
        packages.terraform = terraformConfiguration;

        # --- Apps ---
        # nix run .#tf-apply
        apps.tf-apply = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "tf-apply" ''
              if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
              cp ${terraformConfiguration} config.tf.json \
                && ${terraform}/bin/tofu init \
                && ${terraform}/bin/tofu apply
            ''
          );
          meta = {
            description = "Apply Terraform/OpenTofu configuration";
          };
        };

        # nix run .#tf-destroy
        apps.tf-destroy = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "tf-destroy" ''
              if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
              cp ${terraformConfiguration} config.tf.json \
                && ${terraform}/bin/tofu init \
                && ${terraform}/bin/tofu destroy
            ''
          );
          meta = {
            description = "Destroy Terraform/OpenTofu resources";
          };
        };

        # nix run .#tf-plan
        apps.tf-plan = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "tf-plan" ''
              if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
              cp ${terraformConfiguration} config.tf.json \
                && ${terraform}/bin/tofu init \
                && ${terraform}/bin/tofu plan
            ''
          );
          meta = {
            description = "Plan Terraform/OpenTofu changes";
          };
        };

        # nix run .#deploy
        apps.deploy = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "deploy" ''
              deploy -- --log-format internal-json -v |& nom --json
            ''
          );
          meta = {
            description = "Deploy NixOS configurations using deploy-rs";
          };
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            opentofu
            deploy-rs.packages.${system}.default
            nix-output-monitor
          ];
        };
      }
    );
}
