-- Xaou Mod Center. Routes to existing feature windows without replacing game logic.

local XMC_View, XMC_Target, XMC_Section = nil, nil, "quick"
local XMC_CompatShell = false
local XMC_Page, XMC_PageSize = 1, 6
local XMC_FeatureData = {}
local XMC_WindowTitle = "Xaou ACS Mod"
Xaou_ModCenter_Language = Xaou_ModCenter_Language or "th"

local function xmc_is_english()
    if Xaou_IsEnglish then return Xaou_IsEnglish() end
    return Xaou_ModCenter_Language == "en"
end

local function xmc_t(thai, english)
    if xmc_is_english() then return english or thai end
    return thai
end

local XMC_Sections = {
    quick = {title="เมนู ฟังก์ชั่น", titleEn="Function Menu", desc="ฟังก์ชันที่ ACS_Mod มีอยู่ตอนนี้", descEn="Available ACS_Mod features", features={
        {text="เสกไอเทม", textEn="Spawn Items", action="item"}, {text="เปิดใจ+เพิ่มความสัมพันธ์", textEn="Open Heart + Max Favor", action="jianghu"},
        {text="เปิดคลังจักรวาล", textEn="Open Mini Universe", action="space"}, {text="เครื่องมือไอเทม", textEn="Item Tools", action="world_item"},
        {text="เปิด-ปิด ก่อสร้าง", textEn="Construction Tools", action="tools"}, {text="เวลา / ฤดูกาล / อากาศ", textEn="Time / Season / Weather", action="time_weather"},
        {text="เรียกบอส", textEn="Summon Boss", action="boss"}, {text="เปิด-ปิดคลังอัตโนมัต", textEn="World Tools", action="world_world"},

        {text="ตั้งค่า FPS", textEn="Frame Rate Settings", action="fps"}, {text="จัดการแผนที่", textEn="Map Management", action="map_tools"},
        {text="ตัวเลขความเสียหาย", textEn="Damage Numbers", action="damage_numbers"},
        {text="เปิดกล่องไท่อี้ทั้งหมด", textEn="Open All Taiyi Boxes", action="open_taiyi_boxes"},
        {text="เปิดกล่องอื่นทั้งหมด", textEn="Open All Other Boxes", action="open_other_boxes"},
         
         
    }},
    npc = {title="ระบบ NPC", titleEn="NPC System", desc="จัดการตัวละครและดึงคนเข้าสำนัก", descEn="Manage characters and recruit NPCs", features={
        {text="ปรับแต่งวิชาเทพ", textEn="Divine Cultivation Stats", action="god_practice_stats"},
        {text="ปรับแต่งวิชากายา", textEn="Body Cultivation Tools", action="body_practice_tools"},
        {text="แก้ไขค่า NPC ", textEn="Edit NPC", action="legacy_npc"}, {text="ดึง NPC เข้าสำนัก", textEn="Recruit NPC", action="selector"},
        {text="เพิ่มค่าสถานะทั้ง 5", textEn="Increase Five Attributes", action="boost_five_stats"}, {text="ทะลวงขั้นทันที", textEn="Break Through Now", action="breakthrough_now"},
        {text="ชุบชีวิต NPC", textEn="Revive NPC", action="revive_npc"}, {text="ขโมยของ NPC", textEn="Claim Secret Treasure", action="steal_npc_item"},
        {text="ยืดเวลาทัณฑ์สวรรค์", textEn="Delay Heavenly Tribulation", action="extend_heavenly_tribulation"},
        {text="สัตว์เลี้ยงโตทันที", textEn="Instant Pet Growth", action="instant_pet_growth"},
        {text="ปลุกสติปัญญาเต็มทันที", textEn="Full Pet Awakening", action="awaken_pet_intelligence"},


        
    }},
    book = {title="คัมภีร์และวิชา", titleEn="Manuals and Arts", desc="ระบบหอคัมภีร์และการเรียนวิชา", descEn="Library and cultivation art tools", features={
        {text="เก็บคัมภีร์เข้าหอ", textEn="Store Manuals in Library", action="bulk_book"}, {text="เรียนวิชา", textEn="Learn Cultivation Arts", action="learn"},
        {text="หนังสือคัมภีร์", textEn="Manual Book Tools", action="book_menu"},
        
    }},
    world = {title="กำลังพัฒนา", titleEn="In Development", desc="กำลังพัฒนา", descEn="Features under development", features={
        
       -- {text="เปิดแผนที่วาร์ป", action="warp_map"}, {text="วาร์ป NPC กลับสำนัก", action="warp_home"}, --
       -- {text="เครื่องมือสร้าง", action="tools"}, --
        
    }},
    developer = {title="แจ้งปัญหา", titleEn="Report an Issue", desc="แจ้งปัญหาถึงผู้จัดทำม็อด", descEn="Contact the mod developer", features={
        {text="Facebook ผู้พัฒนา", textEn="Developer Facebook", action="developer_facebook"},
        {text="GitHub ผู้พัฒนา", textEn="Developer GitHub", action="developer_github"},
        -- {text="เปิด Mod Center เดิม", action="legacy_npc"},
        
    }},
}



