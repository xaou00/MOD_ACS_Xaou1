-- Xaou 009 Damage Numbers v1.2
-- Visual-only mod. Damage calculations and save data are never modified.

if Xaou_DamageNumbers_ScriptLoaded then return end
Xaou_DamageNumbers_ScriptLoaded = true

local XaouDamage = GameMain:NewMod("Xaou_DamageNumbers")

local BUTTON_NAME = "Xaou Damage Numbers"
local SNAPSHOT_INTERVAL = 0.08
local BURST_DELAY = 0.18
local FLOAT_DURATION = 1.15

local function show_message(text)
    local shown = false
    pcall(function()
        CS.Wnd_Message.Show(tostring(text), 1, nil, true,
            "Xaou 009 Damage Numbers", 0, 0, "")
        shown = true
    end)
    if not shown then pcall(function() CS.WorldLuaHelper():ShowMsgBox(tostring(text)) end) end
end

local function list_item(values, index)
    if values == nil then return nil end
    local value = nil
    pcall(function() value = values:get_Item(index) end)
    if value == nil then pcall(function() value = values[index] end) end
    return value
end

local function thing_id(thing)
    local value = nil
    if thing ~= nil then pcall(function() value = tonumber(thing.ID) end) end
    return value
end

local function read_number(object, member)
    local value = nil
    if object ~= nil then pcall(function() value = tonumber(object[member]) end) end
    return value
end

local function read_damage_map(thing)
    local result = {}
    if thing == nil then return result end

    local damageMap = nil
    pcall(function() damageMap = thing.PropertyMgr.BodyData.m_DamageID end)
    if damageMap == nil then return result end

    local enumerator = nil
    pcall(function() enumerator = damageMap:GetEnumerator() end)
    if enumerator == nil then return result end

    while true do
        local moved = false
        local ok = pcall(function() moved = enumerator:MoveNext() end)
        if not ok or not moved then break end
        local pair = nil
        pcall(function() pair = enumerator.Current end)
        if pair ~= nil then
            local id, damage = nil, nil
            pcall(function() id = tonumber(pair.Key) end)
            pcall(function() damage = pair.Value end)
            if id ~= nil and damage ~= nil then
                local value = 0
                pcall(function() value = tonumber(damage:GetValue()) or 0 end)
                result[id] = value
            end
        end
    end
    pcall(function() enumerator:Dispose() end)
    return result
end

function XaouDamage:ReadState(thing)
    if thing == nil then return nil end
    local id = thing_id(thing)
    if id == nil then return nil end
    return {
        id = id,
        thing = thing,
        ling = read_number(thing, "LingV"),
        hp = read_number(thing, "Hp"),
        damages = read_damage_map(thing)
    }
end

function XaouDamage:SnapshotAllNpcs()
    local manager, npcType = nil, nil
    pcall(function() manager = CS.XiaWorld.ThingMgr.Instance end)
    pcall(function() npcType = CS.XiaWorld.g_emThingType.Npc end)
    if manager == nil or npcType == nil then return end

    local list = nil
    pcall(function() list = manager:GetThingList(npcType) end)
    if list == nil then return end

    local count = 0
    pcall(function() count = tonumber(list.Count) or 0 end)
    for i = 0, count - 1 do
        local thing = list_item(list, i)
        local state = self:ReadState(thing)
        if state ~= nil and self.Pending[state.id] == nil then
            self.Snapshots[state.id] = state
        end
    end
end

local function get_root()
    local root = nil
    pcall(function() root = GRoot.inst end)
    if root == nil then pcall(function() root = CS.FairyGUI.GRoot.inst end) end
    return root
end

local function make_color(r, g, b)
    local value = nil
    -- FairyGUI expects UnityEngine.Color. XLua Mobile does not apply the
    -- implicit Color32 -> Color conversion used by normal C# code.
    pcall(function() value = CS.UnityEngine.Color(r / 255, g / 255, b / 255, 1) end)
    return value
end

