#!/system/bin/sh

# AFWall+ Work Profile Automation Script v3.1
# ============================================
# IMPORTANT: AFWall+ launches TWO instances of this script in parallel
# The locking mechanism ensures only one writes to file while both apply rules
#
# Installation: 
#   mkdir -p /data/local/afw/
#   chmod 755 /data/local/afw/afw.sh
#   AFWall+ custom script: nohup /data/local/afw/afw.sh > /dev/null 2>&1 &
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
LOCK_TIMEOUT=300                   # Seconds before considering lock stale
LOCK_CHECK_FILE="$LOCK_DIR/pid"    # PID file for lock validation

# --- Behavior Switches ---
RUN_PARALLEL=true                  # Allow both instances to apply rules
TARGET_CHAINS="afwall-wifi-wan afwall-3g-home afwall-vpn afwall-3g-roam"

# --- SCRIPT START ---

# Timing helper functions
get_time_ms() {
    # Get time in milliseconds (using date if available, else seconds)
    if date +%s%N >/dev/null 2>&1; then
        echo $(($(date +%s%N) / 1000000))
    else
        echo $(($(date +%s) * 1000))
    fi
}

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

# Start total timer (only read debug flag if file exists)
if [ -f "$UID_FILE" ] && [ "$(head -n 1 "$UID_FILE" 2>/dev/null | cut -d'=' -f2)" = "1" ]; then
    total_start_time=$(get_time_ms)
    log_parse_start=$(get_time_ms)
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
phase1_start_time=$(get_time_ms)
accumulated_data=""
line_counter=0
config_line_count=3  # Skip first 3 config lines

[ "$DEBUG_MODE" -eq 1 ] && echo "[PHASE1] Starting file parse..."

