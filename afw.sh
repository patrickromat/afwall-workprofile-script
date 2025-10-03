#!/system/bin/sh

# AFWall+ Work Profile Automation Script v3.0
# ============================================
# IMPORTANT: AFWall+ launches TWO instances of this script in parallel
# The locking mechanism ensures only one writes to file while both apply rules
#
# Installation: 
#   chmod 755 /data/local/afw.sh
#   AFWall+ custom script: nohup /data/local/afw.sh > /dev/null 2>&1 &
#
# Configuration file: /sdcard/afw/uid.txt
#   Line 1: debug=0 (or debug=1 for verbose output)
#   Line 2: recalculate=0 (or recalculate=1 to refresh all UIDs)
#   Line 3: sort_by=custom (or sort_by=uid or sort_by=package)
#   Line 4+: Your app entries

# --- CONFIGURATION ---
IPTABLES=/system/bin/iptables
IP6TABLES=/system/bin/ip6tables
UID_FILE="/sdcard/afw/uid.txt"
TEMP_FILE="/sdcard/afw/uid.txt.tmp"
LOCK_DIR="/sdcard/afw/script.lock"
TARGET_USER="10"                   # Work Profile user ID
DELIMITER='§'                      # Safe delimiter (won't conflict with package names)
LOCK_TIMEOUT=300                   # Seconds before considering lock stale
LOCK_CHECK_FILE="$LOCK_DIR/pid"    # PID file for lock validation

# --- Behavior Switches ---
RUN_PARALLEL=true                  # Allow both instances to apply rules
TARGET_CHAINS="afwall-wifi-wan afwall-3g-home afwall-vpn afwall-3g-roam"

# --- SCRIPT START ---

# Function to check if a process is still running
is_process_running() {
    local pid=$1
    [ -d "/proc/$pid" ] && return 0 || return 1
}

# Function to clean stale locks
cleanup_stale_lock() {
    if [ -d "$LOCK_DIR" ]; then
        if [ -f "$LOCK_CHECK_FILE" ]; then
            lock_pid=$(cat "$LOCK_CHECK_FILE" 2>/dev/null)
            if [ -n "$lock_pid" ]; then
                if ! is_process_running "$lock_pid"; then
                    # Process is dead, remove stale lock
                    rm -rf "$LOCK_DIR" 2>/dev/null
                    return 0
                fi
            fi
        fi
        # Check age of lock directory
        lock_age=$(($(date +%s) - $(stat -c %Y "$LOCK_DIR" 2>/dev/null || echo 0)))
        if [ "$lock_age" -gt "$LOCK_TIMEOUT" ]; then
            rm -rf "$LOCK_DIR" 2>/dev/null
            return 0
        fi
    fi
    return 1
}

# Function to validate UID is numeric
is_valid_uid() {
    local uid=$1
    [ -n "$uid" ] && [ "$uid" -eq "$uid" ] 2>/dev/null && return 0 || return 1
}

# Clean up any stale locks first
cleanup_stale_lock

# Start total timer only if in debug mode (check before file exists validation)
if [ -f "$UID_FILE" ] && [ "$(head -n 1 "$UID_FILE" 2>/dev/null | cut -d'=' -f2)" = "1" ]; then
    total_start_time=$(date +%s%N)
fi

# --- PHASE 0: ATOMIC LOCK ACQUISITION ---
HAS_LOCK=false
INSTANCE_ID=$$
if mkdir "$LOCK_DIR" 2>/dev/null; then
    HAS_LOCK=true
    echo "$INSTANCE_ID" > "$LOCK_CHECK_FILE"
    trap 'rm -rf "$LOCK_DIR"' EXIT INT TERM
fi

# 1. PRE-RUN CHECKS AND MODE DETECTION
DEBUG_MODE=0
RECALCULATE_MODE=0
SORT_MODE="custom"  # Default sort by custom name

if [ ! -f "$UID_FILE" ]; then
    if [ "$DEBUG_MODE" -eq 1 ]; then
        echo "[ERROR] Config file not found at $UID_FILE"
    else
        log -p e -t "afwall_custom" "Config file not found at $UID_FILE. Exiting."
    fi
    exit 1
fi

# Parse configuration lines
first_line=$(head -n 1 "$UID_FILE")
if [ "$(echo "$first_line" | cut -d'=' -f1)" = "debug" ]; then
    debug_value=$(echo "$first_line" | cut -d'=' -f2)
    [ "$debug_value" = "1" ] && DEBUG_MODE=1
fi

