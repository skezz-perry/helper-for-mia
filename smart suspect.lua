-- require
local vkeys = require "vkeys" 
local rkeys = require "rkeys"
local imgui, ffi = require "mimgui", require "ffi"
local mimgui_addons = require "mimgui-addons"
local new, str = imgui.new, ffi.string
local faicons = require "fa-icons"
local font_flag = require("moonloader").font_flag 
local encoding = require "encoding"
local memory = require "memory"
local xconf = require "xconf"
local gauth = require "gauth" 
local https = require "ssl.https"
local wm = require('lib.windows.message') 
local game_weapons = require "lib.game.weapons"
local getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)
lsampev, sampev = pcall(require, "lib.samp.events") 
encoding.default = "CP1251" 
u8 = encoding.UTF8
imgui.HotKey = mimgui_addons.HotKey
-- nrequire 


-- local
local t_smart_suspects = {}
local show_regulatory_legal_act = new.bool(false)
local font_size = new.int(0)
local w, h = getScreenResolution()
local string_found = new.char[256]()
local documents = {}
local global_current_document
-- nlocal


-- main
function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	repeat wait(0) until isSampAvailable()
	
	sampRegisterChatCommand("ss", function(parametrs)
		if string.match(parametrs, "^(%d+) (.+)$") then
			local size, text = string.match(parametrs, "^(%d+) (.+)$")
			string_pairs(text, tonumber(size))
		end
	end)
	
	sampRegisterChatCommand("lk", function(parametrs)
		if tonumber(parametrs) and documents[tonumber(parametrs)] then
			global_current_document = documents[tonumber(parametrs)]
			show_regulatory_legal_act[0] = not show_regulatory_legal_act[0]
		end
	end)
	
	lua_thread.create(th_smart_suspects)
	
	--[[
	local ip = sampGetCurrentServerAddress()
	local url = string.format("https://raw.githubusercontent.com/skezz-perry/helper-for-mia/main/%s.json", ip)
	--]]
	
	--[[
	local ip = sampGetCurrentServerAddress()
	local url = string.format("https://raw.githubusercontent.com/skezz-perry/helper-for-mia/main/%s.json", ip)
	local result = https.request(url)
	if result then 
		documents = decodeJson(result) 
		
		for k, document in ipairs(documents) do 
			for article, value in ipairs(document["content"]) do
				local treenode_article = u8:decode(string.format(u8"Статья %s | %s", article, value["title"]))
				if string.len(treenode_article) > 80 then
					treenode_article = string_pairs(treenode_article, 90)[1] .. " .."
				end
				
				document["content"][article]["treenode_article"] = u8(treenode_article)
				
				for part, lvalue in ipairs(value["content"]) do
					local treenode_part = u8:decode(string.format(u8"Часть %s. %s", part, lvalue["title"]))
					if string.len(treenode_part) > 80 then
						treenode_part = string_pairs(treenode_part, 80)[1] .. " .."
					end
						
					hint_index = string.format("##part-%s-%s", article, part)
					hint_value = table.concat(string_pairs(lvalue["title"], 140), "\n")
						
					document["content"][article]["content"][part]["treenode_part"] = u8(treenode_part)
					document["content"][article]["content"][part]["hint_index"] = hint_index
					document["content"][article]["content"][part]["hint_value"] = hint_value
				end 
			end
		end
	end--]]
	
	
	
	while true do wait(0) end
end
-- nmain
 

-- mimgui
local function loadIconicFont(fontSize) 
	-- Load iconic font in merge mode
	local config = imgui.ImFontConfig()
	config.MergeMode = true
	config.PixelSnapH = true
	local iconRanges = new.ImWchar[3](faicons.min_range, faicons.max_range, 0)
	imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85(), fontSize, config, iconRanges)
end
 
imgui.OnInitialize(function() 
	local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
	
	imgui.GetIO().Fonts:Clear()
	imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. "\\tahomabd.ttf", 13, nil, glyph_ranges)
	font_size[0] = imgui.GetIO().Fonts.ConfigData.Data[0].SizePixels
	loadIconicFont(font_size[0])
	apply_custom_style()
	
	button_punishment = { [0] = faicons["ICON_TIMES_CIRCLE"], [1] = faicons["ICON_TICKET"], [2] = faicons["ICON_ID_CARD"], [3] = faicons["ICON_EMPIRE"] }
