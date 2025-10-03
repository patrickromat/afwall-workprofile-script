#!/system/bin/sh

# add custom script: nohup /data/local/afw/afw.sh > /dev/null 2>&1 &
# chmod 755 /data/local/afw/afw.sh
# create uid.txt in /sdcard/afw/uid.txt
# first line (debug run or true runs): debug=0
# second line (it will recalculate package names into UIDs: recalculate=0

# - This script is SILENT when debug=0.

# --- CONFIGURATION ---
IPTABLES=/system/bin/iptables
IP6TABLES=/system/bin/ip6tables
UID_FILE="/sdcard/afw/uid.txt"
TEMP_FILE="/sdcard/afw/uid.txt.tmp" # Temporary file for safe editing
LOCK_DIR="/sdcard/afw/script.lock" # Lock directory
TARGET_USER="10"                   # Search ONLY in the Work Profile (user 10)
DELIMITER='|'                      # Internal separator for in-memory data

# --- Behavior Switches ---
RUN_PARALLEL=false
TARGET_CHAINS="afwall-wifi-wan afwall-3g-home afwall-vpn afwall-3g-roam"

# --- SCRIPT START ---

# Start total timer only if in debug mode
if [ "$(head -n 1 "$UID_FILE" 2>/dev/null | cut -d'=' -f2)" -eq 1 ]; then
    total_start_time=$(date +%s%N)
fi

# --- PHASE 0: ATOMIC LOCK ACQUISITION ---
#-------------------------------------------------
HAS_LOCK=false
if mkdir "$LOCK_DIR" 2>/dev/null; then
    HAS_LOCK=true
    trap 'rmdir "$LOCK_DIR"' EXIT
else
    :
fi

# 1. PRE-RUN CHECKS AND MODE DETECTION
#-------------------------------------------------
DEBUG_MODE=0
RECALCULATE_MODE=0

if [ ! -f "$UID_FILE" ]; then
    if [ "$DEBUG_MODE" -eq 1 ]; then
        echo "[ERROR] Config file not found at $UID_FILE"
    else
        log -p e -t "afwall_custom_script" "Config file not found at $UID_FILE. Exiting."
    fi
    exit 1
fi

first_line=$(head -n 1 "$UID_FILE")
if [ "$(echo "$first_line" | cut -d'=' -f1)" = "debug" ]; then
    debug_value=$(echo "$first_line" | cut -d'=' -f2)
    [ "$debug_value" -eq 1 ] && DEBUG_MODE=1
fi

second_line=$(sed -n '2p' "$UID_FILE")
if [ "$(echo "$second_line" | cut -d'=' -f1)" = "recalculate" ]; then
    recalc_value=$(echo "$second_line" | cut -d'=' -f2)
    [ "$recalc_value" -eq 1 ] && RECALCULATE_MODE=1
fi

if [ "$RUN_PARALLEL" = "false" ] && [ "$HAS_LOCK" = "false" ]; then
    if [ "$DEBUG_MODE" -eq 1 ]; then
        echo "[LOCK-ABORT] RUN_PARALLEL is false and lock is taken. Exiting gracefully."
    else
        log -p w -t "afwall_custom_script" "Lock detected and RUN_PARALLEL is false. Aborting this instance. PID: $$"
    fi
    exit 0
fi

if [ "$DEBUG_MODE" -eq 1 ]; then
    if [ "$HAS_LOCK" = "true" ]; then
        echo "[LOCK] Lock acquired. This instance will write to file."
    else
        echo "[LOCK-WARN] Another instance is running. This instance will NOT write to file."
    fi
fi

# --- PHASE 1: PARSE CONFIG FILE INTO MEMORY ---
#-------------------------------------------------
[ "$DEBUG_MODE" -eq 1 ] && phase1_start_time=$(date +%s%N)
accumulated_data=""
line_counter=0
while IFS= read -r line || [ -n "$line" ]; do
    line_counter=$((line_counter + 1)); if [ "$line_counter" -le 2 ]; then continue; fi
    if [ -z "$line" ] || [ "$(echo "$line" | cut -c1)" = "#" ]; then continue; fi
    item1=$(echo "$line" | awk '{print $1}'); item2=$(echo "$line" | awk '{print $2}')
    uid=""; package_name=""; comments=""
    if [ -z "$(echo "$item1" | tr -d '0-9')" ]; then
        uid="$item1"
        if [ -n "$item2" ] && echo "$item2" | grep -q "\."; then
            package_name="$item2"; comments=$(echo "$line" | awk '{$1=$2=""; print $0}' | sed 's/^ *//')
        else
            comments=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
        fi
    elif echo "$item1" | grep -q "\."; then
        package_name="$item1"; comments=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
    else
        continue
    fi
    record="$uid$DELIMITER$package_name$DELIMITER$comments"; accumulated_data="$accumulated_data$record
