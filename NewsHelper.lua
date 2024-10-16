script_name('News Helper by fa1ser')
script_version('2.0')
script_description('������ ��� ���')
script_author('fa1ser')

require "lib.moonloader"
local memory = require 'memory'
local dlstatus = require('moonloader').download_status
local inicfg = require 'inicfg'
local bit = require 'bit'
local ev =  require 'samp.events'
local vk = require 'vkeys'
local imgui = require 'mimgui'
local ffi = require 'ffi'
local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local sampModule = getModuleHandle('samp.dll')

local mainPages, fastPages, eventPages = new.int(1), new.int(1), new.int(1) 
local buttonPages = {true, false, false, false} 
local buttonPagesEf = {true, false, false, false, false} 
local ToU32 = imgui.ColorConvertFloat4ToU32
local sizeX, sizeY = getScreenResolution()

local rMain, rHelp, rSW, rFastM = new.bool(), new.bool(), new.bool(), new.bool()  

--�������������� 

update_state = false

local script_vers = 2
local script_vers_text = "2.00"

local update_url = "https://raw.githubusercontent.com/Faiserx/NewsHelper/refs/heads/main/update.ini" -- ssilka na fayl
local update_path = getWorkingDirectory() .. "/update.ini" 

local script_url = "https://github.com/Faiserx/NewsHelper/raw/refs/heads/main/NewsHelper.lua" -- ssilka na fayl
local script_path = thisScript().path

local inputDec = new.char[8192]() 
local inputAd, inputAdText, inputReplace, iptBind  = new.char[256](), new.char[256](), new.char[128](), new.char[128]() 
local iptEv, inputEvSet, iptNotepad = new.char[8192](), new.char[256](), new.char[4096]() 

local ComboLanguage = new.int()
local languageList = {'����������', '�����������', '���������', '��������', '�����������'}
local languageItems = imgui.new['const char*'][#languageList](languageList)

local id_name = '##Arizona News Helper '
local tag = '{008080}[News Helper]: {C0C0C0}'
local tmp = {['downKey'] = {}}

local ul_rus = {[string.char(168)] = string.char(184)}
local un_rus = {[string.char(184)] = string.char(168)}
for i = 192, 223 do local A, a = string.char(i), string.char(i + 32); ul_rus[A] = a; un_rus[a] = A end

local tAd = {false, '', false} 
local winSet = {0, {}} 

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	loadVar() 

	while not isSampAvailable() do wait(100) end
	
	downloadUrlToFile(update_url, update_path, function(id, status)
    if status == dlstatus.STATUS_ENDDOWNLOADDATA then
        updateIni = inicfg.load(nil, update_path)
        if tonumber(updateIni.info.vers) > script_vers then
            sampAddChatMessage("Update Available: " .. updateIni.info.vers_text, -1)
            update_state = true 
            end
            os.remove(update_path)
        end
    end)
	
	if not doesDirectoryExist('moonloader\\config\\News Helper') then createDirectory('moonloader\\config\\News Helper') end

	--------------------------------------------------
	adcfg = loadFile('advertisement.cfg', {})
	helbincfg = loadFile('helpBind.cfg', newsHelpBind)
	autbincfg = loadFile('autoBind.cfg', newsAutoBind)
	keybincfg = loadFile('keyBind.cfg', newsKeyBind)
	setup = updateFile('settings.cfg', settingsSCR)
	esterscfg = updateFile('estersBind.cfg', newsHelpEsters)

	cheBoxSize = new.bool(setup.cheBoxSize) 
	msgDelay = new.int(esterscfg.settings.delay) 
	newsDelay = new.int(setup.newsDelay) 
	iptTmp = {['notepad'] = {}} 
	--------------------------------------------------

	sampRegisterChatCommand('nh', openMenu)
	sampRegisterChatCommand('newshelper', openMenu)
	RegisterCallback('menu', setup.keys.menu, openMenu)
	RegisterCallback('helpMenu', setup.keys.helpMenu, function () rHelp[0] = not rHelp[0] end)
	RegisterCallback('catchAd', setup.keys.catchAd)
	RegisterCallback('copyAd', setup.keys.copyAd)
	RegisterCallback('fastMenu', setup.keys.fastMenu, function () 
		if rFastM[0] then rFastM[0] = false end
		if isKeyDown(vk.VK_RBUTTON) then
			local st, getPlayerPed = getCharPlayerIsTargeting()
			if st and sampGetPlayerIdByCharHandle(getPlayerPed) then
				local id = select(2,sampGetPlayerIdByCharHandle(getPlayerPed))
				tmp.targetPlayer = {['Ped'] = getPlayerPed, ['id'] = id, ['nick'] = sampGetPlayerNickname(id), ['score'] = sampGetPlayerScore(id)}
				rFastM[0] = true
			end
		end
	end)

	-----

	sampAddChatMessage(tag .. u8:decode('/nh, /newshelp'), -1)

	while true do
		wait(10)

        if update_state then
            downloadUrlToFile(update_url, update_path, function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    sampAddChatMessage("Script Succesfully Updated!", -1)
                    thisScript():reload()
                end
            end)
            break
		end

		if wasKeyPressed(setup.keys.catchAd[2] or setup.keys.catchAd[1]) then
			for i=1, (#tmp.downKey or 0) do
				tmp.downKey[i] = false
			end
			tmp.downKey[#tmp.downKey+1] = true
			lua_thread.create(function (num)
				while isKeyDown(tmp.downKey[num] and (setup.keys.catchAd[2] or setup.keys.catchAd[1])) do
					if not ((sampIsDialogActive() and u8:encode(sampGetDialogCaption()) == '{BFBBBA}��������') or not sampIsDialogActive()) then break end
					sampSendChat('/newsredak')
					wait(10 + newsDelay[0] * 10 + sampGetPlayerPing(select(2,sampGetPlayerIdByCharHandle(PLAYER_PED))))
				end
			end, #tmp.downKey)
		end
		
		if sampIsDialogActive() and u8:encode(sampGetDialogCaption()) == '{BFBBBA}��������������' then
			if tAd[1] == nil then 
				sampSetCurrentDialogEditboxTextFix(u8:decode(tAd[2]))
				tAd[1] = false
			end
			if tAd[3] == true then
				sampSetCurrentDialogEditboxTextFix('')
				tAd[3] = false
			end -----

			if wasKeyPressed(setup.keys.copyAd[2] or setup.keys.copyAd[1]) then
				if u8:encode(sampGetDialogText()):find('���������:%s+{33AA33}.+\n\n') then
					local textdown = u8:encode(sampGetDialogText()):match('���������:%s+{33AA33}(.+)\n\n')
					sampSetCurrentDialogEditboxTextFix(u8:decode(textdown))
				end
			end

			local text = u8:encode(sampGetCurrentDialogEditboxText())
			for i=2, #autbincfg do
				local au = autbincfg[1][1]:regular() ..autbincfg[i][1]
				if text:find(au) then
					local gCur = getDialogCursorPos()
					sampSetCurrentDialogEditboxTextFix(u8:decode(tostring(text:gsub(au, autbincfg[i][2]))))
					setDialogCursorPos(gCur - utf8len(au:gsub('%%', '')) + utf8len(autbincfg[i][2]))
				end
			end

			for _, btn in ipairs(keybincfg) do
				if (#btn[1] == 1 and wasKeyPressed(btn[1][1])) or (#btn[1] == 2 and isKeyDown(btn[1][1]) and wasKeyPressed(btn[1][2])) then
                    local gCur = getDialogCursorPos()
					sampSetCurrentDialogEditboxTextFix(u8:decode(utf8sub(text, 1, gCur)..btn[2]..utf8sub(text, gCur+1)))
					setDialogCursorPos(gCur + utf8len(btn[2]))
				end
			end
		end
	end
end

function ev.onShowDialog(id, style, title, button1, button2, text)
	tmp.lastDialog = {['id'] = id, ['style'] = style, ['title'] = u8:encode(title), ['button1'] = button1, ['button2'] = button2, ['text'] = u8:encode(text)}

	if tmp.fmActi and u8:encode(title) == '{BFBBBA}{73B461}�������� �����������' then 
		if style == 2 then tmp.fmActi = nil; lua_thread.create(function () wait(10) sampSendDialogResponse(id, 1, 5, nil) end) end
		return false
	end

	if u8:encode(title) == '{BFBBBA}��������������' then
		local ad = u8:encode(text):match('���������:%c{%x+}(.+)%s+{%x+}�������������� ������� � ������ ������'):gsub('%s*\n', ''):gsub('\\', '/') 
		text = text..'										.'
		for i=1, #adcfg do
			if adcfg[i].ad == ad then
				tAd = {nil, adcfg[i].text, false}
				return {id, style, title, button1, button2, text}
			end
		end
		tAd = {true, ad, true}
		return {id, style, title, button1, button2, text}
	end
end

function ev.onSendDialogResponse(id, button, list, input)
	if button == 1 and list == 65535 and tAd[1] and input ~= '' then
		adcfg[#adcfg + 1] = {['ad'] = tAd[2], ['text'] = u8:encode(input):gsub('%s+', ' '):gsub('\\', '/')}
		saveFile('advertisement.cfg', adcfg)
	end
	tAd = {false, '', false}
end

function ev.onServerMessage(color, text)
	if tmp.fmActi and color == -1104335361 and u8:encode(text) == '[������] {ffffff}� ��� ��� � ������ ������ �������� �����������, ���������� �����.' then
		tmp.fmActi = nil
		sampAddChatMessage(u8:decode(tag..'����� �� ��������� ���� ���������!'), -1)
		return false
	end
end

imgui.OnFrame(function() return rMain[0] end,
	function(player)
		imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSizeConstraints(imgui.ImVec2(700, 450), imgui.ImVec2(1240, 840))
		imgui.Begin('News by fa1ser ##window_1', rMain, imgui.WindowFlags.NoCollapse + (not cheBoxSize[0] and imgui.WindowFlags.NoResize or 0) + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoScrollWithMouse) -- + imgui.WindowFlags.NoMove + imgui.WindowFlags.AlwaysAutoResize
		
			imgui.SetCursorPos(imgui.ImVec2(3, 19))
			imgui.BeginChild(id_name .. 'child_window_1', imgui.ImVec2(imgui.GetWindowWidth() - 6, 30), false)
				imgui.Columns(3, id_name .. 'columns_1', false)
				imgui.TextStart('News Helper by fa1ser')
				imgui.NextColumn()
				imgui.TextCenter('v'..thisScript().version..' alpha')
				imgui.NextColumn()
				imgui.TextEnd('promo: #andreich')
				if imgui.IsItemClicked(1) then
					lua_thread.create(function ()
						wait(100)
						thisScript():reload()
					end)
				end
				imgui.Tooltip('Scottdale')
			imgui.EndChild()

			imgui.SetCursorPos(imgui.ImVec2(3, 48))
			imgui.BeginChild(id_name .. 'child_window_2', imgui.ImVec2(149, imgui.GetWindowHeight() - 47), true)
				imgui.SetCursorPosX(22)
				imgui.CustomMenu({
					'�������',
					'��������',
					'�������������',
					'�����',
					'���������'
				}, mainPages, imgui.ImVec2(107, 32), 0.08, true, 9, {
					'',
					'��� ����� ��� ����-������, ��������\n������ � ���������� ���� �\n��������������� ����������!!'
				})
			imgui.EndChild()

			imgui.SameLine()

			imgui.SetCursorPosX(151)
			imgui.BeginChild(id_name .. 'child_window_3', imgui.ImVec2(imgui.GetWindowWidth() - 154, imgui.GetWindowHeight() - 47), true, imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)
			
				if mainPages[0] == 1 then imgui.WindowMain()
				elseif mainPages[0] == 2 then imgui.LocalSettings()
				elseif mainPages[0] == 3 then imgui.Text('�����..')
				elseif mainPages[0] == 4 then imgui.LocalEsters()
				elseif mainPages[0] == 5 then imgui.ScrSettings() end
				
			imgui.EndChild()

		imgui.End()
		imgui.SetMouseCursor(-1)
	end
)

imgui.OnFrame(function() return rHelp[0] end,
	function(player)
		imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 1.05, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(1, 0.5))
		imgui.SetNextWindowSizeConstraints(imgui.ImVec2(395, 500), imgui.ImVec2(395, 800))
		imgui.Begin('Help Ad ##window_2', rHelp, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize)
			for i=1, #helbincfg do
				if imgui.CollapsingHeader(helbincfg[i][1]..'##i'..i) then
					local tSize = imgui.GetWindowWidth()
					local wSize = imgui.GetWindowWidth() - 10
					for f=2, #helbincfg[i] do
						local TextSize = imgui.CalcTextSize(helbincfg[i][f][1]).x+20
						if wSize > tSize+TextSize+10 then
							tSize = tSize+TextSize+10
							imgui.SameLine()
						else tSize = TextSize+10 end
						if imgui.Button(helbincfg[i][f][1]..'##if'..i..f, imgui.ImVec2(TextSize, 20)) then
							if helbincfg[i][f][2]:find('*') then
								sampSetCurrentDialogEditboxTextFix(u8:decode(tostring(helbincfg[i][f][2]:gsub('*', ''))))
								setDialogCursorPos(utf8len(helbincfg[i][f][2]:match('(.-)*')))
							else
								sampSetCurrentDialogEditboxTextFix(u8:decode(helbincfg[i][f][2]))
								if helbincfg[i][f][2]:find('""') then setDialogCursorPos(utf8len(helbincfg[i][f][2]:match('(.-)""')) + 1) end
							end 
						end
						imgui.Tooltip(helbincfg[i][f][2])
					end
				end
			end
		imgui.End()
		imgui.SetMouseCursor(-1)
	end
)

imgui.OnFrame(function() return rFastM[0] end,
	function(player)
		imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 1.1, sizeY / 1.2), imgui.Cond.FirstUseEver, imgui.ImVec2(1, 1))
		imgui.SetNextWindowSize(imgui.ImVec2(500, 300), imgui.Cond.FirstUseEver + imgui.WindowFlags.NoResize)
		imgui.Begin('���� �������� ������� ##window_4', rFastM, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollWithMouse + imgui.WindowFlags.NoScrollbar --[[+ imgui.WindowFlags.NoTitleBar]]) -- + imgui.WindowFlags.AlwaysAutoResize imgui.TabBarFlags.NoCloseWithMiddleMouseButton
			imgui.SetCursorPosY(19)
			imgui.BeginChild(id_name .. 'child_window_6', imgui.ImVec2((imgui.GetWindowWidth() - wPaddX*2) / 1.7, imgui.GetWindowHeight() - 2 - wPaddY*2), false)
				imgui.SetCursorPosY(10)
				if fastPages[0] == 1 then imgui.FmInterviews()
				elseif fastPages[0] == 2 then 
				elseif fastPages[0] == 3 then
				elseif fastPages[0] == 4 then end
				imgui.NewLine()
			imgui.EndChild()
			imgui.SameLine(0, 0)
			
			imgui.BeginChild(id_name .. 'child_window_7', imgui.ImVec2(imgui.GetWindowWidth() - ((imgui.GetWindowWidth() - wPaddX*2) / 1.7) - 2 - wPaddX, imgui.GetWindowHeight() - 2 - wPaddY*2), true)
				imgui.TextCenter(tmp.rolePlay and '{CC0000}��� �������� ����' or ' ')
				imgui.TextCenter('���: '..tmp.targetPlayer.nick)
				imgui.TextCenter('��� � �����: '..tmp.targetPlayer.score)
				imgui.NewLine()
				
				imgui.Separator()

				imgui.NewLine()
				imgui.SetCursorPosX(46)
				imgui.CustomMenu({'�������������', '�������� ���',  '�������� ���', '��������� ��������'}, fastPages, imgui.ImVec2(120, 35), 0.08, true, 15)
			imgui.EndChild()
		imgui.End()
		imgui.SetMouseCursor(-1)
	end
)

imgui.OnInitialize(function()
	imgui.GetIO().MouseDrawCursor = true
	imgui.GetStyle().MouseCursorScale = 1
	local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 14.0, nil, glyph_ranges)
    s2 = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 12.0, _, glyph_ranges)
    s4 = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 14.0, _, glyph_ranges)
	Style()

	wPaddX = imgui.GetStyle().WindowPadding.x
	wPaddY = imgui.GetStyle().WindowPadding.y
	SizScrol = imgui.GetStyle().ScrollbarSize
end)

function imgui.CustomMenu(labels, selected, size, speed, centering, flags, tooltip) 
    local bool = false
    local radius = size.y * 0.50
	flags = flags or 0
	tooltip = tooltip or nil
    local ImDrawlist = imgui.GetWindowDrawList()
    if LastActiveTime == nil then LastActiveTime = {} end
    if LastActive == nil then LastActive = {} end
    local function ImSaturate(f)
        return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
    end
    for i, v in ipairs(labels) do
        local c = imgui.GetCursorPos()
        local p = imgui.GetCursorScreenPos()
        if imgui.InvisibleButton(v..id_name..'invisible_CM_'..i, size) then
            selected[0] = i
            LastActiveTime[v] = os.clock()
            LastActive[v] = true
            bool = true
        end
		if tooltip and tooltip[i] and tooltip[i] ~= '' then 
			imgui.Tooltip(tooltip[i])
		end
        imgui.SetCursorPos(c)
        local t = selected[0] == i and 1.0 or 0.0
        if LastActive[v] then
            local time = os.clock() - LastActiveTime[v]
            if time <= 0.3 then
                local t_anim = ImSaturate(time / speed)
                t = selected[0] == i and t_anim or 1.0 - t_anim
            else
                LastActive[v] = false
            end
        end
        local col_bg = imgui.GetColorU32Vec4(selected[0] == i and imgui.GetStyle().Colors[imgui.Col.ButtonActive] or imgui.ImVec4(0,0,0,0))
        local col_hovered = imgui.GetStyle().Colors[imgui.Col.ButtonHovered]
        local col_hovered = imgui.GetColorU32Vec4(imgui.ImVec4(col_hovered.x, col_hovered.y, col_hovered.z, (imgui.IsItemHovered() and 0.2 or 0)))
		ImDrawlist:AddRectFilled(imgui.ImVec2(p.x-size.x/6, p.y), imgui.ImVec2(p.x + (radius * 0.65) + t * size.x, p.y + size.y), col_bg, 7.0, flags)
        ImDrawlist:AddRectFilled(imgui.ImVec2(p.x-size.x/6, p.y), imgui.ImVec2(p.x + (radius * 0.65) + size.x, p.y + size.y), col_hovered, 7.0, flags)
        imgui.SetCursorPos(imgui.ImVec2(c.x+(centering and (size.x-imgui.CalcTextSize(''..v:hexsub()).x)/2-3 or 15), c.y+(size.y-imgui.CalcTextSize(''..v:hexsub()).y)/2))
        imgui.RenderText(v)
        imgui.SetCursorPos(imgui.ImVec2(c.x, c.y+size.y+5))
    end
    return bool
end
function imgui.HeaderButton(bool, str_id)
    local AI_HEADERBUT = {}
	local DL = imgui.GetWindowDrawList()
	local result = false
	local label = string.gsub(str_id, "##.*$", "")
	local duration = { 0.5, 0.3 }
	local cols = {
        idle = imgui.GetStyle().Colors[imgui.Col.TextDisabled],
        hovr = imgui.GetStyle().Colors[imgui.Col.Text],
        slct = imgui.GetStyle().Colors[imgui.Col.ButtonActive]
    }

 	if not AI_HEADERBUT[str_id] then
        AI_HEADERBUT[str_id] = {
            color = bool and cols.slct or cols.idle,
            clock = os.clock() + duration[1],
            h = {
                state = bool,
                alpha = bool and 1.00 or 0.00,
                clock = os.clock() + duration[2],
            }
        }
    end
    local pool = AI_HEADERBUT[str_id]

	imgui.BeginGroup()
		local pos = imgui.GetCursorPos()
		local p = imgui.GetCursorScreenPos()
		
		imgui.TextColored(pool.color, label)
		local s = imgui.GetItemRectSize()
		local hovered = imgui.isPlaceHovered(p, imgui.ImVec2(p.x + s.x, p.y + s.y))
		local clicked = imgui.IsItemClicked()
		
		if pool.h.state ~= hovered and not bool then
			pool.h.state = hovered
			pool.h.clock = os.clock()
		end
		
		if clicked then
	    	pool.clock = os.clock()
	    	result = true
	    end

    	if os.clock() - pool.clock <= duration[1] then
			pool.color = imgui.bringVec4To(
				imgui.ImVec4(pool.color),
				bool and cols.slct or (hovered and cols.hovr or cols.idle),
				pool.clock,
				duration[1]
			)
		else
			pool.color = bool and cols.slct or (hovered and cols.hovr or cols.idle)
		end

		if pool.h.clock ~= nil then
			if os.clock() - pool.h.clock <= duration[2] then
				pool.h.alpha = imgui.bringFloatTo(
					pool.h.alpha,
					pool.h.state and 1.00 or 0.00,
					pool.h.clock,
					duration[2]
				)
			else
				pool.h.alpha = pool.h.state and 1.00 or 0.00
				if not pool.h.state then
					pool.h.clock = nil
				end
			end

			local max = s.x / 2
			local Y = p.y + s.y + 3
			local mid = p.x + max

			DL:AddLine(imgui.ImVec2(mid, Y), imgui.ImVec2(mid + (max * pool.h.alpha), Y), ToU32(imgui.set_alpha(pool.color, pool.h.alpha)), 3)
			DL:AddLine(imgui.ImVec2(mid, Y), imgui.ImVec2(mid - (max * pool.h.alpha), Y), ToU32(imgui.set_alpha(pool.color, pool.h.alpha)), 3)
		end

	imgui.EndGroup()
	return result
