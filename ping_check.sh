#!/bin/bash

# Define the log file
LOG_FILE="/var/log/availability_test.log"

# Define the IP address to ping
IP_ADDRESS="INSERT_YOUR_IP_ADDRESS"

# Define the trunk name
TRUNK_NAME="800"

# Get the current timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Function to check the status of the specified trunk
check_trunk_status() {
    /usr/sbin/fwconsole trunks --list | grep "$TRUNK_NAME" | awk -F '|' '{gsub(/^ +| +$/, "", $5); print $5}'
}

# Get the current trunk status
TRUNK_STATUS=$(check_trunk_status)

# Log the raw trunk status output for debugging
echo "$TIMESTAMP - Raw trunk status output for trunk $TRUNK_NAME: $TRUNK_STATUS" >> $LOG_FILE

# Interpret the trunk status
if [ "$TRUNK_STATUS" == "off" ]; then
    TRUNK_STATUS_READABLE="enabled"
else
    TRUNK_STATUS_READABLE="disabled"
fi

# Log the interpreted trunk status
echo "$TIMESTAMP - Current status of trunk $TRUNK_NAME: $TRUNK_STATUS_READABLE" >> $LOG_FILE

# Perform 10 pings to the specified IP address
PING_RESULT=$(ping -c 10 $IP_ADDRESS)

# Check the exit status of the ping command
if [ $? -eq 0 ]; then
    # Ping was successful
    echo "$TIMESTAMP - OK" >> $LOG_FILE
    
    # Only disable the trunk if it is currently enabled
    if [ "$TRUNK_STATUS" == "off" ]; then
        echo "$TIMESTAMP - Trunk $TRUNK_NAME is currently enabled. Disabling it." >> $LOG_FILE
        TRUNK_DISABLE_OUTPUT=$(/usr/sbin/fwconsole trunk --disable "$TRUNK_NAME" 2>&1)
        echo "$TIMESTAMP - /usr/sbin/fwconsole trunk --disable $TRUNK_NAME output:" >> $LOG_FILE
        echo "$TRUNK_DISABLE_OUTPUT" >> $LOG_FILE
        # Run the command to reload the configuration
        RELOAD_OUTPUT=$(/usr/sbin/fwconsole reload 2>&1)
        echo "$TIMESTAMP - /usr/sbin/fwconsole reload output:" >> $LOG_FILE
        echo "$RELOAD_OUTPUT" >> $LOG_FILE
    else
        echo "$TIMESTAMP - Trunk $TRUNK_NAME is already disabled. No action taken." >> $LOG_FILE
    fi
else
    # Ping failed
    echo "$TIMESTAMP - Ping to $IP_ADDRESS failed. Output:" >> $LOG_FILE
    echo "$PING_RESULT" >> $LOG_FILE
    
    # Only enable the trunk if it is currently disabled
    if [ "$TRUNK_STATUS" == "on" ]; then
        echo "$TIMESTAMP - Trunk $TRUNK_NAME is currently disabled. Enabling it." >> $LOG_FILE
        TRUNK_ENABLE_OUTPUT=$(/usr/sbin/fwconsole trunk --enable "$TRUNK_NAME" 2>&1)
        echo "$TIMESTAMP - /usr/sbin/fwconsole trunk --enable $TRUNK_NAME output:" >> $LOG_FILE
        echo "$TRUNK_ENABLE_OUTPUT" >> $LOG_FILE

        # Run the command to reload the configuration
        RELOAD_OUTPUT=$(/usr/sbin/fwconsole reload 2>&1)
        echo "$TIMESTAMP - /usr/sbin/fwconsole reload output:" >> $LOG_FILE
        echo "$RELOAD_OUTPUT" >> $LOG_FILE
    else
        echo "$TIMESTAMP - Trunk $TRUNK_NAME is already enabled. No action taken." >> $LOG_FILE
    fi

    # Comment this line out in production
    # echo "$TIMESTAMP - The fwconsole reload command should be disabled in production." >> $LOG_FILE
fi