"
done < "$UID_FILE"
[ "$DEBUG_MODE" -eq 1 ] && phase1_end_time=$(date +%s%N)


# --- PHASE 2: AUGMENT IN-MEMORY DATA (FILL BLANKS) ---
#-------------------------------------------------
[ "$DEBUG_MODE" -eq 1 ] && phase2_start_time=$(date +%s%N)
completed_data=""
while IFS= read -r record; do
    if [ -z "$record" ]; then continue; fi
    uid=$(echo "$record" | cut -d"$DELIMITER" -f1); package_name=$(echo "$record" | cut -d"$DELIMITER" -f2); comment=$(echo "$record" | cut -d"$DELIMITER" -f3-)
    if [ -z "$uid" ] && [ -n "$package_name" ]; then
        output=$(pm list packages --user "$TARGET_USER" -U | grep -w "$package_name"); [ -n "$output" ] && uid=$(echo "$output" | cut -d ':' -f 3)
    elif [ -n "$uid" ] && [ -z "$package_name" ]; then
        output=$(pm list packages --user "$TARGET_USER" --uid "$uid"); [ -n "$output" ] && package_name=$(echo "$output" | head -n1 | awk -F'[: ]' '{print $2}')
    fi
    new_record="$uid$DELIMITER$package_name$DELIMITER$comment"; completed_data="$completed_data$new_record
"
done <<< "$accumulated_data"
[ "$DEBUG_MODE" -eq 1 ] && phase2_end_time=$(date +%s%N)


# --- PHASE 3: RECALCULATE MODULE (if enabled) ---
#-------------------------------------------------
[ "$DEBUG_MODE" -eq 1 ] && phase3_start_time=$(date +%s%N)
if [ "$RECALCULATE_MODE" -eq 1 ]; then
    recalculated_data=""
    while IFS= read -r record; do
        if [ -z "$record" ]; then continue; fi
        uid=$(echo "$record" | cut -d"$DELIMITER" -f1); package_name=$(echo "$record" | cut -d"$DELIMITER" -f2); comment=$(echo "$record" | cut -d"$DELIMITER" -f3-)
        if [ -n "$package_name" ]; then
            output=$(pm list packages --user "$TARGET_USER" -U | grep -w "$package_name")
            if [ -n "$output" ]; then new_uid=$(echo "$output" | cut -d ':' -f 3); uid="$new_uid"; fi
        fi
        new_record="$uid$DELIMITER$package_name$DELIMITER$comment"; recalculated_data="$recalculated_data$new_record
"
    done <<< "$completed_data"
    completed_data="$recalculated_data"
fi
[ "$DEBUG_MODE" -eq 1 ] && phase3_end_time=$(date +%s%N)


# --- PHASE 3.5: SORT BY CUSTOM NAME ---
#-------------------------------------------------
[ "$DEBUG_MODE" -eq 1 ] && sort_start_time=$(date +%s%N)
if [ -n "$completed_data" ]; then
    # Sort by custom name (field 3) alphabetically, case-insensitive
    sorted_data=$(printf "%s" "$completed_data" | awk -F"$DELIMITER" '{if (NF >= 3 && $0 != "") print $3 "|" $0}' | LC_ALL=C sort -f | cut -d'|' -f2-)
    completed_data="$sorted_data"
fi
[ "$DEBUG_MODE" -eq 1 ] && sort_end_time=$(date +%s%N)


# --- PHASE 4: APPLY IPTABLES RULES ---
#---------------------------------------------------------------------
if [ "$DEBUG_MODE" -eq 0 ]; then
    log -p i -t "afwall_custom_script" "Phase 4: Applying final firewall rules..."
    printf "%s" "$completed_data" | while IFS= read -r record; do
        if [ -z "$record" ]; then continue; fi
        uid=$(echo "$record" | cut -d"$DELIMITER" -f1)
        if [ -n "$uid" ]; then
            for chain in $TARGET_CHAINS; do
                $IPTABLES -I "$chain" -m owner --uid-owner "$uid" -j RETURN
                $IP6TABLES -I "$chain" -m owner --uid-owner "$uid" -j RETURN
            done
        fi
    done
    log -p i -t "afwall_custom_script" "Final rules applied. Proceeding to file write."
fi


# --- PHASE 5: FINAL EXECUTION (File Write & Debug Report) ---
#-------------------------------------------------

