{
  description = "Home Manager module for agents-status-tray";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    agents-status-tray.url = "git+file:///home/deepwatrcreatur/flakes/agents-status-tray";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      agents-status-tray,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      homeManagerModules.default = import ./modules/agents-status-tray.nix {
        agents-status-tray-flake = agents-status-tray;
      };

      packages = forAllSystems (
        system:
        {
          default = agents-status-tray.packages.${system}.default;
        }
      );
    };
}
