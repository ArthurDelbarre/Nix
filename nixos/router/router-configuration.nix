{ config, pkgs, ... }:
let
    # Network interface names for the external (internet-facing) and internal (local network) interfaces
    externalInterface = "enp1s0";  # Change this to match your external interface name
    internalInterface = "enp2s0";  # Change this to match your internal interface name
    publicDnsServer = "8.8.8.8";
in
{
    boot.kernel.sysctl = {
        "net.ipv4.conf.all.forwarding" = true;
    };

    # Define the networking options for the internal (local network) interface
    networking = {
        hostName = "router";
        nameservers = [ "${publicDnsServer}" ];

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

    services = {
        # Define the DHCP server options for the internal (local network) interface
        dhcpd4 = {
            enable = true;
            interfaces = [ "${internalInterface}" ];
            extraConfig = ''
                subnet 192.168.0 netmask 255.255.255.0 {
                option routers 192.168.1.1;
                option domain-name-servers ${publicDnsServer};
                option subnet-mask 255.255.255.0;
                interface ${internalInterface};
                range 192.168.1.100 192.168.1.200;
                }
            '';
        };
    };
}
