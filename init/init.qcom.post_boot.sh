#! /vendor/bin/sh

# CPU SM8550 walt governor tweaks
# =========================
# central value definitions
# =========================

CPU0_NODES="
adaptive_high_freq=1110000
adaptive_high_freq_kernel=1100000
adaptive_low_freq=307200
adaptive_low_freq_kernel=0
down_rate_limit_us=300
cpu0_volt_margin_pct=0
cpu0_eff_limit=0
hispeed_freq=1105000
hispeed_load=20
pl=0
rtg_boost_freq=1000000
target_load_shift=15
target_load_thresh=0
up_delay_freq=1836000
up_rate_limit_us=0
"

CPU3_NODES="
adaptive_high_freq=768000
adaptive_high_freq_kernel=768000
adaptive_low_freq=0
adaptive_low_freq_kernel=0
down_rate_limit_us=300
cpu3_volt_margin_pct=32
cpu3_eff_limit=2150400
hispeed_freq=878000
hispeed_load=90
pl=1
rtg_boost_freq=900000
target_load_shift=777
target_load_thresh=886790
up_delay_freq=0
up_rate_limit_us=0
"

CPU7_NODES="
adaptive_high_freq=768000
adaptive_high_freq_kernel=768000
adaptive_low_freq=0
adaptive_low_freq_kernel=0
down_rate_limit_us=300
cpu3_volt_margin_pct=38
cpu3_eff_limit=2723400
hispeed_freq=886790
hispeed_load=90
pl=1
rtg_boost_freq=900000
target_load_shift=777
target_load_thresh=886790
up_delay_freq=0
up_rate_limit_us=0
"


# scaling minimum frequencies
CPU0_MIN_FREQ=307300
CPU5_MIN_FREQ=729600
CPU7_MIN_FREQ=595000

# VM tuning
SWAPPINESS=30
VFS_CACHE_PRESSURE=50

# cpuset restriction
RESTRICTED_CPUSET="5-7"

# =========================
# setter with verification
# =========================

set_and_verify() {
    NODE="$1"
    VAL="$2"
    MAX_RETRIES=5
    RETRY=0

    while [ ! -e "$NODE" ]; do
        sleep 1
        RETRY=$((RETRY + 1))
        [ "$RETRY" -ge 5 ] && return 1
    done

    RETRY=0
    while [ "$RETRY" -lt "$MAX_RETRIES" ]; do
        chmod 666 "$NODE" 2>/dev/null
        echo "$VAL" > "$NODE" 2>/dev/null

        CUR="$(cat "$NODE" 2>/dev/null | tr -d ' \t\r\n')"
        CLEAN_VAL="$(echo "$VAL" | tr -d ' \t\r\n')"

        if [ "$CUR" = "$CLEAN_VAL" ]; then
            break
        fi

        RETRY=$((RETRY + 1))
        sleep 1
    done
}

# =========================
# apply helper
# =========================

apply_cpu() {
    CPU="$1"
    LIST="$2"

    echo "$LIST" | while IFS='=' read -r KEY VAL; do
        KEY="$(echo "$KEY" | tr -d ' \t\r\n')"
        VAL="$(echo "$VAL" | tr -d ' \t\r\n')"

        [ -z "$KEY" ] && continue

        set_and_verify "/sys/devices/system/cpu/${CPU}/cpufreq/superwalt/${KEY}" "$VAL"
    done
}

# =========================
# cpuset special handler (hard lock)
# =========================

apply_cpuset_locked() {
    NODE="/dev/cpuset/restricted/cpus"
    RETRY=0

    while [ ! -e "$NODE" ]; do
        sleep 1
        RETRY=$((RETRY + 1))
        [ "$RETRY" -ge 5 ] && return 1
    done

    chmod 666 "$NODE" 2>/dev/null
    echo "$RESTRICTED_CPUSET" > "$NODE" 2>/dev/null
    chmod 0440 "$NODE" 2>/dev/null
}

# =========================
# apply
# =========================

sleep 2

# set vm swappiness & vfs_cache_pressure
set_and_verify "/proc/sys/vm/swappiness" "$SWAPPINESS"
set_and_verify "/proc/sys/vm/vfs_cache_pressure" "$VFS_CACHE_PRESSURE"

# set scaling governor to superwalt first
set_and_verify "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" "superwalt"
set_and_verify "/sys/devices/system/cpu/cpu3/cpufreq/scaling_governor" "superwalt"
set_and_verify "/sys/devices/system/cpu/cpu7/cpufreq/scaling_governor" "superwalt"

# apply WALT governor settings
apply_cpu cpu0 "$CPU0_NODES"
apply_cpu cpu3 "$CPU3_NODES"
apply_cpu cpu7 "$CPU7_NODES"

# apply scaling minimum frequencies
echo "$CPU0_MIN_FREQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null
echo "$CPU5_MIN_FREQ" > /sys/devices/system/cpu/cpu5/cpufreq/scaling_min_freq 2>/dev/null
echo "$CPU7_MIN_FREQ" > /sys/devices/system/cpu/cpu7/cpufreq/scaling_min_freq 2>/dev/null

# cpuset anwenden
apply_cpuset_locked

# End of CPU walt governor tweaks

G=/sys/devices/system/cpu/cpufreq/policy0/superwalt
 
echo 4800000 > $G/ddr_temp_45
echo 4224000 > $G/ddr_temp_58
echo 3686000 > $G/ddr_temp_61
echo 3686000 > $G/ddr_temp_62
echo 2736000 > $G/ddr_temp_63
echo 1555000 > $G/ddr_temp_70
 
echo 4800000       > $G/ddr_bat_100
echo 4224000       > $G/ddr_bat_70
echo 3686000 > $G/ddr_bat_50
echo 2736000 > $G/ddr_bat_30
echo 1555000 > $G/ddr_bat_20
echo 547000 > $G/ddr_bat_10
 
echo 547000 > $G/ddr_screen_off
 
cat $G/ddr_cap_applied
cat /sys/devices/system/cpu/bus_dcvs/DDR/cur_freq
