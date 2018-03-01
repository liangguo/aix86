
#------------------------------------------------------------------------
#
#   IBM Software
#   Licensed Material - Property of IBM
#   (C) Copyright International Business Machines Corp. 2006, 2014
#   All Rights Reserved.
#
#   U.S. Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with
#   IBM Corp.
#
#------------------------------------------------------------------------
#   aix.tcl
#------------------------------------------------------------------------

package require AIXUtils

proc initp_break_point { sim args } {
    set myargs [lindex $args 0]
    set procid [lindex $myargs 5]
    set tid [lindex $myargs 7]

    set pid [$sim cpu $procid thread $tid display gpr 3]
    set nameaddr [$sim cpu $procid thread $tid display gpr 7]
    set myname [get_string_at_ea $sim $nameaddr $procid $tid]
    puts "[$sim display cycles]: TRIGGER : initp called:pid=$pid:name=$myname"
}

proc printf_break_point { sim args } {
    #set t [$sim cpu 0 display currentthread]
    set myargs [lindex $args 0]
    set pc [lindex $myargs 1]
    set procid [lindex $myargs 5]
    set tid [lindex $myargs 7]
    set t $procid:$tid

    set stringaddr [$sim cpu $t display gpr 3]
    set string [get_string_at_ea $sim $stringaddr $procid $tid]
    set gpr4 [$sim cpu $t display gpr 4]
    set gpr5 [$sim cpu $t display gpr 5]
    set gpr6 [$sim cpu $t display gpr 6]
    puts "printf formatstr=$string r4=$gpr4 r5=$gpr5 r6=$gpr6"
}

proc fprintf_break_point { sim args } {
    #set t [$sim cpu 0 display currentthread]
    set myargs [lindex $args 0]
    set pc [lindex $myargs 1]
    set procid [lindex $myargs 5]
    set tid [lindex $myargs 7]
    set t $procid:$tid

    set stringaddr [$sim cpu $t display gpr 4]
    set string [get_string_at_ea $sim $stringaddr $procid $tid]
    set gpr5 [$sim cpu $t display gpr 5]
    set gpr6 [$sim cpu $t display gpr 6]
    set gpr7 [$sim cpu $t display gpr 7]
    set cycles [$sim display cycles]
    puts "fprintf formatstr1=$string r5=$gpr5 r6=$gpr6 r7=$gpr7"
}

proc trchk0_break_point {sim args} {
    set myargs [lindex $args 0]
    set pc [lindex $myargs 1]
    set procid [lindex $myargs 5]
    set tid [lindex $myargs 7]

    set hooktype [$sim cpu $procid thread $tid display gpr 3]
    set hooktype [expr $hooktype & 0xffffffff]
    set hooktype [format "0x%x" $hooktype]

#    puts "TRIGGER: TRCHK id = $hooktype"
#    set p_pid [$sim cpu $procid thread $tid display gpr 4]
#    set t_tid [$sim cpu $procid thread $tid display gpr 5]
#    set old_tid [$sim cpu $procid thread $tid display gpr 6]
#    set prio [$sim cpu $procid thread $tid display gpr 7]
#    puts "TRIGGER: thread dispatch on cpu $procid thread $tid: tid $t_tid pid $p_pid old_tid $old_tid prio $prio"
#    simstop5A
    if { [string equal $hooktype "0x10600000"] } { #non-idle thread dispatch
	set p_pid [$sim cpu $procid thread $tid display gpr 4]
	set t_tid [$sim cpu $procid thread $tid display gpr 5]
	set old_tid [$sim cpu $procid thread $tid display gpr 6]
	set prio [$sim cpu $procid thread $tid display gpr 7]
# PJB: Quite for now
puts "[$sim display cycles]: TRIGGER : thread dispatch on cpu $procid thread $tid: tid $t_tid pid $p_pid old_tid $old_tid prio $prio"
#	simstop
    } elseif { [string equal $hooktype "0x10c00000"] } { #idle thread dispatch
	set p_pid [$sim cpu $procid thread $tid display gpr 4]
	set t_tid [$sim cpu $procid thread $tid display gpr 5]
	set old_tid [$sim cpu $procid thread $tid display gpr 6]
	set prio [$sim cpu $procid thread $tid display gpr 7]
	set cpuid [$sim cpu $procid thread $tid display gpr 8]
	puts "[$sim display cycles]: TRIGGER : idle loop dispatch on cpu $procid thread $tid: tid $t_tid pid $p_pid old_tid $old_tid prio $prio"
    } elseif { [string equal $hooktype "0x13400000"] } { #idle thread dispatch
	set nameaddr [$sim cpu $procid thread $tid display gpr 6]
	set string [get_string_at_ea $sim $nameaddr $procid $tid]
	puts "[$sim display cycles]: TRIGGER : execve name: $string"
    } elseif { [string equal $hooktype "0x13900000"] } { #idle thread dispatch
	set p_pid [$sim cpu $procid thread $tid display gpr 4]
	set t_tid [$sim cpu $procid thread $tid display gpr 5]
	puts "[$sim display cycles]: TRIGGER : CPU $procid hwthread $tid fork new pid = $p_pid new tid = $t_tid"
    } elseif { [string equal $hooktype "0x15900000"] } { #idle thread dispatch
	puts "\n\n[$sim display cycles]: TRIGGER : mount!!!!!\n\n"
    } elseif { [string equal $hooktype "0x13500000"] } { #process exit
	set t_tid [$sim cpu $procid thread $tid display gpr 5]
	puts "\n\n[$sim display cycles]: TRIGGER : exit called, tid = $t_tid\n\n"
    } elseif { [string equal $hooktype "0x1b000000"] } { #VMM
#
    } elseif { [string equal $hooktype "0x4b000000"] } { #VMM
#
    } else {
#	puts "Call to trchk0, hooktype = $hooktype"
    }
    
    #    simstop
}

