/*
[TITLE]
AnimationListNavigator

[CATEGORY]
animation

[DESCRIPTION]
讀取文件檔中(animationList.txt)註記的動畫時間列表供快速切換動畫

[USAGE]
預設的res目錄為D:/work/mf1.9/BlueWings/other_res/characters/enemys/
自動輸出到對應的res目錄中
需有名為animationList.txt的動畫清單檔存放於max檔目錄中
	animationList.txt 檔案內容的填寫格式
	第一行為NPC名稱
	次行起每行為一項動作, 填寫格式如 : Name,名稱,起始格,結束格,循環,備註
	Name需用正確的.animation檔輸出名稱填寫, 但不需填入hand_字首部分
執行Script

[AUTHOR]
Janus Huang

[LAST UPDATED]
2012.7.18新增循環偵測功能
2012.7.17新增自動播放選項
2012.7.5 新增輸出功能
2012.7.3 新增選取及修改animationList.txt檔按鈕
2012.5.21
*/

try(destroyDialog animationList )catch()
rollout animationList "Animation List Navigator & Exporter" width:370 height:340
(
	-- res目錄路徑設定
	local res = "D:/work/mf1.9/BlueWings/other_res/characters/"
	local eptCate = "enemys/"
	local resPath = res + eptCate
	local eptPath = ""
	
	local f_filename = ""
	local npcName = ""
	local eptAnimObjAry = #()
	local eptAnimObjAryTmp = #()
	
	----------------------------------------
	-- User Interface
	----------------------------------------
	label lbl_animList "Animation List" align:#left
	--ActiveXControl lv "MSComctlLib.ListViewCtrl" height:250
	dotNetControl lv "System.Windows.Forms.ListView" height:250
	label lbl_npcName "Npc name: " align:#left across:3
	label lbl_bones "Nodes to export : " align:#left offset:[40,0] visible:false
	button btn_pickNodes "Pick nodes"  align:#right visible:false
	button btn_refresh "Refresh" across:3 align:#left
	button btn_editFile "Edit AnimList File" align:#left offset:[-50,0]
	button btn_eptAnim "Export Anim" align:#right visible:false
	/*
	group "Selection"
	(
		button btn_selectAll "All" across:3 align:#left
		button btn_selectNone "None" align:#left offset:[-75,0]
		button btn_selectInverse "Inverse" align:#left offset:[-135,0]
	)
	*/
	checkbox chk_autoPlay "Auto Play" align:#left across:2 visible:false
	checkbox chk_loop "Set Loop State" align:#left visible:false
	
	----------------------------------------
	-- Functions
	----------------------------------------

	--從animationList.txt讀取動畫清單為Array:animationList
	fn readAnimationList =
	(
		try(
			--AnimationList文字檔路徑
			f_filename = maxFilePath + "animationList.txt"
			--讀取該檔
			f = openfile f_filename
			-- 讀取文件內的資料轉為Array(animationList)
			animationList = #()			
			npcName = readline f
			lbl_npcName.text = "NPC NAME : " + npcName
			while not eof f do
			(
				cur_line = readline f
				if not matchpattern cur_line pattern:"--*" then
				(
					append animationList (filterString cur_line ",")
				)
			)
		)catch()
	)
	
	-- 起始化List
	fn initListView lv =
	(
		/*
		-- ActiveX外觀設定
		lv.gridLines = true  
		lv.View = #lvwReport
		lv.MultiSelect = true
		lv.fullRowSelect = true 
		lv.sorted = false 
		lv.LabelEdit=  #lvwManual	
		lv.AllowColumnReorder = false
		lv.Checkboxes = true
		lv.HideSelection = false
		*/
		
		--dotNet object initialization
		lv.GridLines = true
		lv.CheckBoxes = true
		lv.Sorting = (dotNetClass "System.Windows.Forms.SortOrder").None
		lv.HeaderStyle = (dotNetClass "System.Windows.Forms.ColumnHeaderStyle").NonClickable
		lv.View = (dotNetClass "System.Windows.Forms.View").Details
		lv.FullRowSelect = true
		lv.HideSelection = false
		lv.MultiSelect = false
		
		
		-- Layout
		layout_def = #( #("-",35) , #("Name",85) , #("Name2",60) , #("Start",40) , #("End",40) , #("L",20),#("Comment",300) )
		
		lv.Columns.Clear()
		for i in layout_def do lv.Columns.add i[1]
		lv.EndUpdate()
		
		/*
		-- ActiveX code
		for i in layout_def do
		(
			column = lv.ColumnHeaders.add() 
			column.text = i[1]
		)
		LV_FIRST = 0x1000
		LV_SETCOLUMNWIDTH = (LV_FIRST + 30) 
		for i = 0 to layout_def.count-1 do windows.sendMessage lv.hwnd LV_SETCOLUMNWIDTH i layout_def[1+i][2]
		*/

	)
	
	-- 將內容填進表中
	fn fillInSpreadSheet lv =
	(
		try(
			--lv.ListItems.Clear()
			lv.Items.Clear()
			itemsArray = #()
			index = 1
			readAnimationList()
			if animationList.count > 0 then
			(
				for item in animationList do 
				(
					--li = lv.ListItems.add()
					li = dotNetObject "System.Windows.Forms.ListViewItem"
					li.text = index as string
					for i in item do
					(
						--sub_li = li.ListSubItems.add()
						--sub_li.text = i as string
						li.SubItems.add (i as string)
					)
					/*
					try(
						if li.ListSubItems[5].text == "y" then li.checked = true
					) catch ()
					*/
					index += 1
					append itemsArray li
				)
			)			
			lv.Items.AddRange itemsArray--when done, we populate the ListView
			lv.AutoResizeColumns (dotNetClass "System.Windows.Forms.ColumnHeaderAutoResizeStyle").HeaderSize
		)catch()
	)
	
	----------------------------------------
	-- Events
	----------------------------------------
	on animationList open do
	(
		initListView lv
		fillInSpreadSheet lv
		btn_eptAnim.enabled = false
	)
	
	on lv ItemSelectionChanged val do
	(
		try(
			myIndex = (lv.selectedIndices.item 0) + 1
			animationRange = interval (animationList[myIndex][3] as time) (animationList[myIndex][4] as time)
			sliderTime = (animationList[myIndex][3] as time)
			completeRedraw()
			if chk_autoPlay.state do (
				if chk_loop.state do timeConfiguration.playbackLoop = lv.selectedItem.checked
				playAnimation immediateReturn:true
			)
		)catch()
	)
	
	on btn_refresh pressed do
	(
		fillInSpreadSheet lv
	)
	
	on btn_editFile pressed do
	(
		shellLaunch "notepad.exe" f_filename
	)	
	
	on btn_selectAll pressed do
	(
		for i = 1 to lv.listItems.count do lv.listItems[i].selected = true
	)
	
	on btn_selectNone pressed do
	(
		for i = 1 to lv.listItems.count do lv.listItems[i].selected = false
	)
	
	on btn_selectInverse pressed do
	(
		for i = 1 to lv.listItems.count do lv.listItems[i].selected = not lv.listItems[i].selected
	)
	
	on btn_pickNodes pressed do
	(
		--選擇要輸出的物件
		eptAnimObjAry = for i in selection collect i.name
		lbl_bones.caption = "Nodes to export : " + eptAnimObjAry.count as string
		if eptAnimObjAry.count != 0 do btn_eptAnim.enabled = true
	)
	
	on btn_eptAnim pressed do
	(
		try (				
			eptPath = resPath + npcName + "/" + npcName + "_biped/animations/"
			oldSelection = for o in selection collect o
			clearselection()
			eptFileType = ".animation"
			
			for i = 1 to lv.listItems.count where lv.listItems[i].selected do (
				-- 定義輸出完整路徑
				-- 假使項目為other_portrait則不加上hand_字首
				if lv.listItems[i].ListSubItems[1].text != "other_portrait" then eptAnimPath = eptPath + "hand_" + lv.listItems[i].ListSubItems[1].text + eptFileType else eptAnimPath = eptPath + lv.listItems[i].ListSubItems[1].text + eptFileType
				-- 切換到要輸出的對應時間區段
				animationRange = interval (lv.listItems[i].ListSubItems[3].text as time) (lv.listItems[i].ListSubItems[4].text as time)
				sliderTime = (lv.listItems[i].ListSubItems[3].text as time)
				completeRedraw()
				-- 選取要輸出的物件
				eptAnimObjAryTmp = for i in eptAnimObjAry collect getNodeByName i
				select eptAnimObjAryTmp
				-- 檢查Biped的Figure及InPlaceMode
				if isValidNode $bip01 do (
					if $bip01.controller.figureMode do $bip01.controller.figureMode = false
					$bip01.controller.inPlaceMode = false
				)
				-- 輸出
				/*
				tmpPath = eptPath
				tmpPath[tmpPath.count] = ""
				testPath = (getDirectories tmpPath).count
				if testPath == 0 then
				(
					testFlag = queryBox ( tmpPath + "\n輸出目錄路徑不存在, 是否建立目錄?" ) title:"輸出目錄路徑不存在"
					if testFlag then 
				)else(	
				)
				*/
				print eptAnimPath
				exportFile eptAnimPath #noPrompt selectedOnly:true
				select oldSelection
			)
		) catch ( messageBox "Error!" )
	)
	
)
createDialog animationList