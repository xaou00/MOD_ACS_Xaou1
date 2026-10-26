-- Xaou automatic learning UI for the standalone Mod Center.

local XLW_View, XLW_Target, XLW_Mode = nil, nil, "all"
local XLW_Busy, XLW_Status, XLW_StatusKind = false, nil, nil

local function child(view,name)
    local value=nil
    pcall(function() value=view:GetChild(name) end)
    return value
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
    local value="NPC"
    pcall(function() value=tostring(npc.Name or npc:GetName()) end)
    return value
end

local function real_npc(npc)
    if Xaou_GetRealNpcObject then return Xaou_GetRealNpcObject(npc) end
    return npc
end

local function set_status(text,kind)
    XLW_Status=tostring(text or "")
    XLW_StatusKind=kind
end

local function mode_title()
    if XLW_Mode=="current" then return "เรียนวิชาปัจจุบัน" end
    if XLW_Mode=="library" then return "เรียนคัมภีร์ทั้งหมดในหอ" end
    return "เรียนทุกวิชาในสำนัก"
end

local function mode_description()
    if XLW_Mode=="current" then
        return "เรียนเฉพาะวิชาที่ NPC กำลังฝึก พร้อมปลดล็อกคัมภีร์และสายวิชาที่รองรับ"
    end
    if XLW_Mode=="library" then
        return "เรียนคัมภีร์ทุกเล่มที่เก็บในหอ โดยใช้ระบบเรียนจริงของเกมและข้ามเล่มที่เรียนแล้ว"
    end
    return "เรียนวิชาทั้งหมดที่มีในสำนัก และข้ามวิชาหรือโหนดที่เกมไม่รองรับโดยอัตโนมัติ"
end

function Xaou_CloseLearnWindow()
    if XLW_View then
        pcall(function() XLW_View:RemoveFromParent() end)
        pcall(function() XLW_View:Dispose() end)
        XLW_View=nil
    end
end

local function refresh(view)
    set_text(child(view,"title"),"เรียนวิชาอัตโนมัติ")
    set_text(child(view,"subtitle"),"NPC เป้าหมาย: "..npc_name(XLW_Target).." | ผู้พัฒนา: Xaou009")
    set_text(child(view,"sectionTitle"),mode_title())
    set_text(child(view,"brand"),"Xaou Learn")
    set_text(child(view,"btnLanguage"),"กลับ Mod Center")

    local status=XLW_Status
    if status==nil or status=="" then status=mode_description() end
    set_text(child(view,"description"),status)
    local statusField=child(view,"description")
    if statusField and CS and CS.UnityEngine then
        pcall(function()
            if XLW_StatusKind=="success" then
                statusField.color=CS.UnityEngine.Color(0.13,0.42,0.20,1)
            elseif XLW_StatusKind=="error" then
                statusField.color=CS.UnityEngine.Color(0.68,0.12,0.10,1)
            else
                statusField.color=CS.UnityEngine.Color(0.30,0.27,0.20,1)
            end
        end)
    end

    local real=real_npc(XLW_Target)
    local icon=""
    pcall(function() icon=tostring(real.Race.TexPath or real.Race.Rolepaint or "") end)
    local portrait=child(view,"npcPortrait")
    pcall(function() portrait.url=icon end)
    set_visible(portrait,icon~="")
    set_text(child(view,"npcName"),npc_name(XLW_Target))
    local npcStatus="พร้อมเรียนวิชา"
    pcall(function() npcStatus="สำนัก: "..tostring(real.SchoolID or 0).." | วิชาปัจจุบัน: "..tostring(real.Practice.Gong or "-") end)
    set_text(child(view,"npcStatus"),npcStatus)

    set_text(child(view,"menuQuick"),(XLW_Mode=="all" and "▶ " or "").."ทุกวิชา")
    set_text(child(view,"menuNpc"),(XLW_Mode=="current" and "▶ " or "").."วิชาปัจจุบัน")
    set_text(child(view,"menuBook"),(XLW_Mode=="library" and "▶ " or "").."คัมภีร์ในหอ")
    set_visible(child(view,"menuQuick"),true)
    set_visible(child(view,"menuNpc"),true)
    set_visible(child(view,"menuBook"),true)
    set_visible(child(view,"menuWorld"),false)
    set_visible(child(view,"menuDeveloper"),false)

    set_text(child(view,"feature1"),"เริ่มเรียน")
    set_text(child(view,"feature2"),"กลับ Mod Center")
    set_visible(child(view,"feature1"),true)
    set_visible(child(view,"feature2"),true)
    set_enabled(child(view,"feature1"),not XLW_Busy)
    for i=3,8 do set_visible(child(view,"feature"..tostring(i)),false) end