##################################
# For monitoring calls to exec
##################################
proc execvexcommon_break_point { sim args } {
    set myargs [lindex $args 0]
    set pc [lindex $myargs 1]
    set procid [lindex $myargs 5]
    set tid [lindex $myargs 7]
    set nameaddr [$sim cpu $procid thread $tid display gpr 3]
    set filename [get_string_at_ea $sim $nameaddr $procid $tid]
    set cycles [mysim display cycles]
    puts "[$sim display cycles]: TRIGGER : exec called: proc $procid thread $tid, binary: $filename"
#    simstop
}



################################################
# Would like to be aware of pal commands issued
################################################
proc palcommand_break_point { sim args } {
    #set t [$sim cpu 0 display currentthread]
    set myargs [lindex $args 0]
    set pc [lindex $myargs 1]
    set mcmid [lindex $myargs 3]
    set procid [lindex $myargs 5]
    set tid [lindex $myargs 7]
    set t $mcmid:$procid:$tid

    set palcmd [$sim cpu $t display gpr 3]    
    set pamcmd [expr $palcmd & 0xffffffff]
    set palcmd [format "%d" $palcmd]
    set lr [$sim cpu $t display spr lr]

	set prefix "[$sim display cycles]: TRIGGER : CPU#$t (lr:$lr)"

    if { [string equal $palcmd "1"] } {
	    puts "$prefix pal command called: ENABLE_NVRAM"
    } elseif { [string equal $palcmd "2"] } {
	    puts "$prefix pal command called: ENABLE_DEBUGGER"
    } elseif { [string equal $palcmd "3"] } {
	    puts "$prefix pal command called: PANIC"
    } elseif { [string equal $palcmd "4"] } {
	    puts "$prefix pal command called: SET_SYSTEM_TIME"
    } elseif { [string equal $palcmd "5"] } {
	    puts "$prefix pal command called: GET_MY_PPDA"
    } elseif { [string equal $palcmd "6"] } {
	    puts "$prefix pal command called: GET_PPDA"
    } elseif { [string equal $palcmd "7"] } {
	    puts "$prefix pal command called: CPU_STOP"
    } elseif { [string equal $palcmd "8"] } {
	    puts "$prefix pal command called: ACK_STOP"
    } elseif { [string equal $palcmd "9"] } {
	    puts "$prefix pal command called: INITIATE_SYSTEM_DUMP"
        simstop
    } elseif { [string equal $palcmd "10"] } {
	    puts "$prefix pal command called: DISABLE_IO"
    } elseif { [string equal $palcmd "11"] } {
	    puts "$prefix pal command called: IPI_VECTOR"
    } elseif { [string equal $palcmd "12"] } {
	    puts "$prefix pal command called: BID_TO_BUSDATA"
    } elseif { [string equal $palcmd "13"] } {
	    puts "$prefix pal command called: BUSDATA_TO_BID"
    }  elseif { [string equal $palcmd "14"] } {
	    puts "$prefix pal command called: IPL_KEY_POSITION"
    } elseif { [string equal $palcmd "15"] } {
	    puts "$prefix pal command called: RTAS_GLUE"
    } elseif { [string equal $palcmd "16"] } {
	    puts "$prefix pal command called: GET_NVRAM_ERROR_LOG_SIZE"
    } elseif { [string equal $palcmd "17"] } {
	    puts "$prefix pal command called: GET_NVRAM_DUMP_INFO_SIZE"
    } elseif { [string equal $palcmd "18"] } {
	    puts "$prefix pal command called: MPCREG"
    } elseif { [string equal $palcmd "19"] } {
	    puts "$prefix pal command called: MPCSEND"
    } elseif { [string equal $palcmd "20"] } {
	    puts "$prefix pal command called: GET_PALMEM_INFO"
    } elseif { [string equal $palcmd "21"] } {
	    puts "$prefix pal command called: ENABLE_KDB_IPI"
    } elseif { [string equal $palcmd "22"] } {
	    puts "$prefix pal command called: KERNEL_OPS"
    } elseif { [string equal $palcmd "23"] } {
	    puts "$prefix pal command called: HA_REPORT"
    } elseif { [string equal $palcmd "24"] } {
	    puts "$prefix pal command called: GET_PAL_STOP_SELF_ADDR"
    } elseif { [string equal $palcmd "29"] } {
	    puts "$prefix pal command called: RTAS_REGISTER"
    } elseif { [string equal $palcmd "30"] } {
	    puts "$prefix pal command called: HA_BINDPROCESSOR"
    } elseif { [string equal $palcmd "32"] } {
	    puts "$prefix pal command called: MC_FWNMI"
    } elseif { [string equal $palcmd "33"] } {
	    puts "$prefix pal command called: SR_FWNMI"
    } elseif { [string equal $palcmd "34"] } {
	    puts "$prefix pal command called: INTERLOCK_FWNMI"
    } elseif { [string equal $palcmd "35"] } {
	    puts "$prefix pal command called: GET_EEH_ADDR"
    } elseif { [string equal $palcmd "36"] } {
	    puts "$prefix pal command called: GET_EEH_DRIVER_ADDR"
    } elseif { [string equal $palcmd "37"] } {
	    puts "$prefix pal command called: GET_STOP_SELF_PARMS"
    } elseif { [string equal $palcmd "38"] } {
	    puts "$prefix pal command called: SET_RTAS_TOKENS"
    } elseif { [string equal $palcmd "39"] } {
	    puts "$prefix pal command called: SET_RTAS_LOCK"
    } elseif { [string equal $palcmd "40"] } {
	    puts "$prefix pal command called: SET_ERRINJCT_TOKENS"
    } elseif { [string equal $palcmd "41"] } {
	    puts "$prefix pal command called: SET_NVRAM_ERROR_LOG_SIZE"
    } elseif { [string equal $palcmd "42"] } {
	    puts "$prefix pal command called: HA_INIT"
    } elseif { [string equal $palcmd "43"] } {
	    puts "$prefix pal command called: RTAS_REGISTER2"
    } elseif { [string equal $palcmd "44"] } {
	    puts "$prefix pal command called: PAL_LOADED"
    } elseif { [string equal $palcmd "45"] } {
	    puts "$prefix pal command called: MD_LOCK"
    } elseif { [string equal $palcmd "46"] } {
	    puts "$prefix pal command called: MD_UNLOCK"
    } else {
	    puts "t unrecognized pal command: $palcmd"
    }

}



