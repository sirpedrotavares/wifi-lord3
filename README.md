#wifi-lord3
This script allows setup and capture traffic through rogue access points.

To execute it:
  *  **./wifi-lord3.sh**

For more info visits our [wiki](https://github.com/sirpedrotavares/wifi-lord3/wiki).

## :book: How it works

This script has 3 modes:

####Rogue access point (free wifi)
* Launch a rouge Access Point (AP) instance based on templates (MEO-WiFi and NOS WiFi responsive templates availabed by default)
* Test each submitted password online (availabe for MEO-WiFi and NOS WiFi portals)

####Crack WPA without brute-force
* Launch a rogue Access Point (AP) instance
* A fake DNS server is launched in order to capture all DNS requests and redirect them
* A captive portal is launched which prompts the user to enter their login credentials
* Each submitted password is saved 

####Crack WPA via brute-force
* Cracking password network based on brute-force attack

## :pushpin: Version History

###Version 1.1 (2016-11-11)
* Hostapd implemented
* DHCP correction some bugs
* Design improvements
* Console that exhibits the entered passwords
* Online validator for MEO and NOS accounts
* Fix bugs

####Version 1.0 (2016-11-07)
* Macchanger bugs
* Fix problems with wireless cards
* Improvement of airbase-ng process
* Fix all project dependencies
* Channel verification
* Validation of user inputs
* Design improvement
* Resolution of identified issues

####Version 0.1 (2016-11-04)
* Menus improvement
* Macchanger implemented
* Mechanisms to exit the program in case of unexpected termination
* Design updates

## :scroll: Changelog
This script is updated with new features, improvements and fix of identified bugs with some frequency.
Check out the [Changelog] (https://github.com/sirpedrotavares/wifi-lord3).

## :octocat: How to contribute
All contributions are welcome. Please use GitHub to its fullest-- submit pull requests.


##  :heavy_exclamation_mark: Requirements
A Linux operating system and an external wifi card. This script was developed and design to work in arch and debin (kali) linux distribution.

## :octocat: Credits
retinadark - wifi-lord3 main developer

## Disclaimer

***Note: This program is free software. It comes without any warranty, to the extent permitted by applicable law. wifi-lord3 is intended to be used for legal security purposes only. Any other use is not the responsibility of the user.***
