-- ============================================================
-- XAOU NPC HELPER
-- ============================================================

function Xaou_Show(msg, title)
    if Xaou_LocalizeText then
        msg = Xaou_LocalizeText(msg)
        if title ~= nil then title = Xaou_LocalizeText(title) end
    end
    if world ~= nil and world.ShowMsgBox ~= nil then
        world:ShowMsgBox(tostring(msg), title or "Xaou")
    else
        print("[Xaou] " .. tostring(msg))
    end
end

-- ============================================================
-- V10.5.2 NPC CENTER - integrated target NPC system
-- ใช้กับปุ่ม NPC: Xaou_OpenNpcControl(bind)
-- ============================================================
Xaou_CurrentNpcTarget = Xaou_CurrentNpcTarget or nil

function Xaou_SafeNpcName(npc)
    if npc == nil then return "ยังไม่ได้เลือก NPC" end
    local ok, v = pcall(function()
        if npc.GetName ~= nil then return npc:GetName() end
        return nil
    end)
    if ok and v ~= nil and tostring(v) ~= "" then return tostring(v) end

    ok, v = pcall(function()
        if npc.Name ~= nil then return npc.Name end
        return nil
    end)
    if ok and v ~= nil and tostring(v) ~= "" then return tostring(v) end

    ok, v = pcall(function()
        if npc.def ~= nil and npc.def.ThingName ~= nil then return npc.def.ThingName end
        return nil
    end)
    if ok and v ~= nil and tostring(v) ~= "" then return tostring(v) end

    return tostring(npc)
end


function Xaou_GetRealNpcObject(npc)
    if npc == nil then return nil end

    -- บางปุ่มส่งตัว Wrapper เข้ามา ต้องลองหา object ตัวจริงหลายทาง
    local candidates = { npc }
    local function add(v)
        if v ~= nil then table.insert(candidates, v) end
    end

    local ok, v = pcall(function() return npc.npcObj end); if ok then add(v) end
    ok, v = pcall(function() return npc.NpcObj end); if ok then add(v) end
    ok, v = pcall(function() return npc.Npc end); if ok then add(v) end
    ok, v = pcall(function() return npc.npc end); if ok then add(v) end
    ok, v = pcall(function() return npc.thing end); if ok then add(v) end
    ok, v = pcall(function() return npc.bind end); if ok then add(v) end
    ok, v = pcall(function() return npc.obj end); if ok then add(v) end

    -- ถ้าตัวไหนมี PropertyMgr ให้ถือว่าตัวนั้นน่าใช้งานที่สุด
    for _, c in ipairs(candidates) do
        local ok2, pm = pcall(function() return c.PropertyMgr end)
        if ok2 and pm ~= nil then return c end
    end

    -- ถ้าเจอ ModifierProperty ตรง ๆ ก็ใช้ได้
    for _, c in ipairs(candidates) do
        local ok2, m = pcall(function() return c.ModifierProperty end)
        if ok2 and m ~= nil then return c end
    end

    return candidates[1]
end

function Xaou_TryModifierProperty(npc, prop, value)
    local realNpc = Xaou_GetRealNpcObject(npc)
    if realNpc == nil then
        return false, "หา NPC ตัวจริงไม่เจอ"
    end

    -- วิธีที่ม็อด PC ใช้จริง: npc.PropertyMgr:ModifierProperty(prop, value, 0, 0, 0)
    local ok, pm = pcall(function() return realNpc.PropertyMgr end)
    if ok and pm ~= nil then
        local ok2, err = pcall(function()
            pm:ModifierProperty(prop, value, 0, 0, 0)
        end)
        if ok2 then return true end

        -- fallback บาง runtime อาจรับแค่ 2 ค่า
        ok2, err = pcall(function()
            pm:ModifierProperty(prop, value)
        end)
        if ok2 then return true end
    end

    -- fallback: method อยู่บน npc โดยตรง
    local ok3, err3 = pcall(function()
        if realNpc.ModifierProperty == nil then error("no direct ModifierProperty") end
        realNpc:ModifierProperty(prop, value)
    end)
    if ok3 then return true end

    return false, "ไม่พบ/เรียก ModifierProperty ไม่สำเร็จ: " .. tostring(prop)
end

function Xaou_TryAddModifier(npc, id)
    local realNpc = Xaou_GetRealNpcObject(npc)
    if realNpc == nil then return false, "หา NPC ตัวจริงไม่เจอ" end

    local ok, err = pcall(function()
        if realNpc.AddModifier == nil then error("no AddModifier") end
        realNpc:AddModifier(id)
    end)
    if ok then return true end

    local ok2, pm = pcall(function() return realNpc.PropertyMgr end)
    if ok2 and pm ~= nil then
        local ok3, err3 = pcall(function()
            if pm.AddModifier == nil then error("no PropertyMgr.AddModifier") end
            pm:AddModifier(id)
        end)
        if ok3 then return true end
    end
    return false, "ไม่พบ/เรียก AddModifier ไม่สำเร็จ: " .. tostring(id)
end