table.insert(XMC_Sections.npc.features, 1, {
    text="กำหนดจำนวนศิษย์สูงสุด",
    textEn="Set Disciple Capacity",
    action="school_capacity"
})

local function xmc_child(view, name)
    local value=nil; pcall(function() value=view:GetChild(name) end); return value
end
local function xmc_text(obj, value)
    if not obj then return end
    pcall(function() obj.text=tostring(value or "") end); pcall(function() obj.title=tostring(value or "") end)
end
local function xmc_visible(obj, value)
    if not obj then return end
    pcall(function() obj.visible=value==true end); pcall(function() obj.touchable=value==true end); pcall(function() obj.enabled=value==true end)
end
local function xmc_enabled(obj, value)
    if not obj then return end
    pcall(function() obj.enabled=value==true end)
    pcall(function() obj.touchable=value==true end)
    pcall(function() obj.alpha=value==true and 1 or 0.45 end)
end
local function xmc_name(npc)
    if Xaou_SafeNpcName then return Xaou_SafeNpcName(npc) end
    local name=xmc_t("NPC เป้าหมาย", "Target NPC"); pcall(function() name=tostring(npc.Name or npc:GetName()) end); return name
end
local function xmc_real_npc(npc)
    if Xaou_GetRealNpcObject then return Xaou_GetRealNpcObject(npc) end
    local real=npc; pcall(function() if npc.npcObj then real=npc.npcObj end end); return real
end
local function xmc_update_target(view)
    local name=xmc_name(XMC_Target)
    if XMC_CompatShell then
        xmc_text(xmc_child(view,"subtitle"),xmc_t("NPC เป้าหมาย: ", "Target NPC: ")..name..xmc_t(" | ผู้พัฒนา: Xaou009", " | Developer: Xaou009"))
    else
        xmc_text(xmc_child(view,"npcName"),name)
    end
    local status=xmc_t("พร้อมใช้งาน", "Ready")
    local real=xmc_real_npc(XMC_Target)
    pcall(function()
        local school=real.SchoolID or 0
        local stage=real.Practice and real.Practice.GongStage or "-"
        status=xmc_t("สำนัก: ", "Sect: ")..tostring(school)..xmc_t(" | ขั้นฝึกฝน: ", " | Stage: ")..tostring(stage)
    end)
    if not XMC_CompatShell then xmc_text(xmc_child(view,"npcStatus"),status) end
    local icon=""; pcall(function() icon=tostring(real.Race.TexPath or real.Race.Rolepaint or "") end)
    local loader=xmc_child(view,XMC_CompatShell and "portrait" or "npcPortrait"); pcall(function() loader.url=icon end); xmc_visible(loader,icon~="")
