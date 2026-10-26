-- Xaou 009 divine cultivation stat editor for ACS Mobile.

local XGP_View, XGP_Target = nil, nil
local XGP_Page, XGP_PageSize, XGP_Visible = 1, 6, {}
local XGP_Status, XGP_StatusKind = "", nil

local XGP_Stats = {
    {th="จำนวนผู้ศรัทธาปัจจุบัน +1,000", en="Current Believers +1,000", kind="population", value=1000},
    {th="พลังศรัทธาปัจจุบัน +50,000", en="Current Faith +50,000", kind="faith", value=50000},
    {th="สภาวะจิตสายเทพ +100", en="Divine Mind State +100", kind="mind_add", value=100},
    {th="สภาวะจิตสายเทพสูงสุด", en="Maximum Divine Mind State", kind="mind_max", value=1000},
    {th="พลังบำเพ็ญสายเทพ +5,000", en="Divine Cultivation +5,000", kind="practice", value=5000},
    {th="พลังเทพ +999", en="Divine Power +999", prop="GodPractice_GodPowerAddV", value=999},
    {th="แปลงศรัทธาเป็นพลัง +999", en="Faith Conversion +999", prop="GodPractice_LingConvert", value=999},
    {th="เพดานผู้ศรัทธาแดนเทพ +9,999", en="Divine Realm Believer Cap +9,999", prop="GodCity_MaxResident", value=9999},
    {th="ผู้ศรัทธาหลักสูงสุด +999", en="Core Believers +999", prop="GodCity_MaxCoreBeliever", value=999},
    {th="ประสิทธิภาพการฝึกสายเทพ +9", en="Divine Practice Effect +9", prop="GodCity_PracticeEffect", value=9},
    {th="พลังผู้พิทักษ์เทพ +5", en="Divine Guard Effect +5", prop="GodCity_GuardEffect", value=5},
    {th="อายุขัย +500 ปี", en="Maximum Age +500", prop="MaxAge", value=500},
    {th="ปราณสูงสุด +100,000", en="Maximum Qi +100,000", prop="NpcLingMaxValue", value=100000},
    {th="ความเร็วเดินทาง +10", en="World Travel Speed +10", prop="WorldMapFlySpeedAddP", value=10},
    {th="ทนความหนาวเพิ่ม", en="Improve Cold Resistance", actions={{prop="ToleranceTMin", value=-100}}},
    {th="ทนความร้อนเพิ่ม", en="Improve Heat Resistance", actions={{prop="ToleranceTMax", value=1000}}},
}

local function xgp_en()
    return Xaou_GetLanguage and Xaou_GetLanguage()=="en"
end
local function xgp_t(th,en)
    return xgp_en() and (en or th) or th
end
local function xgp_child(view,name)
    local value=nil
    pcall(function() value=view:GetChild(name) end)
    return value
end
local function xgp_text(obj,value)
    if not obj then return end
    pcall(function() obj.text=tostring(value or "") end)
    pcall(function() obj.title=tostring(value or "") end)
end
local function xgp_visible(obj,value)
    if not obj then return end
    pcall(function() obj.visible=value==true end)
    pcall(function() obj.touchable=value==true end)
end
local function xgp_enabled(obj,value)
    if not obj then return end
    pcall(function() obj.enabled=value==true end)
    pcall(function() obj.touchable=value==true end)
    pcall(function() obj.alpha=value==true and 1 or 0.45 end)
end
local function xgp_name(npc)
    if Xaou_SafeNpcName then return Xaou_SafeNpcName(npc) end
    local value="NPC"
    pcall(function() value=tostring(npc.Name or npc:GetName()) end)
    return value
end

local function xgp_read_property(prop)
    local real=XGP_Target
    if Xaou_GetRealNpcObject then real=Xaou_GetRealNpcObject(XGP_Target) end
    if real==nil then return false,nil end
    local ok,value=pcall(function() return real:GetProperty(prop) end)
    if ok and value~=nil then return true,tonumber(value) or value end
    local pm=nil
    pcall(function() pm=real.PropertyMgr end)
    if pm~=nil then
        ok,value=pcall(function() return pm:GetProperty(prop) end)
        if ok and value~=nil then return true,tonumber(value) or value end
        ok,value=pcall(function() return pm:GetPropertyValue(prop) end)
        if ok and value~=nil then return true,tonumber(value) or value end
    end
    return false,nil
end

local function xgp_god_data()
    local real=XGP_Target
    if Xaou_GetRealNpcObject then real=Xaou_GetRealNpcObject(XGP_Target) end
    if real==nil then return nil,nil end
    local data=nil
    pcall(function() data=real.PropertyMgr.Practice.GodPracticeData end)
    return data,real
end

