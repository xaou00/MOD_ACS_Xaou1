-- ============================================================
-- XAOU NPC COMMANDS
-- เมนู/รายการคำสั่ง NPC ทั้งหมด
-- ============================================================


function Xaou_IsJianghuPagedPage(page)
    page = tostring(page or "")
    return string.find(page, "jianghu_p", 1, true) == 1
end

function Xaou_GetNpcPageTitle(page)
    page = tostring(page or "main")
    if page == "main" then return "เมนูหลัก" end
    if page == "quick" then return "ด่วน" end
    if page == "character" then return "ตัวละคร" end
    if page == "combat" then return "ต่อสู้" end
    if page == "work" then return "งาน" end
    if page == "cancel" then return "การหลอมโอสถ" end
    if page == "more" then return "เพิ่มเติม" end
    
    if page == "sect" then return "สำนัก" end
    if page == "world" then return "โลก/เวลา" end
    if page == "beast" then return "สัตว์อสูร" end
    if page == "qianKun" then return "จักรวาลย่อส่วน" end
    if page == "system" then return "ระบบ" end
    if page == "debug" then return "Debug" end
    if page == "jianghu" or Xaou_IsJianghuPagedPage(page) or page == "jianghu_all" then return "NPC สำนักอื่น" end
    return page
end


local function Xaou_AddJianghuSeedKeys(dict, seeds, seen)
    if dict == nil then return end
    local function add(value)
        value = tonumber(value) or value
        if value == nil then return end
        local key = tostring(value)
        if not seen[key] then
            seen[key] = true
            table.insert(seeds, value)
        end
    end
    pcall(function()
        for seed, _ in pairs(dict) do add(seed) end
    end)
    pcall(function()
        local e = dict:GetEnumerator()
        while e:MoveNext() do add(e.Current.Key) end
        pcall(function() e:Dispose() end)
    end)
    pcall(function()
        local e = dict.Keys:GetEnumerator()
        while e:MoveNext() do add(e.Current) end
        pcall(function() e:Dispose() end)
    end)
end

local function Xaou_ResolveJianghuDef(mgr, school, seed)
    local def = nil
    pcall(function() def = mgr:GetJHNpcDataByRandomSeed(seed) end)
    if def == nil then
        pcall(function() def = mgr:GetJHNpcDataBySeed(seed) end)
    end
    if def == nil and school ~= nil then
        pcall(function()
            local template = school.JianghuNpcs[seed]
            if template ~= nil then def = mgr:GetJianghuNpcDef(template) end
        end)
    end
    return def
end

local function Xaou_ResolveJianghuName(mgr, def, seed)
    local name = "NPC seed " .. tostring(seed)
    if def ~= nil then
        name = tostring(def.LastName or "") .. tostring(def.FristName or def.FirstName or "")
        if name == "" then name = "NPC seed " .. tostring(seed) end
    end
    pcall(function()
        local gameName = mgr:GetJHNpcName(seed, true, false)
        if gameName ~= nil and tostring(gameName) ~= "" then name = tostring(gameName) end
    end)
    return name
end

-- รวมทะเบียน NPC โลกกับ KnowNpcData เพื่อไม่ให้คนที่เพิ่งรู้จักหายจากรายการ
-- แก้แบบปลอดภัย: แยก "ดึงข้อมูลทั้งหมด" กับ "แสดงเป็นหน้า"
function Xaou_BuildJianghuNpcRawList(limit)
    local list = {}
    local seeds = {}
    local seen = {}
    local maxCount = tonumber(limit or 9999) or 9999

    local ok, err = pcall(function()
        local GSchool = CS.XiaWorld.SchoolGlobleMgr.Instance
        local mgr = JianghuMgr
        if mgr == nil then mgr = CS.XiaWorld.JianghuMgr.Instance end
        if GSchool == nil and mgr == nil then error("ไม่พบระบบ NPC สำนักอื่น") end

        Xaou_AddJianghuSeedKeys(GSchool and GSchool.JianghuNpcs or nil, seeds, seen)
        Xaou_AddJianghuSeedKeys(mgr and mgr.KnowNpcData or nil, seeds, seen)

        table.sort(seeds, function(a, b)
            return tonumber(a) < tonumber(b)
        end)

        for _, seed in ipairs(seeds) do
            local know = nil
            pcall(function() know = mgr:GetKnowNpcData(seed) end)

            -- Keep NPCs from the world registry even when KnowNpcData has not
            -- been created yet. This lets newly generated/encountered NPCs
            -- appear in the list; opening the heart creates KnowNpcData later.
            local def = Xaou_ResolveJianghuDef(mgr, GSchool, seed)
            local name = Xaou_ResolveJianghuName(mgr, def, seed)
            local status = "อยู่"
            pcall(function()
                if GSchool:IsJianghuNpcDie(seed) then status = "ตาย"
                elseif GSchool:IsJianghuNpcLeave(seed) then status = "ออกไปแล้ว" end
            end)

            local fav = "ยังไม่รู้จัก"
            local open = "ปิด"
            if know ~= nil then
                fav = tostring(know.favour or "?")
                if tonumber(know.hlock or 0) == 1 then open = "เปิด" end
            end

            table.insert(list, {
                text = name .. "【" .. status .. " | ❤" .. fav .. " | ใจ:" .. open .. "】",
                page = "jhnpc_" .. tostring(seed)
            })

            if #list >= maxCount then break end
        end
    end)

    if not ok then
        table.insert(list, {text="ERROR ดึงรายชื่อไม่ได้", actions={{kind="message", title="NPC สำนักอื่น", text=tostring(err)}}})
    end
    if #list == 0 then
        table.insert(list, {text="ไม่พบ NPC สำนักอื่น", actions={{kind="message", title="NPC สำนักอื่น", text="ไม่พบข้อมูล JianghuNpcs"}}})
    end

    return list
