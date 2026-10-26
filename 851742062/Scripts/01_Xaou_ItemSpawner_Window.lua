-- Xaou custom FairyGUI item spawner. Game logic remains in 01_Xaou_IconItemSpawner_fixed.lua.

local XIS_View, XIS_Page, XIS_Category, XIS_Selected, XIS_Amount = nil, 1, "all", nil, 1
local XIS_Search = ""
local XIS_PageSize, XIS_Items = 12, {}
local XIS_Categories = {
    {id="all", text="ทั้งหมด"}, {id="vkski", text="อาหาร"},
    {id="โอสถ", text="โอสถ"}, {id="ยารักษา", text="ยารักษา"},
    {id="ยันต์", text="ยันต์"}, {id="อาวุธ", text="อาวุธ"},
    {id="วัตถุดิบ", text="วัสดุ"}, {id="อื่น", text="อื่นๆ"},
}

local function xis_child(view, name)
    local value = nil
    pcall(function() value = view:GetChild(name) end)
    return value
end

local function xis_text(obj, value)
    if obj == nil then return end
    if Xaou_LocalizeText then value = Xaou_LocalizeText(value) end
    pcall(function() obj.text = tostring(value or "") end)
    pcall(function() obj.title = tostring(value or "") end)
end

-- ThingName/Desc already follow the game's active language.
local function xis_game_text(obj, value)
    if obj == nil then return end
    pcall(function() obj.text = tostring(value or "") end)
    pcall(function() obj.title = tostring(value or "") end)
end

local function xis_visible(obj, value)
    if obj == nil then return end
    pcall(function() obj.visible = value == true end)
    pcall(function() obj.touchable = value == true end)
    pcall(function() obj.enabled = value == true end)
end

local function xis_def(data)
    if data == nil or Xaou_GetSpawnerItemDef == nil then return nil end
    local value = nil
    pcall(function() value = Xaou_GetSpawnerItemDef(data.id) end)
    return value
end

local function xis_name(data, def)
    local name = data and tostring(data.id or "") or ""
    pcall(function() if def and def.ThingName then name = tostring(def.ThingName) end end)
    return name
end

local function xis_icon(def)
    local value = ""
    pcall(function() value = tostring(def.TexPath or "") end)
    return value
end

local function xis_refresh_detail(view)
    local def = xis_def(XIS_Selected)
    local name = XIS_Selected and xis_name(XIS_Selected, def) or "เลือกไอเทม"
    local icon = def and xis_icon(def) or ""
    local desc = XIS_Selected and ("หมวด: " .. tostring(XIS_Selected.cat or "อื่น")) or "แตะไอเทมเพื่อดูรายละเอียด"
    pcall(function() if def and def.Desc then desc = tostring(def.Desc) end end)
    xis_game_text(xis_child(view, "detailName"), name)
    xis_game_text(xis_child(view, "detailDesc"), desc)
    xis_text(xis_child(view, "amountLabel"), "จำนวน: " .. tostring(XIS_Amount))
    local loader = xis_child(view, "detailIcon")
    pcall(function() loader.url = icon end)
    xis_visible(loader, icon ~= "")
end