local function xgp_apply_god_value(data)
    local god,real=xgp_god_data()
    if god==nil then
        return false,xgp_t("NPC นี้ยังไม่มีข้อมูลวิชาเทพ","This NPC has no divine cultivation data")
    end
    local before,after=nil,nil
    if data.kind=="population" then
        pcall(function() before=tonumber(god.Population) end)
        local ok,err=pcall(function() god:AddPopulation(tonumber(data.value) or 0) end)
        if not ok then return false,tostring(err) end
        pcall(function() after=tonumber(god.Population) end)
    elseif data.kind=="faith" then
        pcall(function() before=tonumber(god.Faith) end)
        local ok,err=pcall(function() god:AddFaith(tonumber(data.value) or 0) end)
        if not ok then return false,tostring(err) end
        pcall(function() after=tonumber(god.Faith) end)
    else
        return false,"unsupported divine value"
    end
    pcall(function() EventMgr.Instance:EventTrigger(g_emEvent.GodPracticeBelieveChanged,real) end)
    pcall(function() CS.XiaWorld.EventMgr.Instance:EventTrigger(CS.XiaWorld.g_emEvent.GodPracticeBelieveChanged,real) end)
    if before~=nil and after~=nil and before==after then
        return false,xgp_t("เรียก API สำเร็จ แต่ค่าถูกจำกัดไว้ที่ ","API ran, but the value is capped at ")..tostring(after)
    end
    return true,tostring(before or "?").." -> "..tostring(after or "?")
end

local function xgp_mind_need_type()
    local value=nil
    pcall(function() value=g_emNeedType.MindState end)
    if value==nil then pcall(function() value=CS.XiaWorld.g_emNeedType.MindState end) end
    return value
end

local function xgp_apply_mind(data)
    local god,real=xgp_god_data()
    if god==nil or real==nil then
        return false,xgp_t("NPC นี้ยังไม่มีข้อมูลวิชาเทพ","This NPC has no divine cultivation data")
    end
    local needType=xgp_mind_need_type()
    if needType==nil then return false,"g_emNeedType.MindState not found" end
    local before=nil
    pcall(function() before=tonumber(real.Needs:GetNeedValue(needType)) end)
    local ok,err=pcall(function()
        if data.kind=="mind_max" then
            for _=1,6 do god:MindStateLevelLevelUp() end
        end
        real.Needs:AddNeedValue(needType,tonumber(data.value) or 0)
    end)
    if not ok then return false,tostring(err) end
    local after=nil
    pcall(function() after=tonumber(real.Needs:GetNeedValue(needType)) end)
    if before~=nil and after~=nil and before==after then
        return false,xgp_t("ค่าไม่เปลี่ยน อาจติดเพดานสภาวะจิตที่ ","Value did not change; the mind-state cap may be ")..tostring(after)
    end
    pcall(function() EventMgr.Instance:EventTrigger(g_emEvent.NpcPropertyChanged,real) end)
    return true,tostring(before or "?").." -> "..tostring(after or "?")
end

local function xgp_apply_practice(data)
    local god,real=xgp_god_data()
    if god==nil or real==nil then
        return false,xgp_t("NPC นี้ยังไม่ได้ฝึกวิชาสายเทพ","This NPC is not cultivating a divine art")
    end
    local practice=nil
    pcall(function() practice=real.PropertyMgr.Practice end)
    if practice==nil then return false,"NpcPractice not found" end
    local before=nil
    pcall(function() before=tonumber(practice.StageValue) end)
    local ok,err=pcall(function() practice:AddPractice(tonumber(data.value) or 5000) end)
    if not ok then return false,tostring(err) end
    local after=nil
    pcall(function() after=tonumber(practice.StageValue) end)
    if before~=nil and after~=nil and before==after then
        local atNeck=false
        pcall(function() atNeck=practice.TouchNeck==true end)
        if atNeck then
            return false,xgp_t("ติดคอขวด ต้องทะลวงขั้นก่อน","A bottleneck must be broken first")
        end
        return false,xgp_t("เรียก AddPractice แล้ว แต่ค่าบำเพ็ญไม่เปลี่ยน","AddPractice ran, but cultivation progress did not change")
    end
    pcall(function() EventMgr.Instance:EventTrigger(g_emEvent.NpcPracticeChange,real) end)
    return true,tostring(before or "?").." -> "..tostring(after or "?")
end