end
function imgui.SameTable(id, tag, func)
	if tmp.selId == id then tmp.selIdAc = true else tmp.selIdAc = false end
	if imgui.Selectable(id_name..'selec_table_'..tag..id, tmp.selIdAc, imgui.SelectableFlags.AllowDoubleClick) then
		tmp.selId = nil
		if imgui.IsMouseDoubleClicked(0) then
			setVirtualKeyDown(0x01, false)
		end
	end
	imgui.SameLine(0)

	if imgui.BeginPopupContextItem(id_name..'context_item_'..tag..id, 1) or imgui.BeginPopupContextItem(id_name..'context_item_'..tag..id, 0) then
		tmp.selId = id
		if tmp.close then imgui.CloseCurrentPopup() tmp.close = nil end
		if imgui.Button('�������������', imgui.ImVec2(100, 0)) then
			func()
			imgui.OpenPopup(id_name..'EditChatLine_1')
		end
		if imgui.Button('�������', imgui.ImVec2(100, 0)) then
			table.remove(adcfg, id)
			saveFile('advertisement.cfg', adcfg)
			tmp.brea = true
			imgui.CloseCurrentPopup()
		end
		if imgui.Button('�������', imgui.ImVec2(100, 0)) then
			imgui.CloseCurrentPopup()
		end
		if imgui.BeginPopupModal(id_name..'EditChatLine_1', nil, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoTitleBar) then
			imgui.TextCenter('�������������� ������������ ���������� #'..id)
			imgui.Separator()

			imgui.NewLine()
			imgui.TextCenter('{STANDART}{ffa64d99}���������� ������� ������ � �������� �� ��������')
			imgui.PushItemWidth(555)
			imgui.InputText(id_name .. 'input_1', inputAd, sizeof(inputAd) - 1)

			imgui.NewLine()
			imgui.TextCenter('{STANDART}{66ffb399}����������� ���������� ����� ������ ��������������')
			imgui.PushItemWidth(555)
			imgui.InputText(id_name .. 'input_2', inputAdText, sizeof(inputAdText) - 1)

			imgui.NewLine()
			imgui.SetCursorPosX(82.5)
			if imgui.Button('���������', imgui.ImVec2(175, 0)) then
				adcfg[id].ad = str(inputAd)
				adcfg[id].text = str(inputAdText)
				saveFile('advertisement.cfg', adcfg)
				imgui.StrCopy(inputAd, '')
				imgui.StrCopy(inputAdText, '')
				imgui.CloseCurrentPopup()
				tmp.close = true
			end
			imgui.SameLine(nil, 50)
			if imgui.Button('�������', imgui.ImVec2(175, 0)) then imgui.CloseCurrentPopup() tmp.close = true end
			imgui.EndPopup()
		end
		imgui.EndPopup()
	end
	if tmp.selId and not imgui.IsPopupOpen(id_name..'context_item_'..tag..(tmp.selId and tmp.selId or 0)) then
		tmp.selId = nil
	end
end
function imgui.RenderText(text)
	local style = imgui.GetStyle()
    local colors = style.Colors
    local col = imgui.Col
	local width = imgui.GetWindowWidth()

	local score = {}
	for tab in string.gmatch(text, '[^\t]+') do score[#score + 1] = tab end

	for i=1, #score do
		if i ~= 1 then 
			if #score == 2 then
				imgui.SameLine(0)
				imgui.SetCursorPosX((width / #score * (i - 1)) + (width / (#score * 2)) + 10)
			else 
				imgui.SameLine(0)
				local text_width = imgui.CalcTextSize(tostring(string.gsub(score[i], '{%x%x%x%x%x%x}', '')))
				imgui.SetCursorPosX((width / #score * (i - 1)) + (width / (#score * 2)) - (text_width.x / 2) - 10)
			end
		end

		local text = score[i]:gsub('{(%x%x%x%x%x%x)}', '{%1FF}')
		local color = colors[col.Text]
		local start = 1
		local a, b = text:find('{........}', start)	

		while a do
			local t = text:sub(start, a - 1)
			if #t > 0 then
				imgui.TextColored(color, t)
				imgui.SameLine(nil, 0)
			end

			local clr = text:sub(a + 1, b - 1)
			if clr:upper() == 'STANDART' then color = colors[col.Text]
			else
				clr = tonumber(clr, 16)
				if clr then
					local r = bit.band(bit.rshift(clr, 24), 0xFF)
					local g = bit.band(bit.rshift(clr, 16), 0xFF)
					local b = bit.band(bit.rshift(clr, 8), 0xFF)
					local a = bit.band(clr, 0xFF)
					color = imgui.ImVec4(r / 255, g / 255, b / 255, a / 255)
				end
			end

			start = b + 1
			a, b = text:find('{........}', start)
		end
		imgui.NewLine()
		if #text >= start then
			imgui.SameLine(nil, 0)
			imgui.TextColored(color, text:sub(start))
		end

	end
end
function imgui.RenderButtonEf(array, tagConcept, func)
	local tagConcept = tagConcept or {}
	local tagEvents = {{'tag', esterscfg.events[array.name].tag, '', '', '��� �������� �� ������ ��������\n������. (����� ������ ��������)'}}
	tagConcept[#tagConcept+1] = tagEvents[1]
	local cycleEsters = function (arr, t)
		local t = t or false
		for i, but in ipairs(arr) do
			imgui.SetCursorPosX((t and imgui.GetWindowWidth() / 1.334 - 60 + 4 or imgui.GetWindowWidth() / 4 - 69))
			if imgui.Button(but[1]..id_name..'button_EF_'.. (t and '' or 'rp_') ..i, (t and imgui.ImVec2(120, 37) or imgui.ImVec2(138, 27))) then
				if tmp.sNewsEv then sampAddChatMessage(u8:decode(tag .. (t and 'RP �������� ��� ������������, ��������� ���� ����������.' or '�� ��� � �����! ���������, ���� ���������� ���������� �������!')), -1)
				else
					local loFuBtn = {}
					for _, nameBtn in ipairs(func or {}) do
						if but[1] == nameBtn[1] then
							loFuBtn.check = nameBtn[2]
							loFuBtn.func = nameBtn[3]
						end
					end
					for _, concept in ipairs(pushArrS(tagConcept)) do
						if (not concept[2] or concept[2] == '') and findTag(but, concept[1]) and not loFuBtn.check then
							tmp.sNewsEvErr = true
							sampAddChatMessage(u8:decode(tag..concept[4]), -1)
						end
					end
					if not tmp.sNewsEvErr then
						lua_thread.create(function ()
							tmp.sNewsEv = true
							if loFuBtn.func then loFuBtn.func(but, tagConcept)
							else
								for k=2, #but do
									sampSendChat(u8:decode((t and but[k] or regexTag(but[k], tagConcept))))
									if k == #but then break end
									wait(1000 * esterscfg.settings.delay)
									if not tmp.sNewsEv then break end
								end
							end
							tmp.sNewsEv = nil
						end)
					end
					tmp.sNewsEvErr = nil
				end
			end

			if imgui.IsItemClicked(1) then
				setVirtualKeyDown(0x01, false)
				imgui.OpenPopup(id_name..'popup_modal_FF_'..but[1])
			end
			imgui.EditingTableEf(but, tagConcept, arr.name, i)

			imgui.Tooltip(select(2, pcall(function () 
				local toolText = '��� - �������������\n'
				for k=2, #but > 8 and 8 or #but do
					local text = regexTag(but[k], tagConcept)
					local calcText = text:sub(1, 62)
					toolText = toolText .. ' \n' .. (string.len(calcText) == #text and text or calcText..'..')
				end
				return toolText
			end)))
		end
	end

	imgui.SetCursorPosY(imgui.GetCursorPos().y + 10)
	imgui.Columns(2, id_name..'columns_2', false)
		cycleEsters(array)
	imgui.NextColumn()
		imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.334 - 60 + 4)
		if imgui.Button(esterscfg.events.write[1]..id_name..'button_EFd_1', imgui.ImVec2(120, 27)) then
			sampSetChatInputEnabled(true)
			sampSetChatInputText(u8:decode(regexTag(esterscfg.events.write[2], tagEvents)))
		end
		if imgui.IsItemClicked(1) then
			setVirtualKeyDown(0x01, false)
			imgui.OpenPopup(id_name..'popup_modal_FF_�������� � /news')
		end
		imgui.Tooltip('��� - �������������\n\n' .. regexTag(esterscfg.events.write[2], tagEvents))
		imgui.EditingTableEf(esterscfg.events.write, tagEvents, array.name)

		imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.81, 0.2, 0.2, 0.5))
		imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.82, 0.1, 0.1, 0.5))
		imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.82, 0.15, 0.15, 0.5))
			imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.334 - 60 + 4)
			if imgui.Button('����������!'..id_name..'button_EFd_2', imgui.ImVec2(120, 27)) then
				if tmp.sNewsEv then
					tmp.sNewsEv = nil
					sampAddChatMessage(u8:decode(tag..'����\\�������� ��������� ��������.'), -1)
				else
					sampAddChatMessage(u8:decode(tag..'� ��� ��� �������� ������ ��� RP ��������, ��� ���������.'), -1)
				end
			end
			imgui.Tooltip('���������� ������ ������� �\n      �������� ���������!')
		imgui.PopStyleColor(3)

		imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() / 1.334 - 60 + 4, imgui.GetCursorPos().y + 31))
		if imgui.Button('/time'..id_name..'button_EFd_3', imgui.ImVec2(120, 27)) then
			sampSendChat('/time')
		end
		imgui.Tooltip('������� /time')

		cycleEsters(esterscfg.events.actions, true)
	imgui.Columns(1, id_name..'columns_3', false)