while IFS= read -r line || [ -n "$line" ]; do
    line_counter=$((line_counter + 1))
    if [ "$line_counter" -le "$config_line_count" ]; then continue; fi
    
    # Skip empty lines and pure comment lines
    [ -z "$line" ] && continue
    [ "$(echo "$line" | grep -c '^[[:space:]]*#')" -eq 1 ] && continue
    
    # Trim leading whitespace
    line=$(echo "$line" | sed 's/^[[:space:]]*//')
    
    [ "$DEBUG_MODE" -eq 1 ] && echo "[PARSE] Line $line_counter: $line"
    
    # Parse: first field is UID or package, second is package (if first was UID), rest is custom name
    uid=""; package_name=""; custom_name=""
    
    # Get first field
    field1=$(echo "$line" | awk '{print $1}')
    
    # Check if first field is a UID (all digits)
    if [ -n "$field1" ] && [ -z "$(echo "$field1" | tr -d '0-9')" ]; then
        uid="$field1"
        # Get second field (might be package)
        field2=$(echo "$line" | awk '{print $2}')
        if [ -n "$field2" ] && echo "$field2" | grep -q '\.'; then
            package_name="$field2"
            # Everything after second field is custom name
            custom_name=$(echo "$line" | cut -d' ' -f3-)
        else
            # Second field is part of custom name
            custom_name=$(echo "$line" | cut -d' ' -f2-)
        fi
    elif [ -n "$field1" ] && echo "$field1" | grep -q '\.'; then
        # First field is package name
        package_name="$field1"
        # Everything after first field is custom name
        custom_name=$(echo "$line" | cut -d' ' -f2-)
    else
        [ "$DEBUG_MODE" -eq 1 ] && echo "[PARSE] Skipped invalid line: $line"
        continue
    fi
    
    # Trim whitespace from custom name
    custom_name=$(echo "$custom_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    [ "$DEBUG_MODE" -eq 1 ] && echo "[PARSE] Extracted - UID:[$uid] PKG:[$package_name] NAME:[$custom_name]"
    
    # Store with simple space delimiter (3 spaces to avoid conflicts)
    record="$uid   $package_name   $custom_name"
    accumulated_data="$accumulated_data$record
"
done < "$UID_FILE"

phase1_end_time=$(get_time_ms)
[ "$DEBUG_MODE" -eq 1 ] && echo "[PHASE1] Parse complete. Time: $((phase1_end_time - phase1_start_time)) ms"

# --- PHASE 2: AUGMENT IN-MEMORY DATA (FILL BLANKS) ---
phase2_start_time=$(get_time_ms)
[ "$DEBUG_MODE" -eq 1 ] && echo "[PHASE2] Starting data augmentation..."

completed_data=""
record_count=0

echo "$accumulated_data" | while IFS= read -r record; do
    [ -z "$record" ] && continue
    record_count=$((record_count + 1))
    
    # Parse using 3-space delimiter
    uid=$(echo "$record" | awk -F'   ' '{print $1}')
    package_name=$(echo "$record" | awk -F'   ' '{print $2}')
    custom_name=$(echo "$record" | awk -F'   ' '{print $3}')
    
    [ "$DEBUG_MODE" -eq 1 ] && echo "[AUGMENT] Record $record_count - UID:[$uid] PKG:[$package_name] NAME:[$custom_name]"
    
    pm_call_made=false
    
    if [ -z "$uid" ] && [ -n "$package_name" ]; then
        # Try to get UID from package name
        [ "$DEBUG_MODE" -eq 1 ] && echo "[AUGMENT] Looking up UID for package: $package_name"
        pm_start=$(get_time_ms)
        output=$(pm list packages --user "$TARGET_USER" -U 2>/dev/null | grep -w "$package_name")
        pm_end=$(get_time_ms)
        pm_call_made=true
        [ "$DEBUG_MODE" -eq 1 ] && echo "[AUGMENT] PM call took $((pm_end - pm_start)) ms"
        
        if [ -n "$output" ]; then
            uid=$(echo "$output" | sed 's/.*uid://' | awk '{print $1}')
            [ "$DEBUG_MODE" -eq 1 ] && echo "[AUGMENT] Found UID: $uid"
        fi
    elif [ -n "$uid" ] && [ -z "$package_name" ]; then
        # Try to get package name from UID
        if is_valid_uid "$uid"; then
            [ "$DEBUG_MODE" -eq 1 ] && echo "[AUGMENT] Looking up package for UID: $uid"
            pm_start=$(get_time_ms)
            output=$(pm list packages --user "$TARGET_USER" --uid "$uid" 2>/dev/null)
            pm_end=$(get_time_ms)
            pm_call_made=true
            [ "$DEBUG_MODE" -eq 1 ] && echo "[AUGMENT] PM call took $((pm_end - pm_start)) ms"
            
            if [ -n "$output" ]; then
                package_name=$(echo "$output" | head -n1 | sed 's/package://' | awk '{print $1}')
                [ "$DEBUG_MODE" -eq 1 ] && echo "[AUGMENT] Found package: $package_name"
            fi
        fi
    fi
    
    # Generate a default custom name if empty
    if [ -z "$custom_name" ] && [ -n "$package_name" ]; then
        # Extract app name from package (last component)
        app_name=$(echo "$package_name" | awk -F'.' '{print $NF}')
        # Capitalize first letter
        custom_name=$(echo "$app_name" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
        [ "$DEBUG_MODE" -eq 1 ] && echo "[AUGMENT] Generated custom name: $custom_name"
    fi
    
    new_record="$uid   $package_name   $custom_name"
    completed_data="$completed_data$new_record
"
done > /tmp/augmented_data.$$

completed_data=$(cat /tmp/augmented_data.$$ 2>/dev/null)
rm -f /tmp/augmented_data.$$

phase2_end_time=$(get_time_ms)
[ "$DEBUG_MODE" -eq 1 ] && echo "[PHASE2] Augmentation complete. Time: $((phase2_end_time - phase2_start_time)) ms"

# --- PHASE 3: RECALCULATE MODULE (if enabled) ---
phase3_start_time=$(get_time_ms)

if [ "$RECALCULATE_MODE" -eq 1 ]; then
    [ "$DEBUG_MODE" -eq 1 ] && echo "[PHASE3] Starting UID recalculation..."
    
    recalculated_data=""
    record_count=0
    
    echo "$completed_data" | while IFS= read -r record; do
        [ -z "$record" ] && continue
        record_count=$((record_count + 1))
        
        uid=$(echo "$record" | awk -F'   ' '{print $1}')
        package_name=$(echo "$record" | awk -F'   ' '{print $2}')
        custom_name=$(echo "$record" | awk -F'   ' '{print $3}')
        
        [ "$DEBUG_MODE" -eq 1 ] && echo "[RECALC] Record $record_count - Package: $package_name"
        
        if [ -n "$package_name" ]; then
            pm_start=$(get_time_ms)
            output=$(pm list packages --user "$TARGET_USER" -U 2>/dev/null | grep -w "$package_name")
            pm_end=$(get_time_ms)
            [ "$DEBUG_MODE" -eq 1 ] && echo "[RECALC] PM call took $((pm_end - pm_start)) ms"
            
            if [ -n "$output" ]; then
                new_uid=$(echo "$output" | sed 's/.*uid://' | awk '{print $1}')
                if is_valid_uid "$new_uid"; then
                    [ "$DEBUG_MODE" -eq 1 ] && echo "[RECALC] Updated UID from $uid to $new_uid"
                    uid="$new_uid"
                fi
            fi
        fi
        
        new_record="$uid   $package_name   $custom_name"
        recalculated_data="$recalculated_data$new_record
"
    done > /tmp/recalc_data.$$
    
    completed_data=$(cat /tmp/recalc_data.$$ 2>/dev/null)
    rm -f /tmp/recalc_data.$$
fi

phase3_end_time=$(get_time_ms)
[ "$DEBUG_MODE" -eq 1 ] && [ "$RECALCULATE_MODE" -eq 1 ] && echo "[PHASE3] Recalculation complete. Time: $((phase3_end_time - phase3_start_time)) ms"

# --- PHASE 3.5: SORT DATA ---
sort_start_time=$(get_time_ms)
[ "$DEBUG_MODE" -eq 1 ] && echo "[SORT] Sorting by: $SORT_MODE"

if [ -n "$completed_data" ]; then
    case "$SORT_MODE" in
        uid)
            # Sort by UID numerically (field 1)
            sorted_data=$(echo "$completed_data" | grep -v '^$' | sort -t ' ' -k1,1 -n)
            ;;
        package)
            # Sort by package name alphabetically (field 2)
            sorted_data=$(echo "$completed_data" | grep -v '^$' | awk -F'   ' '{print $2 "   " $0}' | sort | awk -F'   ' '{$1=""; sub(/^   /, ""); print}')
            ;;
        custom|*)
            # Sort by custom name alphabetically (field 3)
            sorted_data=$(echo "$completed_data" | grep -v '^$' | awk -F'   ' '{print $3 "   " $0}' | sort -f | awk -F'   ' '{$1=""; sub(/^   /, ""); print}')
            ;;
    esac
    completed_data="$sorted_data
