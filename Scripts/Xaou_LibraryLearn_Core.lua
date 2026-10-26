-- Learn every esoterica stored in CangJingGe through the game's real learning API.

local function xll_current(enumerator)
    local ok,value=pcall(function() return enumerator.Current end)
    if ok then return value end
    ok,value=pcall(function() return enumerator:get_Current() end)
    if ok then return value end
    return nil
end

local function xll_read_set(set)
    local out,seen={},{}
    if set==nil then return out end
    local ok,err=pcall(function()
        local e=set:GetEnumerator()
        while e:MoveNext() do
            local raw=xll_current(e)
            if raw~=nil then
                local id=tostring(raw)
                if id~="" and id~="nil" and not seen[id] then
                    seen[id]=true
                    out[#out+1]=id
                end
            end
        end
        pcall(function() e:Dispose() end)
    end)
    if not ok then return nil,tostring(err) end
    return out
end

local function xll_read_dictionary(dict)
    local out,seen={},{}
    if dict==nil then return out end
    local ok,err=pcall(function()
        local e=dict:GetEnumerator()
        while e:MoveNext() do
            local pair=xll_current(e)
            local list=nil
            pcall(function() list=pair.Value end)
            if list==nil then pcall(function() list=pair:get_Value() end) end
            if list~=nil then
                local count=tonumber(list.Count) or 0
                for i=0,count-1 do
                    local raw=nil
                    pcall(function() raw=list:get_Item(i) end)
                    if raw==nil then pcall(function() raw=list[i] end) end
                    if raw~=nil then
                        local id=tostring(raw)
                        if id~="" and id~="nil" and not seen[id] then
                            seen[id]=true
                            out[#out+1]=id
                        end
                    end
                end
            end
        end
        pcall(function() e:Dispose() end)
    end)
    if not ok then return nil,tostring(err) end
    return out
end

local function xll_library_ids()
    local mgr=nil
    pcall(function() mgr=CS.CangJingGeMgr.Instance end)
    if mgr==nil then return nil,"ไม่พบ CangJingGeMgr.Instance" end

    local set=nil
    pcall(function() set=mgr.allesolist end)
    if set~=nil then
        local ids,err=xll_read_set(set)
        if ids~=nil then return ids end
        return nil,err
    end

    pcall(function()
        local field=mgr:GetType():GetField("allesolist")
        if field~=nil then set=field:GetValue(mgr) end
    end)
    if set~=nil then
        local ids,err=xll_read_set(set)
        if ids~=nil then return ids end
        return nil,err
    end

    local dict=nil
    pcall(function() dict=mgr.esodic end)
    if dict~=nil then return xll_read_dictionary(dict) end
    return nil,"อ่านรายการคัมภีร์ในหอไม่ได้"
end

local function xll_practice(npc)
    if npc==nil then return nil end
    local real=npc
    if Xaou_GetRealNpcObject then
        local ok,value=pcall(function() return Xaou_GetRealNpcObject(npc) end)
        if ok and value~=nil then real=value end
    end
    local candidates={npc,real}
    for _,value in ipairs(candidates) do
        local practice=nil
        pcall(function() practice=value.Practice end)
        if practice~=nil then return practice end
        pcall(function() practice=value.PropertyMgr.Practice end)
        if practice~=nil then return practice end
    end
    return nil
end

local function xll_valid_esoterica(id)
    local mgr=nil
    pcall(function() mgr=CS.XiaWorld.EsotericaMgr.Instance end)
    if mgr==nil then return false end
    local data=nil
    local ok=pcall(function() data=mgr:GetSysEsoterica(id,false) end)
    if not ok or data==nil then pcall(function() data=mgr:GetSysEsoterica(id) end) end
    return data~=nil
end

local function xll_is_learned(practice,id)
    local ok,value=pcall(function() return practice:IsLearnedEsoterica(id) end)
    return ok and value==true
end

local function xll_can_teach(practice,id)
    local ok,value=pcall(function() return practice:CanBeTeach(id) end)
    if not ok or value~=true then return false end

    local checked,allowed=pcall(function() return practice:CheckCanLearnEsoteric(id,nil,false) end)
    if checked then return allowed==true end
    checked,allowed=pcall(function() return practice:CheckCanLearnEsoteric(id,false) end)
    if checked then return allowed==true end
    -- LearnEsotericaEx performs CanBeTeach internally; continue when only the optional guard overload is unavailable.
    return true
end

local function xll_learn(practice,id)
    local ok,err=pcall(function() practice:LearnEsotericaEx(id,0.0,false,false) end)
    if not ok then
        ok,err=pcall(function() practice:LearnEsotericaEx(id,0.0,0,false) end)
    end
    if not ok then return false,tostring(err) end
    if not xll_is_learned(practice,id) then return false,"เกมไม่ยืนยันสถานะเรียนแล้ว" end
    return true
end

function Xaou_GetLibraryEsotericaIds()
    return xll_library_ids()
end

function Xaou_LearnAllLibraryEsoterica(npc)
    local result={
        ok=false,found=0,success=0,learned=0,cannot=0,invalid=0,failed=0,errors={}
    }
    local practice=xll_practice(npc)
    if practice==nil then
        result.failed=1
        result.reason="ไม่พบระบบฝึกฝนของ NPC"
        return result
    end

    local ids,readError=xll_library_ids()
    if ids==nil then
        result.failed=1
        result.reason=tostring(readError or "อ่านหอคัมภีร์ไม่ได้")
        return result
    end
    result.found=#ids
    if #ids==0 then
        result.reason="ไม่มีคัมภีร์อยู่ในหอ"
        return result
    end

    for _,id in ipairs(ids) do
        local ok,err=pcall(function()
            if not xll_valid_esoterica(id) then result.invalid=result.invalid+1;return end
            if xll_is_learned(practice,id) then result.learned=result.learned+1;return end
            if not xll_can_teach(practice,id) then result.cannot=result.cannot+1;return end
            local learned,learnError=xll_learn(practice,id)
            if learned then
                result.success=result.success+1
            else
                error(learnError)
            end
        end)
        if not ok then
            result.failed=result.failed+1
            if #result.errors<10 then result.errors[#result.errors+1]=tostring(id)..": "..tostring(err) end
        end
    end

    pcall(function() practice:RefreshLearnCache() end)
    result.ok=result.failed==0 and (result.success>0 or result.learned>0)
    if result.ok then
        result.summary="พบ "..result.found.." | เรียนใหม่ "..result.success.." | เรียนแล้ว "..result.learned.." | ข้าม "..(result.cannot+result.invalid)
    elseif result.success>0 then
        result.reason="เรียนได้บางส่วน "..result.success.." รายการ และล้มเหลว "..result.failed.." รายการ"
    else
        result.reason="ไม่พบคัมภีร์ที่ NPC สามารถเรียนได้"
    end
    return result
end
