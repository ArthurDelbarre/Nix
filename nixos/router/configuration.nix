{ config, lib, pkgs, ... }:
{
    imports = [
        ./hardware-configuration.nix
    ];

    # Make the system bootable
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Name the host machine
    networking.hostName = "router";

    # Enable network services
    networking.networkmanager.enable = true;

    # Set the time zone
    time.timeZone = "Europe/Paris";

    #Set keyboard layout
    console.keyMap = "fr";

    # Enable the OpenSSh deamon
    services.openssh.enable = true;

    users.mutableUsers = true;

    users.users.neil = {
        isNormalUser = true;
        home = "/home/neil";
        description = "Neil";
        extraGroups = [
            "wheel"
            "networkmanager"
        ];
        hashedPassword = (builtins.readFile ../../users/neil_passwd.txt);
    };
}
