-- Xaou Boss Summon Window for FairyGUI
-- FGUI Package: XaoCtr
-- FGUI Component: BossSummon
--
-- Object names used:
--   card1_name, card1_Desc, card_btn1
--   card2_name, card2_Desc, card_btn2
--   card3_name, card3_Desc, card_btn13  -- ตามชื่อใน FGUI ตอนนี้
--   btnPrevPage, btnNextpage, btnClose
--
-- เปิดหน้าต่างด้วย:
--   Xaou_OpenBossSummonWindow()

local Xaou_Boss_View = nil
local Xaou_Boss_Page = 1
local Xaou_Boss_Unpack = table.unpack or unpack

local Xaou_Boss_List = {
    {
        name = "มังกรคราม",
        bossId = "Boss_Long",
        desc = "บอสสายมังกร / ทดสอบระบบเรียกบอส\nใช้สำหรับลองปุ่มและการต่อสู้",
    },
    {
        name = "หงส์เพลิง",
        bossId = "Boss_Feng",
        desc = "บอสสายไฟ / เหมาะสำหรับทดสอบเอฟเฟกต์ต่อสู้\nเรียกผ่าน GameUlt.CallBoss",
    },
    {
        name = "จูหลง",
        bossId = "Boss_Zhulong",
        desc = "บอสระดับสูงสำหรับทดสอบ\nถ้า ID นี้ไม่ตรง เกมอาจไม่เรียกออกมา",
    },

    -- หน้า 2
    {
        name = "ภัยพิบัติ Fei",
        kind = "godAnimal",
        bossId = "Fei",
        desc = "เรียกสัตว์เทพ Fei ผ่าน Map:AddGodAnimal\nใช้คนละระบบกับ CallBoss",
    },
    {
        name = "ศัตรูชั้นยอด",
        kind = "elite",
        bossId = "EliteEnemy",
        desc = "สร้างศัตรูชั้นยอดที่ขอบแผนที่\nเหมาะสำหรับทดสอบศึกทั่วไป",
    },
    {
        name = "ทดสอบข้อความ",
        kind = "test",
        bossId = "TEST",
        desc = "ปุ่มทดสอบเท่านั้น\nกดแล้วแสดงข้อความ ไม่เรียกบอสจริง",
    },

    -- หน้า 3 เผื่อใส่เพิ่มในอนาคต
    {
        name = "ช่องว่าง 1",
        kind = "test",
        bossId = "EMPTY_1",
        desc = "เตรียมไว้สำหรับเพิ่มบอสตัวใหม่",
    },
    {
        name = "ช่องว่าง 2",
        kind = "test",
        bossId = "EMPTY_2",
        desc = "เตรียมไว้สำหรับเพิ่มบอสตัวใหม่",
    },
    {
        name = "ช่องว่าง 3",
        kind = "test",
        bossId = "EMPTY_3",
        desc = "เตรียมไว้สำหรับเพิ่มบอสตัวใหม่",
    },
}
local function Xaou_Boss_ShowMsg(msg)
    if Xaou_LocalizeText then msg = Xaou_LocalizeText(msg) end
    pcall(function()
        if world ~= nil then world:ShowMsgBox(tostring(msg)) end
    end)
    pcall(function()
        if CS ~= nil and CS.XiaWorld ~= nil and CS.XiaWorld.UI ~= nil then
            CS.XiaWorld.UI.InGameUI.Instance:ShowMsg(tostring(msg))
        end
    end)
end

local function Xaou_Boss_UIPackage()
    if UIPackage ~= nil then return UIPackage end
    if CS ~= nil and CS.FairyGUI ~= nil then return CS.FairyGUI.UIPackage end
    return nil
end

local function Xaou_Boss_GRoot()
    if GRoot ~= nil then return GRoot.inst end
    if CS ~= nil and CS.FairyGUI ~= nil and CS.FairyGUI.GRoot ~= nil then
        return CS.FairyGUI.GRoot.inst
    end
    return nil
end

local function Xaou_Boss_SetText(obj, text)
    if obj == nil then return end
    if Xaou_LocalizeText then text = Xaou_LocalizeText(text) end
    pcall(function() obj.text = tostring(text or "") end)
    pcall(function() obj.title = tostring(text or "") end)
end

local function Xaou_Boss_SetVisible(obj, flag)
    if obj == nil then return end
    pcall(function() obj.visible = flag end)
end

local function Xaou_Boss_GetIcon(data)
    if data == nil then return "" end
    if data.icon ~= nil and tostring(data.icon) ~= "" then
        return tostring(data.icon)
    end

    local icon = ""
    pcall(function()
        local mgr = NpcMgr
        if mgr == nil and CS ~= nil and CS.XiaWorld ~= nil then
            mgr = CS.XiaWorld.NpcMgr.Instance
        end
        if mgr ~= nil then
            local def = mgr:GetRaceDef(tostring(data.bossId or ""))
            if def ~= nil and def.TexPath ~= nil then icon = tostring(def.TexPath) end
        end
    end)
    return icon
