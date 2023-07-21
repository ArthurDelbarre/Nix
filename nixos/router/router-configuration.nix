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
        useNetworkd = false;
        useDHCP = false;
        interfaces."${externalInterface}".useDHCP = true;
        interfaces."${internalInterface}".ipv4.addresses = [
            {
                address = "192.168.1.1";
                prefixLength = 24; # Subnet mask 255.255.255.0
            }
        ];
        firewall = {
            enable = true;
            allowPing = true;
        };

        nat = {
            enable= true;
        };

        sysctl."net.ipv4.ip_forward" = 1;
    };

    services = {
        networkmanager.enable = true;
        networkmanager.interfaces = [ externalInterface ];
        # Define the DHCP server options for the internal (local network) interface
        dhcpd4 = {
            enable = true;
            interfaces = [ internalInterface ];
            options = ''
                option domain-name "local-network";
                option subnet-mask 255.255.255.0;
                range 192.168.1.100 192.168.1.200;
                default-lease-time 43200; # 12 hours in seconds
                max-lease-time 86400;    # 24 hours in seconds
                option routers 192.168.1.1;
            '';
        };
    };
}
