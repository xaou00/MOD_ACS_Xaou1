-- Unified Xaou item, world, climate and special-building menu.

local XWT_View = nil
local XWT_Section = "world"
local XWT_Item = nil

local sections = {
    climate = {
        title = "เวลา / ฤดูกาล / อากาศ",
        description = "เลือกช่วงเวลา หรือเปิดหน้าตั้งค่าฤดูกาลและสภาพอากาศ",
        actions = {
            {"ตอนเช้า", "time_morning"}, {"ตอนเที่ยง", "time_noon"},
            {"ตอนเย็น", "time_evening"}, {"ตอนกลางคืน", "time_night"},
            {"เลือกฤดูกาล", "open_season"}, {"เลือกสภาพอากาศ", "open_weather"},
        },
    },
    item = {
        title = "เครื่องมือไอเทม",
        description = "เลือกไอเทมบนพื้น แล้วเปิดเครื่องมือ Xaou เพื่อใช้งานคำสั่งเหล่านี้",
        actions = {
            {"คูณจำนวนไอเทม ×2", "item_double"},
            {"หลอมอสูร / เพิ่มระดับ", "item_youcui"},
            {"หลอมจิต", "item_lingcui"},
            {"เติมพลังวิญญาณเต็ม", "item_full_ling"},
            {"ทัณฑ์สวรรค์อาวุธเวท 36 ครั้ง", "item_tribulation"},
        },
    },
    world = {
        title = "เครื่องมือโลก",
        description = "ควบคุมแผนที่ หมอก และการเก็บของอัตโนมัติ",
        actions = {
            {"เปิด / ปิดเก็บเข้าคลังอัตโนมัติ", "toggle_auto"},
            {"สั่งเก็บเข้าคลังตอนนี้", "collect_now"},
        },
    },
    season = {
        title = "เลือกฤดูกาล",
        description = "เปลี่ยนวันของโลกไปยังช่วงต้นของฤดูกาลที่เลือก",
        actions = {
            {"ฤดูใบไม้ผลิ", "spring"}, {"ฤดูร้อน", "summer"},
            {"ฤดูใบไม้ร่วง", "autumn"}, {"ฤดูหนาว", "winter"},
        },
    },
    weather = {
        title = "เลือกสภาพอากาศ",
        description = "เปลี่ยนสภาพอากาศปัจจุบันด้วยระบบ BuildModeHelper ของเกม",
        actions = {
            {"อากาศปกติ", "weather_clear"}, {"ฝน / หิมะเบา", "weather_light"},
            {"ฝน / หิมะหนัก", "weather_heavy"}, {"พายุฝุ่น", "weather_dust"},
            {"กลางคืนถาวร", "weather_night"}, {"พายุสายฟ้า", "weather_lightning"},
        },
    },
    building = {
        title = "อาคารพิเศษ Xaou",
        description = "สร้างจากหมวด อาคารพิเศษ แล้วเลือกอาคารเพื่อใช้ปุ่มเฉพาะของมัน",
        actions = {
            {"เตาควบคุมอุณหภูมิ", "building_temp"},
            {"ค่ายกลถ่ายพลังวิญญาณ", "building_qi"},
        },
    },
}

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

function Xaou_CloseWorldToolsWindow()
    if XWT_View ~= nil then
        pcall(function() XWT_View:RemoveFromParent() end)
        pcall(function() XWT_View:Dispose() end)
        XWT_View = nil
    end
end

local function run(action)
    local item_actions = {
        item_double = "double", item_youcui = "youcui", item_lingcui = "lingcui",
        item_full_ling = "full_ling", item_tribulation = "tribulation",
    }
    if item_actions[action] then return Xaou_WorldTools_RunItem(item_actions[action], XWT_Item) end
    if action == "unlock_map" then return Xaou_WorldTools_UnlockMap() end
    if action == "toggle_fog" then return Xaou_WorldTools_ToggleFog() end
    if action == "toggle_auto" then return Xaou_WorldTools_ToggleAutoStorage() end
    if action == "collect_now" then return Xaou_WorldTools_CollectSpaceRingNow(false) end
    if action == "time_morning" then return Xaou_WorldTools_SetTime(5, "ตอนเช้า") end
    if action == "time_noon" then return Xaou_WorldTools_SetTime(11, "ตอนเที่ยง") end
    if action == "time_evening" then return Xaou_WorldTools_SetTime(17, "ตอนเย็น") end
    if action == "time_night" then return Xaou_WorldTools_SetTime(1, "ตอนกลางคืน") end
    if action == "spring" then return Xaou_WorldTools_SetSeason(14, "ฤดูใบไม้ผลิ") end
    if action == "summer" then return Xaou_WorldTools_SetSeason(42, "ฤดูร้อน") end
    if action == "autumn" then return Xaou_WorldTools_SetSeason(75, "ฤดูใบไม้ร่วง") end
    if action == "winter" then return Xaou_WorldTools_SetSeason(98, "ฤดูหนาว") end
    if action == "weather_clear" then return Xaou_WorldTools_SetWeather("Clear", "อากาศปกติ") end
    if action == "weather_light" then return Xaou_WorldTools_SetWeather("LightRain", "ฝนหรือหิมะเบา") end
    if action == "weather_heavy" then return Xaou_WorldTools_SetWeather("HeavyRain", "ฝนหรือหิมะหนัก") end
    if action == "weather_dust" then return Xaou_WorldTools_SetWeather("DustStorm", "พายุฝุ่น") end
    if action == "weather_night" then return Xaou_WorldTools_SetWeather("PermanentNight", "กลางคืนถาวร") end
    if action == "weather_lightning" then return Xaou_WorldTools_SetWeather("LightningStorm", "พายุสายฟ้า") end
    if action == "building_temp" then return show("สร้าง 'เตาควบคุมอุณหภูมิ' จากหมวดอาคารพิเศษ\nจากนั้นเลือกอาคารแล้วกด ตั้งอุณหภูมิ") end
    if action == "building_qi" then return show("สร้าง 'ค่ายกลถ่ายพลังวิญญาณ' จากหมวดอาคารพิเศษ\nเลือกอาคารแล้วกด รับพลัง หรือ เติมพลัง") end
