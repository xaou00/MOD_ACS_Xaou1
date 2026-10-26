-- Xaou 009 body cultivation tools for ACS Mobile.

local XBP_View, XBP_Target = nil, nil
local XBP_Page, XBP_PageSize, XBP_Visible = 1, 6, {}
local XBP_Status = ""

local XBP_Actions = {
    {th="เติมปราณกายาให้เต็ม", en="Refill Body Qi", kind="qi"},
    {th="เพิ่มความก้าวหน้ากายา +5,000", en="Body Progress +5,000", kind="practice", value=5000},
    {th="ปลดท่าปกติ", en="Unlock Normal Stance", kind="attitude", id="SYS_NORMAL"},
    {th="ปลดท่าโจมตี", en="Unlock Attack Stance", kind="attitude", id="SYS_ATK"},
    {th="ปลดเจตจำนงหมานจี๋", en="Unlock Manji Battle Will", kind="attitude", id="BPAttitudes_ManJi"},
    {th="ปลดเจตจำนงราชัน", en="Unlock King Battle Will", kind="attitude", id="BPAttitudes_WangZhe"},
    {th="ปลดวิธีชำระกายพื้นฐาน", en="Unlock Basic Quenching", kind="method", id="BPQuenchingMethods_1"},
    {th="ปลดวิธีชำระกายซ้ำ", en="Unlock Re-quenching", kind="method", id="BPQuenchingMethods_ReQuenching"},
    {th="ปลดวิธีชำระเลือดเนื้อ", en="Unlock Flesh Quenching", kind="method", id="BPQuenchingMethods_1_1"},
    {th="ปลดวิธีชำระกระดูก", en="Unlock Bone Quenching", kind="method", id="BPQuenchingMethods_2"},
    {th="ปลดวิธีชำระไขกระดูก", en="Unlock Marrow Quenching", kind="method", id="BPQuenchingMethods_3"},
    {th="ปลดวิธีชำระอวัยวะ", en="Unlock Organ Quenching", kind="method", id="BPQuenchingMethods_4"},
    {th="ปลดวิธีชำระกายรัตติกาล", en="Unlock Night Quenching", kind="method", id="BPQuenchingMethods_5"},
    {th="ปลดวิธีชำระกายขั้นสูง", en="Unlock Advanced Quenching", kind="method", id="BPQuenchingMethods_6"},
    {th="ปลดแกนกายา", en="Unlock Body Core", kind="superpart", id="_SYS_CORE_"},
    {th="ปลดกายพิเศษของวิชาปัจจุบัน", en="Unlock Current Art Body Parts", kind="gong_parts"},
    {th="ปลดกายพิเศษประจำเผ่าพันธุ์", en="Unlock Racial Body Parts", kind="race_parts"},
    {th="เติมแก่นฝึกกาย +1,000", en="Body Training Essence +1,000", kind="need", value=1000},
    {th="ความเร็วชำระกาย +10", en="Quenching Speed +10", kind="property", prop="BodyPratice_QuenchingSpeed", value=10},
    {th="ปราณกายาสูงสุด +100,000", en="Maximum Body Qi +100,000", kind="property", prop="BodyPratice_MaxZhenQi", value=100000},
    {th="ฟื้นปราณกายาเร็วขึ้น +1,000", en="Body Qi Recovery +1,000", kind="property", prop="BodyPratice_RecoverZhenQi", value=1000},
    {th="ฟื้นฟูร่างกายเร็วขึ้น +10", en="Body Recovery +10", kind="property", prop="BodyPratice_BodyRecover", value=10},
    {th="ความแข็งแกร่งร่างกาย +10", en="Body Strength +10", kind="property", prop="BodyPratice_BodyStrong", value=10},
    {th="ช่องกายพิเศษโจมตี +1", en="Attack Body-Part Slot +1", kind="property", prop="BodyPractice_SuperPartAtk_EquptMaxCount", value=1},
    {th="ช่องกายพิเศษป้องกัน +1", en="Defense Body-Part Slot +1", kind="property", prop="BodyPractice_SuperPartDef_EquptMaxCount", value=1},
    {th="ช่องกายพิเศษเสริมพลัง +1", en="Effect Body-Part Slot +1", kind="property", prop="BodyPractice_SuperPartBuff_EquptMaxCount", value=1},
    {th="พลังกายพิเศษโจมตี +100", en="Body-Part Attack Power +100", kind="property", prop="BodyPractice_SuperPartAddv_AtkPower", value=100},
    {th="พลังกายพิเศษป้องกัน +100", en="Body-Part Defense Power +100", kind="property", prop="BodyPractice_SuperPartAddv_DefPower", value=100},
    {th="ความแม่นยำกายพิเศษ +10", en="Body-Part Accuracy +10", kind="property", prop="BodyPractice_SuperPartAddv_AtkRate", value=10},
    {th="อัตราป้องกันกายพิเศษ +10", en="Body-Part Defense Rate +10", kind="property", prop="BodyPractice_SuperPartAddv_DefRate", value=10},
    {th="เจาะเกราะปราณ +100", en="Qi Shield Penetration +100", kind="property", prop="BodyPractice_SuperPartAddv_ArmorPenetration", value=100},
    {th="โอกาสกดอาวุธเวท +10", en="Artifact Suppression +10", kind="property", prop="BodyPractice_SuperPartAddv_CatchFabao", value=10},
    {th="ระดับไอเทมที่กลืนได้ +5", en="Devour Item Rank +5", kind="property", prop="BodyPractice_EatItemMaxRate", value=5},
    {th="จำนวนแก่นจากการกลืน +10", en="Devour Essence Amount +10", kind="property", prop="BodyPractice_EatItemProduceCountAddp", value=10},
    {th="โอกาสได้แก่นจากการกลืน +10", en="Devour Essence Chance +10", kind="property", prop="BodyPractice_EatItemProduceRateAddp", value=10},
    {th="โอกสคุณสมบัติหายาก +10", en="Rare Quenching Chance +10", kind="property", prop="BodyPractice_RollAddtion_Cache1", value=10},
    {th="โอกาสคุณสมบัติระดับสูง +10", en="Epic Quenching Chance +10", kind="property", prop="BodyPractice_RollAddtion_Cache4", value=10},
    {th="เพิ่มแก่นธาตุทอง +999", en="Metal Essence +999", kind="material", id="Item_BodyPractice_Jin", value=999},
    {th="เพิ่มแก่นธาตุไม้ +999", en="Wood Essence +999", kind="material", id="Item_BodyPractice_Mu", value=999},
    {th="เพิ่มแก่นธาตุน้ำ +999", en="Water Essence +999", kind="material", id="Item_BodyPractice_Shui", value=999},
    {th="เพิ่มแก่นธาตุไฟ +999", en="Fire Essence +999", kind="material", id="Item_BodyPractice_Huo", value=999},
    {th="เพิ่มแก่นธาตุดิน +999", en="Earth Essence +999", kind="material", id="Item_BodyPractice_Tu", value=999},
    {th="เพิ่มแก่นชีวิตขั้น 1 +999", en="Life Essence I +999", kind="material", id="Item_BodyPractice_ShengMingLv1", value=999},
    {th="เพิ่มแก่นชีวิตขั้น 2 +999", en="Life Essence II +999", kind="material", id="Item_BodyPractice_ShengMingLv2", value=999},
    {th="เพิ่มแก่นชีวิตขั้น 3 +999", en="Life Essence III +999", kind="material", id="Item_BodyPractice_ShengMingLv3", value=999},
    {th="เพิ่มแก่นความตาย +999", en="Death Essence +999", kind="material", id="Item_BodyPractice_SiWang", value=999},
    {th="เพิ่มวัตถุดิบชำระกายทั้งหมด +999", en="All Quenching Materials +999", kind="all_materials", value=999},
    {th="ใช้ท่าปกติ", en="Use Normal Stance", kind="set_attitude", id="SYS_NORMAL"},
    {th="ใช้ท่าโจมตี", en="Use Attack Stance", kind="set_attitude", id="SYS_ATK"},
    {th="ใช้เจตจำนงหมานจี๋", en="Use Manji Battle Will", kind="set_attitude", id="BPAttitudes_ManJi"},
    {th="ใช้เจตจำนงราชัน", en="Use King Battle Will", kind="set_attitude", id="BPAttitudes_WangZhe"},
    {th="ฟื้นฟูอวัยวะที่สูญเสียทั้งหมด", en="Restore All Missing Body Parts", kind="revive_parts"},
    {th="อัปเกรดกายพิเศษทั้งหมดแบบสุ่ม", en="Randomly Upgrade All Body Parts", kind="upgrade_parts"},
    {th="ยกเลิกท่าต่อสู้ปัจจุบัน", en="Clear Current Stance", kind="clear_attitude"},
    {th="ดูสถานะวิชากายา", en="View Body Cultivation Status", kind="report"},
}

