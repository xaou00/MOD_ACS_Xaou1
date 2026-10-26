-- Xaou world and item tools. Player-facing APIs only; no probe code.

Xaou_WorldToolsState = Xaou_WorldToolsState or {
    AutoStorage = false,
    NoFog = false,
    SelectedItem = nil,
}

local XaouWorldTools = GameMain:NewMod("Xaou_WorldTools")

local function show(text)
    if Xaou_LocalizeText then text = Xaou_LocalizeText(text) end
    pcall(function() world:ShowMsgBox(tostring(text or "")) end)
end

local function csharp_count(list)
    if list == nil then return 0 end
    local count = 0
    pcall(function() count = tonumber(list.Count) or 0 end)
    return count
end

local function csharp_item(list, index)
    local value = nil
    pcall(function() value = list:get_Item(index) end)
    if value == nil then pcall(function() value = list[index] end) end
    return value
end

local function item_name(item)
    local name = "ไอเทม"
    pcall(function() name = tostring(item:GetName()) end)
    return name
end

local function item_count(item)
    if item == nil then return 0 end
    local count = nil
    pcall(function() count = tonumber(item.Count) end)
    if count == nil or count < 1 then
        pcall(function() count = tonumber(item.FreeCount) end)
    end
    return count or 0
end

local function run_item(item, action)
    if item == nil then return false, "กรุณาเลือกไอเทมบนพื้นก่อน" end

    if action == "double" then
        local count = item_count(item)
        if count < 1 then return false, "ไม่สามารถอ่านจำนวนของไอเทมนี้ได้" end

        -- Mobile XLua can expose callable methods through ':' while a field lookup
        -- such as item.ChangeCount still returns nil. Invoke it directly instead.
        local ok, err = pcall(function() item:ChangeCount(count * 2) end)
        if not ok then
            ok, err = pcall(function() item:ChangeCount(count * 2, false) end)
        end
        if not ok then
            return false, "เพิ่มจำนวนไอเทมไม่สำเร็จ\n" .. tostring(err)
        end
        return true, "คูณจำนวนไอเทม ×2 สำเร็จ\n" .. item_name(item)
    end

    if action == "youcui" then
        if item.SoulCrystalYouPowerUp == nil then return false, "ไอเทมนี้ไม่รองรับการหลอมอสูร" end
        if item.Rate ~= nil and tonumber(item.Rate) >= 12 then return false, "ไอเทมอยู่ระดับสูงสุดแล้ว" end
        item:SoulCrystalYouPowerUp(100)
        return true, "หลอมอสูรสำเร็จ\n" .. item_name(item)
    end

    if action == "lingcui" then
        if item.SoulCrystalLingPowerUp == nil then return false, "ไอเทมนี้ไม่รองรับการหลอมจิต" end
        item:SoulCrystalLingPowerUp(100)
        return true, "หลอมจิตสำเร็จ\n" .. item_name(item)
    end

    if action == "full_ling" then
        if item.AddLing == nil or item.MaxLing == nil or item.LingV == nil then
            return false, "ไอเทมนี้ไม่มีช่องเก็บพลังวิญญาณ"
        end
        local need = math.max(0, (tonumber(item.MaxLing) or 0) - (tonumber(item.LingV) or 0))
        item:AddLing(need)
        return true, "เติมพลังวิญญาณเต็มแล้ว\n" .. item_name(item)
    end

    if action == "tribulation" then
        if item.Fabao == nil or item.Fabao.AddGodCount == nil then
            return false, "ใช้ได้เฉพาะอาวุธเวทเท่านั้น"
        end
        for _ = 1, 36 do item.Fabao:AddGodCount(1) end
        return true, "รับทัณฑ์สวรรค์ 36 ครั้งสำเร็จ\n" .. item_name(item)
    end

    return false, "ไม่พบคำสั่งไอเทม"
end

