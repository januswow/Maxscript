/*
[TITLE]
AnimationListNavigator

[CATEGORY]
animation

[DESCRIPTION]
Ū������ɤ�(animationList.txt)���O���ʵe�ɶ��C���ѧֳt�����ʵe

[USAGE]
�w�]��res�ؿ���D:/work/mf1.9/BlueWings/other_res/characters/enemys/
�۰ʿ�X�������res�ؿ���
�ݦ��W��animationList.txt���ʵe�M���ɦs���max�ɥؿ���
	animationList.txt �ɮפ��e����g�榡
	�Ĥ@�欰NPC�W��
	����_�C�欰�@���ʧ@, ��g�榡�p : Name,�W��,�_�l��,������,�`��,�Ƶ�
	Name�ݥΥ��T��.animation�ɿ�X�W�ٶ�g, �����ݶ�Jhand_�r������
����Script

[AUTHOR]
Janus Huang

[LAST UPDATED]
2012.7.18�s�W�`�������\��
2012.7.17�s�W�۰ʼ���ﶵ
2012.7.5 �s�W��X�\��
2012.7.3 �s�W����έק�animationList.txt�ɫ��s
2012.5.21
*/

try(destroyDialog animationList )catch()
rollout animationList "Animation List Navigator & Exporter" width:370 height:340
(
	-- res�ؿ����|�]�w
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

	--�qanimationList.txtŪ���ʵe�M�欰Array:animationList
	fn readAnimationList =
	(
		try(
			--AnimationList��r�ɸ��|
			f_filename = maxFilePath + "animationList.txt"
			--Ū������
			f = openfile f_filename
			-- Ū����󤺪�����ରArray(animationList)
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
	
	-- �_�l��List
	fn initListView lv =
	(
		/*
		-- ActiveX�~�[�]�w
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
	
	-- �N���e��i����
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
		--��ܭn��X������
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
				-- �w�q��X������|
				-- ���϶��ج�other_portrait�h���[�Whand_�r��
				if lv.listItems[i].ListSubItems[1].text != "other_portrait" then eptAnimPath = eptPath + "hand_" + lv.listItems[i].ListSubItems[1].text + eptFileType else eptAnimPath = eptPath + lv.listItems[i].ListSubItems[1].text + eptFileType
				-- ������n��X�������ɶ��Ϭq
				animationRange = interval (lv.listItems[i].ListSubItems[3].text as time) (lv.listItems[i].ListSubItems[4].text as time)
				sliderTime = (lv.listItems[i].ListSubItems[3].text as time)
				completeRedraw()
				-- ����n��X������
				eptAnimObjAryTmp = for i in eptAnimObjAry collect getNodeByName i
				select eptAnimObjAryTmp
				-- �ˬdBiped��Figure��InPlaceMode
				if isValidNode $bip01 do (
					if $bip01.controller.figureMode do $bip01.controller.figureMode = false
					$bip01.controller.inPlaceMode = false
				)
				-- ��X
				/*
				tmpPath = eptPath
				tmpPath[tmpPath.count] = ""
				testPath = (getDirectories tmpPath).count
				if testPath == 0 then
				(
					testFlag = queryBox ( tmpPath + "\n��X�ؿ����|���s�b, �O�_�إߥؿ�?" ) title:"��X�ؿ����|���s�b"
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