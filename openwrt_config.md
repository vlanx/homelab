## [OpenWRT] as a container config for Proxmox.

Paste the following into a bash script file:

```
#!/bin/bash

url=$1
cid=$2
cname=$3
wget $url -O /tmp/openwrtimage.tar.xz
pct create $cid /tmp/openwrtimage.tar.xz --ostype unmanaged --hostname $name --net0 name=eth0 --net1 name=eth1 --storage local-lvm
rm /tmp/openwrtimage.tar.xz
```

Then just run in like:
```
./script.sh https://images.linuxcontainers.org/images/openwrt/23.05/amd64/default/20241109_11:57/rootfs.tar.xz 999 router
```
Note: Keep in mind you should get a `*.rootfs.tar.xz` url from their [download page](https://images.linuxcontainers.org)

After the container template is created, Go to the container network settings and edit the interfaces settings to reflect your setup. Keep in mind `eth0` must be on WAN.

Access the container via the console on proxmox.
Go to `/etc/config` and edit the `firewall` file.

Add the following rules to allow access to the dashboard from WAN and to allow DHCP clients to get their IP address:
Im not sure if this DHCP rule is necessary, but i put it either way.

```
config rule
	option name             Allow-Dashboard
	option src              wan
	option proto            tcp
	option dest_port        443
	option target	ACCEPT

config rule
        option name 'Allow-DHCP'
        option src 'lan'
        option src_port '67-68'
        list dest_ip '10.10.1.1'
        option dest_port '67-68'
        option target 'ACCEPT'
```

Apply the changes with: `fw4 reload`. You can now access the OpenWRT dashboard.

From there, edit the interfaces (Network -> Interfaces) tab. The eth0 interface *must be* on the wan and you'll probably want it to grab its IP via dhcp, so no change there.

Add the eth1 interface and set its static IP address for the LAN network (10.10.1.0/24) you want it connected to. Most likely you want this device to be the gateway, for eg: `10.10.1.1`
The IPv4 gateway, you want to set it to the gateway of your *WAN*.
Also navigate to the DHCP Server tab if you want your OpenWRT to be the dhcp server for this LAN (I do.)

###### In the Firewall settings, accept all traffic (Input, Output,Forward)

### NAT traffic for your LAN to the internet

In the OpenWRT dashboard, navigate to Network -> Firewall. At the bottom, in the Zones section, tick the checkbox `Masquerading` for the LAN -> WAN Zone.

### Allow SSH traffic from the WAN (either your laptop or the proxmox nodes themselves where the VMs reside).

Im assuming you dont want to only have access to the VMs via console, so you need a way to access their 10.10.1.0/24 network.

I do this by setting up a static route to the LAN network via the OpenWRT WAN IP (192.168.1.X)

Ubuntu/Debian:
```
ip route add 10.10.1.0/24 via 192.168.1.X
```

I need to make a firewall rule to only allow specific devices to connect via SSH, ill look into it in the future.
