#------------------------------------------------------------------------
#
#	IBM Software
#	Licensed Material - Property of	IBM
#	(C) Copyright International Business Machines Corp. 2014
#	All Rights Reserved.
#
#	U.S. Government	Users Restricted Rights - Use, duplication or
#	disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
#------------------------------------------------------------------------
#  boot-linux-le.tcl
#
#
#------------------------------------------------------------------------
# Run with:
#   /opt/ibm/systemsim-p8/run/pegasus/power8 -f ./boot-linux.tcl
#
# needs a little endian ./vmlinux and a ./disk.img
# 

source $env(LIB_DIR)/common/openfirmware_utils.tcl

set img_dir /y/aix86/debian

# Set the filename of the disk image and kernel here
set disk_img debian-ppc64le-rootfs-v2.0.img
set kernel vmlinux_patched

# Increasing the number of hardware threads per processor or the number of
# CPUs in the simulated system will slow down your boot time because the
# underlying simulator is running on only a single thread on the host
# system
proc config_hook { conf } {
    $conf config cpus 1
    $conf config processor/number_of_threads 1
    $conf config memory_size 2048M
    # We're not running under a hypervisor so we want external interrupts
    # directed to the SRRs rather than HSRRs, so we set LPCR[LPES(0)]=1
    $conf config processor/initial/LPCR 0x8
    # We're running a little endian kernel so we need to set the HILE bit
    # of HID0 so that we stay in little endian mode when handling interrupts
    $conf config processor/initial/HID0 0x0000100000000000
}

source $env(LIB_DIR)/pegasus/systemsim.tcl

source $env(RUN_DIR)/pegasus/p8-devtree.tcl

# Make sure the kernel can be found
if {[file exists ./$kernel]} {
    puts "Found kernel $kernel in current directory"
    set kernel_file ./$kernel
} elseif {[file exists $img_dir/$kernel]} {
    puts "Found kernel $kernel in $img_dir"
    set kernel_file $img_dir/$kernel
} else {
    puts "ERROR: Could not find kernel: $kernel"
    exit
}

# Make sure the disk image can be found
if {[file exists ./$disk_img]} {
    puts "Found disk image $disk_img in current directory"
    set diskimg_file ./$disk_img
} elseif {[file exists $img_dir/$disk_img]} {
    puts "Found disk image $disk_img in $img_dir"
    set diskimg_file $img_dir/$disk_img
} else {
    puts "ERROR: Could not find disk image: $disk_img"
    exit
}

# bogus disk
mysim bogus disk init 0 $diskimg_file rw

# networking with IRQ off
# need this locally:
#   sudo tunctl -u $USER -t tap0
#   sudo ifconfig tap0 172.19.98.108 netmask 255.255.255.254
# in sim this:
#   ifconfig eth0 172.19.98.109 netmask 255.255.255.254
mysim bogus net init 0 d0:d0:d0:da:da:da tap0 0 0

# Load vmlinux
mysim load vmlinux $kernel_file 0x0

mysim mode fastest
mysim go
