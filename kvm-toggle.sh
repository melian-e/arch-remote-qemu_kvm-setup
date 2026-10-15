#!/bin/bash

if systemctl is-active --quiet libvirtd; then
    echo "Shutting down virtualization environment..."
    # Stop the default network
    sudo virsh net-destroy default >/dev/null 2>&1
    # Stop the daemon
    sudo systemctl stop libvirtd
    echo "KVM/libvirt is now OFF."
else
    echo "Starting virtualization environment..."
    # Start the daemon
    sudo systemctl start libvirtd
    # Brief pause to let the daemon initialize
    sleep 1
    # Start the default network
    sudo virsh net-start default >/dev/null 2>&1
    echo "KVM/libvirt is now ON."
fi