local XBP_AllMaterials = {
    "Item_BodyPractice_TaiXu","Item_BodyPractice_XuanTian","Item_BodyPractice_JieMie",
    "Item_BodyPractice_JiuYang","Item_BodyPractice_XuanYue","Item_BodyPractice_TaiYang","Item_BodyPractice_TaiYin",
    "Item_BodyPractice_EXJin","Item_BodyPractice_EXMu","Item_BodyPractice_EXShui","Item_BodyPractice_EXHuo","Item_BodyPractice_EXTu",
    "Item_BodyPractice_Jin","Item_BodyPractice_Mu","Item_BodyPractice_Shui","Item_BodyPractice_Huo","Item_BodyPractice_Tu",
    "Item_BodyPractice_FengShuiLing","Item_BodyPractice_FengShuiSha","Item_BodyPractice_Chun","Item_BodyPractice_Xia",
    "Item_BodyPractice_Qiu","Item_BodyPractice_Dong","Item_BodyPractice_YongYe","Item_BodyPractice_JiaoLongYuanJing",
    "Item_BodyPractice_XiongFengYuanJing","Item_BodyPractice_ZhuLongYuanJing","Item_BodyPractice_GuShouJingXue",
    "Item_BodyPractice_GuShouGuFen","Item_BodyPractice_DaYaoYuanJing","Item_BodyPractice_ShengMingLv1",
    "Item_BodyPractice_ShengMingLv2","Item_BodyPractice_ShengMingLv3","Item_BodyPractice_SiWang","Item_BodyPractice_WuHui",
    "Item_BodyPractice_DiMu","Item_BodyPractice_XieMai","Item_BodyPractice_WuXing","Item_BodyPractice_XianDaoJingHua",
    "Item_BodyPractice_XianSui","Item_BodyPractice_ShenSui","Item_BodyPractice_BaBao","Item_BodyPractice_WanDao",
    "Item_BodyPractice_QiQing","Item_BodyPractice_ZhouTian","Item_BodyPractice_XuanYang","Item_BodyPractice_Jian",
    "Item_BodyPractice_LingYu","Item_BodyPractice_WanGu","Item_BodyPractice_XuanCi","Item_BodyPractice_QiSha",
    "Item_BodyPractice_XuanYin",
}