second_line=$(sed -n '2p' "$UID_FILE")
if [ "$(echo "$second_line" | cut -d'=' -f1)" = "recalculate" ]; then
    recalc_value=$(echo "$second_line" | cut -d'=' -f2)
    [ "$recalc_value" = "1" ] && RECALCULATE_MODE=1
fi

third_line=$(sed -n '3p' "$UID_FILE")
if [ "$(echo "$third_line" | cut -d'=' -f1)" = "sort_by" ]; then
    SORT_MODE=$(echo "$third_line" | cut -d'=' -f2)
    # Validate sort mode
    case "$SORT_MODE" in
        uid|package|custom) ;;
        *) SORT_MODE="custom" ;;
    esac
fi

# Log instance information
if [ "$DEBUG_MODE" -eq 1 ]; then
    echo "[INSTANCE] PID: $INSTANCE_ID"
    if [ "$HAS_LOCK" = "true" ]; then
        echo "[LOCK] Lock acquired. This instance ($$) will write to file."
    else
        # Check who has the lock
        if [ -f "$LOCK_CHECK_FILE" ]; then
            other_pid=$(cat "$LOCK_CHECK_FILE")
            echo "[LOCK-INFO] Another instance ($other_pid) holds the lock. This instance will only apply rules."
        else
            echo "[LOCK-WARN] Lock exists but no PID file. This instance will only apply rules."
        fi
    fi
    echo "[CONFIG] Sort mode: $SORT_MODE"
fi

# --- PHASE 1: PARSE CONFIG FILE INTO MEMORY ---
[ "$DEBUG_MODE" -eq 1 ] && phase1_start_time=$(date +%s%N)
accumulated_data=""
line_counter=0
config_line_count=3  # Skip first 3 config lines

while IFS= read -r line || [ -n "$line" ]; do
    line_counter=$((line_counter + 1))
    if [ "$line_counter" -le "$config_line_count" ]; then continue; fi
    # Skip empty lines and pure comment lines
    if [ -z "$line" ] || [ "$(echo "$line" | grep -c '^[[:space:]]*#')" -eq 1 ]; then continue; fi
    
    # Parse the line - everything after package/UID is the custom name
    item1=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]].*//')
    rest_of_line=$(echo "$line" | sed "s/^[[:space:]]*$item1[[:space:]]*//")
    
    uid=""; package_name=""; custom_name=""
    
    # Check if item1 is a UID (all digits)
    if [ -z "$(echo "$item1" | tr -d '0-9')" ] && [ -n "$item1" ]; then
        uid="$item1"
        # Check if next item is a package name
        item2=$(echo "$rest_of_line" | sed 's/^[[:space:]]*//;s/[[:space:]].*//')
        if [ -n "$item2" ] && echo "$item2" | grep -q "\."; then
            package_name="$item2"
            # Everything after package is the custom name
            custom_name=$(echo "$rest_of_line" | sed "s/^[[:space:]]*$item2[[:space:]]*//")
        else
            # Everything after UID is the custom name
            custom_name="$rest_of_line"
        fi
    elif echo "$item1" | grep -q "\."; then
        # First item is a package name
        package_name="$item1"
        # Everything after is the custom name
        custom_name="$rest_of_line"
    else
        continue
    fi
    
    # Clean up custom name - just trim whitespace, no comment removal
    custom_name=$(echo "$custom_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    record="$uid$DELIMITER$package_name$DELIMITER$custom_name"
    accumulated_data="$accumulated_data$record
"
done < "$UID_FILE"
[ "$DEBUG_MODE" -eq 1 ] && phase1_end_time=$(date +%s%N)

# --- PHASE 2: AUGMENT IN-MEMORY DATA (FILL BLANKS) ---
[ "$DEBUG_MODE" -eq 1 ] && phase2_start_time=$(date +%s%N)
completed_data=""
while IFS= read -r record; do
    if [ -z "$record" ]; then continue; fi
    uid=$(echo "$record" | cut -d"$DELIMITER" -f1)
    package_name=$(echo "$record" | cut -d"$DELIMITER" -f2)
    custom_name=$(echo "$record" | cut -d"$DELIMITER" -f3-)
    
    if [ -z "$uid" ] && [ -n "$package_name" ]; then
        # Try to get UID from package name
        output=$(pm list packages --user "$TARGET_USER" -U 2>/dev/null | grep -w "$package_name")
        if [ -n "$output" ]; then
            uid=$(echo "$output" | sed 's/.*uid://' | cut -d' ' -f1)
        fi
    elif [ -n "$uid" ] && [ -z "$package_name" ]; then
        # Try to get package name from UID
        if is_valid_uid "$uid"; then
            output=$(pm list packages --user "$TARGET_USER" --uid "$uid" 2>/dev/null)
            if [ -n "$output" ]; then
                package_name=$(echo "$output" | head -n1 | sed 's/package://' | cut -d' ' -f1)
            fi
        fi
    fi
    
    # Generate a default custom name if empty
    if [ -z "$custom_name" ] && [ -n "$package_name" ]; then
        # Extract app name from package (last component)
        app_name=$(echo "$package_name" | rev | cut -d'.' -f1 | rev)
        # Capitalize first letter
        custom_name=$(echo "$app_name" | sed 's/^./\U&/')
    fi
    
    new_record="$uid$DELIMITER$package_name$DELIMITER$custom_name"
    completed_data="$completed_data$new_record
"
done <<< "$accumulated_data"
[ "$DEBUG_MODE" -eq 1 ] && phase2_end_time=$(date +%s%N)

# --- PHASE 3: RECALCULATE MODULE (if enabled) ---
[ "$DEBUG_MODE" -eq 1 ] && phase3_start_time=$(date +%s%N)
if [ "$RECALCULATE_MODE" -eq 1 ]; then
    recalculated_data=""
    while IFS= read -r record; do
        if [ -z "$record" ]; then continue; fi
        uid=$(echo "$record" | cut -d"$DELIMITER" -f1)
        package_name=$(echo "$record" | cut -d"$DELIMITER" -f2)
        custom_name=$(echo "$record" | cut -d"$DELIMITER" -f3-)
        
        if [ -n "$package_name" ]; then
            output=$(pm list packages --user "$TARGET_USER" -U 2>/dev/null | grep -w "$package_name")
            if [ -n "$output" ]; then
                new_uid=$(echo "$output" | sed 's/.*uid://' | cut -d' ' -f1)
                if is_valid_uid "$new_uid"; then
                    uid="$new_uid"
                fi
            fi
        fi
        new_record="$uid$DELIMITER$package_name$DELIMITER$custom_name"
        recalculated_data="$recalculated_data$new_record
"
    done <<< "$completed_data"
    completed_data="$recalculated_data"
fi
[ "$DEBUG_MODE" -eq 1 ] && phase3_end_time=$(date +%s%N)

# --- PHASE 3.5: SORT DATA ---
[ "$DEBUG_MODE" -eq 1 ] && sort_start_time=$(date +%s%N)
if [ -n "$completed_data" ]; then
    case "$SORT_MODE" in
        uid)
            # Sort by UID numerically
            sorted_data=$(echo "$completed_data" | grep -v '^$' | sort -t"$DELIMITER" -k1 -n)
            ;;
        package)
            # Sort by package name alphabetically
            sorted_data=$(echo "$completed_data" | grep -v '^$' | sort -t"$DELIMITER" -k2)
            ;;
        custom|*)
            # Sort by custom name alphabetically (default)
            sorted_data=$(echo "$completed_data" | grep -v '^$' | sort -t"$DELIMITER" -k3)
            ;;
    esac
    completed_data="$sorted_data
