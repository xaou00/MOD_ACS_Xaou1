-- Book command data migrated from the original Xaou book menu.

Xaou_NewBookCategories={
    {id="all",text="ทั้งหมด"},
    {id="unlock",text="ปลดล็อกวิชา"},
    {id="manual",text="หนังสือคัมภีร์"},
    {id="warp",text="วาร์ป"},
}

Xaou_NewBookCommands={
    {text="วาร์ป",category="warp",action="warp"},
    {text="วิชาสายหลักทั้งหมด",category="unlock",story="Xaou_Unlock_AllGong"},
    {text="วิชาระดับสวรรค์ สุ่ม 20 ครั้ง",category="unlock",story="Xaou_Unlock_RandomHeavenGong20"},
}

local storyNumbers={500,501,502,503,504,505,506,507,508}
for number=510,524 do storyNumbers[#storyNumbers+1]=number end
for index,number in ipairs(storyNumbers) do
    Xaou_NewBookCommands[#Xaou_NewBookCommands+1]={
        text="รับคัมภีร์ 20 เล่ม ชุดที่ "..tostring(index),
        category="manual",
        story="xaou_xaou"..tostring(number),
    }
end

function Xaou_GetNewBookCommands(category)
    category=tostring(category or "all")
    local result={}
    for _,command in ipairs(Xaou_NewBookCommands) do
        if category=="all" or command.category==category then result[#result+1]=command end
    end
    return result
end

local function xbm_real_npc(npc)
    if Xaou_GetRealNpcObject then
        local ok,value=pcall(function() return Xaou_GetRealNpcObject(npc) end)
        if ok and value~=nil then return value end
    end
    return npc
end

function Xaou_RunNewBookCommand(npc,command)
    if command==nil then return false,"ไม่พบคำสั่ง" end
    local actor=xbm_real_npc(npc)
    if actor==nil then return false,"ไม่พบ NPC เป้าหมาย" end

    if command.action=="warp" then
        if Xaou_WarpSystem and Xaou_WarpSystem.ShowMap then
            local ok,err=pcall(function() return Xaou_WarpSystem.ShowMap() end)
            return ok,ok and "เปิดแผนที่วาร์ปแล้ว" or tostring(err)
        end
        local ok,err=pcall(function() actor:TriggerStory("วาร์ป1") end)
        return ok,ok and "เปิดเมนูวาร์ปแล้ว" or tostring(err)
    end

    local story=tostring(command.story or "")
    if story=="" then return false,"คำสั่งไม่มี Story" end
    local ok,err=pcall(function()
        if actor.TriggerStory~=nil then actor:TriggerStory(story);return end
        if CS and CS.XiaWorld and CS.XiaWorld.NpcLuaHelper then
            local helper=CS.XiaWorld.NpcLuaHelper(actor)
            if helper and helper.TriggerStory then helper:TriggerStory(story);return end
        end
        error("TriggerStory not found")
    end)
    return ok,ok and "เปิดคำสั่งแล้ว" or tostring(err)
end
