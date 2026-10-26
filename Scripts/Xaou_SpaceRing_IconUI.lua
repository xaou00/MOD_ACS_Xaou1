-- Xaou SpaceRing icon browser. Storage remains Map.SpaceRing.

local XaouSpaceRingWindow = CS.Wnd_Simple.CreateWindow("XaouSpaceRingWindow")
_G.XaouSpaceRingWindow = XaouSpaceRingWindow

local function xui_mod()
    local mod = nil
    pcall(function() mod = GameMain:GetMod("Xaou_SpaceRing_AddItem") end)
    return mod
end

local function xui_def(id)
    local def = nil
    pcall(function()
        local mgr = ThingMgr
        if mgr == nil and CS ~= nil and CS.XiaWorld ~= nil then
            mgr = CS.XiaWorld.ThingMgr.Instance
        end
        local kind = g_emThingType and g_emThingType.Item or CS.XiaWorld.g_emThingType.Item
        def = mgr:GetDef(kind, tostring(id))
    end)
    return def
end

local function xui_select_index(result)
    if result == nil then return nil end
    if type(result) == "number" then return tonumber(result) end
    local count = nil
    pcall(function() count = tonumber(result.Count) end)
    if count ~= nil and count > 0 then
        local value = nil
        pcall(function() value = result:get_Item(0) end)
        if value == nil then pcall(function() value = result[0] end) end
        return tonumber(value)
    end
    return tonumber(result)
end

local function xui_helper()
    local helper = nil
    pcall(function() helper = CS.WorldLuaHelper() end)
    return helper
end

local function xui_hide(obj)
    if obj == nil then return end
    pcall(function() obj.visible = false end)
    pcall(function() obj:SetSize(0, 0, false) end)
end

function XaouSpaceRingWindow:AddLabel(name, text, x, y, w, h, size)
    if Xaou_LocalizeText then text = Xaou_LocalizeText(text) end
    local obj = self:AddObjectFromUrl("ui://0xrxw6g7hdhl1b", x, y)
    obj.name = name
    obj:SetSize(w or 200, h or 28, false)
    pcall(function() obj.m_title.text = tostring(text or "") end)
    pcall(function()
        obj.m_title.textFormat.size = tonumber(size) or 20
        obj.m_title:ApplyFormat()
    end)
    pcall(function()
        local n = tonumber(obj.numChildren) or 0
        for i = 0, n - 1 do
            local child = obj:GetChildAt(i)
            if child ~= nil and child ~= obj.m_title then child.visible = false end
        end
    end)
    return obj
end

function XaouSpaceRingWindow:AddButton(name, text, x, y, w, h)
    if Xaou_LocalizeText then text = Xaou_LocalizeText(text) end
    local obj = self:AddObjectFromUrl("ui://0xrxw6g7hdhl18", x, y)
    obj.name = name
    obj:SetSize(w or 120, h or 38, false)
    pcall(function()
        obj.m_title.text = tostring(text or "")
        obj.m_title.textFormat.size = 20
        obj.m_title:ApplyFormat()
    end)
    return obj
end

function XaouSpaceRingWindow:AddItemSlot(name, title, icon, count, x, y, w, h)
    local obj = nil
    pcall(function() obj = self:AddObjectFromUrl("ui://0xrxw6g7hdhl1q", x, y) end)
    if obj == nil then return self:AddButton(name, tostring(title) .. " x" .. tostring(count), x, y, w, h) end
    obj.name = name
    obj:SetSize(w, h, false)
    pcall(function()
        local c = obj:GetChild("title")
        if c ~= nil then c.text = tostring(title or "")
        elseif obj.m_title ~= nil then obj.m_title.text = tostring(title or "") end
    end)
    pcall(function()
        local c = obj:GetChild("count")
        if c ~= nil then c.text = "x" .. tostring(count or 0) end
    end)
    pcall(function()
        local c = obj:GetChild("icon")
        if c ~= nil then
            c.icon = tostring(icon or "")
            c:SetSize(w - 26, h - 42, false)
            c.x = 13
            c.y = 6
        end
    end)
    for _, childName in ipairs({"Stuff", "Up", "Loop", "loading", "n15", "n16", "n17", "n18"}) do
        pcall(function()
            local c = obj:GetChild(childName)
            if c ~= nil then c.visible = false end
        end)
    end
    return obj
end

function XaouSpaceRingWindow:ClearDynamic()
    for _, obj in ipairs(self.dynamicObjects or {}) do xui_hide(obj) end
    self.dynamicObjects = {}
    self.itemData = {}
    self.categoryData = {}
end

function XaouSpaceRingWindow:LoadRows()
    local mod = xui_mod()
    local rows = {}
    if mod ~= nil and mod.GetStorageRows ~= nil then
        local ok, value = pcall(function() return mod:GetStorageRows() end)
        if ok and type(value) == "table" then rows = value end
    end
    self.allRows = rows
end

