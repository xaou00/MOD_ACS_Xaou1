-- Xaou 009 Warp System for ACS Mobile / XLua.
-- Uses the game's high-level Place route so FightMap and RPGFightMap are selected by the game.
-- Reference: Amazing_Cultivation_Simulator_Modding_Data.md (2026-09-15).

if Xaou_WarpSystem and Xaou_WarpSystem._Loaded then return end
Xaou_WarpSystem = Xaou_WarpSystem or {}
Xaou_WarpSystem._Loaded = true

local XW_View = nil
local XW_Page = 1
local XW_PageSize = 6
local XW_Visible = {}
local XW_Target = nil
local XW_Category = "all"

-- Fallback Place IDs from the current game data. At runtime GetSchoolPlace() is preferred,
-- so a compatible game build can provide its own authoritative mapping.
local XW_Schools = {
    {school=1,  place="Place_DanXia"},
    {school=2,  place="Place_KunLun"},
    {school=3,  place="Place_TianJi"},
    {school=4,  place="Place_JiuHua"},
    {school=5,  place="Place_LongHu"},
    {school=6,  place="Place_Shu"},
    {school=7,  place="Place_WuLian"},
    {school=8,  place="Place_BaiMan"},
    {school=9,  place="Place_XianKong"},
    {school=10, place="Place_Hei"},
    {school=11, place="Place_HeHuan"},
    {school=12, place="Place_Desert1"},
    {school=13, place="Place_WuDang_JinDing"},
}

-- Place IDs taken from Settings/World/Places in the 2026-09-15 game-data index.
-- Base/System placeholders are deliberately excluded. Runtime PlaceDef checks decide
-- which candidates are actually safe to show on the running game build.
local XW_PlaceCandidates = {
    -- Level 1: cities and large world regions that are not already sect destinations.
    {place="Place_CentralPlains", category="region"},
    {place="Place_DaLiangCity", category="region"},
    {place="Place_Desert", category="region"},
    {place="Place_FertileField", category="region"},
    {place="Place_HeYinCity", category="region"},
    {place="Place_HuCity", category="region"},
    {place="Place_PanSheCity", category="region"},
    {place="Place_ShanCity", category="region"},
    {place="Place_Snowfield", category="region"},
    {place="Place_SouthForest", category="region"},
    {place="Place_SouthMount", category="region"},

    -- Level 2: sub-locations and exploration points.
    {place="Place_BaiMan1", category="site"}, {place="Place_BaiMan2", category="site"}, {place="Place_BaiMan3", category="site"},
    {place="Place_BirthPlace11", category="site"}, {place="Place_BirthPlace12", category="site"}, {place="Place_BirthPlace13", category="site"},
    {place="Place_BirthPlace14", category="site"}, {place="Place_BirthPlace15", category="site"}, {place="Place_BirthPlace16", category="site"},
    {place="Place_CentralPlains1", category="site"}, {place="Place_CentralPlains2", category="site"}, {place="Place_CentralPlains3", category="site"},
    {place="Place_CentralPlains4", category="site"}, {place="Place_CentralPlains5", category="site"},
    {place="Place_DanXia1", category="site"}, {place="Place_DanXia2", category="site"}, {place="Place_DanXia3", category="site"},
    {place="Place_Desert1", category="site"}, {place="Place_Desert2", category="site"}, {place="Place_Desert3", category="site"}, {place="Place_Desert4", category="site"},
    {place="Place_FertileField1", category="site"}, {place="Place_FertileField2", category="site"}, {place="Place_FertileField3", category="site"},
    {place="Place_FertileField4", category="site"}, {place="Place_FertileField5", category="site"},
    {place="Place_HeHuan1", category="site"}, {place="Place_HeHuan2", category="site"}, {place="Place_Hei4", category="site"},
    {place="Place_JiuHua1", category="site"}, {place="Place_JiuHua2", category="site"}, {place="Place_JiuHua3", category="site"},
    {place="Place_KunLun1", category="site"}, {place="Place_KunLun2", category="site"}, {place="Place_KunLun2_1", category="site"},
    {place="Place_LongHu1", category="site"}, {place="Place_LongHu2", category="site"},
    {place="Place_Shu1", category="site"}, {place="Place_Shu2", category="site"}, {place="Place_Shu3", category="site"}, {place="Place_Shu4", category="site"}, {place="Place_Shu5", category="site"},
    {place="Place_Snowfield1", category="site"}, {place="Place_Snowfield2", category="site"}, {place="Place_Snowfield3", category="site"},
    {place="Place_SouthForest1", category="site"}, {place="Place_SouthForest2", category="site"}, {place="Place_SouthForest3", category="site"},
    {place="Place_TianJi1", category="site"}, {place="Place_TianJi2", category="site"},
    {place="Place_WuLian1", category="site"}, {place="Place_WuLian2", category="site"}, {place="Place_XianKong1", category="site"},

    -- Level 3 / DLC / WuDang secondary locations.
    {place="Place_ChiLianYuan", category="special"},
    {place="Place_GuZhanChang", category="special"},
    {place="Place_LongTai", category="special"},
    {place="Place_QingLianShan", category="special"},
    {place="Place_XuanKongDong", category="special"},
    {place="Place_YiJieLieFeng", category="special"},
    {place="Place_BigBamboo", category="special"},
    {place="Place_WuDang_NanYanGong", category="special"},
    {place="Place_WuDang_Taizipo", category="special"},
    {place="Place_WuDang_ZiXiaoGong", category="special"},
}