end
function imgui.EditingTableEf(arrBtn, arrTag, arrName, i)
	local i = i or 0
	if imgui.BeginPopupModal(id_name..'popup_modal_FF_'..arrBtn[1], nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar) then --imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize 
		imgui.TextCenter('{66ffb399}�������������� ������ ��� �����, ������ {ffa64d99}"'..arrBtn[1]:gsub('\n', ' '):gsub('[%s]+', ' '):gsub('^%s', '')..'"')
		imgui.Separator()
		if esterscfg.events[arrName].tag or i == 0 then
			imgui.BeginChild(id_name..'child_window_t_1', imgui.ImVec2((imgui.GetWindowWidth() * 0.75), 80), false)
				imgui.Text('  ������ ���� ����� ������������� ��������� �� ������������ �� ���� �����!')
				if i ~= 0 then
					imgui.SameLine()
					imgui.TextEnd('{a8a8a899}*������')
					imgui.Tooltip('������ �� ���� �� �����!')
				end
				
				imgui.SetCursorPosY(imgui.GetCursorPosY() + 7)
				local butTags = pushArrS(arrTag)
				local divider = (math.fmod(#butTags, 2) == 0 and math.floor(#butTags / 2) or math.floor(#butTags / 2) + 1)
				imgui.Columns(divider, id_name..'columns_TA_'..i, true)
				for k=1, #butTags do
					imgui.SetColumnWidth(-1, imgui.GetWindowWidth() / divider)
					local textTag = '{'..butTags[k][1]..'}'
					if imgui.Selectable(id_name..'selectable_'..k, nil) then
						setClipboardText(textTag)
					end
					imgui.Tooltip((butTags[k][5] or '') .. '\n�����: "'..regexTag(textTag, arrTag)..'"\n\n����� ����� ����������� ���!')
					imgui.SameLine(-1)
					imgui.SetCursorPosX(imgui.GetCursorPos().x - 6 + ((imgui.GetWindowWidth() / divider) / 2 - imgui.CalcTextSize(textTag).x / 2))
					imgui.Text(textTag)
					imgui.NextColumn()
					if k ~= #butTags and math.fmod(k, divider) == 0 then
						imgui.Separator()
					end
				end
			imgui.EndChild()
			
			imgui.SameLine()
			imgui.BeginChild(id_name..'child_window_t_2', imgui.ImVec2((imgui.GetWindowWidth() / 4 - 23), 80), false)
				imgui.SetCursorPos(imgui.ImVec2((i ~= 0 and 12 or 3), 5))
				imgui.Text('{tag} � ������ �����:')

				local sizeText = imgui.CalcTextSize(esterscfg.events[arrName].tag).x + 9
				local iptHeight = (sizeText > 130 and 130 or (sizeText < 65 and 65 or sizeText))
				imgui.SetCursorPosX((imgui.GetWindowWidth() / 2) - (iptHeight / 2))
				imgui.PushItemWidth(iptHeight)
				local iptTags = new.char[256]()
				imgui.StrCopy(iptTags, esterscfg.events[arrName].tag)
				imgui.InputText(id_name..'input_11', iptTags, sizeof(iptTags) - 1)
				if not imgui.IsItemActive() and esterscfg.events[arrName].tag ~= str(iptTags) then
					esterscfg.events[arrName].tag = str(iptTags)
					saveFile('estersBind.cfg', esterscfg)
				end

				imgui.Tooltip((sizeText > iptHeight and str(iptTags)..'\n\n' or '') ..'    �������� �� ������ ���!\n��������� ����������� �����')

				imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - 70, imgui.GetWindowHeight() - 20))
				if imgui.Button((tmp.varEvIptMulti and '�������' or '���������')..id_name..'btn_'..i, imgui.ImVec2(70, 20)) then
					tmp.varEvIptMulti = not tmp.varEvIptMulti
				end
				imgui.Tooltip('������� �����������������\n������� ������, � ������� �����.\n�������� ����� � ����� ���� ������')
			imgui.EndChild()
		else
			imgui.SetCursorPosY(imgui.GetCursorPos().y + 2)
			imgui.TextCenter('��� ������� ������, ��� ��� {ffa64d99}����{STANDART} �������� {ffa64d99}�� �����{STANDART}!')
			imgui.SetCursorPosY(imgui.GetCursorPos().y + 4)
		end

		imgui.BeginChild(id_name..'child_window_t_3', imgui.ImVec2((imgui.GetWindowWidth() - 15), imgui.GetWindowHeight() - imgui.GetCursorPos().y - 39), false, imgui.WindowFlags.HorizontalScrollbar)
			arrBtn = tmp.EvaArrBtn or arrBtn
			if i ~= 0 then
				local stPos = {['x'] = imgui.GetCursorScreenPos().x, ['y'] = imgui.GetCursorScreenPos().y + 5}
				local Drawlist = imgui.GetWindowDrawList()
				local mW = 0  
				local posTags = {}
				local textL = ''
				for k=2, #arrBtn do 
					if tmp.varEvIptMulti then
						local tTxt = regexTag(arrBtn[k], arrTag)
						local sTxt = imgui.CalcTextSize(tTxt).x
						mW = (mW < sTxt and sTxt or mW)
						textL = textL..tTxt..'\n'
						for _, t in ipairs(pushArrS(arrTag)) do
							local txt = (t[2] ~= '' and t[2] or t[3])
							local num = tTxt:find(txt:regular())
							while num do
								table.insert(posTags, {['x'] = imgui.CalcTextSize(tTxt:sub(1, num)).x - 2.1, ['y'] = (k-2)*14, ['w'] = imgui.CalcTextSize(txt).x - 0.5, ['t'] = txt}) 
								local stNum = tTxt:sub(1, num - 1)
								num = tTxt:sub(num + #txt):find(txt:regular())
								if num then num = num + #stNum + #txt end
							end
						end
					else
						textL = textL..arrBtn[k]..'\n'
						local sTxt = imgui.CalcTextSize(arrBtn[k]).x
						mW = (mW < sTxt and sTxt or mW)
						for _, t in ipairs(pushArrS(arrTag)) do
							local num = arrBtn[k]:find('{'..t[1]..'}')
							while num do
								table.insert(posTags, {['x'] = imgui.CalcTextSize(arrBtn[k]:sub(1, num)).x - 1.1, ['y'] = (k-2)*14, ['w'] = imgui.CalcTextSize('{'..t[1]..'}').x - 1.2, ['t'] = '{'..t[1]..'}'}) 
								local stNum = arrBtn[k]:sub(1, num)
								num = arrBtn[k]:sub(num + 1 + #t[1]):find('{'..t[1]..'}')
								if num then num = num + #stNum + #t[1] end
							end
						end
					end
				end

				for _, pos in ipairs(posTags) do
					imgui.SetCursorPos(imgui.ImVec2(pos.x, pos.y + 3))
					imgui.Text(pos.t)
					imgui.Tooltip(''..regexTag(pos.t, arrTag))
				end

				imgui.StrCopy(iptEv, textL)
				imgui.SetCursorPos(imgui.ImVec2(0, 0))
				if imgui.InputTextMultiline(id_name..'inputMulti_1', iptEv, sizeof(iptEv) - 1, imgui.ImVec2(
					(mW+30 > imgui.GetWindowWidth() and mW+30 or imgui.GetWindowWidth()) - (15*(#arrBtn+2) > imgui.GetWindowHeight() and 17 or 0),
					(15*(#arrBtn+2) > imgui.GetWindowHeight() and 15*(#arrBtn+2) or imgui.GetWindowHeight())),
					(tmp.varEvIptMulti and imgui.InputTextFlags.ReadOnly or 0) + imgui.InputTextFlags.NoHorizontalScroll + (esterscfg.events[arrName].tag and imgui.InputTextFlags.CallbackAlways or 0),
					callbacks.bindtag) then

					local arrL = {arrBtn[1]}
					for search in string.gmatch(str(iptEv), '[^%c]+') do
						arrL[#arrL+1] = search
					end
					tmp.EvaArrBtn = arrL
				end

				for _, pos in ipairs(posTags) do
					Drawlist:AddRectFilled(imgui.ImVec2(stPos.x + pos.x, stPos.y + pos.y), imgui.ImVec2(stPos.x + pos.x + pos.w, stPos.y + pos.y + 13), 0x490eb52a, 4, 15)
				end

			else
				imgui.StrCopy(iptEv, (tmp.varEvIptMulti and regexTag(arrBtn[2], arrTag) or arrBtn[2]))
				imgui.PushItemWidth(imgui.GetWindowWidth())
				if imgui.InputText(id_name..'input_15', iptEv, sizeof(iptEv) - 1, (tmp.varEvIptMulti and imgui.InputTextFlags.ReadOnly or 0)) then
					tmp.EvaArrBtn = {arrBtn[1], str(iptEv)}
				end
			end
		imgui.EndChild()

		imgui.NewLine()
		imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() / 2 - 235, imgui.GetWindowHeight() - 30))
		if imgui.Button('���������'..id_name..'btn_'..i, imgui.ImVec2(175, 0)) then
			if tmp.EvaArrBtn then
				if i ~= 0 then esterscfg.events[arrName][i] = tmp.EvaArrBtn
				else esterscfg.events.write[2] = tmp.EvaArrBtn[2] end
				tmp.EvaArrBtn = nil
			end
			tmp.varEvIptMulti = nil
			saveFile('estersBind.cfg', esterscfg)
			imgui.CloseCurrentPopup()
		end
		imgui.SameLine(nil, 120)
		if imgui.Button('�������'..id_name..'btn_'..i, imgui.ImVec2(175, 0)) then
			tmp.EvaArrBtn = nil
			tmp.varEvIptMulti = nil
			imgui.CloseCurrentPopup()
		end
		
		imgui.SetCursorPos((i ~= 0 and imgui.ImVec2(700, 450) or imgui.ImVec2(626, 165))) 
		imgui.EndPopup()
	end
end
function imgui.MeNotepad(arrName)
	imgui.TextCenter(' ������� \\ �������')
	local txtNotp = esterscfg.events[arrName].notepad or ''
	imgui.StrCopy(iptNotepad, iptTmp.notepad[arrName] or txtNotp)
	if imgui.InputTextMultiline(id_name..'input_multiline_1', iptNotepad, sizeof(iptNotepad) - 1, imgui.ImVec2(imgui.GetWindowWidth(), imgui.GetWindowHeight() - imgui.GetCursorPosY()-1)) then
		iptTmp.notepad[arrName] = str(iptNotepad)
	end
	if  not imgui.IsItemActive() and txtNotp ~= str(iptNotepad) then
		esterscfg.events[arrName].notepad = iptTmp.notepad[arrName]
		saveFile('estersBind.cfg', esterscfg)
	end
end

function imgui.WindowMain() 
	imgui.BeginChild(id_name..'child_7', imgui.ImVec2(imgui.GetWindowWidth() - 195, 180), false, 0)
		imgui.TextWrapped('������ �������� ��� ���������� ������� �������� ����������. ������ �� �������������� ��������, ��� ����������� ��� �� � ������� Scottdale. ������ ������� ������ �� ������, � �� �������������. ������� "����" ��� �����������, ������ ��������� � �����������. �� ����������� ��������, ������ ������ ������ ���� ��������, �� ����� ��������� � ����� ������� ���������������, ����������� �� ���������� ������ �������� ��������������� �� �����.\n\n�� ������ ������ ������ ��������� � ����� ������ - ��� ������, ���������, ������� ����� ��� ����� ����������, ������ ������ ���������������� ��� ����� ����������� ������ � ����������� �� ��������� �������.')
	imgui.EndChild()
	
	end
	
function imgui.LocalSettings() 
	imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - 112)
	if imgui.HeaderButton(buttonPages[1], ' ���������� ') then
		buttonPages = {true, false, false, false}
	end
	imgui.Tooltip('�������������� ���������� ����������')
	imgui.SameLine()
	if imgui.HeaderButton(buttonPages[2], ' ���������� ') then
		buttonPages = {false, true, false, false}
	end
	imgui.Tooltip('��������� ����������')
	imgui.SameLine()
	if imgui.HeaderButton(buttonPages[3], ' ������� ������� ') then
		buttonPages = {false, false, true, false}
	end
	imgui.Tooltip('��������� ����-�������')
	imgui.SetCursorPosY(32)
	if buttonPages[1] then imgui.Advertisement()
	elseif buttonPages[2] then imgui.AutoBind()
	elseif buttonPages[3] then imgui.AutoBindButton() end
end
function imgui.Advertisement() 
	imgui.StrCopy(inputReplace, tmp.field and tmp.field or '')
	imgui.SetCursorPosX(6)
	imgui.PushItemWidth(imgui.GetWindowWidth() - 94)
	if imgui.InputTextWithHint(id_name..'input_10', '�����..', inputReplace, sizeof(inputReplace) - 1, imgui.InputTextFlags.AutoSelectAll) then
		if tmp.field ~= str(inputReplace) then
			imgui.StrCopy(inputReplace, tostring(str(inputReplace):gsub('%.', ''):gsub('%(', ''):gsub('%)', ''):gsub('%%', ''):gsub('%+', ''):gsub('%-', ''):gsub('%*', '')))
			tmp.field = str(inputReplace)
		end
	end
	imgui.SameLine(0, 4)
	if imgui.Button('��������'..id_name..'button_6', imgui.ImVec2(80,0)) then
		tmp.field = nil
	end
	imgui.BeginChild(id_name..'child_window_4', imgui.ImVec2(imgui.GetWindowWidth() - 12, imgui.GetWindowHeight() - 60), false)
		local listAdvertisement = function (i, tbl)
			local tbl = tbl or {}
			imgui.SameTable(i, 'ad', function()
				imgui.StrCopy(inputAd, adcfg[i].ad)
				imgui.StrCopy(inputAdText, adcfg[i].text)
			end)
			if tmp.brea then tmp.brea = nil return true end
			imgui.SetCursorPosX(8)
			local addText = '{A52A2A}['..i..']{STANDART} '
			local subAdText = adcfg[i].ad
			local subText = adcfg[i].text
			for k=1, #tbl do
				local strInd = string.nlower(subAdText):find(tbl[k])
				local tStr = strInd and subAdText:sub(strInd, strInd + tbl[k]:len() - 1) or nil
				subAdText = tStr and subAdText:gsub(tStr, '{00cc99EE}'..tStr..'{STANDART}', 1) or subAdText
				local strInd, tStr = nil, nil
				local strInd = string.nlower(subText):find(tbl[k])
				local tStr = strInd and subText:sub(strInd, strInd + tbl[k]:len() - 1) or nil
				subText = tStr and subText:gsub(tStr, '{00cc99EE}'..tStr..'{STANDART}', 1) or subText
			end
			subAdText = addText..subAdText
			while imgui.CalcTextSize(tostring(subAdText:hexsub())).x > imgui.GetWindowWidth() / 2 - 22 do 
				subAdText = subAdText:sub(1, subAdText:len() - 2)
			end
			imgui.RenderText(string.len((addText..adcfg[i].ad):hexsub()) == #subAdText:hexsub() and subAdText or subAdText..'..')
			imgui.Tooltip(adcfg[i].ad)
			imgui.SameLine()
			imgui.SetCursorPosX(imgui.GetWindowWidth() / 2)
			imgui.RenderText(subText)
			imgui.Tooltip(adcfg[i].text)
		end

		imgui.PushFont(s2)

		local adstr = math.floor(imgui.GetScrollY() / 16)
		local admax = math.floor(imgui.GetWindowHeight() / 16) + 2 + adstr

		if string.len(tostring(u8:decode(str(inputReplace)):gsub('%s+', ''))) <= 1 then
			for i=1, #adcfg do
				if i >= adstr and i <= admax then
					if listAdvertisement(i) then break end
				else
					imgui.Text('')
				end
			end
		else 
			local adMstr = 1
			for i = 1, #adcfg do
				local stlin = {(adcfg[i].ad..' '..adcfg[i].text):nlower(), 0, 0, {}}
				for search in string.gmatch(string.nlower(str(inputReplace)), '[^%s]+') do
					stlin[2] = stlin[2] + 1
					if utf8len(search) < 2 then stlin[3] = stlin[3] + 1 end
					if utf8len(search) >= 2 and string.match(stlin[1], '[%s%p]('..search..'[%S]*)') then
						stlin[3] = stlin[3] + 1; stlin[4][#stlin[4] + 1] = search
					end
				end
				if stlin[2] == stlin[3] then
					if adMstr >= adstr and adMstr <= admax then
						if listAdvertisement(i, stlin[4]) then break end
					else
						imgui.Text('')
					end
					adMstr = adMstr + 1
				end
			end
		end
		imgui.PopFont()

	imgui.EndChild()
end
function imgui.AutoBind() 
	imgui.BeginChild(id_name..'child_window_5', imgui.ImVec2(imgui.GetWindowWidth() - 12, imgui.GetWindowHeight() - 40), false)
		imgui.TextStart('{ffff99BB}����������� ������')
		imgui.SameLine()

		imgui.StrCopy(inputReplace, autbincfg[1][1])
		imgui.PushItemWidth(imgui.CalcTextSize(inputReplace).x < 40 and imgui.CalcTextSize(inputReplace).x + 8 or 40)
		if imgui.InputText(id_name..'input_S1', inputReplace, sizeof(inputReplace) - 1, imgui.InputTextFlags.AutoSelectAll) then
			iptTmp.iptSign = str(inputReplace):gsub('%%', '')
		end
		if not imgui.IsItemActive() and iptTmp.iptSign and iptTmp.iptSign ~= '' and iptTmp.iptSign ~= autbincfg[1][1] then
			imgui.StrCopy(inputReplace, iptTmp.iptSign)
			autbincfg[1][1] = iptTmp.iptSign
			saveFile('autoBind.cfg', autbincfg)
		end
		imgui.SameLine()
		imgui.SetCursorPosY(-3)
		imgui.TextStart('{FFFFFF99}(?)')
		imgui.Tooltip('������ � �������� ����������\n������� ��� ����-������')

		imgui.SameLine()
		imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - 314, 0))
		imgui.StrCopy(inputAd, winSet[2][3] or '')
		imgui.PushItemWidth(55)
		if imgui.InputText(id_name..'input_S3', inputAd, sizeof(inputAd) - 1) then
			if str(inputAd) ~= winSet[2][3] then
				winSet[2][3] = str(inputAd)
			end
		end
		imgui.SameLine()
		imgui.StrCopy(inputAdText, winSet[2][4] or '')
		imgui.PushItemWidth(155)
		if imgui.InputText(id_name..'input_S4', inputAdText, sizeof(inputAdText) - 1) then
			if str(inputAdText) ~= winSet[2][4] then
				winSet[2][4] = str(inputAdText)
			end
		end
		imgui.SameLine()
		if imgui.Button('��������'..id_name..'button_S2', imgui.ImVec2(70,20)) and winSet[2][3] and winSet[2][4] then
			if winSet[2][3] ~= '' and winSet[2][4] ~= '' then
				autbincfg[#autbincfg + 1] = {winSet[2][3], winSet[2][4]}
				winSet[2][3], winSet[2][4] = nil, nil
				saveFile('autoBind.cfg', autbincfg)
			end
		end
		imgui.Tooltip('�������� ����� ����-������\n\n*���� �� ������ ���� �������')
		
		imgui.TextCenter('{F9FFFF88}������������ ��� ����������')
		imgui.BeginChild(id_name..'child_6', imgui.ImVec2(imgui.GetWindowWidth(), imgui.GetWindowHeight() - 42))
			local centSize = (imgui.GetWindowWidth() - (math.floor((imgui.GetWindowWidth() + 6) / 270) * 270 - 6)) / 2
			imgui.SetCursorPosX(centSize)
			for i=2, #autbincfg*2-1 do
				local m = (math.fmod(i, 2) == 0 and 1 or 2)
				i = (i+math.fmod(i,2))/2 + (math.fmod(i,2) == 1 and 0 or 1)
				imgui.StrCopy(inputReplace, autbincfg[i][m])
				imgui.PushItemWidth(m == 1 and 55 or 155)
				if imgui.InputText(id_name..'input_S2_'..i..m, inputReplace, sizeof(inputReplace) - 1) then
					if str(inputReplace) ~= '' and str(inputReplace) ~= autbincfg[i][m] then
						autbincfg[i][m] = str(inputReplace)
						saveFile('autoBind.cfg', autbincfg)
					end
				end
				imgui.StrCopy(inputReplace, autbincfg[i][1])
				imgui.SameLine(0)
				if m == 2 then
					if imgui.Button('�'..id_name..'button_S_'..i, imgui.ImVec2(20,20)) then
						table.remove(autbincfg, i)
						saveFile('autoBind.cfg', autbincfg)
						break
					end
					imgui.Tooltip('�������')
					if math.fmod(i-1, math.floor((imgui.GetWindowWidth() + 6) / 270)) ~= 0 then 
						imgui.SameLine()
						imgui.Text(i ~= #autbincfg and '|' or '')
						imgui.SameLine()
					else 
						imgui.SetCursorPosX(centSize)
					end
				end
			end
		imgui.EndChild()

	imgui.EndChild()
end
function imgui.AutoBindButton()
	imgui.BeginChild(id_name..'child_window_25', imgui.ImVec2(imgui.GetWindowWidth() - 12, imgui.GetWindowHeight() - 40), false)
		imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - 314, 0))
		hotkey.List['addNewBtn'] = hotkey.List['addNewBtn'] or {['keys'] = {}, ['callback'] = nil}
		KeyEditor('addNewBtn', nil, imgui.ImVec2(80,20))

		imgui.SameLine()
		imgui.StrCopy(iptBind, iptTmp.iptBind or '')
		imgui.PushItemWidth(130)
		imgui.InputText(id_name..'input_Ss3', iptBind, sizeof(iptBind) - 1)
		if not imgui.IsItemActive() and iptTmp.iptBind ~= str(iptBind) then
			iptTmp.iptBind = str(iptBind)
		end

		imgui.SameLine()
		if imgui.Button('��������'..id_name..'button_Ss2', imgui.ImVec2(70,20)) then
			if hotkey.List['addNewBtn'].keys[1] and iptTmp.iptBind ~= '' then
				table.insert(keybincfg, {hotkey.List['addNewBtn'].keys, iptTmp.iptBind})
				iptTmp.iptBind = nil
				hotkey.List['addNewBtn'].keys = {}
				saveFile('keyBind.cfg', keybincfg)
			end
		end
		imgui.Tooltip('�������� ����� ������\n\n*���� �� ������ ���� �������')

		imgui.TextCenter('{F9FFFF88}��������� ������ ��� �������')
		imgui.BeginChild(id_name..'child_window_26', imgui.ImVec2(imgui.GetWindowWidth(), imgui.GetWindowHeight() - 42), false)
			local centSize = (imgui.GetWindowWidth() - (math.floor((imgui.GetWindowWidth() + 6) / 270) * 270 - 6)) / 2
			imgui.SetCursorPosX(centSize)

			for i, btn in ipairs(keybincfg) do
				hotkey.List['bindCfg_'..i] = hotkey.List['bindCfg_'..i] or {['keys'] = btn[1], ['callback'] = nil}
				if KeyEditor('bindCfg_'..i, nil, imgui.ImVec2(80,20)) then
					keybincfg[i][1] = hotkey.List['bindCfg_'..i].keys
					saveFile('keyBind.cfg', keybincfg)
				end

				imgui.SameLine(0)
				imgui.StrCopy(iptBind, btn[2])
				imgui.PushItemWidth(130)
				imgui.InputText(id_name..'input_BindB_'..i, iptBind, sizeof(iptBind) - 1)
				if not imgui.IsItemActive() and btn[2] and btn[2] ~= str(iptBind) then
					keybincfg[i][2] = str(iptBind)
					saveFile('keyBind.cfg', keybincfg)
				end

				imgui.SameLine()
				if imgui.Button('�'..id_name..'button_Sb_'..i, imgui.ImVec2(20,20)) then
					table.remove(keybincfg, i)
					clearButtons()
					saveFile('keyBind.cfg', keybincfg)
					break
				end
				imgui.Tooltip('�������')

				if math.fmod(i, math.floor((imgui.GetWindowWidth() + 6) / 270)) ~= 0 then 
					imgui.SameLine()
					imgui.Text(i ~= #keybincfg and '|' or '')
					imgui.SameLine()
				else 
					imgui.SetCursorPosX(centSize)
				end
			end
		imgui.EndChild()
	imgui.EndChild()

end
function imgui.LocalEsters()
	imgui.SetCursorPosX(18)
	if imgui.HeaderButton(buttonPagesEf[5], ' ��������� ') then
		buttonPagesEf = {false, false, false, false, true}
	end
	imgui.SameLine()
	imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - 132)
	if imgui.HeaderButton(buttonPagesEf[1], '  ����������� ') then
		buttonPagesEf = {true, false, false, false, false}
	end
	imgui.SameLine()
	if imgui.HeaderButton(buttonPagesEf[2], ' ������� ') then
		buttonPagesEf = {false, true, false, false, false}
	end
	imgui.SameLine()
	if imgui.HeaderButton(buttonPagesEf[3], ' �������� ') then
		buttonPagesEf = {false, false, true, false, false}
	end
	imgui.SameLine()
	if imgui.HeaderButton(buttonPagesEf[4], ' ������ ') then
		buttonPagesEf = {false, false, false, true, false}
	end
	imgui.SetCursorPosY(32)

	if buttonPagesEf[1] then imgui.Events()
	elseif buttonPagesEf[2] then imgui.Text('�����..')
	elseif buttonPagesEf[3] then imgui.Text('�����..')
	elseif buttonPagesEf[4] then imgui.Text('�����..')
	elseif buttonPagesEf[5] then imgui.EventsSetting() end
end
function imgui.EventsSetting()
	imgui.BeginChild(id_name..'child_window_13', imgui.ImVec2(imgui.GetWindowWidth() - 12, imgui.GetWindowHeight() - 40), false)
		for i, tag in ipairs({{'name','��� � �������'},{'duty','��������� (� ��������� �����)'},{'tagCNN','��� � "/d" (��� "[]")'},{'city','����� � ����� ���'},{'server','��� ����� (������)'},{'music','����������� �������� � �����'}}) do
			imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - 160)
			imgui.PushItemWidth(180)
			imgui.StrCopy(inputEvSet, esterscfg.settings[tag[1]])
			imgui.InputText(id_name..'input_Es1_'..i, inputEvSet, sizeof(inputEvSet) - 1)
			if not imgui.IsItemActive() and esterscfg.settings[tag[1]] ~= str(inputEvSet) then
				esterscfg.settings[tag[1]] = str(inputEvSet)
				saveFile('estersBind.cfg', esterscfg)
			end
			if imgui.CalcTextSize(inputEvSet).x > 176 then
				imgui.Tooltip(str(inputEvSet))
			end
			imgui.SameLine()
			imgui.Text(tag[2])
		end
		imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - 160)
		imgui.SliderInt(' �������� ��� �������� ���������'..id_name..'slider_1', msgDelay, 1, 12, '%d sec')
		if not imgui.IsItemActive() and esterscfg.settings.delay ~= msgDelay[0] then
			if msgDelay[0] < 1 or msgDelay[0] > 12 then
				msgDelay[0] = esterscfg.settings.delay
				return
			end
			esterscfg.settings.delay = msgDelay[0]
			saveFile('estersBind.cfg', esterscfg)
		end
	imgui.EndChild()
end
function imgui.Events()
	imgui.BeginChild(id_name..'child_window_8', imgui.ImVec2(imgui.GetWindowWidth() - 12, imgui.GetWindowHeight() - 40), false)
		imgui.BeginChild(id_name .. 'child_window_9', imgui.ImVec2(88, imgui.GetWindowHeight()), false, imgui.WindowFlags.NoScrollbar)
			imgui.SetCursorPosX(1)
			imgui.CustomMenu({
				' ��������',
				' ����������',
				' �������',
				' ������',
				' �������',
				' ����������\n   ��������',
				' �����������',
				' �������',
			}, eventPages, imgui.ImVec2(88, 32), 0.08, true, 0, {
				'',
				'���������� - ������� �������� ��������������\n������, � ��������� ���� �����. (������: 10+10-20)',
				'������� - ������� �������� ������ � ����� �����\n����, � �������� ������ �������� � �������.\n(������: ��� - ���������)',
				'������ - ������� �������� � ����� �� �����\n�����, � ������ ���������� ����� ��� �\n������� ��������� ���������.',
				'������� � ������������ - ��������� ������\n�� ������ ������������ � �������� �������\n��������, � ����� ����������� �� ��\n��������� ���������.',
				'���������� �������� - ������� ��������\n�����-���� ���. ������� �� �������������\n������� �.�. ����������, � �������� ����\n�����. (������: Zn - ����)', 
				'���������� - ������� �������� ����� ��\n���������� / �������� / ����������� ������,\n� ������ ���������� �������� ����������\n������� �� ������� � ��� - ���������\n�� ����� ������������.',
				'������� - ������� �������� �����, �\n��������� ������ �������� ����� ��\n����� ������������ � ����\n��� - ��������� � ���������� �����\n����� ����� ������.',
				'����� - ������� �������� �����, ��������\n������ �������� ��� � �������.\n(������: ���� �� ����� - ����� ��� �����,\n�������� � ��� � �� - ����� ��� �����.)',
				'������ ������������ - ������� ��� ��������\n�����-������ ���������� �������� �����, �\n������ ���������� ������� ���/� ��� �\n������� � ��� - ��������� �� ����� ������������.',
				'������ ����������� - ������� ���������\n������ ����������, ��� ��������������, �\n��������� ������ �������� �������� ����\n� ��� - ��������� �� ����� ������������.', 
				'�������� - ������� ���������� �����\n� ��������� ���, � �������� ������\n�������, ��� ��� �� �����.', 
				'� ������ - ������� ����� ������� ��\n���������� ��������, � ������\n���������� �������� ������ �����\n� ���-��������� �� ������ ���\n��������� �� ����� ������������.',
				'������� - ������� ����� ������� �� ����\n������, � ������ ���������� �������� ������\n����� � ��� - ��������� �� ������ ���\n��������� �� ����� ������������.',
				'������ ��� ����? - ������� ����� ������\n� ������ ��� �������� �����������, �\n��������� ������ ��������\n���-��������� / ��������� �� �����\n������������, ����� �� ����������� ��� �� ���.', 
				'Stand-Up - ���������� ��������� �����,\n� ����������� �� � ����.\n���������� ���������� ����� ������,\n���������������, ��������� ������\n� ��-������� ����������� ���\n��������������, �����������\n��������� �������.'
			})
		imgui.EndChild()
		imgui.SameLine()
		imgui.SetCursorPosX(100)
		imgui.BeginChild(id_name .. 'child_window_10', imgui.ImVec2(imgui.GetWindowWidth() - 100, imgui.GetWindowHeight()), false, imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)
			if eventPages[0] == 1 then imgui.EventDescription()
				elseif eventPages[0] == 2 then imgui.Mathematics()
				elseif eventPages[0] == 3 then imgui.Capitals()
				elseif eventPages[0] == 4 then imgui.ToHide()
				elseif eventPages[0] == 5 then imgui.Greetings()
				elseif eventPages[0] == 6 then imgui.ChemicElements()
				elseif eventPages[0] == 7 then imgui.Interpreter()
				elseif eventPages[0] == 8 then imgui.Mirror()
				elseif eventPages[0] == 9 then imgui.Text('�����..')
				elseif eventPages[0] == 10 then imgui.Text('�����..')
				elseif eventPages[0] == 11 then imgui.Text('�����..')
				elseif eventPages[0] == 12 then imgui.Text('�����..')
				elseif eventPages[0] == 13 then imgui.Text('�����..')
				elseif eventPages[0] == 14 then imgui.Text('�����..')
				elseif eventPages[0] == 15 then imgui.Text('�����..')
				elseif eventPages[0] == 16 then imgui.Text('�����..')
				elseif eventPages[0] == 17 then imgui.Text('�����..') 
			end
		imgui.EndChild()
	imgui.EndChild()

end
function imgui.EventDescription()
	imgui.NewLine()
	imgui.SetCursorPosX(20)
	imgui.BeginChild(id_name..'child_window_23', imgui.ImVec2(imgui.GetWindowWidth() - 40, imgui.GetWindowHeight() - 38), false)
		imgui.TextWrapped('����� ��������� � �������� ��������, �� ������ �� ������������. ������ ������� ���������� ����� ����� �������������� ��� � �����! �� ���� �������� ������ ������� � ����.')
		imgui.TextStart('{b5e530cb}�� ������ �������� ����� ������! ���� �� ���� ������ ��������!')
		imgui.NewLine()
		imgui.TextWrapped('���� �� ����������� � ������ ��� ��� ����� �� ������ ������������ ������ ������, ����������� ������, ��� ������ ��� �� ���!')
		imgui.SetCursorPosY(imgui.GetWindowHeight() - 30)
		imgui.TextWrapped('p.s. � �� ����� � ���� � ������� �� ������� � ���, ��� ��� �� ����, ������ ��� ��� ���. ����������� ����� �������� �����!')
	imgui.EndChild()
end
function imgui.Mathematics()
	imgui.BeginChild(id_name..'child_window_11', imgui.ImVec2(math.floor(imgui.GetWindowWidth() / 3) * 2 - 8, imgui.GetWindowHeight()), false)
		imgui.SetCursorPosX(1)
		imgui.PushItemWidth(30)
		local iptID = new.char[256]('')
		imgui.StrCopy(iptID, iptTmp.iptID or '')
		if imgui.InputText(id_name..'input_9', iptID, sizeof(iptID) - 1, 16) then
			iptTmp.iptID = str(iptID)
			tmp.evNick = nil
			if tonumber(str(iptID)) and sampIsPlayerConnected(str(iptID)) then
				tmp.evNick = sampGetPlayerNickname(str(iptID)):gsub('_', ' '):gsub('^%[%d%d?%]', '')
			end
		end
		imgui.SameLine()
		imgui.Text('ID ������')
		imgui.Tooltip('ID ��� �������������� � ���������')

		imgui.SameLine()

		imgui.SetCursorPosX(imgui.GetWindowWidth() - 142)
		imgui.Text('�������')
		imgui.Tooltip('�������� ���� ������� �� ����')
		imgui.SameLine()
		imgui.PushItemWidth(80)
		local iptPrz = new.char[256]('')
		imgui.StrCopy(iptPrz, iptTmp.iptPrz or '1 ���')
		if imgui.InputText(id_name..'input_11', iptPrz, sizeof(iptPrz) - 1) then
			iptTmp.iptPrz = str(iptPrz)
		end

		imgui.SetCursorPosX(1)
		imgui.PushItemWidth(30)
		local iptScrId = new.char[256]('')
		imgui.StrCopy(iptScrId, iptTmp.iptScrId or '')
		if imgui.InputText(id_name..'input_10', iptScrId, sizeof(iptScrId) - 1, 16) then
			iptTmp.iptScrId = str(iptScrId)
		end
		imgui.SameLine()
		imgui.Text('���-�� ������')
		imgui.Tooltip('������� � �������� ������?')

		imgui.SameLine()

		imgui.SetCursorPosX(imgui.GetWindowWidth() - 88)
		imgui.Text('������')
		imgui.Tooltip('�� ������� ������ ����� ������?')
		imgui.SameLine()
		imgui.PushItemWidth(30)
		local iptScr = new.char[256]('')
		imgui.StrCopy(iptScr, iptTmp.iptScr or '5')
		if imgui.InputText(id_name..'input_12', iptScr, sizeof(iptScr) - 1) then
			iptTmp.iptScr = str(iptScr)
		end

		imgui.RenderButtonEf(esterscfg.events.mathem, {
			{'prize', iptTmp.iptPrz or '1 ���', '1 ���', '� ��� �� �������� {fead00}�������{C0C0C0} �� ������ ����!', '������� �� ����'},
			{'scores', iptTmp.iptScr or '5', '3', '� ��� �� �������� ������� {fead00}�������{C0C0C0} ����� � �����!', '���������� �������'},
			{'scoreID', iptTmp.iptScrId, '2', '� ��� �� �������� ������� {fead00}������{C0C0C0} � ��������!', '���������� ������ � ��������'},
			{'ID', tmp.evNick, 'Rudius Greyrat', '� ��� �� ������ {fead00}ID{C0C0C0} ��������!', '��� ��������'}
		})
	imgui.EndChild()

	imgui.SameLine()

	imgui.BeginChild(id_name..'child_window_12', imgui.ImVec2(math.floor(imgui.GetWindowWidth() / 3), imgui.GetWindowHeight()), false)
		imgui.TextCenter('�����������')

		imgui.SetCursorPos(imgui.ImVec2(8, imgui.GetCursorPosY() + 6))
		imgui.PushItemWidth(imgui.GetWindowWidth() - 20 - 4 - 18)
		local iptCal1 = new.char[256]('')
		imgui.StrCopy(iptCal1, iptTmp.iptCal1 or '')
		if imgui.InputTextWithHint(id_name..'input_13', '10+2^(10/2)*1.5', iptCal1, sizeof(iptCal1) - 1, imgui.InputTextFlags.CallbackAlways, callbacks.calc) then
			iptTmp.iptCal1 = str(iptCal1):gsub('[^%d%+%-%^%/%(%)%*%s%.]+', '')
			local calc = load('return '..iptTmp.iptCal1);
			local resul = tostring(calc and calc() or '������')
			if resul == 'nan' or resul == 'inf' then resul = ' /0 = err' end
			iptTmp.iptCal2 = (iptTmp.iptCal1 ~= '' and resul or '')
		end
		imgui.Tooltip('������� ��������������\n������, ��������� �������:\n\n + ���������\n - �������\n * ��������\n / ��������� (������ �����!)\n ^ �������� � �������\n () ��� ���������� ���������')

		imgui.SameLine(nil, 4)
		if imgui.Button('�'..id_name..'button_12', imgui.ImVec2(18,20)) then
			iptTmp.iptCal1 = nil
			iptTmp.iptCal2 = nil
		end
		imgui.Tooltip('��������')

		imgui.SetCursorPosX(8)
		imgui.Text('���������')
		imgui.SameLine()
		imgui.PushItemWidth(imgui.GetWindowWidth() - 20 - 67)
		local iptCal2 = new.char[256]('')
		imgui.StrCopy(iptCal2, iptTmp.iptCal2 or '')
		imgui.InputText(id_name..'input_14', iptCal2, sizeof(iptCal2) - 1, imgui.InputTextFlags.ReadOnly)

		imgui.SetCursorPosY(imgui.GetCursorPosY() + 6)
		imgui.Separator()
		imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)

		imgui.MeNotepad('mathem')
	imgui.EndChild()
end
function imgui.ChemicElements()
	imgui.BeginChild(id_name..'child_window_17', imgui.ImVec2(math.floor(imgui.GetWindowWidth() / 3) * 2 - 8, imgui.GetWindowHeight()), false)
		imgui.SetCursorPosX(1)
		imgui.PushItemWidth(30)
		local iptID = new.char[256]('')
		imgui.StrCopy(iptID, iptTmp.iptID or '')
		if imgui.InputText(id_name..'input_9', iptID, sizeof(iptID) - 1, 16) then
			iptTmp.iptID = str(iptID)
			tmp.evNick = nil
			if tonumber(str(iptID)) and sampIsPlayerConnected(str(iptID)) then
				tmp.evNick = sampGetPlayerNickname(str(iptID)):gsub('_', ' '):gsub('^%[%d%d?%]', '')
			end
		end
		imgui.SameLine()
		imgui.Text('ID ������')
		imgui.Tooltip('ID ��� �������������� � ���������')

		imgui.SameLine()

		imgui.SetCursorPosX(imgui.GetWindowWidth() - 142)
		imgui.Text('�������')
		imgui.Tooltip('�������� ���� ������� �� ����')
		imgui.SameLine()
		imgui.PushItemWidth(80)
		local iptPrz = new.char[256]('')
		imgui.StrCopy(iptPrz, iptTmp.iptPrz or '1 ���')
		if imgui.InputText(id_name..'input_11', iptPrz, sizeof(iptPrz) - 1) then
			iptTmp.iptPrz = str(iptPrz)
		end

		imgui.SetCursorPosX(1)
		imgui.PushItemWidth(30)
		local iptScrId = new.char[256]('')
		imgui.StrCopy(iptScrId, iptTmp.iptScrId or '')
		if imgui.InputText(id_name..'input_10', iptScrId, sizeof(iptScrId) - 1, 16) then
			iptTmp.iptScrId = str(iptScrId)
		end
		imgui.SameLine()
		imgui.Text('���-�� ������')
		imgui.Tooltip('������� � �������� ������?')

		imgui.SameLine()

		imgui.SetCursorPosX(imgui.GetWindowWidth() - 88)
		imgui.Text('������')
		imgui.Tooltip('�� ������� ������ ����� ������?')
		imgui.SameLine()
		imgui.PushItemWidth(30)
		local iptScr = new.char[256]('')
		imgui.StrCopy(iptScr, iptTmp.iptScr or '5')
		if imgui.InputText(id_name..'input_12', iptScr, sizeof(iptScr) - 1) then
			iptTmp.iptScr = str(iptScr)
		end

		imgui.RenderButtonEf(esterscfg.events.chemic, {
			{'prize', iptTmp.iptPrz or '1 ���', '1 ���', '� ��� �� �������� {fead00}�������{C0C0C0} �� ������ ����!', '������� �� ����'},
			{'scores', iptTmp.iptScr or '5', '3', '� ��� �� �������� ������� {fead00}�������{C0C0C0} ����� � �����!', '���������� �������'},
			{'scoreID', iptTmp.iptScrId, '2', '� ��� �� �������� ������� {fead00}������{C0C0C0} � ��������!', '���������� ������ � ��������'},
			{'ID', tmp.evNick, 'Rudius Greyrat', '� ��� �� ������ {fead00}ID{C0C0C0} ��������!', '��� ��������'}
		})
	imgui.EndChild()

	imgui.SameLine()

	imgui.BeginChild(id_name..'child_window_18', imgui.ImVec2(math.floor(imgui.GetWindowWidth() / 3), imgui.GetWindowHeight()), false)
		local chemicElem = {'H = �������', 'He = �����', 'Li = �����', 'Be = �������', 'B = ���', 'C = �������', 'N = ����', 'O = ��������',
			'F = ����', 'Ne = ����', 'Na = ������', 'Mg = ������', 'Al = ��������', 'Si = �������', 'P = ������', 'S = ����', 'Cl = ����',
			'Ar = �����', 'K = �����', 'Ca = �������', 'Sc = �������', 'Ti = �����', 'V = �������', 'Cr = ����', 'Mn = ��������', 'Fe = ������',
			'Co = �������', 'Cu = ����', 'Zn = ����', 'Ga = �����', 'Ge = ��������', 'As = ������', 'Se = �����', 'Br = ����', 'Kr = �������'
		}
		imgui.BeginChild(id_name..'child_window_24', imgui.ImVec2(imgui.GetWindowWidth(), imgui.GetWindowHeight() / 2 - 10), false)
			for i, element in ipairs(chemicElem) do
				local txtChat = '/news '..esterscfg.events.chemic.tag..element:sub(1, element:find(' ')-1)..' = ?'
				if imgui.Selectable(id_name..'selec_table_HIM_'..i, nil) then
					sampSetChatInputEnabled(true)
					sampSetChatInputText(u8:decode(txtChat))
				end
				imgui.Tooltip('�����������, ������� � ���:\n\n'..txtChat)
				imgui.SameLine(nil, imgui.GetWindowWidth() / 2 - 45)
				imgui.Text(element)
			end
		imgui.EndChild()

		imgui.SetCursorPosY(imgui.GetCursorPosY() + 6)
		imgui.Separator()
		imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)

		imgui.MeNotepad('chemic')
	imgui.EndChild()
end
function imgui.Greetings()
	imgui.BeginChild(id_name..'child_window_19', imgui.ImVec2(math.floor(imgui.GetWindowWidth() / 3) * 2 - 8, imgui.GetWindowHeight()), false)
		imgui.SetCursorPosX(1)
		imgui.PushItemWidth(30)
		local iptID = new.char[256]('')
		imgui.StrCopy(iptID, iptTmp.iptID or '')
		if imgui.InputText(id_name..'input_9', iptID, sizeof(iptID) - 1, 16) then
			iptTmp.iptID = str(iptID)
			tmp.evNick = nil
			if tonumber(str(iptID)) and sampIsPlayerConnected(str(iptID)) then
				tmp.evNick = sampGetPlayerNickname(str(iptID)):gsub('_', ' '):gsub('^%[%d%d?%]', '')
			end
		end
		imgui.SameLine()
		imgui.Text('ID ��������')
		imgui.Tooltip('ID ��������, ������� �������� ������')

		imgui.SameLine()

		imgui.SetCursorPosX(imgui.GetWindowWidth() - 81)
		imgui.Text('�����')
		imgui.Tooltip('������� ����� ���� ������ ����?')
		imgui.SameLine()
		imgui.PushItemWidth(30)
		local iptTime = new.char[256]('')
		imgui.StrCopy(iptTime, iptTmp.iptTime or '15')
		if imgui.InputText(id_name..'input_12', iptTime, sizeof(iptTime) - 1) then
			iptTmp.iptTime = str(iptTime)
		end

		imgui.SetCursorPosX(1)
		imgui.PushItemWidth(30)
		local iptToId = new.char[256]('')
		imgui.StrCopy(iptToId, iptTmp.iptToId or '')
		if imgui.InputText(id_name..'input_10', iptToId, sizeof(iptToId) - 1, 16) then
			iptTmp.iptToId = str(iptToId)
			tmp.evNick2 = nil
			if tonumber(str(iptToId)) and sampIsPlayerConnected(str(iptToId)) then
				tmp.evNick2 = sampGetPlayerNickname(str(iptToId)):gsub('_', ' '):gsub('^%[%d%d?%]', '')
			end
		end
		imgui.SameLine()
		imgui.Text('ID ��������')
		imgui.Tooltip('ID ��������, ������� �������� ������')

		imgui.RenderButtonEf(esterscfg.events.greet, {
			{'time', iptTmp.iptTime or '15', '30', '� ��� �� �������� ������� {fead00}�������{C0C0C0} ����� ���� ����!', '����� ������������ �����'},
			{'toID', tmp.evNick2, 'Sharky Flint', '� ��� �� �������� {fead00}ID ����{C0C0C0} �������� ������!', '��� ���� �������� ������'},
			{'ID', tmp.evNick, 'Rudius Greyrat', '� ��� �� ������ {fead00}ID ���{C0C0C0} �������� ������!', '��� ��� �������� ������'}
		}, {
			{'�������� ������', true, function (txt, tCon)
				for i, lTags in ipairs(tCon) do
					if lTags[1] == 'ID' and not lTags[2] then
						lTags[2] = '*'
					end
					if lTags[1] == 'toID' and not lTags[2] then
						lTags[2] = '*'
					end
					tCon[i] = lTags
				end
				local chTxt = regexTag(txt[2], tCon)
				sampSetChatInputEnabled(true)
				sampSetChatInputText(u8:decode(''..chTxt:gsub('%*', '', 1)))
				if chTxt:find('%*') then setChatCursorPos(utf8len(chTxt:match('(.-)%*'))) end
			end}
		})
	imgui.EndChild()

	imgui.SameLine()

	imgui.BeginChild(id_name..'child_window_20', imgui.ImVec2(math.floor(imgui.GetWindowWidth() / 3), imgui.GetWindowHeight()), false)
		imgui.MeNotepad('greet')
	imgui.EndChild()
end
function imgui.ToHide()
	imgui.BeginChild(id_name..'child_window_19', imgui.ImVec2(math.floor(imgui.GetWindowWidth() / 3) * 2 - 8, imgui.GetWindowHeight()), false)
		imgui.SetCursorPosX(1)
		imgui.PushItemWidth(30)
		local iptID = new.char[256]('')
		imgui.StrCopy(iptID, iptTmp.iptID or '')
		if imgui.InputText(id_name..'input_9', iptID, sizeof(iptID) - 1, 16) then
			iptTmp.iptID = str(iptID)
			tmp.evNick = nil
			if tonumber(str(iptID)) and sampIsPlayerConnected(str(iptID)) then
				tmp.evNick = sampGetPlayerNickname(str(iptID)):gsub('_', ' '):gsub('^%[%d%d?%]', '')
			end
		end
		imgui.SameLine()
		imgui.Text('ID ������')
		imgui.Tooltip('ID ��� �������������� � ���������')

		imgui.SameLine()

		imgui.SetCursorPosX(imgui.GetWindowWidth() - 142)
		imgui.Text('�������')
		imgui.Tooltip('�������� ���� ������� �� ����')
		imgui.SameLine()
		imgui.PushItemWidth(80)
		local iptPrz = new.char[256]('')
		imgui.StrCopy(iptPrz, iptTmp.iptPrz or '1 ���')
		if imgui.InputText(id_name..'input_11', iptPrz, sizeof(iptPrz) - 1) then
			iptTmp.iptPrz = str(iptPrz)
		end

		imgui.SetCursorPosX(1)
		imgui.PushItemWidth(138)
		local iptPhrase = new.char[256]('')
		imgui.StrCopy(iptPhrase, iptTmp.iptPhrase or '')
		if imgui.InputTextWithHint(id_name..'input_10', '������� ��������', iptPhrase, sizeof(iptPhrase) - 1) then
			iptTmp.iptPhrase = str(iptPhrase)
		end
		imgui.SameLine()
		imgui.Text('�����')
		imgui.Tooltip('�����, ������� ������� ������\n������� ��� ����������� � ���!')

		imgui.SameLine()

		imgui.SetCursorPosX(imgui.GetWindowWidth() - 81)
		imgui.Text('�����')
		imgui.Tooltip('������� ����� ���� ������ ����?')
		imgui.SameLine()
		imgui.PushItemWidth(30)
		local iptTime = new.char[256]('')
		imgui.StrCopy(iptTime, iptTmp.iptTime or '50')
		if imgui.InputText(id_name..'input_12', iptTime, sizeof(iptTime) - 1) then
			iptTmp.iptTime = str(iptTime)
		end

		imgui.RenderButtonEf(esterscfg.events.tohide, {
			{'prize', iptTmp.iptPrz or '1 ���', '1 ���', '� ��� �� ������� {fead00}�������{C0C0C0} �� ������ ����!', '������� �� ����'},
			{'time', iptTmp.iptTime or '50', '40', '� ��� �� �������� ������� {fead00}�������{C0C0C0} ����� ���� ����!', '������������ �����'},
			{'phrase', iptTmp.iptPhrase, '������� ��������', '� ��� �� ������� {fead00}�����{C0C0C0} ������� ����� �������!', '����� ������� ����� ��������'},
			{'ID', tmp.evNick, 'Rudius Greyrat', '� ��� �� ������ {fead00}ID{C0C0C0} ��������!', '��� ��������'}
		})
	imgui.EndChild()

	imgui.SameLine()

	imgui.BeginChild(id_name..'child_window_20', imgui.ImVec2(math.floor(imgui.GetWindowWidth() / 3), imgui.GetWindowHeight()), false)
		imgui.MeNotepad('tohide')
	imgui.EndChild()
end
function imgui.Capitals()
	imgui.BeginChild(id_name..'child_window_27', imgui.ImVec2(math.floor(imgui.GetWindowWidth() / 3) * 2 - 8, imgui.GetWindowHeight()), false)
		imgui.SetCursorPosX(1)
		imgui.PushItemWidth(30)
		local iptID = new.char[256]('')
		imgui.StrCopy(iptID, iptTmp.iptID or '')
		if imgui.InputText(id_name..'input_9', iptID, sizeof(iptID) - 1, 16) then
			iptTmp.iptID = str(iptID)
			tmp.evNick = nil
			if tonumber(str(iptID)) and sampIsPlayerConnected(str(iptID)) then
				tmp.evNick = sampGetPlayerNickname(str(iptID)):gsub('_', ' '):gsub('^%[%d%d?%]', '')
			end
		end
		imgui.SameLine()
		imgui.Text('ID ������')
		imgui.Tooltip('ID ��� �������������� � ���������')

		imgui.SameLine()

		imgui.SetCursorPosX(imgui.GetWindowWidth() - 142)
		imgui.Text('�������')
		imgui.Tooltip('�������� ���� ������� �� ����')
		imgui.SameLine()
		imgui.PushItemWidth(80)
		local iptPrz = new.char[256]('')
		imgui.StrCopy(iptPrz, iptTmp.iptPrz or '1 ���')
		if imgui.InputText(id_name..'input_11', iptPrz, sizeof(iptPrz) - 1) then
			iptTmp.iptPrz = str(iptPrz)
		end

		imgui.SetCursorPosX(1)
		imgui.PushItemWidth(30)
		local iptScrId = new.char[256]('')
		imgui.StrCopy(iptScrId, iptTmp.iptScrId or '')
		if imgui.InputText(id_name..'input_10', iptScrId, sizeof(iptScrId) - 1, 16) then
			iptTmp.iptScrId = str(iptScrId)
		end
		imgui.SameLine()
		imgui.Text('���-�� ������')
		imgui.Tooltip('������� � �������� ������?')

		imgui.SameLine()

		imgui.SetCursorPosX(imgui.GetWindowWidth() - 88)
		imgui.Text('������')
		imgui.Tooltip('�� ������� ������ ����� ������?')
		imgui.SameLine()
		imgui.PushItemWidth(30)
		local iptScr = new.char[256]('')
		imgui.StrCopy(iptScr, iptTmp.iptScr or '5')
		if imgui.InputText(id_name..'input_12', iptScr, sizeof(iptScr) - 1) then
			iptTmp.iptScr = str(iptScr)
		end

		imgui.RenderButtonEf(esterscfg.events.capitals, {
			{'prize', iptTmp.iptPrz or '1 ���', '1 ���', '� ��� �� �������� {fead00}�������{C0C0C0} �� ������ ����!', '������� �� ����'},
			{'scores', iptTmp.iptScr or '5', '3', '� ��� �� �������� ������� {fead00}�������{C0C0C0} ����� � �����!', '���������� �������'},
			{'scoreID', iptTmp.iptScrId, '2', '� ��� �� �������� ������� {fead00}������{C0C0C0} � ��������!', '���������� ������ � ��������'},
			{'ID', tmp.evNick, 'Rudius Greyrat', '� ��� �� ������ {fead00}ID{C0C0C0} ��������!', '��� ��������'}
		})
	imgui.EndChild()

	imgui.SameLine()

	imgui.BeginChild(id_name..'child_window_28', imgui.ImVec2(math.floor(imgui.GetWindowWidth() / 3), imgui.GetWindowHeight()), false)
		local capitalsCities = {
			'������� = ����', '��������� = ������-�����', '������� = ������', '���������� = �����', '������� = ��������', '�������� = �����',
			'�������������� = ������', '������� = �����', '�������� = ������', '������ = �����', '������ = �������', '����� = ����������',
			'������ = ����', '����� = ���-����', '���� = ������', '���� = �������', '������� = ������', '������ = ������', '����� = �����',
			'���� = ������', '������ = ����', '����� = �������', '������� = ������', '�������� = �������', '�������� = ����-�����',
			'���������� (���������) = ���������', '�������� = ����', '���� = ����', '������ = �������', '���������� = ��������',
			'������ = ������', '��� = ���������', '����� = ������', '�������� = ����������', '�������� = �������', '����� = �����',
			'������ = ������', '������� = ����', '������� = ����������', '��������� = ���������', '������� = �����', '�������� = ������',
			'����� = �����', '���� = ��������', '��������� = ����', '������ = ���������', '������� = ������', '������ = �����'
		}
		imgui.BeginChild(id_name..'child_window_24', imgui.ImVec2(imgui.GetWindowWidth(), imgui.GetWindowHeight() / 2 - 10), false)
			for i, capital in ipairs(capitalsCities) do
				local txtChat = '/news '..esterscfg.events.capitals.tag..capital:sub(1, capital:find(' ')-1)..' = ?'
				if imgui.Selectable(id_name..'selec_table_HIM_'..i, nil) then
					sampSetChatInputEnabled(true)
					sampSetChatInputText(u8:decode(txtChat))
				end
				imgui.Tooltip('�����������, ������� � ���:\n\n'..txtChat)
				imgui.SameLine(nil, imgui.GetWindowWidth() / 2 - 80)
				imgui.Text(capital)
			end
		imgui.EndChild()

		imgui.SetCursorPosY(imgui.GetCursorPosY() + 6)
		imgui.Separator()
		imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)


		imgui.MeNotepad('capitals')
	imgui.EndChild()