##################################################
# If halt_display gets called, might as well jump
##################################################

proc haltdisplay_break_point { sim args } {
   puts "\n\n\n\n\System halted! No point continuing.\n\n\n"
   simstop
}

proc chrp_crash_break_point { sim args } {
   puts "\n\n\n\n\System crashed! No point continuing.\n\n\n"
   simstop
}


proc set_aix_process_triggers { sim verbosity } {

    #
    # Base messages about processes
    #
    if { $verbosity > 0 } {

        set initpentry [AIXUtils::get_function_entry "initp"]
        $sim trigger set pc $initpentry "initp_break_point $sim"

        set execvexcommon_entry [AIXUtils::get_function_entry "execvex_common"]
        $sim trigger set pc $execvexcommon_entry "execvexcommon_break_point $sim"

        set haltentry [AIXUtils::get_function_entry "halt_display"]
        $sim trigger set pc $haltentry "haltdisplay_break_point $sim"

        set chrp_crash_entry [AIXUtils::get_function_entry "chrp_crash"]
        $sim trigger set pc $chrp_crash_entry "chrp_crash_break_point $sim"

    }

    set printfentry [AIXUtils::get_function_entry "printf"]

    #
    # Second level messages include the AIX pal commands
    #
    if { $verbosity > 2 } {

        set palcommandentry [AIXUtils::get_function_entry "pal_command"]
        $sim trigger set pc $palcommandentry "palcommand_break_point $sim"

    }

    #
    # Third level messages about what gets dispatched when
    #
    if { $verbosity > 2 } {

        #for trace hooks
        set trchk0entry [AIXUtils::get_function_entry "trchook64"]
        #defined in AIX53D an higher
        set trchook2entry [AIXUtils::get_function_entry "mtrchook2"]
        set trchook5entry [AIXUtils::get_function_entry "mtrchook5"]
        $sim trigger set pc $trchk0entry "trchk0_break_point $sim"
        $sim trigger set pc $trchook2entry "trchk0_break_point $sim" 
        $sim trigger set pc $trchook5entry "trchk0_break_point $sim"

    }
}