local function xbp_en()
    return Xaou_GetLanguage and Xaou_GetLanguage()=="en"
end

local function xbp_t(th,en)
    return xbp_en() and (en or th) or th
end

local function xbp_child(view,name)
    local value=nil
    pcall(function() value=view:GetChild(name) end)
    return value
end

local function xbp_text(obj,value)
    if not obj then return end
    pcall(function() obj.text=tostring(value or "") end)
    pcall(function() obj.title=tostring(value or "") end)
end

local function xbp_visible(obj,value)
    if not obj then return end
    pcall(function() obj.visible=value==true end)
    pcall(function() obj.touchable=value==true end)
end

local function xbp_enabled(obj,value)
    if not obj then return end
    pcall(function() obj.enabled=value==true end)
    pcall(function() obj.touchable=value==true end)
    pcall(function() obj.alpha=value==true and 1 or 0.45 end)
end

local function xbp_name(npc)
    if Xaou_SafeNpcName then return Xaou_SafeNpcName(npc) end
    local value="NPC"
    pcall(function() value=tostring(npc.Name or npc:GetName()) end)
    return value
end

local function xbp_real_npc()
    local real=XBP_Target
    if Xaou_GetRealNpcObject then real=Xaou_GetRealNpcObject(XBP_Target) end
    return real
end

local function xbp_data()
    local real=xbp_real_npc()
    if real==nil then return nil,nil,nil end
    local practice,body=nil,nil
    pcall(function() practice=real.PropertyMgr.Practice end)
    if practice~=nil then pcall(function() body=practice.BodyPracticeData end) end
    return body,practice,real
end

local function xbp_list_count(list)
    if list==nil then return 0 end
    local count=0
    pcall(function() count=tonumber(list.Count) or 0 end)
    return count
end