end

local function run_learn(view)
    if XLW_Busy then return end
    if XLW_Target==nil then set_status("ไม่สำเร็จ: ไม่พบ NPC เป้าหมาย","error");refresh(view);return end
    XLW_Busy=true
    set_status("กำลังเรียนวิชา กรุณารอสักครู่...",nil)
    refresh(view)

    local ok,result
    if XLW_Mode=="current" then
        ok,result=pcall(function() return Xaou_LearnCurrentGongDirect(XLW_Target) end)
    elseif XLW_Mode=="library" then
        ok,result=pcall(function() return Xaou_LearnAllLibraryEsoterica(XLW_Target) end)
    else
        ok,result=pcall(function() return Xaou_LearnAllGongsDirect(XLW_Target) end)
    end
    XLW_Busy=false

    if ok and result and result.ok==true then
        if XLW_Mode=="current" then
            set_status("เรียนวิชาปัจจุบันสำเร็จแล้ว","success")
        elseif XLW_Mode=="library" then
            local detail=type(result)=="table" and result.summary or nil
            set_status("เรียนคัมภีร์ทั้งหมดในหอสำเร็จแล้ว"..(detail and (" | "..detail) or ""),"success")
        else
            set_status("เรียนทุกวิชาในสำนักสำเร็จแล้ว","success")
        end
    else
        local reason=result
        if type(result)=="table" then reason=result.reason or result.report end
        if reason==nil or tostring(reason)=="" then reason="ไม่พบวิชาที่สามารถเรียนได้" end
        reason=tostring(reason)
        if string.len(reason)>120 then reason="ไม่พบวิชาที่สามารถเรียนได้ หรือมีข้อมูลบางส่วนไม่รองรับ" end
        set_status("ไม่สำเร็จ: "..reason,"error")
    end
    refresh(view)
end

function Xaou_OpenLearnWindow(npc)
    Xaou_CloseLearnWindow()
    XLW_Target=npc or Xaou_CurrentNpcTarget
    XLW_Mode="all"
    XLW_Busy=false
    set_status(nil,nil)

    local pkg=UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root=(GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if not pkg or not root then return false,"FairyGUI unavailable" end
    pcall(function() pkg.AddPackage("UI/XaoCtr") end)
    local view=nil
    local ok,err=pcall(function() view=pkg.CreateObject("XaoCtr","XaouModCenterWindow") end)
    if not ok or not view then return false,tostring(err or "CreateObject returned nil") end
    XLW_View=view
    root:AddChild(view)
    view.x=(root.width-view.width)/2
    view.y=(root.height-view.height)/2

    local allButton=child(view,"menuQuick")
    if allButton then allButton.onClick:Add(function() XLW_Mode="all";set_status(nil,nil);refresh(view) end) end
    local currentButton=child(view,"menuNpc")
    if currentButton then currentButton.onClick:Add(function() XLW_Mode="current";set_status(nil,nil);refresh(view) end) end
    local libraryButton=child(view,"menuBook")
    if libraryButton then libraryButton.onClick:Add(function() XLW_Mode="library";set_status(nil,nil);refresh(view) end) end
    local startButton=child(view,"feature1")
    if startButton then startButton.onClick:Add(function() run_learn(view) end) end
    local backButton=child(view,"feature2")
    if backButton then backButton.onClick:Add(function()
        local target=XLW_Target
        Xaou_CloseLearnWindow()
        if Xaou_OpenStandaloneModCenter then Xaou_OpenStandaloneModCenter(target) end
    end) end
    local close=child(view,"btnClose")
    if close then close.onClick:Add(Xaou_CloseLearnWindow) end
    local footer=child(view,"btnLanguage")
    if footer then footer.onClick:Add(function()
        local target=XLW_Target
        Xaou_CloseLearnWindow()
        if Xaou_OpenStandaloneModCenter then Xaou_OpenStandaloneModCenter(target) end
    end) end

    refresh(view)
    return true
end