###################################################
# Add needed pieces for AIX in firmware tree
###################################################
proc AIX_Update_OF_Tree { {sim mysim} } {
    set root_node [ $sim mcm 0 of peer 0 ]

    puts "Starting device tree extensions for AIX"
#    set value2 [mysim display cpus]
    set value2 2
    # Set cpu-version and VMX value
    for { set i 0 } { $i < $value2 } { incr i } {
        set devhandle [$sim mcm 0 of find_device "/cpus/PowerPC@$i"]
        if { $devhandle >= 0 } {
	    #set value3 [$sim cpu 0 display spr pvr]
	    set value3 [mysim display spr pvr]
            $sim mcm 0 of setprop $devhandle cpu-version $value3
            if { [ Config::is_defined CONFIG_VSX ] } {
                $sim mcm 0 of addprop $devhandle "int" "ibm,vmx" 2
            }
        }
    }

    # Add Vdevice items
    puts "Adding vdevice info..."
    set vdevice_node [ $sim mcm 0 of find_device "/vdevice" ]

    if { $vdevice_node < 0 } {
        set vdevice_node [ $sim mcm 0 of addchild $root_node "vdevice" "" ]
    }
    $sim mcm 0 of addprop $vdevice_node "string" "name"         "vdevice"
    $sim mcm 0 of addprop $vdevice_node "string" "device_type"  "vdevice"
    $sim mcm 0 of addprop $vdevice_node "string" "compatible"   "IBM,vdevice"
    $sim mcm 0 of addprop $vdevice_node "string" "interrupt-controller"   ""
    $sim mcm 0 of addprop $vdevice_node "int"    "#address-cells"   1
    $sim mcm 0 of addprop $vdevice_node "int"    "#size-cells"      0
    $sim mcm 0 of addprop $vdevice_node "int"    "#interrupt-cells" 2

    set ranges [list \
	    0x000a0000 0x00000007 \
	    0x00000b00 0x00000007 \
	    0x000c0000 0x00000007 \
	    0x00000d00 0x00000007 ]
    $sim mcm 0 of addprop $vdevice_node array "interrupt-ranges" ranges

    set sub_vdevice_node [ $sim mcm 0 of addchild $vdevice_node "IBM,sp@4000" "" ]

    $sim mcm 0 of addprop $sub_vdevice_node "string" "name"         "IBM,sp"
    $sim mcm 0 of addprop $sub_vdevice_node "string" "device_type"  "IBM,sp"
    $sim mcm 0 of addprop $sub_vdevice_node "string" "used-by-rtas" ""
    $sim mcm 0 of addprop $sub_vdevice_node "int"    "reg"          0x4000
    $sim mcm 0 of addprop $sub_vdevice_node "int"    "IBM,AIX-phandle" $sub_vdevice_node

    set vty_vdevice_node [ $sim mcm 0 of addchild $vdevice_node "vty@30000000" "" ]
    $sim mcm 0 of addprop $vty_vdevice_node "string" "name"         "vty"
    $sim mcm 0 of addprop $vty_vdevice_node "string" "device_type"  "serial"
    $sim mcm 0 of addprop $vty_vdevice_node "string" "compatible"   "hvterm-protocol"
    $sim mcm 0 of addprop $vty_vdevice_node "int"    "reg"          0x30000000
    $sim mcm 0 of addprop $vty_vdevice_node "int"    "ibm,my-drc-index" 0x30000000
    $sim mcm 0 of addprop $vty_vdevice_node "int"    "ibm,phandle" 0x30000000

    #set vty_vdevice_node [ $sim mcm 0 of addchild $vdevice_node "vty@40000000" "" ]
    #$sim mcm 0 of addprop $vty_vdevice_node "string" "name"         "vty"
    #$sim mcm 0 of addprop $vty_vdevice_node "string" "device_type"  "serial"
    #$sim mcm 0 of addprop $vty_vdevice_node "string" "compatible"   "hvterm-protocol"
    #$sim mcm 0 of addprop $vty_vdevice_node "int"    "reg"          0x40000000
    #$sim mcm 0 of addprop $vty_vdevice_node "int"    "ibm,my-drc-index" 0x40000000
    #$sim mcm 0 of addprop $vty_vdevice_node "int"    "ibm,phandle" 0x40000000

    # Add bogusdisk items
    puts "Adding /vdevice/bogusdisk info..."
    set bogusdisk_node [ $sim mcm 0 of addchild $vdevice_node "bogusdisk@50000000" "" ]

    if { $bogusdisk_node < 0 } {
        set bogusdisk_node [ $sim mcm 0 of addchild $vdevice_node "bogusdisk@50000000" "" ]
    }

    $sim mcm 0 of addprop $bogusdisk_node "string" "name" "bogusdisk"
    $sim mcm 0 of addprop $bogusdisk_node "string" "compatible" "mambo"
    $sim mcm 0 of addprop $bogusdisk_node "string" "device_type" "block"
    $sim mcm 0 of addprop $bogusdisk_node "int" "reg" 0x50000000

    # Add RTAS items
    puts "Adding /rtas info..."
    set rtas_node [ $sim mcm 0 of find_device "/rtas" ]

    puts "Adding /rtas 2 info..."
    if { $rtas_node < 0 } {
        set rtas_node [ $sim mcm 0 of addchild $root_node "rtas" "" ]
    }
    puts "Adding /rtas 3 info..."
    $sim mcm 0 of addprop $rtas_node "int" "ibm,display-character" 0xa
    puts "Adding /rtas 4 info..."
    $sim mcm 0 of addprop $rtas_node "int" "ibm,display-number-of-lines" 0x2
    puts "Adding /rtas 5 info... sub_vdevice_node = $sub_vdevice_node"
    $sim mcm 0 of addprop $rtas_node "int" "ibm,display-line-length" 0x10
    puts "Adding /rtas 6 info..."
    $sim mcm 0 of addprop $rtas_node "int" "rtas-display-device" $sub_vdevice_node
    puts "Adding /rtas 7 info..."
    $sim mcm 0 of addprop $rtas_node "int" "ibm,form-feed" 0xc
    puts "Adding /rtas 8 info..."

    # Add Option items
    puts "Adding /options info..."
    set options_node [ $sim mcm 0 of find_device "/options" ]

    if { $options_node < 0 } {
        set options_node [ $sim mcm 0 of addchild $root_node "options" "" ]
    }
    $sim mcm 0 of addprop $options_node "string" "output-device" "/vdevice/vty@30000000"
    $sim mcm 0 of addprop $options_node "string" "input-device" "/vdevice/vty@30000000"
    $sim mcm 0 of addprop $options_node "string" "load-base" "16384"

    # Add Aliases items
    puts "Adding /aliases info..."
    set aliases_node [ $sim mcm 0 of find_device "/aliases" ]

    if { $aliases_node < 0 } {
        set aliases_node [ $sim mcm 0 of addchild $root_node "aliases" "" ]
    }
    $sim mcm 0 of addprop $aliases_node "string" "screen" "/vdevice/vty@30000000"

    # Add chosen items
    puts "Adding /chosen info..."
    set chosen_node [ $sim mcm 0 of find_device "/chosen" ]

    if { $chosen_node < 0 } {
        set chosen_node [ $sim mcm 0 of addchild $root_node "chosen" "" ]
    }
    set memory_node [ $sim mcm 0 of find_device "/memory@0" ]
    if { $memory_node < 0 } {
        puts "ERROR: Cannot find /memory@0 in device tree which build AIX extensions to OF tree"
    }
    $sim mcm 0 of addprop $chosen_node "int" "memory" $memory_node
#    $sim mcm 0 of addprop $chosen_node "string" "bootpath" "mambo bogusdiskdevice"
    #$sim mcm 0 of addprop $chosen_node "string" "bootpath" "/vdevice/bogusdisk@50000000"
    $sim mcm 0 of addprop $chosen_node "string" "bootpath" "tap0"
#    $sim mcm 0 of addprop $chosen_node "string" "bootpath" "/vdevice/v-scsi@30000003/disk@8700000000000000"

    $sim mcm 0 of addprop $chosen_node "string" "bootargs" ""

    puts "Done with device tree extensions for AIX"
}

