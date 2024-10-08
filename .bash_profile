#!/usr/bin/env bash
###############################################################################
#
# .bash_profile on Mac OS X Darwin bash is called at login, either by
# running terminal or by ssh from another machine.  It's main purpose
# is to setup aliases and functions that are necessary for an interactive
# shell, but neither a subshell nor a shell called by launchd (for example).
#
# Since .bashrc contains important path and environment variables, it
# should be sourced first to ensure an appropriate environment.
#
# Neither profile should use echo as this can really screw things up on
# an ssh command -- especially those that use ssh like scp.  So I use growl
# (http://growl.info/index.php) to notify the user of problems.
# The Growl Extras folder contains the executable growlnotify, which must
# be in the path.
#
# $Id: .bash_profile-v 1.102 2014-08-11 09:23:08-07 dan Exp $
#
###############################################################################

[[ -s /Users/dan/.bashrc ]] && source /Users/dan/.bashrc || source ${HOME}/.bashrc
bprev="$(echo '$Revision: 1.102 $' | sed -e 's/\$//g' -e 's/ $//')"

###############################################################################
# Functions

###############################################################################
# Alias-type functions
function define()   { open "dict://$*";                                           }
function echored()  { tput setf 4; echo "$*";   tput op;                          }
function editw()    { ${EDITOR} $(/usr/bin/which ${1});                           }
function growlog()  { /Users/dan/bin/growl "$*"; clog "$*";                       }
function manpath()  { /usr/bin/manpath | tr ':' '\n';                             }
function me()       { echo "${HOME}/.bash_profile";                               }
function mute()     { osascript -e 'set volume with output muted';                }            
function oracle()   { pushd ~/Oracle/Oracle\ Content/;                            }
function path()     { echo $PATH | tr ':' '\n';                                   }
function rank()     { sort | uniq -c | sort -rn | head;                           }
function su()       { pwd -P > /tmp/.pushd; /usr/bin/su "$@";                     }
function sud()      { echo "${1}" > /tmp/.pushd; /usr/bin/su "$@";                }
function unmute()   { osascript -e 'set volume withouttput muted';                }            
function wcl()      { cat "${1}" | wc -l | awk '{print $1}';                      }
function whoson()   { who; w; rwho; whos; last | grep -v ${USER};                 }

###############################################################################
# Mac OS X functions

function fatinfo() {
    lipo -info "$(\which ${1})"
}

function portinfopy() { 
    set -o noglob
    port info "py27-*${1}*" | grep " \@"
    set +o noglob
}

function _portupgrade() {
#   Sub function for portupgrade, which upgrades installed MacPorts
    local pf="${HOME}/.installed-ports"
    growlog "starting port upgrade"
    if [[ ! $(nmap -p 873 rsync.macports.org | grep "873/tcp open") ]]; then
	growlog "rsync blocked -- upgrade aborted."
	return 1
    fi
    rm -f "${pf}"
    sudo port installed 2> /dev/null | while read line; do 
	echo ${line} | awk '{print $1 $2}' >> "${pf}"
    done
    growlog "starting selfupdate ($(wcl ${pf}) ports)"
    if ! sudo port selfupdate &> /dev/null; then
	growlog "port selfupdate FAILED.  Exiting."
	return 1
    fi
    growlog "port selfupdate completed"
    [[ ! "$(sudo port installed outdated 2> /dev/null)" ]] && clog "no outdated ports"
    local ports=$(sudo port list outdated 2> /dev/null | awk '{print $1}')
    for p in ${ports}; do
	clog "upgrading ${p}"
	growl "upgrading ${p}"
	sudo port -Rc upgrade ${p} &> /dev/null
    done
    sudo port installed inactive 2> /dev/null | while read line; do
	clog "inactive: $(echo ${line} | awk '{print $1 $2}')"
    done
    [[ ! "$(sudo port installed inactive 2> /dev/null)" ]] && clog "no inactive ports"
    ports=$(sudo port installed inactive 2> /dev/null | awk '{print $1}')
    for p in ${ports}; do
	growlog "uninstalling inactive ${p}"
    done
    sudo port uninstall inactive &> /dev/null
    sudo port installed leaves 2> /dev/null | while read line; do
	clog "leaf: $(echo ${line} | awk '{print $1 $2}')"
    done
    rm -f "${pf}"
    growl "Listing active ports"
    sudo port installed 2> /dev/null | while read line; do 
	echo ${line} | awk '{print $1 $2}' >> "${pf}"
    done
}

function _timeportupgrade() {
    exec 3>&1 4>&2
    time=$(TIMEFORMAT="%0R"; { time _portupgrade 1>&3 2>&4 ; } 2>&1)
    exec 3>&- 4>&-
    clog $(printf "port upgrade completed, %s:%#02d elapsed." $(( time / 60 )) $(( time % 60 )))
    growl -e $(printf "port upgrade completed, %s:%#02d elapsed." $(( time / 60 )) $(( time % 60 )))
}

alias portupgrade='_timeportupgrade &'

function getbundleid() {
    str="${quote}get bundle identifier of (info for (path to application \"${*}\"))"
    osascript -e "${str}${quote}"
}

function mana() {
#   Show a man page from Apple's site in a browser
    local num=$(echo $(basename $(/usr/bin/man -w ${1})) | \
	sed 's/.*\.\([[:digit:]]\).*$/\1/')
    local url="http://developer.apple.com/library/mac/#documentation"
    url="${url}/Darwin/Reference/ManPages/man${num}/${1}.${num}.html"
    open ${url}
}