function XaouSpaceRingWindow:GetCategories()
    local seen = {}
    local result = {"ทั้งหมด"}
    for _, row in ipairs(self.allRows or {}) do
        local cat = tostring(row.category or "อื่นๆ")
        if seen[cat] ~= true then
            seen[cat] = true
            result[#result + 1] = cat
        end
    end
    table.sort(result, function(a, b)
        if a == "ทั้งหมด" then return true end
        if b == "ทั้งหมด" then return false end
        return a < b
    end)
    return result
end

function XaouSpaceRingWindow:GetVisibleRows()
    local result = {}
    for _, row in ipairs(self.allRows or {}) do
        if self.category == "ทั้งหมด" or tostring(row.category or "อื่นๆ") == self.category then
            result[#result + 1] = row
        end
    end
    table.sort(result, function(a, b) return tostring(a.title or a.id) < tostring(b.title or b.id) end)
    return result
end

function XaouSpaceRingWindow:RefreshView(reload)
    if reload == true then self:LoadRows() end
    self:ClearDynamic()
    local categories = self:GetCategories()
    for i, cat in ipairs(categories) do
        if i <= 9 then
            local prefix = cat == self.category and "> " or ""
            local btn = self:AddButton("cat" .. tostring(i), prefix .. cat, 22, 76 + (i - 1) * 47, 145, 40)
            self.categoryData[btn.name] = cat
            self.dynamicObjects[#self.dynamicObjects + 1] = btn
        end
    end

    local rows = self:GetVisibleRows()
    local pageSize = 12
    local maxPage = math.ceil(#rows / pageSize)
    if maxPage < 1 then maxPage = 1 end
    if self.page < 1 then self.page = 1 end
    if self.page > maxPage then self.page = maxPage end
    local first = (self.page - 1) * pageSize + 1
    for slot = 1, pageSize do
        local row = rows[first + slot - 1]
        if row ~= nil then
            local def = xui_def(row.id)
            local title = tostring(row.title or row.id)
            local icon = ""
            if def ~= nil then
                pcall(function() title = tostring(def.ThingName or title) end)
                pcall(function() icon = tostring(def.TexPath or "") end)
            end
            local col = (slot - 1) % 4
            local line = math.floor((slot - 1) / 4)
            local btn = self:AddItemSlot("item" .. tostring(slot), title, icon, row.count, 195 + col * 166, 82 + line * 142, 148, 128)
            btn.tooltips = title .. "\nID: " .. tostring(row.id) .. "\nจำนวน: " .. tostring(row.count)
            self.itemData[btn.name] = row
            self.dynamicObjects[#self.dynamicObjects + 1] = btn
        end
    end
    self.pageLabel.m_title.text = tostring(self.page) .. "/" .. tostring(maxPage)
    local status = "หมวด: " .. tostring(self.category) .. " | " .. tostring(#rows) .. " รายการ"
    if Xaou_LocalizeText then status = Xaou_LocalizeText(status) end
    self.statusLabel.m_title.text = status
end

function XaouSpaceRingWindow:ChooseAmount(row)
    local helper = xui_helper()
    if helper == nil or helper.ShowSelectBox == nil then return end
    local choices = {"เบิก 1 ชิ้น", "เบิก 10 ชิ้น", "เบิก 100 ชิ้น", "เบิกทั้งหมด"}
    helper:ShowSelectBox("เลือกจำนวน\n" .. tostring(row.title) .. "\nมีในคลัง: " .. tostring(row.count), choices, 1, 1, function(result)
        local index = xui_select_index(result)
        if index == 0 then index = 1 end
        if index == nil then return end
        local amount = ({1, 10, 100, tonumber(row.count) or 1})[index]
        if amount == nil then return end
        if amount > tonumber(row.count) then amount = tonumber(row.count) end
        local mod = xui_mod()
        if mod ~= nil and mod.WithdrawFromVirtualStorage ~= nil then
            mod:WithdrawFromVirtualStorage(row.id, amount)
            self:RefreshView(true)
        end
    end)
end

function XaouSpaceRingWindow:OnInit()
    self.sx = 890
    self.sy = 590
    self.category = "ทั้งหมด"
    self.page = 1
    self.dynamicObjects = {}
    self.itemData = {}
    self.categoryData = {}
    self:SetTitle("คลังจักรวาล Xaou")
    self:SetSize(self.sx, self.sy)
    self:AddLabel("brand", "Xaou SpaceRing", 22, 36, 300, 30, 24)
    self.statusLabel = self:AddLabel("status", "กำลังอ่านคลัง...", 195, 40, 540, 28, 20)
    self.btnPrev = self:AddButton("prev", "◀", 350, 522, 58, 40)
    self.pageLabel = self:AddButton("page", "1/1", 418, 522, 86, 40)
    self.btnNext = self:AddButton("next", "▶", 514, 522, 58, 40)
    self.btnRefresh = self:AddButton("refresh", "รีเฟรช", 700, 522, 120, 40)
    self:Center()
end

function XaouSpaceRingWindow:OnShown()
    self.page = 1
    self:RefreshView(true)
    pcall(function() if self.window ~= nil then self.window:BringToFront() end end)
end

function XaouSpaceRingWindow:OnObjectEvent(t, obj, context)
    if t ~= "onClick" or obj == nil then return true end
    local name = tostring(obj.name or "")
    if name == "prev" then self.page = self.page - 1; self:RefreshView(false); return true end
    if name == "next" then self.page = self.page + 1; self:RefreshView(false); return true end
    if name == "refresh" then self:RefreshView(true); return true end
    local cat = self.categoryData[name]
    if cat ~= nil then self.category = cat; self.page = 1; self:RefreshView(false); return true end
    local row = self.itemData[name]
    if row ~= nil then self:ChooseAmount(row); return true end
    return true
end

function Xaou_SpaceRing_OpenIconUI()
    if XaouSpaceRingWindow == nil then return false end
    XaouSpaceRingWindow:Show()
    pcall(function() if XaouSpaceRingWindow.window ~= nil then XaouSpaceRingWindow.window:BringToFront() end end)
    return true
end