"
fi
[ "$DEBUG_MODE" -eq 1 ] && sort_end_time=$(date +%s%N)

# --- PHASE 4: APPLY IPTABLES RULES ---
if [ "$DEBUG_MODE" -eq 0 ]; then
    log -p i -t "afwall_custom" "Instance $INSTANCE_ID applying firewall rules..."
    rules_applied=0
    printf "%s" "$completed_data" | while IFS= read -r record; do
        if [ -z "$record" ]; then continue; fi
        uid=$(echo "$record" | cut -d"$DELIMITER" -f1)
        
        if is_valid_uid "$uid"; then
            for chain in $TARGET_CHAINS; do
                $IPTABLES -I "$chain" 1 -m owner --uid-owner "$uid" -j RETURN 2>/dev/null
                $IP6TABLES -I "$chain" 1 -m owner --uid-owner "$uid" -j RETURN 2>/dev/null
            done
            rules_applied=$((rules_applied + 1))
        fi
    done
    log -p i -t "afwall_custom" "Instance $INSTANCE_ID applied rules for $rules_applied UIDs"
fi

# --- PHASE 5: FINAL EXECUTION (File Write & Debug Report) ---
if [ "$DEBUG_MODE" -eq 1 ]; then
    echo
    echo "[PERFORMANCE REPORT] --- Execution Time per Phase ---"
    echo "[TIME] Phase 1 (Parse File): $((($phase1_end_time - $phase1_start_time) / 1000000)) ms"
    echo "[TIME] Phase 2 (Augment Data): $((($phase2_end_time - $phase2_start_time) / 1000000)) ms"
    if [ "$RECALCULATE_MODE" -eq 1 ]; then
        echo "[TIME] Phase 3 (Recalculate UIDs): $((($phase3_end_time - $phase3_start_time) / 1000000)) ms"
    fi
    echo "[TIME] Phase 3.5 (Sort Data): $((($sort_end_time - $sort_start_time) / 1000000)) ms"
    
    echo
    echo "[FINAL REPORT] --- Final State of In-Memory Data (Sorted by $SORT_MODE) ---"
    printf "%s" "$completed_data" | while IFS= read -r record; do
        if [ -z "$record" ]; then continue; fi
        uid=$(echo "$record" | cut -d"$DELIMITER" -f1)
        package_name=$(echo "$record" | cut -d"$DELIMITER" -f2)
        custom_name=$(echo "$record" | cut -d"$DELIMITER" -f3-)
        echo "UID:[$uid] PKG:[$package_name] NAME:[$custom_name]"
    done
    
    echo
    echo "[FILE CONTENT PREVIEW] --- This is what uid.txt would look like ---"
    echo "$first_line"
    [ "$RECALCULATE_MODE" -eq 1 ] && echo "recalculate=0" || echo "$second_line"
    echo "$third_line"
    printf "%s" "$completed_data" | while IFS= read -r record; do
        if [ -z "$record" ]; then continue; fi
        uid=$(echo "$record" | cut -d"$DELIMITER" -f1)
        package_name=$(echo "$record" | cut -d"$DELIMITER" -f2)
        custom_name=$(echo "$record" | cut -d"$DELIMITER" -f3-)
        if [ -n "$custom_name" ]; then
            processed_line="$uid $package_name $custom_name"
        else
            processed_line="$uid $package_name"
        fi
        echo "$processed_line" | sed 's/[[:space:]]*$//'
    done
    
    echo
    echo "[IPTABLES PREVIEW] --- Commands that would be executed ---"
    rule_count=0
    printf "%s" "$completed_data" | while IFS= read -r record; do
        if [ -z "$record" ]; then continue; fi
        uid=$(echo "$record" | cut -d"$DELIMITER" -f1)
        if is_valid_uid "$uid"; then
            for chain in $TARGET_CHAINS; do
                echo "$IPTABLES -I \"$chain\" 1 -m owner --uid-owner \"$uid\" -j RETURN"
                echo "$IP6TABLES -I \"$chain\" 1 -m owner --uid-owner \"$uid\" -j RETURN"
            done
            rule_count=$((rule_count + 1))
        fi
    done
    
    total_end_time=$(date +%s%N)
    echo
    echo "[SUMMARY]"
    echo "- Instance PID: $INSTANCE_ID"
    echo "- Has write lock: $HAS_LOCK"
    echo "- Total execution time: $((($total_end_time - $total_start_time) / 1000000)) ms"
    echo "- Valid entries processed: $(echo "$completed_data" | grep -c "$DELIMITER")"
    