local XW_Categories = {
    {button="menuQuick", id="all", th="ทั้งหมด", en="All"},
    {button="menuNpc", id="sect", th="สำนัก", en="Sects"},
    {button="menuBook", id="region", th="เมือง/ภูมิภาค", en="Cities / Regions"},
    {button="menuWorld", id="site", th="จุดย่อย", en="Sub-locations"},
    {button="menuDeveloper", id="special", th="พิเศษ/DLC", en="Special / DLC"},
}

local function xw_en()
    if Xaou_IsEnglish then return Xaou_IsEnglish() end
    return Xaou_ModCenter_Language == "en"
end

local function xw_t(thai, english)
    return xw_en() and (english or thai) or thai
end

local function xw_show(text)
    text = tostring(text or "")
    local shown = false
    pcall(function()
        if CS and CS.Wnd_Message then
            CS.Wnd_Message.Show(text, 1, nil, true, "Xaou Warp", 0, 0, "")
            shown = true
        end
    end)
    if not shown then pcall(function() world:ShowMsgBox(text) end) end
end

local function xw_places_mgr()
    local mgr = nil
    -- Prefer the explicit singleton because it is the most consistent route on Android XLua.
    pcall(function() mgr = CS.XiaWorld.PlacesMgr.Instance end)
    if mgr ~= nil then return mgr end
    pcall(function() mgr = PlacesMgr end)
    return mgr
end

local function xw_fight_mgr()
    local mgr = nil
    pcall(function() mgr = CS.XiaWorld.FightMapMgr.Instance end)
    if mgr == nil then pcall(function() mgr = FightMapMgr end) end
    return mgr
end

local function xw_place_def(mgr, placeName)
    if mgr == nil or placeName == nil or tostring(placeName) == "" then return nil end
    local def = nil
    pcall(function() def = mgr:GetPlaceDef(tostring(placeName)) end)
    return def
end

local function xw_place_name(def, placeName)
    local name = nil
    if def ~= nil then
        pcall(function() name = tostring(def.DisplayName) end)
        if name == nil or name == "" or name == "nil" then pcall(function() name = tostring(def.ThingName) end) end
        if name == nil or name == "" or name == "nil" then pcall(function() name = tostring(def.Name) end) end
    end
    if name == nil or name == "" or name == "nil" then name = tostring(placeName or "?") end
    return name
end

local function xw_is_locked(mgr, placeName)
    local locked = false
    local readable = false
    if mgr ~= nil then
        pcall(function()
            locked = mgr:IsLocked(tostring(placeName)) == true
            readable = true
        end)
    end
    return readable and locked or false
end

local function xw_school_place(mgr, row)
    local placeName = nil
    if mgr ~= nil then
        pcall(function() placeName = mgr:GetSchoolPlace(row.school) end)
    end
    if placeName == nil or tostring(placeName) == "" or tostring(placeName) == "nil" then
        placeName = row.place
    end
    placeName = tostring(placeName or "")
    if placeName == "" then return nil end
    return placeName
end

local function xw_nonempty(value)
    if value == nil then return false end
    local text = tostring(value)
    return text ~= "" and text ~= "nil" and text ~= "0" and text ~= "None"
end