end)

imgui.OnFrame(function() return show_regulatory_legal_act[0] end,
function()
	local document = global_current_document
	imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(imgui.ImVec2(570, 600))
	imgui.Begin(document["regulatory_legal_act"], show_regulatory_legal_act, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
		imgui.PushItemWidth(545)
		if imgui.InputTextWithHint("##regulatory_legal_act_i", u8"Введите часть содержания статьи", string_found, 50) then
			local pattern = string.nlower(u8:decode(str(string_found)))
			for article, value in ipairs(document["content"]) do
				document["content"][article]["visible"] = true
				
				local article_pattern = string.nlower(u8:decode(value["title"]))
				if string.match(article_pattern, pattern) then document["content"][article]["visible"] = false end
				
				local part_found = 0
				for part, pvalue in ipairs(value["content"]) do
					document["content"][article]["content"][part]["visible"] = true
					
					local part_pattern = string.nlower(u8:decode(pvalue["title"]))
					if string.match(part_pattern, pattern) then
						part_found = part_found + 1
						document["content"][article]["visible"] = false 
						document["content"][article]["content"][part]["visible"] = false
					end
				end
				
				if not document["content"][article]["visible"] and part_found == 0 then
					for part, pvalue in ipairs(value["content"]) do
						document["content"][article]["content"][part]["visible"] = false
					end
				end
			end
		end
	
		for article, value in ipairs(document["content"]) do
			if not value["visible"] then
				if imgui.TreeNodeStr(value["treenode_article"]) then
					for part, lvalue in ipairs(value["content"]) do
						if not lvalue["visible"] then
							if imgui.Button(button_punishment[lvalue["type_punishment"]]) then
								--
							end imgui.SameLine()
							
							imgui.CustomButton(lvalue["treenode_part"], imgui.ImVec4(0.0, 0.0, 0.0, 0.0))
							imgui.Hint(lvalue["hint_index"], lvalue["hint_value"])
						end
					end
					imgui.TreePop()
				end
			end
		end
		
		-- for k, v in pairs(faicons) do imgui.Text(string.format("%s %s", k, v)) end
	imgui.End()
end)
-- nmimgui


-- thread
function th_smart_suspects()
	local font = renderCreateFont("tahoma", 8, font_flag.BOLD + font_flag.SHADOW)
	local color = "{2ECC71}"
	local ss_x, ss_y = 50, 400
	local cursor_status = false
	
	local crimes_configuration = {
		["attack_officer"] = { ["stars"] = 5, ["reason"] = "3.1 УК" },
		["attack_civil"] = { ["stars"] = 5, ["reason"] = "3.1 УК" },
		["insubordination"] = { ["stars"] = 4, ["reason"] = "31.2 УК" },
		["escape"] = { ["stars"] = 4, ["reason"] = "31.3 УК" },
		["non_payment"] = { ["stars"] = 3, ["reason"] = "25.1 УК" }
	}

	local possible_crimes = {
		{ ["index"] = "attack_officer",  ["clock"] = 180, ["significance"] = 5, ["description"] = "Нападение на офицера" },
		{ ["index"] = "attack_civil",    ["clock"] = 180, ["significance"] = 4, ["description"] = "Нападение на гражданского" },
		{ ["index"] = "insubordination", ["clock"] = 120, ["significance"] = 3, ["description"] = "Неповиновение законным требованиям" },
		{ ["index"] = "escape",          ["clock"] = 120, ["significance"] = 3, ["description"] = "Избегание задержания, побег" },
		{ ["index"] = "non_payment",     ["clock"] = 120, ["significance"] = 2, ["description"] = "Отказ от уплаты штрафа" }
	}

	function preliminary_check_suspect(player_id, crimes, ignore_visual_contact)
		if not possible_crimes[crimes] then return false, 0 end -- проверка возможности добавления в список
		if not isPlayerConnected(player_id) then return false, 1 end -- проверка подключён ли игрок
		local getted, player_handle = sampGetCharHandleBySampPlayerId(player_id)
		local visual_contact
		
		if not ignore_visual_contact then
			if not getted then return false, 2 end -- проверяем существует ли игрок в зоне стрима
			
			local user_x, user_y, user_z = getActiveCameraCoordinates()
			local player_x, player_y, player_z = getCharCoordinates(player_handle)
			local player_distance = getDistanceBetweenCoords3d(user_x, user_y, user_z, player_x, player_y, player_z)
			visual_contact = isCharOnScreen(player_handle) and not processLineOfSight(user_x, user_y, user_z, player_x, player_y, player_z, true, false, false, true, false, false, true, false)
			
			if player_distance > 40 and not visual_contact then return false, 3 end
		end
		
		local player_nickname = sampGetPlayerName(player_id)
		local player_found = false
		
		local stars = crimes_configuration[possible_crimes[crimes]["index"]]["stars"]
		local reason = crimes_configuration[possible_crimes[crimes]["index"]]["reason"]
		
		if #t_smart_suspects > 0 then -- пытаемся найти игрока в списках
			for index, value in ipairs(t_smart_suspects) do
				if value["suspect"] and value["suspect"]["tnickname"] == player_nickname then
					for key, violations in ipairs(value["alleged_violations"]) do
						if violations["stars"] == stars and violations["reason"] == reason then
							return false, 4
						end
					end player_found = index
				end
			end
		end
		
		local violations_code = string.format("Статья %s%s{ffffff}, уровень розыска %s%s", color, reason, color, stars)
		
		local fix_description = renderGetFontDrawTextLength(font, possible_crimes[crimes]["description"])
		local fix_criminal = renderGetFontDrawTextLength(font, violations_code)
		
		local violations = {
			["code"]         = violations_code,
			["crimes"]       = crimes,
			["description"]  = possible_crimes[crimes]["description"],
			["significance"] = possible_crimes[crimes]["significance"],
			["stars"]        = stars,
			["reason"]       = reason,
			["fix"]          = ((fix_description > fix_criminal) and fix_description or fix_criminal) + 6,
			["clock"]        = os.clock()
		}
		
		if visual_contact or ignore_visual_contact then
			if player_found then
				local space = t_smart_suspects[player_found]
				table.remove(t_smart_suspects, player_found)
				table.insert(t_smart_suspects, 1, space)
				table.insert(t_smart_suspects[1]["alleged_violations"], violations)
				table.sort(t_smart_suspects[1]["alleged_violations"], function(a, b) return (a["significance"] > b["significance"]) end)
			else
				table.insert(t_smart_suspects, 1, {
					["suspect"] = {
						["nickname"]       = string.format("%s #%s", player_nickname, player_id),
						["tnickname"]      = player_nickname,
						["id"]             = player_id,
						["visual_contact"] = visual_contact,
						["color"]          = "0xFF" .. bit.tohex(sampGetPlayerColor(player_id), 6)
					},
					["alleged_violations"] = { violations }
				})
			end
		else
			table.insert(t_smart_suspects, 1, {
				["suspect"] = {
					["nickname"]       = string.format("Неизвестный #%d", os.clock()),
					["tnickname"]      = player_nickname,
					["id"]             = player_id,
					["visual_contact"] = visual_contact,
					["color"]          = "0xFF" .. bit.tohex(sampGetPlayerColor(player_id), 6)
				},
				["alleged_violations"] = { violations }
			})
		end
		
		return true, 1
	end
	
	while true do wait(0)
		if #t_smart_suspects > 0 then
			local x, y = ss_x, ss_y
			local mx, my = getCursorPos()
			
			if cursor_status then
				if not isKeyDown(VK_B) then sampSetCursorMode(0) cursor_status = false end
			else
				if isKeyDown(VK_B) then sampSetCursorMode(3) cursor_status = true end
			end
			
			for index, value in ipairs(t_smart_suspects) do
				if isPlayerConnected(value["suspect"]["id"]) then
					for key, violation in ipairs(value["alleged_violations"]) do
						if os.clock() - violation["clock"] < possible_crimes[violation["crimes"]]["clock"] then
							local hovered = cursor_status and ((mx >= x and mx <= x + violation["fix"]) and (my >= y and my <= y + 40)) or false
						
							renderDrawBox(x, y, violation["fix"], 40, hovered and 0xAC212121 or 0xF0212121)
							renderDrawBox(x - 5, y + 2, 3, 36, value["suspect"]["visual_contact"] and value["suspect"]["color"] or 0xFFFFFFFF)
							renderFontDrawText(font, value["suspect"]["nickname"], x + 3, y + 2, 0xFFFFFFFF)
							renderFontDrawText(font, violation["code"], x + 3, y + 14, 0xFFFFFFFF)
							renderFontDrawText(font, violation["description"], x + 3, y + 26, 0xFFFFFFFF)
							y = y + 42
							
							if not value["suspect"]["visual_contact"] then
								local result, player_handle = sampGetCharHandleBySampPlayerId(value["suspect"]["id"])
								if result then
									local user_x, user_y, user_z = getActiveCameraCoordinates()
									local player_x, player_y, player_z = getCharCoordinates(player_handle)
									value["suspect"]["visual_contact"] = isCharOnScreen(player_handle) and not processLineOfSight(user_x, user_y, user_z, player_x, player_y, player_z, true, false, false, true, false, false, true, false)
									if value["suspect"]["visual_contact"] then
										value["suspect"]["nickname"] = string.format("%s #%s", value["suspect"]["tnickname"], value["suspect"]["id"])
									end
								else
									chat(string.format("Подозреваемый %s был исключён из быстрого розыска. Причина: скрылся из зоны видимости.", value["suspect"]["nickname"]))
									table.remove(t_smart_suspects, index)
								end
							end
							
							if hovered then
								if wasKeyPressed(vkeys["VK_LBUTTON"]) then
									--
								elseif wasKeyPressed(vkeys["VK_RBUTTON"]) then
									chat(string.format("Подозреваемый %s был исключён из быстрого розыска.", value["suspect"]["nickname"]))
									table.remove(t_smart_suspects[index]["alleged_violations"], key)
									if #t_smart_suspects[index]["alleged_violations"] == 0 then table.remove(t_smart_suspects, index) end
								end
							end
						else
							chat(string.format("Подозреваемый %s был исключён из быстрого розыска. Причина: прошло допустимое время (%s).", value["suspect"]["nickname"], possible_crimes[violation["crimes"]]["clock"]))
							table.remove(t_smart_suspects[index]["alleged_violations"], key)
							if #t_smart_suspects[index]["alleged_violations"] == 0 then table.remove(t_smart_suspects, index) end
						end
					end 
				else
					chat(string.format("Подозреваемый %s был исключён из быстрого розыска. Причина: выход из игры.", value["suspect"]["nickname"]))
					table.remove(t_smart_suspects, index)
				end
			end
		else
			if cursor_status then sampSetCursorMode(0) cursor_status = false end
		end
	end
end
-- ntread


-- function
function chat(...)
	local output = ""
	for k, v in ipairs({...}) do output = string.format("%s %s", output, tostring(v)) end
	sampAddChatMessage(output, -1)
end

function isPlayerConnected(id)
	local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
	return result and (sampIsPlayerConnected(id) or tonumber(id) == tonumber(player_id))
end

function sampGetDistanceToPlayer(id)
	local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
	if result and player_id == tonumber(id) then return 1 end
	if isPlayerConnected(id) then
		local getted, ped = sampGetCharHandleBySampPlayerId(id)
		if getted then
			local x1, y1, z1 = getCharCoordinates(playerPed)
			local x2, y2, z2 = getCharCoordinates(ped)
			return getDistanceBetweenCoords3d(x1, y1, z1, x2, y2, z2)
		end
	end return 9999
end

function getDistanceToPlayer(player_handle)
	if doesCharExist(player_handle) then
		local x1, y1, z1 = getCharCoordinates(playerPed)
		local x2, y2, z2 = getCharCoordinates(player_handle)
		return getDistanceBetweenCoords3d(x1, y1, z1, x2, y2, z2)
	end return 9999
end

function sampGetPlayerName(id)
	return isPlayerConnected(id) and sampGetPlayerNickname(id)
end

function sampIsPoliceOfficerById(player_id)
	local result, player_handle = sampGetCharHandleBySampPlayerId(player_id)
	local result, player_id = sampGetPlayerIdByCharHandle(player_handle)
	if result then
		local player_color = sampGetPlayerColor(player_id)
		if player_color == 4278190335 then
			return true
		elseif player_color == 2236962 then
			local skin = "-265-266-267-280-281-282-283-284-285-286-288-300-301-302-303-304-305-306-307-310-311-"
			return string.find(skin, "%-" .. getCharModel(player_handle) .. "%-")
		else
			if sampGetPlayerArmor(player_id) > 0 then
				local is = {[4278220149] = true, [4288230246] = true, [4290445312] = true, [4291624704] = true, [4288243251] = true}
				if not is[player_color] then
					return true
				end
			end
		end
	end
end

function string_pairs(text, size)
	local words = {}
	for word in string.gmatch(text, "[^%s]+") do table.insert(words, word) end
	
	local result = { "" }
	for index, value in ipairs(words) do
		local line = result[#result] .. value
		if string.len(line) < size then
			result[#result] = line .. " "
		else
			table.insert(result, value .. " ")
		end
	end
	
	--[[for index, value in ipairs(result) do
		if string.len(value) > size then
			
		end
	end--]]
	
	return result
end

local lower, sub, char, upper = string.lower, string.sub, string.char, string.upper
local concat = table.concat

-- initialization table
local lu_rus, ul_rus = {}, {}
for i = 192, 223 do
    local A, a = char(i), char(i + 32)
    ul_rus[A] = a
    lu_rus[a] = A
end
local E, e = char(168), char(184)
ul_rus[E] = e
lu_rus[e] = E

function string.nlower(s)
    s = lower(s)
    local len, res = #s, {}
    for i = 1, len do
        local ch = sub(s, i, i)
        res[i] = ul_rus[ch] or ch
    end
    return concat(res)
end

function string.nupper(s)
    s = upper(s)
    local len, res = #s, {}
    for i = 1, len do
        local ch = sub(s, i, i)
        res[i] = lu_rus[ch] or ch
    end
    return concat(res)
end

function imgui.CustomButton(str_id, color, size)
    local clr = imgui.Col
    imgui.PushStyleColor(clr.Button, color)
    if not size then size = imgui.ImVec2(0, 0) end
    local result = imgui.Button(str_id, size)
    imgui.PopStyleColor(1)
    return result
end

function imgui.Hint(str_id, hint_text, color, no_center)
    color = color or imgui.GetStyle().Colors[imgui.Col.PopupBg]
    local p_orig = imgui.GetCursorPos()
    local hovered = imgui.IsItemHovered()
    imgui.SameLine(nil, 0)

    local animTime = 0.2
    local show = true

    if not POOL_HINTS then POOL_HINTS = {} end
    if not POOL_HINTS[str_id] then
        POOL_HINTS[str_id] = {
            status = false,
            timer = 0
        }
    end

    if hovered then
        for k, v in pairs(POOL_HINTS) do
            if k ~= str_id and os.clock() - v.timer <= animTime  then
                show = false
            end
        end
    end

    if show and POOL_HINTS[str_id].status ~= hovered then
        POOL_HINTS[str_id].status = hovered
        POOL_HINTS[str_id].timer = os.clock()
    end

    local getContrastColor = function(col)
        local luminance = 1 - (0.299 * col.x + 0.587 * col.y + 0.114 * col.z)
        return luminance < 0.5 and imgui.ImVec4(0, 0, 0, 1) or imgui.ImVec4(1, 1, 1, 1)
    end

    local rend_window = function(alpha)
        local size = imgui.GetItemRectSize()
        local scrPos = imgui.GetCursorScreenPos()
        local DL = imgui.GetWindowDrawList()
        local center = imgui.ImVec2( scrPos.x - (size.x / 2), scrPos.y + (size.y / 2) - (alpha * 4) + 10 )
        local a = imgui.ImVec2( center.x - 7, center.y - size.y - 3 )
        local b = imgui.ImVec2( center.x + 7, center.y - size.y - 3)
        local c = imgui.ImVec2( center.x, center.y - size.y + 3 )
        local col = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(color.x, color.y, color.z, alpha))

        DL:AddTriangleFilled(a, b, c, col)
        imgui.SetNextWindowPos(imgui.ImVec2(center.x, center.y - size.y - 3), imgui.Cond.Always, imgui.ImVec2(0.5, 1.0))
        imgui.PushStyleColor(imgui.Col.PopupBg, color)
        imgui.PushStyleColor(imgui.Col.Border, color)
        imgui.PushStyleColor(imgui.Col.Text, getContrastColor(color))
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 6)
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha)

        local max_width = function(text)
            local result = 0
            for line in text:gmatch('[^\n]+') do
                local len = imgui.CalcTextSize(line).x
                if len > result then
                    result = len
                end
            end
            return result
        end

        local hint_width = max_width(hint_text) + (imgui.GetStyle().WindowPadding.x * 2)
        imgui.SetNextWindowSize(imgui.ImVec2(hint_width, -1), imgui.Cond.Always)
        imgui.Begin('##' .. str_id, _, imgui.WindowFlags.Tooltip + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoTitleBar)
            for line in hint_text:gmatch('[^\n]+') do
                if no_center then
                    imgui.Text(line)
                else
                    imgui.SetCursorPosX((hint_width - imgui.CalcTextSize(line).x) / 2)
                    imgui.Text(line)
                end
            end
        imgui.End()

        imgui.PopStyleVar(3)
        imgui.PopStyleColor(3)
    end

    if show then
        local between = os.clock() - POOL_HINTS[str_id].timer
        if between <= animTime then
            local s = function(f)
                return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
            end
            local alpha = hovered and s(between / animTime) or s(1.00 - between / animTime)
            rend_window(alpha)
        elseif hovered then
            rend_window(1.00)
        end
    end

    imgui.SetCursorPos(p_orig)
