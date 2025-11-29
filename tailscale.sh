#!/usr/bin/env bash

config_file="$HOME/.config/waybar/tailscale/config.json"

# Read config
flags=$(jq -r '.["tailscale-up-flags"] | join(" ")' "$config_file")

# Display 'Connected' and 'Disconnected'
display_text=$(jq -r '.["display-connection-status"]' "$config_file")

if [ "$display_text" = true ]; then
    display_class="-text"
else
    display_class=""
fi


# Get the status output
status=$(tailscale status 2>&1)

if [[ "$status" =~ "Tailscale is stopped" ]] || echo "$status" | grep -q "Logged out"; then
    status_val='state-0'
    tool_tip='Stopped'
else
    status_val='state-1'
    tool_tip=$(tailscale status | awk '$NF == "-" {print $1}')
fi

if [ "$1" = "toggle" ]; then
    if [ "$status_val" = "state-0" ]; then
        # Run tailscale up and capture in a temp file
	
	if echo "$status" | grep -q "Logged out"; then
	    url=$(echo "$status" | grep -oP 'https?://[^\s]+')
	    
	    ACTION_RESULT=$(notify-send --action="open=${url}" "Tailscale" "Click here to login. Then try again." -t 5000)

	    # 3. Handle the returned action
	    case "$ACTION_RESULT" in
		"open")
	        xdg-open "$url"
	        echo "{\"class\": \"$status_val$display_class\", \"text\": \"$( [ "$display_text" = "true" ] && echo "Disconnected" || echo "  " )\", \"tooltip\": \"$tool_tip\"}"
		;;
	    *)
		# Handle timeout or dismissal
	        # echo "Notification dismissed or timed out."
	        echo "{\"class\": \"$status_val$display_class\", \"text\": \"$( [ "$display_text" = "true" ] && echo "Disconnected" || echo "  " )\", \"tooltip\": \"$tool_tip\"}"
		;;
	    esac
	    exit 1
	fi
	# Capture standard output, will not work if 'sudo tailscale set --operator=$USER' not run
	output=$(tailscale up $flags 2>&1)

	# Check if the output contains "Access denied"
	if echo "$output" | grep -q "Access denied"; then
	    notify-send "$(echo '$output' | sed 's/,/,\n/')"
	    # Optional: exit with a non-zero status
	    echo "{\"class\": \"$status_val$display_class\", \"text\": \"$( [ "$display_text" = "true" ] && echo "Disconnected" || echo "  " )\", \"tooltip\": \"$tool_tip\"}"
	    exit 1
	elif echo "$output" | grep -q "Logged Out"; then
	    notify-send "$output"
	    # Optional: exit with a non-zero status 
	    echo "{\"class\": \"$status_val$display_class\", \"text\": \"$( [ "$display_text" = "true" ] && echo "Disconnected" || echo "  " )\", \"tooltip\": \"$tool_tip\"}"
	    exit 1
	else
	    status_val='state-1'
	fi
    else
	output=$(tailscale down 2>&1)
	
	if echo "$output" | grep -q "Access denied"; then
	    (notify-send "Tailscale Error" "$(sed '/To not require root/ s/,/,\n/' <<<"$output")")# notify-send "$output"
	    # Optional: exit with a non-zero status
	    echo "{\"class\": \"$status_val$display_class\", \"text\": \"$( [ "$display_text" = "true" ] && echo "Disconnected" || echo "  " )\", \"tooltip\": \"$tool_tip\"}"
	    exit 1
	fi

	status_val='state-0'
    fi
fi

# Refresh status after toggle
final_status=$(tailscale status 2>&1)

if [[ "$final_status" =~ "Tailscale is stopped" ]] || echo "$final_status" | grep -q "Logged out"; then
    status_val='state-0'
    tool_tip='Stopped'
else
    status_val='state-1'    
    tool_tip=$(tailscale status | awk '$NF == "-" {print $1}')
fi


# Output JSON for Waybar
echo "{\"class\": \"$status_val$display_class\", \"text\": \"$( [ "$display_text" = "true" ] && echo $( [ "$status_val" = "state-0" ] && echo "Disconnected" || echo "Connected" ) || echo "  " )\", \"tooltip\": \"$tool_tip\"}"