local function xw_place_has_map_route(def)
    if def == nil then return false end
    local fightMap, rpgFightMap = nil, nil
    local fightReadable, rpgReadable = false, false
    pcall(function() fightMap = def.FightMap; fightReadable = true end)
    pcall(function() rpgFightMap = def.RPGFightMap; rpgReadable = true end)
    if xw_nonempty(fightMap) or xw_nonempty(rpgFightMap) then return true end
    -- Some Android XLua builds do not expose these PlaceDef fields. In that case
    -- keep the candidate and let Change2FightMap be the final authority.
    if not fightReadable and not rpgReadable then return true end
    return false
end

local function xw_category_ok(category, rowCategory)
    category = tostring(category or "all")
    return category == "all" or category == tostring(rowCategory or "")
end

function Xaou_WarpSystem.GetDestinations(category)
    category = tostring(category or "all")
    local mgr = xw_places_mgr()
    local rows, seen = {}, {}
    if mgr == nil then return rows end

    local function add_place(placeName, rowCategory, schoolId, trusted)
        placeName = tostring(placeName or "")
        if placeName == "" or seen[placeName] or not xw_category_ok(category, rowCategory) then return end
        local def = xw_place_def(mgr, placeName)
        if def == nil then return end
        if trusted ~= true and not xw_place_has_map_route(def) then return end
        seen[placeName] = true
        rows[#rows + 1] = {
            school = schoolId,
            category = rowCategory,
            place = placeName,
            name = xw_place_name(def, placeName),
            locked = xw_is_locked(mgr, placeName),
        }
    end

    -- Sect routes were already runtime-tested, so keep them even on XLua builds
    -- where FightMap/RPGFightMap fields are not readable from PlaceDef.
    for _, school in ipairs(XW_Schools) do
        add_place(xw_school_place(mgr, school), "sect", school.school, true)
    end
    for _, row in ipairs(XW_PlaceCandidates) do
        add_place(row.place, row.category, nil, false)
    end
    return rows
end

local function xw_real_npc(npc)
    if npc == nil then return nil end
    if Xaou_GetRealNpcObject then
        local ok, value = pcall(function() return Xaou_GetRealNpcObject(npc) end)
        if ok and value ~= nil then return value end
    end
    return npc
end

local function xw_active_party()
    local source = nil
    pcall(function() source = World.map.Things:GetPlayerActiveNpcs() end)
    if source == nil then pcall(function() source = World.Map.Things:GetPlayerActiveNpcs() end) end
    if source == nil then pcall(function() source = Map.Things:GetPlayerActiveNpcs() end) end
    return source
end

local function xw_count(list)
    if list == nil then return 0 end
    local count = 0
    pcall(function() count = tonumber(list.Count) or 0 end)
    if count == 0 then pcall(function() count = tonumber(list:get_Count()) or 0 end) end
    return count
end

local function xw_item(list, index)
    if list == nil then return nil end
    local value = nil
    pcall(function() value = list:get_Item(index) end)
    if value == nil then pcall(function() value = list[index] end) end
    return value
end

local function xw_pick_target(npc)
    local target = xw_real_npc(npc or XW_Target or Xaou_CurrentNpcTarget)
    if target ~= nil then return target end

    -- Compatibility fallback for callers that do not provide a target.
    -- IMPORTANT: take only the first active NPC; never return the whole active list.
    local active = xw_active_party()
    if xw_count(active) > 0 then return xw_real_npc(xw_item(active, 0)) end
    return nil
end

