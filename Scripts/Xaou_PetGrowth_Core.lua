-- Xaou 009 instant pet growth. Uses the game's persisted age/growth APIs.

local function xpg_t(thai, english)
    if Xaou_IsEnglish and Xaou_IsEnglish() then return english end
    return thai
end

local function xpg_message(thai, english)
    local message = xpg_t(thai, english)
    if world and world.ShowMsgBox then
        pcall(function() world:ShowMsgBox(message) end)
        return
    end
    pcall(function() CS.Wnd_Message.Show(message) end)
end

local function xpg_real_npc(target)
    if target == nil then return nil end
    if Xaou_GetRealNpcObject then
        local ok, value = pcall(function() return Xaou_GetRealNpcObject(target) end)
        if ok and value ~= nil then return value end
    end
    local real = target
    pcall(function()
        if target.npcObj ~= nil then real = target.npcObj end
    end)
    return real
end

local function xpg_is_animal(npc)
    if npc == nil then return false end
    local isLingShou = false
    pcall(function() isLingShou = npc.IsLingShou == true end)
    if isLingShou then return true end

    local raceType = nil
    pcall(function() raceType = npc.Race.RaceType end)
    if raceType == nil then return false end

    local animalEnum = nil
    pcall(function() animalEnum = g_emNpcRaceType.Animal end)
    if animalEnum == nil then
        pcall(function() animalEnum = CS.XiaWorld.g_emNpcRaceType.Animal end)
    end
    if animalEnum ~= nil and raceType == animalEnum then return true end

    local text = string.lower(tostring(raceType or ""))
    return text == "animal" or string.find(text, "animal", 1, true) ~= nil
end

function Xaou_InstantGrowPet(target)
    local npc = xpg_real_npc(target)
    if npc == nil then
        xpg_message("กรุณาเลือกสัตว์เลี้ยงก่อน", "Please select a pet first")
        return false, "no target"
    end
    if not xpg_is_animal(npc) then
        xpg_message("เป้าหมายนี้ไม่ใช่สัตว์เลี้ยง", "The selected target is not a pet")
        return false, "not an animal"
    end

    local isLingShou = false
    pcall(function() isLingShou = npc.IsLingShou == true end)

    if isLingShou then
        local before = nil
        local okRead, readError = pcall(function()
            before = tonumber(npc.LsInfo.GrowPercent)
        end)
        if not okRead or before == nil then
            xpg_message("อ่านค่าการเติบโตของสัตว์วิญญาณไม่ได้", "Could not read spirit pet growth")
            return false, readError
        end
        if before >= 100 then
            xpg_message("สัตว์เลี้ยงโตเต็มวัยอยู่แล้ว", "This pet is already fully grown")
            return true, "already adult"
        end

        local okGrow, growError = pcall(function()
            npc.LsInfo:AddP(npc, "GrowPercent", 100 - before)
        end)
        if not okGrow then
            xpg_message("ทำให้สัตว์วิญญาณโตไม่สำเร็จ", "Failed to grow the spirit pet")
            return false, growError
        end

        pcall(function() npc:RefreshLsPExtra("GrowPercent", 100, true) end)
        pcall(function()
            if npc.view ~= nil then npc.view.needUpdateMod = true end
        end)
        pcall(function() EventMgr.Instance:EventTrigger(g_emEvent.ThingUpdate, npc) end)
        xpg_message("สัตว์เลี้ยงโตเต็มวัยแล้ว", "Pet growth completed")
        return true, "spirit pet", before, 100
    end

    local age, adultAge = nil, nil
    local okRead, readError = pcall(function()
        age = tonumber(npc.PropertyMgr.Age)
        adultAge = tonumber(npc.Race.AdultAge)
    end)
    if not okRead or age == nil or adultAge == nil or adultAge <= 0 then
        xpg_message("อ่านข้อมูลอายุของสัตว์เลี้ยงไม่ได้", "Could not read the pet age")
        return false, readError
    end
    if age >= adultAge then
        xpg_message("สัตว์เลี้ยงโตเต็มวัยอยู่แล้ว", "This pet is already fully grown")
        return true, "already adult"
    end

    local okGrow, growError = pcall(function()
        npc.PropertyMgr:AddAge(adultAge - age, false)
    end)
    if not okGrow then
        xpg_message("ทำให้สัตว์เลี้ยงโตไม่สำเร็จ", "Failed to grow the pet")
        return false, growError
    end

    pcall(function()
        if npc.view ~= nil then npc.view.needUpdateMod = true end
    end)
    pcall(function() EventMgr.Instance:EventTrigger(g_emEvent.ThingUpdate, npc) end)
    xpg_message("สัตว์เลี้ยงโตเต็มวัยแล้ว", "Pet growth completed")
    return true, "animal", age, adultAge
