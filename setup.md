# Arch Linux On-Demand QEMU/KVM Setup

This guide covers setting up an on-demand QEMU/KVM virtualization environment on an Arch Linux personal computer. This setup allows you to manage VMs locally, share your computer's resources only when needed, and access the VMs remotely (e.g., from a Windows machine).

## 1. Host Preparation & Installation

### Verify Virtualization Support

Ensure your CPU supports hardware virtualization.

```bash
lscpu | grep Virtualization
```

*(You should see `VT-x` for Intel or `AMD-V` for AMD. If blank, enable virtualization in your BIOS/UEFI).*

### Install Packages

Since this is your personal computer and you will access VMs locally, we will install the QEMU desktop components along with the management GUI (`virt-manager`).

```bash
sudo pacman -Syu
sudo pacman -S qemu-desktop libvirt edk2-ovmf dnsmasq iptables-nft virt-manager virt-viewer
```

### Configure User Permissions

Add your standard user to the `libvirt` group to manage VMs locally and connect remotely via SSH without root.

```bash
sudo usermod -aG libvirt $USER
```

**Important:** Log out and log back in, or reboot your machine for this group change to take effect.

## 2. On-Demand Configuration

To keep your daily driver lightweight, we will disable `libvirtd` from running on boot, turn off the default network's autostart, and disable systemd socket activation.

Start the daemon temporarily to configure the network:

```bash
sudo systemctl start libvirtd.service
```

Disable the default network autostart:

```bash
sudo virsh net-autostart default --disable
```

Stop the daemon:

```bash
sudo systemctl stop libvirtd.service
```

**Disable Socket Activation:**
By default, systemd will automatically wake up the `libvirtd` daemon if a tool tries to connect to it. This will bypass your toggle script and leave your VMs without internet. Disable these sockets:

```bash
sudo systemctl disable --now libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket
```

## 3. The Toggle Script

Create a bash script to toggle the `libvirtd` daemon and the `default` virtual network simultaneously.

1. Make sure you have the `kvm-toggle` script:
```bash
cat kvm-toggle
```

2. Make it executable and move it to your local binaries path:
```bash
chmod +x kvm-toggle
sudo mv kvm-toggle /usr/local/bin/
```

You can now turn your hypervisor on and off by simply typing `kvm-toggle` in your terminal.

## 4. Accessing Your VMs

### Method A: Local Access (On Your Arch PC)

Since Arch is your primary computer, managing VMs locally is straightforward:

1. Open your terminal and run `kvm-toggle` to start the virtualization backend.

2. Launch **Virtual Machine Manager (`virt-manager`)** from your desktop application menu.

3. It will automatically connect to `QEMU/KVM`. You can create, launch, and view your VMs here.

4. When finished, shut down your VMs and run `kvm-toggle` again to free up resources.

### Method B: Remote Access from a Windows Client

If you want to view the graphical console of your VMs from a Windows machine over your local network:

**Prerequisite:** Ensure SSH is enabled and running on your Arch host (`sudo systemctl enable --now sshd`).

1. **Download Virt-Viewer for Windows:**
   Go to the [virt-manager download page](https://virt-manager.org/download.html) and download the Windows installer for `virt-viewer`. Install it on your Windows machine.

2. **Start the Hypervisor:**
   SSH into your Arch host from Windows (using PowerShell or PuTTY) and run `kvm-toggle`.

3. **Connect to the VM Display:**
   Open the **Command Prompt** or **PowerShell** on Windows and run the following command (replace `username`, `arch_ip`, and `vm_name`):

   ```cmd
   "C:\Program Files\VirtViewer v11.0-256\bin\remote-viewer.exe" -c qemu+ssh://username@arch_ip/system
   ```

   *(Note: Adjust the file path if the version number is different).*

   A connection window will appear. It will prompt you for your Arch SSH password, and then allow you to select and open the display of any running VM.

*For higher performance (especially for Windows guest VMs), it is highly recommended to enable Remote Desktop (RDP) inside the guest OS, and connect directly to the guest using the Windows Remote Desktop Connection app over an SSH tunnel.*