else
    # --- PRODUCTION MODE: Write file if we have the lock ---
    if [ "$HAS_LOCK" = "true" ]; then
        # Build new file content
        {
            echo "$first_line"
            [ "$RECALCULATE_MODE" -eq 1 ] && echo "recalculate=0" || echo "$second_line"
            echo "$third_line"
            echo "# ============================================"
            echo "# AFWall+ Work Profile App List (Auto-sorted by $SORT_MODE)"
            echo "# Last updated: $(date '+%Y-%m-%d %H:%M:%S')"
            echo "# ============================================"
            
            printf "%s" "$completed_data" | while IFS= read -r record; do
                if [ -z "$record" ]; then continue; fi
                uid=$(echo "$record" | cut -d"$DELIMITER" -f1)
                package_name=$(echo "$record" | cut -d"$DELIMITER" -f2)
                custom_name=$(echo "$record" | cut -d"$DELIMITER" -f3-)
                
                if [ -n "$uid" ] || [ -n "$package_name" ]; then
                    if [ -n "$custom_name" ]; then
                        echo "$uid $package_name $custom_name"
                    else
                        echo "$uid $package_name"
                    fi
                fi
            done
        } > "$TEMP_FILE"
        
        # Atomic move
        mv "$TEMP_FILE" "$UID_FILE" 2>/dev/null
        log -p i -t "afwall_custom" "Instance $INSTANCE_ID updated uid.txt (sorted by $SORT_MODE)"
        
        if [ "$RECALCULATE_MODE" -eq 1 ]; then
            log -p i -t "afwall_custom" "Recalculation complete - UIDs refreshed"
        fi
    else
        log -p i -t "afwall_custom" "Instance $INSTANCE_ID completed (no file write - other instance handles it)"
    fi
fi

# Lock cleanup is handled by trap on exit