end

local function Xaou_Boss_SetIcon(loader, data)
    if loader == nil then return end
    local icon = Xaou_Boss_GetIcon(data)
    pcall(function() loader.url = icon end)
    pcall(function() loader.icon = icon end)
    Xaou_Boss_SetVisible(loader, icon ~= "")
end

local function Xaou_Boss_SetTouchable(obj, flag)
    if obj == nil then return end
    pcall(function() obj.touchable = flag end)
    pcall(function() obj.enabled = flag end)
    pcall(function() obj.grayed = not flag end)
end

local function Xaou_Boss_GetChild(view, ...)
    if view == nil then return nil end
    local names = {...}
    for _, name in ipairs(names) do
        local ok, child = pcall(function() return view:GetChild(name) end)
        if ok and child ~= nil then return child end
    end
    return nil
end

function Xaou_CloseBossSummonWindow()
    if Xaou_Boss_View ~= nil then
        pcall(function() Xaou_Boss_View:RemoveFromParent() end)
        pcall(function() Xaou_Boss_View:Dispose() end)
        Xaou_Boss_View = nil
    end
end

local function Xaou_Boss_CallBoss(data)
    if data == nil then return end

    local kind = data.kind or "boss"
    local ok = false

    if kind == "test" then
        Xaou_Boss_ShowMsg("ทดสอบปุ่ม: " .. tostring(data.name))
        return
    end

    if kind == "godAnimal" then
        if Map ~= nil and Map.AddGodAnimal ~= nil then
            ok = pcall(function()
                Map:AddGodAnimal(data.bossId, 0)
            end)
        end

        if ok then
            Xaou_Boss_ShowMsg("เรียกสัตว์เทพ: " .. tostring(data.name))
        else
            Xaou_Boss_ShowMsg("เรียกสัตว์เทพไม่สำเร็จ: " .. tostring(data.name))
        end
        return
    end

    if kind == "elite" then
        if NpcMgr ~= nil and NpcMgr.CreateEliteEnemysAtSide ~= nil then
            ok = pcall(function()
                NpcMgr:CreateEliteEnemysAtSide("", CS.XiaWorld.g_emThingDir.None, Map, 0)
            end)
        end

        if ok then
            Xaou_Boss_ShowMsg("สร้างศัตรูชั้นยอดแล้ว")
        else
            Xaou_Boss_ShowMsg("สร้างศัตรูชั้นยอดไม่สำเร็จ")
        end
        return
    end

    if GameUlt == nil or GameUlt.CallBoss == nil then
        Xaou_Boss_ShowMsg("ไม่พบ GameUlt.CallBoss")
        return
    end

    ok = pcall(function()
        return GameUlt.CallBoss(data.bossId, nil, nil, false)
    end)

    if ok then
        Xaou_Boss_ShowMsg("เรียกบอส: " .. tostring(data.name))
    else
        Xaou_Boss_ShowMsg("เรียกบอสไม่สำเร็จ: " .. tostring(data.name))
    end
end

