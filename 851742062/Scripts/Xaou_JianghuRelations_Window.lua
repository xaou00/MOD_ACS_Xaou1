-- Xaou Jianghu NPC window. Uses the existing Xaou_OpenHeartBySeed logic.

local Xaou_JH_View = nil
local Xaou_JH_Page = 1
local Xaou_JH_PageSize = 6
local Xaou_JH_Selected = nil
local Xaou_JH_Rows = {}

local function jh_child(view, name)
    local value = nil
    pcall(function() value = view:GetChild(name) end)
    return value
end

local function jh_text(obj, value)
    if obj == nil then return end
    if Xaou_LocalizeText then value = Xaou_LocalizeText(value) end
    pcall(function() obj.text = tostring(value or "") end)
    pcall(function() obj.title = tostring(value or "") end)
end

local function jh_visible(obj, value)
    if obj == nil then return end
    pcall(function() obj.visible = value == true end)
    pcall(function() obj.touchable = value == true end)
    pcall(function() obj.enabled = value == true end)
end

local function jh_get_name(def, seed)
    if def == nil then return "NPC " .. tostring(seed) end
    local name = tostring(def.LastName or "") .. tostring(def.FristName or def.FirstName or "")
    if name == "" then name = "NPC " .. tostring(seed) end
    return name
end