function Xaou_WarpSystem.WarpToPlace(placeName, npc)
    placeName = tostring(placeName or "")
    if placeName == "" then return false, xw_t("ไม่พบรหัสสถานที่", "Destination ID is missing") end
    if Xaou_WarpSystem._Busy then return false, xw_t("ระบบกำลังเปลี่ยนแผนที่", "A map change is already in progress") end

    local places = xw_places_mgr()
    if places == nil then
        xw_show(xw_t("ไม่พบ PlacesMgr ของเกม", "PlacesMgr is unavailable"))
        return false, "PlacesMgr unavailable"
    end
    local def = xw_place_def(places, placeName)
    if def == nil then
        xw_show(xw_t("ไม่พบสถานที่: ", "Unknown destination: ") .. placeName)
        return false, "PlaceDef not found"
    end

    local target = xw_pick_target(npc)
    if target == nil then
        xw_show(xw_t("ไม่พบ NPC เป้าหมายสำหรับวาร์ป", "No target NPC was found for teleport"))
        return false, "target npc missing"
    end

    local fight = xw_fight_mgr()
    if fight == nil then
        xw_show(xw_t("ไม่พบ FightMapMgr ของเกม", "FightMapMgr is unavailable"))
        return false, "FightMapMgr unavailable"
    end

    Xaou_WarpSystem._Busy = true
    -- Official examples pass a Lua table. Keep the party intentionally to ONE NPC;
    -- GetPlayerActiveNpcs() can contain most/all player-side NPCs on the home map.
    local party = {target}
    local ok, err = pcall(function()
        fight:Change2FightMap(party, placeName)
    end)
    Xaou_WarpSystem._Busy = false

    if not ok then
        local locked = xw_is_locked(places, placeName)
        local hint = locked and xw_t("\nสถานที่นี้ยังล็อกอยู่ ลองใช้ 'จัดการแผนที่ > เปิดแผนที่ทั้งหมด' ก่อน", "\nThis destination is locked. Try Map Management > Unlock All Locations first.") or ""
        xw_show(xw_t("วาร์ปไม่สำเร็จ\n", "Teleport failed\n") .. tostring(err) .. hint)
        return false, tostring(err)
    end
    return true
end

function Xaou_WarpSystem.WarpToSchool(schoolId, npc)
    schoolId = tonumber(schoolId)
    if schoolId == nil then return false, "school id invalid" end
    local mgr = xw_places_mgr()
    if mgr == nil then return false, "PlacesMgr unavailable" end
    local placeName = nil
    pcall(function() placeName = mgr:GetSchoolPlace(schoolId) end)
    if placeName == nil or tostring(placeName) == "" or tostring(placeName) == "nil" then
        for _, row in ipairs(XW_Schools) do
            if row.school == schoolId then placeName = row.place; break end
        end
    end
    if placeName == nil then
        xw_show(xw_t("ไม่พบแผนที่ของสำนัก ID ", "No map found for sect ID ") .. tostring(schoolId))
        return false
    end
    return Xaou_WarpSystem.WarpToPlace(tostring(placeName), npc)
end

function Xaou_WarpSystem.WarpSelectedNpcHome(npc)
    local real = npc
    if Xaou_GetRealNpcObject then
        local ok, value = pcall(function() return Xaou_GetRealNpcObject(npc) end)
        if ok and value ~= nil then real = value end
    end
    local schoolId = nil
    if real ~= nil then pcall(function() schoolId = tonumber(real.SchoolID) end) end
    if schoolId == nil or schoolId <= 0 then
        xw_show(xw_t("NPC ที่เลือกไม่มีสำนักที่ใช้เป็นปลายทางได้", "The selected NPC has no usable sect destination"))
        return false
    end
    -- Compatibility entry point kept for older menus. Only the selected NPC is sent.
    return Xaou_WarpSystem.WarpToSchool(schoolId, real)
end

function Xaou_WarpSystem.BackToSchool()
    if Xaou_WarpSystem._Busy then return false end
    Xaou_WarpSystem._Busy = true

    -- RPG World has its own leave path.
    local currentWorld = nil
    pcall(function()
        if GMod and GMod.RPG and GMod.RPG.GetCurWorld then currentWorld = GMod.RPG:GetCurWorld() end
    end)
    if currentWorld ~= nil then
        local ok, err = pcall(function() currentWorld:Leave() end)
        Xaou_WarpSystem._Busy = false
        if ok then return true end
        xw_show(xw_t("ออกจาก RPG World ไม่สำเร็จ\n", "Failed to leave RPG World\n") .. tostring(err))
        return false
    end

    local fight = xw_fight_mgr()
    if fight == nil then
        Xaou_WarpSystem._Busy = false
        xw_show(xw_t("ไม่พบ FightMapMgr ของเกม", "FightMapMgr is unavailable"))
        return false
    end
    local ok, err = pcall(function() fight:Back2School() end)
    Xaou_WarpSystem._Busy = false
    if not ok then
        xw_show(xw_t("กลับสำนักไม่สำเร็จ\n", "Failed to return to the sect\n") .. tostring(err))
        return false
    end
    return true
end