local function xbp_list_item(list,index)
    local value=nil
    local ok=pcall(function() value=list:get_Item(index) end)
    if not ok or value==nil then pcall(function() value=list[index] end) end
    return value
end

local function xbp_unlock_list(body,list)
    local success,failed=0,0
    local count=xbp_list_count(list)
    for i=0,count-1 do
        local id=xbp_list_item(list,i)
        if id~=nil and tostring(id)~="" then
            local ok=pcall(function() body:UnLockSuperPart(tostring(id),false) end)
            local exists=nil
            pcall(function() exists=body:GetSuperPartData(tostring(id)) end)
            if ok and exists~=nil then success=success+1 else failed=failed+1 end
        end
    end
    return success,failed,count
end

local function xbp_add_material(body,id,count)
    local def=nil
    pcall(function()
        if ThingMgr and ThingMgr.Instance and g_emThingType then def=ThingMgr.Instance:GetDef(g_emThingType.Item,id) end
    end)
    if def==nil then
        pcall(function() def=CS.XiaWorld.ThingMgr.Instance:GetDef(CS.XiaWorld.g_emThingType.Item,id) end)
    end
    if def==nil then return false,"item definition not found: "..tostring(id) end
    local before=0;pcall(function() before=tonumber(body:GetQuenchingItemCount(id)) or 0 end)
    local ok,err=pcall(function() body:AddQuenchingItem(id,tonumber(count) or 1) end)
    local after=before;pcall(function() after=tonumber(body:GetQuenchingItemCount(id)) or before end)
    return ok and after>before,ok and (tostring(before).." -> "..tostring(after)) or tostring(err)
end

local function xbp_apply_property(data,real)
    if Xaou_TryModifierProperty==nil then pcall(require,"Scripts/Xaou_NpcHelper.lua") end
    if Xaou_TryModifierProperty==nil then return false,"modifier property system not found" end
    local before=nil;pcall(function() before=real:GetProperty(data.prop) end)
    local called,result,detail=pcall(function() return Xaou_TryModifierProperty(XBP_Target,data.prop,data.value) end)
    local after=nil;pcall(function() after=real:GetProperty(data.prop) end)
    if not called or result~=true then return false,tostring(detail or result) end
    if before~=nil and after~=nil and tonumber(before)==tonumber(after) then return false,"value did not change: "..tostring(after) end
    return true,tostring(before or "?").." -> "..tostring(after or "?")
end