function use() {
#   Show a man page in PDF, caching it.  Use "clear" as $2 to start fresh
    versions=($(man -wa ${1}))
    [[ ${#versions[@]} ]] || return 1      # No man page, displayed on stderr
    if [[ ${#versions[@]} -gt 1 ]]; then
	echo "Warning: there are multiple versions of ${1}"
	printf "%s\n" "${versions[@]}"
    fi
    local p="${HOME}/.mancache/${1}.pdf"
    [[ (-s "${p}") && (-s ${versions}) && (${versions} -nt "${p}") ]] && rm -f "${p}"
    [[ ${2} == clear ]] && rm -f "${p}"
    if [[ -s "${p}" ]]; then open "${p}"; return 0; fi

#   Is there a man entry for the command?
    if [[ "$(man -w "${1}" 2> /dev/null)" ]]; then
#       Manpage exists, but is it a built-in?
	if [[ ! "$(man "${1}" | head | grep BUILTIN 2> /dev/null)" ]]; then
#           Not built-in.  Format it and open it.
	    mkdir -p "$(dirname ${p})"
	    man -t ${1} | pstopdf -i -o "${p}" &> /dev/null
	    open "${p}"
	else
#           Yes, it's a built-in, try help
	    help ${1}
	fi
    else
#       No man entry, lets try using the command with --help	
	echo "No man entry for ${1}, trying --help"
	    ${1} --help
    fi
}

function showprinters() {
    echo "All queues on this machine:"
    lpstat -a | awk '{print $1}'
    echo
    lpstat -d
}
    
function pledit() {
    [[ -w ${1} ]] && priv="" || priv=sudo
    ${priv} plutil -convert xml1 "${1}"
    ${priv} ${EDITOR} "$*"
    ${priv} plutil -convert binary1 "${1}"
}

function tell() {
    [[ ! ${1} ]] && echo "Usage: tell app msg.  Quoting handled." && return 1
    str="${quote}tell app \"${1}\" to"
    shift
    [[ "${1}" == "to" ]] && shift
    for i in ${@}; do
	i_no_space="$(echo ${i} | sed 's/ //g')"
	[[ ${#i} -ne ${#i_no_space} ]] && p="\"${i}\"" || p="${i}"
	str="${str} ${p}"
    done
    str="${str}${quote}"
    /usr/bin/osascript -e "${str}"
}

function dropboxAddressBook() {
    find . -name "*\:AB*" | \
	while read fn; do
	    mv "$fn" "$(echo "$fn" | sed 's/:/./g')"
    done
}

function getFreePort() {
    freeport=$(( 100+( $(od -An -N2 -i /dev/random) )%(60000-1024+1) ))
    port2=$(( freeport + 1 ))
    while [[ ($(grep "${freeport}\|${port2}" /etc/services | grep -v Unassigned)) || \
	($(lsof -i:${freeport},${port2})) ]]; do
	# free port or port2 is busy
	freeport=$(( 100+( $(od -An -N2 -i /dev/random) )%(60000-1024+1) ))
	port2=$(( freeport + 1 ))
    done
    echo ${freeport}
}

function share_mouse() {
    local port="22"
    gw=$(route -n get oracle.com | grep gateway)
    if [[ ! "${gw}" ]]; then
	port="10022"
	target="$(dig papamini.dnsdojo.com +short)"
	other="risc.local"
    else
	target="risc.local"
	other="$(dig papamini.dnsdojo.com +short)"
    fi
    already_running="$(ps axo pid,command | grep "".*[s]sh.*${target}"")"
    if [[ "${already_running}" ]]; then
	pid="$(echo ${already_running} | cut -f1 -d' ')"
	echo "Tunnel already established, signalling pid ${pid}"
	kill -HUP ${pid}
    fi
    other_running="$(ps axo pid,command | grep "".*[s]sh.*${other}"")"
    monport="$(echo ${other_running} | sed 's/.*-L \([[:digit:]]*\):.*$/\1/')"
    if [[ "${monport}" ]]; then
	echo "Killing process using monitor port ${monport}"
	kill "$(ps axo pid,command | grep "[s]sh.*M ${monport}" | cut -f1 -d' ')"
    fi
    echo "Setting up tunnel for port 24800 using ${target} on ${port}"
    autossh -M $(getFreePort) -p ${port} -N -f -R 24800:localhost:24800 "dan@${target}"
    echo "Starting Synergy"
    ssh "dan@${target}" open -a Synergy
    open -a Synergy
    pids=$(ps axo pid,command | grep -i "[s]sh " | awk '{print $1}')
    complete -W "${pids}" kk
}

function share_screen() {
    [[ ! "${1}" ]] && echo "Usage: ${0} target" && return 2
    target="${1}"
    [[ ! $(echo "${target}" | sed 's/[a-z]//g') ]] && target="${!target}"
    [[ ! $(scutil -r "${target}") ]] && echo "Cannot reach ${target}." && return 1
    line=$(ps aux | grep ".*ssh.*-L.*localhost:5900.*${target}" | grep -v grep)
    if [[ "${line}" ]]; then
	local port=$(echo "${line}" | sed -e 's/.*-L//' -e 's/:.*$//' -e 's/[[:blank:]]//g')
	echo "Tunnel already open on port ${port}"
	open "vnc://localhost:${port}"
	return 0;
    fi
    echo "Starting screen sharing with ${target}"
    if [[ $(\which autossh) ]]; then
	o_auto=true;
	monport=$(getFreePort);
    fi
    ssport=$(getFreePort)
    echo "about to call (auto)ssh (-M ${monport} -f -NL ${ssport}:localhost:5900 ${target}"
    [[ ${o_auto} ]] && autossh -M ${monport} -f -NL ${ssport}:localhost:5900 "${target}" || \
	ssh -f -NL ${ssport}:localhost:5900 "${target}"
    sleep 1
    open "vnc://localhost:${ssport}"
}

function 1pass() {
    eval $(op signin)
}

function opget() {
#   Options are [[vpn | sso] [[username | password]]].  Default is vpn password
    eval $(op signin --session "${OP_SESSION_YES65ZLIBJA6JN4CNW7YZ77GSI}") # prompts for password if invalid, otherwise updates env
    opkey="${OP_VPN_KEY}"
    [[ ! "${2}" ]] && field=password || field="${2}"
    [[ "${1,}" == "sso" ]] && opkey="${OP_SSO_KEY}"
    case "${field}" in
	username) op item get "${opkey}" --fields username | pbcopy;;
	password) op item get "${opkey}" --fields password | pbcopy;;
	endpoint) op item get "${opkey}" | \
			jq '.overview.URLs[] | select(.u | contains("twv")).u' | sed 's/\"//g' | sed 's/https://' | pbcopy;;
	*) echo "Nothing to get";;
    esac
    echo "${field} copied to the clipboard."
}

function opgetvpn() {
    [[ ! "${1}" ]] && target="qqabh3n7h5ehnjlrujj4fz5oq4" || target="$*"
   eval $(op signin --session "${OP_SESSION_YES65ZLIBJA6JN4CNW7YZ77GSI}") # prompts for password if invalid, otherwise updates env
    op item get "${target}" | jq '.overview.URLs[] | select(.u | contains("twv")).u' | sed 's/\"//g' | pbcopy
    echo "Copied to clipboard"
}

function opgetany() {
    [[ ! "${1}" ]] && target="qqabh3n7h5ehnjlrujj4fz5oq4" || target="$*"
    eval $(op signin --session "${OP_SESSION_YES65ZLIBJA6JN4CNW7YZ77GSI}") # prompts for password if invalid, otherwise updates env
    op item get "${target}" --fields password | pbcopy
    echo "Copied to clipboard"
}

function st() {
    echo -n "Running tests..."
    [[ $(\which speedtest) && $(\which jq) ]] && \
	speedtest --json | jq -r '. | {i:.client.isp, p:.ping, d:.download, u:.upload} | [.i, .p, .d, .u] | @tsv' | \
	    awk -F "\t" '{printf "\n%s %4.1fs ping, %3.0f Mbps down, %3.0f Mbps up\n", $1, $2, $3/1024/1024, $4/1024/1024}'
}


###############################################################################
# Evernote functions

[[ ! -d ${HOME}/Library/Containers/com.evernote.Evernote ]] && edir="${HOME}" || \
    edir="${HOME}/Library/Containers/com.evernote.Evernote/Data"

export edir="${edir}/Library/Application Support/Evernote/accounts/Evernote/dgerrity/content"

function mdcopy() {
    [[ ! -e "${1}" ]] && echo "${1} does not exist." && return 1
    cat "${1}" | multimarkdown | textutil -stdin -stdout -format html -convert rtf | \
	pbcopy
    echo "Rich text copied to clipboard."
}

function newmd() {
    title="$*"
    f="${HOME}/Dropbox/$(echo ${title} | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g').md"
    [[ -e "${f}" ]] && echo "File named \"${f}\" already exists." && return 1
    touch "${f}"
    [[ ! -w "${f}" ]] && echo "Could not create \"${f}\"" && return 1
    echo "Title: ${title}  "  > "${f}"
    echo "Date: $(Date +'%Y-%m-%d')  " >> "${f}"
    echo "Author: Dan Gerrity  " >> "${f}"
    echo "Marked Style: Buttondown  " >> "${f}"
    echo "css: file:///Users/dan/Dropbox/Library/css/Buttondown.css  " >> "${f}"
    echo "Type: post  " >> "${f}"
    echo "Notebook: _Inbox  " >> "${f}"
    echo "Keywords: Default  " >> "${f}"
    echo " " >> "${f}"
    echo "# ${title} #" >> "${f}"
    edit "${f}"
    open "${f}"
}

function evernew() {
    [[ ! ${1} ]] && echo "Usage: evernew title" && return
    title=$(echo "${@}" | sed -e 's/ /_/g' -e 's/[^[:alpha:]_]*//g')
    echo  "# ${*}" > "${LOCKER}/${title}.md"
    open -a "Marked 2" "${LOCKER}/${title}.md"
    edit "${LOCKER}/${title}.md"
}

function everhtml() {
    mc=$(/bin/ls -1tTr "${edir}" | tail -n1)
    tidy -q -wrap 100 -utf8 --indent auto --output-xhtml yes --doctype loose \
	--logical-emphasis true --drop-empty-paras true --show-warnings no --tidy-mark no \
	"${edir}/${mc}/content.html" | grep -v "\|head>\|title>" | grep -v "^\w*$" > ~/${mc}.html
    edit ~/${mc}.html
    read -p "Update document in Evernote? [n] " ans
    if [[ (${ans}) && ((${ans} == "y") || (${ans} == "Y")) ]]; then
	mv "${edir}/${mc}/content.html" "${edir}/${mc}/content.html.$(date "+%Y-%m-%d")"
	mv ~/${mc}.html "${edir}/${mc}/content.html"
    fi
}

function everenml() {
    mc=$(/bin/ls -1tTr "${edir}" | tail -n1)
    cp "${edir}/${mc}/content.enml" ~/${mc}.enml
    edit ~/${mc}.enml
    read -p "Update document in Evernote? [n] " ans
    if [[ (${ans}) && ((${ans} == "y") || (${ans} == "Y")) ]]; then
	mv "${edir}/${mc}/content.enml" "${edir}/${mc}/content.enml.$(date "+%Y-%m-%d")"
	mv ~/${mc}.enml "${edir}/${mc}/content.enml"
    fi
}

function everid() {
    mc=$(/bin/ls -1tTr "${edir}" | tail -n1)
    echo "Evernote id: ${mc}"
    [[ (${1}) && ($(which engetinfo)) ]] && engetinfo ${mc}
    export EVERPATH="${edir}/${mc}/content.html"
    [[ "${1}" == "-e" ]] && edit "${EVERPATH}"
}

function evermd() {
    mc=$(/bin/ls -1tTr "${edir}" | tail -n1)
    if [[ "$(which engetinfo)" ]]; then
	title="$(engetinfo ${mc} | head -n2|tail -n1 | sed -e 's/^.*: //' -e 's/[[:space:]]*$//')"
    else
	title="$(date "+%Y-%m-%d ")${mc}.md  "
    fi
    tit="$(echo "${title}" | sed -e "s/[\'\/|\*:&@]/-/g" -e 's/[[:space:]]*$//')"
    local md="./${tit}.md"
    echo "Filename is ${md}"
    if ! touch "${md}"; then
	echo "Could not use ${title}.md as a filename."
	title=${mc}
    fi
    rm -f "${md}"
    textutil -convert txt -extension md "${edir}/${mc}/content.html" -stdout >> "${md}"
    echo -e  "\n* * *\n" >> "${md}"
    echo -en "<span style=\"color: #039; font-size: xx-small;line-height: normal;" >> "${md}"
    echo -e  "font-weight: normal; text-decoration: none;\">  " >> "${md}"
    echo -e  "Evernote id: ${mc}  " >> "${md}"
    local lp="$(pwd)/${title}.md"
    echo -e  "Local path: <a src=\"file://${lp}\">${lp} </a>  " >> "${md}"
    echo -e  "Content path: ${edir}/${mc}/content.html  " >> "${md}"
    [[ "$(which engetinfo)" ]] && engetinfo "${mc}" >> "${md}"
    echo -e "</span>\n" >> "${md}"
    open -a Marked "${md}"
    edit "${md}"
}

###############################################################################
# Interviewing

function locker() {
    pushd . &> /dev/null
    echo "Directory pushed, available with popd"
    if [[ "${1}" ]]; then
	fn="${LOCKER}/${1}"
	if [[ ! -f "${fn}" ]]; then
	    if [[ -r "${1}" ]]; then
		mv "${1}" "${fn}"
	    else
		touch "${fn}"
		${EDITOR} "${fn}" &
		osascript -e 'tell app "Emacs" to activate'
	    fi
	else
	    echo "${1} already exists in the locker."
	fi
    else
	cd "${HOME}/Oracle/Oracle Content/Secure/Locker"
#	open .
    fi
}

function interview() {
    pushd . &> /dev/null
    cd "${ORACLE_PREFIX}/Secure/Team/Interviews"
    if [[ ${1} ]]; then
	fn="$(echo "${1,,} ${2,,}" | tr ' ' '-').md"
	open "https://www.linkedin.com/search/results/index/?keywords=${1}+${2}&origin=GLOBAL_SEARCH_HEADER"
	if [[ ! -f "${fn}" ]]; then
	    printf "# ${1} ${2}\n\n" > "${fn}"
	    str="> I am [not] inclined to hire ${1} for the position of {} based on this one-hour, "
	    str+="zoom-based interview conducted on $(date "+%Y-%m-%d")."
	    printf "${str} \n\n---\n\n" >> "${fn}"
	    echo "" >> "${fn}"
	    [[ -f _template.md ]] && cat _template.md >> "${fn}"
	else
	    echo "${fn} already exists."
	fi
    fi
}

###############################################################################
# Internet and lookup functions

function lookup() { open "dict://$*"; }

function quote() {
    echo $(python -c "import urllib; print urllib.quote('''$*''')")
}

function unquote() {
    echo $(python -c "import urllib; print urllib.unquote('''$*''')")
}

function keyencode() {
    val=$(python -c "import base64; print base64.urlsafe_b64encode( '''${1}''' )")
    echo -en "<string>${val}</string>" | pbcopy
    echo "${val} copyied to clipboard in XML format"
}

function keydecode() {
    echo $(python -c "import base64; print base64.urlsafe_b64decode( '''${1}''' )")
}

function keydecodex() {
    echo $(python -c "import base64; print base64.urlsafe_b64decode( '''${1}''' )") | hexdump
}

function urlencode() {
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c"
        esac
    done
}
 
function urldecode() {
    local url_encoded="${1//+/ }"
    echo $(printf '%b' "${url_encoded//%/\x}")
}

function rgb2hex() {
    [[ ! ${3} ]] && echo "usage: $FUNCNAME r g b (where r g b are decimal)" && return
    printf "%02x%02x%02x\n" ${1} ${2} ${3} | pbcopy
    printf "rgb(%d, %d, %d) is #$(pbpaste); on clipboard without the #.\n" ${1} ${2} ${3}
}

function hex2rgb() {
    [[ ! ${1} ]] && echo "usage: $FUNCNAME rrggbb (where rrggbb are hex)" && return
    r="0x${1:0:2}"; g="0x${1:2:2}"; b="0x${1:4:2}";
    printf "rgb(%d, %d, %d)\n" ${r} ${g} ${b}
}

function wolp() {
    [[ ! "$*" ]] && echo "usage: wolp computer-name" && return 1
    kma="/Users/dan/.knownmacaddresses"
    echo "Waking $*..."
    [[ ! -e ${kma} ]] && echo "No known mac addresses" && return 3
    let count=$(grep -ci "$*" "${kma}")
    if [[ ${count} -gt 1 ]]; then
	echo "More than one possibility:"
	grep -i "$*" "${kma}"
    else
	mac=$(grep -i "$*" "${kma}" | cut -f1 -d' ')
	[[ ! ${mac} ]] && echo "No mac address corresponding to $* found." && return 4
	wakeonlan ${mac}
    fi
}

function google() {
#   Google something.
#   Override your default setting by specifying -l or -1 as the first arg
#   time="&tbs=qdr:y"  restricts results to the last year
#   time="&tbs-rltm:1" restricts results to "the latest"
    local time="&tbs=qdr:y"
    local args=$(echo "${*}" | tr " " "+")
    local prefix="http://www.google.com/search?client=safari&rls=en&q="
    local postfix="&ie=UTF-8&oeUTF-8"
    [[ "${1:0:2}" == "-l" ]] && time="&tbs-rltm:1"
    [[ "${1:0:2}" == "-1" ]] && time="&tbs=qdr:y"
    open "${prefix}${args}${postfix}${time}"
}

function translate() {
    dlang="${1}"; shift
    open "http://translate.google.com/#auto/${dlang}/$(echo -ne "${@}" | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')"
}

function li() {
#   Lookup a name on LinkedIn and Facebook                                                          
    if [[ "${netloc}" == "Disconnected" ]]; then echo ${netloc}; return 1; fi
    if [[ ! "${2}" ]]; then echo "Usage: ${0} first last"; return 1; fi
    open "https://www.linkedin.com/search/results/all/?keywords=${1}%20${2}&origin=GLOBAL_SEARCH_HEADER"
}

function lic() {
#   Lookup and print information about a company on LinkedIn
    local zip=""
    if [[ "${1}" == "" ]]; then
        echo "Usage: lic [zip] company name"
        return 1
    fi
    if [[ "$(echo ${1} | sed 's/^[[:digit:]]*$/zip/')" == "zip" ]]; then
        zip="&searchLocationType=I&countryCode=us&postalCode=${1}&distance=100"
        shift
    fi
    local co=$(echo "$@" | tr ' ' '+')
    local url="http://www.linkedin.com/search/fpsearch?company="
    url="${url}${co}&currentCompany=C${zip}&page_num=1&search="
    url="${url}&pplSearchOrigin=MDYS&viewCriteria=2&sortCriteria=DR"
    url="${url}&redir=redir"
    open "${url}"
}

function aria() {
    if [[ "${netloc}" == "Disconnected" ]]; then echo ${netloc}; return 1; fi
    if [[ ${1} =~ \. || ${1} =~ \@ ]]; then
	sstr="${1}"
    elif [[ ${2} ]]; then
	sstr="${1}+${2}"
	li "$@"
    elif [[ ${1} ]]; then
	sstr="@${1}"
    else
	sstr=""
    fi
    url="https://people.oracle.com/apex/f?p=8000:1:13335495794387#${sstr}"
    open "${url}"
}

function zoom() {
    [[ -z ${1}  ]] && zoomvar="zoom_dan" || [[ "${1}" == "me" ]] && zoomvar="zoom_dan" || \
		zoomvar="zoom_${1}"
    echo "Zooming ${1} (${!zoomvar^^})..."
    open "${!zoomvar^^}"
}

function zoomcopy() { echo ${ZOOM_ME} | pbcopy; echo "copied to clipboard - use zn -w me to start"; }

function forcesso() {
    open https://oradocs-corp.sites.us2.oraclecloud.com/authsite/home/
}

function crisp() {
    local dur=; local dt=
    if [[ ! ${3} ]]; then
	echo "crisp [-d date] [duration] task|calendar|email|phone|document|place tag \"desc\""
	echo "crisp [-t HH:MM] [duration] task|calendar|email|phone|document|place tag \"desc\""
	return 1
    fi
    dt="--date $(date "+%Y-%m-%d")T%H:%M:%S"
    if [[ ${1} == -d ]]; then
	shift 
	if [[ (${#1} -ne 19) || (${1:3:1} -eq 1) ]]; then
	    read -p "check date ${1}, should be 2012-MM-DDTHH:MM:SS.  Continue? [n] " ans
	    [[ ("${ans}" == "") || (${ans} == "n") || (${ans} == "N") ]] && return 1
	fi
	dt="--date ${1}"; shift
    elif [[ ${1} == -t ]]; then
	shift;
	if [[ ${#1} -ne 5 ]]; then
	    echo "check time ${1}, should be HH:MM" && return 1
	fi
	dt="--date $(date "+%Y-%m-%d")T${1}:00"; shift
    fi
    if [[ ! $(echo ${1} | sed 's/[0-9\.]//g') ]]; then
	dur="--duration ${1}"; shift
    fi
    [[ ! $(echo ${1} | grep "task\|calendar\|email\|phone\|document\|place") ]] && \
	echo "Bad type ${1}, must be  task|calendar|email|phone|document|place" && return 1
    act="--type ${1}"; shift;
    tag="--tag \"${1}\""; shift;
    text="-t \"$*\""
    eval "/Users/dan/Dropbox/Dev/APIs/Crisply/post-activity.rb \
	-a dgerrity -k ${crisply_key} ${dur} ${act} ${tag} ${dt} ${text}"
    clog "posted to crisply: ${dt} ${dur} ${act} ${tag} ${text}"
}

function amazon() {
    if [[ "${1}" == "" ]]; then echo "Usage: amazon title-of-song"; return 1; fi
    local pt=$(echo $* | tr ' ' '+')
    local url="http://www.amazon.com/s/ref=nb_sb_noss?url="
    url="${url}search-alias%3Ddigital-music&field-keywords=${pt}&x=0&y=0"
    open ${url}
}

function products() {
    curl https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json 2>&1 | grep -c "offerCode";
}

function _handlePortal() {
    url="http://portal.concur.com"
    if ! grep 172\.1 <(ifconfig) >/dev/null; then
	echo "Concur not reachable -- enable vpn"
	return 1
    fi
}

function dict() {
    set -o noglob
    local testpat=$(echo "${1}" | sed 's/[0-9]//g')
    local pat="${1}"
    if [[ ${#1} -ne ${#testpat} ]]; then
	local sub=""
	for ((i=1; i<6; i++)); do 
	    sub="${sub}.";
	    pat=$(echo "${pat}" | sed "s/${i}/${sub}/g")
	done
    fi
    cat "${DEFAULT_DICT:-/usr/share/dict/words}" | tr '[:upper:]' '[:lower:]' | \
	grep -x "${pat}" | sort | uniq
    set +o noglob
}

function emissions() {
#   Looks up the emissions used in a particular flight
    if [[ ! ${4} ]]; then
	echo Usage: $FUNCNAME airline origin destination segments [format]
	return
    fi
    [[ ${5} ]] && format=${5} || format=html
    site="http://impact.brighterplanet.com/flights.${format}"
    str="airline=${1}"
    str="${str}&origin_airport=${2}"
    str="${str}&destination_airport=${3}"
    str="${str}&segments_per_trip=${4}"
    str="${str}&trips=1"
    str="${str}&icao_code=B752"
    str="${str}&key=${BRIGHTER_PLANET_KEY}"
    echo "Assuming ${4} segments one way."
    echo "Query: ${site}/${str}"
    curl -s ${site} -d ${str} > emissions.${format}
    [[ ${format} == html ]] && \
	cat emissions.${format} | grep "Total\|interpreted" | sed 's/^.*>.*>\(.*\)<.*<.*$/\1/' || \
	edit emissions.${format}
}

function browser_refresh() {
    open -a "Google Chrome"  --args \
	 'https://chrome.google.com/webstore/detail/1password-x-–-password-ma/aeblfdkhhhdcdjpifhhbdiojplfjncoa'
    open -a "Firefox"        --args \
	 'https://addons.mozilla.org/en-US/firefox/addon/1password-x-password-manager/?src=search'
    open -a "Microsoft Edge" --args \
	 'https://microsoftedge.microsoft.com/addons/detail/dppgmdbiimibapkepcbdbmkaabgiofem'
    open -a "Brave Browser"  --args \
	 'https://chrome.google.com/webstore/detail/1password-x-–-password-ma/aeblfdkhhhdcdjpifhhbdiojplfjncoa'
}

function find-python-lib() {
    open "http://pypi.python.org/pypi?%3Aaction=search&term=${1}&submit=Search+PyPi"
}

function sendcloud() {
    swaks -s "${SMTP_SERVER}:587" -tls -au "${SMTP_USERNAME}" -ap "${SMTP_PASSWORD}" -f  "dg-mac@gerrity.org" "$@"
}

function slack() {
    if [[ "${netloc}" == "Disconnected" ]]; then echo ${netloc}; return 1; fi
    if [[ ${1} =~ \. || ${1} =~ \@ ]]; then
	userchannel="in channel \""${1}"\""
	shift
    fi
    msg="$*"
    str="osascript -e 'tell script \"Slack\" to send message \""${msg}"\" "${userchan}"'"
    eval "${str}"
}

###############################################################################
# UNIX functions

# RCS functions
export RCSINIT="-x\-v -zLT"

function cdp() {
    [[ ! ${1} ]] && pushd ~ > /dev/null && return
    eval pushd \"${1}\" > /dev/null
}

function check-writables() {
    echo $(hostname -s)
    /bin/ls -AFl /Users/dan | grep "^[^dl].wx.* .*$"
    /bin/ls -AFl /Users/dan/bin | grep "^[^dl].wx.* .*$"
    for i in sierra zulu; do
	[[ $(hostname -s) == ${i} ]] && continue
	echo ${i}
	ssh ${!i} '/bin/ls -AFl /Users/dan | grep "^[^dl].wx.* .*$"'
	ssh ${!i} '/bin/ls -AFl /Users/dan/bin | grep "^[^dl].wx.* .*$"'
    done
}

# RCS directories are soft linked to Dropbox which can cause some confusion
# This routine checks to be sure it's OK to perform the proposed RCS operation
function _ok() {
    if [[ ! -e "${1}" ]]; then
	read -p "File ${1} does not exist in this directory.  Really ${2}? [n] " ans
	[[ "${ans}" != "y" ]] && return 1 || return 0
    elif [[ (${2} == get) && (! -w "${1}") ]]; then return 0
    elif [[ (${2} == get) || (${2} == check-out) && (-w "${1}") ]]; then
	echo "${1} is writable, ${2} skipped"
	if rcsdiff "${1}" &> /dev/null; then  echo "Files identical"; else  echo "Files differ"; fi
	return 1
    elif [[ $(rlog -h "${1}" | grep -A1 "locks:" | tail -n 1 | grep -v access) ]]; then
	lockrev=$(rlog "${1}" | grep -A1 locks | tail -n1 | grep -v access | \
	    awk '{print "Revision "$2" locked by "$1}')
	lockrev="${lockrev:0:$(( ${#lockrev} - 1 ))}"
	if [[ $(grep "Revision: [0-9]" "${1}") ]]; then
	    curRev=$(grep -m 1 "Revision: [0-9]" "${1}" | sed 's/^.*Revision: \([0-9\.]*\).*$/\1/')
	elif [[ $(grep "Id: .* Exp" "${1}") ]]; then
	    curRev=$(grep -m 1 "Id: .* Exp" "${1}" | sed 's/^.*ID: .* \([0-9\.]*\) 2.*$/\1/')
	else
	    curRev="Unknown"
	fi
	echo "${lockrev}"
	echo "Current revision is ${curRev}"
	$(tail "RCS/logs/${1}.log" | grep checked-out | tail -n 1 | sed "s#${HOME}#~#")
	if rcsdiff "${1}" &> /dev/null; then  echo "Files identical"; else  echo "Files differ"; fi
	return 1
    fi
    return 0
}

function _rcslog() {
    local action="${1}"; shift;
    local path="$(hostname):$(pwd)/$(basename ${*})"
    echo "$(date) ${action} ${USER}@${path} ${USER}" >> "RCS/logs/${*}.log"
}

function rcsmv() {
    mv "${1}" "${2}"
    mv "RCS/${1}-v" "RCS/${2}-v"
    mv "RCS/logs/${1}.log" "RCS/logs/${2}.log"
    _rcslog renamed "${2}"
}

function ci()      { /usr/bin/ci -u -d "$@"; _rcslog "checked-in" "$@";     }
function put()     { /usr/bin/ci -l -d "$@"; _rcslog "put" "$@";            }
function unlock()  { /usr/bin/rcs -u "${1}";   _rcslog "unlocked" "${1}";   }
function co()      { if _ok "${1}" "check-out"; then /usr/bin/co -l "${1}";
                     _rcslog "checked-out" "${1}"; fi;                      }
function get()     { if _ok "${1}" "get"; then /usr/bin/co "${1}";
                     _rcslog "get" "${1}"; fi;                              }
function rcslog()  { tail "RCS/logs/${1}.log";                              }


###############################################################################
# File functions

function encrypt() {
    [[ ! -f "${1}" ]] && echo "Usage: ${0} <filename>" && return
    if [[ -f "${1}.aes" ]]; then
	read -p "${1}.aes exists.  Overwrite? [y] " ans
	[[ (${ans}) && (${ans} != "y") ]] && return
    fi
    openssl aes-256-cbc -a -e -salt -in "${1}" -out "${1}.aes"
}

function decrypt() {
    [[ ! -f "${1}.aes" ]] && echo "Usage: ${0} filename-without-aes" && return
    openssl aes-256-cbc -a -d -salt -in "${1}.aes" -out "${1}"
}

function tarball() {
# create, verbose, gzip, filename
    if [[ -f "${1}.tar.gz" ]]; then
	read -p "${1}.tar.gz exists.  Overwrite? [y] " ans
	[[ (${ans}) && (${ans} != "y") ]] && return
    fi
    [[ -d "${1}" ]] && tar -cvz -f "${1}.tar.gz" "${1}" || echo "usage: $FUNCNAME dir-name"
}

function untarball() {
    [[ -e "${1}" ]] && fn="${1}" || fn="${1}.tar.gz}"
    [[ ! -e "${fn}" ]] && fn="${fn}.tar}"
    if [[ ! -e "${fn}" ]]; then
	echo "None of ${1} ${1}.tar ${1}.tar.gz found"
	return
    fi
    tar -xvf "${fn}"
}

function dos2unix() {
    if [[ ! ${2} ]]; then
        tr -d '\r' < "${1}" > ~/.tmp && mv ~/.tmp "${1}"
    else
        tr -d '\r' < "${1}" > "${2}"
    fi
}

function unix2dos() {
    if [[ ! ${2} ]]; then
	sed 's/$'"/$(echo -e \\\r)/" "${1}" > ~/.tmp && mv ~/.tmp "${1}"
    else
	sed 's/$'"/$(echo -e \\\r)/" "${1}" > "${2}"
    fi
}

function formatxml() {
    if [[ ! ${2} ]]; then
        local src=$(mktemp /tmp/bash_profile.XXXXXX) || exit 1
	local dst=$(mktemp /tmp/bash_profile.XXXXXX) || exit 1
	[[ $(head -n1 "${1}" | grep "class ") ]] && tail -n +2 "${1}" > "${src}" || \
	    cat "${1}" > "${src}"
	xmllint --c14n "${src}" | XMLLINT_INDENT=$'    ' xmllint \
	    --encode UTF-8 --format - > "${dst}"
	[[ -s "${dst}" ]] && mv "${dst}" "${1}"
    else
	xmllint --c14n "$*" | XMLLINT_INDENT=$'\t' xmllint --encode UTF-8 --format -
    fi
}

###############################################################################
# System information functions

function apr() {
    apropos "$*" | grep -xi ".*([1278].\?).*" | cut -c 1-${COLUMNS}
}

function pss() {
    [[ ! ${1} ]] && return
    pro="[${1:0:1}]${1:1}"
    ps axo pid,command | grep -i "${pro}"
    pids="$(ps axo pid,command | grep -i ${pro} | awk '{print $1}')"
    complete -W "${pids}" kk
}

function pssh() {
    pss "ssh "
}

function fixmac() {
    local ma=$(echo "${1}" | tr ':' ' ')
    [[ "${ma}" == "(incomplete)" ]] && ma="00 00 00 00 00 00"
    printf "%02s:%02s:%02s:%02s:%02s:%02s" ${ma}
}

function localid() {
    arp -a | while read line; do
	mac=$(fixmac $(echo $line | awk '{print $4}'))
	ip=$(echo ${line} | awk '{print $2}' | sed 's/[()]//g')
	iface=$(echo ${line} | awk '{print $6}')
	dev="$(grep ${mac} .knownmacaddresses | sed 's/^[0-9a-f:]* //')"
	printf "%-15s %s %-5s %s\n" "${ip}" "${mac}" "${iface}" "${dev}"
    done
}

function bandwidth() {
    local server
    [[ ! -z "${1}" ]] && server="${1}" || server=iperf3.centvc.com
    iface="$(route get ${server} | grep interface | awk '{print $2}')"
    bmac="$(fixmac "$(ifconfig -m ${iface} | grep "ether " | awk '{print $2}')")"
    bmacname="$(grep ${bmac} ~/.knownmacaddresses | sed 's/^[0-9a-f:]* //')"
    osxs=$(networksetup -listnetworkserviceorder | sed -n "/Dev.*${iface}/s/.*t: \(.*\),.*/\1/p")
#    [[ (! ${osxs}) && (${iface:0:4} == "utun") ]] && iface="vpn"
#    [[ ${#osxs} -gt 8 ]] && osxs=$(echo ${osxs} | sed -e 's/ /-/g' -e 's/\(.......\).*\(...\)$/\1-\2/')

    echo "Testing interface ${server} through ${iface} ${bmac} ${bmacname} ${osxs}..."
    bw=$(iperf3 -c "${server}" -J | \
	jq '.intervals[].streams[].bits_per_second' | \
	awk 'BEGIN{s=0;s2=0;}{s+=$1;s2+=$1^2;}END{printf "%3.0f +-%.0f Mbps\n", s/NR/10^6, sqrt((s2-s^2/NR)/NR)/10^6;}')
    echo "Bandwidth to ${server}, using interface ${iface} ${bmacname} (${bmac}): ${bw}"
    clog "Bandwidth to ${server}, using interface ${iface} ${bmacname} (${bmac}): ${bw}"
}

function basestations() {
    local ssid=$(airport -I | grep " SSID:" | cut -f18-)
    [[ ! ${ssid} ]] && echo "NO SSID"
    local mybssid=$(airport -I | grep "BSSID:" | awk '{print $2}')
    [[ ! ${mybssid} ]] && echo "NO BSSID"
    [[ ${mybssid} ]] &&  myname=$(grep $mybssid ~/.knownmacaddresses)
    [[ ${myname} ]] && myname=$(echo ${myname} | cut -f2- -d' ') || myname=${bssid}
    echo "RSSI Channel HT Station"
    echo "-----------------------"
    airport -s | grep "${ssid}" | while read line; do
	bssid=$(echo ${line} | sed 's/^.* \([[:alnum:]]\{2\}:\)/\1/' | awk '{print $1}')
	name=$(grep $bssid ~/.knownmacaddresses)
	[[ ${name} ]] && name=$(echo ${name} | cut -f2- -d' ') || \
	    name="${bssid} $(echo ${line} | sed 's/^[[:space:]]*\(.*\)[[:alnum:]]\{2\}:/\1/')"
	printf "%4s %7s %2s " $(echo ${line} | cut -f3-5 -d' ')
	echo ${name}
    done
    echo -e  "\nCurrently using ${myname}\n"
    airport -s | grep -v "${ssid}\|SSID" | while read line; do
	bssid=$(echo ${line} | sed 's/^.* \([[:alnum:]]\{2\}:\)/\1/' | awk '{print $1}')
	echo "bssid ${bssid}"
	name=$(grep $bssid ~/.knownmacaddresses)
	echo "name ${name}"
	[[ ${name} ]] && name=$(echo ${name} | cut -f2- -d' ') || \
	    name="${bssid} $(echo ${line} | sed 's/^[[:space:]]*\(.*\)[[:alnum:]]\{2\}:/\1/')"
	echo "name ${name}"
	printf "%4s %7s %2s " $(echo ${line} | cut -f3-5 -d' ')
	echo ${name}
    done
}

function whos() {
    echo "w:"; w; echo -e "\nusers: "; users; echo -e "\finger:"; finger; echo -e "\nlast:"; last
    echo "Checking for connected file sharing using lsof..."
    sudo lsof -i:548 | grep EST | sed 's/.* TCP \([0-9\.]*\):afp.*$/\1/'
    echo "Checking for iTunes connections using lsof..."
    sudo lsof -i:548 | grep EST | sed 's/.* TCP \([0-9\.]*\):daa.*$/\1/'
}

function my6() {
    ifconfig | grep -A6 "^en.*flags" | grep inet6 | \
	sed 's/^.*6 \(.*\)%\(.*\) p.*$/\2: \1/'
}

function myid() {
    id | cut -f1,2 -d' '
    printf "%3d %s\n" \
	$(id | cut -f3 -d' ' | sed 's/groups=//' | tr "," "\n" | sed 's/[()]/ /g') | sort -n
}

function ports() {
#   Shows ports that are in use
    netstat -aWf inet | grep -v "\*\.\*\|Active\|Proto" | awk '{print $5}' | \
	while read line; do
	    name=$(echo ${line} | sed 's/\(.*\)\..*$/\1/')
	    ip=$(nslookup ${name} | \
		grep -v "#" | grep "Address" | cut -f2 -d' ')
	    [[ -z ${ip} ]] && ip="n/a"
	    proto=$(echo ${line} | sed 's/.*\.\(.*\)$/\1/')
	    printf "%-6s %-45s %s\n" $proto $name $ip
    done
}

function lsnet() {
    gs=${1:-".*"}
    sudo lsof -i  | awk '{printf("%-14s%-11s%s\n", $10, $1, $9)}' | \
	grep -i "${gs}" | sort
}

function printers() {
    open http://localhost:631/printers/
}

function route() {
    [[ "${1}" == "print" ]] && netstat -nrf inet || /sbin/route $*
}

function symlink() {
    if [[ -z ${2} ]]; then
        echo "Usage: $FUNCNAME remote-path local-name"
        echo "ln -s remote-path local-name"
        return 1
    fi
    if [[ -e "${2}" ]]; then
        echo "Local name ${2} exists, delete it first if you meant it"
        return 2
    fi
    if [[ ! -e "${1}" ]]; then
        echo "Remote file or directory ${1} doesn't exist"
        return 3
    fi
    ln -s "${1}" "${2}"
}

function edit() {
    for i in $@; do
	if [[ ! -e "${i}" ]]; then
	    read -p "Create new file ${i}? [y] " ans
	    [[ (! ${ans}) || (${ans} == y) ]] && continue || return
	elif [[ ! -w "${i}" ]]; then
	    read -p "Warning, ${i} is not writeable, continue? [y] " ans
	    [[ (! ${ans}) || (${ans} == y) ]] && continue || return
	fi
	if [[ $(ps axo user,command | grep "${EDITOR} ${1}" | grep -v grep) ]]; then
	    echo "file is being edited in the background or another window."
	    return
	fi
    done
    ${EDITOR} "$@"
}

###############################################################################
# Code
###############################################################################

logger -i "$(me) executed by $(ps -p $PPID -o args=), pid $$"
fgcGrey=37; fgcBlack=30; fgcBlue=34; fgcYellow=33; fgcRed=31; fgcGreen=32;
bgcGrey=47; bgcNone=49
fgc=${fgcBlack}; bgc=${bgcNone}; bold=";1"
case $(hostname -s) in
    papamini)      fgc=${fgcYellow};;
    studio)        fgc=${fgcRed};;
    risc)          fgc=${fgcBlue};;
    rose)          fgc=${fgcRed};;
    dg-mac)        fgc=${fgcGreen};;
    *)             fgc=${fgcBlack}; bgc=${bgcGrey};;
esac
export PROMPT_DIRTRIM=3
export PS1="\[\e]2;\u@\H - \j - \T\a\e[${bgc};${fgc}${bold}m\]\h:\w \\$\[\e[0m\] "

[[ ! ${SSH_CALLER} ]] && export SSH_CALLER=$(hostname -s)
if [[ (${SSH_CLIENT}) && (${SSH_CALLER} == $(hostname -s)) ]]; then
    export PROMPT_DIRTRIM=2
#    export PS1="\h:\w \\$ "
    export TERM=xterm
    tput init
fi

thishost="$(hostname -s | sed 's/[- ]/_/g')"
virtualhosts=""
localhosts="${thishost} ${virtualhosts}"
homehosts="rose risc papamini"
remotehosts="papamini papax router" 
sshhosts="${virtualhosts} ${localhosts} ${homehosts} ${remotehosts}"
dyndnshosts="${homehosts} ${remotehosts}"
for i in ${remotehosts}; do eval export ${i}=\"${i}.dnsdojo.com\"; done
for i in ${localhosts};  do eval export ${i}=\"${i}.local\"; done
[[ "$(uname)" == Darwin ]] && \
    ip=$(ifconfig -m "${aptdev}" | grep "inet " | cut -f2 -d' ') || \
    ip=$(ifconfig | grep "inet " | cut -f2 -d' ')
[[ "${ip:0:9}" == "192.168.4" ]] && for i in ${homehosts}; do eval export ${i}=\"${i}.local\"; done

[[ -r ~/Dropbox/Library/share/dict/altscrab ]] && export DEFAULT_DICT=~/Dropbox/Library/share/dict/altscrab
[[ -r ~/Library/altscrab ]] && export DEFAULT_DICT=~/Library/altscrab

if [[ -r "${HOME}/Oracle/Oracle Content/Secure/Locker" ]]; then
    export LOCKER="${HOME}/Oracle/Oracle Content/Secure/Locker"
    export ORACLE_PREFIX="${HOME}/Oracle/Oracle Content"
elif [[ -r "${HOME}/Oracle Content - Accounts/Oracle Content" ]]; then
    export LOCKER="${HOME}/Oracle Content - Accounts/Oracle Content/Secure/Locker"
    export ORACLE_PREFIX="${HOME}/Oracle Content - Accounts/Oracle Content"
elif [[ -r "${HOME}/Oracle Content/Secure/Locker" ]]; then
    export LOCKER="${HOME}/Oracle Content/Secure/Locker"
    export ORACLE_PREFIX="${HOME}/Oracle Content"
fi
[[ -r ~/Dropbox/Documents/Locker ]] && export LOCKER=~/Dropbox/Documents/Locker

# Old cmd.exe and old qnx habits
alias cd..="cd .."
alias cls="clear"
alias dir="ls -FA"

# The usual "ls" aliases
alias ld='/bin/ls -AF | grep "/$"'                # Directories only
alias lf='/bin/ls -AFlO'                          # Show flags like hidden
alias ll='/bin/ls -AFl'                           # Basic long with colors and dot files
alias ls='/bin/ls -AF'                            # Basic ls with colors and dot files
alias lt='/bin/ls -AFltTr'                        # Sorted with full dates
alias lx='/bin/ls -AFl | grep "^[^dl].*x .*$"'    # Executables, no links, no directories
alias ldg='/bin/ls -AF | grep "/$" | grep -i '    # As above, but with grep
alias lfg='/bin/ls -AFlO | grep -i '
alias llg='/bin/ls -AFl | grep -i '
alias lsg='/bin/ls -AF | grep -i '
alias ltg='/bin/ls -AFltTr | grep -i '
alias lxg='/bin/ls -AFl | grep "^[^dl].*x .*$" | grep -i '
alias lxw='/bin/ls -AFl | grep "^[^dl].wx.* .*$"' #  writeable executables

# Simplifications for me
alias aliasg="\alias | grep -i"
alias clearmancache="rm /Users/dan/.mancache/*.pdf"
alias editprof="pushd ~/ > /dev/null; edit $(me); loadprof; popd > /dev/null"
alias func="compgen -A function | sort"
alias funcg="compgen -A function | grep -i"
alias googleb="google os x bash"
alias googleh="google hints macworld os x"
alias googlem="google os x"
alias listfunc="compgen -A function | sort"
alias listfuncg="compgen -A function | grep -i"
alias loadprof="source $(me); echo Profile ${bprev} loaded"
alias logcat="cat ${lf}"
alias logcatnet="cat ${logdir}/com.centvc.netwatch.log"
alias logedit="edit ${lf}"
alias logmark='clog "------------------ M A R K --------------------"'
alias logopen="open ${lf}"
alias logtail="tail -n50 ${lf}"
alias logtailnet="tail -n50 ${logdir}/com.centvc.netwatch.log"
alias logwatch="tail -f -n50 ${lf}"
alias marked='open -a "Marked" '
alias mou='open -a "Mou" '
alias repo='pushd ~/Repo/haikudeck > /dev/null'
alias whosfilesharing="sudo lsof -i4TCP:548 | grep EST | sed 's/.* TCP \([0-9\.]*\):afp.*$/\1/'"
alias whosonitunes="sudo lsof -i4TCP:548 | grep EST | sed 's/.* TCP \([0-9\.]*\):daa.*$/\1/'"
alias wx='ansiwweather'

# Better unix
export CLICOLOR=1
export LSCOLORS=dxfxcxdxbxegedabagacad
export REPLYTO="dan@gerrity.org"
alias envp="env | sort -f"
alias envg="env | sort -f | grep -i"
alias g="grep"
alias gv="grep -v"
alias hexdump="hexdump -C"
alias htop="sudo htop"
alias kk="sudo kill"
alias keymgmt="man sshd-keygen-wrapper"
alias lsof="sudo /usr/sbin/lsof"
alias rcsversions="/bin/ls | sed 's/ /\\ /g' | xargs rlog | grep \"RCS\|head\" | grep -v no such"
alias rdiff="rcsdiff -wBy --left-column"
alias rdiffc="rcsdiff -wBy --left-column --suppress-common-lines"
alias roothere="su -m"
alias reboot='clog "Restarting..."; sudo shutdown -r now'
alias renew="sudo ipconfig set ${aptdev} DHCP"
alias scpm="/usr/bin/scp -Ep"
alias sd="sudo /sbin/shutdown -s +5"
alias sdiff="diff -wBy --left-column"
alias sdiffc="diff -wBy --left-column --suppress-common-lines"
alias tree="find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"
alias top="top -o cpu"
alias webroot="cd /Library/WebServer/Documents"
alias which="\type -a"

if pgrep -fq "emacs.*daemon$"; then
    export EDITOR=emacsclient
else
    export EDITOR=emacs;
fi

# Mac stuff
function define() { open "dict://${1}"; }
alias cisco='open -a "Cisco AnyConnect Secure Mobility Client"'
alias cycle="sudo ifconfig ${aptdev} down; sleep 2; sudo ifconfig ${aptdev} up"
alias devcenter="open https://developer.apple.com/devcenter/mac/index.action#"
alias dirhide="sudo chflags -h hidden"
alias dirshow="sudo chflags -h nohidden"
alias dnsinfo="scutil --dns | grep 'name\|if_\|domain\|DNS'"
alias editscrab="${EDITOR} $(/usr/bin/which scrab)"
alias ejecttm='nm="Elements_$(hostname -s)" && [[ -e "/Volumes/${nm}" ]] && diskutil eject "${nm}"'
alias et="emacsclient -t -a ~/bin/emacst"
alias flushdns="sudo killall -HUP mDNSResponder"
alias geek="osascript -e 'tell application \"Geektool\" to refresh all'"
alias listapps="system_profiler SPApplicationsDataType"
alias osa="osascript -e"
alias pasteclean="pbpaste | iconv -t ASCII//TRANSLIT >"
alias pbclean="pbpaste | iconv -t ASCII//TRANSLIT | pbcopy | pbpaste"
alias plbuddy="/usr/libexec/PlistBuddy"
alias plcat="plutil -convert xml1 -o -"
alias plconvb="plutil -convert binary1"
alias plconvx="plutil -convert xml1"
alias pyinstall='python setup.py install --user'
alias renew="sudo ipconfig set ${aptdev} DHCP"
alias restartfinder="killall Finder"
alias rootkey="sudo '/Applications/Utilities/Keychain Access.app/Contents/MacOS/Keychain Access' &"
alias scripts="pushd ~/Library/Scripts/Applications > /dev/null"
alias stanford="open http://snsr.stanford.edu/landing.html"
alias switchprinter="lpoptions -d "

this_shell="$(ps -p $$ -o command= | sed -e's/^[.-]//' -e 's/[ -].*//')"
if [[ "${this_shell,,}" == "bash" ]]; then
    if [[ $(/usr/bin/which brew 2>/dev/null) ]]; then

	# Bash completion for brew
	bp=$(brew --prefix)
	[[ -f "${bp}/etc/profile.d/bash_completion.sh" ]] && source "${bp}/etc/profile.d/bash_completion.sh"
	[[ -f "${bp}/etc/bash_completion" ]] && source "${bp}/etc/bash_completion"

	# Bash completion for oci
	vername="$(\ls -Tr ${bp}/Cellar/oci-cli/)"
	pyver="$(\ls -Tr ${bp}/Cellar/oci-cli/${vername}/libexec/lib/)"
	oci_complete="${bp}/Cellar/oci-cli/${vername}/libexec/lib/${pyver}/site-packages/oci_cli/bin/oci_autocomplete.sh"
	[[ -e "${oci_complete}" ]] && source "${oci_complete}"
    fi
    if [[ $(/usr/bin/which op 2>/dev/null) ]]; then
	source <(op completion bash)
    fi

    utils="dig dnstrace dnstracer ftp host iperf3 nc nmap nslookup ping scutil ssh traceroute wget"
    unset list; for i in ${dyndnshosts}; do list="${list} ${!i}"; done
    complete -o default -W "${list}" "${utils}" open
    list="${sshhosts} imap.gmail.com smtp.gmail.com checkip.dyndns.com"
    complete -o default -W "${list}" "${utils}"
    unset list; for i in ${sshhosts}; do list="${list} ${!i}:\~/"; done
    complete -o default -o nospace -W "${list}" scp
    complete -o default -A alias "$(compgen -A alias)"
    complete -o default -A function "$(compgen -A function)"
    complete -d pushd
    complete -u su usermod userdel passwd chage write chfn groups slay w
    complete -g groupmod groupdel newgrp 2>/dev/null
    complete -A stopped -P '%' bg
    complete -j -P '%' fg jobs disown
    complete -v readonly unset
    complete -A setopt set
    complete -A shopt shopt
    complete -A helptopic help
    complete -a unalias
    complete -A binding bind
    complete -c command type which
    complete -b builtin
    complete -W "$([[ -d ~/bin ]] && /bin/ls ~/bin)" editw
    
fi