end
local function xmc_refresh(view)
    xmc_text(xmc_child(view,"title"),XMC_WindowTitle)
    local section=XMC_Sections[XMC_Section] or XMC_Sections.quick
    local total=#section.features
    local maxPage=math.max(1,math.ceil(total/XMC_PageSize))
    XMC_Page=math.max(1,math.min(XMC_Page,maxPage))
    local first=(XMC_Page-1)*XMC_PageSize+1
    xmc_text(xmc_child(view,XMC_CompatShell and "npcName" or "sectionTitle"),xmc_is_english() and section.titleEn or section.title)
    local sectionDesc=xmc_is_english() and section.descEn or section.desc
    xmc_text(xmc_child(view,XMC_CompatShell and "npcStatus" or "description"),sectionDesc..xmc_t("  |  หน้า ", "  |  Page ")..tostring(XMC_Page).."/"..tostring(maxPage))
    XMC_FeatureData={}
    for i=1,XMC_PageSize do
        local btn=xmc_child(view,XMC_CompatShell and (i<=3 and ({"btnOpenHeart","btnMaxFavor","btnRefresh"})[i] or "") or ("feature"..i)); local data=section.features[first+i-1]
        if data then xmc_text(btn,xmc_is_english() and data.textEn or data.text); XMC_FeatureData[i]=data; xmc_visible(btn,true)
        else xmc_visible(btn,false) end
    end
    if not XMC_CompatShell then
        local prev,nextb=xmc_child(view,"feature7"),xmc_child(view,"feature8")
        xmc_text(prev,xmc_t("◀ ย้อนกลับ", "◀ Previous"));xmc_text(nextb,xmc_t("ถัดไป ▶", "Next ▶"))
        xmc_visible(prev,true);xmc_visible(nextb,true)
        xmc_enabled(prev,XMC_Page>1);xmc_enabled(nextb,XMC_Page<maxPage)
    end
    local menus={{"menuQuick","quick","เมนูฟังก์ชั่น","Functions"},{"menuNpc","npc","NPC","NPC"},{"menuBook","book","คัมภีร์","Manuals"},{"menuWorld","world","โลก","World"},{"menuDeveloper","developer","ผู้พัฒนา","Developer"}}
    for index,m in ipairs(menus) do
        local menuName=XMC_CompatShell and ("npcBtn"..tostring(index)) or m[1]
        xmc_text(xmc_child(view,menuName),(XMC_Section==m[2] and "▶ " or "")..(xmc_is_english() and m[4] or m[3]))
    end
    if XMC_CompatShell then
        xmc_text(xmc_child(view,"npcBtn6"),xmc_t("ปิดหน้าต่าง", "Close Window"))
        xmc_visible(xmc_child(view,"btnPrev"),false);xmc_visible(xmc_child(view,"btnNext"),false);xmc_visible(xmc_child(view,"txtPage"),false)
        xmc_text(xmc_child(view,"hint"),xmc_t("เลือกหมวดด้านซ้าย แล้วเลือกเครื่องมือด้านขวา", "Choose a category on the left, then select a tool on the right"))
    end
    xmc_text(xmc_child(view,"btnLanguage"),xmc_t("ภาษา: TH", "Language: EN"))
end

function Xaou_ToggleModCenterLanguage()
    local language = xmc_is_english() and "th" or "en"
    if Xaou_SetLanguage then Xaou_SetLanguage(language) else Xaou_ModCenter_Language = language end
    if XMC_View then
        xmc_update_target(XMC_View)
        xmc_refresh(XMC_View)
    end
    return Xaou_ModCenter_Language
end

function Xaou_CloseStandaloneModCenter()
    if XMC_View then pcall(function() XMC_View:RemoveFromParent() end);pcall(function() XMC_View:Dispose() end);XMC_View=nil end
end

local function xmc_open_legacy()
    if Xaou_OpenNpcManagerWindow then return Xaou_OpenNpcManagerWindow(XMC_Target) end
    if XaouItemWindow then
        XaouItemWindow:SetNpcTarget(XMC_Target); XaouItemWindow.mainMode="npc"; XaouItemWindow.npcPage="quick"
        XaouItemWindow:Show(); pcall(function() XaouItemWindow:RefreshList() end)
    end
