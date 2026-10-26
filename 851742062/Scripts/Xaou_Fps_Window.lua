-- Xaou mobile frame-rate selector. Rendering only; gameplay timing is untouched.

local XFPS_View = nil
Xaou_FpsTarget = Xaou_FpsTarget or -1
Xaou_ActualFps = Xaou_ActualFps or 0

local function child(view, name)
    local value = nil
    pcall(function() value = view:GetChild(name) end)
    return value
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

local function read_target()
    local value = Xaou_FpsTarget
    pcall(function() value = tonumber(CS.UnityEngine.Application.targetFrameRate) or value end)
    return value
end

local function apply_fps(value)
    value = tonumber(value) or -1
    -- Android controls presentation timing through targetFrameRate. Some mobile
    -- XLua builds do not export QualitySettings.vSyncCount at all, so it must
    -- never be allowed to block the actual frame-rate request.
    pcall(function() CS.UnityEngine.QualitySettings.vSyncCount = 0 end)

    local ok, err = pcall(function()
        CS.UnityEngine.Application.targetFrameRate = value
    end)
    if not ok then
        ok, err = pcall(function()
            CS.UnityEngine.Application.set_targetFrameRate(value)
        end)
    end
    if ok then Xaou_FpsTarget = value end
    return ok, err
end

function Xaou_ApplyFpsTarget()
    return apply_fps(Xaou_FpsTarget)
end

function Xaou_CloseFpsWindow()
    if XFPS_View ~= nil then
        pcall(function() XFPS_View:RemoveFromParent() end)
        pcall(function() XFPS_View:Dispose() end)
        XFPS_View = nil
    end
end

local function target_label(value)
    if tonumber(value) == nil or tonumber(value) < 0 then
        return Xaou_T and Xaou_T("อัตโนมัติ", "Automatic") or "อัตโนมัติ"
    end
    return tostring(value) .. " FPS"
end

local function refresh(view)
    local current = read_target()
    local measured = tonumber(Xaou_ActualFps) or 0
    set_text(child(view, "title"), "ตั้งค่าเฟรมเรต")
    set_text(child(view, "subtitle"), "กำหนดอัตราเฟรมสำหรับหน้าจอมือถือ")
    set_text(child(view, "npcName"), "เฟรมเรตเป้าหมาย: " .. target_label(current))
    local measuredText = measured > 0 and (string.format("%.1f FPS", measured)) or (Xaou_T and Xaou_T("กำลังวัด...", "Measuring...") or "กำลังวัด...")
    set_text(child(view, "npcStatus"), "เฟรมเรตที่วัดจริง: " .. measuredText .. "  |  ค่าจริงขึ้นอยู่กับจอและอุปกรณ์")
    set_text(child(view, "brand"), "ผู้พัฒนา: Xaou009")
    set_visible(child(view, "npcPortrait"), false)

    set_text(child(view, "menuQuick"), "▶ เฟรมเรต")
    set_text(child(view, "menuNpc"), "ประหยัดพลังงาน")
    set_text(child(view, "menuBook"), "สมดุล")
    set_text(child(view, "menuWorld"), "ลื่นไหล")
    set_text(child(view, "menuDeveloper"), "สูงสุด")

    set_text(child(view, "sectionTitle"), "เลือกเฟรมเรต")
    set_text(child(view, "description"), "การตั้งค่านี้ไม่เปลี่ยนความเร็วเวลาและระบบฟิสิกส์ของเกม")
    local options = {
        {30, "30 FPS"}, {60, "60 FPS"}, {90, "90 FPS"}, {120, "120 FPS"},
        {-1, "อัตโนมัติ"},
    }
    for i = 1, 8 do
        local button = child(view, "feature" .. tostring(i))
        local option = options[i]
        set_visible(button, option ~= nil)
        if option ~= nil then
            local selected = tonumber(current) == option[1]
            set_text(button, (selected and "▶ " or "") .. option[2])
        end
    end
    set_text(child(view, "btnLanguage"), "กลับ Mod Center")
end

function Xaou_RefreshFpsDisplay()
    if XFPS_View ~= nil then refresh(XFPS_View) end
end

function Xaou_OpenFpsWindow()
    Xaou_CloseFpsWindow()
    local pkg = UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root = (GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if pkg == nil or root == nil then return false, "FairyGUI/GRoot not found" end
    pcall(function() pkg.AddPackage("UI/XaoCtr") end)
    local view = nil
    local ok, err = pcall(function() view = pkg.CreateObject("XaoCtr", "XaouModCenterWindow") end)
    if not ok or view == nil then return false, tostring(err or "CreateObject returned nil") end
    XFPS_View = view
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2

    local options = {30, 60, 90, 120, -1}
    for i, value in ipairs(options) do
        local fps = value
        local button = child(view, "feature" .. tostring(i))
        if button ~= nil then button.onClick:Add(function()
            local applied, applyError = apply_fps(fps)
            if not applied then
                local message = "ตั้งค่าเฟรมเรตไม่สำเร็จ\n" .. tostring(applyError)
                if Xaou_LocalizeText then message = Xaou_LocalizeText(message) end
                pcall(function() world:ShowMsgBox(message) end)
            end
            refresh(view)
        end) end
    end

    local close = child(view, "btnClose")
    if close ~= nil then close.onClick:Add(Xaou_CloseFpsWindow) end
    local back = child(view, "btnLanguage")
    if back ~= nil then back.onClick:Add(function()
        Xaou_CloseFpsWindow()
        if Xaou_OpenStandaloneModCenter then Xaou_OpenStandaloneModCenter(Xaou_CurrentNpcTarget) end
    end) end
    refresh(view)
    return true
end
