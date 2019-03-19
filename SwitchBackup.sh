#!/bin/bash
###############################################################################
#
# SwitchBackup.sh
#
# Copyright (C) 2018-2019 Darren Young <darren@yhlsecurity.com>
#
################################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
###############################################################################
#
# USAGE:
#
# ssh sw-3-1 "copy run tftp://dns01/test.cfg"
#
###############################################################################
#
# TODO/ISSUES:
# 
###############################################################################


###############################################################################
#                              V A R I A B L E S
###############################################################################
MYNAME=$(basename $0)                           # Our name
DEBUG=""                                        # Set to anything for debug
SSH="/usr/bin/ssh"                              # SSH command location

USE_SYSLOG="true"                               # Set to anything non-null to use
LOGGER="/usr/bin/logger"                        # logger location on disk
PRIORITY="local0.notice"                        # What to set logs to
LOGFILE="/tmp/$MYNAME.log"                      # Physical log file

SWITCHES="sw-3-1"                               # List of switches to backup
BKPHOSTS="dns01 dns02"                          # Hosts to backup to
FAILHOSTS=""                                    # Running failure tally


###############################################################################
#                              F U N C T I O N S
###############################################################################

# I honestly don't remember why I started doing this, leftover ksh memories?
typeset -f logmsg
typeset -f errmsg
typeset -f debug
typeset -f run_command

# -----------------------------------------------------------------------------
#        NAME: logmsg
# DESCRIPTION: Print a log formatted message
#        ARGS: string(message)
#     RETURNS: 0
#      STATUS: Stable 
#       NOTES: logger format: logger -i -p local0.notice -t $NAME <message>
# -----------------------------------------------------------------------------
function logmsg() {
    if [[ -z "$1" ]]
    then
        errmsg "Usage: logmsg <message>"
        return 0
    else
        local MESSAGE=$1

        # Log to syslog if set to do so using the logger command
        # TODO: add error detection/correction on the command
        if [[ ! -z $USE_SYSLOG ]]; then
            local CMD="$LOGGER -i -p $PRIORITY -t $MYNAME $MESSAGE"
            debug "CMD: $CMD"
            ${CMD}
        fi

        # If there's a logfile defined, log to it
        # otherwise send to STDOUT (>&1)
        if [[ ! -z $LOGFILE ]]; then
            local NOW=`date +"%b %d %Y %T"`
            echo $NOW $1 >> $LOGFILE
        else
            local NOW=`date +"%b %d %Y %T"`
            >&1 echo "$NOW $MESSAGE"
            return 0
        fi
    fi
}

# -----------------------------------------------------------------------------
#        NAME: errmsg
# DESCRIPTION: Print an error message to stderr and the log file
#        ARGS: string(message)
#     RETURNS: 0 or 1
#      STATUS: Stable
#       NOTES: 
# -----------------------------------------------------------------------------
function errmsg() {
    if [[ -z "$1" ]]; then
        >&2 echo "Usage: errmsg <message>"
        return 0
    else

        # Print to both STDERR and the logmsg dest
        >&2 echo "ERROR: $1"
        logmsg "ERROR: $1"
        return 1
    fi
}

# -----------------------------------------------------------------------------
#        NAME: debug
# DESCRIPTION: Print a debug message
#        ARGS: string(message)
#     RETURNS: 0 or 1
#      STATUS: Stable
#       NOTES: 
# -----------------------------------------------------------------------------
function debug() {
    if [[ -z "$1" ]]
    then
        errmsg "Usage: debug <message>"
        return 0
    else
        if [ "$DEBUG" == "true" ]
        then
            local message="$1"
            logmsg "DEBUG: $message"
            return 1
        else
            return 1
        fi
    fi
}

# -----------------------------------------------------------------------------
#        NAME: run_command
# DESCRIPTION: Run an OS command (safely)
#        ARGS: string(command)
#     RETURNS: 0 or 1
#      STATUS: Under Development
#       NOTES: 
# -----------------------------------------------------------------------------
function run_command() {
    debug "${FUNCNAME[0]}: entering"

    if [[ -z "$1" ]]
    then
        errmsg "Usage: run_command <command>"
        return 0
    else
        local CMD="$1"
        debug "CMD: $CMD"
        RET=$($CMD >> $LOGFILE 2>>$LOGFILE)
        RETVAL=$?

        debug "return: $RET"
        debug "retval: $RETVAL"

        if [[ $RETVAL != 0 ]]; then
            logmsg "Failed to run command"
            return 0
        else
            debug "SUCCESS"
            return 1
    fi
        return 1
    fi
}


###############################################################################
#                                   M A I N
###############################################################################

# Remove the log file if it's there
if [[ -f $LOGFILE ]]; then
	rm -f $LOGFILE
fi

logmsg "Starting on $(hostname)"

# Iterate through the list of switches and back them up
for switch in $SWITCHES; do
    logmsg "Backing up $switch"
    BKPFILE="$switch.cnf.$(date +%m%d%y-%H%M)"      # Name of the backup file

    # Iterate through the backup hosts and do it
    for host in $BKPHOSTS; do
        logmsg "Backing up $BKPFILE to $host"

        ${SSH} sw-3-1 copy running-config tftp://$host/$BKPFILE >> $LOGFILE 2>&1
        RETVAL=$?
        if [[ $RETVAL != 0 ]]; then
            logmsg "Backup to $host failed" 
            FAILHOSTS="$FAILHOSTS $host"
        else
            logmsg "Backup to $host successful" 
        fi
    done
done


# If the running failure tally is non-null, log that message
if [[ ! -z $FAILHOSTS ]]; then
    logmsg "The following hosts failed as backup targets: $FAILHOSTS"
fi

logmsg "Done, buh bye"
exit 0








###############################################################################
#                         S E C T I O N   T E M P L A T E
###############################################################################

# -----------------------------------------------------------------------------
#        NAME: function_template
# DESCRIPTION: 
#        ARGS: 
#     RETURNS: 
#      STATUS: 
#       NOTES: 
# -----------------------------------------------------------------------------