end
local function xmc_action(action)
    local worldToolSections = {
        world_item = "item",
        world_world = "world",
        world_season = "season",
        world_weather = "weather",
        world_building = "building",
    }
    if worldToolSections[action] then
        if Xaou_OpenWorldToolsWindow == nil then
            pcall(require, "Scripts/Xaou_WorldTools_Core.lua")
            pcall(require, "Scripts/Xaou_WorldTools_Window.lua")
        end
        if Xaou_OpenWorldToolsWindow then
            local section = worldToolSections[action]
            Xaou_CloseStandaloneModCenter()
            local ok, result, detail = pcall(function()
                return Xaou_OpenWorldToolsWindow(nil, section)
            end)
            if ok and result ~= false then return true end
            if world then
                world:ShowMsgBox(xmc_t("เปิดเครื่องมือไม่สำเร็จ\n", "Failed to open tool window\n") .. tostring(detail or result))
            end
            return false
        end
        if world then world:ShowMsgBox(xmc_t("ไม่พบระบบเครื่องมือโลก", "World Tools system was not found")) end
        return false
    end
    if action=="school_capacity" then
        if Xaou_OpenSchoolCapacitySelector==nil then
            pcall(require, 'Scripts/Xaou_SchoolCapacity.lua')
        end
        if Xaou_OpenSchoolCapacitySelector then
            return Xaou_OpenSchoolCapacitySelector()
        end
        if world then world:ShowMsgBox(xmc_t("ไม่พบระบบกำหนดจำนวนศิษย์", "Disciple capacity system was not found")) end
        return false
    end
    if action=="damage_numbers" then
        local damageMod=GameMain:GetMod("Xaou_DamageNumbers",true)
        if damageMod==nil then
            pcall(require,'Scripts/Xaou_DamageNumbers.lua')
            damageMod=GameMain:GetMod("Xaou_DamageNumbers",true)
        end
        if damageMod~=nil and damageMod.Toggle~=nil then
            return damageMod:Toggle()
        end
        if world then world:ShowMsgBox(xmc_t("ไม่พบระบบตัวเลขความเสียหาย", "Damage Numbers system was not found")) end
        return false
    end
    if action=="body_practice_tools" then
        if Xaou_OpenBodyPracticeWindow==nil then
            pcall(require,"Scripts/Xaou_BodyPractice_Window.lua")
        end
        if Xaou_OpenBodyPracticeWindow then
            local ok,result,detail=pcall(function() return Xaou_OpenBodyPracticeWindow(XMC_Target) end)
            if ok and result~=false then Xaou_CloseStandaloneModCenter();return result end
            if world then world:ShowMsgBox(xmc_t("เปิดหน้าปรับแต่งวิชากายาไม่สำเร็จ\n","Failed to open Body Cultivation Tools\n")..tostring(detail or result)) end
            return false
        end
        if world then world:ShowMsgBox(xmc_t("ไม่พบระบบปรับแต่งวิชากายา","Body cultivation tool was not found")) end
        return false
    end
    if action=="god_practice_stats" then
        if XMC_Target==nil then
            if world then world:ShowMsgBox(xmc_t("กรุณาเลือก NPC ก่อน", "Please select an NPC first")) end
            return false
        end
        if Xaou_OpenGodPracticeWindow==nil then
            pcall(require, 'Scripts/Xaou_GodPractice_Window.lua')
        end
        if Xaou_OpenGodPracticeWindow then
            local target=XMC_Target
            Xaou_CloseStandaloneModCenter()
            local ok,result=pcall(function() return Xaou_OpenGodPracticeWindow(target) end)
            if ok and result~=false then return true end
            if world then world:ShowMsgBox(xmc_t("เปิดหน้าปรับแต่งวิชาเทพไม่สำเร็จ\n", "Failed to open Divine Cultivation Stats\n")..tostring(result)) end
            return false
        end
        if world then world:ShowMsgBox(xmc_t("ไม่พบระบบปรับแต่งวิชาเทพ", "Divine cultivation stat system was not found")) end
        return false
    end
    if action=="open_other_boxes" then
        if Xaou_ConfirmOpenAllOtherBoxes==nil then pcall(require,'Scripts/Xaou_TaiyiBox_Core.lua') end
        if Xaou_ConfirmOpenAllOtherBoxes then
            return Xaou_ConfirmOpenAllOtherBoxes(XMC_Target)
        end
        if world then world:ShowMsgBox(xmc_t("ไม่พบระบบเปิดกล่องชนิดอื่น", "Other box system was not found")) end
        return false
    end
    if action=="open_taiyi_boxes" then
        if Xaou_ConfirmOpenAllTaiyiBoxes==nil then pcall(require,'Scripts/Xaou_TaiyiBox_Core.lua') end
        if Xaou_ConfirmOpenAllTaiyiBoxes then
            return Xaou_ConfirmOpenAllTaiyiBoxes(XMC_Target)
        end
        if world then world:ShowMsgBox(xmc_t("ไม่พบระบบเปิดกล่องไท่อี้", "Taiyi box system was not found")) end
        return false
    end
    if action=="fps" and Xaou_OpenFpsWindow then
        Xaou_CloseStandaloneModCenter()
        return Xaou_OpenFpsWindow()
    end
    if action=="item" and Xaou_OpenItemSpawnerWindow then
        local ok, result = pcall(Xaou_OpenItemSpawnerWindow)
        if ok and result ~= false then
            Xaou_CloseStandaloneModCenter()
            return result
        end
        if world then world:ShowMsgBox(xmc_t("เปิดหน้าต่างเสกไอเทมไม่สำเร็จ\n", "Failed to open Item Spawner\n")..tostring(result)) end
        return false
    end
    if action=="jianghu" and Xaou_OpenJianghuRelationsWindow then return Xaou_OpenJianghuRelationsWindow() end
    if action=="boss" then
        if Xaou_OpenBossSummonWindow==nil then pcall(require,'Scripts/XaouBossSummonWindow.lua') end
        if Xaou_OpenBossSummonWindow then return Xaou_OpenBossSummonWindow() end
    end
    if action=="building_temp" then
        if Xaou_OpenWorldToolsWindow then
            Xaou_CloseStandaloneModCenter()
            return Xaou_OpenWorldToolsWindow(nil, "building")
        end
    end
    if action=="manual_books" and Xaou_OpenBookMenuWindow then
        local ok,result=pcall(function()
            return Xaou_OpenBookMenuWindow(XMC_Target, "manual")
        end)
    
        if ok and result~=false then
            Xaou_CloseStandaloneModCenter()
            return result
        end
    
        if world then
            world:ShowMsgBox(
                xmc_t("เปิดหน้าหนังสือคัมภีร์ไม่สำเร็จ\n", "Failed to open Manual Books\n")..
                tostring(result)
            )
        end
        return false
    end
    if action=="learn" and Xaou_OpenLearnWindow then
        local target=XMC_Target
        local ok,result=pcall(function() return Xaou_OpenLearnWindow(target) end)
        if ok and result~=false then Xaou_CloseStandaloneModCenter();return result end
        if world then world:ShowMsgBox(xmc_t("เปิดหน้าเรียนวิชาไม่สำเร็จ\n", "Failed to open Cultivation Learning\n")..tostring(result)) end
        return false
    end
    if action=="time_weather" then
        if Xaou_OpenWorldToolsWindow == nil then
            pcall(require, "Scripts/Xaou_WorldTools_Core.lua")
            pcall(require, "Scripts/Xaou_WorldTools_Window.lua")
        end
        if Xaou_OpenWorldToolsWindow ~= nil then
            Xaou_CloseStandaloneModCenter()
            local ok, result = pcall(function()
                return Xaou_OpenWorldToolsWindow(nil, "climate")
            end)
            if ok and result ~= false then return true end
            if world then world:ShowMsgBox(xmc_t("เปิดเมนูเวลา / ฤดูกาล / อากาศไม่สำเร็จ\n", "Failed to open Time / Season / Weather\n") .. tostring(result)) end
            return false
        end
        if world then world:ShowMsgBox(xmc_t("ไม่พบหน้าต่างเครื่องมือเวลา", "Time tools window was not found")) end
        return false
    end
    if action=="instant_pet_growth" then
        if Xaou_InstantGrowPet == nil then
            pcall(require, "Scripts/Xaou_PetGrowth_Core.lua")
        end
        if Xaou_InstantGrowPet == nil then
            if world then world:ShowMsgBox(xmc_t("ไม่พบระบบเร่งการเติบโตของสัตว์เลี้ยง", "Pet growth system was not found")) end
            return false
        end
        return Xaou_InstantGrowPet(XMC_Target)
    end
    if action=="awaken_pet_intelligence" then
        if Xaou_AwakenPetIntelligence == nil then
            pcall(require, "Scripts/Xaou_PetGrowth_Core.lua")
        end
        if Xaou_AwakenPetIntelligence == nil then
            if world then world:ShowMsgBox(xmc_t("ไม่พบระบบปลุกสติปัญญาสัตว์เลี้ยง", "Pet intelligence system was not found")) end
            return false
        end
        return Xaou_AwakenPetIntelligence(XMC_Target)
    end
    if action=="boost_five_stats" then
        if XMC_Target == nil then
            if world then world:ShowMsgBox(xmc_t("กรุณาเลือก NPC ก่อน", "Please select an NPC first")) end
            return false
        end

        if Xaou_ApplyNpcActions == nil then
            pcall(require, "Scripts/Xaou_NpcHelper.lua")
            pcall(require, "Scripts/Xaou_NpcActions.lua")
        end

        if Xaou_ApplyNpcActions == nil then
            if world then world:ShowMsgBox(xmc_t("ไม่พบระบบเพิ่มค่าสถานะ NPC", "NPC attribute system was not found")) end
            return false
        end

        local ok, success, detail = pcall(function()
            return Xaou_ApplyNpcActions(XMC_Target, {
                {kind="addmodifier", id="QuanBu76"},
            })
        end)

        if ok and success == true then
            if world then world:ShowMsgBox(xmc_t("เพิ่มค่าสถานะทั้ง 5 สำเร็จแล้ว", "All five attributes were increased")) end
            return true
        end

        if world then
            world:ShowMsgBox(xmc_t("เพิ่มค่าสถานะไม่สำเร็จ\n", "Failed to increase attributes\n") .. tostring(detail or success))
        end
        return false
    end
    if action=="breakthrough_now" then
        if XMC_Target == nil then
            if world then world:ShowMsgBox(xmc_t("กรุณาเลือก NPC ก่อน", "Please select an NPC first")) end
            return false
        end

        if Xaou_ApplyNpcActions == nil then
            pcall(require, "Scripts/Xaou_NpcHelper.lua")
            pcall(require, "Scripts/Xaou_NpcActions.lua")
        end

        if Xaou_ApplyNpcActions == nil then
            if world then world:ShowMsgBox(xmc_t("ไม่พบระบบจัดการ NPC", "NPC management system was not found")) end
            return false
        end

        local ok, success, detail = pcall(function()
            return Xaou_ApplyNpcActions(XMC_Target, {
                {kind="breakthrough"},
            })
        end)

        if ok and success == true then
            if world then world:ShowMsgBox(xmc_t("ใช้คำสั่งทะลวงขั้นสำเร็จแล้ว", "Breakthrough command completed")) end
            return true
        end

        if world then
            world:ShowMsgBox(xmc_t("ทะลวงขั้นไม่สำเร็จ\n", "Breakthrough failed\n") .. tostring(detail or success))
        end
        return false
    end
    if action=="revive_npc" or action=="steal_npc_item" then
        if XMC_Target == nil then
            if world then world:ShowMsgBox(xmc_t("กรุณาเลือก NPC ก่อน", "Please select an NPC first")) end
            return false
        end

        if Xaou_ApplyNpcActions == nil then
            pcall(require, "Scripts/Xaou_NpcHelper.lua")
            pcall(require, "Scripts/Xaou_NpcActions.lua")
        end

        if Xaou_ApplyNpcActions == nil then
            if world then world:ShowMsgBox(xmc_t("ไม่พบระบบจัดการ NPC", "NPC management system was not found")) end
            return false
        end

        local modifierId = action=="revive_npc"
            and "Modifier_YinYangShuangYu76"
            or "Dan_BaiYanLang76"

        Xaou_CloseStandaloneModCenter()
        local ok, success, detail = pcall(function()
            return Xaou_ApplyNpcActions(XMC_Target, {
                {kind="addmodifier", id=modifierId},
            })
        end)

        if ok and success == true then return true end
        if world then
            world:ShowMsgBox(xmc_t("เปิดโหมดเลือกเป้าหมายไม่สำเร็จ\n", "Failed to start target selection\n") .. tostring(detail or success))
        end
        return false
    end
    if action=="extend_heavenly_tribulation" then
        if XMC_Target == nil then
            if world then world:ShowMsgBox(xmc_t("กรุณาเลือก NPC ก่อน", "Please select an NPC first")) end
            return false
        end

        if Xaou_ApplyNpcActions == nil then
            pcall(require, "Scripts/Xaou_NpcHelper.lua")
            pcall(require, "Scripts/Xaou_NpcActions.lua")
        end

        if Xaou_ApplyNpcActions == nil then
            if world then world:ShowMsgBox(xmc_t("ไม่พบระบบจัดการ NPC", "NPC management system was not found")) end
            return false
        end

        local ok, success, detail = pcall(function()
            return Xaou_ApplyNpcActions(XMC_Target, {
                {kind="addmodifier", id="Dan_ZhongLi76"},
            })
        end)

        if ok and success == true then
            if world then world:ShowMsgBox(xmc_t("ยืดเวลาทัณฑ์สวรรค์แล้ว 100 วัน", "Heavenly Tribulation delayed by 100 days")) end
            return true
        end

        if world then
            world:ShowMsgBox(xmc_t("ยืดเวลาทัณฑ์สวรรค์ไม่สำเร็จ\n", "Failed to delay Heavenly Tribulation\n") .. tostring(detail or success))
        end
        return false
    end
    if action=="bulk_book" and Xaou_OpenBulkEsotericaWindow then
        local target=XMC_Target
        local ok,result=pcall(function() return Xaou_OpenBulkEsotericaWindow(target) end)
        if ok and result~=false then Xaou_CloseStandaloneModCenter();return result end
        if world then world:ShowMsgBox(xmc_t("เปิดหน้าเก็บคัมภีร์ไม่สำเร็จ\n", "Failed to open Manual Storage\n")..tostring(result)) end
        return false
    end
    if action=="unlock_all_gong" then
        if Xaou_RunNewBookCommand==nil then
            pcall(require, "Scripts/Xaou_BookMenu_Core.lua")
        end
    
        if Xaou_RunNewBookCommand then
            local ok, success, detail=pcall(function()
                return Xaou_RunNewBookCommand(XMC_Target, {
                    text=xmc_t("วิชาสายหลักทั้งหมด", "All Main Cultivation Arts"),
                    category="unlock",
                    story="Xaou_Unlock_AllGong",
                })
            end)
    
            if ok and success==true then
                if world then
                    world:ShowMsgBox(xmc_t("ปลดล็อกวิชาสายหลักทั้งหมดแล้ว", "All main cultivation arts were unlocked"))
                end
                return true
            end
    
            if world then
                world:ShowMsgBox(
                    xmc_t("ปลดล็อกวิชาไม่สำเร็จ\n", "Failed to unlock cultivation arts\n")..
                    tostring(detail or success)
                )
            end
            return false
        end
    end
    if action=="book_menu" and Xaou_OpenBookMenuWindow then
        local target=XMC_Target
        local ok,result=pcall(function() return Xaou_OpenBookMenuWindow(target) end)
        if ok and result~=false then Xaou_CloseStandaloneModCenter();return result end
        if world then world:ShowMsgBox(xmc_t("เปิดเมนูคัมภีร์ไม่สำเร็จ\n", "Failed to open Manual Menu\n")..tostring(result)) end
        return false
    end
    if action=="world_tools" and Xaou_OpenWorldToolsWindow then
        local ok,result=pcall(function() return Xaou_OpenWorldToolsWindow(nil,"world") end)
        if ok and result~=false then Xaou_CloseStandaloneModCenter();return result end
        if world then world:ShowMsgBox(xmc_t("เปิดเครื่องมือโลกไม่สำเร็จ\n", "Failed to open World Tools\n")..tostring(result)) end
        return false
    end
    if action=="map_tools" then
        if Xaou_OpenMapToolsWindow==nil then
            pcall(require, "Scripts/Xaou_MapTools_Window.lua")
        end
        if Xaou_OpenMapToolsWindow then
            local ok,result,detail=pcall(function() return Xaou_OpenMapToolsWindow() end)
            if ok and result~=false then Xaou_CloseStandaloneModCenter();return result end
            if world then
                world:ShowMsgBox(xmc_t("เปิดหน้าจัดการแผนที่ไม่สำเร็จ\n", "Failed to open Map Management\n")..tostring(detail or result))
            end
            return false
        end
        if world then world:ShowMsgBox(xmc_t("ไม่พบระบบจัดการแผนที่", "Map Management system was not found")) end
        return false
    end
    if action=="space" then
        local opener = Xaou_SpaceRing_OpenOriginalStorageUI
        if opener == nil then
            if world then world:ShowMsgBox(xmc_t("ไม่พบฟังก์ชันเปิดคลังจักรวาลเดิมของเกม", "The original Mini Universe function was not found")) end
            return false
        end

        local ok, result = pcall(function()
            return opener(XMC_Target)
        end)

        if ok and result ~= false then
            return result
        end

        if world then
            world:ShowMsgBox(xmc_t("เปิดคลังจักรวาลไม่สำเร็จ\n", "Failed to open Mini Universe\n") .. tostring(result))
        end
        return false
    end
    if action=="developer_facebook" then
        local url = "https://web.facebook.com/asstasst2/?locale=th_TH"

        local ok, result = pcall(function()
            CS.UnityEngine.Application.OpenURL(url)
            return true
        end)

        if ok and result == true then
            return true
        end

        if world then
            world:ShowMsgBox(
                xmc_t(
                    "เปิด Facebook ไม่สำเร็จ",
                    "Failed to open Facebook"
                )
            )
        end

        return false
    end
    if action=="developer_github" then
        local url = "https://github.com/xaouxaou009-debug/Mod"
        if Xaou_OpenUrl == nil then
            pcall(require, "Scripts/Xaou_NpcHelper.lua")
        end

        local ok, success, detail = pcall(function()
            if Xaou_OpenUrl ~= nil then
                return Xaou_OpenUrl(url)
            end
            if CS and CS.UnityEngine and CS.UnityEngine.Application then
                CS.UnityEngine.Application.OpenURL(url)
                return true
            end
            error("Application.OpenURL not found")
        end)

        if ok and success == true then return true end
        if world then
            world:ShowMsgBox(xmc_t("เปิด GitHub ไม่สำเร็จ\n", "Failed to open GitHub\n") .. tostring(detail or success))
        end
        return false
    end
    Xaou_CloseStandaloneModCenter()
    if action=="tools" and Xaou_OpenConstructionToolsWindow then return Xaou_OpenConstructionToolsWindow() end
    if action=="selector" and Xaou_OpenExternalNpcSelector then return Xaou_OpenExternalNpcSelector() end
    if action=="warp_map" and Xaou_WarpSystem and Xaou_WarpSystem.ShowMap then return Xaou_WarpSystem.ShowMap() end
    if action=="warp_home" and Xaou_WarpSystem and Xaou_WarpSystem.WarpSelectedNpcHome then return Xaou_WarpSystem.WarpSelectedNpcHome(XMC_Target) end
    if action=="map_info" and Xaou_WarpSystem and Xaou_WarpSystem.DebugMapInfo then return Xaou_WarpSystem.DebugMapInfo() end
    if action=="legacy_npc" then return xmc_open_legacy() end
    if world then world:ShowMsgBox(xmc_t("ฟังก์ชันนี้ยังไม่พร้อมใช้งาน", "This feature is not available yet")) end