end

local function refresh(view)
    local section = sections[XWT_Section] or sections.world
    set_text(child(view, "title"), "เครื่องมือโลกและไอเทม")
    set_text(child(view, "subtitle"), "เครื่องมือเสริมของ Xaou สำหรับระบบเดิมของเกม")
    set_text(child(view, "npcName"), XWT_Item and "กำลังจัดการไอเทมที่เลือก" or "เครื่องมือส่วนกลาง")
    set_text(child(view, "npcStatus"), "หมอก: " .. (Xaou_WorldToolsState.NoFog and "ปิด" or "เปิด") .. "  |  คลังอัตโนมัติ: " .. (Xaou_WorldToolsState.AutoStorage and "เปิด" or "ปิด"))
    set_text(child(view, "brand"), "ผู้พัฒนา: Xaou009")
    set_visible(child(view, "npcPortrait"), false)
    set_visible(child(view, "menuPanel"), false)
    set_visible(child(view, "menuQuick"), false)
    set_visible(child(view, "menuNpc"), false)
    set_visible(child(view, "menuBook"), false)
    set_visible(child(view, "menuWorld"), false)
    set_visible(child(view, "menuDeveloper"), false)
    set_text(child(view, "sectionTitle"), section.title)
    set_text(child(view, "description"), section.description)
    for i = 1, 8 do
        local button = child(view, "feature" .. tostring(i))
        local data = section.actions[i]
        set_visible(button, data ~= nil)
        if data ~= nil then set_text(button, data[1]) end
    end
    set_text(child(view, "btnLanguage"), "กลับ Mod Center")
end

function Xaou_OpenWorldToolsWindow(item, section)
    Xaou_CloseWorldToolsWindow()
    XWT_Item = item or Xaou_WorldToolsState.SelectedItem
    XWT_Section = section or "world"
    local pkg = UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root = (GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if pkg == nil or root == nil then return false, "FairyGUI/GRoot not found" end
    pcall(function() pkg.AddPackage("UI/XaoCtr") end)
    local view = nil
    local ok, err = pcall(function() view = pkg.CreateObject("XaoCtr", "XaouModCenterWindow") end)
    if not ok or view == nil then return false, tostring(err or "CreateObject returned nil") end
    XWT_View = view
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2

    local close = child(view, "btnClose"); if close then close.onClick:Add(Xaou_CloseWorldToolsWindow) end
    local menus = {{"menuQuick", "item"}, {"menuNpc", "world"}, {"menuBook", "season"}, {"menuWorld", "weather"}, {"menuDeveloper", "building"}}
    for _, data in ipairs(menus) do
        local section_key = data[2]
        local button = child(view, data[1])
        if button then button.onClick:Add(function() XWT_Section = section_key; refresh(view) end) end
    end
    for i = 1, 8 do
        local index = i
        local button = child(view, "feature" .. tostring(i))
        if button then button.onClick:Add(function()
            local current = sections[XWT_Section]
            local data = current and current.actions[index]
            if data then
                if data[2] == "open_season" then
                    XWT_Section = "season"
                elseif data[2] == "open_weather" then
                    XWT_Section = "weather"
                else
                    run(data[2])
                end
                refresh(view)
            end
        end) end
    end
    local back = child(view, "btnLanguage")
    if back then back.onClick:Add(function()
        Xaou_CloseWorldToolsWindow()
        if Xaou_OpenStandaloneModCenter then Xaou_OpenStandaloneModCenter(Xaou_CurrentNpcTarget) end
    end) end
    refresh(view)
    return true
end