end

function apply_custom_style()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
	local ImVec2 = imgui.ImVec2
     
	style.WindowBorderSize = 0.0
	
	style.WindowRounding         = 10.0
	style.WindowTitleAlign       = ImVec2(0.5, 0.5)
	style.FrameRounding          = 5.0
	style.ItemSpacing            = ImVec2(10, 5)
	style.ScrollbarSize          = 9
	style.ScrollbarRounding      = 0
	style.GrabMinSize            = 9.6
	style.GrabRounding           = 1.0
	style.WindowPadding          = ImVec2(10, 10)
	style.FramePadding           = ImVec2(5, 4)
	style.DisplayWindowPadding   = ImVec2(27, 27)
	style.DisplaySafeAreaPadding = ImVec2(5, 5)
	style.ButtonTextAlign        = ImVec2(0.5, 0.5)
	style.IndentSpacing          = 12.0
	style.Alpha                  = 1.0
	
	if true then
		colors[clr.Button]               = ImVec4(0.13, 0.75, 0.55, 0.40)
		colors[clr.ButtonHovered]        = ImVec4(0.13, 0.75, 0.75, 0.60)
		colors[clr.ButtonActive]         = ImVec4(0.13, 0.75, 1.00, 0.80)
		colors[clr.Header]               = ImVec4(0.13, 0.75, 0.55, 0.40)
		colors[clr.HeaderHovered]        = ImVec4(0.13, 0.75, 0.75, 0.60)
		colors[clr.HeaderActive]         = ImVec4(0.13, 0.75, 1.00, 0.80)
		colors[clr.Separator]            = ImVec4(0.13, 0.75, 0.55, 0.40)
		colors[clr.SeparatorHovered]     = ImVec4(0.13, 0.75, 0.75, 0.60)
		colors[clr.SeparatorActive]      = ImVec4(0.13, 0.75, 1.00, 0.80)
		colors[clr.SliderGrab]           = ImVec4(0.13, 0.75, 0.75, 0.80)
		colors[clr.SliderGrabActive]     = ImVec4(0.13, 0.75, 1.00, 0.80)
	end
	
	colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled]         = ImVec4(0.50, 0.50, 0.50, 1.00)
	colors[clr.WindowBg]             = ImVec4(0.06, 0.06, 0.06, 0.94)
	colors[clr.PopupBg]              = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.Border]               = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.FrameBg]              = ImVec4(0.44, 0.44, 0.44, 0.60)
	colors[clr.FrameBgHovered]       = ImVec4(0.57, 0.57, 0.57, 0.70)
	colors[clr.FrameBgActive]        = ImVec4(0.76, 0.76, 0.76, 0.80)
	colors[clr.TitleBg]              = ImVec4(0.04, 0.04, 0.04, 1.00)
	colors[clr.TitleBgActive]        = ImVec4(0.16, 0.16, 0.16, 1.00)
	colors[clr.TitleBgCollapsed]     = ImVec4(0.00, 0.00, 0.00, 0.60)
	colors[clr.CheckMark]            = ImVec4(0.13, 0.75, 0.55, 0.80)
	colors[clr.MenuBarBg]            = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab]        = ImVec4(0.31, 0.31, 0.31, 1.00)
	colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.41, 0.41, 1.00)
	colors[clr.ScrollbarGrabActive]  = ImVec4(0.51, 0.51, 0.51, 1.00)
	colors[clr.ResizeGrip]           = ImVec4(0.13, 0.75, 0.55, 0.40)
	colors[clr.ResizeGripHovered]    = ImVec4(0.13, 0.75, 0.75, 0.60)
	colors[clr.ResizeGripActive]     = ImVec4(0.13, 0.75, 1.00, 0.80)
	colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered]     = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
	colors[clr.TextSelectedBg]       = ImVec4(0.26, 0.59, 0.98, 0.35)