end

function Xaou_AwakenPetIntelligence(target)
    local npc = xpg_real_npc(target)
    if npc == nil then
        xpg_message("กรุณาเลือกสัตว์เลี้ยงก่อน", "Please select a pet first")
        return false, "no target"
    end
    if not xpg_is_animal(npc) then
        xpg_message("เป้าหมายนี้ไม่ใช่สัตว์เลี้ยง", "The selected target is not a pet")
        return false, "not an animal"
    end

    local isLingShou = false
    local alreadyAwake = false
    pcall(function() isLingShou = npc.IsLingShou == true end)
    pcall(function() alreadyAwake = npc.ThinkableAnimal == true end)
    if isLingShou then
        xpg_message("สัตว์วิญญาณไม่ใช้ระบบปลุกสติปัญญาแบบสัตว์ทั่วไป", "Spirit pets do not use the normal intelligence awakening system")
        return false, "spirit pet"
    end

    local evolutionRace = ""
    pcall(function() evolutionRace = tostring(npc.Race.YGRace or "") end)
    if evolutionRace == "" or evolutionRace == "SYS_LOST" then
        xpg_message("สัตว์ชนิดนี้ไม่รองรับการปลุกสติปัญญา", "This animal species does not support intelligence awakening")
        return false, "unsupported race"
    end

    if not alreadyAwake then
        local okAwake, awakeError = pcall(function()
            npc:QiZhi(nil)
        end)
        if not okAwake then
            xpg_message("ปลุกสติปัญญาไม่สำเร็จ", "Intelligence awakening failed")
            return false, awakeError
        end
    end

    local awakened = false
    pcall(function() awakened = npc.ThinkableAnimal == true end)
    if not awakened then
        xpg_message("เกมไม่ยืนยันการปลุกสติปัญญาของสัตว์ตัวนี้", "The game did not confirm intelligence awakening for this pet")
        return false, "not confirmed"
    end

    local mgr = nil
    pcall(function() mgr = CS.XiaWorld.HumanoidEvolutionMgr.Instance end)
    if mgr == nil then
        xpg_message("ไม่พบระบบสร้างความคิดของสัตว์", "Animal thought system was not found")
        return false, "manager nil"
    end

    local maxThink = 40
    pcall(function()
        local raceInfo = mgr.RaceInfos:GetDef(npc.RaceDefName)
        if raceInfo ~= nil and tonumber(raceInfo.MaxThink) ~= nil then
            maxThink = tonumber(raceInfo.MaxThink)
        end
    end)

    local thoughts = nil
    pcall(function() thoughts = npc.A2H.thinkFrags end)
    if thoughts == nil then
        -- Let the public game API create the correctly typed List<ThinkFrag> first.
        pcall(function()
            local seedThought = mgr:CreateThink(npc.RaceDefName, nil)
            if seedThought ~= nil and seedThought.frags ~= nil and seedThought.frags.Count > 0 then
                local seedFrag = seedThought.frags:get_Item(0)
                mgr:AddThink(npc, tostring(seedFrag), false)
                thoughts = npc.A2H.thinkFrags
            end
        end)
    end
    if thoughts == nil then
        local okList, newList = pcall(function()
            local listType = CS.System.Collections.Generic.List(CS.XiaWorld.HumanoidEvolutionMgr.ThinkFrag)
            return listType()
        end)
        if not okList or newList == nil then
            okList, newList = pcall(function()
                local listType = CS.System.Collections.Generic.List(typeof(CS.XiaWorld.HumanoidEvolutionMgr.ThinkFrag))
                return listType()
            end)
        end
        if not okList or newList == nil then
            xpg_message("สร้างรายการความคิดไม่สำเร็จ", "Could not create the thought list")
            return false, newList
        end
        thoughts = newList
        local okAssign, assignError = pcall(function() npc.A2H.thinkFrags = thoughts end)
        if not okAssign then
            xpg_message("บันทึกรายการความคิดไม่สำเร็จ", "Could not assign the thought list")
            return false, assignError
        end
    end

    local count = 0
    pcall(function() count = tonumber(thoughts.Count) or 0 end)

    -- Reserve room for three matching thoughts of every orb type. The game's
    -- consideration window only enables an orb when one fragment appears 3 times.
    local guaranteed = {}
    pcall(function()
        local seed = mgr:CreateThink(npc.RaceDefName, nil)
        if seed ~= nil and seed.frags ~= nil then
            local fragCount = tonumber(seed.frags.Count) or 0
            for i = 0, fragCount - 1 do
                local frag = seed.frags:get_Item(i)
                local def = mgr.Fragments:GetDef(frag)
                if def ~= nil then guaranteed[tostring(def.Type)] = tostring(frag) end
            end
        end
    end)

    local requiredTypes = {"Scene", "Target", "Emotion"}
    local guaranteedReady = true
    for _, fragType in ipairs(requiredTypes) do
        if guaranteed[fragType] == nil then guaranteedReady = false end
    end

    if guaranteedReady then
        -- Keep locked thoughts, but make enough space for all three selectable sets.
        while count > maxThink - 9 do
            local removed = false
            for i = count - 1, 0, -1 do
                local thought = nil
                pcall(function() thought = thoughts:get_Item(i) end)
                local locked = false
                if thought ~= nil then pcall(function() locked = thought.Lock == true end) end
                if thought ~= nil and not locked then
                    local okRemove = pcall(function() thoughts:RemoveAt(i) end)
                    if okRemove then
                        count = count - 1
                        removed = true
                        break
                    end
                end
            end
            if not removed then break end
        end

        for _, fragType in ipairs(requiredTypes) do
            local frag = guaranteed[fragType]
            for _ = 1, 3 do
                local beforeAdd = count
                local okAdd = pcall(function()
                    return mgr:AddThink(npc, frag, false)
                end)
                if okAdd then
                    pcall(function() count = tonumber(thoughts.Count) or beforeAdd end)
                end
            end
        end
    end

    local attempts = 0
    local failures = 0
    while count < maxThink and attempts < maxThink * 4 do
        attempts = attempts + 1
        local okCreate, thought = pcall(function()
            return mgr:CreateThink(npc.RaceDefName, nil)
        end)
        if not okCreate then
            okCreate, thought = pcall(function()
                return mgr:CreateThink(npc.RaceDefName)
            end)
        end
        if okCreate and thought ~= nil then
            local okAdd = pcall(function() thoughts:Add(thought) end)
            if okAdd then
                count = count + 1
            else
                failures = failures + 1
            end
        else
            failures = failures + 1
        end
    end

    -- Fill the final awakening wheel as well. The game reads QiZhiPassTime for
    -- external power and thinkFinals.Count for the 3-10 wisdom-crystal gauge.
    local finalCount = 0
    local maxFinal = 10
    local qiZhiNeed = 0
    local a2h = nil
    pcall(function() a2h = npc.A2H end)
    pcall(function()
        local raceInfo = mgr.RaceInfos:GetDef(npc.RaceDefName)
        if raceInfo ~= nil then
            qiZhiNeed = tonumber(raceInfo.QiZhiVFullNeed) or 0
            local rule = mgr.Rules:GetDef(raceInfo.RaceRule)
            if rule ~= nil and rule.FinalNode ~= nil then
                maxFinal = tonumber(rule.FinalNode.Max) or maxFinal
            end
        end
    end)

    if a2h ~= nil and qiZhiNeed > 0 then
        pcall(function() a2h.QiZhiPassTime = qiZhiNeed end)
    end
    if a2h ~= nil then
        pcall(function()
            if a2h.thinkFinals ~= nil then finalCount = tonumber(a2h.thinkFinals.Count) or 0 end
        end)
    end

    -- Mobile may stringify the fragment enum as a number. When that happens,
    -- recover the three real fragment IDs from an existing final crystal.
    local finalFrags = {
        Emotion = guaranteed.Emotion,
        Target = guaranteed.Target,
        Scene = guaranteed.Scene
    }
    local finalTemplate = nil
    if a2h ~= nil then
        pcall(function()
            if a2h.thinkFinals ~= nil and a2h.thinkFinals.Count > 0 then
                finalTemplate = a2h.thinkFinals:get_Item(0)
                if finalTemplate ~= nil and finalTemplate.aggregates ~= nil then
                    for i = 0, finalTemplate.aggregates.Count - 1 do
                        local aggregate = finalTemplate.aggregates:get_Item(i)
                        local combine = tostring(aggregate.Combine or "")
                        if combine == "AEmotion" then finalFrags.Emotion = tostring(aggregate.frag) end
                        if combine == "ATarget" then finalFrags.Target = tostring(aggregate.frag) end
                        if combine == "AScene" then finalFrags.Scene = tostring(aggregate.frag) end
                    end
                end
            end
        end)
    end
    local finalFragsReady = finalFrags.Emotion ~= nil and finalFrags.Target ~= nil and finalFrags.Scene ~= nil

    if a2h ~= nil and finalFragsReady then
        local finalAttempts = 0
        while finalCount < maxFinal and finalAttempts < maxFinal * 2 do
            finalAttempts = finalAttempts + 1
            local okFinal, finalNode = pcall(function()
                return mgr:Frag2FinalNode(
                    finalFrags.Emotion,
                    finalFrags.Target,
                    finalFrags.Scene
                )
            end)
            if (not okFinal or finalNode == nil) and finalTemplate ~= nil then
                okFinal, finalNode = pcall(function()
                    return mgr:GetThinkFinal(finalTemplate.aggregates, mgr.RaceInfos:GetDef(npc.RaceDefName))
                end)
            end
            if okFinal and finalNode ~= nil then
                local beforeFinal = finalCount
                local okAddFinal = pcall(function() a2h:AddThinkFinal(finalNode) end)
                if not okAddFinal then
                    okAddFinal = pcall(function() a2h.thinkFinals:Add(finalNode) end)
                end
                if okAddFinal then
                    pcall(function() finalCount = tonumber(a2h.thinkFinals.Count) or beforeFinal end)
                end
                if finalCount <= beforeFinal then break end
            else
                break
            end
        end
    end

    -- Last-resort mobile path: the existing final crystal is already a valid,
    -- saveable game object. Reuse it when XLua cannot construct the nested type.
    if a2h ~= nil and finalCount < maxFinal then
        local finals = nil
        local template = finalTemplate
        pcall(function() finals = a2h.thinkFinals end)
        if finals ~= nil and template == nil then
            pcall(function() template = finals:get_Item(0) end)
            if template == nil then pcall(function() template = finals[0] end) end
        end
        if finals ~= nil and template ~= nil then
            local copyAttempts = 0
            while finalCount < maxFinal and copyAttempts < maxFinal * 2 do
                copyAttempts = copyAttempts + 1
                local beforeCopy = finalCount
                local okCopy = pcall(function() finals:Add(template) end)
                if okCopy then
                    pcall(function() finalCount = tonumber(finals.Count) or beforeCopy end)
                end
                if finalCount <= beforeCopy then break end
            end
        end
    end

    local qiZhiPower = 0
    if a2h ~= nil then
        pcall(function() qiZhiPower = tonumber(a2h.QiZhiPassTime) or 0 end)
    end

    pcall(function() npc.A2H.CanThinkCount = 0 end)
    if count >= maxThink then
        pcall(function() npc.A2H:SetConsiderS(1, npc) end)
    end
    pcall(function() npc:RefreshPerferLevel() end)
    pcall(function() EventMgr.Instance:EventTrigger(g_emEvent.ThingUpdate, npc) end)
    if count >= maxThink and finalCount >= maxFinal then
        xpg_message("ปลุกสติปัญญาเต็มแล้ว ความคิด " .. tostring(count) .. "/" .. tostring(maxThink) .. " ผลึกปัญญา " .. tostring(finalCount) .. "/" .. tostring(maxFinal) .. " พลัง " .. tostring(qiZhiPower) .. "/" .. tostring(qiZhiNeed), "Pet awakening completed. Thoughts " .. tostring(count) .. "/" .. tostring(maxThink) .. ", wisdom crystals " .. tostring(finalCount) .. "/" .. tostring(maxFinal) .. ", power " .. tostring(qiZhiPower) .. "/" .. tostring(qiZhiNeed))
        return true, evolutionRace, count, maxThink, finalCount, maxFinal
    end
    if count >= maxThink then
        xpg_message("เติมความคิดเต็มแล้ว แต่ผลึกปัญญาได้ " .. tostring(finalCount) .. "/" .. tostring(maxFinal) .. " พลัง " .. tostring(qiZhiPower) .. "/" .. tostring(qiZhiNeed), "Thoughts are full, but wisdom crystals reached " .. tostring(finalCount) .. "/" .. tostring(maxFinal) .. ", power " .. tostring(qiZhiPower) .. "/" .. tostring(qiZhiNeed))
        return false, "partial finals", count, maxThink, finalCount, maxFinal
    end

    xpg_message("ปลุกสติปัญญาสำเร็จ แต่เติมความคิดได้ " .. tostring(count) .. "/" .. tostring(maxThink), "Intelligence awakened, but thoughts reached only " .. tostring(count) .. "/" .. tostring(maxThink))
    return false, "partial", count, maxThink, failures
end