function Xaou_WarpSystem.DebugMapInfo()
    local rows = Xaou_WarpSystem.GetDestinations()
    local lines = {xw_t("สถานที่วาร์ปที่เกมยืนยันได้: ", "Confirmed teleport destinations: ") .. tostring(#rows)}
    for _, row in ipairs(rows) do
        lines[#lines + 1] = tostring(row.school) .. ". " .. tostring(row.name) .. " | " .. tostring(row.place) .. (row.locked and " [LOCKED]" or "")
    end
    xw_show(table.concat(lines, "\n"))
    return rows
end

local function xw_child(view, name)
    local value = nil
    pcall(function() value = view:GetChild(name) end)
    return value
end

local function xw_text(obj, value)
    if obj == nil then return end
    pcall(function() obj.text = tostring(value or "") end)
    pcall(function() obj.title = tostring(value or "") end)
end

local function xw_visible(obj, value)
    if obj == nil then return end
    pcall(function() obj.visible = value == true end)
    pcall(function() obj.touchable = value == true end)
    pcall(function() obj.enabled = value == true end)
end

local function xw_enabled(obj, value)
    if obj == nil then return end
    pcall(function() obj.enabled = value == true end)
    pcall(function() obj.touchable = value == true end)
    pcall(function() obj.alpha = value == true and 1 or 0.45 end)
end

function Xaou_CloseWarpWindow()
    if XW_View ~= nil then
        pcall(function() XW_View:RemoveFromParent() end)
        pcall(function() XW_View:Dispose() end)
        XW_View = nil
    end
end

local function xw_category_title()
    for _, row in ipairs(XW_Categories) do
        if row.id == XW_Category then return xw_t(row.th, row.en) end
    end
    return xw_t("ทั้งหมด", "All")
end

local function xw_refresh(view)
    local rows = Xaou_WarpSystem.GetDestinations(XW_Category)
    local maxPage = math.max(1, math.ceil(#rows / XW_PageSize))
    XW_Page = math.max(1, math.min(XW_Page, maxPage))
    local first = (XW_Page - 1) * XW_PageSize + 1
    XW_Visible = {}

    xw_text(xw_child(view, "title"), xw_t("แผนที่วาร์ป", "Teleport Map"))
    xw_text(xw_child(view, "subtitle"), xw_t("คัดจาก PlaceDef จริงของเกม: สำนัก เมือง จุดย่อย และสถานที่พิเศษ", "Runtime PlaceDef destinations: sects, regions, sub-locations and special places"))
    xw_text(xw_child(view, "sectionTitle"), xw_t("เลือกสถานที่ • ", "Choose Destination • ") .. xw_category_title())
    xw_text(xw_child(view, "description"), xw_t("พบสถานที่ที่เข้าได้ ", "Enterable destinations: ") .. tostring(#rows) .. xw_t(" แห่ง  |  หน้า ", "  |  Page ") .. tostring(XW_Page) .. "/" .. tostring(maxPage))
    local targetName = xw_t("NPC ที่เลือก", "Selected NPC")
    local target = xw_pick_target(XW_Target)
    if target ~= nil and Xaou_SafeNpcName then pcall(function() targetName = Xaou_SafeNpcName(target) end) end
    xw_text(xw_child(view, "npcName"), xw_t("วาร์ป NPC: ", "Teleport NPC: ") .. tostring(targetName))
    xw_text(xw_child(view, "npcStatus"), xw_t("จุดที่ไม่มีฉาก FightMap/RPGFightMap จะถูกซ่อน • [ล็อก] คือยังไม่ปลดล็อก", "Places without a FightMap/RPGFightMap route are hidden • [LOCKED] means not unlocked"))
    xw_text(xw_child(view, "brand"), "Xaou 009 Warp")
    xw_visible(xw_child(view, "npcPortrait"), false)

    for _, menu in ipairs(XW_Categories) do
        local button = xw_child(view, menu.button)
        xw_visible(button, true)
        xw_text(button, (XW_Category == menu.id and "▶ " or "") .. xw_t(menu.th, menu.en))
    end

    for i = 1, XW_PageSize do
        local button = xw_child(view, "feature" .. tostring(i))
        local row = rows[first + i - 1]
        XW_Visible[i] = row
        if row ~= nil then
            local lockText = row.locked and xw_t(" [ล็อก]", " [LOCKED]") or ""
            xw_text(button, tostring(row.name) .. lockText)
            xw_visible(button, true)
        else
            xw_visible(button, false)
        end
    end

    local prev = xw_child(view, "feature7")
    local nextb = xw_child(view, "feature8")
    xw_text(prev, xw_t("◀ ย้อนกลับ", "◀ Previous"))
    xw_text(nextb, xw_t("ถัดไป ▶", "Next ▶"))
    xw_visible(prev, true)
    xw_visible(nextb, true)
    xw_enabled(prev, XW_Page > 1)
    xw_enabled(nextb, XW_Page < maxPage)
    xw_text(xw_child(view, "btnLanguage"), xw_t("กลับ Mod Center", "Back to Mod Center"))
end

local function xw_native_fallback()
    local rows = Xaou_WarpSystem.GetDestinations("all")
    local helper = nil
    pcall(function() helper = CS.WorldLuaHelper() end)
    if helper == nil or helper.ShowSelectBox == nil then
        Xaou_WarpSystem.DebugMapInfo()
        return false
    end
    local choices = {}
    for _, row in ipairs(rows) do
        choices[#choices + 1] = tostring(row.name) .. (row.locked and xw_t(" [ล็อก]", " [LOCKED]") or "")
    end
    if #choices == 0 then
        xw_show(xw_t("ไม่พบ PlaceDef ที่ใช้วาร์ปได้ในเกมเวอร์ชันนี้", "No usable PlaceDef was found in this game build"))
        return false
    end
    helper:ShowSelectBox(xw_t("เลือกสถานที่วาร์ป", "Choose teleport destination"), choices, 1, 1, function(result)
        local index = tonumber(result)
        if index == nil then
            local count = nil
            pcall(function() count = tonumber(result.Count) end)
            if count ~= nil and count > 0 then
                local value = nil
                pcall(function() value = result:get_Item(0) end)
                if value == nil then pcall(function() value = result[0] end) end
                index = tonumber(value)
            end
        end
        if index == nil then return end
        local row = rows[index + 1] or rows[index]
        if row ~= nil then Xaou_WarpSystem.WarpToPlace(row.place, XW_Target) end
    end)
    return true
end

function Xaou_OpenWarpWindow(target)
    Xaou_CloseWarpWindow()
    XW_Target = target or Xaou_CurrentNpcTarget
    XW_Category = "all"
    XW_Page = 1

    local pkg = UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root = (GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if pkg == nil or root == nil then return xw_native_fallback() end
    pcall(function() pkg.AddPackage("UI/XaoCtr") end)

    local view = nil
    local ok = pcall(function() view = pkg.CreateObject("XaoCtr", "XaouModCenterWindow") end)
    if not ok or view == nil then return xw_native_fallback() end

    XW_View = view
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2

    for _, menu in ipairs(XW_Categories) do
        local categoryId = menu.id
        local button = xw_child(view, menu.button)
        if button ~= nil then button.onClick:Add(function()
            XW_Category = categoryId
            XW_Page = 1
            xw_refresh(view)
        end) end
    end

    for i = 1, XW_PageSize do
        local index = i
        local button = xw_child(view, "feature" .. tostring(index))
        if button ~= nil then button.onClick:Add(function()
            local row = XW_Visible[index]
            if row == nil then return end
            local target = XW_Target
            Xaou_CloseWarpWindow()
            Xaou_WarpSystem.WarpToPlace(row.place, target)
        end) end
    end

    local prev = xw_child(view, "feature7")
    local nextb = xw_child(view, "feature8")
    if prev ~= nil then prev.onClick:Add(function()
        if XW_Page > 1 then XW_Page = XW_Page - 1; xw_refresh(view) end
    end) end
    if nextb ~= nil then nextb.onClick:Add(function()
        local maxPage = math.max(1, math.ceil(#Xaou_WarpSystem.GetDestinations(XW_Category) / XW_PageSize))
        if XW_Page < maxPage then XW_Page = XW_Page + 1; xw_refresh(view) end
    end) end

    local close = xw_child(view, "btnClose")
    if close ~= nil then close.onClick:Add(Xaou_CloseWarpWindow) end
    local back = xw_child(view, "btnLanguage")
    if back ~= nil then back.onClick:Add(function()
        Xaou_CloseWarpWindow()
        if Xaou_OpenStandaloneModCenter then Xaou_OpenStandaloneModCenter(XW_Target or Xaou_CurrentNpcTarget) end
    end) end

    xw_refresh(view)
    return true
end

function Xaou_WarpSystem.ShowMap(target)
    return Xaou_OpenWarpWindow(target)
end
