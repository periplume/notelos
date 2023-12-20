#!/usr/bin/env bash
# file: notelos-lib.sh
# source: https://github.com/periplume/notelos.git
# author: jason@bloom.us
# desc: notelos shell library functions

# SCRIPT AND SHELL SETTINGS
set -o errexit
set -o nounset
set -o pipefail

# OUTPUT

# some color
red=$(tput setab 1; tput setaf 7)
boldred=$(tput setab 1 ; tput setaf 7)
green=$(tput setaf 2)
cyan=$(tput setaf 6)
yellow=$(tput setaf 3)
label=$(tput setab 7; tput setaf 0)
prompt=$(tput setab 5; tput setaf 7)
reset=$(tput sgr0)
# TODO functionalize colorizing

##################################################
# LOGGING AND CONSOLE MESSAGES AND USER INTERFACE
##################################################

# user output: types
# name		description														display
#----------------------------------------------------------------------------
# debug		verbose																cyan
# info		information only											blue text, green bg
# warn		warning (abnormal)										black text, yellow bg
# error		not allowed														white text, red bg
# fatal		error and exiting (out of trap)				black text, red bg, bold text?
# ask			ask user for input										white text, cyan bg
#
#	always expect fresh new line
# exception...after ask...in which case, take care of that immediately
# suppress all if _studioSILENT=true
#
# call as
# _warn "message"
# _info "message"

# _fLOG creates logging functions based on runtime switches (command options)
# and static features: (defaults and global variables)
#
# the three main determinants:
# _studioSILENT= true | false
# _studioLOG= true | false
# _studioDEBUG= true | false
#
# subordinate dependencies:
# _studioLOG= true | false
# _studioLOGFILE= "path to file"
# $(tput colors)

# to turn (eg) debugging on -before- the second _fLOG (after reading the
# parameters)...enable it here
#_studioDEBUG=true

#TODO print DEBUG to console on stderr
##################################################
# LOGGING AND CONSOLE MESSAGES AND USER INTERFACE
##################################################

