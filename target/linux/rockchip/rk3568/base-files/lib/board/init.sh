#!/bin/sh
# based on https://github.com/6ang996/istoreos-rk356x/blob/rk356x/target/linux/rk356x/armv8/base-files/etc/init.d/rename_iface

. /lib/functions.sh

rename_iface() {
    ip link set $1 down && ip link set $1 name $2
}

get_iface_device() {
    basename $(readlink /sys/class/net/$1/device)
}

set_iface_cpumask() {
    local core_mask="$1"
    local interface="$2"
    local device="$3"
    local irq
    local seconds

    [[ -z "${device}" || "${device}" = "${interface}-0" ]] && ip link set dev "${interface}" up

    [[ -z "${device}" ]] && device="$interface"

    for seconds in $(seq 0 2); do
        irq=$(grep -m1 " ${device}\$" /proc/interrupts | sed -n -e 's/^ *\([^ :]\+\):.*$/\1/p')
        if [ -n "${irq}" ]; then
            echo "${core_mask}" > /proc/irq/${irq}/smp_affinity
            return 0
        fi
        sleep 1
    done
}

board_fixup_iface_name() {
    local device
    case $(board_name) in
    fastrhino,r66s)
        device="$(get_iface_device eth0)"
        if [[ "$device" = "0001:11:00.0" ]]; then
            rename_iface eth0 lan1
            rename_iface eth1 eth0
            rename_iface lan1 eth1
        fi
        ;;
    hinlink,opc-h66k)
        device="$(get_iface_device eth1)"
        if [[ "$device" = "0001:11:00.0" ]]; then
            rename_iface eth0 lan1
            rename_iface eth1 eth0
            rename_iface lan1 eth1
        fi
        ;;
    fastrhino,r68s)
        device="$(get_iface_device eth0)"
        if [[ "$device" = "fe010000.ethernet" ]]; then
            rename_iface eth0 wan
            rename_iface eth1 eth0
            rename_iface wan eth1
        fi
        device="$(get_iface_device eth3)"
        if [[ "$device" = "0002:21:00.0" ]]; then
            rename_iface eth2 lan3
            rename_iface eth3 eth2
            rename_iface lan3 eth3
        fi
        ;;
    firefly,rk3568-roc-pc)
        device="$(get_iface_device eth0)"
        if [[ "$device" = "fe010000.ethernet" ]]; then
            rename_iface eth0 wan
            rename_iface eth1 eth0
            rename_iface wan eth1
        fi
        ;;
    friendlyelec,nanopi-r5s)
        device="$(get_iface_device eth2)"
        # r5s lan1 is under pcie2x1
        if [[ "$device" = "0000:01:00.0" ]]; then
            rename_iface eth1 lan2
            rename_iface eth2 eth1
            rename_iface lan2 eth2
        fi
        ;;
    hinlink,opc-h68k)
        device="$(get_iface_device eth1)"
        if [[ "$device" = "fe010000.ethernet" ]]; then
            rename_iface eth0 wan
            rename_iface eth1 eth0
            rename_iface wan eth1
        fi
        device="$(get_iface_device eth3)"
        if [[ "$device" = "0001:11:00.0" ]]; then
            rename_iface eth2 lan3
            rename_iface eth3 eth2
            rename_iface lan3 eth3
        fi
        ;;
    esac
}

board_set_iface_smp_affinity() {
    case $(board_name) in
    firefly,rk3568-roc-pc)
        set_iface_cpumask 2 eth0
        set_iface_cpumask 4 eth1
        ;;
    friendlyelec,nanopi-r5s)
        set_iface_cpumask 2 eth0
        ;;
    fastrhino,r68s|\
    hinlink,opc-h68k)
        set_iface_cpumask 1 "eth0"
        set_iface_cpumask 2 "eth1"
        set_iface_cpumask 4 "eth2" "eth2-0"
        set_iface_cpumask 4 "eth2" "eth2-16"
        set_iface_cpumask 2 "eth2" "eth2-18"
        set_iface_cpumask 8 "eth3" "eth3-0"
        set_iface_cpumask 8 "eth3" "eth3-18"
        set_iface_cpumask 1 "eth3" "eth3-16"
        ;;
    fastrhino,r66s|\
    hinlink,opc-h66k)
        set_iface_cpumask 4 "eth0" "eth0-0"
        set_iface_cpumask 4 "eth0" "eth0-16"
        set_iface_cpumask 2 "eth0" "eth0-18"
        set_iface_cpumask 8 "eth1" "eth1-0"
        set_iface_cpumask 8 "eth1" "eth1-18"
        set_iface_cpumask 1 "eth1" "eth1-16"
        ;;
    esac
}

board_fixup_iface_name

board_set_iface_smp_affinity