end
function imgui.Interpreter()
	imgui.BeginChild(id_name..'child_window_11', imgui.ImVec2(math.floor(imgui.GetWindowWidth() / 3) * 2 - 8, imgui.GetWindowHeight()), false)
		imgui.SetCursorPosX(1)
		imgui.PushItemWidth(30)
		local iptID = new.char[256]('')
		imgui.StrCopy(iptID, iptTmp.iptID or '')
		if imgui.InputText(id_name..'input_9', iptID, sizeof(iptID) - 1, 16) then
			iptTmp.iptID = str(iptID)
			tmp.evNick = nil
			if tonumber(str(iptID)) and sampIsPlayerConnected(str(iptID)) then
				tmp.evNick = sampGetPlayerNickname(str(iptID)):gsub('_', ' '):gsub('^%[%d%d?%]', '')
			end
		end
		imgui.SameLine()
		imgui.Text('ID ������')
		imgui.Tooltip('ID ��� �������������� � ���������')

		imgui.SameLine()

		imgui.SetCursorPosX(imgui.GetWindowWidth() - 142)
		imgui.Text('�������')
		imgui.Tooltip('�������� ���� ������� �� ����')
		imgui.SameLine()
		imgui.PushItemWidth(80)
		local iptPrz = new.char[256]('')
		imgui.StrCopy(iptPrz, iptTmp.iptPrz or '1 ���')
		if imgui.InputText(id_name..'input_11', iptPrz, sizeof(iptPrz) - 1) then
			iptTmp.iptPrz = str(iptPrz)
		end

		imgui.SetCursorPosX(1)
		imgui.PushItemWidth(30)
		local iptScrId = new.char[256]('')
		imgui.StrCopy(iptScrId, iptTmp.iptScrId or '')
		if imgui.InputText(id_name..'input_10', iptScrId, sizeof(iptScrId) - 1, 16) then
			iptTmp.iptScrId = str(iptScrId)
		end
		imgui.SameLine()
		imgui.Text('���-�� ������')
		imgui.Tooltip('������� � �������� ������?')

		imgui.SameLine()

		imgui.SetCursorPosX(imgui.GetWindowWidth() - 88)
		imgui.Text('������')
		imgui.Tooltip('�� ������� ������ ����� ������?')
		imgui.SameLine()
		imgui.PushItemWidth(30)
		local iptScr = new.char[256]('')
		imgui.StrCopy(iptScr, iptTmp.iptScr or '5')
		if imgui.InputText(id_name..'input_12', iptScr, sizeof(iptScr) - 1) then
			iptTmp.iptScr = str(iptScr)
		end

		imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - 75)
		imgui.PushItemWidth(120)
		imgui.Combo('����'..id_name..'combo_1', ComboLanguage, languageItems, #languageList)

		imgui.RenderButtonEf(esterscfg.events.interpreter, {
			{'prize', iptTmp.iptPrz or '1 ���', '1 ���', '� ��� �� �������� {fead00}�������{C0C0C0} �� ������ ����!', '������� �� ����'},
			{'scores', iptTmp.iptScr or '5', '3', '� ��� �� �������� ������� {fead00}�������{C0C0C0} ����� � �����!', '���������� �������'},
			{'scoreID', iptTmp.iptScrId, '2', '� ��� �� �������� ������� {fead00}������{C0C0C0} � ��������!', '���������� ������ � ��������'},
			{'language', languageList[ComboLanguage[0]+1]:match('(.+)....'), '��������', '� ��� �� ������ {fead00}����{C0C0C0} ������� �����!', '���� �� ������� ����� �����\n�������� ��������, ��� ��� ���������!'},
			{'ID', tmp.evNick, 'Rudius Greyrat', '� ��� �� ������ {fead00}ID{C0C0C0} ��������!', '��� ��������'}
		})
	imgui.EndChild()

	imgui.SameLine()

	imgui.BeginChild(id_name..'child_window_12', imgui.ImVec2(math.floor(imgui.GetWindowWidth() / 3), imgui.GetWindowHeight()), false)
		if imgui.BeginTabBar(id_name..'tabbar_1') then
			if imgui.BeginTabItem(' ������� '..id_name..'tabitem_1') then
				imgui.TextCenter('����������')

				imgui.SetCursorPos(imgui.ImVec2(8, imgui.GetCursorPosY() + 6))
				imgui.PushItemWidth(imgui.GetWindowWidth() - 20 - 4 - 18)
				local iptTrnsl = new.char[32]('')
				imgui.StrCopy(iptTrnsl, iptTmp.iptTrnsl or '')
				if imgui.InputTextWithHint(id_name..'input_13', '�������', iptTrnsl, sizeof(iptTrnsl) - 1, imgui.InputTextFlags.CharsNoBlank) then
					iptTmp.iptTrnsl = str(iptTrnsl)
				end
				imgui.Tooltip('������� ����� �����,\n  �� ��� ��������!')

				imgui.SameLine(nil, 4)
				if imgui.Button('�'..id_name..'button_12', imgui.ImVec2(18, 20)) then
					iptTmp.iptTrnsl = nil
					tmp.Trnsl = nil
				end
				imgui.Tooltip('��������')

				imgui.SetCursorPos(imgui.ImVec2(8, imgui.GetCursorPosY() + 3))
				if imgui.Button('���������'..id_name..'button_19', imgui.ImVec2(imgui.GetWindowWidth() - 20, 20)) and iptTmp.iptTrnsl and iptTmp.iptTrnsl ~= '' then
					lua_thread.create(function (word, lang, tmp)
						local st, func = pcall(loadstring, [[return {translate=function(txt, langTag, tmp)local commonAnswer = true local tName = os.tmpname()if doesFileExist(tName)then os.remove(tName)end downloadUrlToFile('https://translate.googleapis.com/translate_a/single?'..httpBuild({['client'] = 'gtx', ['dt'] = 't', ['sl'] = 'ru', ['tl'] = langTag, ['q'] = txt}), tName, function (_, st)if st==58 then if doesFileExist(tName)then local tFile=io.open(tName, 'r')if tFile then local answer=decodeJson(tFile:read('*a'))commonAnswer=(answer[1][1][1] and true or false)tmp.Trnsl=answer[1][1][1]or'������ �������!'tFile:close()os.remove(tName)end else tmp.Trnsl='��������� ������!'commonAnswer=false end end end)return commonAnswer end}]])
						if st then pcall(func().translate, word, lang, tmp) else tmp.Trnsl = '������ �������!' end
					end, iptTmp.iptTrnsl, langArr.tags[ComboLanguage[0]+2], tmp)
				end

				if tmp.Trnsl then 
					local txtChat = '/news '..esterscfg.events.interpreter.tag..tmp.Trnsl..' = ?'
					imgui.SetCursorPos(imgui.ImVec2(8, imgui.GetCursorPosY() + 3))
					imgui.PushStyleColor(imgui.Col.HeaderHovered, imgui.ImVec4(0, 0, 0, 0))
					imgui.PushStyleColor(imgui.Col.HeaderActive, imgui.ImVec4(0, 0, 0, 0))
					if imgui.Selectable(id_name..'selec_table_Wt', nil) then
						sampSetChatInputEnabled(true)
						sampSetChatInputText(u8:decode(txtChat))
					end
					imgui.PopStyleColor(2)
					imgui.Tooltip('�����������, ������� � ���:\n\n'..txtChat)
					imgui.SameLine(nil, imgui.GetWindowWidth() / 2 - imgui.CalcTextSize(tmp.Trnsl or ' ').x / 2 - 10)
					imgui.Text(tmp.Trnsl or ' ')
				end

				imgui.EndTabItem()
			end
			if imgui.BeginTabItem('���������'..id_name..'tabitem_2') then
				imgui.BeginChild(id_name..'child_window_24', imgui.ImVec2(imgui.GetWindowWidth(), imgui.GetWindowHeight() / 2 - 10), false)
					for i, word in ipairs(langArr.ru) do
						local foreignW = langArr[langArr.tags[ComboLanguage[0]+2]][i]
						local txtChat = '/news '..esterscfg.events.interpreter.tag..foreignW..' = ?'
						if imgui.Selectable(id_name..'selec_table_W_'..i, nil) then
							sampSetChatInputEnabled(true)
							sampSetChatInputText(u8:decode(txtChat))
						end
						imgui.Tooltip('�����������, ������� � ���:\n\n'..txtChat)
						imgui.SameLine(nil, imgui.GetWindowWidth() / 2 - 60)
						imgui.Text(word..' = '..foreignW)
					end
				imgui.EndChild()
				imgui.EndTabItem()
			end
			imgui.EndTabBar()
		end

		imgui.SetCursorPosY(imgui.GetCursorPosY() + 6)
		imgui.Separator()
		imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)

		imgui.MeNotepad('interpreter')
	imgui.EndChild()
