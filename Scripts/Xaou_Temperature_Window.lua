-- Temperature controller UI built from the standalone XaoCtr package.

local XTW_View = nil
local XTW_Target = nil
local XTW_Value = 20

local function child(view, name)
    local value = nil; pcall(function() value = view:GetChild(name) end); return value
end
local function set_text(obj, value)
    if obj == nil then return end
    if Xaou_LocalizeText then value = Xaou_LocalizeText(value) end
    pcall(function() obj.text = tostring(value or "") end)
    pcall(function() obj.title = tostring(value or "") end)
end
local function set_visible(obj, value)
    if obj == nil then return end
    pcall(function() obj.visible = value == true end)
    pcall(function() obj.touchable = value == true end)
end
local function show(text)
    if Xaou_LocalizeText then text = Xaou_LocalizeText(text) end
    pcall(function() world:ShowMsgBox(tostring(text)) end)
end

function Xaou_CloseTemperatureWindow()
    if XTW_View ~= nil then
        pcall(function() XTW_View:RemoveFromParent() end)
        pcall(function() XTW_View:Dispose() end)
        XTW_View = nil
    end
end

local function refresh(view)
    local actual = nil
    pcall(function() actual = XTW_Target:GetRoomTemperature() end)
    set_text(child(view, "title"), "เตาควบคุมอุณหภูมิ")
    set_text(child(view, "subtitle"), "กำหนดอุณหภูมิเป้าหมายของห้อง")
    set_text(child(view, "npcName"), "อุณหภูมิเป้าหมาย: " .. tostring(XTW_Value) .. "°C")
    set_text(child(view, "npcStatus"), "อุณหภูมิห้องนี้: " .. (actual and (tostring(math.floor(actual * 10 + 0.5) / 10) .. "°C") or "ยังอ่านไม่ได้") .. "  |  แต่ละห้องตั้งค่าแยกกัน")
    set_text(child(view, "brand"), "ระบบอาคาร Xaou009")
    set_visible(child(view, "npcPortrait"), false)
    set_text(child(view, "menuQuick"), "ลด 10°C")
    set_text(child(view, "menuNpc"), "ลด 1°C")
    set_text(child(view, "menuBook"), "เพิ่ม 1°C")
    set_text(child(view, "menuWorld"), "เพิ่ม 10°C")
    set_text(child(view, "menuDeveloper"), "คืนค่า 20°C")
    set_text(child(view, "sectionTitle"), "ค่าอุณหภูมิที่ใช้บ่อย")
    set_text(child(view, "description"), "เลือกค่าหรือปรับทีละองศา แล้วกดบันทึกค่า")
    local values = {-20, 0, 10, 20, 30, 40, 60}
    for i = 1, 7 do
        set_visible(child(view, "feature" .. tostring(i)), true)
        set_text(child(view, "feature" .. tostring(i)), tostring(values[i]) .. "°C")
    end
    set_visible(child(view, "feature8"), true)
    set_text(child(view, "feature8"), "บันทึกค่า " .. tostring(XTW_Value) .. "°C")
    set_text(child(view, "btnLanguage"), "ปิด")
end

function Xaou_OpenTemperatureWindow(target)
    Xaou_CloseTemperatureWindow()
    XTW_Target = target
    XTW_Value = tonumber(target and target.WenDu) or 20
    local pkg = UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root = (GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if pkg == nil or root == nil then return false end
    pcall(function() pkg.AddPackage("UI/XaoCtr") end)
    local view = nil
    local ok = pcall(function() view = pkg.CreateObject("XaoCtr", "XaouModCenterWindow") end)
    if not ok or view == nil then return false end
    XTW_View = view; root:AddChild(view)
    view.x = (root.width - view.width) / 2; view.y = (root.height - view.height) / 2
    local close = child(view, "btnClose"); if close then close.onClick:Add(Xaou_CloseTemperatureWindow) end
    local deltas = {{"menuQuick", -10}, {"menuNpc", -1}, {"menuBook", 1}, {"menuWorld", 10}}
    for _, data in ipairs(deltas) do
        local delta = data[2]
        local button = child(view, data[1])
        if button then button.onClick:Add(function() XTW_Value = XTW_Value + delta; refresh(view) end) end
    end
    local reset = child(view, "menuDeveloper"); if reset then reset.onClick:Add(function() XTW_Value = 20; refresh(view) end) end
    local values = {-20, 0, 10, 20, 30, 40, 60}
    for i = 1, 7 do
        local value = values[i]
        local button = child(view, "feature" .. tostring(i))
        if button then button.onClick:Add(function() XTW_Value = value; refresh(view) end) end
    end
    local save = child(view, "feature8")
    if save then save.onClick:Add(function()
        if XTW_Target == nil then show("ไม่พบอาคารเป้าหมาย"); return end
        XTW_Target:setWenDu(XTW_Value)
        show("ตั้งอุณหภูมิเป็น " .. tostring(XTW_Value) .. "°C แล้ว")
        Xaou_CloseTemperatureWindow()
    end) end
    local back = child(view, "btnLanguage"); if back then back.onClick:Add(Xaou_CloseTemperatureWindow) end
    refresh(view); return true
end
