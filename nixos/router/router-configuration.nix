{ config, pkgs, ... }:
let
    # Network interface names for the external (internet-facing) and internal (local network) interfaces
    externalInterface = "enp0s1";  # Change this to match your external interface name
    internalInterface = "enp0s2";  # Change this to match your internal interface name
    publicDnsServer = "8.8.8.8";
in
{
    boot.kernel.sysctl = {
        "net.ipv4.conf.all.forwarding" = true;
    };
    networking = {

        hostName = "nix-router";
        nameservers = [ "${publicDnsServer}" ];
        firewall.enable = false;

        interfaces = {
            "${externalInterface}" = {
                useDHCP = true;
            };

            "${internalInterface}" = {
                useDHCP = false;
                ipv4.addresses = [{
                    address = "10.13.84.1";
                    prefixLength = 24;
                }];
            };
        };

        nftables = {
            enable = true;
            ruleset = ''
                table ip filter {
                    chain input {
                        type filter hook input priority 0; policy drop;

                        iifname { "${internalInterface}" } accept comment "Allow local network to access the router"
                        iifname "${externalInterface}" ct state { established, related } accept comment "Allow established traffic"
                        iifname "${externalInterface}" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
                        iifname "${externalInterface}" counter drop comment "Drop all other unsolicited traffic from wan"
                    }

                    chain forward {
                        type filter hook forward priority filter; policy drop;
                        iifname { "${internalInterface}" } oifname { "${externalInterface}" } accept comment "Allow trusted LAN to WAN"
                        iifname { "${externalInterface}" } oifname { "${internalInterface}" } ct state established, related accept comment "Allow established back to LANs"
                    }
                }

                table ip nat {
                    chain postrouting {
                        type nat hook postrouting priority 100; policy accept;
                        oifname "${externalInterface}" masquerade
                    }
                }

                table ip6 filter {
                    chain input {
                        type filter hook input priority 0; policy drop;
                    }

                    chain forward {
                        type filter hook forward priority 0; policy drop;
                    }
                }
            '';
        };
    };

    services = {
        dhcpd4 = {
        enable = true;
        interfaces = [ "${externalInterface}" ];
        extraConfig = ''
            subnet 10.13.84.0 netmask 255.255.255.0 {
            option routers 10.13.84.1;
            option domain-name-servers ${publicDnsServer};
            option subnet-mask 255.255.255.0;
            interface ${externalInterface};
            range 10.13.84.2 10.13.84.254;
            }
        '';
        };
    };
}
