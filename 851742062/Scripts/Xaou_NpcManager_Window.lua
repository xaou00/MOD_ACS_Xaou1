-- Xaou NPC Manager UI. Reads commands and executes actions from the main mod.

local XNM_View, XNM_Target, XNM_CommandPage = nil, nil, "quick"
local XNM_Page, XNM_PageSize, XNM_VisibleCommands = 1, 6, {}
local XNM_StatusText, XNM_StatusKind = nil, nil

local XNM_Categories = {
    {button="menuQuick", page="quick", text="ด่วน"},
    {button="menuNpc", page="character", text="ตัวละคร"},
    {button="menuBook", page="combat", text="ต่อสู้"},
    {button="menuWorld", page="cancel", text="ยกเลิกบัฟ"},
    {button="menuDeveloper", page="more", text="เพิ่มเติม"},
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
local function set_status(text,kind)
    XNM_StatusText=tostring(text or "")
    XNM_StatusKind=kind
end
local function npc_name(npc)
    if Xaou_SafeNpcName then return Xaou_SafeNpcName(npc) end
    local value="NPC";pcall(function() value=tostring(npc.Name or npc:GetName()) end);return value
end
local function real_npc(npc)
    if Xaou_GetRealNpcObject then return Xaou_GetRealNpcObject(npc) end
    return npc
end
local function clean_text(value)
    local text=tostring(value or "")
    text=string.gsub(text,"^%s*%d+%.%s*","")
    return text
end
local function page_title(page)
    local value=tostring(page or "")
    if Xaou_GetNpcPageTitle then pcall(function() value=tostring(Xaou_GetNpcPageTitle(page)) end) end
    return value
end

function Xaou_CloseNpcManagerWindow()
    if XNM_View then
        pcall(function() XNM_View:RemoveFromParent() end)
        pcall(function() XNM_View:Dispose() end)
        XNM_View=nil
    end
end

local function get_commands()
    if not Xaou_GetNpcCommands then return {} end
    local ok,value=pcall(function() return Xaou_GetNpcCommands(XNM_CommandPage) end)
    return ok and type(value)=="table" and value or {}
end

local function refresh(view)
    local commands=get_commands()
    local maxPage=math.max(1,math.ceil(#commands/XNM_PageSize))
    XNM_Page=math.max(1,math.min(XNM_Page,maxPage))
    local first=(XNM_Page-1)*XNM_PageSize+1
    XNM_VisibleCommands={}

    set_text(child(view,"title"),"จัดการ NPC")
    set_text(child(view,"subtitle"),"NPC เป้าหมาย: "..npc_name(XNM_Target).." | ผู้พัฒนา: Xaou009")
    set_text(child(view,"sectionTitle"),page_title(XNM_CommandPage))
    local status=XNM_StatusText
    if status==nil or status=="" then status="เลือกคำสั่งที่ต้องการ" end
    set_text(child(view,"description"),status.."  |  หน้า "..tostring(XNM_Page).."/"..tostring(maxPage))
    local statusField=child(view,"description")
    if statusField and CS and CS.UnityEngine then
        pcall(function()
            if XNM_StatusKind=="success" then
                statusField.color=CS.UnityEngine.Color(0.13,0.42,0.20,1)
            elseif XNM_StatusKind=="error" then
                statusField.color=CS.UnityEngine.Color(0.68,0.12,0.10,1)
            else
                statusField.color=CS.UnityEngine.Color(0.30,0.27,0.20,1)
            end
        end)
    end
    set_text(child(view,"btnLanguage"),"กลับ Mod Center")

    local real=real_npc(XNM_Target)
    local icon="";pcall(function() icon=tostring(real.Race.TexPath or real.Race.Rolepaint or "") end)
    local portrait=child(view,"npcPortrait");pcall(function() portrait.url=icon end);set_visible(portrait,icon~="")
    set_text(child(view,"npcName"),npc_name(XNM_Target))
    local status="พร้อมใช้งาน";pcall(function() status="สำนัก: "..tostring(real.SchoolID or 0).." | ขั้นฝึกฝน: "..tostring(real.Practice and real.Practice.GongStage or "-") end)
    set_text(child(view,"npcStatus"),status)
    set_text(child(view,"brand"),"Xaou NPC Manager")

    for i=1,XNM_PageSize do
        local button=child(view,"feature"..tostring(i))
        local command=commands[first+i-1]
        if command then
            XNM_VisibleCommands[i]=command
            set_text(button,clean_text(command.text))
            set_visible(button,true)
        else
            set_visible(button,false)
        end
    end

    local prev,nextb=child(view,"feature7"),child(view,"feature8")
    set_text(prev,"◀ ย้อนกลับ");set_text(nextb,"ถัดไป ▶")
    set_visible(prev,true);set_visible(nextb,true)
    set_enabled(prev,XNM_Page>1);set_enabled(nextb,XNM_Page<maxPage)

    for _,category in ipairs(XNM_Categories) do
        set_text(child(view,category.button),(XNM_CommandPage==category.page and "▶ " or "")..category.text)
    end
end

local function run_command(command,view)
    if not command then return end
    if command.page then
        XNM_CommandPage=tostring(command.page);XNM_Page=1;set_status(nil,nil);refresh(view);return
    end
    if command.actions and Xaou_ApplyNpcActions then
        local label=clean_text(command.text)
        set_status("กำลังใช้คำสั่ง: "..label,nil);refresh(view)
        local ok,result,detail=pcall(function() return Xaou_ApplyNpcActions(XNM_Target,command.actions) end)
        if ok and result==true then
            set_status("สำเร็จ: "..label,"success")
        else
            local reason=detail or result or "ระบบไม่ยืนยันผลลัพธ์"
            set_status("ไม่สำเร็จ: "..label.." ("..tostring(reason)..")","error")
        end
        refresh(view)
        return
    end
    set_status("ไม่สำเร็จ: คำสั่งนี้ยังไม่รองรับในหน้าใหม่","error")
    refresh(view)
end

function Xaou_OpenNpcManagerWindow(npc)
    Xaou_CloseNpcManagerWindow();XNM_Target=npc;XNM_CommandPage="quick";XNM_Page=1;set_status(nil,nil)
    local pkg=UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root=(GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if not pkg or not root then return false end
    pcall(function() pkg.AddPackage("UI/XaoCtr") end)
    local view=nil;local ok,err=pcall(function() view=pkg.CreateObject("XaoCtr","XaouModCenterWindow") end)
    if not ok or not view then return false,tostring(err or "CreateObject returned nil") end
    XNM_View=view;root:AddChild(view);view.x=(root.width-view.width)/2;view.y=(root.height-view.height)/2

    for _,category in ipairs(XNM_Categories) do
        local page=category.page;local button=child(view,category.button)
        if button then button.onClick:Add(function() XNM_CommandPage=page;XNM_Page=1;refresh(view) end) end
    end
    for i=1,XNM_PageSize do
        local index=i;local button=child(view,"feature"..tostring(index))
        if button then button.onClick:Add(function() run_command(XNM_VisibleCommands[index],view) end) end
    end
    local prev,nextb=child(view,"feature7"),child(view,"feature8")
    if prev then prev.onClick:Add(function() if XNM_Page>1 then XNM_Page=XNM_Page-1;refresh(view) end end) end
    if nextb then nextb.onClick:Add(function()
        local maxPage=math.max(1,math.ceil(#get_commands()/XNM_PageSize))
        if XNM_Page<maxPage then XNM_Page=XNM_Page+1;refresh(view) end
    end) end
    local close=child(view,"btnClose");if close then close.onClick:Add(Xaou_CloseNpcManagerWindow) end
    local back=child(view,"btnLanguage");if back then back.onClick:Add(function()
        local target=XNM_Target;Xaou_CloseNpcManagerWindow()
        if Xaou_OpenStandaloneModCenter then Xaou_OpenStandaloneModCenter(target) end
    end) end
    refresh(view);return true
end