local function Xaou_Boss_Refresh(view)
    if view == nil then return end

    Xaou_Boss_SetText(Xaou_Boss_GetChild(view, "title", "txtTitle"), "เรียกบอส")

    local pageSize = 3
    local total = #Xaou_Boss_List
    local maxPage = math.max(1, math.ceil(total / pageSize))

    if Xaou_Boss_Page < 1 then Xaou_Boss_Page = 1 end
    if Xaou_Boss_Page > maxPage then Xaou_Boss_Page = maxPage end

    local slots = {
        {
            card = Xaou_Boss_GetChild(view, "card1"),
            icon = Xaou_Boss_GetChild(view, "card1_icon"),
            name = Xaou_Boss_GetChild(view, "card1_name"),
            desc = Xaou_Boss_GetChild(view, "card1_Desc", "card1_desc"),
            btn  = Xaou_Boss_GetChild(view, "card_btn1", "card1_btn"),
        },
        {
            card = Xaou_Boss_GetChild(view, "card2"),
            icon = Xaou_Boss_GetChild(view, "card2_icon"),
            name = Xaou_Boss_GetChild(view, "card2_name"),
            desc = Xaou_Boss_GetChild(view, "card2_Desc", "card2_desc"),
            btn  = Xaou_Boss_GetChild(view, "card_btn2", "card2_btn"),
        },
        {
            card = Xaou_Boss_GetChild(view, "card3"),
            icon = Xaou_Boss_GetChild(view, "card3_icon"),
            name = Xaou_Boss_GetChild(view, "card3_name"),
            desc = Xaou_Boss_GetChild(view, "card3_Desc", "card3_desc"),
            -- ตอนนี้ใน FGUI เห็นชื่อเป็น card_btn13 เลยใส่ไว้ก่อน
            btn  = Xaou_Boss_GetChild(view, "card_btn13", "card_btn3", "card3_btn"),
        },
    }

    for i = 1, pageSize do
        local index = (Xaou_Boss_Page - 1) * pageSize + i
        local data = Xaou_Boss_List[index]
        local slot = slots[i]

        if data ~= nil then
            Xaou_Boss_SetVisible(slot.card, true)
            Xaou_Boss_SetIcon(slot.icon, data)
            Xaou_Boss_SetText(slot.name, data.name)
            Xaou_Boss_SetText(slot.desc, data.desc)
            Xaou_Boss_SetText(slot.btn, "เรียกบอส")
            Xaou_Boss_SetTouchable(slot.btn, true)

            if slot.btn ~= nil then
                slot.btn.data = data
            end
        else
            Xaou_Boss_SetVisible(slot.card, false)
            Xaou_Boss_SetIcon(slot.icon, nil)
            Xaou_Boss_SetText(slot.name, "")
            Xaou_Boss_SetText(slot.desc, "")
            Xaou_Boss_SetText(slot.btn, "")
            Xaou_Boss_SetTouchable(slot.btn, false)
            if slot.btn ~= nil then
                slot.btn.data = nil
            end
        end
    end

    local txtPage = Xaou_Boss_GetChild(view, "txtPage", "pageText")
    Xaou_Boss_SetText(txtPage, tostring(Xaou_Boss_Page) .. "/" .. tostring(maxPage))
end

local function Xaou_Boss_BindCardButton(view, btnNameList)
    local btn = Xaou_Boss_GetChild(view, Xaou_Boss_Unpack(btnNameList))
    if btn == nil then return end

    Xaou_Boss_SetTouchable(btn, true)
    btn.onClick:Add(function()
        Xaou_Boss_CallBoss(btn.data)
    end)
end

function Xaou_OpenBossSummonWindow()
    Xaou_CloseBossSummonWindow()

    local pkg = Xaou_Boss_UIPackage()
    local root = Xaou_Boss_GRoot()

    if pkg == nil or root == nil then
        Xaou_Boss_ShowMsg("ไม่พบ FairyGUI / GRoot")
        return
    end

    pcall(function() pkg.AddPackage("UI/XaoCtr") end)

    local view = nil
    pcall(function()
        view = pkg.CreateObject("XaoCtr", "BossSummon")
    end)

    if view == nil then
        Xaou_Boss_ShowMsg("เปิด XaouUI/BossSummon ไม่ได้")
        return
    end

    Xaou_Boss_View = view
    root:AddChild(view)

    pcall(function()
        view.x = (root.width - view.width) / 2
        view.y = (root.height - view.height) / 2
    end)

    Xaou_Boss_BindCardButton(view, {"card_btn1", "card1_btn"})
    Xaou_Boss_BindCardButton(view, {"card_btn2", "card2_btn"})
    Xaou_Boss_BindCardButton(view, {"card_btn13", "card_btn3", "card3_btn"})

    local btnPrev = Xaou_Boss_GetChild(view, "btnPrevPage", "btnPrev")
    local btnNext = Xaou_Boss_GetChild(view, "btnNextpage", "btnNextPage", "btnNext")
    local btnClose = Xaou_Boss_GetChild(view, "btnClose", "Close")

    Xaou_Boss_SetText(btnPrev, "◀")
    Xaou_Boss_SetText(btnNext, "▶")
    Xaou_Boss_SetText(btnClose, "×")

    if btnPrev ~= nil then
        Xaou_Boss_SetTouchable(btnPrev, true)
        btnPrev.onClick:Add(function()
            Xaou_Boss_Page = Xaou_Boss_Page - 1
            Xaou_Boss_Refresh(view)
        end)
    end

    if btnNext ~= nil then
        Xaou_Boss_SetTouchable(btnNext, true)
        btnNext.onClick:Add(function()
            Xaou_Boss_Page = Xaou_Boss_Page + 1
            Xaou_Boss_Refresh(view)
        end)
    end

    if btnClose ~= nil then
        Xaou_Boss_SetTouchable(btnClose, true)
        btnClose.onClick:Add(function()
            Xaou_CloseBossSummonWindow()
        end)
    end

    Xaou_Boss_Refresh(view)
end

-- Alias เผื่อเรียกจากปุ่มทดสอบชื่ออื่น
function Xaou_OpenBossWindow()
    Xaou_OpenBossSummonWindow()
end

function OpenBossSummonWindow()
    Xaou_OpenBossSummonWindow()
end
