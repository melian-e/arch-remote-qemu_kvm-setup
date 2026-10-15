# Arch Linux Minimal QEMU/KVM Setup with Remote Access

This guide covers setting up a headless, on-demand QEMU/KVM hypervisor on Arch Linux. It avoids installing desktop environments on the host and ensures the virtualization daemon only runs when requested.

## 1. Host Preparation & Installation

### Verify Virtualization Support
Ensure your CPU supports hardware virtualization.
```bash
lscpu | grep Virtualization
```
*(You should see `VT-x` for Intel or `AMD-V` for AMD. If blank, enable virtualization in your BIOS/UEFI).*

### Install Minimal Packages
Install only the core backend packages required to run and route traffic for the VMs.
```bash
sudo pacman -Syu
sudo pacman -S qemu-base libvirt edk2-ovmf dnsmasq iptables-nft
```

### Configure User Permissions
Add your standard user to the `libvirt` group to manage VMs and connect remotely via SSH without root.
```bash
sudo usermod -aG libvirt $USER
```
**Important:** Log out and log back in, or reboot your machine for this group change to take effect.

## 2. On-Demand Configuration

To keep the system lightweight, we will not enable `libvirtd` to run on boot. Furthermore, we need to disable the default network's autostart behavior so the daemon and network can be toggled together.

Start the daemon temporarily to configure the network:
```bash
sudo systemctl start libvirtd.service
```

Disable the default network autostart:
```bash
sudo virsh net-autostart default --disable
```

Stop the daemon for now:
```bash
sudo systemctl stop libvirtd.service
```

**Disable Socket Activation:**
By default, systemd will automatically wake up the `libvirtd` daemon if a tool (like `virsh` or `virt-manager`) tries to connect to it. This will bypass your toggle script and leave your VMs without a started network. Disable these sockets to prevent this:

```
sudo systemctl disable --now libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket

```

## 3. The Toggle Script

Create a bash script to toggle the `libvirtd` daemon and the `default` virtual network simultaneously.

1. Make sure you have the kvm-toggle script :
```bash
cat kvm-toggle
```

2. Make it executable and move it to your local binaries path:
```bash
chmod +x kvm-toggle
sudo mv kvm-toggle /usr/local/bin/
```

You can now turn your hypervisor on and off by simply typing `kvm-toggle` in your terminal.

## 4. Remote Graphical Access

Since the Arch host has no GUI, you will manage your VMs and view their displays from your personal client computer.

### On your personal client machine:
1. Install **`virt-manager`** (Virtual Machine Manager).
2. Open `virt-manager`.
3. Go to **File > Add Connection**.
4. Check **Connect to remote host over SSH**.
5. Enter your Arch Linux server's `Username` (the one in the `libvirt` group) and `Hostname` (or IP address).
6. Click **Connect**. 

### Standard Workflow
1. SSH into your Arch host and run `kvm-toggle` to start the environment.
2. Open `virt-manager` on your client PC to create, launch, and view your VMs.
3. When finished, gracefully shut down your VMs from inside the guest OS or via `virt-manager`.
4. Run `kvm-toggle` on your Arch host to shut down the virtualization backend and free up resources.
