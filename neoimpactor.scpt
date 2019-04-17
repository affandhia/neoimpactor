# Affan Dhia Ardhiva - @affandhia 2019
# inspired from AutoImpactor v2.0 / https://github.com/Shmadul/AutoImpactor and @matsuo3rd 2019
# Download ClicClick at https://github.com/BlueM/cliclick
# Download SleepDisplay at https://github.com/bigkm/SleepDisplay
# error documentation https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/reference/ASLR_error_codes.html
# custom error:
# -401: bad request or invalid input
# -404: the thing is not found


script util
	to split(someText, delimiter)
		set AppleScript's text item delimiters to delimiter
		set someText to someText's text items
		set AppleScript's text item delimiters to {""} --> restore delimiters to default value
		return someText
	end split
	
	to get_filename_from_posix_path(path)
		# split the file by the posix delimiter
		set filepath to split(path, {"/"})
		
		# empty string return null
		if length of filepath is less than 1 then
			return null
		end if
		
		# return the filename which is the last item of the list
		return item ((length of filepath)) of filepath
		
	end get_filename_from_posix_path
	
	to raw_filepath_to_posixpath(filepath)
		return POSIX path of filepath
	end raw_filepath_to_posixpath
	
	on posixpath_to_alias(thepath)
		return posixpath_to_file(thepath) as alias
	end posixpath_to_alias
	
	on posixpath_to_file(thepath)
		return POSIX file thepath
	end posixpath_to_file
	
	on alias_to_posixpath(thealias)
		return POSIX path of thealias
	end alias_to_posixpath
	
	on get_parent_path(thepath)
		set theparent to "/"
		tell application "Finder"
			set theparent to get (container of my posixpath_to_alias(thepath)) as text
		end tell
		-- set theparent to POSIX file (do shell script "dirname " & quoted form of POSIX path of (path to me)) as alias
		return alias_to_posixpath(theparent)
	end get_parent_path
	
	on is_path_exist(thepath)
		try
			posixpath_to_alias(thepath)
			return true
		on error
			return false
		end try
	end is_path_exist
	
	on create_new_file(thepath)
		dump_to_file(thepath, "")
	end create_new_file
	
	on dump_to_file(thepath, thetext)
		set cmde to "echo " & quoted form of thetext & " > " & quoted form of thepath
		run_command(cmde)
	end dump_to_file
	
	on append_to_file(thepath, thetext)
		set cmde to "echo " & quoted form of thetext & " >> " & quoted form of thepath
		run_command(cmde)
	end append_to_file
	
	on run_command(command)
		do shell script command
	end run_command
	
	on list_files_in_folder(thepath)
		set thefiles to list folder posixpath_to_alias(thepath)
		set thefullpathfiles to {}
		repeat with thefile in thefiles
			set end of thefullpathfiles to alias_to_posixpath(posixpath_to_alias(thepath)) & thefile
		end repeat
		return thefullpathfiles
	end list_files_in_folder
end script

