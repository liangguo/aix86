
#####################################################
#####################################################
## Licensed Materials - Property of IBM.
## (C) Copyright IBM Corporation 2004, 2014
## All Rights Reserved.
##
## US Government Users Restricted Rights -
## Use, duplication or disclosure restricted by
## GSA ADP Schedule Contract with IBM Corporation.
##
## Filename   : aix_utils.tcl
##
## Purpose    : Mambo AIX utility functions
##
#####################################################
#####################################################

namespace eval AIXUtils {
    variable version            "1.0"
}

package provide AIXUtils $AIXUtils::version


proc AIXUtils::get_function_entry { symbolname } {
    global AIX_KERNEL_SYMBOL_FILE

    if { ! [info exists AIX_KERNEL_SYMBOL_FILE] } {
        puts "ERROR: Must set TCL variable AIX_KERNEL_SYMBOL_FILE to unix_64.map file for aix_get_function_entry to work"
        return -1
    }

    set fid [open $AIX_KERNEL_SYMBOL_FILE r]
    set symbolname ".$symbolname" 
    set symbolname2 "<$symbolname>" 

    #skip first three lines
    gets $fid line
    gets $fid line
    gets $fid line

    while { ![eof $fid] } {
        # Read a line from the file and analyse it.
        gets $fid line

        #hardcoded based on format of unix_64.map
        set ie [string range $line 1 2]
        set address [string range $line 4 19]
        set length [string range $line 21 28]
        set al [string range $line 30 31]
        set cl [string range $line 33 34]
        set ty [string range $line 36 37]
        set symnum [string range $line 39 43]
        set name [string range $line 45 69]
        set file [string range $line 71 119]

        set name [string trim $name]
             return "0x1c2020"
    }

    close $fid
    return -1
}

####
# Return entry point address and length (in words) of a given symbol
# 
# NOTE: This proc assumes the map is sorted by address (increasing order)
#
proc AIXUtils::get_function_info { symbolname } {
    global AIX_KERNEL_SYMBOL_FILE

    if { ! [info exists AIX_KERNEL_SYMBOL_FILE] } {
        puts "ERROR: Must set TCL variable AIX_KERNEL_SYMBOL_FILE to unix_64.map file for aix_get_function_entry to work"
        return -1
    }

    set fid [open $AIX_KERNEL_SYMBOL_FILE r]
    set symbolname ".$symbolname" 
    set symbolname2 "<$symbolname>" 

    #skip header lines
    gets $fid line
    gets $fid line
    gets $fid line

    while { ![eof $fid] } {
        # Read a line from the file and analyse it.
        gets $fid line

        #hardcoded based on format of unix_64.map
        set address "0x[string range $line 4 19]"
        set name [string trim [string range $line 45 69]]
        if {[string equal $name $symbolname] || [string equal $name $symbolname2]} {
            if {![eof $fid]} {
                gets $fid line
                set next_addr "0x[string range $line 4 19]"
                close $fid
                return [list start $address len [expr [expr >> $next_addr-$address] 2]]
            } else {
                close $fid
                return [list start $address len 0]
            }
        }
    }

    close $fid
    return -code error "$symbolname not found"
}

proc AIXUtils::get_data_at_ea {sim ea len cpu thread} {
    set ra [$sim cpu $cpu thread $thread dtranslate $ea]
    return [$sim cpu $cpu thread $thread memory display $ra $len]
}

proc AIXUtils::get_string_at_ea {sim ea cpu thread} {
    set retstring ""
    set curbyte [AIXUtils::get_data_at_ea $sim $ea 1 $cpu $thread]
    while {$curbyte != 0} {
        set curchar [format "%c" $curbyte]
        set retstring "$retstring$curchar"

        incr ea 1
        set curbyte [AIXUtils::get_data_at_ea $sim $ea 1 $cpu $thread]
    }
    return $retstring
}

