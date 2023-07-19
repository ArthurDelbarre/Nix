{
    description = "Nix config for my HUB project";

    inputs = {
        nixpkgs.url = "nixpkgs/nixos-21.11";
        nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    };

    outputs = { self, nixpkgs, nixpkgs-unstable }:
    let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
        overlay-unstable = final: prev: {
            unstable = nixpkgs-unstable.legacyPackages.${prev.system};
            # use this variant if unfree packages are needed:
            # unstable = import nixpkgs-unstable {
            #   inherit system;
            #   config.allowUnfree = true;
            # };
        };
    in
    {
        packages.x86_64-linux = {

            installer = pkgs.writeShellApplication {
                name = "installer";
                text = ''
                    #!${pkgs.stdenv.shell}
                    ${builtins.readFile ./scripts/installer.sh}
                '';
            };
        };

        nixosConfigurations.router = nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
                # Overlays-module makes "pkgs.unstable" available in configuration.nix
                ({ config, pkgs, ... }:
                {
                    nixpkgs.overlays = [ overlay-unstable ];
                })
                ./hardware-configuration.nix
                ./nixos/router/configuration.nix
            ];
        };
    };
}
