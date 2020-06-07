#!/usr/bin/env bash
###############################################################################
#
# get-ad-list - returns names of availability domains for the given region
#
###############################################################################

args="${@}"

function usage() {
#   Displays usage information
    enter $FUNCNAME $LINENO "$@"
    echo "${me} version ${version}"; echo
    [[ "${1}" == "version" ]] && exit 1
    echo "${me} shows a list of availability domains available in a given region."
    echo "Usage: ${me} [options]"; echo
    echo "Optons"
    echo "  -v           Verbose"
    echo "  -d           Debug"
    echo "  -c           OCI Compartment OCID (defaults to environment OCI_COMPARMENT_PROD)"
    echo "  -r           OCI Region long name (defaults to environmentOCI_REGION)"
    echo
    [[ "${1}" == help ]] && exit 1
    exit 1
}

###############################################################################
# Functions
###############################################################################

# Debugging, logging, and message routines.
function enter() {
#   Call at the entry of each function for debugging purposes: enter $FUNCNAME $LINENO "$@"
    [[ ! ${o_debug} ]] && return 0
    ln=${2}; fn=${1}; shift; shift;
    printf "Line %3s, %s" ${ln} ${fn}
    [[ "$@" ]] && echo -en "( $(echo "$@" | sed 's/ /, /g') )"
    echo
}

function vecho()   { [[ ${o_verbose} ]] && echo "${*}";        }
function vechonr() { [[ ${o_verbose} ]] && echo -en "${*}";    }
function decho()   { [[ ${o_debug}   ]] && echo "${*}";        }
function don()     { [[ ${o_debug}   ]] && set -x;             }
function doff()    { [[ ${o_debug}   ]] && set +x;             }

function cbasename() { echo $(/usr/bin/basename $(echo "${*}" | sed 's/^-//')); }
function clog() {
    [[ "${whorang:0:5}" == "login" ]] && let shlvl=0 || let shlvl=${SHLVL}-1
    sp=$(printf "%$((${shlvl}*4))s" " ")
    echo "$(date "+%Y-%m-%d %H:%M:%S")${sp}$(cbasename $0) $@" >> "${lf}"
}

function mainprog() {
    enter ${FUNCNAME} ${LINENO} ${@}
    export available_ads="$(oci iam availability-domain list --region ${o_region} --compartment-id ${o_compartment} | jq -r .data[].name)"
    echo "Available ADs in this region: ${available_ads}"
    export available_shapes="$(oci limits value list --service-name compute --all | \
    	   jq -r .data[].name | grep vm | sort | uniq | tr '-' '.' | tr "mv" "MV" | sed 's/\.s\(.*\).count/\.S\1/')"
    echo "Available shapes in this region: ${available_shapes}"
    echo "Get shape types with non-zero limits"
    export available_shapes="$(oci limits value list --service-name compute --all | \
    	   jq -r .data[].name | grep vm | sort | uniq | tr '-' '.' | tr "mv" "MV" | sed 's/\.s\(.*\).count/\.S\1/')"
    echo "${available_shapes}" | tr ' ' '\n'
    micro=$(echo ${available_shapes} | grep -i micro)
    if [[ ${micro} ]]; then
	echo "it appears that micros are available in ${o_region}"
    else
	echo "No micros are available for you in this region."
	return 1
    fi
    
}

###############################################################################
# CODE
###############################################################################

let starttime=$(date -j -f "%a %b %d %T %Z %Y" "$(date)" "+%s")
whorang="$(ps -o pid=,command= -p $PPID | sed -e 's/^[-\.]//' | sed 's#/bin/bash ##')"

o_debug=; o_verbose=; o_region=${OCI_REGION}; o_compartment=${OCI_COMPARTMENT_PROD};
rc=0

while getopts ":c:r:dv" option; do
    decho "Top of getops: option ${option}, OPTARG ${OPTARG}, OPTIND ${OPTIND}, line ${@}"
    decho "line after OPTIND is ${@:$OPTIND}"
    [[ ${OPTARG:0:2} == "--" ]] && OPTARG="-" && option="double" && let OPTIND--
    lowerarg=$(echo "${OPTARG}" | tr [A-Z] [a-z])
    case ${option} in
	c) o_compartment=${lowerarg};;
	r) o_region=${lowerarg};;
	d) o_verbose=t; o_debug=t;;
	v) o_verbose=t;;
	*) usage;;
    esac
done
for i in o_debug o_verbose o_region o_compartment; do decho "${i}=|${!i}|"; done

TIMEFORMAT="%R seconds"
[[ ${o_debug} ]] && time mainprog || mainprog
[[ ${rc} != 0 ]] && clog "exit with rc ${rc}"
let stoptime=$(date -j -f "%a %b %d %T %Z %Y" "$(date)" "+%s")
clog "$(( stoptime - starttime )) seconds"
decho "$(( stoptime - starttime )) seconds"
exit 0


