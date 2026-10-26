local tbThing = GameMain:GetMod("ThingHelper"):GetThing("Xaou_QiArray_Building")

local function show(text) pcall(function() world:ShowMsgBox(tostring(text)) end) end
local function selected_npc(callback)
    CS.Wnd_SelectNpc.Instance:Select(WorldLua:GetSelectNpcCallback(function(result)
        if result == nil or result.Count == 0 then return end
        local id = nil; pcall(function() id = result:get_Item(0) end)
        if id == nil then pcall(function() id = result[0] end) end
        local npc = nil; pcall(function() npc = CS.XiaWorld.ThingMgr.Instance:FindThingByID(id) end)
        if npc == nil then pcall(function() npc = ThingMgr:FindThingByID(id) end) end
        if npc ~= nil then callback(npc) end
    end), g_emNpcRank.Disciple, 1, 1, nil, nil, "เลือกตัวละคร")
end

function tbThing:OnPutDown()
    pcall(function() self.it:RemoveBtnData("รับพลัง") end)
    pcall(function() self.it:RemoveBtnData("เติมพลัง") end)
    self.it:AddBtnData("รับพลัง", "res/Sprs/ui/icon_hand", "bind.luaclass:GetTable():SelectNpcOut()", "เติมพลังปราณของ NPC จากค่ายกล", nil)
    self.it:AddBtnData("เติมพลัง", "res/Sprs/ui/icon_hand", "bind.luaclass:GetTable():SelectNpcIn()", "ถ่ายพลังปราณครึ่งหนึ่งของ NPC เข้าค่ายกล", nil)
end

function tbThing:SelectNpcOut() selected_npc(function(npc) self:OutLing(npc) end) end
function tbThing:SelectNpcIn() selected_npc(function(npc) self:InLing(npc) end) end

function tbThing:OutLing(npc)
    local need = math.max(0, math.ceil((tonumber(npc.MaxLing) or 0) - (tonumber(npc.LingV) or 0)))
    local stored = math.max(0, tonumber(self.it.LingV) or 0)
    local amount = math.min(need, stored)
    if amount <= 0 then show("NPC เต็มแล้ว หรือค่ายกลไม่มีพลัง") return end
    npc:AddLing(amount); self.it:AddLing(-amount)
    show("ถ่ายพลังให้ " .. tostring(npc.Name) .. " จำนวน " .. tostring(amount) .. " สำเร็จ")
end

function tbThing:InLing(npc)
    local amount = math.max(0, math.ceil((tonumber(npc.LingV) or 0) / 2))
    if amount <= 0 then show("NPC ไม่มีพลังให้ถ่าย") return end
    npc:AddLing(-amount); self.it:AddLing(amount)
    show(tostring(npc.Name) .. " เติมพลังเข้าค่ายกล " .. tostring(amount) .. " สำเร็จ")
end

