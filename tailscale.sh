#!/usr/bin/env bash

# Declare file locations
module_location="$HOME/.config/waybar/tailscale"
config_file="$module_location/config.json"

# Read config
flags=$(jq -r '.["tailscale-up-flags"] | join(" ")' "$config_file")
display_text=$(jq -r '.["display-connection-status"]' "$config_file")
auth_timeout=$(jq -r '.["auth-timeout"]' "$config_file") # In seconds

if [ "$display_text" = true ]; then
    display_class="-text"
else
    display_class=""
fi

check_status() {
    status_json=$(tailscale status --json 2>&1)
    ts_status=$(echo "$status_json" | jq -r '.BackendState')
    
    if [[ "$ts_status" == "Stopped" ]]; then
	status_text='Disconnected'
	status_val='state-0'
        tool_tip='Stopped'
    elif [[ "$ts_status" == "NeedsLogin" ]]; then
        status_text='Logged Out'
        status_val='state-0'
        tool_tip='Click to login'
    else
	status_text='Connected'
        status_val='state-1'
	tool_tip=$(tailscale status --json | jq -r '.TailscaleIPs[0]')
    fi
}


if [[ "$1" == "toggle" ]]; then

    status_json=$(tailscale status --json 2>&1)
    ts_status=$(echo "$status_json" | jq -r '.BackendState')

    operator=$(tailscale debug prefs | jq 'has("OperatorUser")')
    if [[ "$operator" = false ]]; then
	if ! sudo tailscale set --operator="$USER"; then
	    (notify-send "Tailscale Error" "tailscale rule not present in sudoers.\nOperator must be set via CLI\n Run 'sudo tailscale set --operator=$USER'")
	    exit 1
	fi
    fi
    if [[ "$ts_status" == "NeedsLogin" ]]; then
        # Run tailscale up to create auth url
	tailscale up $flags >/dev/null 2>&1 &

	# Wait for the auth url to generate
	sleep 2
	auth_url=$(tailscale status --json | jq -r '.AuthURL')

	xdg-open "$auth_url"

    elif [[ "$ts_status" == "Running" ]]; then
	# Capture standard output, will not work if 'sudo tailscale set --operator=$USER' not run
	tailscale down 2>&1
    elif [[ "$ts_status" == "Stopped" ]]; then
	# Capture standard output, will not work if 'sudo tailscale set --operator=$USER' not run
	tailscale up $flags 2>&1
    fi
    
    check_status

elif [[ "$1" == "status" ]]; then
    check_status
fi


# Output for waybar

echo "{\"class\": \"$status_val$display_class\", \"text\": \"$( [ "$display_text" = "true" ] && echo "$status_text" || echo "  " )\", \"tooltip\": \"$tool_tip\"}"