local function jh_add_seed_keys(dict, seeds, seen)
    if dict == nil then return end
    local function add(value)
        value = tonumber(value) or value
        if value == nil then return end
        local key = tostring(value)
        if not seen[key] then
            seen[key] = true
            seeds[#seeds + 1] = value
        end
    end
    pcall(function()
        for seed, _ in pairs(dict) do add(seed) end
    end)
    pcall(function()
        local e = dict:GetEnumerator()
        while e:MoveNext() do add(e.Current.Key) end
        pcall(function() e:Dispose() end)
    end)
    pcall(function()
        local e = dict.Keys:GetEnumerator()
        while e:MoveNext() do add(e.Current) end
        pcall(function() e:Dispose() end)
    end)
end

local function jh_resolve_def(mgr, school, seed)
    local def = nil
    pcall(function() def = mgr:GetJHNpcDataByRandomSeed(seed) end)
    if def == nil then
        pcall(function() def = mgr:GetJHNpcDataBySeed(seed) end)
    end
    if def == nil and school ~= nil then
        pcall(function()
            local template = school.JianghuNpcs[seed]
            if template ~= nil then def = mgr:GetJianghuNpcDef(template) end
        end)
    end
    return def
end

local function jh_resolve_name(mgr, def, seed)
    local name = jh_get_name(def, seed)
    pcall(function()
        local gameName = mgr:GetJHNpcName(seed, true, false)
        if gameName ~= nil and tostring(gameName) ~= "" then name = tostring(gameName) end
    end)
    return name
end

local function jh_build_rows()
    local rows, seeds, seen = {}, {}, {}
    local ok = pcall(function()
        local school = CS.XiaWorld.SchoolGlobleMgr.Instance
        local mgr = JianghuMgr
        if mgr == nil then mgr = CS.XiaWorld.JianghuMgr.Instance end

        -- World registry contains generated Jianghu NPCs, while KnowNpcData is
        -- the authoritative list of NPCs the player has actually met.
        jh_add_seed_keys(school and school.JianghuNpcs or nil, seeds, seen)
        jh_add_seed_keys(mgr and mgr.KnowNpcData or nil, seeds, seen)
        table.sort(seeds, function(a, b) return tonumber(a) < tonumber(b) end)
        for _, seed in ipairs(seeds) do
            -- Do not require KnowNpcData here. A newly generated/encountered
            -- Jianghu NPC may already exist in the world registry before the
            -- game creates a persistent relationship record. The Open Heart
            -- action below can create that record safely via AddKnowNpcData.
            local def = jh_resolve_def(mgr, school, seed)
            local status = "อยู่"
            pcall(function()
                if school:IsJianghuNpcDie(seed) then status = "เสียชีวิต"
                elseif school:IsJianghuNpcLeave(seed) then status = "ออกไปแล้ว" end
            end)
            rows[#rows + 1] = {
                seed=seed,
                def=def,
                name=jh_resolve_name(mgr, def, seed),
                status=status
            }
        end
    end)
    if not ok then return {} end
    return rows
end

local function jh_read_state(row)
    local state = {favor="ยังไม่รู้จัก", vigilance="-", heart="ยังไม่เปิด"}
    if row == nil then return state end
    pcall(function()
        local data = JianghuMgr:GetKnowNpcData(row.seed)
        if data ~= nil then
            state.favor = tostring(data.favour or data.Favour or data.Favor or 0)
            state.vigilance = tostring(data.Vigilance or 0)
            state.heart = tonumber(data.hlock or 0) == 1 and "เปิดแล้ว" or "ยังไม่เปิด"
        end
    end)
    return state
end

local function jh_portrait(row)
    if row == nil then return "" end
    local value = ""
    pcall(function()
        local mgr = JianghuMgr or CS.XiaWorld.JianghuMgr.Instance
        local npc = mgr and mgr:GetNpc(row.seed) or nil
        if npc ~= nil and npc.Race ~= nil then
            value = tostring(npc.Race.TexPath or npc.Race.Rolepaint or "")
        end
    end)
    if value == "" and row.def ~= nil then
        pcall(function()
            local npcMgr = NpcMgr or CS.XiaWorld.NpcMgr.Instance
            local race = npcMgr and npcMgr:GetRaceDef(tostring(row.def.Race or "")) or nil
            if race ~= nil then
                value = tostring(race.TexPath or race.Rolepaint or "")
            end
        end)
    end
    return value
end

local function jh_refresh_detail(view)
    local row = Xaou_JH_Selected
    local state = jh_read_state(row)
    jh_text(jh_child(view, "npcName"), row and row.name or "เลือก NPC")
    jh_text(jh_child(view, "npcStatus"), row and
        ("สถานะ: " .. tostring(row.status) .. "\nความชอบ: " .. state.favor ..
         "\nความระแวง: " .. state.vigilance .. "\nเปิดใจ: " .. state.heart) or
        "สถานะ: -\nความชอบ: -\nความระแวง: -\nเปิดใจ: -")
    local portrait = jh_child(view, "portrait")
    local url = jh_portrait(row)
    pcall(function() portrait.url = url end)
    pcall(function() portrait.icon = url end)
    jh_visible(portrait, url ~= "")
end

local function jh_refresh(view, rebuild)
    jh_text(jh_child(view, "title"), "NPC สำนักอื่น")
    jh_text(jh_child(view, "subtitle"), "เลือกตัวละครเพื่อเปิดใจหรือเพิ่มความสัมพันธ์")
    if rebuild == true then Xaou_JH_Rows = jh_build_rows() end
    local maxPage = math.max(1, math.ceil(#Xaou_JH_Rows / Xaou_JH_PageSize))
    Xaou_JH_Page = math.max(1, math.min(Xaou_JH_Page, maxPage))
    local first = (Xaou_JH_Page - 1) * Xaou_JH_PageSize + 1
    for i = 1, Xaou_JH_PageSize do
        local button = jh_child(view, "npcBtn" .. tostring(i))
        local row = Xaou_JH_Rows[first + i - 1]
        if row ~= nil then
            local state = jh_read_state(row)
            local mark = Xaou_JH_Selected == row and "▶ " or ""
            jh_text(button, mark .. row.name .. "  |  ใจ: " .. state.heart .. "  |  ❤ " .. state.favor)
            button.data = row
            jh_visible(button, true)
        else
            if button ~= nil then button.data = nil end
            jh_visible(button, false)
        end
    end
    jh_text(jh_child(view, "txtPage"), tostring(Xaou_JH_Page) .. "/" .. tostring(maxPage))
    jh_refresh_detail(view)
end

function Xaou_CloseJianghuNpcWindow()
    if Xaou_JH_View ~= nil then
        pcall(function() Xaou_JH_View:RemoveFromParent() end)
        pcall(function() Xaou_JH_View:Dispose() end)
        Xaou_JH_View = nil
    end
end

function Xaou_OpenJianghuNpcWindow()
    Xaou_CloseJianghuNpcWindow()
    local pkg = UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root = (GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if pkg == nil or root == nil then return false end
    pcall(function() pkg.AddPackage("UI/XaoCtr") end)
    local view = nil
    local errors = {}
    local function try_create(label, creator)
        if view ~= nil then return end
        local ok, value = pcall(creator)
        if ok and value ~= nil then view = value
        else errors[#errors + 1] = label .. ": " .. tostring(value) end
    end
    try_create("CreateObject", function() return pkg.CreateObject("XaoCtr", "JianghuNpcWindow") end)
    try_create("CreateObject.xml", function() return pkg.CreateObject("XaoCtr", "JianghuNpcWindow.xml") end)
    try_create("CreateObjectFromURL", function() return pkg.CreateObjectFromURL("ui://xmc97319jhn01") end)
    try_create("GetItemURL", function()
        local url = pkg.GetItemURL("XaoCtr", "JianghuNpcWindow")
        if url == nil or tostring(url) == "" then return nil end
        return pkg.CreateObjectFromURL(url)
    end)
    if view == nil then return false, table.concat(errors, "\n") end
    Xaou_JH_View = view
    Xaou_JH_Page = 1
    Xaou_JH_Selected = nil
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2

    for i = 1, Xaou_JH_PageSize do
        local button = jh_child(view, "npcBtn" .. tostring(i))
        if button ~= nil then button.onClick:Add(function()
            if button.data ~= nil then
                Xaou_JH_Selected = button.data
                jh_refresh(view, false)
            end
        end) end
    end

    local prev = jh_child(view, "btnPrev")
    local nextb = jh_child(view, "btnNext")
    local close = jh_child(view, "btnClose")
    local refresh = jh_child(view, "btnRefresh")
    local open = jh_child(view, "btnOpenHeart")
    local maxFavor = jh_child(view, "btnMaxFavor")
    jh_text(prev, "◀")
    jh_text(nextb, "▶")
    jh_text(close, "×")
    jh_text(refresh, "รีเฟรช")
    jh_text(open, "เปิดใจ")
    jh_text(maxFavor, "เปิดใจ + สัมพันธ์เต็ม")

    if prev then prev.onClick:Add(function() Xaou_JH_Page = Xaou_JH_Page - 1; jh_refresh(view, false) end) end
    if nextb then nextb.onClick:Add(function() Xaou_JH_Page = Xaou_JH_Page + 1; jh_refresh(view, false) end) end
    if close then close.onClick:Add(Xaou_CloseJianghuNpcWindow) end
    if refresh then refresh.onClick:Add(function() jh_refresh(view, true) end) end
    if open then open.onClick:Add(function()
        if Xaou_JH_Selected ~= nil and Xaou_OpenHeartBySeed(Xaou_JH_Selected.seed, false) then jh_refresh(view, true) end
    end) end
    if maxFavor then maxFavor.onClick:Add(function()
        if Xaou_JH_Selected ~= nil and Xaou_OpenHeartBySeed(Xaou_JH_Selected.seed, true) then jh_refresh(view, true) end
    end) end

    jh_refresh(view, true)
    pcall(function() view:BringToFront() end)
    return true
end
