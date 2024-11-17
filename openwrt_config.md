## [OpenWRT] as a container config for Proxmox.

Paste the following into a bash script file:
```
#!/bin/bash

url=$1
cid=$2
cname=$3
wget "$url" -O /tmp/openwrtimage.tar.xz
pct create $cid /tmp/openwrtimage.tar.xz --ostype unmanaged --hostname $cname --net0 name=eth0,bridge=vmbr0,ip=dhcp --net1 name=eth1,bridge=vn100,tag=100,mtu=1450 --storage local-lvm
rm /tmp/openwrtimage.tar.xz
```
# THE MOST IMPORTANT THING

I spent countless hours wondering why, for some reason, HTTP (Port 80) traffic wouldn't pass via OpenWRT to my Machines that were residing in a different cluster node than the OpenWRT.
The f@c#i@g problem was the MTU size. Set it to 1450 in the LAN interfaces. That solved my problem...

I set the eth0 interface to get its IP via dhcp, and set it to vmbr0 interface, and set the VLAN and TAG to the eth1 LAN interface. NOTICE THE MTU PARAMETER!

Then just run in like:
```
./script.sh https://images.linuxcontainers.org/images/openwrt/23.05/amd64/default/20241109_11:57/rootfs.tar.xz 999 router
```
Note: Keep in mind you should get a `*.rootfs.tar.xz` url from their [download page](https://images.linuxcontainers.org)

After the container template is created, Go to the container network settings and edit the interfaces settings to reflect your setup. Keep in mind `eth0` must be on WAN.

Access the container via the console on proxmox.
Go to `/etc/config` and edit the `firewall` file.

Add the following rules to allow access to the dashboard from WAN:

```
config rule
	option name             Allow-Dashboard
	option src              wan
	option proto            tcp
	option dest_port        443
	option target	ACCEPT
```

Apply the changes with: `fw4 reload`. You can now access the OpenWRT dashboard.

From there, edit the interfaces (Network -> Interfaces) tab. The eth0 interface *must be* on the wan and you'll probably want it to grab its IP via dhcp, so no change there.

Add the eth1 interface and set its static IP address for the LAN network (10.10.1.0/24) you want it connected to. Most likely you want this device to be the gateway, for eg: `10.10.1.1`
The IPv4 gateway, you want to set it to the gateway of your *WAN*.
Also navigate to the DHCP Server tab if you want your OpenWRT to be the dhcp server for this LAN (I do.)

###### In the Firewall General settings, accept traffic from Input, Output and Forward.
I don't know if this is the safest way, but its the only one i know that allows my VLAN VMs to access the internet. I should just get a dedicated router image instead of a firewall but oh well.

### NAT is enabled by default, so no need to do anything extra.

### Allow SSH traffic from the WAN (either your laptop or the proxmox nodes themselves where the VMs reside).

Im assuming you dont want to only have access to the VMs via console, so you need a way to access their 10.10.1.0/24 network.

I do this by setting up a static route to the LAN network via the OpenWRT WAN IP (192.168.1.X)

Ubuntu/Debian:
```
ip route add 10.10.1.0/24 via 192.168.1.X
```

I need to make a firewall rule to only allow specific devices to connect via SSH, ill look into it in the future.

