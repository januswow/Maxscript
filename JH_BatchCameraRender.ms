/*
	JH_BatchCameraRender
	Copyright (C) 2015, Janus Huang
	januswow@gmail.com
	http://januswow.blogspot.tw/
	Tested in 3dsMax 2012
	
	This tool is based on
	Batch Camera Render 2, maxscript tool for batch rendering in 3ds max
	By Sergo Pogosyan (www.sergepogosyan.com, contact@sergepogosyan.com)
*/

macroScript JH_BatchCameraRender
	category:"Janus Huang"
	toolTip:"JH_BatchCameraRender"
	buttonText:"JH_BatchCameraRender"
(
	-- standard values
	local isDialogOpen = false
	-- for batch multiple files
	batchIniFilename = "batchCameraRender_batch.ini"
	-- for batch single file
	iniFileSuffix = "_batch.ini"
	iniSectionPrefix = "Batch_"
	standard_columns = #("Batch Name", "Camera", "Frames", "Width", "Height", "Output Path", "Output Filename", "Render Preset")
	standard_key = #("Checked", "Batch Name", "Camera", "Frames", "Width", "Height", "Output Path", "Output Filename", "Render Preset")
	standard_resolution = #([320,240],[640,480],[768,576],[900,600],[1024,1024],[1200,800],[1200,960],[1500,1000],[1920,1080],[2048,2048],[2400,1200],[2400,1920])
	
	global output_lastRenderPath = ""
	
	-- expose values for render purpose
	renderingFrame = 0;
	renderingCount = 0;
	renderingBatchname = "New Batch"
	renderingCamera = "Camera777"
	
	-- expose rollout
	global mainRolloutFloater
	global rollout_batchManager
	rollout_batchSettings
	rollout_camera
	rollout_resolution
	rollout_frameRange
	rollout_output
	
	-- expose function
	global fill_ListView
	global fill_uiElements

	----------------------------------------------------------------------------------------------------
	-- Basic Functions
	----------------------------------------------------------------------------------------------------

	fn isValidValue val =
	(
		if val != "" and val != "undefined" and val != undefined then
		(
			return true
		) else (
			return false
		)
	)
	
	fn appendInt ary i =
	(
		if ary != undefined and i != undefined do
		(
			if classof i != integer do i = i as integer
			if i != undefined do append ary i
		)
	)
	
	fn removeEndingSlash str =
	(
		if str != "" and str != undefined do
		(
			tempStr = subString str (str.count) -1
			if tempStr == "\\" do str = subString str 1 (str.count-1)
		)
		return str
	)

	fn arrayStringToArray str=
	(
		-- parse filenames array string to filenames array
		tmpStr = subString str 4 -1
		tmpArray = filterString tmpStr "\""
		newArray = for s in tmpArray where s.count > 3 collect s
				
		return newArray
	)
	
	fn openFileDialog =
	(
		-- open file dialog from DotNet for selecting multiple files
		filesArray = undefined
		
		ofd = DotNetObject "System.Windows.Forms.OpenFileDialog"
		ofd.Title = "Files to Batch..."
		ofd.Filter = "3ds Max(*.max)|*.max|All files (*.*)|*.*"
		ofd.InitialDirectory = maxFilepath
		ofd.Multiselect = true
		
		ofdResult = ofd.ShowDialog()
		ofdResult.toString()
		
		if ofdResult.equals ofdResult.OK do filesArray = ofd.filenames
		
		return filesArray
	)
	
	fn findAndSetDLL dllObj val =
	(
		-- set dropdownlist selection
		if isValidValue val do
		(
			ddlIndex = findItem dllObj.items val
			if ddlIndex > 0 then
			(
				-- val is exist
				dllObj.selection = ddlIndex
			) else (
				-- val is not exist
				dllObj.selection = 0
			)
		)
	)
	
	fn updateUIState =
	(
		-- toggle enabled state of ui
		if rollout_batchManager.listView_main.selectedItems.count > 0 then myState = true else myState = false
		
		rollout_batchManager.btn_duplicate.enabled = myState
		rollout_batchManager.btn_delete.enabled = myState
		
		for ctrl in rollout_batchSettings.controls do ctrl.enabled = myState
		for ctrl in rollout_camera.controls do ctrl.enabled = myState
		for ctrl in rollout_resolution.controls do ctrl.enabled = myState
		for ctrl in rollout_frameRange.controls do ctrl.enabled = myState
		for ctrl in rollout_output.controls where ctrl.caption != "Open" do ctrl.enabled = myState
		--if false then rollout_output.btn_output_filepath_open.enabled = true else rollout_output.btn_output_filepath_open.enabled = false
		
		if rollout_batchManager.listView_main.checkedItems.count > 0 then myState = true else myState = false
		rollout_batchManager.btn_render.enabled = myState
	)
	
	----------------------------------------------------------------------------------------------------
	-- Camera Functions
	----------------------------------------------------------------------------------------------------

	fn getCameras =
	(
		-- get all cameras in file
		camerasArray = for obj in cameras where iskindof obj camera collect obj.name
		return camerasArray
	)

	fn init_CameraDDL =
	(
		-- initialize camera drop down list
		rollout_camera.ddl_cameras.items = #()
		--rollout_camera.ddl_cameras.items = #("Top", "Front", "Left")
		
		customCameras = getCameras()
		if customCameras.count > 0 do
		(
			join rollout_camera.ddl_cameras.items customCameras
		)
		rollout_camera.ddl_cameras.items = rollout_camera.ddl_cameras.items
	)
	
	----------------------------------------------------------------------------------------------------
	-- INI Functions
	----------------------------------------------------------------------------------------------------
	
	fn generateSectionName index = 
	(
		newSectionName = iniSectionPrefix + index as string
		return newSectionName
	)

	fn getIniFilename =
	(
		local maxFilenameWithoutExt = subString maxFilename 1 (maxFilename.count - 4)
		local iniFilename = maxFilepath + maxFilenameWithoutExt + iniFileSuffix
		return iniFilename
	)

	fn getBatchIniFilename =
	(
		local maxFilenameWithoutExt = subString maxFilename 1 (maxFilename.count - 4)
		local iniFilename = maxFilepath + batchIniFilename
		return iniFilename
	)

	fn readBatchIniValue = (
		iniFilename = getBatchIniFilename()
		return (getIniSetting iniFilename "Files to batch" "Filenames")
	)

	fn writeBatchIniValue val =
	(
		-- write file list into 1 Section to ini File
		-- val is full filenames (array to string)
		if (maxFilename != "") do
		(
			iniFilename = getBatchIniFilename()
			try(setFileAttribute iniFilename #readOnly false)catch()
			
			setIniSetting iniFilename "Files to batch" "Filenames" (val as string)
		)
	)

	fn getLastIniSectionIndex =
	(
		iniFilename = getIniFilename()
		index = -1
		do (
			index += 1
			lastBatch = generateSectionName index
		) while (hasINISetting iniFilename lastBatch)
		index -= 1
		return index
	)

	fn getLastIniSectionLength =
	(
		myLength = getLastIniSectionIndex() + 1
		return myLength
	)

	fn readIniValue sectionIndex key = (
		if sectionIndex > -1 then
		(
			iniFilename = getIniFilename()
			newSectionName = generateSectionName sectionIndex
			return (getIniSetting iniFilename newSectionName key)
		) else (
				format "Function : readIniValue, sectionIndex < 0"
		)
	)

	fn writeIniValue sectionIndex key val =
	(
		if (maxFilename != "") do
		(
			iniFilename = getIniFilename()
			try(setFileAttribute iniFilename #readOnly false)catch()
			
			if sectionIndex > -1 then
			(
				newSectionName = generateSectionName sectionIndex
				setIniSetting iniFilename newSectionName key val
			) else (
					format "Function : %, %.\n" "writeIniValue" "sectionIndex < 0"
			)
		)
	)
	
	fn writeIniValues sectionIndices key val =
	(
		-- write INI values to multiple sections
		-- section means list item
		if (maxFilename != "") do
		(
			iniFilename = getIniFilename()
			try(setFileAttribute iniFilename #readOnly false)catch()
			
			for sectionIndex in sectionIndices do
			(
				if sectionIndex > -1 then
				(
					newSectionName = generateSectionName sectionIndex
					setIniSetting iniFilename newSectionName key val
				) else (
						format "Function : %, %.\n" "writeIniValues" "sectionIndex < 0"
				)
			)
		)
	)
	
	fn newBatch =
	(
		-- add new batch to INI data and refresh list view
		if (maxFilename != "") do
		(
			iniFilename = getIniFilename()
			try(setFileAttribute iniFilename #readOnly false)catch()
			
			sectionIndex = getLastIniSectionLength()
			newSectionName = generateSectionName sectionIndex
			
			writeIniValue sectionIndex "Batch Name" "New Batch"
		)
		fill_listview()
	)
	
	fn duplicateIniValues sourceIndex destinationIndex =
	(
		for keyName in standard_key do
		(
			thisValue = readIniValue sourceIndex keyName
			if thisValue != undefined do writeIniValue destinationIndex keyName thisValue
		)
	)
	
	fn deleteIniSection sectionIndex =
	(
		if (maxFilename != "") do
		(
			iniFilename = getIniFilename()
			lastSectionIndex = getLastIniSectionIndex()
			
			newSectionName = generateSectionName sectionIndex
			delIniSetting iniFilename newSectionName
			
			if sectionIndex <  lastSectionIndex do
			(
				-- if the deleted one is not the last section, need to resort all of rest sections
				for i = sectionIndex to lastSectionIndex do
				(
					duplicateIniValues (i+1) i
				)
				lastSectionName = generateSectionName lastSectionIndex
				delIniSetting iniFilename lastSectionName
			)
		)
	)
	
	----------------------------------------------------------------------------------------------------
	-- List View Functions
	----------------------------------------------------------------------------------------------------
	
	fn init_ListView = 
	(
		listviewObj = rollout_batchManager.listView_main
		listviewObj.BeginUpdate()
		
		--dotNet object initialization
		listviewObj.GridLines = true
		listviewObj.CheckBoxes = true
		listviewObj.Sorting = (dotNetClass "System.Windows.Forms.SortOrder").None
		listviewObj.HeaderStyle = (dotNetClass "System.Windows.Forms.ColumnHeaderStyle").NonClickable
		listviewObj.View = (dotNetClass "System.Windows.Forms.View").Details
		listviewObj.FullRowSelect = true
		listviewObj.HideSelection = false
		
		listviewObj.Columns.Clear()		
		for i in standard_columns do listviewObj.Columns.add i		
		listviewObj.EndUpdate()
	)

	fn addListViewSubItem listItem subItemName subItemValue =
	(	
		sub_item = undefined	
		
		if (subItemValue != "") then
		(
			sub_item = listItem.SubItems.add (subItemValue as string)
		) else (
			sub_item = listItem.SubItems.add "undefined"
		)
		
		if (subItemValue == "undefined") then
		(
			sub_item.ForeColor = sub_item.ForeColor.LightGray
			sub_item.Font = dotnetobject "System.Drawing.Font" sub_item.Font (dotnetclass "System.Drawing.FontStyle").Italic
		) else (
			sub_item.ForeColor = sub_item.ForeColor.Black
			sub_item.Font = dotnetobject "System.Drawing.Font" sub_item.Font (dotnetclass "System.Drawing.FontStyle").Regular
		)
			
		sub_item.name = subItemName as string
	)

	fn setListViewItem listItems subItemValue =
	(	
		for listItem in listItems do
		(		
			listItem.text = subItemValue as string
		)
	)

	fn setListViewSubItems listItems subItemName subItemValue =
	(	
		for listItem in listItems do
		(
			sub_item = listItem.SubItems.item subItemName
			if sub_item != undefined do sub_item.text = subItemValue as string
		)
	)

	fn getListViewSelectedIndex =
	(
		if rollout_batchManager.listView_main.selectedIndices.count > 0 then
		(
			selectedIndex = rollout_batchManager.listView_main.selectedIndices.item 0
		) else (
			selectedIndex = -1
		)
		return selectedIndex
	)
	
	fn getListViewSelectedIndices =
	(
		selectedArray = #()
		if rollout_batchManager.listView_main.selectedIndices.count > 0 do
		(
			for i = 0 to rollout_batchManager.listView_main.selectedIndices.count - 1 do
			(
				append selectedArray (rollout_batchManager.listView_main.selectedIndices.item i)
			)
		)
		return selectedArray
	)

	fn getListViewSelectedItems = 
	(
		selectedItems = #()
		for i=0 to (rollout_batchManager.listView_main.SelectedItems.Count - 1) do append selectedItems (rollout_batchManager.listView_main.SelectedItems.Item i)
		
		return selectedItems
	)

	fn getListItemCheckState listviewObj index =
	(
		if not index > (listviewObj.Items.Count-1) then
		(
			val = (listviewObj.Items.item index).checked
		) else (
			val = undefined
		)
		return val
	)
	
	fn getListViewCheckedIndices =
	(
		checkedArray = #()
		if rollout_batchManager.listView_main.checkedIndices.count > 0 do
		(
			for i = 0 to rollout_batchManager.listView_main.checkedIndices.count - 1 do
			(
				append checkedArray (rollout_batchManager.listView_main.checkedIndices.item i)
			)
		)
		return checkedArray
	)
	
	fn fill_ListView =
	(
		-- fill data from INI to list view
		listviewObj = rollout_batchManager.listView_main
		-- get existing items length in ini file
		listviewObj.Items.Clear()
		sectionLength = getLastIniSectionLength()
		if (sectionLength > 0) then
		(
			itemsArray = #()		
			for sectionIndex = 0 to sectionLength - 1 do
			(
				-- fill each item's data to list view
				li = dotNetObject "System.Windows.Forms.ListViewItem"
				
				for keyName in standard_key do
				(
					case keyName of
					(
						"Checked":
						(
							li.checked = (readIniValue sectionIndex keyName) == "true"
						)
						"Batch Name":
						(
							li.text = readIniValue sectionIndex keyName
						)
						"Camera":
						(
							addListViewSubItem li keyName (readIniValue sectionIndex keyName)
						)
						"Frames":
						(
							addListViewSubItem li keyName (readIniValue sectionIndex keyName)
						)
						"Width":
						(
							addListViewSubItem li keyName (readIniValue sectionIndex keyName)
						)
						"Height":
						(
							addListViewSubItem li keyName (readIniValue sectionIndex keyName)
						)
						"Output Path":
						(
							addListViewSubItem li keyName (readIniValue sectionIndex keyName)
						)
						"Output Filename":
						(
							addListViewSubItem li keyName (readIniValue sectionIndex keyName)
						)
						"Render Preset":
						(
							addListViewSubItem li keyName (readIniValue sectionIndex keyName)
						)
						default:
						(
							addListViewSubItem li keyName "undefined"
						)
					)
				)
				append itemsArray li
			)
			
			listviewObj.Items.AddRange itemsArray--when done, we populate the ListView
			listviewObj.AutoResizeColumns (dotNetClass "System.Windows.Forms.ColumnHeaderAutoResizeStyle").HeaderSize
		) else (
			format "Function : %, %.\n" "fill_ListView" "sectionLength < 1"
		)
	)
	
	----------------------------------------------------------------------------------------------------
	-- Filename sytax Functions
	----------------------------------------------------------------------------------------------------
	
	fn parseKeyword keyword =
	(
		-- parse filename syntax
		result = undefined		
		if keyword != undefined do
		(
			keyword = toLower keyword
			filteredKeyword = filterString keyword "^"
			
			case filteredKeyword[1] of
			(
				"filepath":
				(
					if maxFilepath != "" and filteredKeyword.count == 1 do result = maxFilepath
				)
				"filename":
				(
					if maxFilename != "" and filteredKeyword.count == 1 do result = substring maxFilename 1 (maxfilename.count-4)
				)
				"date":
				(
					if filteredKeyword.count == 1 then
					(
						result = ((dotnetclass "System.DateTime").Now).ToString("yyyyMMdd")
					) else  if filteredKeyword.count == 2 then (
						-- date^customCode
						result = ((dotnetclass "System.DateTime").Now).ToString(filteredKeyword[2])
					)
				)
				"count":
				(
					countNum = renderingCount
					if filteredKeyword.count == 1 then
					(
						result = countNum as string
					) else  if filteredKeyword.count == 2 then (
						-- date^customCode
						formatOption = "0" + filteredKeyword[2] + "u"
						result = formattedPrint countNum format:formatOption
					)
				)
				"frame":
				(
					frameNum = renderingFrame
					if filteredKeyword.count == 1 then
					(
						result = frameNum as string
					) else  if filteredKeyword.count == 2 then (
						-- date^customCode
						formatOption = "0" + filteredKeyword[2] + "u"
						result = formattedPrint frameNum format:formatOption
					)
				)
				"camera":
				(
					result = renderingCamera
				)
				"batchname":
				(
					result = renderingBatchname
				)
			)
		)
		return result
	)

	fn parseFilenameSyntax str =
	(
		originalStr = str
		safeCount = 0
		result = undefined
		continueFlag = true		
		do
		(
			keywordString = undefined
			safeCount += 1
			keywordStartIndex = findString str "%"
			if keywordStartIndex != undefined do
			(
				-- found first pattern
				headString = substring str 1 (keywordStartIndex-1)
				tempString = substring str (keywordStartIndex+1) -1
				keywordEndIndex = findString tempString "%"
				if keywordEndIndex != undefined do
				(
					-- found second pattern
					keywordString = substring str (keywordStartIndex+1) (keywordEndIndex-1)					
					restString = subString tempString (keywordEndIndex+1) -1					
					-- check keyword is valid
					if parseKeyword keywordString != undefined then
					(
						result = headString + (parseKeyword keywordString) + restString
						str = result
					)
				)
			)
			if (parseKeyword keywordString) == undefined or safeCount > 30 then continueFlag = false
		) while (continueFlag)
		if result == undefined do result = originalStr
		return result
	)
	
	fn previewOutputFilename =
	(
		selectedIndex = getListViewSelectedIndex()
		-- set properties
		renderingCamera = readIniValue selectedIndex "Camera"
		renderingBatchname = readIniValue selectedIndex "Batch Name"
		
		filepathString = parseFilenameSyntax rollout_output.edt_output_filepath.text
		filenameString = parseFilenameSyntax rollout_output.edt_output_filename.text
		rollout_output.edt_output_preview.text = pathConfig.appendPath filepathString filenameString
	)
	
	----------------------------------------------------------------------------------------------------
	-- Render presets Functions
	----------------------------------------------------------------------------------------------------
	
	fn getRenderPresetNames =
	(
		renderPresetNames = #()
		if (maxVersion())[1] >= 11000 then	--run renderPresetMRUList command only if script is running under 3dsmax 2009+
			renderPresetNames = for i in renderPresetMRUList where (i[1]!="") collect i[1]
		-- 	sort render_preset_array
		return renderPresetNames 
	)

	fn getRenderPresetArray =
	(
		renderPresetArray = #()
		if (maxVersion())[1] >= 11000 then	--run renderPresetMRUList command only if script is running under 3dsmax 2009+
			renderPresetArray = renderPresetMRUList
		-- 	sort render_preset_array
		return renderPresetArray 
	)
	
	fn getRenderPresetFilenameByName str = 
	(
		reseult = undefined
		renderPresetArray = getRenderPresetArray()
		for preset in renderPresetArray where preset[1] == str do reseult = preset[2]
		return reseult
	)
	
	fn updateRenderPresets =
	(
		-- update render presets drop down list
		rollout_batchSettings.ddl_renderPresets.items = getRenderPresetNames()
		rollout_batchSettings.ddl_renderPresets.selection = 0
	)
	
	----------------------------------------------------------------------------------------------------
	-- Resolution Functions
	----------------------------------------------------------------------------------------------------

	fn init_ResolutionDDL =
	(
		-- initialize standard resolution drop down list (resolution presets)
		local resolutionArray = #()
		for item in standard_resolution do
		(
			local newRes = (item[1] as integer) as string + " x " + (item[2] as integer) as string
			append resolutionArray newRes
		)
		
		rollout_resolution.ddl_resolutionPresets.items = resolutionArray
	)

	fn getStandardResolution index =
	(
		-- set resoltion value from selected standard resolution
		local width = standard_resolution[index][1]
		local height = standard_resolution[index][2]
		
		-- update UI, INI, List View
		rollout_resolution.spn_resolutionWidth.value = width
		writeIniValues (getListViewSelectedIndices()) "Width" ((width as integer) as string)
		setListViewSubItems (getListViewSelectedItems()) "Width" ((width as integer) as string)
		
		rollout_resolution.spn_resolutionHeight.value = height
		writeIniValues (getListViewSelectedIndices()) "Height" ((height as integer) as string)
		setListViewSubItems (getListViewSelectedItems()) "Height" ((height as integer) as string)
	)
	
	----------------------------------------------------------------------------------------------------
	-- Fill UI elements Functions
	----------------------------------------------------------------------------------------------------
	
	fn fill_uiElements =
	(
		-- fill data from INI to UI of selected list item
		listviewObj = rollout_batchManager.listView_main
		if listviewObj.selectedIndices.count > 0 then
		(
			lastValue = true
			equalFlag = true
			selectedListItemIndices = getListViewSelectedIndices()
			for keyName in standard_key do
			(
				for selectedListItemIndex in selectedListItemIndices do
				(
					val = readIniValue selectedListItemIndex keyName
					
					case keyName of
					(
						"Checked": ()	
						"Batch Name":
						(
							if isValidValue val then rollout_batchSettings.edt_batchName.text = val else rollout_batchSettings.edt_batchName.text = ""
						)						
						"Camera":
						(
							init_CameraDDL()
							findAndSetDLL rollout_camera.ddl_cameras val
						)						
						"Frames":
						(
							if isValidValue val then rollout_frameRange.edt_frames.text = val else rollout_frameRange.edt_frames.text = ""
						)						
						"Width":
						(
							rollout_resolution.ddl_resolutionPresets.selection = 0
							rollout_resolution.spn_resolutionWidth.value = val as integer
						)						
						"Height":
						(
							rollout_resolution.spn_resolutionHeight.value = val as integer
						)						
						"Output Path":
						(
							rollout_output.edt_output_filepath.text = val
							previewOutputFilename()
							if doesFileExist (parseFilenameSyntax val) then rollout_output.btn_output_filepath_open.enabled = true else rollout_output.btn_output_filepath_open.enabled = false
						)						
						"Output Filename":
						(
							rollout_output.edt_output_filename.text = val
							previewOutputFilename()
						)						
						"Render Preset":
						(
							updateRenderPresets()
							findAndSetDLL rollout_batchSettings.ddl_renderPresets val
						)						
						default: ()
					)
					lastValue = val
				)
			)
		) else (
			--format "Function : %, %. value : %\n" "fill_uiElements" "listviewObj.selectedIndices.count < 1" (listviewObj.selectedIndices.count as string)
		)
	)
	
	----------------------------------------------------------------------------------------------------
	-- Render Functions
	----------------------------------------------------------------------------------------------------
	
	fn parseFramesStringToArray str =
	(
		framesWaitForRender = #()
		filteredCommaStr = filterString str ","
		for s in filteredCommaStr do
		(
			if findString s "-" == undefined then
			(
				appendInt framesWaitForRender (s as integer)
			) else (
				filteredDashStr = filterString s "-"
				if filteredDashStr.count == 2 then
				(
					sortIntArray = #()
					for i in filteredDashStr do appendInt sortIntArray (i as integer)
					sortIntArray = sort sortIntArray
					if sortIntArray.count == 2 do
					(
						for j = sortIntArray[1] to sortIntArray[2] do
						(
							appendInt framesWaitForRender j
						)
					)
				)
			)
		)
		return framesWaitForRender
	)
	
	fn renderFrame frame camera_obj output_width output_height outputFile quiet =
	(
		-- MAXScript HELP : Controlling the Renderer / Render Scene Dialog 
		result = render frame:frame camera:camera_obj outputSize:[output_width, output_height] outputfile:outputFile vfb:(not quiet) progressbar:true quiet:quiet
		format "%\n\t...Done\n" result
	)
	
	fn renderHandler checkedIndices =
	(		
		for index in checkedIndices do
		(
			-- each selected index
			if keyboard.escPressed do
			(
				messageBox "Batch Process aborted by User"
				exit
			)
			framesString = readIniValue index "Frames"
			framesWaitForRender = parseFramesStringToArray framesString
			
			renderingBatchname = readIniValue index "Batch Name"
			renderingCamera = readIniValue index "Camera"
			myCamera = getNodeByName renderingCamera
			
			if isvalidNode myCamera and iskindof myCamera Camera then
			(
				myWidth = (readIniValue index "Width") as integer
				myHeight = (readIniValue index "Height") as integer
				
				if myWidth < 1 or myHeight < 1 or myWidth == undefined or myHeight == undefined then
				(
					format "Resolution is not valid. Batch : % aborted.\n" renderingBatchname
				) else (
					myQuiet = rollout_batchManager.ckb_output_quietMode.checked
					
					myRenderPreset = readIniValue index "Render Preset"
					renderPresetFile = getRenderPresetFilenameByName myRenderPreset
					if renderPresetFile != undefined and doesFileExist renderPresetFile then
					(
						renderPresets.loadAll 0 renderPresetFile
					) else (
						format "Load render preset failed. Preset File : % does not exist. Batch : % aborted\n" renderPresetFile renderingBatchname
					)
					
					for f in framesWaitForRender do
					(
						if keyboard.escPressed do
						(
							messageBox "Batch Process aborted by User"
							exit
						)
						-- update counter for filename
						renderingFrame = f
						renderingCount +=1
						
						filepathString = removeEndingSlash(parseFilenameSyntax (readIniValue index "Output Path"))
						filenameString = parseFilenameSyntax (readIniValue index "Output Filename")
						myOutput = pathConfig.appendPath filepathString filenameString
						output_lastRenderPath = myOutput
						rollout_batchManager.btn_output_openLastRendered.enabled = true
						
						-- check output destination is valid
						if not doesFileExist filepathString do
						(
							-- path not exist, need create folder
							makeDir filepathString
							format "Create folder : %\n" filepathString
						)
						
						if doesFileExist filepathString then
						(
							-- render each frame
							format "============== Rendering % ==============\n" renderingBatchname
							format "Frame : %, Camera : %\n" f myCamera.name
							format "Width : %, Height : %\n" myWidth myHeight
							--format "filepathString : %\nfilenameString : %\n" filepathString filenameString
							--format "myOutput : %\n" myOutput
							renderFrame f myCamera myWidth myHeight myOutput myQuiet
						) else (
							format "Output destination is not valid (%). Batch : % aborted.\n" myOutput renderingBatchname
						)
					)
					-- reset counter
					renderingFrame = 0
					renderingCount = 0
				)
			) else (
				format "Camera does not exist. Batch : % aborted.\n" renderingBatchname
			)
		)
	)
	
	----------------------------------------------------------------------------------------------------
	-- Rollouts
	----------------------------------------------------------------------------------------------------

	rollout rollout_batchManager "Batch Manager"
	(
		button btn_refresh "Refresh" align:#left width:70 across:6
		button btn_addBatch "Add" align:#left width:70
		button btn_duplicate "Duplicate" align:#left width:70 enabled:false
		button btn_delete "Delete" align:#left width:70 enabled:false
		button btn_selectAll "Select All" align:#left width:70
		button btn_checkAll "Check All" align:#left width:70
		
		dotNetControl listView_main "System.Windows.Forms.ListView" height:170
		
		button btn_output_openLastRendered "Open Last Rendered Folder" align:#left across:4 enabled:false
		checkbox ckb_output_quietMode "Quiet mode"checked:true align:#right offset:[40,0]
		button btn_render "Render ..." align:#right width:80 offset:[20,0]
		button btn_batch "Batch ..." align:#right width:80
		
		on rollout_batchManager open do
		(
			init_ListView()
			fill_ListView()
			
			callbacks.addScript #filePostOpen "fill_ListView()" id:#JH_BatchCameraRender
			callbacks.addScript #filePostMerge "fill_ListView()" id:#JH_BatchCameraRender
			callbacks.addScript #systemPostNew "fill_ListView()" id:#JH_BatchCameraRender
			callbacks.addScript #systemPostReset "fill_ListView()" id:#JH_BatchCameraRender
		)
		
		on rollout_batchManager close do
		(
			callbacks.removeScripts id:#JH_BatchCameraRender
			isDialogOpen = false
		)
		
		on btn_refresh pressed do
		(
			init_ListView()
			fill_ListView()
		)
		
		on btn_addBatch pressed do
		(
			newBatch()
		)
		
		on btn_duplicate pressed do
		(
			sourceIndex = getListViewSelectedIndex()
			newBatch()
			destinationIndex = getLastIniSectionIndex()
			duplicateIniValues sourceIndex destinationIndex
			fill_ListView()
		)
		
		on btn_delete pressed do
		(
			deleteIniSection (getListViewSelectedIndex())
			fill_ListView()
		)
		
		on btn_selectAll pressed do
		(
			if listView_main.selectedItems.count == listView_main.items.count then
			(
				-- all item is selected
				for i = 0 to listView_main.items.count - 1 do
				(
					(listView_main.items.item i).selected = false
				)
			) else (
				for i = 0 to listView_main.items.count - 1 do
				(
					(listView_main.items.item i).selected = true
				)
			)
			updateUIState()
		)
		
		on btn_checkAll pressed do
		(
			if listView_main.checkedItems.count == listView_main.items.count then
			(
				-- all item is selected
				for i = 0 to listView_main.items.count - 1 do
				(
					(listView_main.items.item i).checked = false
				)
			) else (
				for i = 0 to listView_main.items.count - 1 do
				(
					(listView_main.items.item i).checked = true
				)
			)
			updateUIState()
		)
		
		on listView_main ItemSelectionChanged val  do
		(
			fill_uiElements()
			updateUIState()
		)
		
		on listView_main ItemChecked val  do
		(
			writeIniValue val.item.index "Checked" (val.item.checked as string)
			updateUIState()
		)
		
		on btn_render pressed do
		(
			renderHandler (getListViewCheckedIndices())
		)
		
		on btn_batch pressed do
		(
			continueFlag = false
			
			iniValue = readBatchIniValue()
			filesArray = undefined	
			filesArray = arrayStringToArray iniValue
			
			-- check existing files
			if filesArray != undefined and filesArray.count > 0 and doesFileExist filesArray[1] do
			(
				-- ini data is exist
				queryString = "Files wait for batch : \n"
				for f in filesArray where doesFileExist f do queryString += f + "\n"
				queryString += "Continue batch process?"
				continueFlag = queryBox queryString
			)
			
			-- get new files
			if not continueFlag do filesArray = openFileDialog()
			
			if filesArray != undefined and filesArray.count > 0 do
			(
				writeBatchIniValue filesArray
				format "############## Batch Render ##############\n"
				format "Files count : %\n" filesArray.count
				for f in filesArray where doesFileExist f do
				(
					format "############## Start Rendering File ##############\n"
					format "File : %\n" f
					loadMaxFile f
					renderHandler (getListViewCheckedIndices())
				)
			)
		)
		
		on btn_output_openLastRendered pressed do
		(
			thisPath = getFilenamePath output_lastRenderPath
			if doesFileExist thisPath do ShellLaunch ("explorer.exe") ( "/n, " + thisPath)
		)
	)

	rollout rollout_batchSettings "Batch Settings"
	(
		editText edt_batchName "Batch Name"
		dropdownlist ddl_renderPresets "Render Presets"
		
		on edt_batchName entered str do
		(
			writeIniValues (getListViewSelectedIndices()) "Batch Name" str
			setListViewItem (getListViewSelectedItems()) str
		)
		
		on ddl_renderPresets selected val do
		(
			thisPresetName = ddl_renderPresets.selected
			writeIniValues (getListViewSelectedIndices()) "Render Preset" thisPresetName
			setListViewSubItems (getListViewSelectedItems()) "Render Preset" thisPresetName
		)
	)

	rollout rollout_camera "Camera"
	(
		dropDownList ddl_cameras "" items:#() width:250 align:#left across:3
		button btn_camera_getSelected "Get Selected" width:70 align:#right offset:[75,0]
		button btn_camera_select "Select" width:70 align:#right
		
		on ddl_cameras selected val do
		(
			thisCameraName = ddl_cameras.selected
			if isValidNode (getNodeByName thisCameraName) do
			(
				if iskindof (getNodeByName thisCameraName) Camera do
				(
					-- execute while is valid camera object
					writeIniValues (getListViewSelectedIndices()) "Camera" thisCameraName
					setListViewSubItems (getListViewSelectedItems()) "Camera" thisCameraName
				)
			)
		)
		
		on btn_camera_getSelected pressed do
		(
			init_CameraDDL()
			
			if selection.count > 0 do
			(
				if iskindof selection[1] Camera do
				(
					thisCameraName = selection[1].name
					newIndex = findItem ddl_cameras.items thisCameraName
					if  newIndex > 0 do
					(
						writeIniValues (getListViewSelectedIndices()) "Camera" ddl_cameras.items[newIndex]
						setListViewSubItems (getListViewSelectedItems()) "Camera" ddl_cameras.items[newIndex]
						ddl_cameras.selection = newIndex
					)
				)
			)
		)
		
		on btn_camera_select pressed do
		(
			thisCameraName = ddl_cameras.selected
			if thisCameraName != undefined and isValidNode (getNodeByName thisCameraName) then
			(
				select (getNodeByName thisCameraName)
			) else (
				format "Camera is not exist.\n"
			)
		)
	)
	
	rollout rollout_resolution "Resolution"
	(
		dropDownList ddl_resolutionPresets width:250
		label lbl_resolutionWidth "Width" width:80 align:#left across:4
		spinner spn_resolutionWidth "" range:[1,9048,640] type:#integer width:80 align:#left offset:[-80,0]
		label lbl_resolutionHeight "Height" width:80 align:#left
		spinner spn_resolutionHeight "" range:[1,9048,480] type:#integer width:80 align:#left offset:[-80,0]
		
		on rollout_resolution open do
		(
			init_resolutionDDL()
		)
		
		on ddl_resolutionPresets selected val do
		(
			getStandardResolution val
		)
		
		on spn_resolutionWidth changed val do
		(
			writeIniValues (getListViewSelectedIndices()) "Width" (val as string)
			setListViewSubItems (getListViewSelectedItems()) "Width" (val as string)
		)
		
		on spn_resolutionHeight changed val do
		(
			writeIniValues (getListViewSelectedIndices()) "Height" (val as string)
			setListViewSubItems (getListViewSelectedItems()) "Height" (val as string)
		)
	)

	rollout rollout_frameRange "Frame Range"
	(
		editText edt_frames align:#left
		label lbl_description "Example : 1,3,5-12" align:#right
		
		on edt_frames entered str do
		(
			writeIniValues (getListViewSelectedIndices())  "Frames" str
			setListViewSubItems (getListViewSelectedItems()) "Frames" str
		)
	)

	rollout rollout_output "Output"
	(
	--	button btn_setFilename "File..."
		label lbl_output_filepath "File Path" align:#left across:3
		editText edt_output_filepath width:300 offset:[-89,0]
		button btn_output_filepath_open "Open" width:70 align:#right offset:[-2,0] enabled:false
		label lbl_output_filename "Filename" align:#left across:3
		editText edt_output_filename width:300 offset:[-89,0]
		button btn_output_filenameSyntax "Syntax" width:70 align:#right
		label lbl_output_preview "Preview" align:#left across:3
		editText edt_output_preview width:300 offset:[-89,0] readOnly:true
		button btn_output_preview "Syntax" width:70 align:#right visible:false
		--button btn_output_openLastRendered "Open Last Rendered Folder" align:#right
		
		on edt_output_filepath entered str do
		(
			writeIniValues (getListViewSelectedIndices())  "Output Path" str
			setListViewSubItems (getListViewSelectedItems()) "Output Path" str
			previewOutputFilename()
			if doesFileExist (parseFilenameSyntax str) then btn_output_filepath_open.enabled = true else btn_output_filepath_open.enabled = false
		)
		
		on edt_output_filename entered str do
		(
			writeIniValues (getListViewSelectedIndices())  "Output Filename" str
			setListViewSubItems (getListViewSelectedItems()) "Output Filename" str
			previewOutputFilename()
		)
		
		on btn_output_filenameSyntax pressed do
		(
			info_string = "You can use special keywords in filename and filepath :\n"
			info_string += "\n"
			info_string += "%filepath%\tMax file path\n"
			info_string += "%filename%\tMax file filename\n"
			info_string += "%camera%\tCamera name\n"
			info_string += "%batchname%\tBatch name\n"
			info_string += "%date%\tDate(You can format date by ^, ex. %date^yyMMdd%)\n"
			info_string += "\n"
			info_string += "And serialize with :\n"
			info_string += "\n"
			info_string += "%frame%\tFrame count\n"
			info_string += "%count%\tRender count\n"
			info_string += "(You can padding zero by ^, ex. %frame^4%, %count^6)\n"
			info_string += "\n"
			info_string += "Example:\n"
			info_string += "\n"
			info_string += "The string\nD:\Max\%camera%_%date^yyMMdd%\wow_%count^4%.jpg\n"
			info_string += "will yield the path\n"
			info_string += "D:\Max\Camera001_150520%\wow_0025.jpg"
			messagebox info_string title:"File name template info" beep:false
		)
		
		on btn_output_filepath_open pressed do
		(
			thisPath = parseFilenameSyntax edt_output_filepath.text
			if doesFileExist thisPath do ShellLaunch ("explorer.exe") ( "/n, " + thisPath)
		)
	)
	
	/*
	rollout rollout_renderTargets "Render Targets"
	(
		radiobuttons ckb_renderTargets_type_layers labels:#("Layers") default:1 align:#left
		Group ""
		(
			listBox lb_renderTargets_layers_exist "Layers" width:190 height:8 align:#left across:4
			button btn_renderTargets_layers_delete "<" offset:[45,50]
			button btn_renderTargets_layers_send ">" offset:[-45,50]
			listBox lb_renderTargets_layers_render "Render" width:190 height:8 align:#right
		)
	)
	*/
	
	----------------------------------------------------------------------------------------------------
	-- MAXScript Events Handler
	----------------------------------------------------------------------------------------------------
	
	on isChecked do
	(
		--return true if rollout is open
		isDialogOpen
	)
	
	on execute do
	(
		--here can be placed initialization code
		--to set window placement, size, etc.
		
		if isDialogOpen then 
		(
			--if open, close it
			CloseRolloutFloater mainRolloutFloater
			--and lower the flag
			isDialogOpen = false
		) else (
			--if closed, open it
			mainRolloutFloater = newRolloutFloater "JH Batch Camera Render" 500 700
			addRollout rollout_batchManager mainRolloutFloater
			addRollout rollout_batchSettings mainRolloutFloater
			addRollout rollout_camera mainRolloutFloater
			addRollout rollout_resolution mainRolloutFloater
			addRollout rollout_frameRange mainRolloutFloater
			addRollout rollout_output mainRolloutFloater
			updateUIState()
			isDialogOpen = true
		)
	)
	
	on closeDialogs do 
	(
		CloseRolloutFloater mainRolloutFloater
	)
)