"
fi

sort_end_time=$(get_time_ms)
[ "$DEBUG_MODE" -eq 1 ] && echo "[SORT] Sorting complete. Time: $((sort_end_time - sort_start_time)) ms"

# --- PHASE 4: APPLY IPTABLES RULES ---
phase4_start_time=$(get_time_ms)

if [ "$DEBUG_MODE" -eq 0 ]; then
    log -p i -t "afwall_custom" "Instance $INSTANCE_ID applying firewall rules..."
    rules_applied=0
    
    echo "$completed_data" | while IFS= read -r record; do
        [ -z "$record" ] && continue
        uid=$(echo "$record" | awk -F'   ' '{print $1}')
        
        if is_valid_uid "$uid"; then
            for chain in $TARGET_CHAINS; do
                $IPTABLES -I "$chain" 1 -m owner --uid-owner "$uid" -j RETURN 2>/dev/null
                $IP6TABLES -I "$chain" 1 -m owner --uid-owner "$uid" -j RETURN 2>/dev/null
            done
            rules_applied=$((rules_applied + 1))
        fi
    done
    
    log -p i -t "afwall_custom" "Instance $INSTANCE_ID applied rules for $rules_applied UIDs"
else
    [ "$DEBUG_MODE" -eq 1 ] && echo "[PHASE4] Skipping iptables in debug mode"
fi

phase4_end_time=$(get_time_ms)
[ "$DEBUG_MODE" -eq 1 ] && echo "[PHASE4] Rules application complete. Time: $((phase4_end_time - phase4_start_time)) ms"