end
function imgui.Mirror()
	imgui.BeginChild(id_name..'child_window_27', imgui.ImVec2(math.floor(imgui.GetWindowWidth() / 3) * 2 - 8, imgui.GetWindowHeight()), false)
		imgui.SetCursorPosX(1)
		imgui.PushItemWidth(30)
		local iptID = new.char[256]('')
		imgui.StrCopy(iptID, iptTmp.iptID or '')
		if imgui.InputText(id_name..'input_9', iptID, sizeof(iptID) - 1, 16) then
			iptTmp.iptID = str(iptID)
			tmp.evNick = nil
			if tonumber(str(iptID)) and sampIsPlayerConnected(str(iptID)) then
				tmp.evNick = sampGetPlayerNickname(str(iptID)):gsub('_', ' '):gsub('^%[%d%d?%]', '')
			end
		end
		imgui.SameLine()
		imgui.Text('ID ������')
		imgui.Tooltip('ID ��� �������������� � ���������')

		imgui.SameLine()

		imgui.SetCursorPosX(imgui.GetWindowWidth() - 142)
		imgui.Text('�������')
		imgui.Tooltip('�������� ���� ������� �� ����')
		imgui.SameLine()
		imgui.PushItemWidth(80)
		local iptPrz = new.char[256]('')
		imgui.StrCopy(iptPrz, iptTmp.iptPrz or '1 ���')
		if imgui.InputText(id_name..'input_11', iptPrz, sizeof(iptPrz) - 1) then
			iptTmp.iptPrz = str(iptPrz)
		end

		imgui.SetCursorPosX(1)
		imgui.PushItemWidth(30)
		local iptScrId = new.char[256]('')
		imgui.StrCopy(iptScrId, iptTmp.iptScrId or '')
		if imgui.InputText(id_name..'input_10', iptScrId, sizeof(iptScrId) - 1, 16) then
			iptTmp.iptScrId = str(iptScrId)
		end
		imgui.SameLine()
		imgui.Text('���-�� ������')
		imgui.Tooltip('������� � �������� ������?')

		imgui.SameLine()

		imgui.SetCursorPosX(imgui.GetWindowWidth() - 88)
		imgui.Text('������')
		imgui.Tooltip('�� ������� ������ ����� ������?')
		imgui.SameLine()
		imgui.PushItemWidth(30)
		local iptScr = new.char[256]('')
		imgui.StrCopy(iptScr, iptTmp.iptScr or '5')
		if imgui.InputText(id_name..'input_12', iptScr, sizeof(iptScr) - 1) then
			iptTmp.iptScr = str(iptScr)
		end

		imgui.RenderButtonEf(esterscfg.events.mirror, {
			{'prize', iptTmp.iptPrz or '1 ���', '1 ���', '� ��� �� �������� {fead00}�������{C0C0C0} �� ������ ����!', '������� �� ����'},
			{'scores', iptTmp.iptScr or '5', '3', '� ��� �� �������� ������� {fead00}�������{C0C0C0} ����� � �����!', '���������� �������'},
			{'scoreID', iptTmp.iptScrId, '2', '� ��� �� �������� ������� {fead00}������{C0C0C0} � ��������!', '���������� ������ � ��������'},
			{'ID', tmp.evNick, 'Rudius Greyrat', '� ��� �� ������ {fead00}ID{C0C0C0} ��������!', '��� ��������'}
		})
	imgui.EndChild()

	imgui.SameLine()

	imgui.BeginChild(id_name..'child_window_28', imgui.ImVec2(math.floor(imgui.GetWindowWidth() / 3), imgui.GetWindowHeight()), false)
		imgui.TextCenter('��������������� ����')

		imgui.SetCursorPos(imgui.ImVec2(8, imgui.GetCursorPosY() + 6))
		imgui.PushItemWidth(imgui.GetWindowWidth() - 20 - 4 - 18)
		local iptMir1 = new.char[64]('')
		imgui.StrCopy(iptMir1, iptTmp.iptMir1 or '')
		if imgui.InputTextWithHint(id_name..'input_13', '������', iptMir1, sizeof(iptMir1) - 1, imgui.InputTextFlags.CharsNoBlank) then
			iptTmp.iptMir1 = str(iptMir1)
			tmp.iptMir2 = nil
			if iptTmp.iptMir1 ~= '' then
				local inverted = u8:decode(iptTmp.iptMir1:nlower()):reverse()
				tmp.iptMir2 = u8:encode(inverted:match('^(.)')):nupper() .. u8:encode(inverted:match('^.(.*)'))
			end

		end
		imgui.Tooltip('������� ����� �����,\n  �� ��� ���������!')

		imgui.SameLine(nil, 4)
		if imgui.Button('�'..id_name..'button_12', imgui.ImVec2(18, 20)) then
			iptTmp.iptMir1 = nil
			tmp.iptMir2 = nil
		end
		imgui.Tooltip('��������')

		local txtChat = '/news '..esterscfg.events.mirror.tag..(tmp.iptMir2 and tmp.iptMir2..' = ?' or '������ = ?')
		imgui.SetCursorPos(imgui.ImVec2(8, imgui.GetCursorPosY() + 3))
		if imgui.Button(tmp.iptMir2 or '������'..id_name..'button_16', imgui.ImVec2(imgui.GetWindowWidth() - 20, 20)) then
			sampSetChatInputEnabled(true)
			sampSetChatInputText(u8:decode(txtChat))
		end
		imgui.Tooltip('�����������, ������� � ���:\n\n'..txtChat)

		imgui.SetCursorPosY(imgui.GetCursorPosY() + 6)
		imgui.Separator()
		imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)

		imgui.MeNotepad('mirror')
	imgui.EndChild()
end
function imgui.ScrSettings()
	if imgui.Checkbox('�������� ������ ����'..id_name..'checkbox_1', cheBoxSize) then
		setup.cheBoxSize = cheBoxSize[0]
		saveFile('settings.cfg', setup)
	end
	if KeyEditor('menu', '������� ������� ����', imgui.ImVec2(280,25)) then
		saveKeysBind()
	end
	if KeyEditor('helpMenu', '��������������� ����', imgui.ImVec2(280,25)) then
		saveKeysBind()
	end
	if KeyEditor('catchAd', '�������� ����������', imgui.ImVec2(280,25)) then
		saveKeysBind()
	end
	if KeyEditor('copyAd', '����������� ����������', imgui.ImVec2(280,25)) then
		saveKeysBind()
	end
	if KeyEditor('fastMenu', '������� ����', imgui.ImVec2(280,25)) then
		saveKeysBind()
	end
	imgui.PushItemWidth(280)
	imgui.SliderInt(id_name..'slider_2', newsDelay, 1, 50, '�������� "/newsredak" ('..newsDelay[0] * 10 ..')')
	if not imgui.IsItemActive() and setup.newsDelay ~= newsDelay[0] then
		if newsDelay[0] < 1 or newsDelay[0] > 50 then
			newsDelay[0] = setup.newsDelay
			return
		end
		setup.newsDelay = newsDelay[0]
		saveFile('settings.cfg', setup)
	end
	imgui.Tooltip('��� �������������� ��������, ���\n����� ��������. ���� � ��� �����\n"�� �����!", �������������\n��������� ��������')
end

function imgui.FmInterviews()
	local refusals = {
		{'�����', function ()
			tmp.fmRef = nil
		end},
		{'�������', function ()
			sampSendChat(u8:decode(tmp.targetPlayer.nick:gsub('_', ' ')..', ��������, �� �� ����������������� ���������. ��������� ����� �����������.'))
			wait(1000)
			sampSendChat(u8:decode('/b ����� �������� � ���. ���������, ����� ����� ������� 35+ �������'))
		end},
		{'����', function ()
			sampSendChat(u8:decode(tmp.targetPlayer.nick:gsub('_', ' ')..', ��������, �� �� ���������� � �� �����, ������� �� ������ � ��� ��������.'))
			wait(1000)
			sampSendChat(u8:decode('/b � ��� ���� WARN �� ��������.'))
		end},
		{'��� ���', function ()
			sampSendChat(u8:decode(tmp.targetPlayer.nick:gsub('_', ' ')..', ��������, �� � ��� � �������� ��������. ��������� � ���������.'))
			wait(1000)
			sampSendChat(u8:decode('/b � ��� ����� ���. ��� ����� ��������� � /mm - 1 - 12'))
		end},
		{'������ ���', function ()
			sampSendChat(u8:decode(tmp.targetPlayer.nick:gsub('_', ' ')..', ��������, �� �� ��������� � ������ �����������.'))
			wait(1000)
			sampSendChat(u8:decode('����� ���������� � ���, ��������� � ��������� �����.'))
		end},
		{'��� 3 ��', function ()
			sampSendChat(u8:decode(tmp.targetPlayer.nick:gsub('_', ' ')..', �������� �� ����� �������� � ���. ����������� ����� ����� 3-� ������ �������� � �����.'))
			wait(1000)
			sampSendChat(u8:decode('/b ��� ����� 3+ ������� ���������.'))
		end},
		{'� ��', function ()
			sampSendChat(u8:decode(tmp.targetPlayer.nick:gsub('_', ' ')..', ��������, �� �� ���������� � ������ ������ ����� �����������.'))
		end},
		{'�����', function ()
			sampSendChat(u8:decode(tmp.targetPlayer.nick:gsub('_', ' ')..', ��������, �� �� ��� �� ���������. �� �������������.'))
		end},
		{'���.�����', function ()
			sampSendChat(u8:decode(tmp.targetPlayer.nick:gsub('_', ' ')..', ��������, �� ��� ���� ����� �������� � ��� ����� �������� ���. �����.'))
			wait(1000)
			sampSendChat(u8:decode('�������� � ����� � ����� �������� �����.'))
		end}
	}
	local buttons = {
		{'�����������', function ()
			sampSendChat(u8:decode('������������, �� ������ �� �������������?'))
		end},
		{'������ ����������', function ()
			sampSendChat(u8:decode('������, �������� ���� ���������. � ������ �������, �������� � ���. �����.'))
			wait(1000)
			local myId = select(2,sampGetPlayerIdByCharHandle(PLAYER_PED))
			sampSendChat(u8:decode(string.format('/b /showpass %s | /showlic %s | /showmc %s', myId, myId, myId)))
		end},
		{'�������� ����������', function ()
			if sampIsDialogActive() then 
				if tmp.lastDialog.title == '{BFBBBA}���. �����' then
					sampSendChat(u8:decode('/me ���� � �������� �������� ���. �����, ����� ����������� ������ �'))
					wait(1000)
					if tmp.lastDialog.text:match('{FFFFFF}���: '..tmp.targetPlayer.nick) then
						local narko = tonumber(tmp.lastDialog.text:match('{CEAD2A}����������������: ([%d%.]+){FFFFFF}'))
						if narko <= 3 then -- 3 �������� �� ���������� ���������
							sampSendChat(u8:decode('/do ���. ����� �������� ��������.'))
							wait(1000)
							sampSendChat(u8:decode('/me ������ ���. ����� �������� ��������'))
						else
							for f=1, #refusals do
								if refusals[f][1] == '�����' then refusals[f][2]() break end
							end
						end
					else
						sampAddChatMessage(u8:decode(tag..'���. ������ ������� ��������!'), -1)
					end		
				elseif tmp.lastDialog.title == '{BFBBBA}�������' then
					sampSendChat(u8:decode('/me ���� � �������� �������� �������, ����� ����������� ������ ���'))
					wait(1000)
					if tmp.lastDialog.text:match('{FFFFFF}{FFFFFF}���: {FFD700}'..tmp.targetPlayer.nick) then
						if tmp.targetPlayer.score >= 3 then
							if tmp.lastDialog.text:match('{FF6200}������� � ��������������� ��������: %d+ .- %(���������� �������� ���%. �����%)') then
								for f=1, #refusals do
									if refusals[f][1] == '���.�����' then refusals[f][2]() break end
								end
							else
								if tonumber(tmp.lastDialog.text:match('{FFFFFF}�����������������: {FFD700}(%d+)/100')) < 35 then
									for f=1, #refusals do
										if refusals[f][1] == '�������' then refusals[f][2]() break end
									end
								else
									sampSendChat(u8:decode('/do � �������� ��� ��������.'))
									wait(1000)
									sampSendChat(u8:decode('/me ������ �������� �������� �������'))
								end
							end
						else
							for f=1, #refusals do
								if refusals[f][1] == '��� 3 ��' then refusals[f][2]() break end
							end
						end
					else
						sampAddChatMessage(u8:decode(tag..'������� ����������� ������� ��������!'), -1)
					end
				elseif tmp.lastDialog.title == '{BFBBBA}��������' then
					sampSendChat(u8:decode('/me ���� � �������� �������� ��������, ����� ����������� ������ ��'))
					wait(1000)
					if tmp.lastDialog.text:match('{FFFFFF}�������� �� ����: 		{FF6347}��� {cccccc}%(.-%)') then
						sampSendChat(u8:decode('/do ����������� �������� � �������� ���.'))
						wait(1000)
						sampSendChat(u8:decode('��� ���������� �������� �������� �� �������� �����������. ��� ����� ������� � ������ �������������� �. ���-������.'))
					else
						sampSendChat(u8:decode('/do ����������� �������� �������.'))
						wait(1000)
						sampSendChat(u8:decode('/me ������ �������� �������� ��������'))
					end
				elseif tmp.lastDialog.title == '{BFBBBA}{73B461}�������� �����������' and tmp.lastDialog.style == 5 then
					local numLine = -1
					for line in tmp.lastDialog.text:gmatch('[^\n]+') do
						if line:match('{ffffff} ���������� ���������� .-%.%.\t'..tmp.targetPlayer.nick) then
							tmp.fmActi = true; sampSendDialogResponse(tmp.lastDialog.id, 1, numLine, nil); break
						end
						numLine = numLine + 1
					end
					if not tmp.fmActi then
						sampAddChatMessage(u8:decode(tag..'������ ������� �� ��������� ���� ���������!'), -1)
					end
				end
			else
				tmp.fmActi, tmp.fmActiT = true, os.clock()
				sampSendChat(u8:decode('/offer'))
				while tmp.fmActi and (os.clock() - tmp.fmActiT < 3) do
					if tmp.lastDialog and tmp.lastDialog.title == '{BFBBBA}{73B461}�������� �����������' and tmp.lastDialog.style == 5 then
						local numLine = -1
						for line in tmp.lastDialog.text:gmatch('[^\n]+') do
							if line:match('{ffffff} ���������� ���������� .-%.%.\t'..tmp.targetPlayer.nick) then
								tmp.fmActi = true; sampSendDialogResponse(tmp.lastDialog.id, 1, numLine, nil); break
							end
							numLine = numLine + 1
						end
						if not tmp.fmActi then
							sampSendDialogResponse(tmp.lastDialog.id, 0, nil, nil)
							sampAddChatMessage(u8:decode(tag..'������ ������� �� ��������� ���� ���������!'), -1)
						end
						break
					end
					wait(100)
				end
			end
		end, '�������������� �������� ����������'},
		{'������ �1', function ()
			sampSendChat(u8:decode('������... ��� ��������� � ���� ��� �������?'))
		end, '� ���: ������... ��� ��������� � ���� ��� �������?'},
		{'������ �2', function ()
			sampSendChat(u8:decode('���������, ���������� ���-������ � ����?'))
		end, '� ���: ���������, ���������� ���-������ � ����?'},
		{'������ �3', function ()
			sampSendChat(u8:decode('������ �� ������� ������ ��� ����������?'))
		end, '� ���: ������ �� ������� ������ ��� ����������?'},
		{'�� ���������', function ()
			sampSendChat(u8:decode('����������! �� ��� ���������! ���������� ��������� �� 2 �����.'))
			wait(1000)
			sampSendChat(u8:decode('/invite '..tmp.targetPlayer.id))
		end, '� ���: ����������! �� ��� ���������!\n���������� ��������� �� 2 �����.'},
		{'�����', function ()
			tmp.fmRef = true
		end}
	}
	local menu = not tmp.fmRef and buttons or refusals
	for i=1, #menu do
		if imgui.Button(menu[i][1]..id_name..'button_FM_'..i, imgui.ImVec2(270, 27)) then
			if tmp.rolePlay then return end tmp.rolePlay = true
			lua_thread.create(function ()
				if tmp.fmRef then tmp.fmRef= nil end
				menu[i][2]()
				tmp.rolePlay = false
			end)
		end
		if menu[i][3] then imgui.Tooltip(menu[i][3]) end
	end