function Xaou_TryBreakthroughNow(npc)
    local realNpc = Xaou_GetRealNpcObject(npc)
    if realNpc == nil then return false, "หา NPC ตัวจริงไม่เจอ" end

    local practice = nil
    local okPractice = pcall(function() practice = realNpc.PropertyMgr.Practice end)
    if not okPractice or practice == nil then
        return false, "NPC นี้ไม่มีระบบฝึกตน"
    end

    local neck = nil
    pcall(function() neck = practice.CurNeck end)
    if neck == nil then return false, "NPC ไม่มีขั้นถัดไปให้ทะลวง" end

    local kind = nil
    pcall(function() kind = neck.Kind end)
    if kind == CS.XiaWorld.g_emGongBottleNeckType.Die then
        return false, "คอขวดความตายไม่สามารถบังคับทะลวงได้"
    end

    local beforeStage, beforeTouch, beforeGod = nil, nil, nil
    pcall(function() beforeStage = practice.LogicStage end)
    pcall(function() beforeTouch = practice.TouchNeck == true end)
    pcall(function() beforeGod = practice.GodCount end)

    local result = false
    local okBreak, breakErr = pcall(function()
        result = practice:BrokenNeck(false) == true
    end)
    if not okBreak then return false, tostring(breakErr) end
    if not result then return false, "ระบบเกมปฏิเสธการทะลวงขั้น" end

    local afterStage, afterTouch, afterGod = nil, nil, nil
    pcall(function() afterStage = practice.LogicStage end)
    pcall(function() afterTouch = practice.TouchNeck == true end)
    pcall(function() afterGod = practice.GodCount end)
    if afterStage ~= beforeStage or afterTouch ~= beforeTouch or afterGod ~= beforeGod then
        return true, "ทะลวงขั้นสำเร็จ"
    end
    return false, "เกมตอบว่าสำเร็จแต่ไม่พบการเปลี่ยนขั้น"
end

function Xaou_BuildNpcDebugLines(npc)
    local lines = {}
    table.insert(lines, "NPC Debug")
    table.insert(lines, "ชื่อ: " .. Xaou_SafeNpcName(npc))
    if npc == nil then
        table.insert(lines, "ยังไม่มี target")
        return lines
    end

    local candidates = {
        {"target", function() return npc end},
        {"target.npcObj", function() return npc.npcObj end},
        {"target.NpcObj", function() return npc.NpcObj end},
        {"target.Npc", function() return npc.Npc end},
        {"target.npc", function() return npc.npc end},
        {"target.bind", function() return npc.bind end},
        {"target.thing", function() return npc.thing end},
        {"realNpc", function() return Xaou_GetRealNpcObject(npc) end},
    }

    for _, it in ipairs(candidates) do
        local name, fn = it[1], it[2]
        local ok, obj = pcall(fn)
        if ok and obj ~= nil then
            local hasPM = false
            local hasMod = false
            local hasAdd = false
            pcall(function() hasPM = obj.PropertyMgr ~= nil end)
            pcall(function() hasMod = obj.ModifierProperty ~= nil end)
            pcall(function() hasAdd = obj.AddModifier ~= nil end)
            table.insert(lines, name .. " = OK | PM:" .. tostring(hasPM) .. " | Mod:" .. tostring(hasMod) .. " | Add:" .. tostring(hasAdd))
        else
            table.insert(lines, name .. " = nil")
        end
    end
    return lines
end

function Xaou_RunRawCodeForNpc(npc, code)
    local realNpc = Xaou_GetRealNpcObject(npc)
    local me = realNpc or npc
    local src = tostring(code or "")
    if src == "" then return true end

    local fn = nil
    local err = nil

    if loadstring ~= nil then
        fn, err = loadstring(src)
    elseif load ~= nil then
        fn, err = load(src)
    else
        return false, "Lua runtime ไม่มี loadstring/load"
    end

    if fn == nil then
        return false, "compile raw lua ไม่สำเร็จ: " .. tostring(err)
    end

    -- ใส่ environment ให้ raw lua ใช้ me/world/story/GameMain ได้
    if setfenv ~= nil then
        local env = {}
        if _G ~= nil then
            setmetatable(env, { __index = _G })
        end
        env.me = me
        env.npc = me
        env.target = me
        env.realNpc = realNpc
        pcall(function() env.story = story end)
        setfenv(fn, env)
    end

    local ok, runErr = pcall(fn)
    if not ok then
        return false, tostring(runErr)
    end
    return true
end

function Xaou_ActionMessage(text, title)
    Xaou_Show(tostring(text or ""), title or "Xaou")
    return true
end

function Xaou_OpenUrl(url)
    local ok = pcall(function()
        if CS ~= nil and CS.UnityEngine ~= nil and CS.UnityEngine.Application ~= nil then
            CS.UnityEngine.Application.OpenURL(tostring(url))
        elseif UnityEngine ~= nil and UnityEngine.Application ~= nil then
            UnityEngine.Application.OpenURL(tostring(url))
        else
            error("Application.OpenURL not found")
        end
    end)
    return ok, ok and nil or "เปิด URL ไม่สำเร็จ"
end