end

function Xaou_BuildJianghuNpcCommands(page)
    local all = Xaou_BuildJianghuNpcRawList(9999)

    local perPage = 16
    local pageNo = tonumber(page or 1) or 1
    if pageNo < 1 then pageNo = 1 end

    local total = #all
    local totalPage = math.ceil(total / perPage)
    if totalPage < 1 then totalPage = 1 end
    if pageNo > totalPage then pageNo = totalPage end

    local list = {}
    local startIndex = (pageNo - 1) * perPage + 1
    local endIndex = math.min(startIndex + perPage - 1, total)

    for i = startIndex, endIndex do
        table.insert(list, all[i])
    end

    local prevPage = pageNo - 1
    local nextPage = pageNo + 1

    -- ปุ่มเปลี่ยนหน้า: แยกข้อความหน้าออกจากปุ่มถัดไป เพื่อไม่ให้งง
    if prevPage < 1 then
        table.insert(list, {text="◀ หน้าแรกแล้ว", actions={{kind="message", title="NPC สำนักอื่น", text="นี่คือหน้าแรกแล้ว"}}})
    else
        table.insert(list, {text="◀ ก่อนหน้า", page="jianghu_p" .. tostring(prevPage)})
    end

    if nextPage > totalPage then
        table.insert(list, {text="หน้า " .. tostring(pageNo) .. "/" .. tostring(totalPage) .. " | สุดท้ายแล้ว", actions={{kind="message", title="NPC สำนักอื่น", text="นี่คือหน้าสุดท้ายแล้ว"}}})
    else
        table.insert(list, {text="หน้า " .. tostring(pageNo) .. "/" .. tostring(totalPage) .. " | ถัดไป ▶", page="jianghu_p" .. tostring(nextPage)})
    end

    return list
end

function Xaou_BuildJianghuNpcActionPage(page)
    local seed = tostring(page):gsub("jhnpc_", "")
    return {
        { text="🤝 เปิดใจ", actions={{kind="openheartseed", seed=seed}} },
        { text="💞 เปิดใจ + ความชอบเต็ม", actions={{kind="openheartseed", seed=seed, favor=true}} },
        { text="📋 ดูข้อมูล", actions={{kind="jhinfo", seed=seed}} },
        { text="◀ กลับ", page="jianghu" },
    }
end