function XaouDamage:CreateLabel(text, color, target, offset)
    local root = get_root()
    if root == nil then return false, "GRoot unavailable" end

    local label = nil
    local ok, err = pcall(function()
        if GTextField ~= nil then label = GTextField() end
        if label == nil then label = CS.FairyGUI.GTextField() end
    end)
    if not ok or label == nil then return false, tostring(err or "GTextField unavailable") end

    local configured, configError = pcall(function()
        label.text = tostring(text)
        label.touchable = false
        label:SetSize(260, 70)
        root:AddChild(label)
    end)
    if not configured then
        pcall(function() label:Dispose() end)
        return false, tostring(configError)
    end

    -- Styling differs slightly between FairyGUI mobile builds. Keep the
    -- label alive even when an optional style property is unavailable.
    pcall(function() label.color = color end)
    pcall(function() label.fontSize = 32 end)
    pcall(function()
        local format = label.textFormat
        format.size = 32
        label.textFormat = format
    end)
    pcall(function()
        local format = label.textFormat
        format.color = color
        label.textFormat = format
    end)
    pcall(function()
        local format = label.textFormat
        format.bold = true
        label.textFormat = format
    end)
    pcall(function()
        local format = label.textFormat
        format.stroke = 2
        format.strokeColor = make_color(40, 24, 16)
        label.textFormat = format
    end)
    pcall(function() label.align = CS.FairyGUI.AlignType.Center end)
    pcall(function() label.verticalAlign = CS.FairyGUI.VertAlignType.Middle end)

    self.Floaters[#self.Floaters + 1] = {
        label = label,
        target = target,
        age = 0,
        duration = FLOAT_DURATION,
        offset = tonumber(offset) or 0
    }
    return true
end

function XaouDamage:WorldToGui(target, rise)
    if target == nil then return nil, nil end
    local camera, pos = nil, nil
    pcall(function() camera = CS.MapCamera.Instance.MainCamera end)
    if camera == nil then pcall(function() camera = MapCamera.Instance.MainCamera end) end
    if camera == nil then pcall(function() camera = CS.UnityEngine.Camera.main end) end
    pcall(function() pos = target.ViewPos end)
    if camera == nil or pos == nil then return nil, nil end

    local screen = nil
    pcall(function() screen = camera:WorldToScreenPoint(pos) end)
    if screen == nil or tonumber(screen.z) == nil or tonumber(screen.z) < 0 then return nil, nil end

    local root = get_root()
    if root == nil then return nil, nil end
    local sh = 1
    pcall(function() sh = tonumber(CS.UnityEngine.Screen.height) or 1 end)
    local point = CS.UnityEngine.Vector2(tonumber(screen.x), sh - tonumber(screen.y))
    local localPoint = nil
    pcall(function() localPoint = root:GlobalToLocal(point) end)
    if localPoint == nil then return nil, nil end
    return tonumber(localPoint.x), tonumber(localPoint.y) - 75 - (tonumber(rise) or 0)
end

function XaouDamage:UpdateFloaters(dt)
    for i = #self.Floaters, 1, -1 do
        local row = self.Floaters[i]
        row.age = row.age + dt
        if row.age >= row.duration or row.label == nil then
            if row.label ~= nil then
                pcall(function()
                    row.label:RemoveFromParent()
                    row.label:Dispose()
                end)
            end
            table.remove(self.Floaters, i)
        else
            local x, y = self:WorldToGui(row.target, row.offset + row.age * 55)
            if x == nil or y == nil then
                local root = get_root()
                if root ~= nil then
                    x = tonumber(root.width) * 0.5
                    y = tonumber(root.height) * 0.35 - row.offset - row.age * 55
                end
            end
            if x ~= nil and y ~= nil then pcall(function()
                row.label:SetXY(x - 130, y - 35)
                row.label.alpha = math.max(0, 1 - row.age / row.duration)
            end) end
        end
    end
end

function XaouDamage:StartOrExtendBurst(target, values)
    if not self.Enabled or target == nil then return end
    local id = thing_id(target)
    if id == nil then return end

    local burst = self.Pending[id]
    if burst == nil then
        burst = {
            target = target,
            before = self.Snapshots[id],
            delay = BURST_DELAY,
            rawDamage = 0,
            hadBlocked = false
        }
        self.Pending[id] = burst
    else
        burst.delay = BURST_DELAY
    end

    local count = 0
    pcall(function() count = tonumber(values.Length) or 0 end)
    if count >= 4 then
        local raw = nil
        pcall(function() raw = tonumber(values[3]) end)
        if raw ~= nil and raw > burst.rawDamage then burst.rawDamage = raw end
    end
    local passed = nil
    pcall(function() passed = values[0] end)
    if passed == false then burst.hadBlocked = true end
end

