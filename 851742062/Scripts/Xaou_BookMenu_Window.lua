-- Xaou FGUI replacement for the original three-category book page.

local XBM_View,XBM_Target,XBM_Category=nil,nil,"all"
local XBM_Page,XBM_PageSize,XBM_Visible=1,6,{}
local XBM_Status,XBM_StatusKind=nil,nil

local categories={
    {button="menuQuick",id="all",text="ทั้งหมด"},
    {button="menuNpc",id="unlock",text="ปลดล็อกวิชา"},
    {button="menuBook",id="manual",text="หนังสือคัมภีร์"},
    {button="menuWorld",id="warp",text="วาร์ป"},
}

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
local function category_title()
    for _,entry in ipairs(categories) do if entry.id==XBM_Category then return entry.text end end
    return "ทั้งหมด"
end
local function set_status(text,kind)
    XBM_Status=tostring(text or "");XBM_StatusKind=kind
end

function Xaou_CloseBookMenuWindow()
    if XBM_View then
        pcall(function() XBM_View:RemoveFromParent() end)
        pcall(function() XBM_View:Dispose() end)
        XBM_View=nil
    end
end

local function commands()
    if Xaou_GetNewBookCommands then return Xaou_GetNewBookCommands(XBM_Category) end
    return {}
end

local function refresh(view)
    local list=commands()
    local maxPage=math.max(1,math.ceil(#list/XBM_PageSize))
    XBM_Page=math.max(1,math.min(XBM_Page,maxPage))
    local first=(XBM_Page-1)*XBM_PageSize+1
    XBM_Visible={}

    set_text(child(view,"title"),"เมนูคัมภีร์")
    set_text(child(view,"subtitle"),"NPC เป้าหมาย: "..npc_name(XBM_Target).." | ผู้พัฒนา: Xaou009")
    set_text(child(view,"sectionTitle"),category_title())
    set_text(child(view,"brand"),"Xaou Book Center")
    set_text(child(view,"btnLanguage"),"กลับ Mod Center")
    local status=XBM_Status
    if status==nil or status=="" then status="เลือกคำสั่งคัมภีร์ที่ต้องการ" end
    set_text(child(view,"description"),status.." | หน้า "..XBM_Page.."/"..maxPage)
    local field=child(view,"description")
    if field and CS and CS.UnityEngine then pcall(function()
        if XBM_StatusKind=="success" then field.color=CS.UnityEngine.Color(0.13,0.42,0.20,1)
        elseif XBM_StatusKind=="error" then field.color=CS.UnityEngine.Color(0.68,0.12,0.10,1)
        else field.color=CS.UnityEngine.Color(0.30,0.27,0.20,1) end
    end) end

    set_text(child(view,"npcName"),npc_name(XBM_Target))
    set_text(child(view,"npcStatus"),"ใช้เป็นผู้รับคัมภีร์และคำสั่งวิชา")
    local portrait=child(view,"npcPortrait")
    local icon="";pcall(function() icon=tostring(XBM_Target.Race.TexPath or XBM_Target.Race.Rolepaint or "") end)
    pcall(function() portrait.url=icon end);set_visible(portrait,icon~="")

    for _,entry in ipairs(categories) do
        set_text(child(view,entry.button),(XBM_Category==entry.id and "▶ " or "")..entry.text)
        set_visible(child(view,entry.button),true)
    end
    set_visible(child(view,"menuDeveloper"),false)

    for i=1,XBM_PageSize do
        local button=child(view,"feature"..i)
        local command=list[first+i-1]
        if command then
            XBM_Visible[i]=command;set_text(button,command.text);set_visible(button,true)
        else set_visible(button,false) end
    end
    local prev,nextb=child(view,"feature7"),child(view,"feature8")
    set_text(prev,"◀ ย้อนกลับ");set_text(nextb,"ถัดไป ▶")
    set_visible(prev,true);set_visible(nextb,true)
    set_enabled(prev,XBM_Page>1);set_enabled(nextb,XBM_Page<maxPage)
end

local function run(index,view)
    local command=XBM_Visible[index]
    if command==nil then return end
    local target=XBM_Target
    local ok,result,detail=pcall(function() return Xaou_RunNewBookCommand(target,command) end)
    if ok and result==true then
        set_status("เปิดคำสั่ง: "..command.text,"success")
        refresh(view)
    else
        set_status("ไม่สำเร็จ: "..tostring(detail or result),"error")
        refresh(view)
    end
end

function Xaou_OpenBookMenuWindow(npc, category)
    Xaou_CloseBookMenuWindow(); XBM_Target = npc or Xaou_CurrentNpcTarget; XBM_Category = tostring(category or "all"); XBM_Page = 1; set_status(nil, nil)
    local pkg=UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root=(GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if not pkg or not root then return false,"FairyGUI unavailable" end
    pcall(function() pkg.AddPackage("UI/XaoCtr") end)
    local view=nil;local ok,err=pcall(function() view=pkg.CreateObject("XaoCtr","XaouModCenterWindow") end)
    if not ok or not view then return false,tostring(err or "CreateObject returned nil") end
    XBM_View=view;root:AddChild(view);view.x=(root.width-view.width)/2;view.y=(root.height-view.height)/2

    for _,entry in ipairs(categories) do
        local category=entry.id;local button=child(view,entry.button)
        if button then button.onClick:Add(function() XBM_Category=category;XBM_Page=1;set_status(nil,nil);refresh(view) end) end
    end
    for i=1,XBM_PageSize do
        local index=i;local button=child(view,"feature"..i)
        if button then button.onClick:Add(function() run(index,view) end) end
    end
    local prev,nextb=child(view,"feature7"),child(view,"feature8")
    if prev then prev.onClick:Add(function() if XBM_Page>1 then XBM_Page=XBM_Page-1;refresh(view) end end) end
    if nextb then nextb.onClick:Add(function()
        local maxPage=math.max(1,math.ceil(#commands()/XBM_PageSize))
        if XBM_Page<maxPage then XBM_Page=XBM_Page+1;refresh(view) end
    end) end
    local function back()
        local target=XBM_Target;Xaou_CloseBookMenuWindow()
        if Xaou_OpenStandaloneModCenter then Xaou_OpenStandaloneModCenter(target) end
    end
    local close=child(view,"btnClose");if close then close.onClick:Add(Xaou_CloseBookMenuWindow) end
    local footer=child(view,"btnLanguage");if footer then footer.onClick:Add(back) end
    refresh(view);return true
end