function Xaou_GetNpcCommands(page)
    page = tostring(page or "main")

    if page == "main" then
        return {
            { text="1. ตั่งค่าด่วน", page="quick" },
            { text="2. ตัวละคร", page="character" },
            { text="3. ต่อสู้", page="combat" },
            { text="5. การหลอมโอสถ", page="cancel" },
            { text="6. เพิ่มเติม", page="more" },
            { text="7. NPC สำนักอื่น", page="jianghu" },
            
        }

    elseif page == "quick" then
        return {
            { text="1. โหมดตายยาก", actions={
                {kind="modifier", prop="RecoveryPower", value=999},
                {kind="modifier", prop="MagicDamageRecoveryPowerAddV", value=9999},
                {kind="modifier", prop="LingAbsorbSpeed", value=1000},
                {kind="modifier", prop="NutritionToJingYuanK", value=1000},
                {kind="modifier", prop="NutritionWaterAutoRecover", value=1000},
            }},
            { text="2. ไม่ต้องกิน/ดื่ม/เหนื่อย", actions={
                {kind="modifier", prop="FatigueConsumeConstant", value=-10},
                {kind="modifier", prop="WaterConsumeConstant", value=-10},
                {kind="modifier", prop="HappyConsumeConstant", value=-10},
                {kind="modifier", prop="NutritionConsumeConstant", value=-10},
                {kind="modifier", prop="PracticeFoodConsumeConstant", value=-10},
            }},
            { text="3. พรสวรรค์สูงสุด", actions={
                {kind="modifier", prop="IntelligenceSkillEXPConstant", value=999},
                {kind="modifier", prop="PotentialOfBasepracticeAddValue", value=1000},
                {kind="modifier", prop="BasepracticeSpeedCoefficient", value=1000},
                {kind="modifier", prop="DeepPracticeSpeedSpecialCoefficient", value=1000},
                {kind="modifier", prop="MindStateBaseValue", value=1000},
                {kind="modifier", prop="SpeedOfMindStateCoefficient", value=1000},
                {kind="modifier", prop="SpeedOfMindStateCoefficientByMoods", value=-1000},
                {kind="modifier", prop="InspirationCoefficient", value=1000},
            }},
            { text="4. หลอมอาวุธ/โอสถระดับเทพ", actions={
                {kind="modifier", prop="FabaoMake_SpeedAddV", value=100000},
                {kind="modifier", prop="FabaoMake_SuccessRateAddV", value=100000},
                {kind="modifier", prop="FabaoMake_LingInheritRateAddV", value=100000},
                {kind="modifier", prop="FabaoMake_QualityAddV", value=100000},
                {kind="modifier", prop="FabaoMake_TwelveRateChance", value=100000},
                {kind="modifier", prop="DanMake_Speed", value=100000},
                {kind="modifier", prop="DanMake_SpeedAddV", value=100000},
                {kind="modifier", prop="DanMake_SuccessRate", value=100000},
                {kind="modifier", prop="DanMake_SuccessRateAddV", value=100000},
            }},
            { text="5. ปรุงโอสถได้ x100", actions={{kind="modifier", prop="DanMake_YieldAddP", value=100}} },
            { text="6. พลังต่อสู้ขั้นสุด", actions={
                {kind="modifier", prop="NpcFight_BaseHitChance", value=1000},
                {kind="modifier", prop="NpcFight_BaseDodgeChance", value=1000},
                {kind="modifier", prop="NpcFight_ShieldConversionEquipAdd", value=1000},
                {kind="modifier", prop="NpcFight_FabaoNum", value=5},
                {kind="modifier", prop="NpcFight_FabaoPowerAddP", value=1000},
                {kind="modifier", prop="NpcFight_SpellPowerAddP", value=1000},
                {kind="modifier", prop="NpcFight_ShieldConversionRateAddP", value=1000},
            }},
            { text="7. โบนัสการฝึกฝน", actions={
                {kind="modifier", prop="LeadExperienceAddtion", value=999},
                {kind="modifier", prop="WorldMapFlySpeed", value=1000},
                {kind="modifier", prop="WorldMapFlySpeedAddP", value=1000},
                {kind="modifier", prop="ExperiencePrestigeAddP", value=1000},
                {kind="modifier", prop="ExperienceFindSpeedAddV", value=1000},
            }},
            { text="8. ความเร็วทำงานสูงสุด", actions={
                {kind="modifier", prop="GlobalEfficiency", value=100000},
                {kind="modifier", prop="BaseWorkSpeed", value=999},
            }},
            { text="9. ◀ กลับ", page="main" },
        }

    elseif page == "character" then
        return {
            { text="เพิ่มต้านธาตุทั้งห้า +999", actions={
                {kind="modifier", prop="NpcFight_ShieldResistanceToJin", value=999},
                {kind="modifier", prop="NpcFight_ShieldResistanceToMu", value=999},
                {kind="modifier", prop="NpcFight_ShieldResistanceToShui", value=999},
                {kind="modifier", prop="NpcFight_ShieldResistanceToHuo", value=999},
                {kind="modifier", prop="NpcFight_ShieldResistanceToTu", value=999},
            }},
            { text="เพิ่มการฟื้นฟูร่างกาย +999", actions={{kind="modifier", prop="RecoveryPower", value=999}} },
            { text="เพิ่มความเร็วในการเดิน +999", actions={{kind="modifier", prop="MoveSpeed", value=999}} },
            { text="เพิ่มค่าอารมณ์พื้นฐาน +999", actions={{kind="modifier", prop="BaseEmotionAddV", value=999}} },
            { text="เพิ่มอุณหภูมิต่ำสุดที่ทนได้ +999", actions={{kind="modifier", prop="ComfyTMin", value=999}} },
            { text="เพิ่มอุณหภูมิสูงสุดที่ทนได้ +999", actions={{kind="modifier", prop="ComfyTMax", value=999}} },
            { text="อุณหภูมิขีดจำกัดต่ำสุดขั้นสุด +999", actions={{kind="modifier", prop="ToleranceTMin", value=999}} },
            { text="อุณหภูมิขีดจำกัดสูงสุดขั้นสุด +999", actions={{kind="modifier", prop="ToleranceTMax", value=999}} },
            { text="เพิ่มทนต่อความเจ็บปวด +999", actions={{kind="modifier", prop="PainTolerance", value=999}} },
            { text="โอกาสการเกิดฝันร้าย+0.1", actions={{kind="modifier", prop="NightmareHappenPercent", value=0.1}} },
            { text="โอกาสการเกิดฝันดี+1", actions={{kind="modifier", prop="NiceDreamHappenPercent", value=1}} }, 
            { text="ปรับอัตราการใช้พลังงาน +999", actions={{kind="modifier", prop="FatigueConsumeConstant", value=999}} },
            { text="ปรับโบนัสการฟื้นฟูพลังงาน +999", actions={{kind="modifier", prop="FatigueRecoveryConstant", value=999}} },            
            { text="ปรับอัตราการบริโภคอาหาร +999", actions={{kind="modifier", prop="NutritionConsumeConstant", value=999}} },
            { text="ปรับโบนัสการฟื้นฟูจากอาหาร +999", actions={{kind="modifier", prop="NutritionRecoveryConstant", value=999}} },           
            { text="ปรับอัตราการบริโภคน้ำ +999", actions={{kind="modifier", prop="WaterConsumeConstant", value=999}} }, 
            { text="ปรับโบนัสการฟื้นฟูจากการดื่มน้ำ +999", actions={{kind="modifier", prop="WaterRecoveryConstant", value=999}} },
            { text="ปรับอัตราการใช้ความบันเทิง +999", actions={{kind="modifier", prop="HappyConsumeConstant", value=999}} },
            { text="ปรับโบนัสการฟื้นฟูความบันเทิง +999", actions={{kind="modifier", prop="NiceDreamHappenPercent", value=999}} }, 
            { text="ปรับอัตราการใช้พลังปราณแท้ +999", actions={{kind="modifier", prop="PracticeFoodConsumeConstant", value=999}} },
            { text="ปรับโบนัสการฟื้นฟูพลังปราณแท้ +999", actions={{kind="modifier", prop="PracticeFoodRecoveryConstant", value=999}} },            
            { text="ปรับโบนัสการฟื้นฟูบาดแผลภายใน +999", actions={{kind="modifier", prop="MagicDamageRecoveryPowerAddV", value=999}} },
            { text="ปรับโบนัสศักยภาพ +999", actions={{kind="modifier", prop="PotentialOfBasepracticeAddValue", value=999}} },           
            { text="ปรับโบนัสบทลงทัณฑ์สวรรค์ +999", actions={{kind="modifier", prop="GodPenaltyAddV", value=999}} }, 
            { text="ปรับความมั่นคงของสภาวะจิต +999", actions={{kind="modifier", prop="SpeedOfMindStateCoefficient", value=999}} }, 
            { text="ค่าพื้นฐานของสภาวะจิต +999", actions={{kind="modifier", prop="MindStateBaseValue", value=999}} },    
            { text="ปรับผลกระทบของอารมณ์ต่อสภาวะจิต +999", actions={{kind="modifier", prop="SpeedOfMindStateCoefficientByMoods", value=999}} },   
            { text="ปรับโบนัสความเร็วการดูดซับลมปราณ +999", actions={{kind="modifier", prop="LingAbsorbSpeed", value=999}} },
            { text="ปรับลมปราณพื้นฐาน +999", actions={{kind="modifier", prop="_SPECIAL_NOADD_NpcLingMaxValue", value=999}} },            
            { text="ปรับพลังวิญญาณสูงสุดของ NPC +999", actions={{kind="modifier", prop="NpcLingMaxValue", value=999}} },
            { text="ปรับโบนัสศักยภาพ +999", actions={{kind="modifier", prop="PotentialOfBasepracticeAddValue", value=999}} },           
            { text="ปรับโบนัสบทลงทัณฑ์สวรรค์ +999", actions={{kind="modifier", prop="GodPenaltyAddV", value=999}} }, 
            { text="ปรับความมั่นคงของสภาวะจิต +999", actions={{kind="modifier", prop="SpeedOfMindStateCoefficient", value=999}} }, 
            { text="เพิ่มอายุขัย +999", actions={{kind="modifier", prop="MaxAge", value=999}} },
            { text="ปรับตัวคูณโอกาสทะลวงคอขวด +999", actions={{kind="modifier", prop="PracticeRateAddPFromDan", value=999}} },
            { text="ปรับความเร็วการบินผจญภัย +999", actions={{kind="modifier", prop="WorldMapFlySpeed", value=999}} }, 
            { text="ปรับโบนัสความเร็วการบินระหว่างออกผจญภัย +999", actions={{kind="modifier", prop="WorldMapFlySpeedAddP", value=999}} },
            { text="ปรับตัวคูณเวลาคอขวดจากการผจญภัย +999", actions={{kind="modifier", prop="ExperienceNeckTimeCostCoefficient", value=999}} },            
            { text="ปรับระยะเวลาหน่วงก่อนคอขวดเริ่มนับถอยหลัง +999", actions={{kind="modifier", prop="NeckCountdownAddV", value=999}} },
            { text="ปรับจำนวนคัมภีร์ลับสูงสุด +999", actions={{kind="modifier", prop="EsotericaNum", value=999}} },           
            { text="ปรับค่าพลังบำเพ็ญแท้เพิ่มเติม +999", actions={{kind="modifier", prop="AbilityLvAddV", value=999}} }, 
            { text="ปรับตัวคูณชื่อเสียงการผจญภัย +999", actions={{kind="modifier", prop="ExperiencePrestigeAddP", value=999}} }, 
            { text="ปรับความเร็วการสำรวจผจญภัย +999", actions={{kind="modifier", prop="ExperienceFindSpeedAddV", value=999}} },
            { text="ปรับอัตราการได้รับพลังปราณแท้ +999", actions={{kind="modifier", prop="NutritionToJingYuanK", value=999}} }, 
            { text="ปรับประสิทธิภาพการดูดซับลมปราณ +999", actions={{kind="modifier", prop="NutritionWaterAutoRecover", value=999}} },
            { text="โบนัสอุปกรณ์ต่ออัตราแปลงโล่ +999", actions={{kind="modifier", prop="NpcFight_ShieldConversionEquipAdd", value=999}} },            
            { text="ปรับตัวคูณฟื้นฟูพลังวิญญาณของอาวุธวิเศษ +999", actions={{kind="modifier", prop="NpcFight_FabaoLingRecoverK", value=999}} },
            { text="ปรับโบนัสพลังอาวุธวิเศษ +999", actions={{kind="modifier", prop="NpcFight_FabaoPowerAddP", value=999}} },           
            { text="ปรับโบนัสฟื้นฟูพลังวิญญาณของอาวุธวิเศษ +999", actions={{kind="modifier", prop="NpcFight_FabaoLingRecoverAddP", value=999}} }, 
            { text="ปรับโบนัสความเร็วโจมตีของอาวุธวิเศษ +999", actions={{kind="modifier", prop="NpcFight_FabaoCoolDownAddP", value=999}} }, 
            { text="ความเร็วในการเรียนรู้ +999", actions={{kind="modifier", prop="IntelligenceSkillEXPConstant", value=999}} },
            { text="ปรับความจุค่ายกล +999", actions={{kind="modifier", prop="NpcFight_ZhenEnginePower", value=999}} },
            { text="ปรับตัวค่าความหยั่งรู้ +999", actions={{kind="modifier", prop="InspirationCoefficient", value=999}} }, 
            
            { text="ปรับโบนัสความเร็วการบำเพ็ญ +999", actions={{kind="modifier", prop="DeepPracticeSpeedSpecialCoefficient", value=999}} },
            { text="ปรับโบนัสความเร็วการสร้างรากฐาน +999", actions={{kind="modifier", prop="BasepracticeSpeedCoefficient", value=999}} },            
            { text="ปรับแต่งความเร็วงานพื้นฐาน +999", actions={{kind="modifier", prop="BaseWorkSpeed", value=999}} },
            { text="ปรับแต่งอัตราเพิ่มแต้มประสบการณ์ +999", actions={{kind="modifier", prop="LeadExperienceAddtion", value=999}} },           
            { text="ความเร็วงานรวม +999", actions={{kind="modifier", prop="GlobalEfficiency", value=999}} }, 
 

            
        }

        elseif page == "combat" then
        return {
            { text="เพิ่มเลือด สูงสุด +999", actions={{kind="modifier", prop="MaxHp", value=999}} },
            { text="เพิ่มโอกาสโจมตี +999", actions={{kind="modifier", prop="NpcFight_BaseHitChance", value=999}} },
            { text="เพิ่มโอกาสหลบ +999", actions={{kind="modifier", prop="NpcFight_BaseDodgeChance", value=999}} },
            { text="เพิ่มพลัง โจมตีอาวุธวิเศษ +999", actions={{kind="modifier", prop="NpcFight_FabaoPowerAddP", value=999}} },
            { text="เพิ่มเกราะโล่ +999", actions={{kind="modifier", prop="NpcFight_ShieldConversionRateAddP", value=999}} },
            { text="เพิ่ม อาวุธวิเศษ 5 ช่อง", actions={{kind="modifier", prop="NpcFight_FabaoNum", value=5}} },
            { text="เพิ่มพลังเวท +999", actions={{kind="modifier", prop="NpcFight_SpellPowerAddP", value=999}} },
            { text="เพิ่มระยะมองเห็น +999", actions={{kind="modifier", prop="VisionRadius", value=999}} },
            { text="เพิ่มค่าความเร็วในการบินของอาวุธพิเศษ +999", actions={{kind="modifier", prop="NpcFight_FabaoFlySpeedAddP", value=999}} }, 
            { text="เพิ่มค่าโบนัสความเร็วการเลี้ยวของอาวุธวิเศษ +999", actions={{kind="modifier", prop="NpcFight_FabaoTurnSpeedAddP", value=999}} },
            { text="เพิ่มค่าต้านทานการกระเด็นจากอาวุธวิเศษ +999", actions={{kind="modifier", prop="NpcFight_FabaoRepelResist", value=999}} },            
            { text="เพิ่มโบนัสความยาวหางอาวุธวิเศษ +999", actions={{kind="modifier", prop="NpcFight_FabaoTrailingLengthAddP", value=999}} },
            { text="เพิ่มโบนัสระยะเวลาคาถา +999", actions={{kind="modifier", prop="NpcFight_SpellCastTimeAddP", value=999}} },           
            { text="เพิ่มค่าอำพรางซ่อนเร้นตัว +999", actions={{kind="modifier", prop="NpcFight_SneakValue", value=999}} }, 
            { text="ปรับโบนัสพลังวิญญาณสูงสุดอาวุธวิเศษ +999", actions={{kind="modifier", prop="NpcFight_FabaoMaxLingAddP", value=999}} },
            { text="ปรับโบนัสระยะกระเด็นของอาวุธวิเศษ +999", actions={{kind="modifier", prop="NpcFight_FabaoRepelDistanceAddV", value=999}} }, 
            { text="ปรับโบนัสการใช้พลังวิญญาณของวิชา +999", actions={{kind="modifier", prop="NpcFight_SpellLingCostAddP", value=999}} },
            { text="ปรับพลังโจมตีของวิชา +999", actions={{kind="modifier", prop="NpcFight_SpellPowerAddP", value=999}} },            
            { text="ปรับโบนัสคูลดาวน์ของวิชา +999", actions={{kind="modifier", prop="NpcFight_SpellCoolDownAddP", value=999}} },
            { text="ปรับโบนัสความแข็งแกร่งโล่พลัง +999", actions={{kind="modifier", prop="NpcFight_ShieldConversionRate", value=999}} },           
            { text="ปรับตัวคูณความแข็งแกร่งของโล่พลัง +999", actions={{kind="modifier", prop="NpcFight_ShieldConversionRateAddP", value=999}} }, 
            { text="ปรับขนาดพื้นที่ค่ายกล +999", actions={{kind="modifier", prop="NpcFight_ZhenKeyPointNum", value=999}} }, 
            
            
            
            
            
        }
        
        
         
        
        
        
        
        elseif page == "cancel" then
        return {
            { text="ปรับโบนัสขีดจำกัดเตาหลอม +999", actions={{kind="modifier", prop="MaxAccumulativeLingAddV", value=999}} },
            { text="ปรับโบนัสความเร็วการหลอมอาวุธวิเศษ +999", actions={{kind="modifier", prop="FabaoMake_SpeedAddV", value=999}} }, 
            { text="ปรับโบนัสอัตราสำเร็จการหลอมอาวุธวิเศษ +999", actions={{kind="modifier", prop="FabaoMake_SuccessRateAddV", value=999}} },
            { text="ปรับโบนัสระดับขั้นอาวุธวิเศษ +999", actions={{kind="modifier", prop="FabaoMake_LingInheritRateAddV", value=999}} },            
            { text="ปรับโบนัสคุณภาพอาวุธวิเศษ +999", actions={{kind="modifier", prop="FabaoMake_QualityAddV", value=999}} },
            { text="ปรับอัตราสำเร็จพื้นฐานการสร้างศาสตราเทพ +999", actions={{kind="modifier", prop="FabaoMake_TwelveRateChance", value=999}} },           
            { text="ปรับความเร็วการหลอมโอสถ +999", actions={{kind="modifier", prop="DanMake_Speed", value=999}} }, 
            { text="ปรับโบนัสความเร็วการหลอมโอสถ +999", actions={{kind="modifier", prop="DanMake_SpeedAddV", value=999}} },
            { text="ปรับโบนัสอัตราสำเร็จจากทักษะปรุงโอสถ +999", actions={{kind="modifier", prop="DanMake_SuccessRate", value=999}} },
            { text="ปรับโบนัสอัตราความสำเร็จในการหลอมโอสถ +999", actions={{kind="modifier", prop="DanMake_SuccessRateAddV", value=999}} },
            { text="ปรับโบนัสปริมาณการผลิตโอสถจากทักษะปรุงโอสถ +999", actions={{kind="modifier", prop="DanMake_Yield", value=999}} }, 
            { text="ปรับโบนัสปริมาณการผลิตโอสถ +999", actions={{kind="modifier", prop="DanMake_YieldAddP", value=999}} },
            

        }
        
        
        elseif page == "more" then
        return {
            { text="1. เพิ่มค่าโบนัสจำนวนผู้ศรัทธาเป็นพลัง +999", actions={{kind="modifier", prop="GodPractice_LingConvert", value=999}} },
            { text="2. เพิ่มจำนวนผู้ศรัทธาษ +9999", actions={{kind="modifier", prop="GodCity_MaxResident", value=9999}} },            
            { text="3. ปรับขีดจำกัดจำนวนศิษย์ศรัทธาหลัก +999", actions={{kind="modifier", prop="GodCity_MaxCoreBeliever", value=999}} },
            { text="4. ปรับค่าทันสวรรค์สายเทพ +999", actions={{kind="modifier", prop="GodCity_ThunderAddion", value=999}} },           
            { text="5. โบนัสการได้รับศรัทธาของอาณาจักรเทพ +999", actions={{kind="modifier", prop="GodCity_PracticeEffect", value=999}} },
            { text="6. ปรับตัวคูณค่าสถานะผู้พิทักษ์เทพ +999", actions={{kind="modifier", prop="GodCity_GuardEffect", value=5}} },
            { text="7. ปรับโบนัสความเป็นเทพ +999", actions={{kind="modifier", prop="GodPractice_GodPowerAddV", value=999}} },
        }
    elseif page == "cancel" then
        return {
            { text="1. ปิดโหมดตายยาก", actions={
                {kind="modifier", prop="RecoveryPower", value=-999},
                {kind="modifier", prop="MagicDamageRecoveryPowerAddV", value=-9999},
                {kind="modifier", prop="LingAbsorbSpeed", value=-1000},
                {kind="modifier", prop="NutritionToJingYuanK", value=-1000},
                {kind="modifier", prop="NutritionWaterAutoRecover", value=-1000},
            }},
            { text="2. รีเซ็ตกิน/ดื่ม/เหนื่อย", actions={
                {kind="modifier", prop="FatigueConsumeConstant", value=10},
                {kind="modifier", prop="WaterConsumeConstant", value=10},
                {kind="modifier", prop="HappyConsumeConstant", value=10},
                {kind="modifier", prop="NutritionConsumeConstant", value=10},
                {kind="modifier", prop="PracticeFoodConsumeConstant", value=10},
            }},
            { text="3. รีเซ็ตพรสวรรค์สูงสุด", actions={
                {kind="modifier", prop="IntelligenceSkillEXPConstant", value=-999},
                {kind="modifier", prop="PotentialOfBasepracticeAddValue", value=-1000},
                {kind="modifier", prop="BasepracticeSpeedCoefficient", value=-1000},
                {kind="modifier", prop="DeepPracticeSpeedSpecialCoefficient", value=-1000},
                {kind="modifier", prop="MindStateBaseValue", value=-1000},
                {kind="modifier", prop="SpeedOfMindStateCoefficient", value=-1000},
                {kind="modifier", prop="SpeedOfMindStateCoefficientByMoods", value=1000},
                {kind="modifier", prop="InspirationCoefficient", value=-1000},
            }},
            { text="4. รีเซ็ตพลังต่อสู้", actions={
                {kind="modifier", prop="NpcFight_BaseHitChance", value=-1000},
                {kind="modifier", prop="NpcFight_BaseDodgeChance", value=-1000},
                {kind="modifier", prop="NpcFight_FabaoNum", value=-5},
                {kind="modifier", prop="NpcFight_FabaoPowerAddP", value=-1000},
                {kind="modifier", prop="NpcFight_SpellPowerAddP", value=-1000},
            }},
            { text="5. รีเซ็ตความเร็วงาน", actions={
                {kind="modifier", prop="GlobalEfficiency", value=-100000},
                {kind="modifier", prop="BaseWorkSpeed", value=-999},
            }},
            { text="6. ◀ กลับ", page="main" },
        }

    elseif page == "more" then
        return {
            
            { text="1. ทะลวงขั้นทันที", actions={{kind="breakthrough"}} },
            { text="2. ชุบชีวิต NPC", actions={{kind="addmodifier", id="Modifier_YinYangShuangYu76"}} },
            { text="3. สัตว์อสูร / ศัตรู", page="beast" },
            { text="4. ขโมยของ NPC", actions={{kind="addmodifier", id="Dan_BaiYanLang76"}} },
            { text="5. เพิ่มค่าสถานะทั้ง 5", actions={{kind="addmodifier", id="QuanBu76"}} },
            { text="6. ยืดเวลาของทัณฑ์สวรรค์", actions={{kind="addmodifier", id="Dan_ZhongLi76"}} },
            { text="7. เปลียนเวลาของเกม", page="Xaou_1" },
            
            { text="10. หน้าถัดไป ▶", page="more1" },
        }
        
    elseif page == "more1" then
        return {
            
            { text="9. ◀ กลับ", page="more" },
            { text="3. หน้าถัดไป ▶", page="more" },
            
            
        }

    elseif page == "world" then
        return {
            { text="1. เวลา / ฤดูกาล / อากาศ", actions={{kind="story", story="TQSJJJXG"}} },
            
            
            { text="4. เปิดหมอกแผนที่", actions={{kind="message", title="ระบบ", text="ฟังก์ชันเปิดหมอกให้ผูกกับ Toggle/OpenFog ในไฟล์หลักต่อ"}} },
            { text="5. เมนูปรับเวลาเดิม", actions={{kind="story", story="BuildMode_ChangeTime"}} },
            { text="6. เมนูอากาศเดิม", actions={{kind="story", story="BuildMode_ChangeWeather"}} },
            { text="7. ◀ กลับ", page="more" },
        }

    elseif page == "beast" then
        return {
            { text="1. เรียกอสูร : มังกรฟ้า", actions={{kind="addmodifier", id="Dan_ChiHuo76"}} },
            { text="2. เรียกอสูร : นกฟีนิกซ์เพลิง", actions={{kind="addmodifier", id="Dan_Huoji76"}} },
            { text="3. เรียกอสูร : มังกรไฟ", actions={{kind="addmodifier", id="Dan_YuMu76"}} },
            { text="4. สุ่มเรียกอสูร", actions={{kind="addmodifier", id="Dan_KaoRou76"}} },
            { text="5. เรียกโจรป่า", actions={{kind="addmodifier", id="Dan_MiMi76"}} },
            { text="6. โจรป่าระดับสูง", actions={{kind="addmodifier", id="Dan_SuperMiMi76"}} },
            
            { text="10. ◀ กลับ", page="more" },
        }

   

    elseif page == "system" then
        return {
            
            { text="3. เปิดเมนูเสกของ", actions={{kind="raw", code="Xaou_OpenIconItemSpawner();"}} },
            { text="4. GitHub ผู้พัฒนา", actions={{kind="url", url="https://github.com/xaouxaou009-debug/Mod"}} },
            { text="5. ข้อมูลม็อด", actions={{kind="message", title="XAOU", text="ผู้พัฒนา: xaouxaou009\nระบบ: XAOU Mod Center"}} },
            { text="6. ◀ กลับ", page="more" },
        }
    elseif page == "Xaou_1" then
        return {
            { text="1. ตอนเช้า", actions={{kind="changetime", hour=5}} },
            { text="2. ☀ เที่ยงวัน", actions={{kind="changetime", hour=11}} },
            { text="3. ตอนเย็น", actions={{kind="changetime", hour=17}} },
            { text="4. ตอนดึก", actions={{kind="changetime", hour=1}} },
            { text="5. สภาพอากาศแห่งการเก็บเกี่ยว", actions={{kind="changeweather", weather="HarvestAir"}} },
            { text="6. ◀ กลับ", page="more" },
        }

    elseif page == "jianghu" then
        return Xaou_BuildJianghuNpcCommands(1)

    elseif Xaou_IsJianghuPagedPage(page) then
        local pno = tonumber(string.match(tostring(page), "jianghu_p(%d+)")) or 1
        return Xaou_BuildJianghuNpcCommands(pno)

    elseif page == "jianghu_all" then
        return Xaou_BuildJianghuNpcRawList(9999)

    elseif string.sub(tostring(page), 1, 6) == "jhnpc_" then
        return Xaou_BuildJianghuNpcActionPage(page)

    elseif page == "debug" then
        local lines = Xaou_BuildNpcDebugLines(Xaou_CurrentNpcTarget)
        local list = {}
        for i, line in ipairs(lines) do
            table.insert(list, { text=tostring(i) .. ". " .. tostring(line), actions=nil })
        end
        table.insert(list, { text="◀ กลับ", page="main" })
        return list
    end

    return {}
end