end

function imgui.Tooltip(text)
	if imgui.IsItemHovered() then
		imgui.BeginTooltip()
		imgui.PushFont(s4)
		imgui.Text(text)
		imgui.PopFont()
		imgui.EndTooltip()
	end
end
function imgui.TextStart(text)
	imgui.RenderText(tostring(text))
end
function imgui.TextCenter(text)
	text = tostring(text)
	imgui.SetCursorPosX(imgui.GetWindowWidth() / 2  - imgui.CalcTextSize(tostring(text:gsub('{%x%x%x%x%x%x%x?%x?}', ''):gsub('{STANDART}', ''))).x / 2 - 2)
	imgui.RenderText(text)
end
function imgui.TextEnd(text)
	text = tostring(text)
	imgui.SetCursorPosX(imgui.GetWindowWidth() - imgui.CalcTextSize(tostring(text:gsub('{%x%x%x%x%x%x%x?%x?}', ''):gsub('{STANDART}', ''))).x - 8)
	imgui.RenderText(text)
end
function imgui.isPlaceHovered(a, b)
	local m = imgui.GetMousePos()
	if m.x >= a.x and m.y >= a.y then
		if m.x <= b.x and m.y <= b.y then
			return true
		end
	end
	return false
end
function imgui.bringVec4To(from, to, start_time, duration)
    local timer = os.clock() - start_time
    if timer >= 0.00 and timer <= duration then
        local count = timer / (duration / 100)
        return imgui.ImVec4(
            from.x + (count * (to.x - from.x) / 100),
            from.y + (count * (to.y - from.y) / 100),
            from.z + (count * (to.z - from.z) / 100),
            from.w + (count * (to.w - from.w) / 100)
        ), true
    end
    return (timer > duration) and to or from, false
end
function imgui.bringFloatTo(from, to, start_time, duration)
    local timer = os.clock() - start_time
    if timer >= 0.00 and timer <= duration then
        local count = timer / (duration / 100)
        return from + (count * (to - from) / 100), true
    end
    return (timer > duration) and to or from, false
end
function imgui.set_alpha(color, alpha)
	alpha = alpha and imgui.limit(alpha, 0.0, 1.0) or 1.0
	return imgui.ImVec4(color.x, color.y, color.z, alpha)
end
function imgui.limit(v, min, max)
	min = min or 0.0
	max = max or 1.0
	return v < min and min or (v > max and max or v)
end
function updateFile(filename, default)
	local cfg = loadFile(filename, default)
	if default.reset ~= cfg.reset then 
		cfg = table.recuiteral(default, cfg)
		cfg.reset = default.reset
		saveFile(filename, cfg)
	end
	return cfg
end
function saveFile(filename, tbl)
	local direct = getWorkingDirectory() .. '\\config\\News Helper\\' .. filename
	if not pcall(table.save, tbl, direct) then
		print(u8:decode('{CC0F00}ERROR:{999999}������ ���������� �����: {FFAA00}'..filename))
		print(u8:decode('{CAAF00}!!! {999999}��� ���������� ������ �������, �������� ������������ {CAAF00}!!!'))
	end
end
function loadFile(filename, option)
	local direct = getWorkingDirectory() .. '\\config\\News Helper\\' .. filename
	local tTable = option
	if pcall(table.read, direct) then local st = table.read(direct) tTable = st or option else
		print(u8:decode('{CC0F00}ERROR:{999999}������ ��������� �����: {FFAA00}'..filename))
		print(u8:decode('{CAAF00}!!! {999999}���� ��������� ����������� ��������, ��� ����������..'))
		print(u8:decode('{999999}..����� ������ �������� ������������� ������� ����� ����� {CAAF00}!!!'))
	end
	return tTable
end
function table.save(tbl, fn)
	local f, err = io.open(fn, "w")
	if not f then
		return nil, err
	end
	tmp.tag = ''
	f:write(table.tostring(tbl, true))
	f:close()
	tmp.tag = nil
	return true
end
function table.read(fn)
	local f, err = io.open(fn, "r")
	if not f then
		return nil, err
	end
	local tbl = assert(loadstring("return " .. f:read("*a")))
	f:close()
	return tbl()
end
function table.key_to_str(k)
	if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
		return k
	end
	return "[" .. table.val_to_str(k) .. "]"
end
function table.val_to_str(v)
	if "string" == type(v) then
		v = string.gsub(v, "\\", "\\\\")
		v = string.gsub(v, "\n", "\\n")
		return "'" .. string.gsub(v,"'", "\\'") .. "'"
	end
	if tmp.tag then tmp.tag = tmp.tag .. '\t' end
		local tt = "table" == type(v) and table.tostring(v) or tostring(v)
	if tmp.tag then tmp.tag = '' end
	return tt
end
function table.tostring(tbl) 
	local result, done = {}, {}
	for k, v in ipairs(tbl) do
		table.insert(result, tmp.tag..'\t'..table.val_to_str(v))
		done[k] = true
	end
	for k, v in pairs(tbl) do
		if not done[k] then
			table.insert(result, tmp.tag..'\t'..table.key_to_str(k) .. " = " .. table.val_to_str(v))
		end
	end
	return tmp.tag:gsub('%s', '', 1).."{\n" .. table.concat(result, ",\n") .. "\n"..tmp.tag.."}"
end
function table.recuiteral(out, inA)
	if type(out) ~= 'table' or type(inA) ~= 'table' then return {} end
	local k, v = next(out)
	while k do
		if not inA[k] and type(k) == 'string' then
			inA[k] = v
		elseif type(v) == 'table' and type(inA[k]) == 'table' then
			inA[k] = table.recuiteral(v, inA[k]) 
		end
		k, v = next(out, k)
	end
	return inA
end

function utf8len(s)
	local s = tostring(s)
	local pos = 1
	local bytes = s:len()
	local len = 0
	while pos <= bytes do
		len = len + 1
		pos = pos + utf8charbytes(s, pos)
	end
	return len
end
function utf8charbytes(s, i)
    local i = i or 1
    local c = string.byte(s, i)

    if c > 0 and c <= 127 then
        return 1
    elseif c >= 194 and c <= 223 then
        local c2 = string.byte(s, i + 1)
        return 2
    elseif c >= 224 and c <= 239 then
        local c2 = s:byte(i + 1)
        local c3 = s:byte(i + 2)
        return 3
    elseif c >= 240 and c <= 244 then
        local c2 = s:byte(i + 1)
        local c3 = s:byte(i + 2)
        local c4 = s:byte(i + 3)
        return 4
    end
end
function utf8sub(s, i, j)
    local j = j or -1
    if i == nil then return "" end

    local pos = 1
    local bytes = string.len(s)
    local len = 0

    local l = (i >= 0 and j >= 0) or utf8len(s)
    local startChar = (i >= 0) and i or l + i + 1
    local endChar = (j >= 0) and j or l + j + 1

    if startChar > endChar then
        return ""
    end

    local startByte, endByte = 1, bytes

    while pos <= bytes do
        len = len + 1
        if len == startChar then
            startByte = pos
        end

        pos = pos + utf8charbytes(s, pos)
        if len == endChar then
            endByte = pos - 1
            break
        end
    end

    return string.sub(s, startByte, endByte)
end
function utf8replace(s, mapping)
    local pos = 1
    local bytes = string.len(s)
    local charbytes
    local newstr = ""

    while pos <= bytes do
        charbytes = utf8charbytes(s, pos)
        local c = string.sub(s, pos, pos + charbytes - 1)
        newstr = newstr .. (mapping[c] or c)
        pos = pos + charbytes
    end

    return newstr
end
function string.nlower(s)
    local s, res = string.lower(u8:decode(s)), {}
    for i = 1, #s do
        local ch = s:sub(i, i)
        res[i] = ul_rus[ch] or ch
    end
    return u8:encode(table.concat(res))
end
function string.nupper(s)
    local s, res = string.upper(u8:decode(s)), {}
    for i=1, #s do
        local ch = s:sub(i, i)
        res[i] = un_rus[ch] or ch
    end
    return u8:encode(table.concat(res))
end
function string.hexsub(str)
	return str:gsub('{%x%x%x%x%x%x%}', ''):gsub('{%x%x%x%x%x%x%x%x}', ''):gsub('{STANDART}', '')
end
function string.regular(rgx)
	local str = ''
	for i=1, #rgx do
		local sign = rgx:sub(i, i)
		if sign:match('%p') then
			str = str..string.char(37, sign:byte())
		else 
			str = str..string.char(sign:byte())
		end
	end
	return str
end
function urlEncode(str)
	local str = string.gsub(str, "\\", "\\")
	local str = string.gsub(str, "([^%w])", function (str) return string.format("%%%02X", string.byte(str)) end)
	return str
end
function httpBuild(query)
	local buff=""
	for k, v in pairs(query) do
		buff = buff.. string.format("%s=%s&", k, urlEncode(v))
	end
	local buff = string.reverse(string.gsub(string.reverse(buff), "&", "", 1))
	return buff
end


function getDownKeys()
    local t = {}
    for index, KEYID in ipairs(hotkey.LargeKeys) do
        if isKeyDown(KEYID) then
            table.insert(t, KEYID)
        end
    end
    return t
end
function GetKeysText(bind)
    local t = {}
    if hotkey.List[bind] then
        for k, v in ipairs(hotkey.List[bind].keys) do
            table.insert(t, vk.id_to_name(v):gsub('Numpad ', 'Num'):gsub('Arrow ', '') or 'UNK')
        end
    end
    return table.concat(t, ' + ')
end
function RegisterCallback(name, keys, callback)
    if hotkey.List[name] == nil then
        hotkey.List[name] = {
            keys = keys,
            callback = callback
        }
        return true else return false
    end
end
function KeyEditor(bindname, text, size)
    if hotkey.List[bindname] then
        local keystext = #hotkey.List[bindname].keys == 0 and hotkey.Text.no_key or GetKeysText(bindname)
        if hotkey.EditKey ~= nil then
            if hotkey.EditKey == bindname then
                keystext = hotkey.Text.wait_for_key
            end
        end 
        if imgui.Button((text ~= nil and text..': ' or '')..keystext..'##hotkey_EDITOR:'..bindname, size) then
            hotkey.Edit.backup = hotkey.List[bindname].keys
            hotkey.List[bindname].keys = {}
            hotkey.EditKey = bindname
        end
        if hotkey.Ret.name ~= nil then
            if hotkey.Ret.name == bindname then
                hotkey.Ret.name = nil
                return hotkey.Ret.data
			end
        end
    else
        imgui.Button('Bind "'..tostring(bindname)..'" not found##hotkey_EDITOR:BINDNAMENOTFOUND', size)
    end
	imgui.Tooltip('����� ������������ ����� ������� ���\n����������� �������. (Shift - ��������)\n\nAlt/Ctrl/Space/Enter + ����� �������.\nBackspace - ������� ��������� ����.\nESC - �������� ���������')
end
function saveKeysBind()
	for k, _ in pairs(setup.keys) do
		if hotkey.List[k] then
			setup.keys[k] = hotkey.List[k].keys
		end
	end
	saveFile('settings.cfg', setup)
end
function clearButtons()
	for k, _ in pairs(hotkey.List) do
		local var = k:match('bindCfg_([%d]+)')
		if var then
			hotkey.List['bindCfg_'..var] = nil
		end
	end
end

function sampSetCurrentDialogEditboxTextFix(txt) 
	local txt = tostring(txt)
	
	local sampGetDialogInfoPtr = memory.getuint32(sampModule + 0x26E898)
	local pEditBox = memory.getuint32(sampGetDialogInfoPtr + 0x24)
	local IsActive = memory.getint8(sampGetDialogInfoPtr + 0x28)
	if IsActive then
        setEditboxText = ffi.cast('void(__thiscall *)(uintptr_t this, char* text, int i)', sampModule + 0x84E70)
        setEditboxText(pEditBox, ffi.cast('char*', txt), 0)
    end
end
function setDialogCursorPos(pos)
    local m_pEditbox = memory.getuint32(sampGetDialogInfoPtr() + 0x24, true)
    memory.setuint8(m_pEditbox + 0x119, pos, true)
    memory.setuint8(m_pEditbox + 0x11E, pos, true)
end
function setChatCursorPos(pos)
    local pEditBox = memory.getuint32(sampGetInputInfoPtr() + 0x08, true)
    memory.setuint8(pEditBox + 0x119, pos, true)
    memory.setuint8(pEditBox + 0x11E, pos, true)
end
function getDialogCursorPos()
    local m_pEditbox = memory.getuint32(sampGetDialogInfoPtr() + 0x24, true)
    return memory.getuint8(m_pEditbox + 0x119, true)
end
function getChatCursorPos()
    local pEditBox = memory.getuint32(sampGetInputInfoPtr() + 0x08, true)
    return memory.getuint8(pEditBox + 0x119, true)
end

function pushArrS(arr)
	local arr = decodeJson(encodeJson(arr)) or {}
	for i, name in ipairs(nHelpEsterSet[1]) do
		table.insert(arr, {name, esterscfg.settings[name], nHelpEsterSet[3][i], '� ���������� ����������� {fead00}'..nHelpEsterSet[2][i]..'{C0C0C0} ���-�� ������������ � �����!', nHelpEsterSet[4][i]})
	end
	return arr
end
function regexTag(str, tagsArr)
	if not str then return 'err' end
	for _, t in ipairs(pushArrS(tagsArr)) do
		str = str:gsub('{'..t[1]..'}', t[2] ~= '' and t[2] or t[3])
	end
	return str
end
function findTag(arr, find)
	for _, str in ipairs(arr) do
		if str:find('{'..find..'}') then
			return true
		end
	end
	return false
end

function openMenu()
	if not isPauseMenuActive() then
		rMain[0] = not rMain[0]
		rSW[0] = false
	end
end
function resetIO()
    for i = 0, 511 do
        imgui.GetIO().KeysDown[i] = false
    end
    for i = 0, 4 do
        imgui.GetIO().MouseDown[i] = false
    end
    imgui.GetIO().KeyCtrl = false
    imgui.GetIO().KeyShift = false
    imgui.GetIO().KeyAlt = false
    imgui.GetIO().KeySuper = false
end

addEventHandler('onWindowMessage', function(msg, key) 
	if isSampAvailable() then
		if (msg == 0x0100 or msg == 260) and not sampIsChatInputActive() then 
			if hotkey.EditKey == nil then
				if (hotkey.no_flood and key ~= hotkey.lastkey) or (not hotkey.no_flood) then
					hotkey.lastkey = key
					for name, data in pairs(hotkey.List) do
						keys = data.keys
						if (#keys == 1 and key == keys[1]) or (#keys == 2 and isKeyDown(keys[1]) and key == keys[2]) then
							if data.callback then data.callback(name) end
						end
					end
				end
				if hotkey.EditKey ~= nil then
					if #hotkey.List[hotkey.EditKey] < 2 then
						table.insert(hotkey.List[hotkey.EditKey], key)
					end
				end
			else
				if key == vk.VK_ESCAPE then
					hotkey.List[hotkey.EditKey].keys = hotkey.Edit.backup
					hotkey.EditKey = nil
					consumeWindowMessage(true, false)
					return
				elseif key == vk.VK_BACK then
					hotkey.List[hotkey.EditKey].keys = {}
					hotkey.EditKey = nil
					saveKeysBind()
					clearButtons()
				end
			end
		elseif (msg == 0x0101 or msg == 261) and not sampIsChatInputActive() then
			if hotkey.EditKey ~= nil then
				if key == vk.VK_BACK then
					hotkey.List[hotkey.EditKey].keys = {}
					hotkey.EditKey = nil
				else
					local PressKey = getDownKeys()
					local LargeKey = PressKey[#PressKey]
					if LargeKey == 16 then return end 
					hotkey.List[hotkey.EditKey].keys = {#PressKey > 0 and PressKey[#PressKey] or key, #PressKey > 0 and key or nil}
					if hotkey.List[hotkey.EditKey].keys[1] == hotkey.List[hotkey.EditKey].keys[2] then
						hotkey.List[hotkey.EditKey].keys[2] = nil
					end
					hotkey.Ret.name = hotkey.EditKey
					hotkey.Ret.data = hotkey.List[hotkey.EditKey].keys
					hotkey.EditKey = nil
				end
			end
		end

		if msg == 0x100  then 
			if (key == vk.VK_TAB and (rMain[0] or rHelp[0] or rSW[0])) and not isPauseMenuActive() then
				
			end
			if (key == vk.VK_ESCAPE and (rMain[0] or rHelp[0] or rSW[0])) and not isPauseMenuActive() then
				consumeWindowMessage(true, false)
				if msg == 0x100 then
					if rSW[0] then rSW[0] = false; rMain[0] = true
					else rMain[0] = false; rHelp[0] = false; resetIO() end
				end
			end
		end
	end

end)

function Style()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
  
    style.WindowRounding = 5
    style.FrameRounding = 3
    style.ScrollbarRounding = 3
    style.GrabRounding = 1

    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.WindowBorderSize = 1
	style.FrameBorderSize = 1
    style.ScrollbarSize = 17

    colors[clr.Text] = ImVec4(0.86, 0.93, 0.89, 0.78)
    colors[clr.TextDisabled] = ImVec4(0.36, 0.42, 0.47, 1)
    colors[clr.WindowBg] =  ImVec4(0.11, 0.15, 0.17, 1)
    colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.FrameBg] = ImVec4(0.20, 0.25, 0.29, 1)
    colors[clr.FrameBgHovered] = ImVec4(0.12, 0.20, 0.28, 1)
    colors[clr.FrameBgActive] = ImVec4(0.09, 0.12, 0.14, 1)
	colors[clr.Tab] = ImVec4(0.26, 0.98, 0.85, 0.30)
	colors[clr.TabHovered] = ImVec4(0.26, 0.98, 0.85, 0.50)
	colors[clr.TabActive] = ImVec4(0.26, 0.98, 0.85, 0.50)
    colors[clr.TitleBg] = ImVec4(0.11, 0.15, 0.17, 1)
    colors[clr.TitleBgCollapsed] = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.TitleBgActive] = ImVec4(0.11, 0.15, 0.17, 1)
    colors[clr.MenuBarBg] = ImVec4(0.15, 0.18, 0.22, 1)
    colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.39)
    colors[clr.ScrollbarGrab] = ImVec4(0.26, 0.98, 0.85, 0.30)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.26, 0.98, 0.85, 0.50)
    colors[clr.CheckMark] = ImVec4(0.26, 0.98, 0.85, 1)
    colors[clr.SliderGrab] = ImVec4(0.23, 0.98, 0.84, 0.3)
    colors[clr.SliderGrabActive] = ImVec4(0.23, 0.98, 0.84, 0.7)
    colors[clr.Button] = ImVec4(0.26, 0.98, 0.85, 0.30)
    colors[clr.ButtonHovered] = ImVec4(0.26, 0.98, 0.85, 0.50)
    colors[clr.ButtonActive] = ImVec4(0.06, 0.98, 0.82, 0.50)
    colors[clr.Header] = ImVec4(0.26, 0.98, 0.85, 0.31)
    colors[clr.HeaderHovered] = ImVec4(0.26, 0.98, 0.85, 0.30)
    colors[clr.HeaderActive] = ImVec4(0.26, 0.98, 0.85, 0.60)
    colors[clr.ResizeGrip] = ImVec4(0.26, 0.59, 0.98, 0.25)
    colors[clr.ResizeGripHovered] = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1)
    colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1)
    colors[clr.PlotLinesHovered] = ImVec4(1, 0.43, 0.35, 1)
    colors[clr.PlotHistogram] =  ImVec4(0.90, 0.70, 0.00, 1)
    colors[clr.PlotHistogramHovered] = ImVec4(1, 0.60, 0.00, 1)
    colors[clr.TextSelectedBg] = ImVec4(0.25, 1, 0.00, 0.43)
	colors[clr.Border] = ImVec4(0.30, 0.35, 0.39, 1)
