local modifierScript = GameMain:GetMod("_ModifierScript")
local modifierClass = modifierScript:GetModifier("modifier_baiyanlang")

function modifierClass:Enter(modifier, npc)
    local info = {
        KC = "Item",
        Line = {StartObj = npc},
        HeadMsg = "กรุณาเลือกสมบัติลับที่ต้องการชิงมา",
        Apply = function(_, map, key, mode)
            local target = mode:GetThing(g_emThingType.Item, key, map)
            target:BindItem2Npc(npc)
        end,
        Check = function(_, map, key, mode)
            local target = mode:GetThing(g_emThingType.Item, key, map)
            return target ~= nil and target.IsMiBao
        end,
    }

    world:EnterUILuaMode("TableCtrl", info)
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
