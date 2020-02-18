#!/usr/bin/env bash
###############################################################################
#
# .bashrc on Mac OS X Darwin bash is called at every invocation of bash, 
# including subshells executed under this users name. It's
# main purpose is to set paths and environment variables necessary
# for subshell execution.  Functions and aliases used in login sessions
# should really be put into .bash_profile since that file is loaded at login.
#
# Neither profile should use "echo" as this can really screw things up on a
# remote login (even when redirected)
#
# $Id: .bashrc-v 1.29 2014-01-11 22:19:06-08 dan Exp dan $
#
###############################################################################

# Definitions
rcrev="$(echo '$Revision: 1.29 $' | sed -e 's/\$//g' -e 's/ $//')"
whorang="$(/usr/bin/basename "$(ps -p $PPID -o command= | sed -e 's/^[-.]//' -e 's#/bin/bash ##')")"
if [[ -d "${HOME}/logs" ]]; then logdir="${HOME}/logs"
elif [[ -d "${HOME}/Library/Logs" ]]; then logdir="${HOME}/Library/Logs"
elif [[ -d "/Users/dan/logs" ]]; then logdir="/Users/dan/logs"
else logdir="${HOME}"
fi
export logdir
export lf="${logdir}/com.centvc.log"

function cbasename() { echo $(/usr/bin/basename $(echo "${*}" | sed 's/^-//')); }
function log() {
    [[ "${whorang:0:5}" == "login" ]] && let shlvl=0 || let shlvl=${SHLVL}-1
    sp=$(printf "%$((${shlvl}*4))s" " ")
    echo "$(date "+%Y-%m-%d %H:%M:%S")${sp}$(cbasename $0) $@" >> "${lf}"
}

[[ -d "${HOME}/bin" ]]   && [[ ! "${PATH}" =~ "${HOME}/bin" ]] && PATH="${HOME}/bin:${PATH}"
[[ -d /usr/local/sbin ]] && [[ ! "${PATH}" =~ /usr/local/sbin ]] && PATH="${PATH}:/usr/local/sbin"
[[ -d /Applications/Postgres.app ]] && export PATH="${PATH}:/Applications/Postgres.app/Contents/Versions/9.4/bin"
export PATH

export DISPLAY=:0.0   
export daapport=3689
export rsyncport=873
export LC_ALL="en_US.UTF-8"
export homessid="kpp-dual"
export aptname="Wi-Fi"
export aptdev=en0
export vpndev=utun2;
export proxyport=34343
export proxy=97.113.238.244
export daapserver=sierra.dnsdojo.com
export GIT_CRYPT=yes
export EDITOR=emacs

# Default addresses for important machines 
# for i in romeo sierra cookie tango deltagolf zulu; do export "${i}"="${i}.dnsdojo.com"; done
case "$(hostname -s)" in
    romeo)   export daapserver=sierra.dnsdojo.com; export vpndev=utun1 aptdev=en1;;
    sierra)  export proxy=romeo.dnsdojo.com; export proxyport=34345; aptdev=en1;;
    *);;
esac
export $(hostname -s | sed -e 's/[- ]/_/g' -e 's/[()]//g')="$(hostname)"

[[ -e "${HOME}/.bash_env" ]] && source "${HOME}/.bash_env"