# --- PHASE 5: FINAL EXECUTION (File Write & Debug Report) ---
phase5_start_time=$(get_time_ms)

if [ "$DEBUG_MODE" -eq 1 ]; then
    echo
    echo "[PERFORMANCE REPORT] --- Execution Time per Phase ---"
    echo "[TIME] Phase 1 (Parse File): $((phase1_end_time - phase1_start_time)) ms"
    echo "[TIME] Phase 2 (Augment Data): $((phase2_end_time - phase2_start_time)) ms"
    if [ "$RECALCULATE_MODE" -eq 1 ]; then
        echo "[TIME] Phase 3 (Recalculate UIDs): $((phase3_end_time - phase3_start_time)) ms"
    fi
    echo "[TIME] Phase 3.5 (Sort Data): $((sort_end_time - sort_start_time)) ms"
    echo "[TIME] Phase 4 (Apply Rules): $((phase4_end_time - phase4_start_time)) ms"
    
    echo
    echo "[FINAL REPORT] --- Final State of In-Memory Data (Sorted by $SORT_MODE) ---"
    echo "$completed_data" | while IFS= read -r record; do
        [ -z "$record" ] && continue
        uid=$(echo "$record" | awk -F'   ' '{print $1}')
        package_name=$(echo "$record" | awk -F'   ' '{print $2}')
        custom_name=$(echo "$record" | awk -F'   ' '{print $3}')
        echo "UID:[$uid] PKG:[$package_name] NAME:[$custom_name]"
    done
    
    echo
    echo "[FILE CONTENT PREVIEW] --- This is what uid.txt would look like ---"
    echo "$first_line"
    [ "$RECALCULATE_MODE" -eq 1 ] && echo "recalculate=0" || echo "$second_line"
    echo "$third_line"
    echo "$completed_data" | while IFS= read -r record; do
        [ -z "$record" ] && continue
        uid=$(echo "$record" | awk -F'   ' '{print $1}')
        package_name=$(echo "$record" | awk -F'   ' '{print $2}')
        custom_name=$(echo "$record" | awk -F'   ' '{print $3}')
        
        if [ -n "$custom_name" ]; then
            echo "$uid $package_name $custom_name"
        elif [ -n "$package_name" ]; then
            echo "$uid $package_name"
        else
            echo "$uid"
        fi
    done
    
    echo
    echo "[IPTABLES PREVIEW] --- Commands that would be executed ---"
    rule_count=0
    echo "$completed_data" | while IFS= read -r record; do
        [ -z "$record" ] && continue
        uid=$(echo "$record" | awk -F'   ' '{print $1}')
        if is_valid_uid "$uid"; then
            for chain in $TARGET_CHAINS; do
                echo "$IPTABLES -I \"$chain\" 1 -m owner --uid-owner \"$uid\" -j RETURN"
                echo "$IP6TABLES -I \"$chain\" 1 -m owner --uid-owner \"$uid\" -j RETURN"
            done
            rule_count=$((rule_count + 1))
        fi
    done
    
    total_end_time=$(get_time_ms)
    echo
    echo "[SUMMARY]"
    echo "- Instance PID: $INSTANCE_ID"
    echo "- Has write lock: $HAS_LOCK"
    echo "- Total execution time: $((total_end_time - total_start_time)) ms"
    echo "- Valid entries processed: $(echo "$completed_data" | grep -c '   ')"
    
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
            
            echo "$completed_data" | while IFS= read -r record; do
                [ -z "$record" ] && continue
                uid=$(echo "$record" | awk -F'   ' '{print $1}')
                package_name=$(echo "$record" | awk -F'   ' '{print $2}')
                custom_name=$(echo "$record" | awk -F'   ' '{print $3}')
                
                if [ -n "$uid" ] || [ -n "$package_name" ]; then
                    if [ -n "$custom_name" ]; then
                        echo "$uid $package_name $custom_name"
                    elif [ -n "$package_name" ]; then
                        echo "$uid $package_name"
                    else
                        echo "$uid"
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

phase5_end_time=$(get_time_ms)
[ "$DEBUG_MODE" -eq 1 ] && echo "[PHASE5] File write/report complete. Time: $((phase5_end_time - phase5_start_time)) ms"

# Lock cleanup is handled by trap on exit
