-- Xaou Construction Tools UI for the standalone XaoCtr package.
-- Public entry point: Xaou_OpenConstructionToolsWindow()

local XCT_View=nil
Xaou_ConstructionToolsState=Xaou_ConstructionToolsState or {
    QuickBuildEnable=false,
    FreeBuildEnable=false,
    FreeBuildBackup={}
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
local function show_message(value)
    if Xaou_LocalizeText then value=Xaou_LocalizeText(value) end
    pcall(function() world:ShowMsgBox(tostring(value)) end)
end
local function building_defs()
    local map=nil;pcall(function() map=CS.XiaWorld.ThingMgr.s_mapThingDefs end)
    if not map then return nil end
    local buildings=nil
    pcall(function() buildings=map[4] end)
    if not buildings then pcall(function() buildings=map:get_Item(4) end) end
    return buildings
end
local function toggle_quick_build()
    local state=Xaou_ConstructionToolsState
    state.QuickBuildEnable=not state.QuickBuildEnable
    local ok,err=pcall(function() CS.GameMain.Instance.QuickBuild=state.QuickBuildEnable end)
    return ok,err
end
local function enable_free_build()
    local state=Xaou_ConstructionToolsState
    local defs=building_defs();if not defs then return false,"ไม่พบรายการอาคาร" end
    local ok,err=pcall(function()
        local e=defs:GetEnumerator()
        while e:MoveNext() do
            local def=e.Current.Value
            if def and def.Building and def.Building.BeMade then
                local made,name=def.Building.BeMade,tostring(def.Name)
                if not state.FreeBuildBackup[name] then
                    state.FreeBuildBackup[name]={CostStuffCount=made.CostStuffCount,CostStuffScale=made.CostStuffScale,CostItems=made.CostItems}
                end
                made.CostStuffCount=0;made.CostStuffScale=0;made.CostItems=nil
            end
        end
        state.FreeBuildEnable=true
    end)
    return ok,err
end
local function disable_free_build()
    local state=Xaou_ConstructionToolsState
    local defs=building_defs();if not defs then return false,"ไม่พบรายการอาคาร" end
    local ok,err=pcall(function()
        local e=defs:GetEnumerator()
        while e:MoveNext() do
            local def=e.Current.Value
            if def and def.Building and def.Building.BeMade then
                local old=state.FreeBuildBackup[tostring(def.Name)]
                if old then
                    local made=def.Building.BeMade
                    made.CostStuffCount=old.CostStuffCount;made.CostStuffScale=old.CostStuffScale;made.CostItems=old.CostItems
                end
            end
        end
        state.FreeBuildEnable=false
    end)
    return ok,err
end
local function toggle_free_build()
    if Xaou_ConstructionToolsState.FreeBuildEnable then return disable_free_build() end
    return enable_free_build()
end
local function state_text(value)
    return value==true and "เปิดใช้งาน" or "ปิดอยู่"
end

function Xaou_CloseConstructionToolsWindow()
    if XCT_View then
        pcall(function() XCT_View:RemoveFromParent() end)
        pcall(function() XCT_View:Dispose() end)
        XCT_View=nil
    end
end

local function refresh(view)
    local state=Xaou_ConstructionToolsState
    local quick,free=state.QuickBuildEnable==true,state.FreeBuildEnable==true

    set_text(child(view,"title"),"เครื่องมือก่อสร้าง")
    set_text(child(view,"subtitle"),"ควบคุมระบบช่วยสร้างของ Xaou")
    set_text(child(view,"npcName"),"สถานะการก่อสร้าง")
    set_text(child(view,"npcStatus"),"สร้างด่วน: "..state_text(quick).."  |  สร้างฟรี: "..state_text(free))
    set_text(child(view,"brand"),"ผู้พัฒนา: Xaou009")
    set_visible(child(view,"npcPortrait"),false)

    set_visible(child(view,"menuPanel"),false)
    set_visible(child(view,"menuQuick"),false)
    set_visible(child(view,"menuNpc"),false)
    set_visible(child(view,"menuBook"),false)
    set_visible(child(view,"menuWorld"),false)
    set_visible(child(view,"menuDeveloper"),false)

    set_text(child(view,"sectionTitle"),"เลือกโหมดก่อสร้าง")
    set_text(child(view,"description"),"แตะปุ่มเพื่อเปิดหรือปิด ระบบจะแสดงสถานะล่าสุดทันที")
    set_text(child(view,"feature1"),"สร้างด่วน\n"..state_text(quick))
    set_text(child(view,"feature2"),"สร้างฟรี\n"..state_text(free))
    set_text(child(view,"feature3"),"ปิดเครื่องมือทั้งหมด")
    set_text(child(view,"feature4"),"รีเฟรชสถานะ")
    set_text(child(view,"btnLanguage"),"กลับ Mod Center")
    for i=1,4 do set_visible(child(view,"feature"..tostring(i)),true) end
    for i=5,8 do set_visible(child(view,"feature"..tostring(i)),false) end
end

local function toggle(view,which)
    local ok,err
    if which=="quick" then ok,err=toggle_quick_build() else ok,err=toggle_free_build() end
    if not ok then show_message("เปลี่ยนสถานะไม่สำเร็จ\n"..tostring(err)) end
    refresh(view)
end

local function disable_all(view)
    local ok,err=pcall(function()
        if Xaou_ConstructionToolsState.QuickBuildEnable then toggle_quick_build() end
        if Xaou_ConstructionToolsState.FreeBuildEnable then
            local restored,restoreError=disable_free_build();if not restored then error(restoreError) end
        end
    end)
    if not ok then show_message("ปิดเครื่องมือไม่สำเร็จ\n"..tostring(err)) end
    refresh(view)
end

function Xaou_OpenConstructionToolsWindow()
    Xaou_CloseConstructionToolsWindow()
    local pkg=UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root=(GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if not pkg or not root then return false,"FairyGUI/GRoot not found" end
    pcall(function() pkg.AddPackage("UI/XaoCtr") end)
    local view=nil;local ok,err=pcall(function() view=pkg.CreateObject("XaoCtr","XaouModCenterWindow") end)
    if not ok or not view then return false,tostring(err or "CreateObject returned nil") end
    XCT_View=view;root:AddChild(view);view.x=(root.width-view.width)/2;view.y=(root.height-view.height)/2

    local close=child(view,"btnClose");if close then close.onClick:Add(Xaou_CloseConstructionToolsWindow) end
    local quick=child(view,"feature1");if quick then quick.onClick:Add(function() toggle(view,"quick") end) end
    local free=child(view,"feature2");if free then free.onClick:Add(function() toggle(view,"free") end) end
    local disable=child(view,"feature3");if disable then disable.onClick:Add(function() disable_all(view) end) end
    local reload=child(view,"feature4");if reload then reload.onClick:Add(function() refresh(view) end) end
    local back=child(view,"btnLanguage");if back then back.onClick:Add(function()
        Xaou_CloseConstructionToolsWindow()
        if Xaou_OpenStandaloneModCenter then Xaou_OpenStandaloneModCenter(Xaou_CurrentNpcTarget) end
    end) end
    refresh(view);return true
end