end


function loadVar()
	thUpd = {
		'',
		['tr'] = false,
		['inf'] = '',
		{
			{['version'] = '2.0 reload', {
				' - ������ �������.',
				' - ��������� ������� �������� � ���� ��������� ��������',
				' - ���� ������ ������� ����� ���������� �� �� �������',
				}
			},{['version'] = '1.9 release', {
				' - ������ �� ������ ������� � ����',
				' - ��������� ������ ������� ���, � ����� ������� ������ �������',
				}
			},{['version'] = '1.7 beta', {
				' ������ ��������������� ��� ��������� � ���, ���',
				' - ����������� ������� �������������� ���������� ����������',
				' - ������������� ��� � ��������',
				}
			}
		}
	}
	settingsSCR = {
		['reset'] = 'tet',
		['newsDelay'] = 13,
		['cheBoxSize'] = false,
		['thUpdDesc'] = nil,
		['keys'] = {
			['menu'] = {},
			['helpMenu'] = {vk.VK_DELETE},
			['catchAd'] = {vk.VK_F3},
			['copyAd'] = {vk.VK_DOWN},
			['fastMenu'] = {}
		}
	}
	newsHelpBind = {
		{'������� �����',
			{'����� ��� � ��', '����� ��� � �. ���-������. ������: '},
			{'����� ��� � ��', '����� ��� � �. ���-������. ������: '},
			{'����� ��� � ��', '����� ��� � �. ���-��������. ������: '},
			{'����� ��� � �����', '����� ��� � ������� ������. ������: '},
			{'����� ��� � �������', '����� ��� � �. *. ������: '},
			{'����� ��� � ��(�)', '����� ��� � �. ���-������ � ������� �� * ����. ������: '},
			{'����� ��� � ��(�)', '����� ��� � �. ���-������ � ������� �� * ����. ������: '},
			{'����� ��� � ��(�)', '����� ��� � �. ���-�������� � ������� �� * ����. ������: '},
			{'����� ��� � �������(�)', '����� ��� � �. * � ������� �� * ����. ������: '},
			{'����� ��� � �����(�)', '����� ��� � ������� ������ � ������� �� * ����. ������: '},
			{'����� ��� � ��(�)', '����� ��� � �. ���-������ � ��������. ������: '},
			{'����� ��� � ��(�)', '����� ��� � �. ���-������ � ��������. ������: '},
			{'����� ��� � ��(�)', '����� ��� � �. ���-�������� � ��������. ������: '},
			{'����� ��� � �������(�)', '����� ��� � �. * � ��������. ������: '},
			{'����� ��� � �����(�)', '����� ��� � ������� ������ � ��������. ������: '},
			{'����� ��� � ��(�+�)', '����� ��� � �. ���-������ � ������� � ��������. ������: '},
			{'����� ��� � ��(�+�)', '����� ��� � �. ���-������ � ������� � ��������. ������: '},
			{'����� ��� � ��(�+�)', '����� ��� � �. ���-�������� � ������� � ��������. ������: '},
			{'����� ��� � �������(�+�)', '����� ��� � �. * � ������� � ��������. ������: '},
			{'����� ��� � �����(�+�)', '����� ��� � ������� ������ � ������� � ��������. ������: '},
			{'����� ��� � ����� ��', '����� ��� � ����� ����� �����. ������: '},
		},{'������� �����',
			{'������ ��� � ��', '������ ��� � �. ���-������. ����: '},
			{'������ ��� � ��', '������ ��� � �. ���-������. ����: '},
			{'������ ��� � ��', '������ ��� � �. ���-��������. ����: '},
			{'������ ��� � �����', '������ ��� � ������� ������. ����: '},
			{'������ ��� � ��', '������ ��� � �. *. ����: '},
			{'������ ��� � ��(�)', '������ ��� � �. ���-������ � ������� �� * ����. ����: '},
			{'������ ��� � ��(�)', '������ ��� � �. ���-������ � ������� �� * ����. ����: '},
			{'������ ��� � ��(�)', '������ ��� � �. ���-�������� � ������� �� * ����. ����: '},
			{'������ ��� � �������(�)', '������ ��� � �. * � ������� �� * ����. ����: '},
			{'������ ��� � ����� (�)', '������ ��� � ������� ������ � ������� �� * ����. ����: '},
			{'������ ��� � ��(�)', '������ ��� � �. ���-������ � ��������. ����: '},
			{'������ ��� � ��(�)', '������ ��� � �. ���-������ � ��������. ����: '},
			{'������ ��� � ��(�)', '������ ��� � �. ���-�������� � ��������. ����: '},
			{'������ ��� � �������(�)', '������ ��� � �. * � ��������. ����: '},
			{'������ ��� � ����� (�)', '������ ��� � ������� ������ � ��������. ����: '},
			{'������ ��� � ��(�+�)', '������ ��� � �. ���-������ � ������� � ��������. ����: '},
			{'������ ��� � ��(�+�)', '������ ��� � �. ���-������ � ������� � ��������. ����: '},
			{'������ ��� � ��(�+�)', '������ ��� � �. ���-�������� � ������� � ��������. ����: '},
			{'������ ��� � �������(�+�)', '������ ��� � �. * � ������� � ��������. ����: '},
			{'������ ��� � ����� (�+�)', '������ ��� � ������� ������ � ������� � ��������. ����: '},
			{'������ ��� �', '������ ��� �� ����� *. ����: '}
		},{'������� ���������',
			{'329 �������', '�������� ������� �329! ����� ������ ���� � �����, ���� ������ ����!'},
			{'330 �������', '�������� ������� �330 � ������ �������� ������, ���� ������ ����!'},
		},{'������� ������������',
			{'������� ��� ��','�������� ��� �.���-������! ���� ���� ����������!'},
			{'������� ��� ��','�������� ��� �.���-������! ���� ���� ����������!'},
			{'������� ��� ��','�������� ��� �.���-��������! ���� ���� ����������!'},
		},{'�������/������� ����������',
			{'������ �/�','������ �/� "*". ����: '},
			{'����� �/�','����� �/� "*". ������: '},
			{'����� �/� ����� ������','����� �/� ����� ������. ������: '},
			{'������ �/�','������ �/� "*". ����: '},
			{'����� �/�','����� �/� "*". ������: '},
			{'����� �/� ����� ������','����� �/� ����� ������. ������: '},
			{'������ �/�', '������ �/� "*". ����: '},
			{'����� �/�', '����� �/� "*". ������: '},
			{'����� �/� ����� ������', '����� �/� ����� �����. ������: '},
			{'������ �/�', '������ �/� "*". ����: '},
			{'����� �/�', '����� �/�. ������: '},
			{'����� �/� ����� ������', '����� �/� ����� ������. ������: '},
			{'������ �/�', '������ �/� "*". ����: '},
			{'����� �/�', '����� �/� "*". ������: '},
			{'����� �/� ����� ������', '����� �/� ����� ������. ������: '},
			{'������ �/�', '������ �/�  "*". ����: '},
			{'����� �/�', '����� �/�  "*". ������: '},
			{'����� �/� ����� ������', '����� �/� ����� ������. ������: '}
		},{'�������/������� �/���',
			{'������ �/� � ��','������ �/� * � �. ���-������. ����: '},
			{'����� �/� � ��','����� �/� * � �. ���-������. ������: '},
			{'����� �/�','����� �/� � ����� ����� �����. ������: '},
			{'������ �/� � ��','������ �/� * � �. ���-������. ����: '},
			{'����� �/� � ��','����� �/� � �. ���-������. ������: '},
			{'������ �/�','������ �/� * �* . ����:'},
			{'������ �/� � ��','������ �/� * � � ���-��������. ����: '},
			{'����� �/� � ��','����� �/� � �. ���-��������. ������: '},
			{'������ �/� � ��','������ �/� � *. ����: '},
			{'����� �/� ��� ������','����� �/� � ����� ����� �����. ������: '},
		},{'�������/������� �����������/������',
			{'����� �/�','����� �/� "*". ������: '},
			{'������ �/�','������ �/� "*". ����: '},
			{'����� �/� � ��������','����� �/� "*" � ����������� "+*". ������: '},
			{'������ �/� � ��������','������ �/� "*" � ����������� "+*". ����: '},
			{'����� ����','����� �/� � ������ ����. ������: '},
			{'����� ���� �� ����','����� �/� � ������ "*". ������: '},
			{'������ ���� �� �����','����� �/� "*". ������: '},
			{'������ ���� �� ����','������ �/� � ������ "*". ����: '}
		},{'������� �/���',
			{'�������� ���','�������� ��� �*, � ��� ����� ������� ��� � �������! ����������'},
			{'�������� ����������','�������� ���������� �*, � ��� ����� ������� ���� �� ���� �����'},
			{'�������� �����','�������� ����� �*, � ��� ����� ������� ���������! ����������'},
			{'�������� 24/7','�������� ������� 24/7 �*, � ��� ����� ������� ����! ����� ����������'},
			{'�������� ���','�������� ��� �*, � ��� ����� ������������ �������. ���� ���'},
			{'�������� ���������','�������� ��������� �*, � ��� ����� ������������ ����������. '},
			{'�������� ��� �� �������','�������� ��� �� ������� ���������� � �. *. � ��� ��� ������'},
			{'�������� ��� �� �������','�������� ��� � �. *, ������� � ������������ ������ ������ ����������'},
			{'�������� ������ ������','��������� ������? ����� ���� � ������ ������ �* � �.'},
			{'�������� ����� ������','������ ����� ��� ������� ���� ����? ���� � ����� ������ �. '},
			{'�������� ������� ������','�� ������ ��������� ��� ����? ����� ���� � ������� ������ �'},
			{'�������� ����������', '����� ������ ����� ������ � ���! �������� �� ���������� � '}
		},{'������������� �����/�����',
			{'Warlock MC','�������� ������������� � ��� "��������� ���". ���� � ����'},
			{'Russian Mafia','�������� ������������� � ���� "������� �����". ������� � ��������'},
			{'LCN','�������� ����� � �� "������". ������� � ��������'},
			{'Yakuza','�������� ������������� � �������� �������� "Yakuza". ������� � ���������'},
			{'Tierra Robada Bikers', '�������� ������������� � ��� "Tierra Robada Bikers". ���� � ����'},
			{'Night Wolfs','�������� ������������� � �� "Night Wolfs". �������� ��� �� ������'},
			{'Groove','�������� ����� � �� "Groove".  �������� ��� �� ������'},
			{'The Ballas','�������� ����� � �� "Ballas". �������� ��� �� ������'},
			{'The Vagos','�������� ����� � �� "Vagos". �������� ��� �� ������'},
			{'The Aztecas','�������� ����� � �� "Aztec". �������� ��� �� ������'},
			{'The Rifa','�������� ����� � �� "Rifa". �������� ��� �� ������'}
		},{'������������� ����',
			{'���','�������� ������������� � ��� �. *. ���� ���!'},
			{'��','�������� ������������� � ������� �. *. ���� � �����!'},
			{'��','�������� ������������� � �������� �. *. ���� ���! '},
			{'���','�������� ������������� � ���! ���� ������ ����!'},
			{'���','�������� ������������� � ������ �������� ������! ���� ���!'},
			{'��','�������� ������������� � ����� �. *! ���� ��� � ����������! '},
			{'���', '�������� ������������� � ��������� ��������! ���� ������ ����!'},
			{'���-��','�������� ������������� � �������������! ���� ��� � �����!'}
		},{'�����',
			{'�� ����� ���������', '����� "*" �� ����� ��������� ���� �������������'},
			{'��� ���������', '����� * ���� �������������.'},
			{'��� �����', '��� �����. � ���� ��� �������. ������� ���������'}
		},{'�������� ������',
			{'����� �������� ������','����� �/� "�������� �����". ������/��:'},
			{'������ �������� ������','������ �/� "�������� ������". ����: */��'},
			{'����� �������� ������ (���-��)','����� �/� "�������� ������" � ���������� * ����. ������: '},
			{'������ �������� ������ (���-��)','������ �/� "�������� ������" � ���������� * ����. ����: */��'}
		},{'�������/������� ����������� �������',
			{'����� ����������� ������','����� �/� "����������� ������". ������: '},
			{'������ ����������� ������','������ �/� "����������� ������". ����: */��'},
			{'����� ����������� ������ (���-��)','����� �/� "����������� ������" � ���������� * ����. ������: '},
			{'������ ����������� ������ (���-��)','������ �/� "����������� ������" � ���������� * ����. ����: */��'}
		},{'�������/������� ��������/��������',
			{'����� �/�','����� �/� "". ������: */��'},
			{'������ �/�','������ �/� "". ����: */��'},
			{'����� �������','����� �/� "�������". ������: */��'},
			{'������ �������','������ �/� "�������". ����: */��'}
		},{'�������/������� "�/�, ���������, �����������"',
			{'����� ������','����� �/� "*". ������:'},
			{'������ ������','������ �/� "*". ����:'},
			{'����� �������','����� �/� "*". ������:'},
			{'������ ������� ','������ �/� "*". ����: '},
			{'����� �/� ','����� �/� "" ��� �/� "". ������:'},
			{'������ �/� ','������ �/� "" ��� �/� "". ����:'}
		},{'������',
			{'���� �/�', '���� �/� "*". ����: '},
			{'���� �/�', '���� �/� "*". ����: '},
			{'���� �/�', '���� �/� "*". ����: '},
			{'���� �/�', '���� �/� "*". ����: '},
			{'���� �/�', '���� �/� "*". ����: '},
			{'������ �/�', '������� �/� "*". ������: '},
			{'������ �/�', '������� �/� "*". ������: '},
			{'������ �/�', '������� �/� "*". ������: '},
			{'������ �/�', '������� �/� "*". ������: '},
			{'������ �/�', '������� �/� "*". ������: '}
		},{'������',
			{'����� AZ', '����� �/� "����� �� AZ-Coin". ������: '},
			{'������ AZ', '������ �/� "����� �� AZ-Coin". ����: '},
			{'����� EXP', '����� ����� "������������ EXP". ������: '},
			{'������ EXP', '������ ����� "������������ EXP". ����: '},
			{'������� ��� ��', '������ ����� "������������ EXP". ����: '},
		}
	}
	nHelpEsterSet = {
		{'name','duty','tagCNN','city','server','music'},
		{'��� � �������', '���������', '��� � �����������', '�����', '��� �����', '����������� ��������'},
		{'Faiser Andreich', '��������', '��� ��', '���-������', '���������', '������������������� �������� ������������ Prodigy News��������'},
		{'���� ���', '���� ���������', '��� � �����������', '����� ����� ���', '�������� ������ �������', '����������� ��������'}
	}
	newsHelpEsters = {
		['reset'] = 'bit4',
		['settings'] = {
			['name'] = '',
			['duty'] = '',
			['tagCNN'] = '��� ��',
			['city'] = '���-������',
			['server'] = '���������',
			['music'] = '������������������� �������� ������������ Prodigy News��������',
			['delay'] = 4
		},
		['events'] = {
			['write'] = {'�������� � /news', '/news {tag}'},
			['actions'] = {
				{'      ������ \n(RP ��������)',
					'/me ������� � �������� ����� � ������� ������� �������',
					'/do ������ 30 ������ ������� ��� �������.',
					'/me ������� �������� � ������ �� ����� ��������',
					'/me ����������� ��� � ���� �������',
					'/do ������ ��� ���� ������.',
					'/me ����� �������� �� ������',
					'/me ���������� ������ � ����, ��� �� ���� � ������������ � �����',
					'/todo ���, ���, ��� - ��� �������� �����!*������ � ��������',
					'/do �� �������� � ������ � ����������.'
				}, {'    ��������� \n(RP ��������)',
					'/me �������� �������� � ���� �������� � ������',
					'/me ����� �������� � ���� �������� �����',
					'/me ����� ���� ������ � �������� ������� �������',
					'/do ��� ���������� ���� ������� ���������.',
					'/me ��������� ������, ����� � ���� � ���������� � ������'
				}, ['name'] = 'actions'
			},
			['mathem'] = {
				{'������ ����',
					'/d [{tagCNN}]-[���] ������� ��������������� �����. ������� �� ����������!',
					'/news {music}',
					'/news {tag}����������� ���, ������� ��������� ����� {server}.',
					'/news {tag}� ��������� {duty} ��� �. {city}',
					'/news {tag}{name}!',
					'/news {tag}������ ������� ������ ���� �� ���� "����������".',
					'/news {tag}������� �������� ��� ���� � �������������!',
					'/news {tag}�������� ������� �����������...',
					'/news {tag}� ����� �������������� ������, � ��������� ������ �������� �����.',
					'/news {tag}������ ���������, ������� ������� ��������� � �������� ����. ������ �� {scores} ������.',
					'/news {tag}���� �� ������� ���������� {prize} �������� ����� {server}.',
					'/news {tag}������ ���������, �� ���������� �������.',
					'/news {tag}���������, ��� ������ ��������� ����� � ����������...',
					'/news {tag}���������� ���� ��������, ���������� �������� � ��������� � ��Ȼ,',
					'/news {tag}�������, ��������� ������������ �. {city} � ����������� ���� �����.',
					'/news {tag}�� ��� �, ������� ��������!'
				}, {'��������� ������',
					'/news {tag}��������� ������...'
				}, {'����!',
					'/news {tag}����! ����! ����!'
				}, {'���. ���������!',
					'/news {tag}���. ���������! �� ��������������, ����� ���������...'
				}, {'������ ���',
					'/news {tag}������ ��� {ID}! � � ���� ��� {scoreID} ���������� �������!'
				}, {'������� ����������',
					'/news {tag}� � ��� ���� ����������!',
					'/news {tag}� ���...',
					'/news {tag}{ID}! ��� ��� ������ �� ������� {scores} ���������� �������!',
					'/news {tag}{ID}, � ��� ����������! ��� �������� {prize}$!',
					'/news {tag}{ID}, � ����� ��� �������� � ���...',
					'/news {tag}� ���������� �. {city} �� ���������� ����� �������.'
				}, {'��������� ����',
					'/news {tag}�� ��� �, ������� ���������!',
					'/news {tag}������ ����� ����������� � ����.',
					'/news {tag}������� �� ������� ���������� ������ �� ����.',
					'/news {tag}����� ���������� ����� �����������',
					'/news {tag}� ���� ��� {name}, {duty} ������������ �. {city}.',
					'/news {tag}������ ���������� � ����� �������� ��� � ����� �������!',
					'/news {tag}�� ������� � �����!!!',
					'/news {music}',
					'/d [{tagCNN}]-[���] ��������� ��������������� �����, �������, ��� �� ����������, �� �����!'
				}, ['name'] = 'mathem', ['tag'] = '[����������]: '
			},
			['chemic'] = {
				{'������ ����',
					'/d [{tagCNN}]-[���] ������� ��������������� �����. ������� �� ����������!',
					'/news {music}',
					'/news {tag}����������� ���, ������� ��������� ����� {server}.',
					'/news {tag}� ��������� {name}, {duty} ��� �. {city}',
					'/news {tag}������ ������� ������ ���� �� ���� "���������� ��������".',
					'/news {tag}������� �������� ��� ���� � �������������...',
					'/news {tag}�������� ������� �����������...',
					'/news {tag}� ������� �����-�� ���������� ������� �� ������� ����������,...',
					'/news {tag}...� �� ������ �������� �������� ����� ��������.',
					'/news {tag}��������, "�" � "��������".',
					'/news {tag}���������, ������� ��������� � ������� ���� �������...',
					'/news {tag}...{scores} ����� ��������, ��������� � �����������.',
					'/news {tag}�� ��� ��� �������� �������� ����.',
					'/news {tag}���� �� ������� ���������� {prize} ��������.',
					'/news {tag}������ ���������, �� ���������� �������.',
					'/news {tag}���������, ��� ������ ��������� ����� � ����������...',
					'/news {tag}���������� ���� ��������, ��������� ������� ��������� � ��Ȼ...',
					'/news {tag}...��������� ������������ �. {city} � ����������� �����.',
					'/news {tag}������ � �������� ���������� �������� � �� ������!'
				}, {'��������� �������',
					'/news {tag}��������� �������...'
				}, {'����!',
					'/news {tag}����! ����! ����!'
				}, {'���. ���������!',
					'/news {tag}���. ���������! �� ��������������, ����� ���������...'
				}, {'������ ���',
					'/news {tag}������ ��� {ID}! � � ���� ��� {scoreID} ���������� �������!'
				}, {'������� ����������',
					'/news {tag}� � ��� ���� ����������!',
					'/news {tag}� ���...',
					'/news {tag}{ID}! ��� ��� ������ �� ������� {scores} ���������� �������!',
					'/news {tag}{ID}, � ��� ����������! ��� �������� {prize}$!',
					'/news {tag}{ID}, � ����� ��� �������� � ���...',
					'/news {tag}� ���������� �. {city} �� ���������� ����� �������.'
				}, {'��������� ����',
					'/news {tag}�� ��� �, ������� ���������!',
					'/news {tag}������ ����� ����������� � ����.',
					'/news {tag}������� �� ������ ��������� ���������� ��������.',
					'/news {tag}����� ���������� ����� �����������',
					'/news {tag}� ���� ��� {name}, {duty} ������������ �. {city}.',
					'/news {tag}������ ���������� � ����� �������� ��� � ����� �������!',
					'/news {tag}�� ������� � �����!!!',
					'/news {music}',
					'/d [{tagCNN}]-[���] ��������� ��������������� �����, �������, ��� �� ����������, �� �����!'
				}, ['name'] = 'chemic', ['tag'] = '[���.��������]: '
			},
			['greet'] = {
				{'������ ����',
					'/d [{tagCNN}]-[���] ������� ��������������� �����. ������� �� ����������!',
					'/news {music}',
					'/news {tag}����������� ���, ������� ��������� ����� {server}.',
					'/news {tag}� ��������� {name}, {duty} ��� �. {city}.',
					'/news {tag}������ ������� ������ ���� �� ���� "������� � ������������".',
					'/news {tag}������� �������� ��� ���� � �������������...',
					'/news {tag}�������� ������� �����������...',
					'/news {tag}���������� ���������� ���������� ��������� � ��������� �...',
					'/news {tag}...�������������� � ���� ���.',
					'/news {tag}� ������� ����� ���������� �� �� ���� ���� {server}.',
					'/news {tag}���������, ��� ������ ��������� ����� � ����������...',
					'/news {tag}���������� ���� �������� � ��������� ������� ��������� � ��Ȼ...',
					'/news {tag}...��������� ������������ �. {city} � ����������� �����.',
					'/news {tag}����������� ����� ������ ����� {time} �����, � � ����������...',
					'/news {tag}...�������� ������� ���� ��������.',
					'/news {tag}� ���, ������� ������. ��� ���� ���������!'
				}, {'�������� ������',
					'/news {tag}{ID} ������� ������ {toID}!'
				}, {'���. ���������!',
					'/news {tag}���. ���������! �� ��������������, ����� ���������...'
				}, {'��������� ����',
					'/news {tag}�� ��� �, ������� ���������!',
					'/news {tag}������ ����� ��������� � ����.',
					'/news {tag}������� �� �������� ������ ����� �������� � �������...',
					'/news {tag}...� ������� ������ �����.',
					'/news {tag}����� ���������� ����� �����������...',
					'/news {tag}� ���� ��� {name}, {duty} ������������ �. {city}.',
					'/news {tag}������ ���������� � ����� �������� ��� � ����� �������!',
					'/news {tag}�� ������� � �����!!!',
					'/news {music}',
					'/d [{tagCNN}]-[���] ��������� ��������������� �����, �������, ��� �� ����������, �� �����!'
				}, ['name'] = 'greet', ['tag'] = '[�������]: '
			},
			['tohide'] = {
				{'������ ����',
					'/d [{tagCNN}]-[���] ������� ��������������� �����. ������� �� ����������!',
					'/news {music}',
					'/news {tag}����������� ���, ������� ��������� ����� {server}.',
					'/news {tag}� ��������� {name}, {duty} ������������ �. {city}.',
					'/news {tag}������ ������� ������ ���� �� ���� �������.',
					'/news {tag}������� �������� ��� ���� � �������������...',
					'/news {tag}�������� ������� �����������...',
					'/news {tag}� �������� �� ������������ ����� �� ���������� ����� {server}...',
					'/news {tag}... � �������� ���� ��������������.',
					'/news {tag}���� ������ � ����� ����.',
					'/news {tag}������ ��������� ������, �� ��� �� ���...',
					'/news {tag}���������, ������� ������ ����� ����, ������ ������� �����-����.',
					'/news {tag}��� ����� ������ �� �� ������� �������� �������� ����.',
					'/news {tag}����� �����: �{phrase}�',
					'/news {tag}������, ��� ���������� �����, �������� �������� ����.',
					'/news {tag}���� �� ������� ���������� {prize} ��������.',
					'/news {tag}������ ���������, �� ���������� �������.',
					'/news {tag}���� � ������� {time} ����� ����� �� ������ ���� �����, �� �...',
					'/news {tag}...������� ���� �������������� � GPS.',
					'/news {tag}� ����� �� ����� ���� �������...',
					'/news {tag}���� ����������� �������!',
				}, {'������� ����������',
					'/news {tag}���� ����, �������, � ��� ���� ���������� �������!',
					'/news {tag}������ ��� {ID}! ���������� ���, ��� �������� {prize}.'
				}, {'���. ���������!',
					'/news {tag}���. ���������! �� ��������������, ����� ���������...'
				}, {'��������� ����',
					'/news {tag}�� ��� �, ������� ���������!',
					'/news {tag}������ ����� ��������� � ����.',
					'/news {tag}������� �� ���������� ����� ���� �� ���������� ����� {server}.',
					'/news {tag}� ������ ���������� ��� ����������, � ���� �� ��� ����� ����������!',
					'/news {tag}����� ���������� ����� �����������...',
					'/news {tag}� ���� ��� {name}, {duty} ������������ �. {city}.',
					'/news {tag}������ ���������� � ����� �������� ��� � ����� �������!',
					'/news {tag}�� ������� � �����!!!',
					'/news {music}',
					'/d [{tagCNN}]-[���] ��������� ��������������� �����, �������, ��� �� ����������, �� �����!'
				}, ['name'] = 'tohide', ['tag'] = '[������]: '
			},
			['capitals'] = {
				{'������ ����',
					'/d [{tagCNN}]-[���] ������� ��������������� �����. ������� �� ����������!',
					'/news {music}',
					'/news {tag}����������� ���, ������� ��������� ����� {server}.',
					'/news {tag}� ��������� {name}, {duty} ��� �. {city}.',
					'/news {tag}������ ������� ������ ���� �� ���� "�������".',
					'/news {tag}������� �������� ��� ���� � �������������...',
					'/news {tag}�������� ������� �����������...',
					'/news {tag}� ������ �������� ������ � ����� ����� ����, ...',
					'/news {tag}... � �� ������ �������� ��������� � ������� �� ��� ������.',
					'/news {tag}������ ���������, ��� ������� ���������, �������� ���� ����.',
					'/news {tag}����� ����� ���������� {scores} �����!',
					'/news {tag}������, ��� ��������� ��� �������, �������� �������� ����.',
					'/news {tag}���� �� ������� ���������� {prize} ��������.',
					'/news {tag}������ ���������, �� ���������� �������.',
					'/news {tag}���������, ��� ������ ��������� ����� � �����������',
					'/news {tag}���������� ���� ��������, ���������� �������� � ��������� � ��Ȼ...',
					'/news {tag}... ��������� ������������ �. {city} � ����������� �����.',
					'/news {tag}� ���... �� ��������!!!'
				}, {'��������� ������',
					'/news {tag}��������� ������...'
				}, {'����!',
					'/news {tag}����! ����! ����!'
				}, {'���. ���������!',
					'/news {tag}���. ���������! �� ��������������, ����� ���������...'
				}, {'������ ���',
					'/news {tag}������ ��� {ID}! � � ���� ��� {scoreID} ���������� �������!'
				}, {'������� ����������',
					'/news {tag}� � ��� ���� ����������!',
					'/news {tag}� ��� {ID}',
					'/news {tag}{ID}! ��� ��� ������ �� ������� {scores} ���������� �������!',
					'/news {tag}�� ������� ������ ���-�� ������.',
					'/news {tag}{ID}, � ��� ����������! ��� ������� {prize}$!',
					'/news {tag}{ID}, � ����� ��� �������� � ���...',
					'/news {tag}� ���������� �. {city} �� ���������� ����� �������.'
				}, {'��������� ����',
					'/news {tag}�� ��� �, ������� ���������!',
					'/news {tag}������ ����� ��������� � ����.',
					'/news {tag}������� �� � ���� ������ ��������� ������ � �� �������.',
					'/news {tag}����� ��� ���� ���������...',
					'/news {tag}� ���� ��� {name}, {duty} ������������ �. {city}.',
					'/news {tag}������ ���������� � �������� ����� �������!',
					'/news {tag}�� ������� � �����!!!',
					'/news {music}',
					'/d [{tagCNN}]-[���] ��������� ��������������� ����� 114.6 FM, �� �����!'
				}, ['name'] = 'capitals', ['tag'] = '[�������]: '
			},
			['mirror'] = {
				{'������ ����',
					'/d [{tagCNN}]-[���] ������� ��������������� �����. ������� �� ����������!',
					'/news {music}',
					'/news {tag}����������� ���, ������� ��������� ����� {server}.',
					'/news {tag}� ��������� {name}, {duty} ������������ �. {city}.',
					'/news {tag}������ ������� ������ ���� �� ���� ��������.',
					'/news {tag}������� �������� ��� ���� � �������������...',
					'/news {tag}�������� ������� �����������...',
					'/news {tag}� ������� �����-�� ����� � ��������������� �������.',
					'/news {tag}�� ���� ��������� ��� ����� ��������, ...',
					'/news {tag}... ��������, ������� - ��������.',
					'/news {tag}������ ��� ��� �� ����� �� ��� ������, �� ������, ��� �� ����������.',
					'/news {tag}���������, ������� ��������� � ������� ���� ������� ...',
					'/news {tag}... {scores} ����� �����, ��������� � �����������.',
					'/news {tag}� �������� �������� ����.',
					'/news {tag}���� �� ������� ���������� {prize} ��������.',
					'/news {tag}������ ���������, �� ���������� �������.',
					'/news {tag}���������, ��� ������ ��������� ����� � ����������...',
					'/news {tag}���������� ���� ��������, ���������� �������� � ��������� � ��Ȼ ...',
					'/news {tag}... ��������� ������������ �. {city} � ����������� �����.',
					'/news {tag}������ � ����� ���������� ����� � �� ������!'
				}, {'��������� ������',
					'/news {tag}��������� ������...'
				}, {'����!',
					'/news {tag}����! ����! ����!'
				}, {'���. ���������!',
					'/news {tag}���. ���������! �� ��������������, ����� ���������...'
				}, {'������ ���',
					'/news {tag}������ ��� {ID}! � � ���� ��� {scoreID} ���������� �������!'
				}, {'������� ����������',
					'/news {tag}� � ��� ���� ����������!',
					'/news {tag}� ���...',
					'/news {tag}{ID}! ��� ��� ������ �� ������� {scores} ���������� �������!',
					'/news {tag}{ID}, � ��� ����������! ��� �������� {prize}$!',
					'/news {tag}{ID}, � ����� ��� �������� � ���...',
					'/news {tag}� ���������� �. {city} �� ���������� ����� �������.'
				}, {'��������� ����',
					'/news {tag}�� ��� �, ������� ���������!',
					'/news {tag}������ ����� ��������� � ����.',
					'/news {tag}������� �� ������� ������ �� ���� ����������� ����� � ���������.',
					'/news {tag}��� �������, ������� ������ ����� ������ � ������� �������!',
					'/news {tag}����� ���������� ����� �����������...',
					'/news {tag}� ���� ��� {name}, {duty} ������������ �. {city}.',
					'/news {tag}������ ���������� � ����� �������� ��� � ����� �������!',
					'/news {tag}�� ������� � �����!!!',
					'/news {music}',
					'/d [{tagCNN}]-[���] ��������� ��������������� �����, �������, ��� �� ����������, �� �����!'
				}, ['name'] = 'mirror', ['tag'] = '[�������]: ',
				['notepad'] = '������ = ������\n����� = �����\n���� = ����\n����� = �����\n������� = �������\n�������� = ��������\n������ = ������\n������� = �������\n���� = ����\n�������� = ��������\n��� = ���\n������ = ������\n��������� = ���������\n������� = �������\n����� = �����\n��� = ���\n������� = �������\n���� = ����\n������� = �������\n������� = �������\n'
			},
			['interpreter'] = {
				{'������ ����',
					'/d [{tagCNN}]-[���] ������� ��������������� �����. ������� �� ����������!',
					'/news {music}',
					'/news {tag}����������� ���, ������� ��������� ����� {server}.',
					'/news {tag}� ��������� {duty} ��� �. {city}',
					'/news {tag}{name}!',
					'/news {tag}������ ������� ������ ���� �� ���� "�����������".',
					'/news {tag}������� �������� ��� ���� � �������������!',
					'/news {tag}� ������ ����� �� {language}�� �����, � �� ������ �������� �����.',
					'/news {tag}�������� ���� ������ ������� �����, ��� �� ����� ������� ������...',
					'/news {tag}������ ���������, ������� ������� ��������� � �������� ����. ������ �� {scores} ������.',
					'/news {tag}���� �� ������� ���������� {prize} �������� ����� {server}.',
					'/news {tag}������ ���������, �� ���������� �������.',
					'/news {tag}���������, ��� ������ ��������� ����� � ����������...',
					'/news {tag}���������� ���� ��������, ���������� �������� � ��������� � ��Ȼ,',
					'/news {tag}�������, ��������� ������������ �. {city} � ����������� ���� �����.',
					'/news {tag}�� ��� �, ������� ��������!'
				}, {'��������� �����',
					'/news {tag}��������� ����� ����� ...'
				}, {'����!',
					'/news {tag}����! ����! ����!'
				}, {'���. ���������!',
					'/news {tag}���. ���������! �� ��������������, ����� ���������...'
				}, {'������ ���',
					'/news {tag}������ ��� {ID}! � � ���� ��� {scoreID} ���������� �������!'
				}, {'������� ����������',
					'/news {tag}� � ��� ���� ����������!',
					'/news {tag}� ���...',
					'/news {tag}{ID}! ��� ��� ������ �� ������� {scores} ���������� �������!',
					'/news {tag}{ID}, � ��� ����������! ��� �������� {prize}$!',
					'/news {tag}{ID}, � ����� ��� �������� � ���...',
					'/news {tag}� ���������� �. {city} �� ���������� ����� �������.'
				}, {'��������� ����',
					'/news {tag}�� ��� �, ������� ���������!',
					'/news {tag}������ ����� ����������� � ����.',
					'/news {tag}������� �� ������� {language}�� ����, ������ �� ����.',
					'/news {tag}����� ���������� ����� �����������',
					'/news {tag}� ���� ��� {name}, {duty} ������������ �. {city}.',
					'/news {tag}������ ���������� � ����� �������� ��� � ����� �������!',
					'/news {tag}�� ������� � �����!!!',
					'/news {music}',
					'/d [{tagCNN}]-[���] ��������� ��������������� �����, �������, ��� �� ����������, �� �����!'
				}, ['name'] = 'interpreter', ['tag'] = '[�����������]: '
			}
		}
	}
	langArr = {
		['tags'] = {'ru', 'en', 'fr', 'es', 'de', 'it'--[[, 'zh', 'kk']]},
		['ru'] = {
			'������', '�����', '����', '�����', '�������', '��������', '������', '�������', '����', '��������',
			'���', '������', '���������', '�������', '�����', '���', '�������', '����', '�������', '�������'
		},
		['en'] = {
			'Car', 'Book', 'Table', 'Pen', 'Bed', 'T-shirt', 'Globe', 'Picture', 'Chair', 'Plant', 'Meal',
			'Weather', 'Computer', 'Plate', 'Wall', 'Cat', 'Bear', 'Fish', 'Fun', 'Shop'
		},
		['fr'] = {
			'Machine', 'Livre', 'Bureau', 'Poignee', 'Lit', 'T-shirt', 'Globe', 'Peinture', 'Chaise', 'Plante',
			'Repas', 'Temps', 'Ordinateur', 'Assiette', 'Mur', 'Chat', 'Ours', 'Poisson', 'Gaiete', 'Boutique'
		},
		['es'] = {
			'Maquina', 'Libro', 'Mesa', 'Manija', 'Cama', 'Camiseta', 'Globo', 'Pintura', 'Silla', 'Planta',
			'Comida', 'Tiempo', 'Ordenador', 'Plato', 'Pared', 'Gato', 'Oso', 'Pez', 'Alegria', 'Tienda'
		},
		['de'] = {
			'Auto', 'Das Buch', 'Der Tisch', 'Stift', 'Bett', 'T-Shirt', 'Der Globus', 'Das Bild', 'Der Stuhl', 'Die Pflanze',
			'Essen', 'Das Wetter', 'Computer', 'Teller', 'Die Wand', 'Der Kater', 'Der Bar', 'Fisch', 'Spab', 'Geschaft'
		},
		['it'] = {
			'Macchina', 'Libro', 'Tavolo', 'Maniglia', 'Letto', 'Maglia', 'Globo', 'Dipinto', 'Sedia', 'Pianta',
			'Pasto', 'Tempo', 'Computer', 'Scodellino', 'Parete', 'Gatto', 'Orso', 'Pesce', 'Allegria', 'Negozio'
		}--[[,
		['zh'] = {
			'??', '?', '?', '???', '?', 'T??', '??', '??', '??', '??', '??', '????',
			'??', '??', '??', '??', '??', '?', '??', '??'
		},
		['kk'] = {
			'������', 'ʳ���', '?����', '?����', '�?���', '��������', '������', '�����', '������?', '?����',
			'����?', '��� ����', '���������', '����?', '?����?�', '����?', '��', '����?', '�??���', '�?���'
		}]]
	}
	newsAutoBind = {{'..'},
		{'��', 'Twin Turbo'},
		{'���', '�����������'},
		{'��', '�����������'},
		{'��', '�����'},
		{'��', '�����-����� '},
		{'���', '"��������� ���" '},
		{'���', '�� ����� ��������� '},
		{'���', '���� ������'},
		{'����', '�� "����". '},
		{'������', '�� "������". '},
		{'�����', '�� "�����". '},
		{'�����', '�� "�����". '},
		{'����', '�� "����". '},
		{'���', '�. ��������-����. '},
		{'���', '�. ������-������. '},
		{'���', '�. ����-������. '},
		{'���', '�. ���-�������. '},
		{'���', '�. ��������-�����. '},
		{'���', '�. �����-����. '},
		{'���', '�. ����-���. '},
		{'��', '����-���. '},
		{'��', '������� �������.'},
		{'00', '.OOO.OOO$'},
		{'01', '.OOO$/��'},
		{'02', '.OOO$/���'},
		{'���', '��� || ��� -> '},
		{'���', '�/� ������ '},
		{'���', '�/� � ������ '},
		{'��', '���-������'},
		{'��', '���-������'},
		{'��', '���-��������'},
		{'��', '����� �����'},
		{'���:', '������: '},
		{'����', '������: ����������'},
		{'��', '��� � �����.'},
		{'��', '� ������� ������. '}
	}
	newsKeyBind = {
		{{vk.VK_CONTROL, vk.VK_1}, '������: ���������'},
		{{vk.VK_CONTROL, vk.VK_2}, '����: ����������'},
		{{vk.VK_CONTROL, vk.VK_NUMPAD7}, '�. ���-������. '},
		{{vk.VK_CONTROL, vk.VK_NUMPAD8}, '�. ���-������. '},
		{{vk.VK_CONTROL, vk.VK_NUMPAD9}, '�. ���-��������. '},
		{{vk.VK_MENU, vk.VK_1}, '������: '},
		{{vk.VK_MENU, vk.VK_2}, '����: '},
		{{vk.VK_CONTROL, vk.VK_5}, '��� � �������'},
		{{vk.VK_MENU, vk.VK_Q}, '�/� '},
		{{vk.VK_MENU, vk.VK_W}, '�/� '},
		{{vk.VK_MENU, vk.VK_E}, '�/� '},
		{{vk.VK_MENU, vk.VK_R}, '�/� '},
		{{vk.VK_MENU, vk.VK_T}, '�/� '},
		{{vk.VK_MENU, vk.VK_Y}, '�/� '},
		{{vk.VK_MENU, vk.VK_U}, '�/� '},
		{{vk.VK_MENU, vk.VK_I}, '�/� '},
		{{vk.VK_MENU, vk.VK_6}, '$'}
	}
	callbacks = {
		calc = ffi.cast('int (*)(ImGuiInputTextCallbackData* data)', function(data)
			local txtIpt = ffi.string(data.Buf)
			local txtMatch = '[^%d%+%-%^%/%(%)%*%s%.]+'
			if txtIpt:match(txtMatch) then
				local share = false
				if txtIpt:match('[\\|]+') then
					share = txtIpt:find('[\\|]+')
					data:InsertChars(share, '/')
				end
				local intCh = txtIpt:find(txtMatch)
				data:DeleteChars(intCh - 1, string.match(txtIpt:sub(intCh, intCh), '[^%w%p]') and 2 or 1)
				data.CursorPos = intCh - (share and 0 or 1)
			end
			return 0
		end),
		bindtag = ffi.cast('int (*)(ImGuiInputTextCallbackData* data)', function(data)
			local txtIpt = ffi.string(data.Buf)
			local txtMatch = '[%c][%c]'
			if txtIpt:match(txtMatch) then
				local intCh = txtIpt:find(txtMatch)
				if intCh > tmp.callBT or intCh == tmp.callBT then -- enter >; backspace <
					data:InsertChars(intCh + 1, '/news \n')
					data:DeleteChars(intCh, 1)
					data.CursorPos = intCh + 6
				else
					data:DeleteChars(intCh, 1)
				end
			end
			if tmp.callBT ~= data.CursorPos then
				tmp.callBT = data.CursorPos
			end
			return 0
		end)
	}
	hotkey = {
		no_flood = false,
		lastkey = 9999,
		MODULEINFO = {
			version = 2,
			author = 'chapo'
		},
		Text = {
			wait_for_key = '�������...',
			no_key = '���'
		},
		List = {},
		EditKey = nil,
		Edit = {
			backup = {},
			new = {}
		},
		Ret = {name = nil, data = {}},
		LargeKeys = {vk.VK_SHIFT, vk.VK_SPACE, vk.VK_CONTROL, vk.VK_MENU, vk.VK_RETURN}
	}
end