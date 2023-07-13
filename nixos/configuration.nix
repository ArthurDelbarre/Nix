{ config, pkgs, ... }:
{

    imports = [
        ./hardware-configuration.nix
    ];

    # Name the host machine
    networking.hostName = "router";

    # Enable network services
    networking.networkmanager.enable = true;
    networking.wireless.enable = true;

    # Set the time zone
    time.timeZone = "Europe/Paris";

    #Set keyboard layout
    service.xserver.layout = "fr";

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
