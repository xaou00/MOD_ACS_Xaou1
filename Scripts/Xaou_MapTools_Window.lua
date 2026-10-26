-- Dedicated map management window from the existing XaoCtr package.

local XMAP_View = nil

local function child(view, name)
    local value = nil
    pcall(function() value = view:GetChild(name) end)
    return value
end

local function is_english()
    if Xaou_IsEnglish then return Xaou_IsEnglish() end
    return Xaou_ModCenter_Language == "en"
end

local function tr(thai, english)
    return is_english() and english or thai
end

local function set_text(object, value)
    if object == nil then return end
    pcall(function() object.text = tostring(value or "") end)
    pcall(function() object.title = tostring(value or "") end)
end

local function show_message(text)
    pcall(function() world:ShowMsgBox(tostring(text)) end)
end

local function read_no_fog()
    local value = Xaou_WorldToolsState and Xaou_WorldToolsState.NoFog == true
    pcall(function() value = CS.GameMain.Instance.NoFog == true end)
    if Xaou_WorldToolsState then Xaou_WorldToolsState.NoFog = value end
    return value
end

local function refresh(view, message)
    local no_fog = read_no_fog()
    set_text(child(view, "title"), tr("จัดการแผนที่", "Map Management"))
    set_text(child(view, "subtitle"), tr("ควบคุมหมอกและสถานที่บนแผนที่โลก", "Control fog and world-map locations"))
    set_text(child(view, "btnClose"), "×")
    set_text(child(view, "fogTitle"), tr("หมอกแผนที่", "Map Fog"))
    set_text(child(view, "fogDescription"), tr(
        "ปิดหมอกเพื่อมองเห็นพื้นที่บนแผนที่\nเปิดหมอกเพื่อกลับสู่การแสดงผลปกติ",
        "Disable fog to reveal the map.\nEnable fog to restore normal visibility."
    ))
    set_text(child(view, "fogStatus"), no_fog and tr("สถานะ: ปิดหมอก", "Status: Fog Off") or tr("สถานะ: เปิดหมอก", "Status: Fog On"))
    set_text(child(view, "btnFogToggle"), no_fog and tr("เปิดหมอก", "Enable Fog") or tr("ปิดหมอก", "Disable Fog"))
    set_text(child(view, "worldTitle"), tr("แผนที่โลก", "World Map"))
    set_text(child(view, "worldDescription"), tr(
        "เปิดสถานที่ทั้งหมดที่สามารถค้นพบบนแผนที่โลก",
        "Unlock every discoverable location on the world map."
    ))
    set_text(child(view, "btnUnlockMap"), tr("เปิดแผนที่ทั้งหมด", "Unlock All Locations"))
    set_text(child(view, "statusText"), message or tr("Xaou009 • ระบบจัดการแผนที่", "Xaou009 • Map Management"))
end

function Xaou_CloseMapToolsWindow()
    if XMAP_View ~= nil then
        pcall(function() XMAP_View:RemoveFromParent() end)
        pcall(function() XMAP_View:Dispose() end)
        XMAP_View = nil
    end
end

local function toggle_fog()
    local next_value = not read_no_fog()
    if Xaou_WorldTools_SetNoFog == nil then
        show_message(tr("ไม่พบระบบควบคุมหมอก", "Fog control system was not found"))
        return false
    end
    local ok, result = pcall(function() return Xaou_WorldTools_SetNoFog(next_value, true) end)
    if not ok or result == false then
        show_message(tr("เปลี่ยนสถานะหมอกไม่สำเร็จ", "Failed to change fog state") .. "\n" .. tostring(result))
        return false
    end
    refresh(XMAP_View, next_value and tr("ปิดหมอกแผนที่แล้ว", "Map fog disabled") or tr("เปิดหมอกแผนที่แล้ว", "Map fog enabled"))
    return true
end

local function unlock_map()
    if Xaou_WorldTools_UnlockMap == nil then
        show_message(tr("ไม่พบระบบเปิดแผนที่", "Map unlock system was not found"))
        return false
    end
    local ok, result = pcall(function() return Xaou_WorldTools_UnlockMap() end)
    if not ok or result == false then
        show_message(tr("เปิดแผนที่ไม่สำเร็จ", "Failed to unlock the map") .. "\n" .. tostring(result))
        return false
    end
    refresh(XMAP_View, tr("เปิดสถานที่ทั้งหมดบนแผนที่แล้ว", "All world-map locations unlocked"))
    return true
end

function Xaou_OpenMapToolsWindow()
    Xaou_CloseMapToolsWindow()
    local package = UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root = (GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if package == nil or root == nil then return false, "FairyGUI/GRoot not found" end

    pcall(function() package.AddPackage("UI/XaoCtr") end)
    local view = nil
    local ok, err = pcall(function()
        view = package.CreateObject("XaoCtr", "XaouMapToolsWindow")
    end)
    if not ok or view == nil then return false, tostring(err or "CreateObject returned nil") end

    XMAP_View = view
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2

    local close = child(view, "btnClose")
    if close then close.onClick:Add(Xaou_CloseMapToolsWindow) end
    local fog = child(view, "btnFogToggle")
    if fog then fog.onClick:Add(toggle_fog) end
    local unlock = child(view, "btnUnlockMap")
    if unlock then unlock.onClick:Add(unlock_map) end

    refresh(view)
    return true
end