_fLOG() {
	# collapsing function...sets up according to the static determinants
	# creates all log functions dynamically (based on defaults plus positional
	# parameters)
	#
	# set the notelos modes to generic names
	_DEBUG=${_notelosDEBUG:-false}
	_SILENT=${_notelosSILENT:-false}
	_LOG=${_notelosLOG:-false}
	_LOGGING=${_notelosLOGGING:-false}
	_LOGFILE=${_notelosLOGFILE:-/dev/null}
	# 
	local _log=0
	local _console=0
	local _color=0
	# if _SILENT is false or unset, assume interactive
	[[ "${_SILENT:-}" = "false" ]] && _console=1
	# if _LOG and _LOGGING is true, log
	[[ "${_LOG:-}" = "true" && "${_LOGGING:-}" = "true" ]] && _log=1
	# if we have color, print in color
	#TODO remove the tput requirement here
	[[ $(tput colors) ]] && _color=1
	#
	# set up colors	
	_cDebug=$(tput setaf 6)
	_cInfo=$(tput setaf 2)
	_cWarn=$(tput setaf 11)
	_cError=$(tput setaf 1)
	_cAsk=$(tput setaf 0; tput setab 11)
	_cReset=$(tput sgr0)
	# create 5 log functions based on static determinants above
	# CONSOLE AND LOG
	if [[ $_console = 1 && $_log = 1 ]]; then
		_debug() {
			[[ "$_DEBUG" = "false" ]] && return
			local _timeStamp=$(date +%s.%N)
			printf '%s %s\n' "${_cDebug}DEBUG${_cReset}" "${@}" >&2
			printf '%s %s %s\n' "$_timeStamp" "${self} ${_cDebug}DEBUG${_cReset}" "${@}" >>${_LOGFILE}
		}
		_info() {
			local _timeStamp=$(date +%s.%N)
			printf '%s %s %s\n' "$_timeStamp" "${self} ${_cInfo}INFO${_cReset}" "${@}" >>${_LOGFILE}
			# hack: below prints _info...multi-line messages are indented
			SAVEIFS=$IFS
			IFS=$'\n'
			_pList=(${1})
			IFS=$SAVEIFS
			if [[ ${#_pList[@]} -gt 1 ]]; then
				printf '%s %s\n' "${_cInfo}INFO${_cReset}" "${_pList[0]} "
				for (( i=1; i<${#_pList[@]}; i++ ))
				do
					printf "\t\t: %s\n" "${_pList[$i]} "
				done
			else
				printf "%s %s\n" "${_cInfo}INFO${_cReset}" "${1} "
			fi
		}
		_warn() {
			local _timeStamp=$(date +%s.%N)
			printf '%s %s\n' "${_cWarn}WARN${_cReset}" "${@}"
			printf '%s %s %s\n' "$_timeStamp" "${self} ${_cWarn}WARN${_cReset}" "${@}" >>${_LOGFILE}
		}
		_error() {
			local _timeStamp=$(date +%s.%N)
			printf '%s %s\n' "${_cError}ERROR${_cReset}" "${@}"
			printf '%s %s %s\n' "$_timeStamp" "${self} ${_cError}ERROR${_cReset}" "${@}" >>${_LOGFILE}
		}
		_ask() {
			local _timeStamp=$(date +%s.%N)
			printf '%s %s' "${_cAsk}USER${_cReset}" "${@}"
			#printf '%s %s %s\n' "$_timeStamp" "${self} ${_cAsk}USER${_cReset}" "${@}" >>${_LOGFILE}
			# don't log prompts...if something is important, log as debug
		}
	# LOG ONLY
	elif [[ $_console = 0 && $_log = 1 ]]; then
		_debug() {
			[[ "$_DEBUG" = "false" ]] && return
			local _timeStamp=$(date +%s.%N)
			printf '%s %s %s\n' "$_timeStamp" "${self} ${_cDebug}DEBUG${_cReset}" "${@}" >>${_LOGFILE}
		}
		_info() {
			local _timeStamp=$(date +%s.%N)
			printf '%s %s %s\n' "$_timeStamp" "${self} ${_cInfo}INFO${_cReset}" "${@}" >>${_LOGFILE}
		}
		_warn() {
			local _timeStamp=$(date +%s.%N)
			printf '%s %s %s\n' "$_timeStamp" "${self} ${_cWarn}WARN${_cReset}" "${@}" >>${_LOGFILE}
		}
		_error() {
			local _timeStamp=$(date +%s.%N)
			printf '%s %s %s\n' "$_timeStamp" "${self} ${_cError}ERROR${_cReset}" "${@}" >>${_LOGFILE}
		}
		_ask() {
			:
			#local _timeStamp=$(date +%s.%N)
			#printf '%s %s %s\n' "$_timeStamp" "${self} ${_cAsk}USER${_cReset}" "${@}" >>${_studioLOGFILE}
			# don't log _ask prompts
		}
	# CONSOLE ONLY
	elif [[ $_console = 1 && $_log = 0 ]]; then
		_debug() {
			[[ "$_DEBUG" = "false" ]] && return
			printf '%s %s\n' "${_cDebug}DEBUG${_cReset}" "${@}" >&2 
		}
		_info() {
			printf '%s %s\n' "${_cInfo}INFO${_cReset}" "${@}"
		}
		_warn() {
			printf '%s %s\n' "${_cWarn}WARN${_cReset}" "${@}"
		}
		_error() {
			printf '%s %s\n' "${_cError}ERROR${_cReset}" "${@}"
		}
		_ask() {
			printf '%s %s' "${_cAsk}USER${_cReset}" "${@}"
		}
	else
		# do nothing
		_debug() { : ; }
		_info() { : ; }
		_warn() { : ; }
		_error() { : ; }
		_ask() { : ; }
	fi
	export -f _debug
	export -f _info
	export -f _warn
	export -f _error
	export -f _ask
}

_XfLOG() {
	# collapsing function...sets up according to the static determinants
	# creates all log functions dynamically (based on defaults plus positional
	# parameters)
	# _debug
	# _info
	# _warn
	# _error
	# _ask
	# log function usage as simple as:
	# _info "the message contents" 
	local _log=0
	local _console=0
	local _color=0
	[[ "${_studioSILENT:-}" = "false" ]] && _console=1
	[[ "${_studioLOG:-}" = "true" && "${_studioLOGGING:-}" = "true" ]] && _log=1
	[[ $(tput colors) ]] && _color=1
	#
	# set up colors	
	_cDebug=$(tput setaf 6)
	_cInfo=$(tput setaf 2)
	_cWarn=$(tput setaf 11)
	_cError=$(tput setaf 1)
	_cAsk=$(tput setaf 0; tput setab 11)
	_cReset=$(tput sgr0)
	# create 5 log functions based on static determinants above
	# CONSOLE AND LOG
	if [[ $_console = 1 && $_log = 1 ]]; then
		_debug() {
			[[ "$_studioDEBUG" = "false" ]] && return
			local _timeStamp=$(date +%s.%N)
			printf '%s %s\n' "${_cDebug}DEBUG${_cReset}" "${@}" >&2
			printf '%s %s %s\n' "$_timeStamp" "${self} ${_cDebug}DEBUG${_cReset}" "${@}" >>${_studioLOGFILE}
		}
		_info() {
			local _timeStamp=$(date +%s.%N)
			printf '%s %s %s\n' "$_timeStamp" "${self} ${_cInfo}INFO${_cReset}" "${@}" >>${_studioLOGFILE}
			# hack: below prints _info...multi-line messages are indented
			SAVEIFS=$IFS
			IFS=$'\n'
			_pList=(${1})
			IFS=$SAVEIFS
			if [[ ${#_pList[@]} -gt 1 ]]; then
				printf '%s %s\n' "${_cInfo}INFO${_cReset}" "${_pList[0]} "
				for (( i=1; i<${#_pList[@]}; i++ ))
				do
					printf "\t\t: %s\n" "${_pList[$i]} "
				done
			else
				printf "%s %s\n" "${_cInfo}INFO${_cReset}" "${1} "
			fi
		}
		_warn() {
			local _timeStamp=$(date +%s.%N)
			printf '%s %s\n' "${_cWarn}WARN${_cReset}" "${@}"
			printf '%s %s %s\n' "$_timeStamp" "${self} ${_cWarn}WARN${_cReset}" "${@}" >>${_studioLOGFILE}
		}
		_error() {
			local _timeStamp=$(date +%s.%N)
			printf '%s %s\n' "${_cError}ERROR${_cReset}" "${@}"
			printf '%s %s %s\n' "$_timeStamp" "${self} ${_cError}ERROR${_cReset}" "${@}" >>${_studioLOGFILE}
		}
		_ask() {
			local _timeStamp=$(date +%s.%N)
			printf '%s %s' "${_cAsk}USER${_cReset}" "${@}"
			#printf '%s %s %s\n' "$_timeStamp" "${self} ${_cAsk}USER${_cReset}" "${@}" >>${_studioLOGFILE}
			# don't log prompts...if something is important, log as debug
		}
	# LOG ONLY
	elif [[ $_console = 0 && $_log = 1 ]]; then
		_debug() {
			[[ "$_studioDEBUG" = "false" ]] && return
			local _timeStamp=$(date +%s.%N)
			printf '%s %s %s\n' "$_timeStamp" "${self} ${_cDebug}DEBUG${_cReset}" "${@}" >>${_studioLOGFILE}
		}
		_info() {
			local _timeStamp=$(date +%s.%N)
			printf '%s %s %s\n' "$_timeStamp" "${self} ${_cInfo}INFO${_cReset}" "${@}" >>${_studioLOGFILE}
		}
		_warn() {
			local _timeStamp=$(date +%s.%N)
			printf '%s %s %s\n' "$_timeStamp" "${self} ${_cWarn}WARN${_cReset}" "${@}" >>${_studioLOGFILE}
		}
		_error() {
			local _timeStamp=$(date +%s.%N)
			printf '%s %s %s\n' "$_timeStamp" "${self} ${_cError}ERROR${_cReset}" "${@}" >>${_studioLOGFILE}
		}
		_ask() {
			:
			#local _timeStamp=$(date +%s.%N)
			#printf '%s %s %s\n' "$_timeStamp" "${self} ${_cAsk}USER${_cReset}" "${@}" >>${_studioLOGFILE}
			# don't log _ask prompts
		}
	# CONSOLE ONLY
	elif [[ $_console = 1 && $_log = 0 ]]; then
		_debug() {
			[[ "$_studioDEBUG" = "false" ]] && return
			printf '%s %s\n' "${_cDebug}DEBUG${_cReset}" "${@}" >&2 
		}
		_info() {
			printf '%s %s\n' "${_cInfo}INFO${_cReset}" "${@}"
		}
		_warn() {
			printf '%s %s\n' "${_cWarn}WARN${_cReset}" "${@}"
		}
		_error() {
			printf '%s %s\n' "${_cError}ERROR${_cReset}" "${@}"
		}
		_ask() {
			printf '%s %s' "${_cAsk}USER${_cReset}" "${@}"
		}
	else
		# do nothing
		_debug() { : ; }
		_info() { : ; }
		_warn() { : ; }
		_error() { : ; }
		_ask() { : ; }
	fi
	export -f _debug
	export -f _info
	export -f _warn
	export -f _error
	export -f _ask
}


###########################
# trap and signal catching
###########################

_irishExit() {
	echo #to clear line...this is a bit ugly
	# this function does not behave as desired
  _ask "ctrl-c detected; to resume, press R, to quit, press ENTER"
  while read -s -t 15 -n 1 _ANS; do
		echo
  	if [[ ${_ANS:-n} = 'R' ]]; then
			_info "resuming"
    	return
  	else
   	#_error "user requested exit with ctrl-c"
			_error "goodbye"
			exit 1
		# this seems to fuck up my terminal???
  	fi
	done
}

_getTERMDIMENSIONS() {
	# return "columns:lines"
	local columns=$COLUMNS
	local lines=$LINES
	echo "$columns:$lines"
}


_isOnline() {
	local google="www.google.com"
	local timeout=3
	local result
	result=$(ping -c 1 -W "$timeout" "$google" 2>&1)
	if [ $? -eq 0 ]; then
		local rtt
		rtt=$(echo "$result" | awk -F/ '/rtt/ {print $5}')
		_debug "${FUNCNAME[0]} google icmp ok, rtt=$rtt"
		return 0
	else
		return 1
	fi
}

_XisOnline () {
  # arg 1: mode (simple or full, default=simple)
  mode=${1:-simple}
	# return the result
	# 0 is true (online)
	# 1 is false (offline)
	result=0
  if [[ $mode = "simple" ]]
	then
		attempt=0
		testsites=(http://www.google.com http://www.amazon.com http://www.microsoft.com)
		while [ $attempt -lt 3 ]
		do
			testHTTP ${testsites[$attempt]} $mode
			if [ $? = 0 ]
			then
				# can reach google on port 80, we are online
				declare -g STUDIO_MODE_OFFLINE=false
				_debug "${FUNCNAME[0]}: test mode: $mode; result: ONLINE"
				return 0
			else
				# can not reach google, try the next in $testsites list
				# this is broken...will set only based on last test
				attempt=$(( $attempt + 1 ))
			fi
		done
		if [ -z ${STUDIO_MODE_OFFLINE} ]
		then
			declare -g STUDIO_MODE_OFFLINE=true
			_debug "${FUNCNAME[0]}: test mode: $mode; result: OFFLINE"
		fi
  else
		# mode is full
		declare -A testList
	for sTest in testRoute testLink testPing testLocalDNS testRemoteDNS
	do
		eval $sTest
		if [ $? = 0 ]
		then
			testList[$sTest]="pass"
		else
			testList[$sTest]="fail"
		fi
	done
	if testHTTP "http://www.google.com" $mode
	then
		# add another check here as sometimes google will time out
		testList[testHTTP]="pass"
	else
		testList[testHTTP]="fail"
	fi
	fi
	passCount=0
	failCount=0
	warnCount=0
	for k in "${!testList[@]}"
	do
		if [ ${testList[$k]} = "pass" ]
		then
			passCount=$(( $passCount + 1 ))
		elif [ ${testList[$k]} = "fail" ]
		then
			failCount=$(( $failCount + 1 ))
		elif [ ${testList[$k]} = "warn" ]
		then
			warnCount=$(( $warnCount + 1 ))
		fi
	done
	if [ $failCount -eq 0 ]
	then
		declare -g STUDIO_MODE_OFFLINE=false
		_debug "${FUNCNAME[0]}: test mode: $mode; pass=$passCount fail=$failCount: ONLINE"
		return 0
	elif [ $failCount -le $passCount ]
	then
		declare -g STUDIO_MODE_OFFLINE=false
		declare -g STUDIO_ONLINE_WARN=true
		_debug "${FUNCNAME[0]}: test mode: $mode; pass=$passCount fail=$failCount: ONLINE (with WARNINGS)"
		return 0
	else
		declare -g STUDIO_MODE_OFFLINE=true
		_debug "${FUNCNAME[0]}: test mode: $mode; pass=$passCount fail=$failCount: OFFLINE (improve this heuristic)"
		return 1
	fi
}

testRoute () {
  # desc: sub-function to test for internet gateways
  # no args
  # figure out the most likely default route and set STUDIO_NET_ROUTE
  # return 0 for gateways, set globals $STUDIO_NET_ VARs
  # return 1 for none
  local ip_route=$(ip -4 route)
  local default_routes=$(echo "$ip_route" | grep ^default)
  local gateway_count=$(echo "$default_routes" | wc -l)
  if [ -z "$default_routes" ]
  then
    return 1
  elif [ $gateway_count -gt "1" ]
  then
    local trimmed=$(echo "$default_routes" | awk '$9!=""')
    local sorted=$(echo "$trimmed" | sort -g -k1,9)
    local default_route=$(echo "$sorted" | head -1)
  elif [ $gateway_count = "1" ]
  then
    local default_route=$default_routes
  fi
  _debug "${FUNCNAME[0]}: routes detected: [$gateway_count]: $default_route"
  declare -g STUDIO_NET_ROUTE=$default_route
  declare -g STUDIO_NET_ADAPTER=$(echo "$default_route" | awk '{print $5}')
  declare -g STUDIO_NET_ADAPTERMAC=$(ip link show $STUDIO_NET_ADAPTER | grep "link/ether" | awk '{print $2}')
  declare -g STUDIO_NET_IP=$(ip -4 addr show $STUDIO_NET_ADAPTER | grep inet | awk '{print  $2}')
  declare -g STUDIO_NET_GATEWAY=$(echo "$default_route" | awk '{print $3}')
  return 0
}
 
testLink () {
  # desc: test adapter link status
	# arg1: adapter name (optional)
	# uses $STUDIO_NET_ADAPTER as default
  # return 0 if UP
  # return 1 if DOWN
  adapter=${1:-$STUDIO_NET_ADAPTER}
  link_status=$(ip link show $adapter | awk '{print $9}')
  if [ "$link_status" != "UP" ]
  then
    _debug "${FUNCNAME[0]}: the link on $adapter is $link_status"
    return 1
  else
    _debug "${FUNCNAME[0]}: the link on $adapter is $link_status"
    return 0
  fi
}

testHostProbe () {
  # desc: use nmap to probe host when, eg, it is filtering icmp
  # arg: host ip to probe
  # return 0 if host appears up
  # return 1 if host appears down
  nmap_output=temp/nmap.$(date +%s).out
  nmap -oG ${nmap_output} -Pn $1 >/dev/null
  grep -q "Status: Up" ${nmap_output}
  if [ $? -eq "0" ]
  then
    _debug "${FUNCNAME[0]}: nmap reports host at $1 is up"
    return 0
  else
    _debug "${FUNCNAME[0]}: nmap reports host at $1 is down"
    return 1
  fi
}

testPing () {
  # desc: sub-function wrapper for ping
	# args: one IP address (uses STUDIO_NET_GATEWAY if empty)
  # return 0 if success
  # return 1 if not
  # reporting if host is up or down (uses nmap as 2nd check)
  ip=${1:-$STUDIO_NET_GATEWAY}
  ping_output=$(ping -n -c1 -W3 "$ip")
  if [ $? -ne "0" ]
  then
    # figure out if device is filtering ICMP (ie alive)
    icmp_filtered=$(echo "$ping_output" | head -2 | tail -1 | cut -d' ' -f5)
    if [[ $icmp_filtered = "filtered" ]]
    then
      _debug "${FUNCNAME[0]}: ping to $ip appears to be filtered"
      testHostProbe $ip
      if [ $? -eq "0" ]
      then
        _debug "${FUNCNAME[0]}: ping filtering detected, nmap reports: host is up"
        return 0
      fi
    else
      _debug "${FUNCNAME[0]}: no ping response, nmap also reports: host is down"
      return 1
    fi
    ping_output=$(ping -n -c1 -W5 "$ip")
    if [ $? -ne "0" ]
    then
      _debug "${FUNCNAME[0]}: ping to $ip failed: check networking"
      return 1
    else
      ping_latency=$(echo "$ping_output" | grep ^rtt | cut -d/ -f5)
      _debug "${FUNCNAME[0]}: ping to $ip success: latency $ping_latency"
      return 0
    fi
  else
    ping_latency=$(echo "$ping_output" | grep ^rtt | cut -d/ -f5)
    _debug "${FUNCNAME[0]}: ping to $ip success: latency $ping_latency"
    return 0
  fi
}

testLocalDNS () {
  # desc: test DNS resolution with local resolver
	# arg1: adapter name (STUDIO_NET_ADAPTER is default)
  # return 0 on success
  # return 1 on failure
  adapter=${1:-$STUDIO_NET_ADAPTER}
  nmcli_output=$(nmcli -t device show $adapter)
  # figure out how many local resolvers we have so we can enumerate if we see
  # fail on the first inquiry
  # declare -g DNS1 DNS2
  dns_primary=$(echo "$nmcli_output" | grep ^IP4.DNS | head -1 | cut -d: -f2)
  if [ $? -ne "0" ]
  then
    # try another if possible, otherwise return 1
    echo "FIX"
    return 1
  else
    dig_output=$(dig @$dns_primary www.google.com)
    dig_returncode=$?
    dig_answer=$(echo "$dig_output" | grep ^www.google.com | awk '{print $5}')
    dig_latency=$(echo "$dig_output" | grep "^;; Query time:" | awk '{print $4}')
    declare -g STUDIO_NET_DNS=$dns_primary
    _debug "${FUNCNAME[0]}: dns query to $dns_primary for www.google.com is $dig_answer latency $dig_latency"
    return 0
  fi
}

testRemoteDNS () {
  # desc: sub-function to test name resolution
  # args: none 
  # success: return 0 (we can reach name servers and resolve names)
  # failure: return 1
  googleDNS1="8.8.8.8"
  googleDNS2="9.9.9.9"
  testPing "$googleDNS1"
  if [ $? -ne "0" ]
  then
    testPing "$googleDNS2"
    if [ $? -ne "0" ]
    then
      echo "${RED}FAIL${RESET} can't reach any google public DNS"
      return 1
    else
      dig_output=$(dig @$googleDNS2 www.google.com)
      dig_returncode=$?
      dig_answer=$(echo "$dig_output" | grep ^www.google.com | awk '{print $5}')
      dig_latency=$(echo "$dig_output" | grep "^;; Query time:" | awk '{print $4}')
      _debug "${FUNCNAME[0]}: query to $googleDNS2 for www.google.com is $dig_answer latency  $dig_latency"
      return 0
    fi
  else
    dig_output=$(dig @$googleDNS1 www.google.com)
    dig_returncode=$?
    dig_answer=$(echo "$dig_output" | grep ^www.google.com | awk '{print $5}')
    dig_latency=$(echo "$dig_output" | grep "^;; Query time:" | awk '{print $4}')
    _debug "${FUNCNAME[0]}: query to $googleDNS1 for www.google.com is $dig_answer latency    $dig_latency"
  fi
}

testHTTP () {
  # desc: function to test http connectivity
  # arg 1: http server to test
  # arg 2: mode (simple|full) default=simple
  #   simple mode: return 0 as soon as HTTP STATUS=200, else return 1
  #   full mode: get to 200 and collect details
  # note, we will follow only ONE redirect
	# TODO need much better logic here...rethink how this is done
	# eg, when one test fails (eg google http fetch) it throws it all off
  mode=${2-simple}
  getHTTPheaders so "$1"
  # return 1 if we cannot get the http headers
  if [[ ! $? = "0" ]]
  then
    _debug "${FUNCNAME[0]}: failed http fetch at $1 with curl"
		return 1
  fi
  # print the headers
  #for h in ${!so[@]}
  #do
  # printf "${BLUE}%s=${RESET}${GREEN}%s${RESET}\n" $h "${so[$h]}"
  #done
	if [[ ${so["Status"]} =~ 30? ]]
	then
		# got a redirect, follow it once
    redirect=${so["location"]}
    getHTTPheaders so "$redirect"
		if [[ ${so["Status"]} = 200 ]]
		then
			# got a status 200
			_debug "${FUNCNAME[0]}: http alive at $1"
			return 0
		else
			# failed after http redirect
			_debug "${FUNCNAME[0]}: http redirect failed, giving up on $1"
			return 1
		fi
	elif [[ ${so["Status"]} = 200 ]]
	then
		_debug "${FUNCNAME[0]}: http fetch success at $1"
		return 0
	else
		_debug "${FUNCNAME[0]}: http fetch failed at $1"
		return 1
	fi
  #if [[ ${so["Status"]} = "200" ]] && [[ $mode = "simple" ]]
  #then
  #  logEvent 0 $FUNCNAME "http alive at $1"
  #  return 0
  #elif [[ ${so["Status"]} =~ 30? ]]
  #then
  #  redirect=${so["location"]}
  #  getHTTPheaders so "$redirect"
  #  if [[ ${so["Status"]} = "200" ]] && [[ $mode = "simple" ]]
  #  then
  #    logEvent 1 $FUNCNAME "http redirect from $1; http alive at $redirect"
  #    return 0
  #  else
  #    echo WHAT
  #  fi
  #else
  #  echo WHATWHAT
  #fi
  # enumerate through the array:
  #for h in ${!so[@]}; do printf "%s=%s\n" $h "${so[$h]}"; done | sort
}

# curl timeouts need to be handled better
# also capture curl timer data
# https://stackoverflow.com/questions/18215389/how-do-i-measure-request-and-response-times-at-once-using-curl

getHTTPheaders () {
  # Call this as: headers ARRAY URL
  # modified from: https://stackoverflow.com/questions/24943170/how-to-parse-http-headers-using-bash
  {
    # (Re)define the specified variable as an associative array.
    unset $1;
    declare -gA $1;
    local line rest
    # Get the first line, assuming HTTP/1.0 or above. Note that these fields
    # have Capitalized names.
    IFS=$' \t\n\r' read -r $1[Proto] $1[Status] rest
    # if we only get curl non-zero exit code we have a problem
    if [[ ${so[Proto]} =~ ^[1-9] ]] && [[ -z ${so[Status]} ]]
    then
      #logEvent 2 $FUNCNAME "curl non-zero error ${so[Proto]} for $2"
      return 1
    fi
    # Drop the CR from the message, if there was one.
    declare -gA $1[Message]="${rest%$'\r'}"
    # Now read the rest of the headers. 
    while true; do
      # Get rid of the trailing CR if there is one.
      IFS=$'\r' read line rest;
      # Stop when we hit an empty line
      if [[ -z $line ]]; then break; fi
      # Make sure it looks like a header
      # This regex also strips leading and trailing spaces from the value
      if [[ $line =~ ^([[:alnum:]_-]+):\ *(( *[^ ]+)*)\ *$ ]]; then
        # Force the header to lower case, since headers are case-insensitive,
        # and store it into the array
        declare -gA $1[${BASH_REMATCH[1],,}]="${BASH_REMATCH[2]}"
      else
        _debug "${FUNCNAME[0]}: ignoring non-header line: %q\n' '$line"
        printf "Ignoring non-header line: %q\n" "$line" >> /dev/stderr
      fi
    done
    # use process substitution and capture curl's exit code in case of failure
  } < <(curl --connect-timeout 3 -Is "$2"; printf "$?")
}

# collect curl timer data
# see https://stackoverflow.com/questions/18215389/how-do-i-measure-request-and-response-times-at-once-using-curl
# see curl_format.txt
# curl -w "@curl_format.txt" -o /dev/null -s "http://wordpress.com/"

# check out chrony for time sync

# check out lazydocker

# check out lazygit

### UNIFIED EDITOR
_studioEdit() {
	# given path ($1)
	[[ -z "${1}" ]] && { _error "full path is required"; return 1; }
  local _file=${1}
	vim -u "${_studioDir}/.config/vimrc" -c 'set syntax=markdown' "${_file}"
}

# FUN
_superJob() {
	# cribbed from the internet somewhere
	local x		# time in seconds
	local z		# message
	x=${1:-1}
	z=${2:-studiofun}
	progressbar() {
 		local loca=$1; local loca2=$2;
		declare -a bgcolors; declare -a fgcolors;
		for i in {40..46} {100..106}; do
    	bgcolors+=("$i")
		done
		for i in {30..36} {90..96}; do
			fgcolors+=("$i")
		done
		local u=$(( 50 - loca ));
		local y; local t;
		local z; z=$(printf '%*s' "$u");
		local w=$(( loca * 2 ));
		local bouncer=".oO°Oo.";
		for ((i=0;i<loca;i++)); do
			t="${bouncer:((i%${#bouncer})):1}"
			bgcolor="\\E[${bgcolors[RANDOM % 14]}m \\033[m"
			y+="$bgcolor";
		done
		fgcolor="\\E[${fgcolors[RANDOM % 14]}m"
		echo -ne " $fgcolor$t$y$z$fgcolor$t \\E[96m(\\E[36m$w%\\E[96m)\\E[92m            $fgcolor$loca2\\033[m\r"
	}
	timeprogress() {
		local loca="$1"; local loca2="$2";
		loca=$(bc -l <<< scale=2\;"$loca/50")
		for i in {1..50}; do
			progressbar "$i" "$loca2"; 
				sleep "$loca";
			done
			echo -e "\n"
	}
	#timeprogress "$1" "$2"
	timeprogress "$x" "$z"
}

_isTerminalDARK () {
	# return 0 if yes (bg is dark)
	# return 1 if no (bg is light)
	# return 2 if unknown (bg is unknown)
	# adapted from https://github.com/spazm/bash-term-background/blob/master/term-background.sh
	local answer=2
	local RGB_fg
	local RGB_bg
	get_fg_bg() {
		local fg
		local bg
		# disable echo for the following
		stty -echo
		# get        fg       bg     colors with this weird
		echo -ne '\e]10;?\a\e]11;?\a'
		# read the results into $fg and $bg
		IFS=: read -t 0.1 -d $'\a' x fg
		IFS=: read -t 0.1 -d $'\a' x bg
		# re-enable echo
		stty echo
		# if $bg is empty, return 2 (because we have no idea)
		[[ -z $bg ]] && return 2
		# print the results (for debugging)
		#typeset -p fg
		#typeset -p bg
		# read the fg and bg results into indexed arrays
		IFS='/' read -ra RGB_fg <<< $fg
		IFS='/' read -ra RGB_bg <<< $bg
		# print the results (for debugging)
		#typeset -p RGB_fg
		#typeset -p RGB_bg
	}
	is_dark() {
		typeset r g b
		r=$1; g=$2; b=$3
		# calculate the hex rgb codes...
		if (( (16#$r + 16#$g + 16#$b) < 117963 )) ; then
			answer=0
		else
			answer=1
		fi
	}
	get_fg_bg || return 2
	is_dark ${RGB_bg[@]} && return $answer || return 2
}

_toggleTerminalBG() {
	# using xterm escape sequences, query the terminal for fg and bg colors
 	# then swap them	
	local fg
	local bg
	stty -echo
	echo -ne '\e]10;?\a\e]11;?\a'
	IFS=: read -t 0.1 -d $'\a' x fg
	IFS=: read -t 0.1 -d $'\a' x bg
	stty echo
	[[ -z $bg ]] && return 1
	#typeset -p bg
	#typeset -p fg
	IFS='/' read -ra RGB_fg_hex <<< $fg
	IFS='/' read -ra RGB_bg_hex <<< $bg
	#typeset -p RGB_fg_hex
	#typeset -p RGB_bg_hex
	#echo "fg hex: R(${RGB_fg_hex[0]:0:2}) G(${RGB_fg_hex[1]:0:2}) B(${RGB_fg_hex[2]:0:2})"
	bg_set="#${RGB_fg_hex[0]:0:2}${RGB_fg_hex[1]:0:2}${RGB_fg_hex[2]:0:2}"
	#echo $bg_set
	#echo "fg dec: R($((16#${RGB_fg_hex[0]:0:2}))) G($((16#${RGB_fg_hex[1]:0:2}))) B($((16#${RGB_fg_hex[2]:0:2})))"
	#echo "bg hex: R(${RGB_bg_hex[0]:0:2}) G(${RGB_bg_hex[1]:0:2}) B(${RGB_bg_hex[2]:0:2})"
	fg_set="#${RGB_bg_hex[0]:0:2}${RGB_bg_hex[1]:0:2}${RGB_bg_hex[2]:0:2}"
	#echo $fg_set
	#echo "bg dec: R($((16#${RGB_bg_hex[0]:0:2}))) G($((16#${RGB_bg_hex[1]:0:2}))) B($((16#${RGB_bg_hex[2]:0:2})))"
	#echo "fg #${RGB_fg_hex[0]:0:2}${RGB_fg_hex[1]:0:2}${RGB_fg_hex[2]:0:2}"
	# rgb colors format #hex or (int,int,int)
	printf "\033]11;%s\033\\" ${bg_set}
	printf "\033]10;%s\033\\" ${fg_set}
}

# a brute-force kind of xterm-compatible live color adjustment for the terminal
#TODO allow color names to be changed
_adjustColorScheme() {
	# define the ansi 8-bit palette of 16 colors (the names are arbitrary, used
	# for display, and can be changed)
	declare -A ansi_palette=([0]="black" [1]="red" [2]="green" [3]="yellow" [4]="blue" [5]="magenta" [6]="cyan" [7]="white" [8]="grey" [9]="brightred" [10]="brightgreen" [11]="brightyellow" [12]="brightblue" [13]="brightmagenta" [14]="brightcyan" [15]="snow")
	# define the assoc array to store the initial discovered colors
	declare -A initial
	# define the same for the user
	declare -A _user
	# use nameref to pass the _user selected scheme back to the caller
	declare -n _newColorScheme=${1}
	# the list of elements we cycle through with _cycle
	declare -a _cycle=("bg" "fg" "cursor" 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)
	# set the i for cycle()
	local i=0
	# get the scheme as found
	_get_initial() {
		local bg=11		# the SGR code for bg
		local fg=10		# the SGR code for fg
		local cursor=12
		local hex			# the hex string we keep
		# first get the background and foreground and cursor colors
		for x in bg fg cursor; do
			stty -echo
			echo -ne "\e]${!x};?\a"
			IFS=: read -t 0.1 -d $'\a' discard response
			stty echo
			[[ -z $response ]] && return 1
			IFS='/' read -ra hex_array <<< $response
			for value in "${hex_array[@]}"; do
				hex+=${value:0:2}
			done
			initial[$x]=$hex
			hex=""
		done
		# next get the ansi 16
		for x in {0..15}; do
			stty -echo
			echo -ne "\e]4;${x};?\a"
			IFS=: read -t 0.1 -d $'\a' discard response
			stty echo
			[[ -z $response ]] && return 1
			IFS='/' read -ra hex_array <<< $response
			for value in "${hex_array[@]}"; do
				hex+=${value:0:2}
			done
			initial[$x]=$hex
			hex=""
		done
	}

	_printScreen() {
		rgb() {
			# print the hex value in RGB (123,12, 0) using ansi-8 (grey)
			((r=16#${1:0:2},g=16#${1:2:2},b=16#${1:4:2}))
			tuple="($r,$g,$b)"
			printf "\033[38;5;8m%-13s\033[0m" $tuple
		}
		ind() {
			# highlighted the current ansi
			[[ $1 = "${_current}" ]] && printf "\033[7;5m%2s\033[0m" $1 || printf "%2s" $1 
		}
		ind-bg() {
			# highlight the bg when selected
			[[ $1 == "bg" && $1 == $_current ]] && printf "  \033[7;5m%11s\033[0m" "background" || printf "  %11s" "background"
		}
		ind-fg() {
			# highlight the fg when selected
			[[ $1 == "fg" && $1 == $_current ]] && printf "  \033[7;5m%11s\033[0m" "foreground" || printf "  %11s" "foreground"
		}
		ind-curs() {
			[[ $1 == "cursor" && $1 == $_current ]] && printf "  \033[7;5m%11s\033[0m" "cursor" || printf "  %11s" "cursor"
		}
		col() {
			# print the color in the color
			printf "\033[38;5;%sm%-13s\033[0m" $1 ${ansi_palette[$1]}
		}
		get_lum() {
			# print the relative luminance value
			# accept $1 as hex ie "ffffff"
			# use the Digital ITU BT.601 conversion formula
			local _r="0.299"; local r=$((16#${1:0:2}))
			local _g="0.587"; local g=$((16#${1:2:2}))
			local _b="0.114"; local b=$((16#${1:4:2}))
			echo "scale=2; $_r * $r + $_g * $g + $_b * $b" | bc
		}
		mode() {
			# guess the mode (dark or light)
			local bg_lum
			local fg_lum
			local guess
			bg_lum=$(get_lum ${_user["bg"]})
			fg_lum=$(get_lum ${_user["fg"]})
			(( $(echo "$bg_lum > $fg_lum" | bc -l) )) && guess=light || guess=dark
			echo -n "$guess"
		}
		# paint the screen
		clear
		printf "\033[1m(0)reset (1)toggle fg/bg (2)cycle colors (s)save (q)reset and quit\033[0m\n"
		printf "\033[1m(G)+green (g)-green (R)+red (r)-red (B)+blue (b)-blue\033[0m\n"
		echo
		printf ':------base------hex-----r,g,b------luminance-------mode:%s-----------------o\n' $(mode)
		printf '%s #%s %s [%s]\n' "$(ind-bg 'bg')" ${_user["bg"]} "$(rgb ${_user["bg"]})" "$(get_lum ${_user["bg"]})"
		printf '%s #%s %s [%s]\n' "$(ind-fg 'fg')" ${_user["fg"]} "$(rgb ${_user["fg"]})" "$(get_lum ${_user["fg"]})"
		printf '%s #%s %s [%s]\n' "$(ind-curs 'cursor')" ${_user["cursor"]} "$(rgb ${_user["cursor"]})" "$(get_lum ${_user["cursor"]})"
		echo
		printf ':--normal----[ansi 8-bit colors]----------bright-------------------------------o\n'
		printf '%s %s #%s %s %s %s #%s %s\n' "$(ind 0)" "$(col 0)" ${_user[0]} "$(rgb ${_user[0]})" "$(ind 8)" "$(col 8)" ${_user[8]} "$(rgb ${_user[8]})"
		printf '%s %s #%s %s %s %s #%s %s\n' "$(ind 1)" "$(col 1)" ${_user[1]} "$(rgb ${_user[1]})" "$(ind 9)" "$(col 9)" ${_user[9]} "$(rgb ${_user[9]})"
		printf '%s %s #%s %s %s %s #%s %s\n' "$(ind 2)" "$(col 2)" ${_user[2]} "$(rgb ${_user[2]})" "$(ind 10)" "$(col 10)" ${_user[10]} "$(rgb ${_user[10]})"
		printf '%s %s #%s %s %s %s #%s %s\n' "$(ind 3)" "$(col 3)" ${_user[3]} "$(rgb ${_user[3]})" "$(ind 11)" "$(col 11)" ${_user[11]} "$(rgb ${_user[11]})"
		printf '%s %s #%s %s %s %s #%s %s\n' "$(ind 4)" "$(col 4)" ${_user[4]} "$(rgb ${_user[4]})" "$(ind 12)" "$(col 12)" ${_user[12]} "$(rgb ${_user[12]})"
		printf '%s %s #%s %s %s %s #%s %s\n' "$(ind 5)" "$(col 5)" ${_user[5]} "$(rgb ${_user[5]})" "$(ind 13)" "$(col 13)" ${_user[13]} "$(rgb ${_user[13]})"
		printf '%s %s #%s %s %s %s #%s %s\n' "$(ind 6)" "$(col 6)" ${_user[6]} "$(rgb ${_user[6]})" "$(ind 14)" "$(col 14)" ${_user[14]} "$(rgb ${_user[14]})"
		printf '%s %s #%s %s %s %s #%s %s\n' "$(ind 7)" "$(col 7)" ${_user[7]} "$(rgb ${_user[7]})" "$(ind 15)" "$(col 15)" ${_user[15]} "$(rgb ${_user[15]})"
		printf ':---------instructions---------------------------------------------------------o\n'
		printf " > press '2' to cycle through the elements (the active one \033[7;5mblinks\033[0m)\n"
		printf " > use keys 'RGB' to increase red, green, and blue; and 'rgb' to decrease\n"
		printf " > press '1' to swap bg and fg colors, ie toggle light and dark\n"
		printf " > choose a scheme that reads well in \033[3mboth\033[0m light and dark mode\n"
		printf " > p.s. don't forget the cursor -->"
	}

	cycle() {
		# cycles through the $_cycle list (defined above) and sets $_current
		printf '%s' "${_cycle[${i:=0}]}"
		((i=i>=${#_cycle[@]}-1?0:++i)) || :
		# the OR true fixes something obscure to me (which is that when the value is
		# zero the evaluation returns 1)
		_current=${_cycle[$i]}
	}

	reset_initial() {
		# set all the colors back to the initial ones
		for x in "${_cycle[@]}"; do
			if [[ $x = "fg" ]]; then
				printf "\033]10;#%s\033\\" "${initial["fg"]}"
			elif [[ $x = "bg" ]]; then
				printf "\033]11;#%s\033\\" "${initial["bg"]}"
			elif [[ $x = "cursor" ]]; then
				printf "\033]12;#%s\033\\" "${initial["cursor"]}"
			else
				printf "\033]4;%s;#%s\033\\" $x "${initial[$x]}"
			fi
		done
	}

	apply_color() {
		# accepts $1, otherwise, applies $_current
		apply_to=${1:-${_current}}
		if [[ $apply_to = "fg" ]]; then
			printf "\033]10;#%s\033\\" "${_user["fg"]}"
		elif [[ $apply_to = "bg" ]]; then
			printf "\033]11;#%s\033\\" "${_user["bg"]}"
		elif [[ $apply_to = "cursor" ]]; then
			printf "\033]12;#%s\033\\" "${_user["cursor"]}"
		else
			printf "\033]4;%s;#%s\033\\" $apply_to "${_user[$apply_to]}"
		fi
	}

	_set_user() {
		# populates $_user from $_initial
		for key in "${!initial[@]}"; do
			_user["$key"]="${initial[$key]}"
		done
		declare -g _user
	}

	# set the default in the _cycle
	local _current="bg"

	# get the initial settings and populate $initial
	_get_initial
	
	# copy the initial rgb values to the user-adjustable array $_user
	_set_user
	
	# paint the initial screen
	_printScreen

	# loop and read one key
	local __input
	while read -rsn1 __input; do
		case ${__input} in
			0)
				_reset=true
				_set_user
				;;
			1)
				_was_bg=${_user["bg"]}
				_was_fg=${_user["fg"]}
				_user["bg"]=${_was_fg}
				_user["fg"]=${_was_bg}
				apply_color "fg"
				apply_color "bg"
				_skip=true
				;;
			2)
				cycle
				_skip=true
				;;
			s)
				# save the existing _user scheme to _newColorScheme, which is a nameref
				# to _colorScheme in notelos
				for key in "${!_user[@]}"; do
					_newColorScheme[$key]=${_user[$key]}
				done
				printf '\n'
				break
				;;
			R)
				# get the hex rgb value for the current element
				hex=${_user[$_current]}
				# convert hex to decimal (and return true if this evaluation returns
				# false (as it does when b=0 for a reason i don't understand)
				((r=16#${hex:0:2},g=16#${hex:2:2},b=16#${hex:4:2})) || :
				# add one if we are less than 255
				[[ $r -lt 255 ]] && ((r++)) || :
				# set _user (active scheme) 
				_user["$_current"]=$(printf '%02x%02x%02x\n' $r $g $b)
				# this whole routine needs its own function
				;;
			r)
				hex=${_user[$_current]}
				((r=16#${hex:0:2},g=16#${hex:2:2},b=16#${hex:4:2})) || :
				[[ $r -gt 0 ]] && ((r--)) || :
				_user["$_current"]=$(printf '%02x%02x%02x\n' $r $g $b)
				;;
			G)
				hex=${_user[$_current]}
				((r=16#${hex:0:2},g=16#${hex:2:2},b=16#${hex:4:2})) || :
				[[ $g -lt 255 ]] && ((g++)) || :
				_user["$_current"]=$(printf '%02x%02x%02x\n' $r $g $b)
				;;
			g)
				hex=${_user[$_current]}
				((r=16#${hex:0:2},g=16#${hex:2:2},b=16#${hex:4:2})) || :
				[[ $g -gt 0 ]] && ((g--)) || :
				_user["$_current"]=$(printf '%02x%02x%02x\n' $r $g $b)
				;;
			B)
				hex=${_user[$_current]}
				((r=16#${hex:0:2},g=16#${hex:2:2},b=16#${hex:4:2})) || :
				[[ $b -lt 255 ]] && ((b++)) || :
				_user["$_current"]=$(printf '%02x%02x%02x\n' $r $g $b)
				;;
			b)
				hex=${_user[$_current]}
				((r=16#${hex:0:2},g=16#${hex:2:2},b=16#${hex:4:2})) || :
				[[ $b -gt 0 ]] && ((b--)) || :
				_user["$_current"]=$(printf '%02x%02x%02x\n' $r $g $b)
				;;
			q)
				reset_initial
				printf '\n'
				break
				;;
			*)
				reset_initial
				printf '\n'
				break
				;;
		esac

		# apply the intention
		if [[ ${_reset:-} = "true" ]]; then
			reset_initial
			unset _reset
			_skip=true
		fi
		if [[ ${_skip:-} = "true" ]]; then
			unset _skip
		else
			apply_color
		fi
		_printScreen
	done
}

# set the xterm window title
# $ echo -e '\033]0;new window title\a'

# guidance
# https://jeffkreeftmeijer.com/vim-16-color/

_getTerminalCOLORCOUNT() {
	# lets figure out how many colors the term supports
	# bits		colors			name
	#	2				2						monochrome (black and white)
	# 4				16					ansi-16
	# 8				256					ansi-256	
	# 24			16m					truecolor
	# print one of 4 values as defined in _keys (currently only 3/0)
	declare -A _keys=([0]="mono" [1]="ansi-16" [2]="ansi-256" [3]="truecolor")
	local _answer=0
	# first read the color setting for color 78 (arbitrary choice)
	{ printf "\033]4;78;?\007\033\\" >>/dev/tty
		IFS=: read -s -r -t 0.2 -d$'\a' discard original78 2>/dev/null
	} </dev/tty
	[[ -z "${original78}" ]] && return 0
	# next set it to an improbable and different value
	improbable78="ffff/1234/5678"
	[[ $original78 = "ffff/1234/5678" ]] && improbable78="ffff/1234/56ff"
	# next set it to our improbable value and read it back again
	{ printf "\033]4;78;rgb:%s\007\033\\" "$improbable78" >>/dev/tty
		printf "\033]4;78;?\007\033\\" >>/dev/tty
		IFS=: read -s -r -t 0.2 -d$'\a' discard new78 2>/dev/null
	} </dev/tty
	# see if the setting took hold, in which case, we have treucolor
	[[ $improbable78 = $new78 ]] && _answer=3
	# set it back to the original like a good citizen
	printf "\033]4;78;rgb:%s\007\033\\" "$original78" >>/dev/tty
	# print the result
	echo ${_keys[$_answer]}
	# a more thorough hueristic would test many more things
	# this https://github.com/eth-p/my-dotfiles/blob/master/home/.local/libexec/term-query-bg
	# turned out to be the most helpful resource
}

_applyColorScheme() {
	# set all the colors to the values in $1 (nameref)
	local -n colorScheme=$1
	# colorScheme is an assoc array with the scheme
	for x in "${!colorScheme[@]}"; do
		if [[ $x = "fg" ]]; then
			printf "\033]10;#%s\033\\" "${colorScheme["fg"]}"
		elif [[ $x = "bg" ]]; then
			printf "\033]11;#%s\033\\" "${colorScheme["bg"]}"
		elif [[ $x = "cursor" ]]; then
			printf "\033]12;#%s\033\\" "${colorScheme["cursor"]}"
		else
			printf "\033]4;%s;#%s\033\\" $x "${colorScheme[$x]}"
		fi
	done
}

	_isTerminalTRUECOLOR() {
	# check for $COLORTERM first
	[[ $COLORTERM =~ ^(truecolor|24bit)$ ]] && return 0
}