# Procedure for setting bootargs in /chosen node of OF dev tree
#    "-s trap" causes AIX to drop into KDB
#    "-s debug" causes KDB to be enabled
#    "-s verbose" causes AIX to output extra debug info to the console
proc set_aix_bootargs { bootargs {sim mysim} } {
    set devhandle [$sim mcm 0 of find_device "/chosen"]
    if { $devhandle >= 0 } {
        $sim mcm 0 of setprop $devhandle "bootargs" $bootargs
    }
}

###############################################################
###############################################################
## Special configuration parameters                          ## 
###############################################################
###############################################################

proc Config_For_AIX { {conf myconf} } {

    #Same timebase to CPU clock ratio as Power5
    $conf config processor/timebase_frequency 1/8
    $conf config processor_option/HID_CACHE_INHIBIT FALSE
    $conf config enable_pseries_nvram TRUE

}

#################################################################
#################################################################
## After the machine is created, we need to setup a few things ##
#################################################################
#################################################################

proc aix_patch_hypervisor_emu_assist_intr { args } {
# patch the Hypervisor Emulation Assistance Interrupt vector
# physical addr 0xE40
# the patch will cause an Illegal Instruction Interrupt to be routed
# to the AIX Illegal Instruction Interrupt handler at 0x700

   # This patch will place the following code at 0xE40:
   # 00000E40    7c3243a6    mtspr    SPRG2, r1    # Save r1
   # 00000E44    7c3a4aa6    mfspr    r1, HSRR0    # Get HSRR0
   # 00000E48    7c3a03a6    mtsrr0   r1           # Set SRR0 = HSRR0
   # 00000E4C    7c3b4aa6    mfspr    r1, HSRR1    # Get HSRR1
   # 00000E50    64210008    oris     r1, 8        # Set bit #44
   # 00000E54    7c3b03a6    mtsrr1   r1           # Set SRR1
   # 00000E58    38200700    li       r1, 0x700
   # 00000E5C    7c3a4ba6    mtspr1   HSRR0, r1    # Set HSRR0 to 0x700
   # 00000E60    7c2000a6    mfmsr    r1           # get MSR
   # 00000E64    7c3b4ba6    mtspr    HSRR1, r1    # Set HSRR1 to MSR
   # 00000E68    7c3242a6    mfspr    r1, SPRG2    # Restore r1
   # 00000E6C    4C000224    hrfid                 # Return from interrupt (-> 0x700)
   mysim memory set 0x00000E40    4 0x7c3243a6
   mysim memory set 0x00000E44    4 0x7c3a4aa6
   mysim memory set 0x00000E48    4 0x7c3a03a6
   mysim memory set 0x00000E4C    4 0x7c3b4aa6
   mysim memory set 0x00000E50    4 0x64210008
   mysim memory set 0x00000E54    4 0x7c3b03a6
   mysim memory set 0x00000E58    4 0x38200700
   mysim memory set 0x00000E5C    4 0x7c3a4ba6
   mysim memory set 0x00000E60    4 0x7c2000a6
   mysim memory set 0x00000E64    4 0x7c3b4ba6
   mysim memory set 0x00000E68    4 0x7c3242a6
   mysim memory set 0x00000E6C    4 0x4C000224

   # stop and check if it worked
   # puts "Hit aix_patch_hypervisor_emu_assist_intr trigger @ [mysim display cycles]"
   #simstop

   # one time only... clear the interrupt
   mysim trigger clear pc 0x0E40
}

