#!/bin/bash

# Set PATH explicitly (adjust as needed)
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Define the log file
LOG_FILE="/var/log/availability_test.log"

# Define the logging option
LOGGING="YES"  # Set to "NO" to disable logging

# Function to log messages
log_message() {
    if [ "$LOGGING" == "YES" ]; then
        echo "$1" >> "$LOG_FILE"
    fi
}

# Define the IP address to ping
IP_ADDRESS="YOUR_IP_ADDRESS"

# Define the trunk name
TRUNK_NAME="YOUR_TRUNK_NAME"

# Get the current timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Get the trunk number
TRUNK_NUMBER=$(fwconsole trunks --list | grep "$TRUNK_NAME" | awk -F '|' '{gsub(/^ +| +$/, "", $2); print $2}')
log_message "$TIMESTAMP - Trunk number for $TRUNK_NAME is $TRUNK_NUMBER"

# Function to check the status of trunk
check_trunk_status() {
    /usr/sbin/fwconsole trunks --list | grep "$TRUNK_NAME" | awk -F '|' '{gsub(/^ +| +$/, "", $5); print $5}'
}

# Get the current trunk status
TRUNK_STATUS=$(check_trunk_status)

# Log the raw trunk status output for debugging
log_message "$TIMESTAMP - Raw trunk status output for trunk $TRUNK_NUMBER: $TRUNK_STATUS"

# Interpret the trunk status
if [ "$TRUNK_STATUS" == "off" ]; then
    TRUNK_STATUS_READABLE="enabled"
else
    TRUNK_STATUS_READABLE="disabled"
fi

# Log the interpreted trunk status
log_message "$TIMESTAMP - Current status of trunk $TRUNK_NUMBER: $TRUNK_STATUS_READABLE"

# Perform 10 pings to the specified IP address
PING_RESULT=$(ping -c 10 $IP_ADDRESS)

# Check the exit status of the ping command
if [ $? -eq 0 ]; then
    # Ping was successful
    log_message "$TIMESTAMP - Ping OK"
    
    # Only disable the trunk if it is currently enabled
    if [ "$TRUNK_STATUS" == "off" ]; then
        log_message "$TIMESTAMP - Trunk $TRUNK_NAME is currently enabled. Disabling it."
        TRUNK_DISABLE_OUTPUT=$(/usr/sbin/fwconsole trunk --disable $TRUNK_NUMBER 2>&1)
        log_message "$TIMESTAMP - /usr/sbin/fwconsole trunk --disable $TRUNK_NUMBER output:"
        log_message "$TRUNK_DISABLE_OUTPUT"
        # Run the command to reload the configuration
        RELOAD_OUTPUT=$(/usr/sbin/fwconsole reload 2>&1)
        log_message "$TIMESTAMP - /usr/sbin/fwconsole reload output:"
        log_message "$RELOAD_OUTPUT"
    else
        log_message "$TIMESTAMP - Trunk $TRUNK_NUMBER is already disabled. No action taken."
    fi
else
    # Ping failed
    log_message "$TIMESTAMP - Ping to $IP_ADDRESS failed. Output:"
    log_message "$PING_RESULT"
    
    # Only enable the trunk if it is currently disabled
    if [ "$TRUNK_STATUS" == "on" ]; then
        log_message "$TIMESTAMP - Trunk $TRUNK_NUMBER is currently disabled. Enabling it."
        TRUNK_ENABLE_OUTPUT=$(/usr/sbin/fwconsole trunk --enable $TRUNK_NUMBER 2>&1)
        log_message "$TIMESTAMP - /usr/sbin/fwconsole trunk --enable $TRUNK_NUMBER output:"
        log_message "$TRUNK_ENABLE_OUTPUT"

        # Run the command to reload the configuration
        RELOAD_OUTPUT=$(/usr/sbin/fwconsole reload 2>&1)
        log_message "$TIMESTAMP - /usr/sbin/fwconsole reload output:"
        log_message "$RELOAD_OUTPUT"
    else
        log_message "$TIMESTAMP - Trunk $TRUNK_NUMBER is already enabled. No action taken."
    fi
fi