function Xaou_WorldTools_RunItem(action, item)
    item = item or Xaou_WorldToolsState.SelectedItem
    local ok, success, message = pcall(function()
        local result, reason = run_item(item, action)
        return result, reason
    end)
    if not ok then show("ทำรายการไม่สำเร็จ\n" .. tostring(success)); return false end
    show(message)
    return success == true
end

function Xaou_WorldTools_UnlockMap()
    local ok, err = pcall(function() CS.XiaWorld.PlacesMgr.Instance:UnlockAll() end)
    show(ok and "เปิดสถานที่ทั้งหมดบนแผนที่แล้ว" or ("เปิดแผนที่ไม่สำเร็จ\n" .. tostring(err)))
    return ok
end

function Xaou_WorldTools_SetNoFog(enabled, quiet)
    enabled = enabled == true
    local ok, err = pcall(function()
        CS.GameMain.Instance.NoFog = enabled
        if CS.MapRender.Instance ~= nil and CS.MapRender.Instance.Fog ~= nil then
            CS.MapRender.Instance.Fog.enabled = not enabled
        end
        Xaou_WorldToolsState.NoFog = enabled
    end)
    if quiet ~= true then
        show(ok and (enabled and "ปิดหมอกแผนที่แล้ว" or "เปิดหมอกแผนที่แล้ว") or ("เปลี่ยนหมอกไม่สำเร็จ\n" .. tostring(err)))
    end
    return ok
end

function Xaou_WorldTools_ToggleFog()
    return Xaou_WorldTools_SetNoFog(not Xaou_WorldToolsState.NoFog)
end

function Xaou_WorldTools_SetTime(hour, label)
    local value = tonumber(hour) or 6
    local ok, err = pcall(function()
        local helper = GameMain:GetMod("BuildModeHelper")
        if helper == nil then error("BuildModeHelper not found") end
        helper:ChangeTime(value)
    end)
    show(ok and ("เปลี่ยนเวลาเป็น" .. tostring(label or value) .. "แล้ว") or ("เปลี่ยนเวลาไม่สำเร็จ\n" .. tostring(err)))
    return ok
end

function Xaou_WorldTools_SetSeason(day, label)
    local ok, err = pcall(function()
        local helper = GameMain:GetMod("BuildModeHelper")
        if helper == nil or helper.ChangeDay == nil then error("ไม่พบ BuildModeHelper.ChangeDay") end
        helper:ChangeDay(tonumber(day))
    end)
    show(ok and ("เปลี่ยนเป็น" .. tostring(label or "ฤดูกาลที่เลือก") .. "แล้ว") or ("เปลี่ยนฤดูกาลไม่สำเร็จ\n" .. tostring(err)))
    return ok
end

function Xaou_WorldTools_SetWeather(weather, label)
    local ok, err = pcall(function()
        if weather == "Clear" then
            World.Weather:ClearAllWeather()
        else
            local helper = GameMain:GetMod("BuildModeHelper")
            if helper == nil or helper.ChangeWeather == nil then error("ไม่พบ BuildModeHelper.ChangeWeather") end
            helper:ChangeWeather(tostring(weather))
        end
    end)
    show(ok and ("เปลี่ยนสภาพอากาศเป็น" .. tostring(label or weather) .. "แล้ว") or ("เปลี่ยนสภาพอากาศไม่สำเร็จ\n" .. tostring(err)))
    return ok
end

local function find_sleeve_building()
    local list = nil
    pcall(function() list = CS.XiaWorld.ThingMgr.Instance:GetThingList(CS.XiaWorld.g_emThingType.Building) end)
    if list == nil then pcall(function() list = ThingMgr:GetThingList(g_emThingType.Building) end) end
    for i = 0, csharp_count(list) - 1 do
        local building = csharp_item(list, i)
        local def_name = nil
        pcall(function() def_name = tostring(building.def.Name) end)
        if def_name == "Building_SleeveSpace" then return building end
    end
    return nil