local function xbp_dictionary_keys(dict)
    local result={}
    if dict==nil then return result end
    local ok,enumerator=pcall(function() return dict:GetEnumerator() end)
    if not ok or enumerator==nil then return result end
    while true do
        local moved=false
        local moveOk=pcall(function() moved=enumerator:MoveNext() end)
        if not moveOk or not moved then break end
        local key=nil;pcall(function() key=enumerator.Current.Key end)
        if key~=nil then result[#result+1]=tostring(key) end
    end
    pcall(function() enumerator:Dispose() end)
    return result
end

local function xbp_apply(data)
    if data==nil then return end
    local body,practice,real=xbp_data()
    if body==nil then
        XBP_Status=xbp_t("NPC ที่เลือกยังไม่ได้ฝึกวิชาสายกายา","The selected NPC is not a body cultivator")
        if world then pcall(function() world:ShowMsgBox(XBP_Status) end) end
        return
    end

    local ok,detail=false,""
    if data.kind=="qi" then
        local before,maximum,after=nil,nil,nil
        pcall(function() before=tonumber(body.QiValue) end)
        pcall(function() maximum=tonumber(body.MaxZhenQi) end)
        local called,err=pcall(function() body:AddZhenQi(maximum or 999999999) end)
        pcall(function() after=tonumber(body.QiValue) end)
        ok=called and after~=nil and (before==nil or after>=before)
        detail=called and (tostring(before or "?").." -> "..tostring(after or "?")) or tostring(err)
    elseif data.kind=="practice" then
        local before,after=nil,nil
        pcall(function() before=tonumber(practice.StageValue) end)
        local called,err=pcall(function() practice:AddPractice(tonumber(data.value) or 5000,true) end)
        pcall(function() after=tonumber(practice.StageValue) end)
        ok=called and after~=nil and (before==nil or after>before)
        if called and before==after then
            local neck=false;pcall(function() neck=practice.TouchNeck==true end)
            detail=neck and xbp_t("ติดคอขวด ต้องทะลวงขั้นก่อน","A bottleneck must be broken first") or xbp_t("ค่าไม่เปลี่ยน","Value did not change")
        else
            detail=called and (tostring(before or "?").." -> "..tostring(after or "?")) or tostring(err)
        end
    elseif data.kind=="attitude" then
        local called,err=pcall(function() body:UnLockAttitude(data.id,false) end)
        local found=false
        local list=nil;pcall(function() list=body.Attitudes end)
        for i=0,xbp_list_count(list)-1 do
            if tostring(xbp_list_item(list,i))==data.id then found=true;break end
        end
        ok=called and found
        detail=ok and data.id or tostring(err or ("unlock not confirmed: "..data.id))
    elseif data.kind=="method" then
        local called,err=pcall(function() body:AddQuenchingMethod(data.id,false) end)
        local found=false;pcall(function() found=body:CheckQuenchingMethod(data.id)==true end)
        ok=called and found
        detail=ok and data.id or tostring(err or ("unlock not confirmed: "..data.id))
    elseif data.kind=="superpart" then
        local called,err=pcall(function() body:UnLockSuperPart(data.id,false) end)
        local part=nil;pcall(function() part=body:GetSuperPartData(data.id) end)
        ok=called and part~=nil
        detail=ok and data.id or tostring(err or ("unlock not confirmed: "..data.id))
    elseif data.kind=="gong_parts" then
        local list=nil;pcall(function() list=practice.Gong.SuperParts end)
        local success,failed,total=xbp_unlock_list(body,list)
        ok=total>0 and success>0 and failed==0
        detail=xbp_t("พบ ","Found ")..total..xbp_t(" / ปลดสำเร็จ "," / unlocked ")..success..xbp_t(" / ไม่สำเร็จ "," / failed ")..failed
    elseif data.kind=="race_parts" then
        local list=nil;pcall(function() list=real.Race.RaceSuperPart end)
        local success,failed,total=xbp_unlock_list(body,list)
        ok=total>0 and success>0 and failed==0
        detail=xbp_t("พบ ","Found ")..total..xbp_t(" / ปลดสำเร็จ "," / unlocked ")..success..xbp_t(" / ไม่สำเร็จ "," / failed ")..failed
    elseif data.kind=="need" then
        local needType=nil
        pcall(function() needType=g_emNeedType.Practice end)
        if needType==nil then pcall(function() needType=CS.XiaWorld.g_emNeedType.Practice end) end
        local before,after=nil,nil
        pcall(function() before=tonumber(real.Needs:GetNeedValue(needType)) end)
        local called,err=pcall(function() real.Needs:AddNeedValue(needType,tonumber(data.value) or 1000) end)
        pcall(function() after=tonumber(real.Needs:GetNeedValue(needType)) end)
        ok=called and after~=nil and (before==nil or after>before)
        detail=called and (tostring(before or "?").." -> "..tostring(after or "?")) or tostring(err)
    elseif data.kind=="property" then
        ok,detail=xbp_apply_property(data,real)
    elseif data.kind=="material" then
        ok,detail=xbp_add_material(body,data.id,data.value)
    elseif data.kind=="all_materials" then
        local success,failed=0,0
        for _,id in ipairs(XBP_AllMaterials) do
            local added=xbp_add_material(body,id,data.value)
            if added then success=success+1 else failed=failed+1 end
        end
        ok=success>0
        detail=xbp_t("เพิ่มสำเร็จ ","Added ")..success..xbp_t(" ชนิด / ข้าม "," types / skipped ")..failed
    elseif data.kind=="set_attitude" then
        local unlocked=false
        local list=nil;pcall(function() list=body.Attitudes end)
        for i=0,xbp_list_count(list)-1 do
            if tostring(xbp_list_item(list,i))==data.id then unlocked=true;break end
        end
        if not unlocked then pcall(function() body:UnLockAttitude(data.id,false) end) end
        local called,err=pcall(function() body:ChangeAttitude(data.id) end)
        local current=nil;pcall(function() current=tostring(body.CurAttitude) end)
        ok=called and current==data.id
        detail=ok and current or tostring(err or ("attitude not confirmed: "..tostring(current)))
    elseif data.kind=="revive_parts" then
        local removed=nil;pcall(function() removed=real.PropertyMgr.BodyData.RemovedParts end)
        local names={}
        for i=0,xbp_list_count(removed)-1 do
            local part=xbp_list_item(removed,i);local id=nil
            pcall(function() id=tostring(part.def.Name) end)
            if id then names[#names+1]=id end
        end
        local success,failed=0,0
        for _,id in ipairs(names) do
            local restored=nil;local called=pcall(function() restored=real.PropertyMgr.BodyData:RevivePart(id) end)
            if called and restored~=nil then success=success+1 else failed=failed+1 end
        end
        ok=#names==0 or success>0
        detail=(#names==0) and xbp_t("ไม่มีอวัยวะที่สูญเสีย","No missing body parts") or (xbp_t("ฟื้นสำเร็จ ","Restored ")..success..xbp_t(" / ไม่สำเร็จ "," / failed ")..failed)
    elseif data.kind=="upgrade_parts" then
        local dict=nil;pcall(function() dict=body.SuperParts end)
        local keys=xbp_dictionary_keys(dict)
        local success,failed=0,0
        for _,id in ipairs(keys) do
            if id~="_SYS_CORE_" then
                local called=pcall(function() body:UpgradSuperPart2RandomLevel(id) end)
                if called then success=success+1 else failed=failed+1 end
            end
        end
        ok=success>0
        detail=xbp_t("อัปเกรดสำเร็จ ","Upgraded ")..success..xbp_t(" / ไม่สำเร็จ "," / failed ")..failed
    elseif data.kind=="clear_attitude" then
        local called,err=pcall(function() body:ClearAttitude() end)
        local current=nil;pcall(function() current=body.CurAttitude end)
        ok=called and (current==nil or tostring(current)=="")
        detail=ok and xbp_t("ยกเลิกท่าต่อสู้แล้ว","Current stance cleared") or tostring(err or current)
    elseif data.kind=="report" then
        local qi,maxQi,stage,attitudes,methods,parts,materials="?","?","?",0,0,0,0
        pcall(function() qi=body.QiValue end);pcall(function() maxQi=body.MaxZhenQi end);pcall(function() stage=practice.StageValue end)
        pcall(function() attitudes=body.Attitudes.Count end);pcall(function() methods=body.QuenchingMethod.Count end)
        pcall(function() parts=body.SuperParts.Count end);pcall(function() materials=body.QuenchingMaterial.Count end)
        ok=true
        detail=xbp_t("ปราณกายา: ","Body Qi: ")..tostring(qi).."/"..tostring(maxQi)..
            xbp_t("\nความก้าวหน้า: ","\nProgress: ")..tostring(stage)..
            xbp_t("\nท่าต่อสู้: ","\nStances: ")..tostring(attitudes)..
            xbp_t("\nวิธีชำระกาย: ","\nQuenching methods: ")..tostring(methods)..
            xbp_t("\nกายพิเศษ: ","\nSpecial body parts: ")..tostring(parts)..
            xbp_t("\nชนิดวัตถุดิบ: ","\nMaterial types: ")..tostring(materials)
    end

    if ok then
        XBP_Status=xbp_t("สำเร็จ: ","Success: ")..(xbp_en() and data.en or data.th).."\n"..detail
        pcall(function() EventMgr.Instance:EventTrigger(g_emEvent.NpcPracticeChange,real) end)
        pcall(function() CS.XiaWorld.EventMgr.Instance:EventTrigger(CS.XiaWorld.g_emEvent.NpcPracticeChange,real) end)
    else
        XBP_Status=xbp_t("ไม่สำเร็จ: ","Failed: ")..tostring(detail)
    end
    if world then pcall(function() world:ShowMsgBox(XBP_Status) end) end
end

local function xbp_refresh()
    if not XBP_View then return end
    local maxPage=math.max(1,math.ceil(#XBP_Actions/XBP_PageSize))
    XBP_Page=math.max(1,math.min(XBP_Page,maxPage))
    local first=(XBP_Page-1)*XBP_PageSize+1
    XBP_Visible={}

    xbp_text(xbp_child(XBP_View,"title"),xbp_t("ปรับแต่งวิชากายา","Body Cultivation Tools"))
    xbp_text(xbp_child(XBP_View,"subtitle"),xbp_t("เลือกปลดล็อกหรือเพิ่มค่าทีละอย่าง","Unlock or improve one option at a time"))
    xbp_text(xbp_child(XBP_View,"sectionTitle"),xbp_t("ระบบฝึกกายา","Body Cultivation"))
    xbp_text(xbp_child(XBP_View,"description"),(XBP_Status~="" and XBP_Status or xbp_t("NPC เป้าหมาย: ","Target NPC: ")..xbp_name(XBP_Target))..xbp_t("  |  หน้า ","  |  Page ")..XBP_Page.."/"..maxPage)
    xbp_text(xbp_child(XBP_View,"npcName"),xbp_name(XBP_Target))
    xbp_text(xbp_child(XBP_View,"npcStatus"),xbp_t("ใช้ได้เฉพาะ NPC ที่ฝึกวิชาสายกายา","Only available for body cultivators"))
    xbp_text(xbp_child(XBP_View,"brand"),"Xaou 009 Body Practice")

    for i=1,XBP_PageSize do
        local data=XBP_Actions[first+i-1]
        local button=xbp_child(XBP_View,"feature"..i)
        XBP_Visible[i]=data
        if data then xbp_text(button,xbp_en() and data.en or data.th);xbp_visible(button,true) else xbp_visible(button,false) end
    end
    local prev,nextb=xbp_child(XBP_View,"feature7"),xbp_child(XBP_View,"feature8")
    xbp_text(prev,xbp_t("◀ ย้อนกลับ","◀ Previous"));xbp_text(nextb,xbp_t("ถัดไป ▶","Next ▶"))
    xbp_visible(prev,true);xbp_visible(nextb,true)
    xbp_enabled(prev,XBP_Page>1);xbp_enabled(nextb,XBP_Page<maxPage)
    for _,name in ipairs({"menuQuick","menuNpc","menuBook","menuWorld","menuDeveloper"}) do xbp_visible(xbp_child(XBP_View,name),false) end
    xbp_text(xbp_child(XBP_View,"btnLanguage"),xbp_t("กลับ Mod Center","Back to Mod Center"))

    local real=xbp_real_npc();local icon=""
    pcall(function() icon=tostring(real.Race.TexPath or real.Race.Rolepaint or "") end)
    local portrait=xbp_child(XBP_View,"npcPortrait");pcall(function() portrait.url=icon end);xbp_visible(portrait,icon~="")
end

function Xaou_CloseBodyPracticeWindow()
    if XBP_View then
        pcall(function() XBP_View:RemoveFromParent() end)
        pcall(function() XBP_View:Dispose() end)
        XBP_View=nil
    end
end

function Xaou_OpenBodyPracticeWindow(npc)
    if npc==nil then return false,xbp_t("กรุณาเลือก NPC ก่อน","Please select an NPC first") end
    Xaou_CloseBodyPracticeWindow();XBP_Target=npc;XBP_Page=1;XBP_Status=""
    local pkg=UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root=(GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if not pkg or not root then return false,"FairyGUI is unavailable" end
    pcall(function() pkg.AddPackage("UI/XaoCtr") end)
    local view=nil;local ok,err=pcall(function() view=pkg.CreateObject("XaoCtr","XaouModCenterWindow") end)
    if not ok or not view then return false,tostring(err or "CreateObject returned nil") end
    XBP_View=view;root:AddChild(view);view.x=(root.width-view.width)/2;view.y=(root.height-view.height)/2
    for i=1,XBP_PageSize do
        local index=i;local button=xbp_child(view,"feature"..i)
        if button then button.onClick:Add(function() xbp_apply(XBP_Visible[index]);xbp_refresh() end) end
    end
    local prev,nextb=xbp_child(view,"feature7"),xbp_child(view,"feature8")
    if prev then prev.onClick:Add(function() if XBP_Page>1 then XBP_Page=XBP_Page-1;xbp_refresh() end end) end
    if nextb then nextb.onClick:Add(function() local maxPage=math.max(1,math.ceil(#XBP_Actions/XBP_PageSize));if XBP_Page<maxPage then XBP_Page=XBP_Page+1;xbp_refresh() end end) end
    local close=xbp_child(view,"btnClose");if close then close.onClick:Add(Xaou_CloseBodyPracticeWindow) end
    local back=xbp_child(view,"btnLanguage");if back then back.onClick:Add(function() local target=XBP_Target;Xaou_CloseBodyPracticeWindow();if Xaou_OpenStandaloneModCenter then Xaou_OpenStandaloneModCenter(target) end end) end
    xbp_refresh();return true
end
