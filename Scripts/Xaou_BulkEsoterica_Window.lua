-- Xaou FGUI window for collecting map manuals without opening the NPC selector.

local XBE_View,XBE_Target,XBE_Entries=nil,nil,nil
local XBE_Confirm,XBE_Busy=false,false
local XBE_Status,XBE_StatusKind=nil,nil

local function child(view,name)
    local value=nil;pcall(function() value=view:GetChild(name) end);return value
end
local function set_text(obj,value)
    if not obj then return end
    if Xaou_LocalizeText then value=Xaou_LocalizeText(value) end
    pcall(function() obj.text=tostring(value or "") end)
    pcall(function() obj.title=tostring(value or "") end)
end
local function set_visible(obj,value)
    if not obj then return end
    pcall(function() obj.visible=value==true end)
    pcall(function() obj.touchable=value==true end)
end
local function set_enabled(obj,value)
    if not obj then return end
    pcall(function() obj.enabled=value==true end)
    pcall(function() obj.touchable=value==true end)
    pcall(function() obj.alpha=value==true and 1 or 0.45 end)
end
local function npc_name(npc)
    if Xaou_SafeNpcName then return Xaou_SafeNpcName(npc) end
    local value="NPC";pcall(function() value=tostring(npc.Name or npc:GetName()) end);return value
end
local function real_npc(npc)
    if Xaou_GetRealNpcObject then
        local ok,value=pcall(function() return Xaou_GetRealNpcObject(npc) end)
        if ok and value~=nil then return value end
    end
    return npc
end
local function set_status(text,kind)
    XBE_Status=tostring(text or "");XBE_StatusKind=kind
end

function Xaou_CloseBulkEsotericaWindow()
    if XBE_View then
        pcall(function() XBE_View:RemoveFromParent() end)
        pcall(function() XBE_View:Dispose() end)
        XBE_View=nil
    end
end

local function refresh(view)
    local count=XBE_Entries and #XBE_Entries or 0
    set_text(child(view,"title"),"เก็บคัมภีร์เข้าหอ")
    set_text(child(view,"subtitle"),"ผู้ดำเนินการ: "..npc_name(XBE_Target).." | ผู้พัฒนา: Xaou009")
    set_text(child(view,"sectionTitle"),"คัมภีร์บนแผนที่")
    set_text(child(view,"brand"),"Xaou Bulk Esoterica")
    set_text(child(view,"btnLanguage"),"กลับ Mod Center")

    local status=XBE_Status
    if status==nil or status=="" then
        status="พบคัมภีร์บนแผนที่ "..count.." เล่ม ระบบจะเพิ่มเข้าหอก่อนลบของบนพื้น"
    end
    set_text(child(view,"description"),status)
    local field=child(view,"description")
    if field and CS and CS.UnityEngine then
        pcall(function()
            if XBE_StatusKind=="success" then field.color=CS.UnityEngine.Color(0.13,0.42,0.20,1)
            elseif XBE_StatusKind=="error" then field.color=CS.UnityEngine.Color(0.68,0.12,0.10,1)
            else field.color=CS.UnityEngine.Color(0.30,0.27,0.20,1) end
        end)
    end

    local real=real_npc(XBE_Target)
    local icon="";pcall(function() icon=tostring(real.Race.TexPath or real.Race.Rolepaint or "") end)
    local portrait=child(view,"npcPortrait");pcall(function() portrait.url=icon end);set_visible(portrait,icon~="")
    set_text(child(view,"npcName"),npc_name(XBE_Target))
    set_text(child(view,"npcStatus"),"ใช้เป็นผู้บันทึกคัมภีร์เข้าหออัตโนมัติ")

    set_text(child(view,"menuQuick"),"▶ เก็บคัมภีร์")
    set_visible(child(view,"menuQuick"),true)
    set_visible(child(view,"menuNpc"),false)
    set_visible(child(view,"menuBook"),false)
    set_visible(child(view,"menuWorld"),false)
    set_visible(child(view,"menuDeveloper"),false)

    if XBE_Confirm then
        set_text(child(view,"feature1"),"ยืนยันเก็บทั้งหมด "..count.." เล่ม")
    else
        set_text(child(view,"feature1"),"เก็บคัมภีร์ทั้งหมด "..count.." เล่ม")
    end
    set_text(child(view,"feature2"),"กลับ Mod Center")
    set_visible(child(view,"feature1"),true);set_visible(child(view,"feature2"),true)
    set_enabled(child(view,"feature1"),not XBE_Busy and count>0)
    for i=3,8 do set_visible(child(view,"feature"..tostring(i)),false) end
end

local function collect(view)
    if XBE_Busy then return end
    if not XBE_Confirm then
        XBE_Confirm=true
        set_status("ยืนยันว่าจะเก็บคัมภีร์ทั้งหมดบนแผนที่เข้าหอ ใช่ไหม?",nil)
        refresh(view)
        return
    end

    XBE_Busy=true;set_status("กำลังเก็บคัมภีร์ กรุณารอสักครู่...",nil);refresh(view)
    local ok,result=pcall(function() return Xaou_CollectAllMapEsoterica(real_npc(XBE_Target),XBE_Entries) end)
    XBE_Busy=false;XBE_Confirm=false
    if ok and result and result.ok==true then
        set_status("เก็บคัมภีร์เข้าหอสำเร็จแล้ว | "..tostring(result.summary or ""),"success")
        XBE_Entries={}
    else
        local reason=result
        if type(result)=="table" then reason=result.reason or result.summary end
        set_status("ไม่สำเร็จ: "..tostring(reason or "ไม่ทราบสาเหตุ"),"error")
        local entries=nil;pcall(function() entries=Xaou_ScanMapEsoterica() end)
        if entries~=nil then XBE_Entries=entries end
    end
    refresh(view)
end

function Xaou_OpenBulkEsotericaWindow(npc)
    Xaou_CloseBulkEsotericaWindow()
    XBE_Target=npc or Xaou_CurrentNpcTarget
    XBE_Confirm=false;XBE_Busy=false;set_status(nil,nil)
    local entries,scanError=Xaou_ScanMapEsoterica()
    XBE_Entries=entries or {}
    if entries==nil then set_status("ไม่สำเร็จ: "..tostring(scanError),"error") end

    local pkg=UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root=(GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if not pkg or not root then return false,"FairyGUI unavailable" end
    pcall(function() pkg.AddPackage("UI/XaoCtr") end)
    local view=nil;local ok,err=pcall(function() view=pkg.CreateObject("XaoCtr","XaouModCenterWindow") end)
    if not ok or not view then return false,tostring(err or "CreateObject returned nil") end
    XBE_View=view;root:AddChild(view);view.x=(root.width-view.width)/2;view.y=(root.height-view.height)/2

    local start=child(view,"feature1");if start then start.onClick:Add(function() collect(view) end) end
    local function back()
        local target=XBE_Target;Xaou_CloseBulkEsotericaWindow()
        if Xaou_OpenStandaloneModCenter then Xaou_OpenStandaloneModCenter(target) end
    end
    local backButton=child(view,"feature2");if backButton then backButton.onClick:Add(back) end
    local footer=child(view,"btnLanguage");if footer then footer.onClick:Add(back) end
    local close=child(view,"btnClose");if close then close.onClick:Add(Xaou_CloseBulkEsotericaWindow) end
    refresh(view);return true
end