script neodialog
	on browse_folder(title)
		set returnvalue to ""
		try
			display dialog title & "\n\nChoose mode" buttons {"Cancel", "Drag & Drop", "Browse..."} default button 3
			if the button returned of the result is "Drag & Drop" then
				display dialog title & "\n\nType or drag the folder into the text field" default answer "" buttons {"Cancel", "Save"} default button 2
				copy the result as list to {text_returned, button_pressed}
				set value to item 2 of the result as string
				
				if value as string is equal to "" then
					error number -401
				end if
				
				set returnvalue to value
			else
				set thefolder to choose folder with prompt title & ":"
				
				set returnvalue to util's alias_to_posixpath(thefolder)
			end if
		on error
			set returnvalue to null
		end try

		if not (util's is_path_exist(returnvalue)) then
			display alert "The folder doesn't exist"
			error number -404
		end if

		return returnvalue
	end browse_folder

	on browse_file(title)
		set returnvalue to ""
		try
			display dialog title & "\n\nChoose mode" buttons {"Cancel", "Drag & Drop", "Browse..."} default button 3
			if the button returned of the result is "Drag & Drop" then
				display dialog title & "\n\nType or drag the file into the text field" default answer "" buttons {"Cancel", "Save"} default button 2
				copy the result as list to {text_returned, button_pressed}
				set value to item 2 of the result as string
				
				if value as string is equal to "" then
					error number -401
				end if
				
				set returnvalue to value
			else
				set thefolder to choose file with prompt title & ":"
				
				set returnvalue to util's alias_to_posixpath(thefolder)
			end if
		on error
			set returnvalue to null
		end try

		if not (util's is_path_exist(returnvalue)) then
			display alert "The file doesn't exist"
			error number -404
		end if

		return returnvalue
	end browse_file

	on text_input(title, allowEmtpy)
		set returnvalue to ""
		try
			display dialog title default answer "" buttons {"Cancel", "Save"} default button 2
			copy the result as list to {text_returned, button_pressed}
			set value to item 2 of the result as string
			
			if not(allowEmtpy) and value as string is equal to "" then
				error number -401
			end if
			
			set returnvalue to value
		on error
			set returnvalue to null
		end try

		return returnvalue
	end text_input
end script

script config
	property appleid : ""
	property pass : ""
	property ipasfolder : ""
	property filepaths : {}
	property device : ""
	property configPath : "newgen.cfg"
	property workdir : ""
	property cliclickfilepath: ""
	property sleepdisplayfilepath: ""
	
	to set_config_path(filepath)
		set configPath to filepath
	end set_config_path
	
	to init()
		__set_workdir()
		__preprocess_configPath()
		__load_config()
		__load_files_in_ipasfolder()
	end init
	
	on __set_workdir()
		set currentFile to my util's alias_to_posixpath(path to me)
		set workdir to my util's get_parent_path(currentFile)
	end __set_workdir
	
	on __preprocess_configPath()
		if not (configPath starts with "/") then
			set configPath to workdir & configPath
		end if
	end __preprocess_configPath
	
	on __load_config()
		if util's is_path_exist(configPath) then
			set lns to paragraphs of (read file (util's posixpath_to_file(configPath)) as «class utf8»)
			# Loop over lines read and copy each to the clipboard.
			repeat with ln in lns
				__line_reducer(ln)
			end repeat
		else
			display dialog "Config file doesn't exist." buttons {"Nah, just exit", "Create config file"} default button 2
			if the button returned of the result is "Nah, just exit" then
				return
			else
				__init_config()
			end if
		end if
	end __load_config
	
	on __validate_input_text(theinput)
		if theinput is null then
			display alert "Unable to continue, all field must be filled correctly."
			log "Invalid input."
			error number -401
		end if
	end __validate_input_text

	on __init_config()
		
		# get email
		set appleid to neodialog's text_input("Apple ID", false)
		__validate_input_text(appleid)
		
		# get password
		set pass to neodialog's text_input("Password (App-Specific)", false)
		__validate_input_text(pass)
		
		# get ipa
		set ipasfolder to neodialog's browse_folder("Select IPA Folder")
		
		# get cliclickfilepath
		set cliclickfilepath to neodialog's browse_file("Select CliClick binary file\nDownload: https://github.com/BlueM/cliclick")

		# get cliclickfilepath
		set sleepdisplayfilepath to neodialog's browse_file("Select SleepDisplay binary file\nDownload: https://github.com/bigkm/SleepDisplay")

		# get device
		set device to neodialog's text_input("Device Label in Impactor", false)
		__validate_input_text(device)
		
		util's dump_to_file(configPath, __to_string())
		__load_config()
	end __init_config
	
	on __extract_line(theline)
		if theline as string is equal to "" then
			return {null, null}
		end if
		set thekey to item 1 of util's split(theline, {"="})
		set the_offset to offset of "=" in theline
		set thevalue to items (the_offset + 1) thru (count theline) of theline as string
		return {thekey, thevalue}
	end __extract_line
	
	on __line_reducer(theline)
		set thedata to __extract_line(theline)
		set thekey to item 1 of thedata
		set thevalue to item 2 of thedata
		
		if thekey as string is equal to "appleid" then
			set appleid to thevalue
		else if thekey as string is equal to "pass" then
			set pass to thevalue
		else if thekey as string is equal to "ipasfolder" then
			set ipasfolder to thevalue
		else if thekey as string is equal to "device" then
			set device to thevalue
		else if thekey as string is equal to "cliclickfilepath" then
			set cliclickfilepath to thevalue
		else if thekey as string is equal to "sleepdisplayfilepath" then
			set sleepdisplayfilepath to thevalue
		end if
	end __line_reducer
	
	on __load_files_in_ipasfolder()
		set filepaths to util's list_files_in_folder(ipasfolder)
	end __load_files_in_ipasfolder
	
	on __to_string()
		set ds to ""
		set ds to ds & "appleid=" & (get appleid of me) & "\n"
		set ds to ds & "pass=" & pass & "\n"
		set ds to ds & "ipasfolder=" & ipasfolder & "\n"
		set ds to ds & "device=" & device & "\n"
		set ds to ds & "cliclickfilepath=" & cliclickfilepath & "\n"
		set ds to ds & "sleepdisplayfilepath=" & sleepdisplayfilepath & "\n"
		
		return ds
	end __to_string
end script

on wakeup_screen(sleepdisplayfilepath)
	log "Waking up Display"
	if util's is_path_exist(sleepdisplayfilepath) then
		do shell script sleepdisplayfilepath & " -wake"
	else
		error number -404
	end if
end wakeup_screen

on launch_impactor()
	log "Launching Impactor and focus"
	tell application "Impactor" to activate
end launch_impactor

on select_device(deviceLabel, cliclickfilepath)
	log "Looking for Device " & deviceLabel
	set targetDevice to null
	
	tell application "System Events" to tell process "Impactor"
		click button 1 of combo box 2 of window "Cydia Impactor"
		delay 0.25
		set devices to (text fields of list 1 of scroll area 1 of combo box 2 of window "Cydia Impactor")
		set devicesCount to (count devices)
		
		if devicesCount ≥ 1 then
			repeat with device in devices
				set deviceName to value of device
				if deviceName = deviceLabel then
					set targetDevice to device
					exit repeat
				end if
			end repeat
		end if
		
		# Get TargetDevice position in Combo Box
		log "Looking for Device's dropdown list x,y position"
		if targetDevice is not null then
			log "Device Found"
			tell targetDevice
				set {xPosition, yPosition} to position of targetDevice
				set {xSize, ySize} to size
			end tell
			set {realXPosition, realYPosition} to {(xPosition + (xSize div 2)) as string, (yPosition + (ySize div 2)) as string}
		else
			log "Device Not Found"
			display dialog "Could not find Target Device " & deviceLabel
			my quit_impactor()
			error number -128
		end if
	end tell
	
	# Click Target Device
	log "Clicking on Device at m:" & realXPosition & "," & realYPosition & " dc:" & realXPosition & "," & realYPosition
	tell application "System Events" to tell process "Impactor"
		click button 1 of combo box 2 of window "Cydia Impactor"
	end tell

	if util's is_path_exist(cliclickfilepath) then
		do shell script cliclickfilepath & " m:" & realXPosition & "," & realYPosition & " dc:" & realXPosition & "," & realYPosition
	else
		error number -404
	end if
	
	delay 0.25
end select_device

on select_ipa_file(filepath)
	log "Launching \"Install Package...\" menu"
	
	tell application "Impactor" to activate
	tell application "System Events" to tell process "Impactor"
		click menu item "Install Package..." of menu 1 of menu bar item "Device" of menu bar 1
	end tell
	
	delay 0.25
	
	# Select IPA file
	log "Entering IPA file " & filepath
	
	#tell application "System Events"
	launch_impactor()
	tell application "System Events" to tell process "Impactor"
		keystroke "G" using {shift down, command down}
		delay 0.5
	-- end tell
	
	-- launch_impactor()
	-- tell application "System Events" to tell process "Impactor"
		keystroke filepath
		delay 3
		keystroke return
		delay 1
		keystroke return
		delay 0.5
	end tell
end select_ipa_file

on input_username(username)
	log "Entering Apple ID Username " & username
	tell application "System Events" to tell process "Impactor"
		set value of text field 1 of window "Apple ID Username" to username
		click button "OK" of window "Apple ID Username"
	end tell
end input_username

on input_password(password)
	log "Entering Apple ID Password"
	tell application "System Events" to tell process "Impactor"
		set value of text field 1 of window "Apple ID Password" to password
		click button "OK" of window "Apple ID Password"
	end tell
end input_password

on fill_credentials(username, password)
	#"Apple ID Username"
	input_username(username)
	
	delay 1
	
	#"Apple ID Password"
	input_password(password)
end fill_credentials

on installation_watcher(filename, index)
	log "Installing file " & filename
	tell application "System Events" to tell process "Impactor"
		delay 1
		
		set isSuccess to true
		
		repeat until (not (exists progress indicator 1 of window "Cydia Impactor"))
			log "Checking installation status..."
			
			set listdialog to get windows whose description is "dialog"
			
			repeat with dialogwindow in listdialog
				tell dialogwindow
					if exists static text "Error" then
						set errmsg to ""
						repeat with thestatictext in (every static text)
							set errmsg to errmsg & (value of thestatictext) & " "
						end repeat
						log errmsg
						
						set isSuccess to isSuccess and false
					end if
					
					if exists button "OK" then
						log "Closing the dialog..."
						click button "OK"
					end if
				end tell
			end repeat
			
		end repeat
		
		# send the notification
		-- if isSuccess then
		-- 	my complete_notification(filename, index)
		-- else
		-- 	my failed_notification(filename, index)
		-- end if
	end tell
end installation_watcher

on complete_notification(filename, index)
	display notification "Installation done." with title "#" & index & " IPA Completed" subtitle filename sound name "Frog"
	beep 1
end complete_notification

on failed_notification(filename, index)
	display notification "Installation failed." with title "#" & index & " IPA Failed" subtitle filename sound name "Frog"
	beep 2
end failed_notification

on install_ipa(deviceLabel, filepaths, username, password, cliclickfilepath, sleepdisplayfilepath)
	# Wakeup Screen - if Screen is Sleeping / cliclick (selecting target device) will not work
	wakeup_screen(sleepdisplayfilepath)
	
	# Launch the impactor
	launch_impactor()
	
	# Search for TargetDevice in Devices Combo Box
	select_device(deviceLabel, cliclickfilepath)
	
	# wrap literal string into a list, list will not be wrapped
	set filepathsAsList to filepaths as list
	
	if length of filepathsAsList is greater than 0 then
		log "Processing these files: " & filepathsAsList
		
		set counter to 1
		
		repeat with filepath in filepathsAsList
			set filename to util's get_filename_from_posix_path(filepath) of me
			log "Installing file \"" & filename & "\" [ #" & counter & " ]"
			# select the ipa file via "install package..." menu
			select_ipa_file(filepath)
			
			# fill the apple id and password
			fill_credentials(username, password)
			
			# Wait for IPA sideload to complete and quit Cydia Impactor
			installation_watcher(filename, counter)
			
			set counter to counter + 1
		end repeat
	else
		log "There is no file to be installed. Please put the considered files to the folder."
	end if
end install_ipa

on install_ipa_with_config(theconfig)
	install_ipa(get device of theconfig, get filepaths of theconfig, get appleid of theconfig, get pass of theconfig, get cliclickfilepath of theconfig, get sleepdisplayfilepath of theconfig)
end install_ipa_with_config

on quit_impactor()
	tell application "Impactor"
		quit
	end tell
end quit_impactor

on main()
	set CONFIG_PATH to "neoimpactor.cfg"
	
	tell config to set_config_path(CONFIG_PATH)
	tell config to init()
	
	install_ipa_with_config(config)
	quit_impactor()
end main

main()