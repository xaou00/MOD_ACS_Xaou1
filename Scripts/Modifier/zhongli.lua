local modifierScript = GameMain:GetMod("_ModifierScript")
local modifierClass = modifierScript:GetModifier("modifier_zhongli")

function modifierClass:Enter(modifier, npc)
    xlua.private_accessible(CS.XiaWorld.GodPractice)
    local practice = npc.PropertyMgr.Practice
    if practice and practice.GodPracticeData then
        local godPractice = practice.GodPracticeData
        if godPractice.FeishengJieColdDown > 0 then
            godPractice.FeishengJieColdDown =
                godPractice.FeishengJieColdDown + 600 * 100 * modifier.Scale
        end
    end
end

function modifierClass:Step(modifier, npc, dt)
end

function modifierClass:UpdateStack(modifier, npc, add)
end

function modifierClass:Leave(modifier, npc)
end

function modifierClass:OnGetSaveData()
    return nil
end

function modifierClass:OnLoadData(modifier, npc, data)
end