if [ "$DEBUG_MODE" -eq 1 ]; then
    # --- DEBUG MODE: Print all reports ---
    echo; echo "[PERFORMANCE REPORT] --- Execution Time per Phase ---"
    echo "[TIME] Phase 1 (Parse File): $((($phase1_end_time - $phase1_start_time) / 1000000)) ms"
    echo "[TIME] Phase 2 (Augment Data): $((($phase2_end_time - $phase2_start_time) / 1000000)) ms"
    if [ "$RECALCULATE_MODE" -eq 1 ]; then
        echo "[TIME] Phase 3 (Recalculate UIDs): $((($phase3_end_time - $phase3_start_time) / 1000000)) ms"
    fi
    echo "[TIME] Phase 3.5 (Sort by Custom Name): $((($sort_end_time - $sort_start_time) / 1000000)) ms"
    
    report_start_time=$(date +%s%N)
    echo; echo "[FINAL REPORT] --- Final State of In-Memory Data (Sorted by Custom Name) ---"
    printf "%s" "$completed_data" | while IFS= read -r record; do if [ -z "$record" ]; then continue; fi; uid=$(echo "$record" | cut -d"$DELIMITER" -f1); package_name=$(echo "$record" | cut -d"$DELIMITER" -f2); comment=$(echo "$record" | cut -d"$DELIMITER" -f3-); echo "UID:[$uid] PKG:[$package_name] COMMENT:[$comment]"; done
    
    echo; echo "[FILE CONTENT PREVIEW] --- This is what uid.txt would look like ---"
    echo "$first_line"; [ "$RECALCULATE_MODE" -eq 1 ] && echo "recalculate=0" || echo "$second_line"
    printf "%s" "$completed_data" | while IFS= read -r record; do if [ -z "$record" ]; then continue; fi; uid=$(echo "$record" | cut -d"$DELIMITER" -f1); package_name=$(echo "$record" | cut -d"$DELIMITER" -f2); comment=$(echo "$record" | cut -d"$DELIMITER" -f3-); processed_line="$uid $package_name $comment"; echo "$processed_line" | sed 's/^ *//;s/ *$//'; done
    
    echo; echo "[IPTABLES PREVIEW (FINAL)] --- Based on completed data ---"
    printf "%s" "$completed_data" | while IFS= read -r record; do
        if [ -z "$record" ]; then continue; fi; uid=$(echo "$record" | cut -d"$DELIMITER" -f1)
        if [ -n "$uid" ]; then
            for chain in $TARGET_CHAINS; do
                echo "$IPTABLES -I \"$chain\" -m owner --uid-owner \"$uid\" -j RETURN"
                echo "$IP6TABLES -I \"$chain\" -m owner --uid-owner \"$uid\" -j RETURN"
            done
        fi
    done
    report_end_time=$(date +%s%N)

    echo; echo "[PERFORMANCE REPORT] --- Final Timers ---"
    echo "[TIME] Phase 5 (Generate All Reports): $((($report_end_time - $report_start_time) / 1000000)) ms"
    total_end_time=$(date +%s%N)
    echo "[TIME] Total Script Execution Time: $((($total_end_time - $total_start_time) / 1000000)) ms"
    echo "[FINAL REPORT] --- End of All Previews ---"

else
    # --- NORMAL MODE: Rebuild file ---
    
    if [ "$HAS_LOCK" = "true" ]; then
        echo "$first_line" > "$TEMP_FILE"
        if [ "$RECALCULATE_MODE" -eq 1 ]; then
            log -p i -t "afwall_custom_script" "Recalculate mode was enabled. Resetting flag."
            echo "recalculate=0" >> "$TEMP_FILE"
        else
            echo "$second_line" >> "$TEMP_FILE"
        fi
        printf "%s" "$completed_data" | while IFS= read -r record; do if [ -z "$record" ]; then continue; fi; uid=$(echo "$record" | cut -d"$DELIMITER" -f1); package_name=$(echo "$record" | cut -d"$DELIMITER" -f2); comment=$(echo "$record" | cut -d"$DELIMITER" -f3-); processed_line="$uid $package_name $comment"; echo "$processed_line" | sed 's/^ *//;s/ *$//' >> "$TEMP_FILE"; done
        log -p i -t "afwall_custom_script" "Phase 5: Config file rebuilt successfully. Sorted by custom name."
        mv "$TEMP_FILE" "$UID_FILE"
    else
        log -p w -t "afwall_custom_script" "Lock not held. Skipping file write."
    fi
    
    log -p i -t "afwall_custom_script" "Script run finished. PID: $$"
fi
