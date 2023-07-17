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
            partitioning = pkgs.writeScriptBin "partitioning" ./scripts/partitioning.sh;

            test = pkgs.writeScriptBin "myscript" ''
                echo foo
            '';
        };

        nixosConfigurations.router = nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
                # Overlays-module makes "pkgs.unstable" available in configuration.nix
                ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })
                ./nixos/router/configuration.nix
            ];
        };
    };
}
