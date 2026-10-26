-- ============================================================
-- XAOU NPC ACTIONSห
-- ============================================================

function Xaou_ApplyNpcActions(npc, actions)
    if npc == nil then
        Xaou_Show("ยังไม่ได้เลือก NPC\nให้กดปุ่มจากตัวละคร/NPC ก่อน", "NPC")
        return false, "ยังไม่ได้เลือก NPC"
    end

    if type(actions) ~= "table" then return false, "ข้อมูลคำสั่งไม่ถูกต้อง" end

    local ok, err = pcall(function()
        for _, a in ipairs(actions) do
            local kind = tostring(a.kind or "")

            if kind == "modifier" then
                local ok2, err2 = Xaou_TryModifierProperty(npc, a.prop, a.value)
                if not ok2 then error(err2) end

            elseif kind == "addmodifier" then
                local ok2, err2 = Xaou_TryAddModifier(npc, a.id or a.modifier)
                if not ok2 then error(err2) end

            elseif kind == "breakthrough" then
                local ok2, err2 = Xaou_TryBreakthroughNow(npc)
                if not ok2 then error(err2) end

            elseif kind == "story" then
                local realNpc = Xaou_GetRealNpcObject(npc)
                local ok2, err2 = pcall(function()
                    if realNpc == nil then error("NPC not found") end
                    if CS == nil or CS.XiaWorld == nil or CS.XiaWorld.NpcLuaHelper == nil then
                        error("NpcLuaHelper not found")
                    end
                    local helper = CS.XiaWorld.NpcLuaHelper(realNpc)
                    if helper == nil then error("NpcLuaHelper returned nil") end
                    helper:TriggerStory(tostring(a.story or a.name or ""))
                end)
                if not ok2 then error(err2) end

            elseif kind == "raw" or kind == "lua" then
                local ok2, err2 = Xaou_RunRawCodeForNpc(npc, a.code)
                if not ok2 then error(err2) end

            elseif kind == "message" then
                Xaou_ActionMessage(a.text, a.title)

            elseif kind == "url" then
                local ok2, err2 = Xaou_OpenUrl(a.url)
                if not ok2 then error(err2) end

            elseif kind == "unlockgong" then
                local ok2, err2 = pcall(function()
                    local realNpc = Xaou_GetRealNpcObject(npc)
                    if realNpc ~= nil and realNpc.UnLockGong ~= nil then
                        realNpc:UnLockGong(tostring(a.gong or a.id))
                    else
                        world:UnLockGong(tostring(a.gong or a.id))
                    end
                end)
                if not ok2 then error(err2) end


            elseif kind == "randomgong" then                                                                                        -- เพิ่มฟังชั่น --
                local level = tonumber(a.level or 4) or 4
                local times = tonumber(a.times or 1) or 1
                local ok2, err2 = pcall(function()
                    for i = 1, times do
                        world:UnlockRandomGong(level)
                    end
                end)
                if not ok2 then error(err2) end

            elseif kind == "changetime" then
                local h = tonumber(a.hour or a.value or 11) or 11
                local ok2, err2 = pcall(function()
                    local helper = GameMain:GetMod("BuildModeHelper")
                    if helper == nil then error("BuildModeHelper not found") end
                    helper:ChangeTime(h)
                end)
                if not ok2 then error(err2) end

            elseif kind == "changeweather" then
                local weather = tostring(a.weather or a.value or "HarvestAir")
                local ok2, err2 = pcall(function()
                    local helper = GameMain:GetMod("BuildModeHelper")
                    if helper == nil or helper.ChangeWeather == nil then error("BuildModeHelper.ChangeWeather not found") end
                    helper:ChangeWeather(weather)
                end)
                if not ok2 then error(err2) end

            elseif kind == "enter_qiankun" then
                local realNpc = Xaou_GetRealNpcObject(npc)
                local ok2, err2 = pcall(function()
                    RPGMapMgr:EnterRPGWorld({realNpc.npcObj or realNpc}, "RpgQianKun")
                end)
                if not ok2 then error(err2) end

            elseif kind == "openheartseed" then
                local ok2 = Xaou_OpenHeartBySeed(a.seed, a.favor == true)
                if not ok2 then error("เปิดใจ NPC สำนักอื่นไม่สำเร็จ") end

            elseif kind == "jhinfo" then
                Xaou_JHShowInfo(a.seed)

            elseif kind == "modfunc" then
                local ok2, err2 = pcall(function()
                    local mod = GameMain:GetMod(tostring(a.mod or "Xaou009_ACS_Mod"))
                    if mod == nil then error("ไม่พบ Mod: " .. tostring(a.mod)) end
                    local fn = mod[tostring(a.func or "")]
                    if fn == nil then error("ไม่พบฟังก์ชัน: " .. tostring(a.func)) end
                    fn(mod)
                end)
                if not ok2 then error(err2) end

            else
                error("ไม่รู้จัก action kind: " .. tostring(kind))
            end
        end
    end)

    if not ok then
        return false, tostring(err)
    end
    return true, "ใช้คำสั่งสำเร็จ " .. tostring(#actions) .. " รายการ"
end



-- ปลดล็อกวิชาหลักทั้งหมด (ย้ายมาจากไฟล์หลัก)
function Xaou_UnlockAllMainGong(npc)
    local me = npc or Xaou_CurrentNpcTarget
    if me == nil then return false end

    local gongs = {
        "Gong_1_Shui","Gong_2_Mu","Gong_3_Jin","Gong_4_None",
        "Gong_5_Tu","Gong_6_Huo","Gong_7_Huo","Gong_8_Jin",
        "Gong_9_Mu","Gong_10_Huo","Gong_11_Tu","Gong_12_None",
        "Gong_13_None","Gong_DaNeng","Gong_LingShou","Gong_LOST",
        "Gong_YaoShou","God_Gong_1","God_Gong_2","God_Gong_3",
        "Body_Gong_1","Body_Gong_2","Body_Gong_3","Body_Gong_5"
    }
    

    for _, id in ipairs(gongs) do
        pcall(function()
            me:UnLockGong(id)
        end)
    end

    Xaou_Show("ปลดล็อกวิชาสายหลักทั้งหมดแล้ว", "NPC")
    return true
end


-- ============================================================
-- Jianghu NPC / ระบบเปิดใจ NPC สำนักอื่น
-- ใช้ flow เดียวกับ Magic_BrokeHeartLock เพื่อให้ KnowNpcData และ event ของเกมครบ
-- ============================================================
function Xaou_OpenHeartBySeed(seed, addFavor)
    local ok, err = pcall(function()
        if seed == nil then error("seed ว่าง") end
        seed = tonumber(seed) or seed

        JianghuMgr:AddKnowNpcData(seed)
        local JHData = JianghuMgr:GetKnowNpcData(seed)

        if JHData == nil then
            error("หา/สร้าง KnowNpcData ไม่สำเร็จ")
        end

        JHData:UnlockHeart()

        if addFavor == true then
            local current = tonumber(JHData.favour) or 0
            local delta = 100 - current
            if delta > 0 then
                local added = false
                pcall(function()
                    JianghuMgr:AddKnowNpcData(seed, CS.XiaWorld.g_emJHNpcDataType.None, delta, nil)
                    added = true
                end)
                if not added then JHData.favour = 100 end
            end
        end
    end)

    if ok then
        Xaou_Show("เปิดใจ NPC สำนักอื่นสำเร็จ", "Jianghu NPC")
        return true
    else
        Xaou_Show("เปิดใจไม่สำเร็จ:\n" .. tostring(err), "Jianghu NPC")
        return false
    end
end

function Xaou_JHShowInfo(seed)
    local ok, err = pcall(function()
        local def = JianghuMgr:GetJHNpcDataByRandomSeed(seed)
        local data = JianghuMgr:GetKnowNpcData(seed)
        local name = "ไม่ทราบชื่อ"
        if def ~= nil then
            name = tostring(def.LastName or "") .. tostring(def.FristName or def.FirstName or "")
        end
        local fav = "-"
        local vig = "-"
        local hlock = "-"
        if data ~= nil then
            fav = tostring(data.favour)
            vig = tostring(data.Vigilance)
            hlock = tostring(data.hlock)
        end
        Xaou_Show("ชื่อ: "..name.."\nseed: "..tostring(seed).."\nความชอบ: "..fav.."\nระแวง: "..vig.."\nเปิดใจ(hlock): "..hlock, "ข้อมูล NPC สำนักอื่น")
    end)
    if not ok then Xaou_Show("ดูข้อมูลไม่ได้:\n"..tostring(err), "Jianghu NPC") end
end
