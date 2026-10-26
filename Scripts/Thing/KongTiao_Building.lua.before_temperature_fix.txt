local tbThing = GameMain:GetMod("ThingHelper"):GetThing("KongTiao_Building")

function tbThing:OnInit()
    self.Time = tonumber(self.Time) or 0
    self.WenDu = tonumber(self.WenDu) or 20
end

function tbThing:OnStep(dt)
    local building = self.it
    if building == nil or building.BuildingState ~= g_emBuildingState.Working or building.AtRoom == nil then return end
    self.Time = (tonumber(self.Time) or 0) + (tonumber(dt) or 0)
    if self.Time < 0.25 then return end
    self.Time = 0
    local ok = pcall(function()
        xlua.private_accessible(CS.XiaWorld.AreaRoom)
        local target = tonumber(self.WenDu) or 20
        local room = building.AtRoom
        local base_temperature = tonumber(room.m_fTemperature) or 0
        room.m_fTemperatureOffset = target - base_temperature
    end)
    if not ok then self.Time = -8 end
end

function tbThing:OnPutDown()
    pcall(function() self.it:RemoveBtnData("ตั้งอุณหภูมิ") end)
    self.it:AddBtnData("ตั้งอุณหภูมิ", "res/Sprs/ui/icon_hand", "bind.luaclass:GetTable():OpenTemperature()", "ตั้งอุณหภูมิเป้าหมายของห้อง", nil)
end

function tbThing:OpenTemperature()
    if Xaou_OpenTemperatureWindow ~= nil then Xaou_OpenTemperatureWindow(self) end
end

function tbThing:setWenDu(value) self.WenDu = tonumber(value) or 20 end
function tbThing:GetRoomTemperature()
    local value = nil
    pcall(function() value = tonumber(self.it.AtRoom.Temperature) end)
    return value
end
function tbThing:OnGetSaveData() return {WenDu = tonumber(self.WenDu) or 20, Time = tonumber(self.Time) or 0} end
function tbThing:OnLoadData(data)
    data = data or {}; self.WenDu = tonumber(data.WenDu) or 20; self.Time = tonumber(data.Time) or 0
end