function XaouDamage:FinishBurst(id, burst)
    local current = self:ReadState(burst.target)
    if current == nil then return end
    local before = burst.before or current

    local lingLoss = 0
    if before.ling ~= nil and current.ling ~= nil then
        lingLoss = math.max(0, before.ling - current.ling)
    end

    local hpLoss = 0
    if before.hp ~= nil and current.hp ~= nil then
        hpLoss = math.max(0, before.hp - current.hp)
    end

    local injury = 0
    local oldDamages = before.damages or {}
    for damageId, value in pairs(current.damages or {}) do
        if oldDamages[damageId] == nil then injury = injury + (tonumber(value) or 0) end
    end

    local shown = false
    local displayError = nil
    local injuryNumber = math.floor(injury * 100 + 0.5)
    if injuryNumber > 0 then
        local ok, err = self:CreateLabel("-" .. tostring(injuryNumber), make_color(235, 72, 55), burst.target, 0)
        shown = ok
        if not ok then displayError = err end
    elseif hpLoss > 0 then
        local ok, err = self:CreateLabel("-" .. tostring(math.floor(hpLoss + 0.5)), make_color(235, 72, 55), burst.target, 0)
        shown = ok
        if not ok then displayError = err end
    elseif burst.rawDamage > 0 then
        local ok, err = self:CreateLabel("-" .. tostring(math.floor(burst.rawDamage + 0.5)), make_color(235, 72, 55), burst.target, 0)
        shown = ok
        if not ok then displayError = err end
    end

    if lingLoss > 0 then
        local ok, err = self:CreateLabel("-" .. tostring(math.floor(lingLoss * 10 + 0.5) / 10) .. " ปราณ",
            make_color(65, 170, 245), burst.target, shown and 34 or 0)
        if ok then shown = true else displayError = displayError or err end
    end

    if not shown and burst.hadBlocked then
        local ok, err = self:CreateLabel("ป้องกัน", make_color(225, 190, 80), burst.target, 0)
        shown = ok
        if not ok then displayError = displayError or err end
    end
    if not shown and displayError ~= nil and not self.ErrorShown then
        self.ErrorShown = true
        show_message("สร้างตัวเลขลอยไม่สำเร็จ\n" .. tostring(displayError))
    end
    self.Snapshots[id] = current
end

function XaouDamage:Toggle()
    self.Enabled = not self.Enabled
    local state = self.Enabled and "เปิด" or "ปิด"
    show_message("ตัวเลขความเสียหาย: " .. state)
    return self.Enabled
end

function XaouDamage:RegisterEvent(eventValue, eventKey)
    if eventValue == nil then return end
    local events = GameMain:GetMod("_Event", true)
    if events == nil then return end
    events:RegisterEvent(eventValue, function(_, target, values)
        self:StartOrExtendBurst(target, values)
    end, eventKey)
end

function XaouDamage:OnEnter()
    self.Enabled = false
    self.Snapshots = {}
    self.Pending = {}
    self.Floaters = {}
    self.SnapshotTimer = 0
    self.Keys = {
        Hit = "XaouDamageNumbers_Hit",
        WillHit = "XaouDamageNumbers_WillHit",
        ThingHit = "XaouDamageNumbers_ThingHit",
        SelectNpc = "XaouDamageNumbers_SelectNpc"
    }

    self:RegisterEvent(g_emEvent.FightBodyBeHit, self.Keys.Hit)
    self:RegisterEvent(g_emEvent.WillFightBodyBeHit, self.Keys.WillHit)
    self:RegisterEvent(g_emEvent.ThingFightBodyBeHit, self.Keys.ThingHit)
    self:SnapshotAllNpcs()

    -- Controlled from Xaou Mod Center in the integrated build.
end

function XaouDamage:OnStep(dt)
    local step = tonumber(dt) or 0.016
    self:UpdateFloaters(step)

    for id, burst in pairs(self.Pending) do
        burst.delay = burst.delay - step
        if burst.delay <= 0 then
            self.Pending[id] = nil
            local ok, err = pcall(function() self:FinishBurst(id, burst) end)
            if not ok and not self.ErrorShown then
                self.ErrorShown = true
                show_message("แสดงตัวเลขดาเมจไม่สำเร็จ\n" .. tostring(err))
            end
        end
    end

    self.SnapshotTimer = self.SnapshotTimer - step
    if self.SnapshotTimer <= 0 then
        self.SnapshotTimer = SNAPSHOT_INTERVAL
        self:SnapshotAllNpcs()
    end
end

function XaouDamage:OnLeave()
    local events = GameMain:GetMod("_Event", true)
    if events ~= nil and self.Keys ~= nil then
        pcall(function() events:UnRegisterEvent(g_emEvent.FightBodyBeHit, self.Keys.Hit) end)
        pcall(function() events:UnRegisterEvent(g_emEvent.WillFightBodyBeHit, self.Keys.WillHit) end)
        pcall(function() events:UnRegisterEvent(g_emEvent.ThingFightBodyBeHit, self.Keys.ThingHit) end)
        pcall(function() events:UnRegisterEvent(g_emEvent.SelectNpc, self.Keys.SelectNpc) end)
    end
    for i = #self.Floaters, 1, -1 do
        local row = self.Floaters[i]
        pcall(function() row.label:RemoveFromParent(); row.label:Dispose() end)
    end
    self.Floaters = {}
end

function XaouDamage:NeedSyncData()
    return false
end
