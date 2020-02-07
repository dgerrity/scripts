#!/usr/bin/env bash
###############################################################################
# 
# ec - emacs client - a direct way to invoke the GUI version of emacs as a
# client.
#
# $Id: ec-v 1.2 2013-07-31 14:24:58-07 dan Exp $
#
###############################################################################

set -e
alias emacsclient="/Applications/Emacs.app/Contents/MacOS/bin/emacsclient"
export ALTERNATE_EDITOR=""

if [[ $# -eq 0 ]]; then
    # Emacs doesn't activate itself when there is no filename provided.
    emacsclient -n -c &
    sleep 0.1
    osascript -e "tell application \"Emacs\" to activate"
    wait
else
    emacsclient -n -c "$@"
fi
