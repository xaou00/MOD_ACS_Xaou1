-- Xaou 009 - selectable sect disciple capacity for ACS Mobile.

Xaou_SchoolCapacityState = Xaou_SchoolCapacityState or {
    Target = nil,
    Base = nil,
}

local XaouSchoolCapacity = GameMain:NewMod("Xaou_SchoolCapacity")
local CAPACITY_OPTIONS = { 20, 30, 40, 50, 60, 70, 80, 90 }

local function t(thai, english)
    if Xaou_IsEnglish and Xaou_IsEnglish() then return english end
    return thai
end

local function show(message)
    message = tostring(message or "")
    local ok = pcall(function()
        CS.Wnd_Message.Show(message, 1, nil, true, "Xaou 009", 0, 0, "")
    end)
    if not ok then pcall(function() world:ShowMsgBox(message) end) end
end

local function to_number(value)
    if value == nil then return nil end
    if type(value) == "number" then return value end
    local number = tonumber(value)
    if number ~= nil then return number end
    pcall(function() number = tonumber(value.value) end)
    if number ~= nil then return number end
    local text = nil
    pcall(function() text = value:ToString() end)
    text = text or tostring(value)
    return tonumber(string.match(text, "%-?%d+%.?%d*"))
end

local function select_index(result)
    if type(result) == "number" or type(result) == "string" then
        return to_number(result)
    end
    local count = nil
    pcall(function() count = to_number(result.Count) end)
    if count ~= nil and count > 0 then
        local value = nil
        pcall(function() value = result:get_Item(0) end)
        if value == nil then pcall(function() value = result[0] end) end
        return to_number(value)
    end
    return nil
end

local function school_values()
    local school = nil
    pcall(function() school = CS.XiaWorld.SchoolMgr.Instance end)
    if school == nil then return nil, nil, nil, "SchoolMgr.Instance is nil" end

    pcall(function() school:UpdateCount() end)
    local disciple_count, wait_receive, property_count, maximum = nil, nil, nil, nil
    pcall(function() disciple_count = to_number(school:GetSchoolData(g_emSchoolData.NumDisciple)) end)
    pcall(function() wait_receive = to_number(school:GetSchoolData(g_emSchoolData.WaitReceive)) end)
    pcall(function() property_count = to_number(school.DiscipleCount) end)
    pcall(function() maximum = to_number(school:GetDiscipleMax()) end)

    local active_count = disciple_count or property_count or 0
    local current = active_count + (wait_receive or 0)
    return school, current, maximum, nil
end

local function apply_capacity(target, saved_base)
    target = to_number(target)
    if target == nil or target < 1 then return false, "invalid target" end

    local school, current, old_max, school_error = school_values()
    if school == nil then return false, school_error end

    local runtime = nil
    pcall(function() runtime = CS.XiaWorld.RuntimeVar.Var end)
    if runtime == nil then return false, "RuntimeVar.Var is nil" end

    local old_scale = nil
    pcall(function() old_scale = to_number(runtime.SchoolNpcScale) end)
    if old_scale == nil or old_scale <= 0 then old_scale = 1 end

    local base = to_number(saved_base)
    if base == nil or base <= 0 then
        if old_max == nil or old_max <= 0 then return false, "GetDiscipleMax is invalid" end
        base = old_max / old_scale
    end
    if base <= 0 then return false, "base capacity is invalid" end

    local new_scale = (target + 0.001) / base
    local ok_set, set_error = pcall(function()
        runtime.SchoolNpcScale = new_scale
    end)
    if not ok_set then return false, tostring(set_error) end

    local actual = nil
    pcall(function() actual = to_number(school:GetDiscipleMax()) end)
    if actual ~= target then
        return false, "expected=" .. tostring(target) .. " actual=" .. tostring(actual)
    end

    Xaou_SchoolCapacityState.Target = target
    Xaou_SchoolCapacityState.Base = base
    return true, actual, current
end

function Xaou_SetSchoolCapacity(target)
    local _, current = school_values()
    target = to_number(target)
    if target == nil then
        show(t("ไม่สามารถอ่านจำนวนที่เลือกได้", "Could not read the selected capacity"))
        return false
    end
    if current ~= nil and target < current then
        show(t(
            "ตั้งค่าไม่ได้\nขณะนี้มีสมาชิกในสำนัก " .. tostring(current) .. " คน\nกรุณาเลือกจำนวนที่ไม่น้อยกว่านี้",
            "Cannot apply this capacity\nThe sect currently has " .. tostring(current) .. " members.\nChoose a value that is not lower."
        ))
        return false
    end

    local ok, actual_or_error = apply_capacity(target, Xaou_SchoolCapacityState.Base)
    if not ok then
        show(t("ตั้งค่าจำนวนศิษย์ไม่สำเร็จ\n", "Failed to set disciple capacity\n") .. tostring(actual_or_error))
        return false
    end
    show(t(
        "กำหนดจำนวนศิษย์สูงสุดเป็น " .. tostring(actual_or_error) .. " คนแล้ว",
        "Maximum disciple capacity is now " .. tostring(actual_or_error) .. "."
    ))
    return true
end

function Xaou_OpenSchoolCapacitySelector()
    local _, current, maximum, school_error = school_values()
    if maximum == nil then
        show(t("อ่านข้อมูลสำนักไม่สำเร็จ\n", "Failed to read sect data\n") .. tostring(school_error or "GetDiscipleMax is nil"))
        return false
    end

    local helper = nil
    pcall(function() helper = CS.WorldLuaHelper() end)
    if helper == nil or helper.ShowSelectBox == nil then
        show(t("ไม่พบหน้าต่างเลือกรายการ", "Selection window is unavailable"))
        return false
    end

    local choices = {}
    for _, value in ipairs(CAPACITY_OPTIONS) do
        choices[#choices + 1] = tostring(value) .. t(" คน", " disciples")
    end
    local prompt = t(
        "กำหนดจำนวนศิษย์สูงสุด\nปัจจุบัน: " .. tostring(current or "-") .. "/" .. tostring(maximum),
        "Set maximum disciple capacity\nCurrent: " .. tostring(current or "-") .. "/" .. tostring(maximum)
    )
    helper:ShowSelectBox(prompt, choices, 1, 1, function(result)
        local index = select_index(result)
        if index == nil then return end
        local selected = CAPACITY_OPTIONS[index + 1]
        if selected == nil then selected = CAPACITY_OPTIONS[index] end
        if selected ~= nil then Xaou_SetSchoolCapacity(selected) end
    end)
    return true
end

function XaouSchoolCapacity:OnEnter()
    if Xaou_SchoolCapacityState.Target ~= nil then
        pcall(apply_capacity, Xaou_SchoolCapacityState.Target, Xaou_SchoolCapacityState.Base)
    end
end

function XaouSchoolCapacity:OnSave()
    return {
        Target = Xaou_SchoolCapacityState.Target,
        Base = Xaou_SchoolCapacityState.Base,
    }
end

function XaouSchoolCapacity:OnLoad(data)
    data = data or {}
    Xaou_SchoolCapacityState.Target = to_number(data.Target)
    Xaou_SchoolCapacityState.Base = to_number(data.Base)
end

function XaouSchoolCapacity:OnAfterLoad()
    if Xaou_SchoolCapacityState.Target ~= nil then
        pcall(apply_capacity, Xaou_SchoolCapacityState.Target, Xaou_SchoolCapacityState.Base)
    end
end

function XaouSchoolCapacity:NeedSyncData() return false end
