-- Standalone Jianghu relations feature for XaoCtr.
-- Require this file, then call Xaou_OpenJianghuRelationsWindow().

pcall(require, 'Scripts/Xaou_JianghuRelations_Window.lua')

local function xjr_message(text)
    if Xaou_LocalizeText then text = Xaou_LocalizeText(text) end
    local shown=false
    pcall(function()
        CS.Wnd_Message.Show(tostring(text),1,nil,true,"Xaou NPC สำนักอื่น",0,0,"")
        shown=true
    end)
    if not shown then pcall(function() world:ShowMsgBox(tostring(text)) end) end
end

local function xjr_manager()
    local mgr=nil
    pcall(function() mgr=JianghuMgr end)
    if not mgr then pcall(function() mgr=CS.XiaWorld.JianghuMgr.Instance end) end
    return mgr
end

function Xaou_OpenHeartBySeed(seed,addFavor)
    local ok,err=pcall(function()
        if seed==nil then error("ไม่พบรหัส NPC") end
        seed=tonumber(seed) or seed
        local mgr=xjr_manager();if not mgr then error("ไม่พบ JianghuMgr") end

        -- Follow Magic_BrokeHeartLock: create the persistent relationship record
        -- first, then let JHNpcData perform the real heart unlock.
        mgr:AddKnowNpcData(seed)
        local data=mgr:GetKnowNpcData(seed)
        if not data then error("ไม่สามารถสร้างข้อมูลความสัมพันธ์ของ NPC ได้") end

        data:UnlockHeart()
        if addFavor==true then
            local current=tonumber(data.favour) or 0
            local delta=100-current
            if delta>0 then
                local added=false
                pcall(function()
                    mgr:AddKnowNpcData(seed,CS.XiaWorld.g_emJHNpcDataType.None,delta,nil)
                    added=true
                end)
                -- Compatibility fallback for a Mobile build that hides the enum.
                if not added then data.favour=100 end
            end
        end
    end)
    if ok then
        xjr_message(addFavor and "เปิดใจและเพิ่มความสัมพันธ์สำเร็จ" or "เปิดใจสำเร็จ")
        return true
    end
    xjr_message("ดำเนินการไม่สำเร็จ\n"..tostring(err))
    return false
end

function Xaou_OpenJianghuRelationsWindow()
    if not Xaou_OpenJianghuNpcWindow then
        xjr_message("โหลดหน้าต่าง NPC สำนักอื่นไม่สำเร็จ")
        return false
    end
    local ok,result,detail=pcall(Xaou_OpenJianghuNpcWindow)
    if not ok or result==false then
        xjr_message("เปิดหน้าต่างไม่สำเร็จ\n"..tostring(detail or result))
        return false
    end
    return true
end
