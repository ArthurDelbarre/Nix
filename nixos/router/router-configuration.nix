{ config, pkgs, ... }:
let
    # Network interface names for the external (internet-facing) and internal (local network) interfaces
    externalInterface = "enp0s1";  # Change this to match your external interface name
    internalInterface = "enp0s2";  # Change this to match your internal interface name
in
{
    # Define the networking options for the internal (local network) interface
    networking = {
        hostName = "router";

        networkmanager = {
            enable = true;
        };

        interfaces = {
            "${externalInterface}" = {
                useDHCP = true;
            };

            "${internalInterface}" = {
                useDHCP = false;
                ipv4.addresses = [{
                    address = "192.168.1.1";
                    prefixLength = 24; # Subnet mask 255.255.255.0
                }];
            };
        };

        firewall = {
            enable = true;
            allowPing = true;
        };

        nat = {
            enable= true;
        };

    };

    boot.kernel.sysctl = {
        "net.ipv4.conf.all.forwarding" = true;
    };

    services = {
        # Define the DHCP server options for the internal (local network) interface
        dhcpd4 = {
            enable = true;
            interfaces = [ internalInterface ];
            extraConfig = ''
                interface "${internalInterface}";
                option routers 192.168.1.1;
                option domain-name "local-network";
                option subnet-mask 255.255.255.0;
                range 192.168.1.100 192.168.1.200;
            '';
        };
    };
}