end

function Xaou_WorldTools_CollectSpaceRingNow(quiet)
    local building = find_sleeve_building()
    if building == nil then
        if not quiet then show("ไม่พบอาคารจักรวาลย่อส่วนที่กำลังทำงาน") end
        return false
    end
    local working = false
    pcall(function() working = building.BuildingState == g_emBuildingState.Working end)
    if not working then
        if not quiet then show("อาคารจักรวาลย่อส่วนยังไม่ทำงาน") end
        return false
    end
    local key = nil
    pcall(function() key = building.Key end)
    local ok, err = pcall(function() Map:CollectToRemoteStorage(key) end)
    if not quiet then show(ok and "สั่งเก็บของเข้าคลังจักรวาลแล้ว" or ("เก็บของอัตโนมัติไม่สำเร็จ\n" .. tostring(err))) end
    return ok
end

function Xaou_WorldTools_ToggleAutoStorage()
    Xaou_WorldToolsState.AutoStorage = not Xaou_WorldToolsState.AutoStorage
    if Xaou_WorldToolsState.AutoStorage then Xaou_WorldTools_CollectSpaceRingNow(true) end
    show(Xaou_WorldToolsState.AutoStorage and "เปิดเก็บของเข้าคลังจักรวาลอัตโนมัติแล้ว" or "ปิดเก็บของอัตโนมัติแล้ว")
    return Xaou_WorldToolsState.AutoStorage
end

function Xaou_WorldTools_OpenForItem(item)
    Xaou_WorldToolsState.SelectedItem = item
    if Xaou_OpenWorldToolsWindow ~= nil then return Xaou_OpenWorldToolsWindow(item, "item") end
    show("ยังไม่พบหน้าต่างเครื่องมือโลก")
    return false
end

function XaouWorldTools:AddItemButton(item)
    if item == nil then return end
    local is_item = false
    pcall(function() is_item = item.ThingType == g_emThingType.Item end)
    if not is_item then return end
    pcall(function() item:RemoveBtnData("คูณ2") end)
    item:AddBtnData(
        "คูณ2",
        "res/Sprs/ui/icon_hand",
        "Xaou_WorldTools_OpenForItem(bind)",
        "คูณ หลอม เติมพลัง และเพิ่มทัณฑ์สวรรค์ให้ไอเทมที่เลือก",
        nil
    )
end

function XaouWorldTools:OnEnter()
    self._autoTimer = 0
    local event = GameMain:GetMod("_Event")
    if event ~= nil then
        event:RegisterEvent(g_emEvent.SelectItem, function(_, item)
            Xaou_WorldToolsState.SelectedItem = item
            self:AddItemButton(item)
        end, "Xaou_WorldTools_SelectItem")
    end
    if Xaou_WorldToolsState.NoFog then Xaou_WorldTools_SetNoFog(true, true) end
end

function XaouWorldTools:OnStep(dt)
    if not Xaou_WorldToolsState.AutoStorage then return end
    self._autoTimer = (self._autoTimer or 0) + (tonumber(dt) or 0)
    if self._autoTimer < 2 then return end
    self._autoTimer = 0
    Xaou_WorldTools_CollectSpaceRingNow(true)
end

function XaouWorldTools:OnSave()
    return { AutoStorage = Xaou_WorldToolsState.AutoStorage == true, NoFog = Xaou_WorldToolsState.NoFog == true }
end

function XaouWorldTools:OnLoad(data)
    data = data or {}
    Xaou_WorldToolsState.AutoStorage = data.AutoStorage == true
    Xaou_WorldToolsState.NoFog = data.NoFog == true
end

function XaouWorldTools:OnAfterLoad()
    if Xaou_WorldToolsState.NoFog then Xaou_WorldTools_SetNoFog(true, true) end
end

function XaouWorldTools:NeedSyncData() return false end