end

function Xaou_OpenStandaloneModCenter(npc)
    Xaou_CloseStandaloneModCenter(); XMC_Target=npc or Xaou_CurrentNpcTarget; XMC_Section="quick";XMC_Page=1
    local pkg=UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage); local root=(GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if not pkg or not root then return false end
    pcall(function() pkg.AddPackage("UI/XaoCtr") end)
    local view=nil
    local errors={}
    local function try_create(label, creator)
        if view then return end
        local ok, value=pcall(creator)
        if ok and value then view=value else errors[#errors+1]=label..": "..tostring(value) end
    end
    try_create("CreateObject",function() return pkg.CreateObject("XaoCtr","XaouModCenterWindow") end)
    try_create("CreateObject.xml",function() return pkg.CreateObject("XaoCtr","XaouModCenterWindow.xml") end)
    try_create("CreateObjectFromURL",function() return pkg.CreateObjectFromURL("ui://xmc97319xmc01") end)
    try_create("package item URL",function()
        local url=pkg.GetItemURL("XaoCtr","XaouModCenterWindow")
        if not url or tostring(url)=="" then return nil end
        return pkg.CreateObjectFromURL(url)
    end)
    if not view then
        try_create("compat JianghuNpcWindow",function() return nil end)
        if view then XMC_CompatShell=true end
    else
        XMC_CompatShell=false
    end
    if not view then return false,table.concat(errors,"\n") end
    XMC_View=view;root:AddChild(view);view.x=(root.width-view.width)/2;view.y=(root.height-view.height)/2
    xmc_text(xmc_child(view,"btnClose"),"×");xmc_text(xmc_child(view,"btnLanguage"),xmc_t("ภาษา: TH", "Language: EN"))
    local menus={{"menuQuick","quick"},{"menuNpc","npc"},{"menuBook","book"},{"menuWorld","world"},{"menuDeveloper","developer"}}
    for index,m in ipairs(menus) do
        local buttonName, sectionName=XMC_CompatShell and ("npcBtn"..tostring(index)) or m[1],m[2]
        local b=xmc_child(view,buttonName)
        if b then b.onClick:Add(function() XMC_Section=sectionName;XMC_Page=1;xmc_refresh(view) end) end
    end
    local featureLimit=XMC_CompatShell and 3 or XMC_PageSize
    for i=1,featureLimit do
        local featureIndex=i
        local b=xmc_child(view,XMC_CompatShell and ({"btnOpenHeart","btnMaxFavor","btnRefresh"})[featureIndex] or ("feature"..featureIndex))
        if b then b.onClick:Add(function() local d=XMC_FeatureData[featureIndex];if d then xmc_action(d.action) end end) end
    end
    if not XMC_CompatShell then
        local prev,nextb=xmc_child(view,"feature7"),xmc_child(view,"feature8")
        if prev then prev.onClick:Add(function() if XMC_Page>1 then XMC_Page=XMC_Page-1;xmc_refresh(view) end end) end
        if nextb then nextb.onClick:Add(function()
            local section=XMC_Sections[XMC_Section] or XMC_Sections.quick
            local maxPage=math.max(1,math.ceil(#section.features/XMC_PageSize))
            if XMC_Page<maxPage then XMC_Page=XMC_Page+1;xmc_refresh(view) end
        end) end
    end
    local close=xmc_child(view,"btnClose");if close then close.onClick:Add(Xaou_CloseStandaloneModCenter) end
    if XMC_CompatShell then local close2=xmc_child(view,"npcBtn6");if close2 then close2.onClick:Add(Xaou_CloseStandaloneModCenter) end end
    local lang=xmc_child(view,"btnLanguage");if lang then lang.onClick:Add(Xaou_ToggleModCenterLanguage) end
    xmc_update_target(view);xmc_refresh(view);return true
end
