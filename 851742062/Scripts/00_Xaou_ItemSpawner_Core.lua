-- Xaou item shop

local mod = GameMain:GetMod("Xaou_ItemSpawner_Standalone")
local itemList, itemMap = nil, nil

local function show(text, title)
    if Xaou_LocalizeText then
        text = Xaou_LocalizeText(text)
        if title ~= nil then title = Xaou_LocalizeText(title) end
    end
    local shown = false
    pcall(function()
        CS.Wnd_Message.Show(tostring(text), 1, nil, true, tostring(title or "Xaou"), 0, 0, "")
        shown = true
    end)
    if not shown then pcall(function() world:ShowMsgBox(tostring(text)) end) end
end

local function normalize(data)
    if type(data) ~= "table" then return nil end
    local id = data.id or data.ID or data.Name or data.name
    if id == nil or tostring(id) == "" then return nil end
    return {
        id=tostring(id),
        count=tonumber(data.count or data.Count or 1) or 1,
        cat=tostring(data.cat or data.category or "อื่น"),
    }
end

local function add_item(data)
    local value = normalize(data)
    if value == nil then return end
    if itemMap[value.id] == nil then
        itemMap[value.id] = value
        itemList[#itemList + 1] = value
    else
        itemMap[value.id].cat = value.cat
        itemMap[value.id].count = value.count
    end
end

local function rebuild()
    itemList, itemMap = {}, {}
    pcall(function()
        local mgr = ThingMgr or CS.XiaWorld.ThingMgr.Instance
        local _, defs = mgr.m_mapThingDefs:TryGetValue(2)
        if defs ~= nil then
            for _, def in pairs(defs) do
                if def ~= nil and def.Name ~= nil then
                    add_item({id=tostring(def.Name), count=1, cat="อื่น"})
                end
            end
        end
    end)
    if type(Xaou_ExtraItemList) == "table" then
        for _, data in ipairs(Xaou_ExtraItemList) do add_item(data) end
    end
    if type(Xaou_ItemPacks) == "table" then
        for _, pack in ipairs(Xaou_ItemPacks) do
            local list = type(pack) == "table" and (pack.items or pack) or nil
            if type(list) == "table" then
                for _, data in ipairs(list) do add_item(data) end
            end
        end
    end
    table.sort(itemList, function(a, b) return tostring(a.id) < tostring(b.id) end)
end

function Xaou_GetSpawnerItemDef(id)
    local value = nil
    pcall(function()
        local mgr = ThingMgr or CS.XiaWorld.ThingMgr.Instance
        local kind = g_emThingType and g_emThingType.Item or CS.XiaWorld.g_emThingType.Item
        value = mgr:GetDef(kind, tostring(id))
    end)
    return value
end

function Xaou_GetSpawnerItems(category, keyword)
    rebuild()
    local result = {}
    local cat = tostring(category or "all")
    if cat == "อาหาร" then cat = "vkski" end
    if cat == "material" or cat == "วัสดุ" then cat = "วัตถุดิบ" end
    local search = string.lower(tostring(keyword or ""))
    for _, data in ipairs(itemList) do
        local matchCat = cat == "all" or tostring(data.cat) == cat
        local matchSearch = search == ""
        if not matchSearch then
            local def = Xaou_GetSpawnerItemDef(data.id)
            local name = def and tostring(def.ThingName or "") or ""
            matchSearch = string.find(string.lower(data.id), search, 1, true) ~= nil
                or string.find(string.lower(name), search, 1, true) ~= nil
        end
        if matchCat and matchSearch then result[#result + 1] = data end
    end
    return result
end

function Xaou_SpawnItemDirect(id, count)
    local ok, result = pcall(function()
        local def = Xaou_GetSpawnerItemDef(id)
        if def == nil then error("ไม่พบไอเทม: " .. tostring(id)) end
        local map = Map or CS.XiaWorld.World.Instance.map
        local key = map:GetRandomInLifeArea(4)
        if key == nil then error("หาตำแหน่งวางของไม่พบ") end
        local remain = math.max(1, tonumber(count) or 1)
        local maxStack = math.max(1, tonumber(def.MaxStack) or remain)
        while remain > 0 do
            local amount = math.min(remain, maxStack)
            local thing = ItemRandomMachine.RandomItem(tostring(id), nil, 1, 12, 1, amount)
            map:DropItem(thing, key, true, true, false, true, 0, false)
            remain = remain - amount
        end
        return true
    end)
    if ok and result == true then
        show("เสกไอเทมสำเร็จ จำนวน " .. tostring(count), "Xaou เสกไอเทม")
        return true
    end
    show("เสกไอเทมไม่สำเร็จ\n" .. tostring(result), "Xaou เสกไอเทม")
    return false
end

function Xaou_ItemSpawner_Open()
    if Xaou_OpenItemSpawnerWindow == nil then
        show("ไม่พบหน้าต่างเสกไอเทม", "Xaou เสกไอเทม")
        return false
    end
    local ok, result = pcall(Xaou_OpenItemSpawnerWindow)
    if not ok or result == false then
        show("เปิดหน้าต่างไม่สำเร็จ\n" .. tostring(result), "Xaou เสกไอเทม")
        return false
    end
    return true
end



function mod:OnEnter()
    local events = GameMain:GetMod("_Event")
    if events ~= nil then
        events:RegisterEvent(g_emEvent.SelectNpc, function(evt, npc, objs) self:AddButton(npc) end, self)
    end
end

function mod:OnLeave()
    local events = GameMain:GetMod("_Event", true)
    if events ~= nil then pcall(function() events:UnRegisterEvent(g_emEvent.SelectNpc, self) end) end
    pcall(function() Xaou_CloseItemSpawnerWindow() end)
end