proc Setup_For_AIX { {sim mysim} } {

    AIX_Update_OF_Tree $sim

    # patch the Hypervisor Emulation Assistance Interrupt vector at 
    # physical addr 0xE40
    # the patch will cause an Illegal Instruction Interrupt to be routed
    # to the AIX Illegal Instruction Interrupt handler at 0x700
    mysim trigger set pc 0x0E40 aix_patch_hypervisor_emu_assist_intr 

}

proc aix_check_boot_files { } {
   global bootdiskfile
   global AIX_KERNEL_FILE
   global AIX_KERNEL_SYMBOL_FILE

    if { ![file readable $bootdiskfile]} {
        puts "Unable to find boot disk image ($bootdiskfile)"
        exit
    }
    if { ![file readable $AIX_KERNEL_FILE]} {
        puts "Unable to find kernel image ($AIX_KERNEL_FILE)"
        exit
    }
    if { ![file readable $AIX_KERNEL_SYMBOL_FILE]} {
        puts "Unable to find kernel symbol image ($AIX_KERNEL_SYMBOL_FILE)"
        exit
    }
    if { [file readable "bootdisk.[pid].cow"] } {
       puts "ERROR: need to delete bootdisk_cow before continuing!\n"
       exit
    }
    if { [file readable "bootdisk.[pid].cow.table"] } {
       puts "ERROR: need to delete bootdisk_cow.table before continuing!\n"
       exit
    }
}

