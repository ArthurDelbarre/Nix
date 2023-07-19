{ config, pkgs, hardware-config, ... }:
{
    imports = [
        (hardware-config + "/hardware-configuration.nix")
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
    services.xserver.layout = "fr";

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
        passwordFile = "../users/neil_passwd.txt";
    };
}