end

function httpRequest(request, body, handler) -- copas.http
    -- start polling task
    if not copas.running then
        copas.running = true
        lua_thread.create(function()
            wait(0)
            while not copas.finished() do
                local ok, err = copas.step(0)
                if ok == nil then error(err) end
                wait(0)
            end
            copas.running = false
        end)
    end
    -- do request
    if handler then
        return copas.addthread(function(r, b, h)
            copas.setErrorHandler(function(err) h(nil, err) end)
            h(http.request(r, b))
        end, request, body, handler)
    else
        local results
        local thread = copas.addthread(function(r, b)
            copas.setErrorHandler(function(err) results = {nil, err} end)
            results = table.pack(http.request(r, b))
        end, request, body)
        while coroutine.status(thread) ~= 'dead' do wait(0) end
        return table.unpack(results)
    end
end
-- nfunction


-- event
function sampev.onBulletSync(suspect_id, data)
	if sampGetDistanceToPlayer(suspect_id) < 40 then
		local color = sampGetPlayerColor(suspect_id)
		if color ~= 2236962 and color ~= 4278190335 then
			if data["targetType"] == 1 then -- вооружённое нападение
				if sampIsPoliceOfficerById(data["targetId"]) then 
					preliminary_check_suspect(suspect_id, 1)
				else
					preliminary_check_suspect(suspect_id, 2)
				end
			elseif data["targetType"] == 2 then
				local result, vehicle_handle = sampGetCarHandleBySampVehicleId(data["targetId"])
				if result then
					if isCharSittingInAnyCar(playerPed) and storeCarCharIsInNoSave(playerPed) == vehicle_handle then
						preliminary_check_suspect(suspect_id, 1)
					else
						local is_vehicle_have_officer = false
						
						local result, passenger_number = getNumberOfPassengers(vehicle_handle)
						if result and passenger_number > 0 then
							for i = 0, getMaximumNumberOfPassengers(vehicle_handle) do
								if i == 3 then 
									passenger = getDriverOfCar(vehicle_handle)
								else
									if not isCarPassengerSeatFree(vehicle_handle, i) then
										passenger = getCharInCarPassengerSeat(vehicle_handle, i)
									end
								end
									
								if sampIsPoliceOfficer(passenger) then is_vehicle_have_officer = true end
							end
						end
						
						if is_vehicle_have_officer then
							preliminary_check_suspect(suspect_id, 1)
						else
							preliminary_check_suspect(suspect_id, 2)
						end
					end
				end
			end
		end
	end
end
-- !event


-- http
 
-- nhttp