#################################################################
#################################################################
## After the machine is created, run until to the AIX prompt   ##
#################################################################
#################################################################

proc aix_prompt {sim args} {
    array set triginfo $args
    $sim trigger clear console $triginfo(match)
    simstop
}
proc aix_display {sim args} {
    array set triginfo $args
    $sim trigger clear console $triginfo(match)
    $sim trigger set console "root@localhost:" "aix_prompt $sim"
    console_input $sim " "
}
proc aix_root_passwd_again {sim args} {
    array set triginfo $args
    $sim trigger clear console $triginfo(match)
    $sim trigger set console "root@localhost" "aix_prompt $sim"
    console_input $sim "a1passwd"
}
proc aix_root_passwd {sim args} {
    array set triginfo $args
    $sim trigger clear console $triginfo(match)
    $sim trigger set console "Enter the new password again:" "aix_root_passwd_again $sim"
    console_input $sim "a1passwd"
}
proc aix_root_login {sim args} {
    # get rid of trigger
    array set triginfo $args
    $sim trigger clear console $triginfo(match)
    $sim trigger set console "password:"  "aix_root_passwd $sim"
    console_input $sim "root"
}
proc aix_system_console {sim args} {
    # get rid of trigger
    array set triginfo $args
    $sim trigger clear console $triginfo(match)
    $sim trigger set console "Console login:"  "aix_root_login $sim"
    console_input $sim "1"
}
proc wait_for_aix_prompt { {sim mysim} } {
    $sim trigger set console "system console" "aix_system_console $sim"
    $sim go
}
proc aix_root_login_2 {sim args} {
    # get rid of trigger
    array set triginfo $args
    puts "my_aix_root_login"
    $sim trigger clear console $triginfo(match)
    $sim trigger set console "root: :/" "aix_prompt $sim"
    $sim trigger set console "root@localhost:/" "aix_prompt $sim"
    console_input $sim "root"
}
proc aix_system_console_2 {sim args} {
    # get rid of trigger
    array set triginfo $args
    $sim trigger clear console $triginfo(match)
    $sim trigger set console "Console login:"  "aix_root_login_2 $sim"
    console_input $sim "1"
}
proc wait_for_aix_prompt_2 { {sim mysim} } {
    $sim trigger set console "system console" "aix_system_console_2 $sim"
    $sim go
}

proc aix_shell_prompt { {sim args} } {
    $sim trigger set console "root@localhost" "aix_prompt $sim"
    $sim go
}