local function xis_refresh(view, rebuild)
    xis_text(xis_child(view, "title"), "เสกไอเทม")
    xis_text(xis_child(view, "subtitle"), "เลือกหมวดและไอเทมที่ต้องการ")
    if rebuild == true and Xaou_GetSpawnerItems ~= nil then
        local ok, value = pcall(function() return Xaou_GetSpawnerItems(XIS_Category, XIS_Search) end)
        XIS_Items = ok and type(value) == "table" and value or {}
    end
    local maxPage = math.max(1, math.ceil(#XIS_Items / XIS_PageSize))
    XIS_Page = math.max(1, math.min(XIS_Page, maxPage))
    local first = (XIS_Page - 1) * XIS_PageSize + 1
    for i = 1, XIS_PageSize do
        local button = xis_child(view, "item" .. tostring(i))
        local data = XIS_Items[first + i - 1]
        if data then
            local def = xis_def(data)
            local name, icon = xis_name(data, def), xis_icon(def)
            local title = nil
            pcall(function() title = button:GetChild("title") end)
            xis_game_text(title or button, name)
            local loader = xis_child(button, "icon")
            pcall(function() loader.url = icon end)
            if button then button.data = data end
            xis_visible(button, true)
        else
            if button then button.data = nil end
            xis_visible(button, false)
        end
    end
    xis_text(xis_child(view, "txtPage"), tostring(XIS_Page) .. "/" .. tostring(maxPage))
    local status = tostring(#XIS_Items) .. " รายการ | หมวด: " .. tostring(XIS_Category)
    if XIS_Search ~= "" then status = status .. " | ค้นหา: " .. XIS_Search end
    xis_text(xis_child(view, "status"), status)
    xis_refresh_detail(view)
end

function Xaou_CloseItemSpawnerWindow()
    if XIS_View then
        pcall(function() XIS_View:RemoveFromParent() end)
        pcall(function() XIS_View:Dispose() end)
        XIS_View = nil
    end
end

function Xaou_OpenItemSpawnerWindow()
    Xaou_CloseItemSpawnerWindow()
    local pkg = UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root = (GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if pkg == nil or root == nil then return false end
    pcall(function() pkg.AddPackage("UI/XaoCtr") end)
    local view = nil
    pcall(function() view = pkg.CreateObject("XaoCtr", "XaouItemSpawnerWindow") end)
    if view == nil then return false end
    XIS_View, XIS_Page, XIS_Category, XIS_Selected, XIS_Amount = view, 1, "all", nil, 1
    XIS_Search = ""
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2

    xis_text(xis_child(view, "btnClose"), "×")
    xis_text(xis_child(view, "btnPrev"), "◀")
    xis_text(xis_child(view, "btnNext"), "▶")
    xis_text(xis_child(view, "btnRefresh"), "รีเฟรช")
    xis_text(xis_child(view, "btnSpawn"), "เสกไอเทม")
    xis_text(xis_child(view, "btnClearSearch"), "×")
    for i, cat in ipairs(XIS_Categories) do
        local button = xis_child(view, "cat" .. tostring(i))
        xis_text(button, cat.text)
        if button then button.onClick:Add(function()
            XIS_Category, XIS_Page, XIS_Selected = cat.id, 1, nil
            xis_refresh(view, true)
        end) end
    end
    for i = 1, XIS_PageSize do
        local button = xis_child(view, "item" .. tostring(i))
        if button then button.onClick:Add(function()
            if button.data then XIS_Selected = button.data; xis_refresh_detail(view) end
        end) end
    end
    local amounts = {{"amount1",1},{"amount10",10},{"amount100",100},{"amount999",999}}
    for _, pair in ipairs(amounts) do
        local button, amount = xis_child(view, pair[1]), pair[2]
        xis_text(button, tostring(amount))
        if button then button.onClick:Add(function() XIS_Amount = amount; xis_refresh_detail(view) end) end
    end
    local prev, nextb = xis_child(view, "btnPrev"), xis_child(view, "btnNext")
    local close, refresh = xis_child(view, "btnClose"), xis_child(view, "btnRefresh")
    local spawn = xis_child(view, "btnSpawn")
    local inputSearch, clearSearch = xis_child(view, "inputSearch"), xis_child(view, "btnClearSearch")
    if prev then prev.onClick:Add(function() XIS_Page = XIS_Page - 1; xis_refresh(view, false) end) end
    if nextb then nextb.onClick:Add(function() XIS_Page = XIS_Page + 1; xis_refresh(view, false) end) end
    if close then close.onClick:Add(Xaou_CloseItemSpawnerWindow) end
    if refresh then refresh.onClick:Add(function() xis_refresh(view, true) end) end
    if inputSearch ~= nil then
        pcall(function()
            inputSearch.onChanged:Add(function()
                local value = ""
                pcall(function() value = tostring(inputSearch.text or "") end)
                XIS_Search, XIS_Page, XIS_Selected = value, 1, nil
                xis_refresh(view, true)
            end)
        end)
    end
    if clearSearch ~= nil then clearSearch.onClick:Add(function()
        XIS_Search, XIS_Page, XIS_Selected = "", 1, nil
        pcall(function() inputSearch.text = "" end)
        xis_refresh(view, true)
    end) end
    if spawn then spawn.onClick:Add(function()
        if XIS_Selected and Xaou_SpawnItemDirect then Xaou_SpawnItemDirect(XIS_Selected.id, XIS_Amount) end
    end) end
    xis_refresh(view, true)
    return true
end