local function xgp_refresh()
    if not XGP_View then return end
    local maxPage=math.max(1,math.ceil(#XGP_Stats/XGP_PageSize))
    XGP_Page=math.max(1,math.min(XGP_Page,maxPage))
    local first=(XGP_Page-1)*XGP_PageSize+1
    XGP_Visible={}

    xgp_text(xgp_child(XGP_View,"title"),xgp_t("ปรับแต่งวิชาเทพ","Divine Cultivation Stats"))
    xgp_text(xgp_child(XGP_View,"subtitle"),xgp_t("เลือกค่าที่ต้องการเพิ่มให้ NPC ที่เลือก","Choose a stat to increase for the selected NPC"))
    xgp_text(xgp_child(XGP_View,"sectionTitle"),xgp_t("พลังศรัทธาและแดนเทพ","Faith and Divine Realm"))
    local detail=XGP_Status
    if detail=="" then detail=xgp_t("NPC เป้าหมาย: ","Target NPC: ")..xgp_name(XGP_Target) end
    xgp_text(xgp_child(XGP_View,"description"),detail..xgp_t("  |  หน้า ","  |  Page ")..XGP_Page.."/"..maxPage)
    xgp_text(xgp_child(XGP_View,"npcName"),xgp_name(XGP_Target))
    xgp_text(xgp_child(XGP_View,"npcStatus"),xgp_t("เลือกเพิ่มทีละค่า ผลจะบันทึกกับ NPC","Increase one stat at a time; changes are stored on the NPC"))
    xgp_text(xgp_child(XGP_View,"brand"),"Xaou 009 Divine Practice")

    for i=1,XGP_PageSize do
        local button=xgp_child(XGP_View,"feature"..i)
        local data=XGP_Stats[first+i-1]
        if data then
            XGP_Visible[i]=data
            xgp_text(button,xgp_en() and data.en or data.th)
            xgp_visible(button,true)
        else
            xgp_visible(button,false)
        end
    end
    local prev,nextb=xgp_child(XGP_View,"feature7"),xgp_child(XGP_View,"feature8")
    xgp_text(prev,xgp_t("◀ ย้อนกลับ","◀ Previous"))
    xgp_text(nextb,xgp_t("ถัดไป ▶","Next ▶"))
    xgp_visible(prev,true);xgp_visible(nextb,true)
    xgp_enabled(prev,XGP_Page>1);xgp_enabled(nextb,XGP_Page<maxPage)

    local menus={"menuQuick","menuNpc","menuBook","menuWorld","menuDeveloper"}
    for _,name in ipairs(menus) do xgp_visible(xgp_child(XGP_View,name),false) end
    xgp_text(xgp_child(XGP_View,"btnLanguage"),xgp_t("กลับ Mod Center","Back to Mod Center"))

    local real=XGP_Target
    if Xaou_GetRealNpcObject then real=Xaou_GetRealNpcObject(XGP_Target) end
    local icon=""
    pcall(function() icon=tostring(real.Race.TexPath or real.Race.Rolepaint or "") end)
    local portrait=xgp_child(XGP_View,"npcPortrait")
    pcall(function() portrait.url=icon end)
    xgp_visible(portrait,icon~="")
end

local function xgp_apply(data)
    if not data or not XGP_Target then return end
    if data.kind=="practice" then
        local ok,detail=xgp_apply_practice(data)
        if ok then
            XGP_Status=xgp_t("เพิ่มสำเร็จ: ","Applied: ")..(xgp_en() and data.en or data.th).."\n"..tostring(detail)
            XGP_StatusKind="success"
        else
            XGP_Status=xgp_t("เพิ่มไม่สำเร็จ: ","Failed: ")..tostring(detail)
            XGP_StatusKind="error"
        end
        if world then pcall(function() world:ShowMsgBox(XGP_Status) end) end
        xgp_refresh()
        return
    end
    if data.kind=="mind_add" or data.kind=="mind_max" then
        local ok,detail=xgp_apply_mind(data)
        if ok then
            XGP_Status=xgp_t("เพิ่มสำเร็จ: ","Applied: ")..(xgp_en() and data.en or data.th).."\n"..tostring(detail)
            XGP_StatusKind="success"
        else
            XGP_Status=xgp_t("เพิ่มไม่สำเร็จ: ","Failed: ")..tostring(detail)
            XGP_StatusKind="error"
        end
        if world then pcall(function() world:ShowMsgBox(XGP_Status) end) end
        xgp_refresh()
        return
    end
    if data.kind=="population" or data.kind=="faith" then
        local ok,detail=xgp_apply_god_value(data)
        if ok then
            XGP_Status=xgp_t("เพิ่มสำเร็จ: ","Applied: ")..(xgp_en() and data.en or data.th).."\n"..tostring(detail)
            XGP_StatusKind="success"
        else
            XGP_Status=xgp_t("เพิ่มไม่สำเร็จ: ","Failed: ")..tostring(detail)
            XGP_StatusKind="error"
        end
        if world then pcall(function() world:ShowMsgBox(XGP_Status) end) end
        xgp_refresh()
        return
    end
    if Xaou_TryModifierProperty==nil then pcall(require,'Scripts/Xaou_NpcHelper.lua') end
    if Xaou_TryModifierProperty==nil then
        XGP_Status=xgp_t("ไม่พบระบบแก้ไขค่าสถานะ","Stat modifier system was not found")
        XGP_StatusKind="error";xgp_refresh();return
    end
    local actions=data.actions or {{prop=data.prop,value=data.value}}
    local okAll,reason=true,nil
    local changed,readable=false,false
    local debugParts={}
    for _,action in ipairs(actions) do
        local beforeOk,before=xgp_read_property(action.prop)
        local ok,result,detail=pcall(function()
            return Xaou_TryModifierProperty(XGP_Target,action.prop,action.value)
        end)
        if not ok or result~=true then
            okAll=false;reason=tostring(action.prop)..": "..tostring(detail or result);break
        end
        local afterOk,after=xgp_read_property(action.prop)
        if beforeOk and afterOk then
            readable=true
            if tostring(before)~=tostring(after) then changed=true end
            debugParts[#debugParts+1]=tostring(action.prop).." "..tostring(before).." -> "..tostring(after)
        end
    end
    if okAll then
        if readable and not changed then
            XGP_Status=xgp_t("เรียกคำสั่งได้ แต่ค่ายังไม่เปลี่ยน: ","Command ran, but value did not change: ")..(xgp_en() and data.en or data.th)
            XGP_StatusKind="error"
        else
            XGP_Status=xgp_t("เพิ่มสำเร็จ: ","Applied: ")..(xgp_en() and data.en or data.th)
            XGP_StatusKind="success"
        end
        if #debugParts>0 then XGP_Status=XGP_Status.."\n"..table.concat(debugParts,"\n") end
        if data.prop=="GodCity_MaxResident" then
            local god=xgp_god_data()
            local area=0
            pcall(function() area=tonumber(god.GodCityArea) or 0 end)
            if area<=0 then
                XGP_Status=XGP_Status.."\n"..xgp_t("หมายเหตุ: ยังไม่เปิดแดนเทพ เกมจึงจำกัดเพดานไว้ 1,000","Note: Divine Realm is not open, so the active cap remains 1,000")
            end
        end
        if world then pcall(function() world:ShowMsgBox(XGP_Status) end) end
    else
        XGP_Status=xgp_t("เพิ่มไม่สำเร็จ: ","Failed: ")..tostring(reason or "unknown")
        XGP_StatusKind="error"
        if world then pcall(function() world:ShowMsgBox(XGP_Status) end) end
    end
    xgp_refresh()
end

function Xaou_CloseGodPracticeWindow()
    if XGP_View then
        pcall(function() XGP_View:RemoveFromParent() end)
        pcall(function() XGP_View:Dispose() end)
        XGP_View=nil
    end
end

function Xaou_OpenGodPracticeWindow(npc)
    if npc==nil then return false,"NPC target is nil" end
    Xaou_CloseGodPracticeWindow()
    XGP_Target=npc;XGP_Page=1;XGP_Status="";XGP_StatusKind=nil
    local pkg=UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root=(GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if not pkg or not root then return false,"FairyGUI is unavailable" end
    pcall(function() pkg.AddPackage("UI/XaoCtr") end)
    local view=nil
    local ok,err=pcall(function() view=pkg.CreateObject("XaoCtr","XaouModCenterWindow") end)
    if not ok or not view then return false,tostring(err or "CreateObject returned nil") end
    XGP_View=view;root:AddChild(view)
    view.x=(root.width-view.width)/2;view.y=(root.height-view.height)/2

    for i=1,XGP_PageSize do
        local index=i;local button=xgp_child(view,"feature"..index)
        if button then button.onClick:Add(function() xgp_apply(XGP_Visible[index]) end) end
    end
    local prev,nextb=xgp_child(view,"feature7"),xgp_child(view,"feature8")
    if prev then prev.onClick:Add(function() if XGP_Page>1 then XGP_Page=XGP_Page-1;xgp_refresh() end end) end
    if nextb then nextb.onClick:Add(function()
        local maxPage=math.max(1,math.ceil(#XGP_Stats/XGP_PageSize))
        if XGP_Page<maxPage then XGP_Page=XGP_Page+1;xgp_refresh() end
    end) end
    local close=xgp_child(view,"btnClose")
    if close then close.onClick:Add(Xaou_CloseGodPracticeWindow) end
    local back=xgp_child(view,"btnLanguage")
    if back then back.onClick:Add(function()
        local target=XGP_Target;Xaou_CloseGodPracticeWindow()
        if Xaou_OpenStandaloneModCenter then Xaou_OpenStandaloneModCenter(target) end
    end) end
    xgp_refresh()
    return true
end
