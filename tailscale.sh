#!/usr/bin/env bash

flags_file="$HOME/.config/waybar/tailscale/tailscale_up_flags.txt"

# Read flags, skipping comments and blank lines
mapfile -t ARGS < <(grep -vE '^\s*#' "$flags_file" | sed '/^\s*$/d')

# Get the status output
status=$(tailscale status 2>&1)

if [[ "$status" =~ "Tailscale is stopped" ]] || echo "$status" | grep -q "Logged out"; then
    status_val=0
else
    status_val=1
fi

if [ "$1" = "toggle" ]; then
    if [ "$status_val" = "0" ]; then
        # Run tailscale up and capture in a temp file
	
	if echo "$status" | grep -q "Logged out"; then
	    url=$(echo "$status" | grep -oP 'https?://[^\s]+')
	    
	    ACTION_RESULT=$(notify-send --action="open=${url}" "Tailscale" "Click here to login. Then try again." -t 5000)

	    # 3. Handle the returned action
	    case "$ACTION_RESULT" in
		"open")
	        xdg-open "$url"
	        echo "{\"class\": \"state-$status_val\", \"text\": \"Disconnected\"}"
		;;
	    *)
		# Handle timeout or dismissal
	        # echo "Notification dismissed or timed out."
	        echo "{\"class\": \"state-$status_val\", \"text\": \"Disconnected\"}"
		;;
	    esac
	    exit 1
	fi
	# Capture standard output, will not work if 'sudo tailscale set --operator=$USER' not run
	output=$(tailscale up "${ARGS[@]}" 2>&1)

	# Check if the output contains "Access denied"
	if echo "$output" | grep -q "Access denied"; then
	    notify-send "$(echo '$output' | sed 's/,/,\n/')"
	    # Optional: exit with a non-zero status
	    echo "{\"class\": \"state-$status_val\", \"text\": \"Disconnected\"}"
	    exit 1
	elif echo "$output" | grep -q "Logged Out"; then
	    notify-send "$output"
	    # Optional: exit with a non-zero status 
	    echo "{\"class\": \"state-$status_val\", \"text\": \"Disconnected\"}"
	    exit 1
	else
	    status_val=1
	fi
    else
	output=$(tailscale down 2>&1)
	
	if echo "$output" | grep -q "Access denied"; then
	    (notify-send "Tailscale Error" "$(sed '/To not require root/ s/,/,\n/' <<<"$output")")# notify-send "$output"
	    # Optional: exit with a non-zero status
	    echo "{\"class\": \"state-$status_val\", \"text\": \"Disconnected\"}"
	    exit 1
	fi

	status_val=0
    fi
fi

# Refresh status after toggle
final_status=$(tailscale status 2>&1)

if [[ "$final_status" =~ "Tailscale is stopped" ]] || echo "$final_status" | grep -q "Logged out"; then
    status_val=0
    connected="Disconnected"
else
    status_val=1
    connected="Connected"
fi


# Output JSON for Waybar
echo "{\"class\": \"state-$status_val\", \"text\": \"$connected\"}"


