-- ============================================================
-- Xaou Learn Full Gong Addon
-- Real mobile path for teaching a selected NPC a full gong.
-- Confirmed path:
--   RefreshLearnCache -> RandomTree -> AddEsotericaList(all)
--   -> LearnTreeNode(all valid nodes) -> RefreshLearnCache -> Refresh UI
-- This intentionally does not call CangJingGeMgr.AddGong().
-- ============================================================

Xaou_LearnFullGong_Addon_Loaded = true

local function xlf_str(value)
    if value == nil then return "nil" end
    return tostring(value)
end

local function xlf_helper()
    local ok, helper = pcall(function() return CS.WorldLuaHelper() end)
    if ok then return helper end
    return nil
end

local XLF_DEBUG_LOG_FILE = "Xaou_Invoke_DebugLog.txt"
local XLF_LastDebugLogPath = nil
local XLF_LastDebugWriteTrace = nil
local XLF_LearnWindow = nil
local XLF_RestoreMainWindow = false

local function xlf_debug_enabled()
    return Xaou_LearnFullGong_Debug == true or Xaou_Debug == true
end

local function xlf_hide_main_window()
    if XaouItemWindow == nil then return end
    XLF_RestoreMainWindow = true
    pcall(function() XaouItemWindow:Hide() end)
end

local function xlf_restore_main_window()
    if XLF_RestoreMainWindow ~= true then return end
    XLF_RestoreMainWindow = false
    if XaouItemWindow == nil then return end
    pcall(function() XaouItemWindow:Show() end)
    pcall(function() XaouItemWindow:ForceMainPosition() end)
    pcall(function()
        if XaouItemWindow.window ~= nil and XaouItemWindow.window.BringToFront ~= nil then
            XaouItemWindow.window:BringToFront()
        end
    end)
    pcall(function() XaouItemWindow:RefreshList() end)
end

local function xlf_now_string()
    local ok, value = pcall(function()
        return tostring(CS.System.DateTime.Now:ToString("yyyy-MM-dd HH:mm:ss.fff"))
    end)
    if ok and value ~= nil then return tostring(value) end

    ok, value = pcall(function()
        if CS ~= nil and CS.UnityEngine ~= nil and CS.UnityEngine.Time ~= nil then
            return "UnityTime:" .. tostring(CS.UnityEngine.Time.realtimeSinceStartup)
        end
        return nil
    end)
    if ok and value ~= nil then return tostring(value) end
    return "unknown-time"
end

local function xlf_debug_base_paths()
    local paths = {}
    local function add(path)
        path = tostring(path or "")
        if path ~= "" then paths[#paths + 1] = path end
    end

    local mod_names = {
        "Xaou009_ACS_Mod_Main",
        "Xaou009_ACS_Mod",
        "3750375861",
    }
    for _, mod_name in ipairs(mod_names) do
        pcall(function()
            local mod = GameMain ~= nil and GameMain:GetMod(mod_name) or nil
            if mod ~= nil then
                local fields = {
                    "ModPath", "Path", "RootPath", "BasePath", "Dir", "Directory",
                    "Folder", "ModDir", "FilePath", "FullPath"
                }
                for _, field in ipairs(fields) do
                    local ok, value = pcall(function() return mod[field] end)
                    if ok and value ~= nil then add(value) end
                end
            end
        end)
    end

    pcall(function()
        if CS ~= nil and CS.UnityEngine ~= nil and CS.UnityEngine.Application ~= nil then
            add(CS.UnityEngine.Application.persistentDataPath)
            add(CS.UnityEngine.Application.temporaryCachePath)
            add(CS.UnityEngine.Application.dataPath)
        end
    end)

    add("/storage/emulated/0/Download")
    add("/storage/emulated/0/Documents")
    add("/sdcard/Download")
    add("/sdcard/Documents")
    add(".")
    return paths
end

local function xlf_join_path(base, file)
    base = tostring(base or "")
    file = tostring(file or XLF_DEBUG_LOG_FILE)
    if base == "" or base == "." then return file end
    local last = string.sub(base, -1)
    if last == "/" or last == "\\" then return base .. file end
    return base .. "/" .. file
end

local function xlf_try_append_file(path, payload)
    local attempts = {}

    local ok_sw, err_sw = pcall(function()
        if CS == nil or CS.System == nil or CS.System.IO == nil or CS.System.IO.StreamWriter == nil then
            error("CS.System.IO.StreamWriter not found")
        end
        local writer = CS.System.IO.StreamWriter(path, true)
        writer:Write(payload)
        writer:Close()
        pcall(function() writer:Dispose() end)
    end)
    attempts[#attempts + 1] = "StreamWriter(path,true)=" .. (ok_sw and "SUCCESS" or ("FAILED | " .. tostring(err_sw)))
    if ok_sw then return true, "StreamWriter", table.concat(attempts, "\n") end

    local ok_rw, err_rw = pcall(function()
        if CS == nil or CS.System == nil or CS.System.IO == nil or CS.System.IO.File == nil then
            error("CS.System.IO.File not found")
        end
        local old = ""
        local exists_ok, exists = pcall(function() return CS.System.IO.File.Exists(path) end)
        if exists_ok and exists == true then
            local read_ok, read_value = pcall(function() return CS.System.IO.File.ReadAllText(path) end)
            if read_ok and read_value ~= nil then old = tostring(read_value)
            else error("ReadAllText failed before append: " .. tostring(read_value)) end
        end
        CS.System.IO.File.WriteAllText(path, old .. payload)
    end)
    attempts[#attempts + 1] = "File.Exists/ReadAllText/WriteAllText=" .. (ok_rw and "SUCCESS" or ("FAILED | " .. tostring(err_rw)))
    if ok_rw then return true, "ReadWriteAllText", table.concat(attempts, "\n") end

    local ok_write, err_write = pcall(function()
        if CS == nil or CS.System == nil or CS.System.IO == nil or CS.System.IO.File == nil then
            error("CS.System.IO.File not found")
        end
        local exists = false
        pcall(function() exists = CS.System.IO.File.Exists(path) end)
        if exists == true then
            error("WriteAllText create-only fallback skipped because file already exists")
        end
        CS.System.IO.File.WriteAllText(path, payload)
    end)
    attempts[#attempts + 1] = "File.WriteAllText(create only)=" .. (ok_write and "SUCCESS" or ("FAILED | " .. tostring(err_write)))
    if ok_write then return true, "WriteAllTextCreate", table.concat(attempts, "\n") end

    return false, table.concat(attempts, "\n"), table.concat(attempts, "\n")
end

local function xlf_append_debug_log(title, text)
    title = tostring(title or "Xaou Learn")
    text = tostring(text or "")

    local payload_lines = {}
    payload_lines[#payload_lines + 1] = ""
    payload_lines[#payload_lines + 1] = "============================================================"
    payload_lines[#payload_lines + 1] = "Time: " .. xlf_now_string()
    payload_lines[#payload_lines + 1] = "Title: " .. title
    payload_lines[#payload_lines + 1] = "Class Name: Xaou_LearnFullGong"
    payload_lines[#payload_lines + 1] = "Method Name: LearnFullGong"
    payload_lines[#payload_lines + 1] = "------------------------------------------------------------"
    payload_lines[#payload_lines + 1] = text
    payload_lines[#payload_lines + 1] = "============================================================"
    payload_lines[#payload_lines + 1] = ""
    local payload = table.concat(payload_lines, "\n")

    local paths = {}
    local seen = {}
    for _, base in ipairs(xlf_debug_base_paths()) do
        local path = xlf_join_path(base, XLF_DEBUG_LOG_FILE)
        if seen[path] ~= true then
            paths[#paths + 1] = path
            seen[path] = true
        end
    end

    local trace = {}
    trace[#trace + 1] = "DebugLogFile=" .. XLF_DEBUG_LOG_FILE
    local success_count = 0
    local first_success = nil
    local last_err = nil
    for _, path in ipairs(paths) do
        pcall(function()
            if CS ~= nil and CS.System ~= nil and CS.System.IO ~= nil and CS.System.IO.Directory ~= nil then
                local dir = string.match(tostring(path), "^(.*)/[^/]*$") or string.match(tostring(path), "^(.*)\\[^\\]*$")
                if dir ~= nil and dir ~= "" and dir ~= "." then
                    CS.System.IO.Directory.CreateDirectory(dir)
                end
            end
        end)

        local ok, method_or_err, write_trace = xlf_try_append_file(path, payload)
        if ok then
            success_count = success_count + 1
            if first_success == nil then first_success = path end
            XLF_LastDebugLogPath = path
            trace[#trace + 1] = "SUCCESS: " .. tostring(path)
            trace[#trace + 1] = "  WriteMethod: " .. tostring(method_or_err)
        else
            trace[#trace + 1] = "FAILED: " .. tostring(path)
            trace[#trace + 1] = "  Reason: " .. tostring(method_or_err)
            last_err = method_or_err
        end
        if write_trace ~= nil then
            trace[#trace + 1] = "  WriteTrace: " .. tostring(write_trace)
        end
    end

    trace[#trace + 1] = "SuccessCount=" .. tostring(success_count)
    if first_success ~= nil then
        trace[#trace + 1] = "DebugLogPath=" .. tostring(first_success)
        trace[#trace + 1] = "WriteResult=SUCCESS"
        XLF_LastDebugWriteTrace = table.concat(trace, "\n")
        return true, first_success, XLF_LastDebugWriteTrace
    end

    trace[#trace + 1] = "DebugLogPath=nil"
    trace[#trace + 1] = "WriteResult=FAILED"
    trace[#trace + 1] = "LastError=" .. tostring(last_err)
    XLF_LastDebugWriteTrace = table.concat(trace, "\n")
    return false, nil, XLF_LastDebugWriteTrace
end

local function xlf_show(text, title)
    title = title or "Xaou Learn"
    text = tostring(text)

    if xlf_debug_enabled() then
        local log_ok, log_path, log_trace = xlf_append_debug_log(title, text)
        text = text
            .. "\n\nDebugLogPath=" .. tostring(log_path)
            .. "\nWriteResult=" .. (log_ok and "SUCCESS" or "FAILED")
        if log_trace ~= nil and tostring(log_trace) ~= "" then
            text = text .. "\n\n" .. tostring(log_trace)
        end
    end

    if Xaou_Show ~= nil then
        local ok = pcall(function() Xaou_Show(tostring(text), title) end)
        if ok then return true end
    end

    local helper = xlf_helper()
    if helper ~= nil then
        local ok = pcall(function() helper:ShowMsgBox(tostring(text), title) end)
        if ok then return true end
    end

    pcall(function()
        CS.Wnd_Message.Show(tostring(text), 1, nil, true, title, 0, 0, "")
    end)
    pcall(function() print("[XaouLearnFullGong] " .. tostring(text)) end)
    return false
end

local function xlf_count(list)
    if list == nil then return 0 end
    local ok, value = pcall(function() return list.Count end)
    if ok and value ~= nil then return tonumber(value) or 0 end
    ok, value = pcall(function() return list:get_Count() end)
    if ok and value ~= nil then return tonumber(value) or 0 end
    ok, value = pcall(function() return list.Length end)
    if ok and value ~= nil then return tonumber(value) or 0 end
    ok, value = pcall(function() return list:get_Length() end)
    if ok and value ~= nil then return tonumber(value) or 0 end
    return 0
end

local function xlf_item(list, index)
    if list == nil then return nil end
    local ok, value = pcall(function() return list[index] end)
    if ok and value ~= nil then return value end
    ok, value = pcall(function() return list:get_Item(index) end)
    if ok and value ~= nil then return value end
    ok, value = pcall(function() return list.Item[index] end)
    if ok and value ~= nil then return value end
    ok, value = pcall(function() return list:GetValue(index) end)
    if ok and value ~= nil then return value end
    return nil
end

local function xlf_num(value)
    if value == nil then return nil end
    local n = tonumber(value)
    if n ~= nil then return n end
    local ok, text = pcall(function() return tostring(value) end)
    if ok then return tonumber(text) end
    return nil
end

local function xlf_select_index(result)
    local n = xlf_num(result)
    if n ~= nil then return n end
    local count = xlf_count(result)
    if count > 0 then return xlf_num(xlf_item(result, 0)) end
    return nil
end

local function xlf_list_summary(list, limit)
    if list == nil then return "nil" end
    limit = limit or 8
    local count = xlf_count(list)
    local out = { "Count=" .. tostring(count) }
    local max = count
    if max > limit then max = limit end
    for i = 0, max - 1 do
        out[#out + 1] = tostring(i + 1) .. "=" .. xlf_str(xlf_item(list, i))
    end
    if count > max then out[#out + 1] = "... +" .. tostring(count - max) end
    return table.concat(out, " | ")
end

local function xlf_list_contains(list, text)
    if list == nil or text == nil then return false end
    local count = xlf_count(list)
    local needle = tostring(text)
    for i = 0, count - 1 do
        local item = xlf_item(list, i)
        if item ~= nil and tostring(item) == needle then return true end
    end
    return false
end

local function xlf_new_string_list()
    local ok, list = pcall(function()
        local list_type = CS.System.Collections.Generic.List(CS.System.String)
        return list_type()
    end)
    if ok and list ~= nil then return list end

    ok, list = pcall(function()
        local list_type = CS.System.Collections.Generic.List(typeof(CS.System.String))
        return list_type()
    end)
    if ok and list ~= nil then return list end
    return nil
end

local function xlf_get_npc_practice(npc)
    if npc == nil then return nil, "npc nil" end
    local attempts = {
        { "npc.PropertyMgr.Practice", function() return npc.PropertyMgr.Practice end },
        { "npc.PropertyMgr:get_Practice()", function() return npc.PropertyMgr:get_Practice() end },
        { "npc.Practice", function() return npc.Practice end },
        { "npc.practice", function() return npc.practice end },
    }
    local last = nil
    for _, attempt in ipairs(attempts) do
        local ok, value = pcall(attempt[2])
        if ok and value ~= nil then return value, attempt[1] end
        if not ok then last = attempt[1] .. " => " .. xlf_str(value) end
    end
    return nil, last or "practice not found"
end

local function xlf_npc_name(npc)
    if npc == nil then return "nil" end
    local attempts = {
        function() return npc:GetName() end,
        function() return npc:GetName(true) end,
        function() return npc.DisplayName end,
        function() return npc.Name end,
        function() return npc.Key end,
    }
    for _, fn in ipairs(attempts) do
        local ok, value = pcall(fn)
        if ok and value ~= nil then return tostring(value) end
    end
    return xlf_str(npc)
end

local function xlf_npc_can_work(npc)
    if npc == nil then return false end
    local ok, is_disciple = pcall(function() return npc.IsDisciple end)
    if ok and is_disciple == false then return false end
    local can_work = nil
    ok, can_work = pcall(function() return npc.CanDoDiscipleWork end)
    if ok and can_work == false then return false end
    return true
end

local function xlf_decode_npc(result)
    if result == nil then return nil, nil end
    local npc_id = xlf_num(result)
    if npc_id ~= nil then
        local ok, npc = pcall(function()
            return CS.XiaWorld.ThingMgr.Instance:FindThingByID(npc_id)
        end)
        if ok then return npc, npc_id end
    end

    local count = xlf_count(result)
    if count > 0 then
        npc_id = xlf_num(xlf_item(result, 0))
        if npc_id ~= nil then
            local ok, npc = pcall(function()
                return CS.XiaWorld.ThingMgr.Instance:FindThingByID(npc_id)
            end)
            if ok then return npc, npc_id end
        end
    end

    if type(result) ~= "number" and type(result) ~= "string" and type(result) ~= "boolean" then
        return result, nil
    end
    return nil, npc_id
end

local function xlf_read_field(obj, field)
    if obj == nil then return nil end
    local ok, value = pcall(function() return obj[field] end)
    if ok then return value end
    return nil
end

local function xlf_get_gong_def(gong_id)
    local ok, def = pcall(function()
        return CS.XiaWorld.PracticeMgr.Instance:GetGongDef(tostring(gong_id))
    end)
    if ok then return def end
    return nil
end

local function xlf_gong_name(gong_id)
    local def = xlf_get_gong_def(gong_id)
    if def == nil then return tostring(gong_id) end
    local value = xlf_read_field(def, "DisplayName")
    if value ~= nil then return tostring(value) end
    value = xlf_read_field(def, "Name")
    if value ~= nil then return tostring(value) end
    return tostring(gong_id)
end

local function xlf_gong_key_from_def(def)
    if def == nil then return nil end
    local fields = { "Name", "Key", "Gong", "GongID", "GongId", "DisplayName" }
    for _, field in ipairs(fields) do
        local value = xlf_read_field(def, field)
        if value ~= nil then
            local text = tostring(value)
            if string.find(text, "Gong_", 1, true) ~= nil then return text end
        end
    end
    local text = tostring(def)
    return string.match(text, "(Gong_[%w_]+)")
end

local function xlf_get_npc_current_gong_id(npc)
    local practice = xlf_get_npc_practice(npc)
    if practice == nil then return nil, "no practice" end
    local ok, gong = pcall(function() return practice.Gong end)
    if not ok or gong == nil then
        ok, gong = pcall(function() return practice:get_Gong() end)
    end
    if not ok or gong == nil then return nil, "no Practice.Gong" end

    local key = xlf_gong_key_from_def(gong)
    if key ~= nil then return key, "Practice.Gong" end
    return nil, "Practice.Gong id not readable"
end

local function xlf_get_gong_eso_infos(gong_id, add)
    local list = xlf_new_string_list()
    if list == nil then
        return {
            ok = false,
            ret = "cannot create List<string>",
            list = nil,
            count = 0,
        }
    end

    local ok, ret = pcall(function()
        return CS.CangJingGeMgr.Instance:GetGongEsoInfos(tostring(gong_id), list, add == true)
    end)
    return {
        ok = ok,
        ret = ret,
        list = list,
        count = xlf_count(list),
    }
end

local function xlf_get_school_gong_list()
    local ok, list = pcall(function() return CS.XiaWorld.SchoolMgr.Instance.GongList end)
    if ok then return list, xlf_count(list) end
    return nil, 0
end

local function xlf_get_skill_tree()
    local practice_mgr = CS.XiaWorld.PracticeMgr.Instance
    local ok, tree = pcall(function() return practice_mgr.SkillTree end)
    if ok and tree ~= nil then return tree, "PracticeMgr.Instance.SkillTree" end
    ok, tree = pcall(function() return practice_mgr:get_SkillTree() end)
    if ok and tree ~= nil then return tree, "PracticeMgr.Instance:get_SkillTree()" end
    return nil, "SkillTree not found"
end

local function xlf_get_gong_tree_nodes(gong_id)
    local skill_tree, source = xlf_get_skill_tree()
    if skill_tree == nil then
        return { ok = false, list = nil, count = 0, skill_tree = nil, source = source }
    end

    local ok, list = pcall(function()
        return skill_tree:GetGongTree(tostring(gong_id))
    end)
    return {
        ok = ok,
        list = ok and list or nil,
        count = ok and xlf_count(list) or 0,
        skill_tree = skill_tree,
        source = source,
        error = ok and nil or list,
    }
end

local function xlf_practice_list(practice, field)
    if practice == nil then return nil, 0 end
    local ok, value = pcall(function() return practice[field] end)
    if not ok or value == nil then
        ok, value = pcall(function() return practice["get_" .. field](practice) end)
    end
    if ok then return value, xlf_count(value) end
    return nil, 0
end

local function xlf_is_learned_eso(practice, eso_id)
    if practice == nil or eso_id == nil then return false end
    local text = tostring(eso_id)
    local ok, value = pcall(function() return practice:IsLearnedEsoterica(text) end)
    if ok and value == true then return true end
    ok, value = pcall(function() return practice:CheckIsLearnedEsoteric(text) end)
    if ok and value == true then return true end
    local list = nil
    list = xlf_practice_list(practice, "LearnedEsotericaList")
    if xlf_list_contains(list, text) then return true end
    list = xlf_practice_list(practice, "EsotericaList")
    if xlf_list_contains(list, text) then return true end
    return false
end

local function xlf_is_learned_node(practice, node_id)
    if practice == nil or node_id == nil then return false end
    local text = tostring(node_id)
    local ok, value = pcall(function() return practice:IsLearnedTreeUnit(text) end)
    if ok and value == true then return true end
    local list = nil
    list = xlf_practice_list(practice, "LearnedTreeList")
    if xlf_list_contains(list, text) then return true end
    list = xlf_practice_list(practice, "LearnedTree")
    if xlf_list_contains(list, text) then return true end
    return false
end

local function xlf_node_key_state(node_def)
    if node_def == nil then return false, "node_def nil" end
    local fields = {
        "Esoterica", "EsotericaKey", "EsotericaName", "EsotericaID", "EsotericaId",
        "Eso", "EsoKey", "EsoName", "EsoID", "EsoId",
        "Book", "BookKey", "BookName",
    }
    local seen = {}
    for _, field in ipairs(fields) do
        local ok, value = pcall(function() return node_def[field] end)
        if ok and value ~= nil then
            local text = tostring(value)
            seen[#seen + 1] = field .. "=" .. text
            if text == "" or text == "nil" then
                return false, field .. " is empty"
            end
        end
    end
    if #seen > 0 then return true, table.concat(seen, " | ") end
    return true, "no direct esoterica key field readable"
end

local function xlf_is_key_null_error(value)
    local text = tostring(value or "")
    if string.find(text, "ArgumentNullException", 1, true) ~= nil then return true end
    if string.find(text, "key", 1, true) ~= nil and string.find(text, "null", 1, true) ~= nil then return true end
    if string.find(text, "GetSysEsoterica", 1, true) ~= nil then return true end
    return false
end

local function xlf_lower(value)
    local ok, text = pcall(function() return string.lower(tostring(value or "")) end)
    if ok then return text end
    return ""
end

local function xlf_text_has_any(text, words)
    text = xlf_lower(text)
    for _, word in ipairs(words) do
        if string.find(text, xlf_lower(word), 1, true) ~= nil then return true end
    end
    return false
end

local function xlf_short_value(value)
    if value == nil then return "nil" end
    local count = xlf_count(value)
    if count > 0 then return xlf_list_summary(value, 6) end
    local text = tostring(value)
    if string.len(text) > 160 then text = string.sub(text, 1, 160) .. "..." end
    return text
end

local function xlf_add_candidate(candidates, seen, source, name, value)
    if value == nil then return end
    local text = tostring(value)
    if text == "" or text == "nil" then return end
    local key = tostring(source) .. ":" .. tostring(name) .. ":" .. text
    if seen[key] == true then return end
    seen[key] = true
    candidates[#candidates + 1] = {
        source = tostring(source),
        name = tostring(name),
        value = value,
        text = text,
    }
end

local function xlf_collect_node_candidates(node_def)
    local candidates = {}
    local seen = {}
    local keywords = {
        "eso", "esoterica", "book", "manual", "key", "name", "id",
        "need", "learn", "tree", "gong", "skill", "magic", "item",
    }
    local direct_fields = {
        "Name", "Key", "ID", "Id", "Gong", "GongName", "GongID", "GongId",
        "Tree", "TreeName", "TreeKey", "Node", "NodeName", "NodeKey",
        "Esoterica", "EsotericaKey", "EsotericaName", "EsotericaID", "EsotericaId",
        "Eso", "EsoKey", "EsoName", "EsoID", "EsoId",
        "Book", "BookKey", "BookName", "Manual", "ManualKey", "ManualName",
        "Need", "NeedCount", "NeedItem", "NeedEsoterica",
        "Learn", "LearnKey", "LearnNode", "Skill", "SkillKey", "Magic", "MagicKey",
        "Desc", "Description", "Story",
    }

    for _, field in ipairs(direct_fields) do
        local ok, value = pcall(function() return node_def[field] end)
        if ok and value ~= nil then xlf_add_candidate(candidates, seen, "direct", field, value) end
    end

    local ok_type, typ = pcall(function() return node_def:GetType() end)
    if ok_type and typ ~= nil then
        local ok_fields, fields = pcall(function() return typ:GetFields() end)
        if ok_fields and fields ~= nil then
            local count = xlf_count(fields)
            for i = 0, count - 1 do
                local field_info = xlf_item(fields, i)
                local ok_name, name = pcall(function() return field_info.Name end)
                name = ok_name and tostring(name) or ""
                if name ~= "" and xlf_text_has_any(name, keywords) then
                    local ok_value, value = pcall(function() return field_info:GetValue(node_def) end)
                    if ok_value and value ~= nil then xlf_add_candidate(candidates, seen, "field", name, value) end
                end
                if #candidates >= 120 then break end
            end
        end

        local ok_props, props = pcall(function() return typ:GetProperties() end)
        if ok_props and props ~= nil then
            local count = xlf_count(props)
            for i = 0, count - 1 do
                local prop_info = xlf_item(props, i)
                local ok_name, name = pcall(function() return prop_info.Name end)
                name = ok_name and tostring(name) or ""
                if name ~= "" and xlf_text_has_any(name, keywords) then
                    local ok_index, indexes = pcall(function() return prop_info:GetIndexParameters() end)
                    if (not ok_index) or xlf_count(indexes) == 0 then
                        local ok_value, value = pcall(function() return prop_info:GetValue(node_def, nil) end)
                        if ok_value and value ~= nil then xlf_add_candidate(candidates, seen, "property", name, value) end
                    end
                end
                if #candidates >= 160 then break end
            end
        end
    end

    return candidates
end

local function xlf_try_resolve_esoterica_value(value)
    if value == nil then return nil end
    local text = tostring(value)
    if text == "" or text == "nil" then return nil end
    if string.len(text) > 120 then return nil end

    local managers = {
        { name = "CangJingGeMgr", obj = function() return CS.CangJingGeMgr.Instance end },
        { name = "EsotericaMgr", obj = function() return CS.XiaWorld.EsotericaMgr.Instance end },
    }
    local methods = { "GetSysEsoterica", "GetEsotericaDef", "CheckEso" }
    local hits = {}

    for _, manager in ipairs(managers) do
        local ok_mgr, obj = pcall(manager.obj)
        if ok_mgr and obj ~= nil then
            for _, method_name in ipairs(methods) do
                local ok_method, method = pcall(function() return obj[method_name] end)
                if ok_method and method ~= nil then
                    local ok_call, ret = pcall(function() return method(obj, text) end)
                    if ok_call and ret ~= nil and ret ~= false then
                        hits[#hits + 1] = manager.name .. "." .. method_name .. "=" .. xlf_short_value(ret)
                    end
                end
            end
        end
    end

    if #hits <= 0 then return nil end
    return table.concat(hits, " | ")
end

local function xlf_inspect_node_def(node_id, node_def)
    local lines = {}
    lines[#lines + 1] = "Node=" .. xlf_str(node_id)
    lines[#lines + 1] = "NodeDef=" .. xlf_str(node_def)
    if node_def == nil then return table.concat(lines, "\n") end

    local ok_type, typ = pcall(function() return node_def:GetType() end)
    lines[#lines + 1] = "Type=" .. xlf_str(ok_type and typ or nil)

    local key_ok, key_state = xlf_node_key_state(node_def)
    lines[#lines + 1] = "KeyState ok=" .. tostring(key_ok) .. " detail=" .. xlf_str(key_state)

    local candidates = xlf_collect_node_candidates(node_def)
    lines[#lines + 1] = "CandidateMemberCount=" .. tostring(#candidates)
    local max_show = #candidates
    if max_show > 40 then max_show = 40 end
    for i = 1, max_show do
        local c = candidates[i]
        lines[#lines + 1] = "  " .. tostring(i) .. ". "
            .. c.source .. "." .. c.name .. "=" .. xlf_short_value(c.value)
    end
    if #candidates > max_show then
        lines[#lines + 1] = "  ... +" .. tostring(#candidates - max_show) .. " more members"
    end

    local resolve_lines = {}
    local seen_values = {}
    for _, c in ipairs(candidates) do
        local text = tostring(c.value)
        if seen_values[text] ~= true then
            seen_values[text] = true
            local resolved = xlf_try_resolve_esoterica_value(c.value)
            if resolved ~= nil then
                resolve_lines[#resolve_lines + 1] = c.name .. "=" .. text .. " => " .. resolved
            end
        end
        if #resolve_lines >= 20 then break end
    end
    if #resolve_lines <= 0 then
        lines[#lines + 1] = "ResolvedEsotericaRefs=none"
    else
        lines[#lines + 1] = "ResolvedEsotericaRefs:"
        for _, line in ipairs(resolve_lines) do
            lines[#lines + 1] = "  " .. line
        end
    end

    return table.concat(lines, "\n")
end

local function xlf_learn_tree_node(practice, node_def)
    local key_ok, key_state = xlf_node_key_state(node_def)
    if key_ok ~= true then
        return false, key_state, "skip-empty-key", true, key_state
    end

    local ok, value = pcall(function()
        return practice:LearnTreeNode(node_def, 1.0, false, false)
    end)
    if ok and value ~= false then
        return true, value, "LearnTreeNode(nodeDef,1,false,false)", false, key_state
    end

    local first_error = value
    ok, value = pcall(function()
        return practice:LearnTreeNode(node_def, 1.0, 0, false, true)
    end)
    if ok and value ~= false then
        return true, value, "LearnTreeNode(nodeDef,1,0,false,true)", false, key_state
    end

    local merged = tostring(first_error) .. " | fallback=" .. tostring(value)
    if xlf_is_key_null_error(first_error) or xlf_is_key_null_error(value) then
        return false, merged, "skip-key-null-error", true, key_state
    end
    return false, merged, "failed", false, key_state
end

local function xlf_refresh_ui()
    local lines = {}
    local classes = {
        "Wnd_NpcPractice", "Wnd_Practice", "Wnd_NpcInfo", "Wnd_ThingInfo",
        "Wnd_SelectNpc", "Wnd_Message",
    }
    local methods = {
        "Refresh", "RefreshUI", "UpdateInfo", "UpdateView", "Update",
        "OnUpdate", "ShowInfo", "Reset",
    }

    for _, class_name in ipairs(classes) do
        local ok_cls, cls = pcall(function() return CS[class_name] end)
        if ok_cls and cls ~= nil then
            local ok_inst, inst = pcall(function() return cls.Instance end)
            if ok_inst and inst ~= nil then
                for _, method_name in ipairs(methods) do
                    local ok_method, method = pcall(function() return inst[method_name] end)
                    if ok_method and method ~= nil then
                        local ok_call = pcall(function() return method(inst) end)
                        if ok_call then
                            lines[#lines + 1] = class_name .. "." .. method_name
                            break
                        end
                    end
                end
            end
        end
    end

    return #lines, table.concat(lines, ", ")
end

local function xlf_counts_line(practice, label)
    local learned_eso, learned_eso_count = xlf_practice_list(practice, "LearnedEsotericaList")
    local learned_tree, learned_tree_count = xlf_practice_list(practice, "LearnedTreeList")
    return tostring(label)
        .. " LearnedEsotericaList=" .. tostring(learned_eso_count)
        .. " " .. xlf_list_summary(learned_eso, 8)
        .. " | LearnedTreeList=" .. tostring(learned_tree_count)
        .. " " .. xlf_list_summary(learned_tree, 8)
end

local function xlf_show_result(result, success_text, fail_text, title)
    title = title or "Xaou Learn"
    if xlf_debug_enabled() then
        xlf_show(result ~= nil and (result.report or xlf_str(result)) or xlf_str(result), title)
        return
    end

    if result ~= nil and result.ok == true then
        xlf_show(success_text, title)
    else
        xlf_show(fail_text, title)
    end
end

function Xaou_LearnFullGong(npc, gong_id, options)
    options = options or {}
    local result = {
        ok = false,
        npc = npc,
        gong_id = gong_id ~= nil and tostring(gong_id) or nil,
        eso_found = 0,
        eso_added = 0,
        eso_already = 0,
        eso_failed = 0,
        node_found = 0,
        node_learned = 0,
        node_already = 0,
        node_skipped = 0,
        node_failed = 0,
        skipped_nodes = {},
        failed_nodes = {},
        skipped_node_details = {},
        lines = {},
    }
    local lines = result.lines

    lines[#lines + 1] = "Xaou LearnFullGong"
    lines[#lines + 1] = "Made by xaou"
    lines[#lines + 1] = "No AddGong call."
    lines[#lines + 1] = "Mode=Safe Learn"
    lines[#lines + 1] = "NPC=" .. xlf_npc_name(npc)
    lines[#lines + 1] = "GongId=" .. xlf_str(result.gong_id)
    lines[#lines + 1] = "GongName=" .. xlf_str(result.gong_id ~= nil and xlf_gong_name(result.gong_id) or nil)

    if npc == nil then
        lines[#lines + 1] = "Stopped: npc nil."
        result.report = table.concat(lines, "\n")
        return result
    end
    if result.gong_id == nil or result.gong_id == "" then
        lines[#lines + 1] = "Stopped: gongId nil."
        result.report = table.concat(lines, "\n")
        return result
    end

    local practice, practice_source = xlf_get_npc_practice(npc)
    lines[#lines + 1] = "PracticeSource=" .. xlf_str(practice_source)
    lines[#lines + 1] = "Practice=" .. xlf_str(practice)
    if practice == nil then
        lines[#lines + 1] = "Stopped: practice nil."
        result.report = table.concat(lines, "\n")
        return result
    end

    local eso_detail = xlf_get_gong_eso_infos(result.gong_id, true)
    result.eso_found = eso_detail.count
    lines[#lines + 1] = "GetGongEsoInfos ok=" .. tostring(eso_detail.ok)
        .. " return=" .. xlf_str(eso_detail.ret)
        .. " list=" .. xlf_list_summary(eso_detail.list, 12)
    if eso_detail.ok ~= true or eso_detail.count <= 0 then
        lines[#lines + 1] = "Stopped: no esoterica info for gong."
        result.report = table.concat(lines, "\n")
        return result
    end

    local nodes = xlf_get_gong_tree_nodes(result.gong_id)
    result.node_found = nodes.count
    lines[#lines + 1] = "GetGongTree ok=" .. tostring(nodes.ok)
        .. " source=" .. xlf_str(nodes.source)
        .. " count=" .. tostring(nodes.count)
        .. " list=" .. xlf_list_summary(nodes.list, 12)
    if nodes.ok ~= true or nodes.count <= 0 or nodes.skill_tree == nil then
        lines[#lines + 1] = "Stopped: no skill tree nodes."
        result.report = table.concat(lines, "\n")
        return result
    end

    lines[#lines + 1] = xlf_counts_line(practice, "Before")

    local ok_refresh_before, refresh_before = pcall(function() return practice:RefreshLearnCache() end)
    lines[#lines + 1] = "RefreshLearnCache(before) ok=" .. tostring(ok_refresh_before) .. " value=" .. xlf_str(refresh_before)

    local learned_tree_list, learned_tree_count = xlf_practice_list(practice, "LearnedTreeList")
    if learned_tree_count <= 0 then
        local ok_random_tree, random_tree_value = pcall(function()
            return practice:RandomTree(false, result.gong_id, false)
        end)
        lines[#lines + 1] = "RandomTree(false,gongId,false) ok=" .. tostring(ok_random_tree) .. " value=" .. xlf_str(random_tree_value)
    else
        lines[#lines + 1] = "RandomTree skipped: LearnedTreeList already has " .. tostring(learned_tree_count)
    end

    local ok_refresh_prepare, refresh_prepare = pcall(function() return practice:RefreshLearnCache() end)
    lines[#lines + 1] = "RefreshLearnCache(after prepare) ok=" .. tostring(ok_refresh_prepare) .. " value=" .. xlf_str(refresh_prepare)

    for i = 0, eso_detail.count - 1 do
        local eso_id = xlf_item(eso_detail.list, i)
        if eso_id ~= nil then
            eso_id = tostring(eso_id)
            if xlf_is_learned_eso(practice, eso_id) then
                result.eso_already = result.eso_already + 1
            else
                local ok_add, add_value = pcall(function()
                    return practice:AddEsotericaList(eso_id)
                end)
                if ok_add and add_value ~= false then
                    result.eso_added = result.eso_added + 1
                else
                    result.eso_failed = result.eso_failed + 1
                    result.failed_nodes[#result.failed_nodes + 1] = "Eso " .. eso_id .. " | " .. xlf_str(add_value)
                end
            end
        else
            result.eso_failed = result.eso_failed + 1
        end
    end

    for i = 0, nodes.count - 1 do
        local node_id = xlf_item(nodes.list, i)
        if node_id ~= nil then
            node_id = tostring(node_id)
            if xlf_is_learned_node(practice, node_id) then
                result.node_already = result.node_already + 1
            else
                local ok_def, node_def = pcall(function()
                    return nodes.skill_tree:GetDef(node_id)
                end)
                if ok_def and node_def ~= nil then
                    local ok_node, node_value, node_method, node_skip, key_state = xlf_learn_tree_node(practice, node_def)
                    if ok_node then
                        result.node_learned = result.node_learned + 1
                    elseif node_skip == true then
                        local inspect = xlf_inspect_node_def(node_id, node_def)
                        result.skipped_node_details[#result.skipped_node_details + 1] = inspect
                        result.node_skipped = result.node_skipped + 1
                        result.skipped_nodes[#result.skipped_nodes + 1] = node_id .. " | " .. xlf_str(node_method) .. " | " .. xlf_str(key_state)
                    else
                        result.node_failed = result.node_failed + 1
                        result.failed_nodes[#result.failed_nodes + 1] = node_id .. " | " .. xlf_str(node_method) .. " | " .. xlf_str(node_value)
                    end
                else
                    result.node_failed = result.node_failed + 1
                    result.failed_nodes[#result.failed_nodes + 1] = node_id .. " | GetDef failed | " .. xlf_str(node_def)
                end
            end
        else
            result.node_skipped = result.node_skipped + 1
            result.skipped_nodes[#result.skipped_nodes + 1] = "nil node id"
        end
    end

    local ok_refresh_after, refresh_after = pcall(function() return practice:RefreshLearnCache() end)
    lines[#lines + 1] = "RefreshLearnCache(after learn) ok=" .. tostring(ok_refresh_after) .. " value=" .. xlf_str(refresh_after)

    local ui_count, ui_detail = xlf_refresh_ui()
    lines[#lines + 1] = "RefreshUI count=" .. tostring(ui_count) .. " detail=" .. xlf_str(ui_detail)
    lines[#lines + 1] = xlf_counts_line(practice, "After")

    result.ok = result.eso_failed == 0 and result.node_failed == 0
    lines[#lines + 1] = "Summary:"
    lines[#lines + 1] = "EsoFound=" .. tostring(result.eso_found)
        .. " Added=" .. tostring(result.eso_added)
        .. " Already=" .. tostring(result.eso_already)
        .. " Failed=" .. tostring(result.eso_failed)
    lines[#lines + 1] = "TreeNodeFound=" .. tostring(result.node_found)
        .. " Learned=" .. tostring(result.node_learned)
        .. " Already=" .. tostring(result.node_already)
        .. " Skipped=" .. tostring(result.node_skipped)
        .. " Failed=" .. tostring(result.node_failed)
    lines[#lines + 1] = "SkippedNodes=" .. (#result.skipped_nodes > 0 and table.concat(result.skipped_nodes, " || ") or "none")
    lines[#lines + 1] = "FailedNodes=" .. (#result.failed_nodes > 0 and table.concat(result.failed_nodes, " || ") or "none")
    if #result.skipped_node_details > 0 then
        lines[#lines + 1] = "SkippedNodeDetails:"
        for _, detail in ipairs(result.skipped_node_details) do
            lines[#lines + 1] = "------------------------------------------------------------"
            lines[#lines + 1] = detail
        end
    end
    lines[#lines + 1] = "SaveLoadTest: save game, load game, then re-open NPC practice UI and check Extra Manuals / learned nodes."

    result.report = table.concat(lines, "\n")
    return result
end

LearnFullGong = Xaou_LearnFullGong

local function xlf_bool_value(value)
    if value == true then return true end
    if value == false or value == nil then return false end
    local text = string.lower(tostring(value))
    return text == "true" or text == "1"
end

local function xlf_count_potential_keyless_nodes(nodes)
    if nodes == nil or nodes.ok ~= true or nodes.list == nil or nodes.skill_tree == nil then return 0, {} end
    local count = nodes.count or xlf_count(nodes.list)
    local keyless = 0
    local names = {}
    for i = 0, count - 1 do
        local node_id = xlf_item(nodes.list, i)
        if node_id ~= nil then
            node_id = tostring(node_id)
            local ok_def, node_def = pcall(function()
                return nodes.skill_tree:GetDef(node_id)
            end)
            if ok_def and node_def ~= nil then
                local key_ok, key_state = xlf_node_key_state(node_def)
                if key_ok ~= true then
                    keyless = keyless + 1
                    names[#names + 1] = node_id .. "(" .. xlf_str(key_state) .. ")"
                end
            end
        end
    end
    return keyless, names
end

local function xlf_dry_run_all_gongs(npc)
    local lines = {
        "Xaou Learn All Gongs Dry-run",
        "Made by xaou",
        "Dry-run only.",
        "No AddEsotericaList call.",
        "No LearnTreeNode call.",
        "NPC=" .. xlf_npc_name(npc),
    }

    local practice, practice_source = xlf_get_npc_practice(npc)
    lines[#lines + 1] = "PracticeSource=" .. xlf_str(practice_source)
    lines[#lines + 1] = "Practice=" .. xlf_str(practice)
    if practice ~= nil then
        lines[#lines + 1] = xlf_counts_line(practice, "NPC Current")
    end

    local gong_list, gong_count = xlf_get_school_gong_list()
    lines[#lines + 1] = "SchoolMgr.GongList.Count=" .. tostring(gong_count)
    if gong_list == nil or gong_count <= 0 then
        lines[#lines + 1] = "Stopped: GongList is empty."
        return table.concat(lines, "\n")
    end

    local total = 0
    local ready = 0
    local skip = 0
    local no_eso = 0
    local no_tree = 0
    local hidden = 0
    local def_missing = 0
    local total_eso = 0
    local total_nodes = 0
    local total_potential_keyless = 0

    lines[#lines + 1] = ""
    lines[#lines + 1] = "Gong list:"

    for i = 0, gong_count - 1 do
        local raw = xlf_item(gong_list, i)
        local gong_id = raw ~= nil and tostring(raw) or nil
        if gong_id ~= nil and gong_id ~= "" then
            total = total + 1
            local def = xlf_get_gong_def(gong_id)
            local hide_value = def ~= nil and xlf_read_field(def, "Hide") or nil
            local hide = xlf_bool_value(hide_value)
            local kind_value = def ~= nil and (xlf_read_field(def, "GongKind") or xlf_read_field(def, "Kind")) or nil
            local eso_detail = xlf_get_gong_eso_infos(gong_id, true)
            local eso_count = eso_detail.count or 0
            local nodes = xlf_get_gong_tree_nodes(gong_id)
            local node_count = nodes.count or 0
            local keyless_count, keyless_names = xlf_count_potential_keyless_nodes(nodes)
            local status = "READY"
            local reason = "ok"

            if def == nil then
                status = "SKIP"
                reason = "GetGongDef=nil"
                def_missing = def_missing + 1
            elseif hide == true then
                status = "SKIP"
                reason = "Hide=true"
                hidden = hidden + 1
            elseif eso_detail.ok ~= true or eso_count <= 0 then
                status = "SKIP"
                reason = "EsoListCount=0"
                no_eso = no_eso + 1
            elseif nodes.ok ~= true or node_count <= 0 then
                status = "SKIP"
                reason = "TreeNodeCount=0"
                no_tree = no_tree + 1
            else
                ready = ready + 1
            end

            if status == "SKIP" then skip = skip + 1 end
            total_eso = total_eso + eso_count
            total_nodes = total_nodes + node_count
            total_potential_keyless = total_potential_keyless + keyless_count

            lines[#lines + 1] = tostring(total) .. ". [" .. status .. "] "
                .. gong_id
                .. " | " .. xlf_gong_name(gong_id)
                .. " | EsoListCount=" .. tostring(eso_count)
                .. " | TreeNodeCount=" .. tostring(node_count)
                .. " | PotentialKeyless=" .. tostring(keyless_count)
                .. " | Hide=" .. xlf_str(hide_value)
                .. " | Kind=" .. xlf_str(kind_value)
                .. " | Reason=" .. reason
            if #keyless_names > 0 then
                lines[#lines + 1] = "   PotentialKeylessNodes=" .. table.concat(keyless_names, " | ")
            end
        end
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "Summary:"
    lines[#lines + 1] = "TotalGongs=" .. tostring(total)
        .. " Ready=" .. tostring(ready)
        .. " Skip=" .. tostring(skip)
    lines[#lines + 1] = "SkipReasons:"
        .. " NoEso=" .. tostring(no_eso)
        .. " NoTree=" .. tostring(no_tree)
        .. " Hidden=" .. tostring(hidden)
        .. " DefMissing=" .. tostring(def_missing)
    lines[#lines + 1] = "Totals:"
        .. " EsoListCount=" .. tostring(total_eso)
        .. " TreeNodeCount=" .. tostring(total_nodes)
        .. " PotentialKeylessNodes=" .. tostring(total_potential_keyless)
    lines[#lines + 1] = "NextStep: if this dry-run looks correct, add real Learn All Gongs using READY entries only."

    return table.concat(lines, "\n")
end

local function xlf_collect_ready_gongs()
    local entries = {}
    local scan_lines = {}
    local stats = {
        total = 0,
        ready = 0,
        skip = 0,
        no_eso = 0,
        no_tree = 0,
        hidden = 0,
        def_missing = 0,
    }

    local gong_list, gong_count = xlf_get_school_gong_list()
    if gong_list == nil or gong_count <= 0 then
        scan_lines[#scan_lines + 1] = "SchoolMgr.GongList is empty."
        return entries, stats, table.concat(scan_lines, "\n")
    end

    for i = 0, gong_count - 1 do
        local raw = xlf_item(gong_list, i)
        local gong_id = raw ~= nil and tostring(raw) or nil
        if gong_id ~= nil and gong_id ~= "" then
            stats.total = stats.total + 1
            local def = xlf_get_gong_def(gong_id)
            local hide_value = def ~= nil and xlf_read_field(def, "Hide") or nil
            local hide = xlf_bool_value(hide_value)
            local eso_detail = xlf_get_gong_eso_infos(gong_id, true)
            local eso_count = eso_detail.count or 0
            local nodes = xlf_get_gong_tree_nodes(gong_id)
            local node_count = nodes.count or 0
            local ready = true
            local reason = "ok"

            if def == nil then
                ready = false
                reason = "GetGongDef=nil"
                stats.def_missing = stats.def_missing + 1
            elseif hide == true then
                ready = false
                reason = "Hide=true"
                stats.hidden = stats.hidden + 1
            elseif eso_detail.ok ~= true or eso_count <= 0 then
                ready = false
                reason = "EsoListCount=0"
                stats.no_eso = stats.no_eso + 1
            elseif nodes.ok ~= true or node_count <= 0 then
                ready = false
                reason = "TreeNodeCount=0"
                stats.no_tree = stats.no_tree + 1
            end

            if ready then
                stats.ready = stats.ready + 1
                entries[#entries + 1] = {
                    gong_id = gong_id,
                    eso_count = eso_count,
                    node_count = node_count,
                }
            else
                stats.skip = stats.skip + 1
            end

            scan_lines[#scan_lines + 1] = tostring(stats.total) .. ". "
                .. (ready and "[READY] " or "[SKIP] ")
                .. gong_id
                .. " | " .. xlf_gong_name(gong_id)
                .. " | EsoListCount=" .. tostring(eso_count)
                .. " | TreeNodeCount=" .. tostring(node_count)
                .. " | Reason=" .. reason
        end
    end

    return entries, stats, table.concat(scan_lines, "\n")
end

local function xlf_learn_all_gongs(npc)
    local result = {
        ok = false,
        ready_gongs = 0,
        success_gongs = 0,
        failed_gongs = 0,
        report = nil,
    }
    local lines = {
        "Xaou Learn All Gongs",
        "Made by xaou",
        "Mode=Real Learn",
        "No AddGong call.",
        "Uses only READY entries from SchoolMgr.GongList.",
        "NPC=" .. xlf_npc_name(npc),
    }

    local entries, stats, scan_report = xlf_collect_ready_gongs()
    lines[#lines + 1] = "Scan:"
    lines[#lines + 1] = scan_report
    lines[#lines + 1] = "ScanSummary: TotalGongs=" .. tostring(stats.total)
        .. " Ready=" .. tostring(stats.ready)
        .. " Skip=" .. tostring(stats.skip)

    if #entries <= 0 then
        lines[#lines + 1] = "Stopped: no READY gong entries."
        result.report = table.concat(lines, "\n")
        return result
    end

    local ok_count = 0
    local fail_count = 0
    local eso_added = 0
    local eso_already = 0
    local eso_failed = 0
    local node_learned = 0
    local node_already = 0
    local node_skipped = 0
    local node_failed = 0
    local failed_gongs = {}
    local skipped_nodes = {}

    lines[#lines + 1] = ""
    lines[#lines + 1] = "Learn loop:"

    for i, entry in ipairs(entries) do
        local ok, result = pcall(function()
            return Xaou_LearnFullGong(npc, entry.gong_id)
        end)

        if ok and result ~= nil then
            if result.ok == true then ok_count = ok_count + 1 else fail_count = fail_count + 1 end
            eso_added = eso_added + tonumber(result.eso_added or 0)
            eso_already = eso_already + tonumber(result.eso_already or 0)
            eso_failed = eso_failed + tonumber(result.eso_failed or 0)
            node_learned = node_learned + tonumber(result.node_learned or 0)
            node_already = node_already + tonumber(result.node_already or 0)
            node_skipped = node_skipped + tonumber(result.node_skipped or 0)
            node_failed = node_failed + tonumber(result.node_failed or 0)

            if result.ok ~= true then
                failed_gongs[#failed_gongs + 1] = entry.gong_id
            end
            if result.skipped_nodes ~= nil and #result.skipped_nodes > 0 then
                skipped_nodes[#skipped_nodes + 1] = entry.gong_id .. ": " .. table.concat(result.skipped_nodes, " | ")
            end

            lines[#lines + 1] = tostring(i) .. ". " .. entry.gong_id
                .. " | ok=" .. tostring(result.ok == true)
                .. " | Eso Added=" .. tostring(result.eso_added or 0)
                .. " Already=" .. tostring(result.eso_already or 0)
                .. " Failed=" .. tostring(result.eso_failed or 0)
                .. " | Nodes Learned=" .. tostring(result.node_learned or 0)
                .. " Already=" .. tostring(result.node_already or 0)
                .. " Skipped=" .. tostring(result.node_skipped or 0)
                .. " Failed=" .. tostring(result.node_failed or 0)
        else
            fail_count = fail_count + 1
            failed_gongs[#failed_gongs + 1] = entry.gong_id .. " | exception=" .. xlf_str(result)
            lines[#lines + 1] = tostring(i) .. ". " .. entry.gong_id
                .. " | exception=" .. xlf_str(result)
        end
    end

    local practice = xlf_get_npc_practice(npc)
    if practice ~= nil then
        lines[#lines + 1] = xlf_counts_line(practice, "After Learn All")
    end
    xlf_refresh_ui()

    lines[#lines + 1] = ""
    lines[#lines + 1] = "Summary:"
    lines[#lines + 1] = "ReadyGongs=" .. tostring(#entries)
        .. " SuccessGongs=" .. tostring(ok_count)
        .. " FailedGongs=" .. tostring(fail_count)
    lines[#lines + 1] = "Eso Added=" .. tostring(eso_added)
        .. " Already=" .. tostring(eso_already)
        .. " Failed=" .. tostring(eso_failed)
    lines[#lines + 1] = "TreeNodes Learned=" .. tostring(node_learned)
        .. " Already=" .. tostring(node_already)
        .. " Skipped=" .. tostring(node_skipped)
        .. " Failed=" .. tostring(node_failed)
    lines[#lines + 1] = "SkippedNodes=" .. (#skipped_nodes > 0 and table.concat(skipped_nodes, " || ") or "none")
    lines[#lines + 1] = "FailedGongList=" .. (#failed_gongs > 0 and table.concat(failed_gongs, " || ") or "none")

    result.ready_gongs = #entries
    result.success_gongs = ok_count
    result.failed_gongs = fail_count
    result.ok = fail_count == 0 and eso_failed == 0 and node_failed == 0
    result.report = table.concat(lines, "\n")
    return result
end

local function xlf_confirm_and_learn_all(npc)
    local helper = xlf_helper()
    if helper == nil then
        local result = xlf_learn_all_gongs(npc)
        xlf_show_result(result, "เรียนทุกวิชาในสำนักสำเร็จแล้ว", "ไม่พบวิชาที่สามารถเรียนได้", "Xaou Learn")
        return
    end

    local text = "Xaou Learn\nผู้สร้าง: xaou\n\nต้องการเรียนทุกวิชาในสำนักให้ NPC ที่เลือกใช่ไหม?"
    helper:ShowSelectBox(text, { "ยืนยัน" }, 1, 1, function(confirm_result)
        local index = xlf_select_index(confirm_result)
        if index == 0 then
            local ok, result = pcall(function()
                return xlf_learn_all_gongs(npc)
            end)
            if ok then
                xlf_show_result(result, "เรียนทุกวิชาในสำนักสำเร็จแล้ว", "ไม่พบวิชาที่สามารถเรียนได้", "Xaou Learn")
            else
                if xlf_debug_enabled() then
                    xlf_show("Learn All Gongs failed:\n" .. xlf_str(result), "Xaou Learn")
                else
                    xlf_show("เรียนทุกวิชาไม่สำเร็จ", "Xaou Learn")
                end
            end
        end
    end)
end

local function xlf_current_gong_entry(npc)
    local npc_gong, npc_source = xlf_get_npc_current_gong_id(npc)
    if npc_gong == nil or tostring(npc_gong) == "" then
        return nil
    end

    local detail = xlf_get_gong_eso_infos(npc_gong, true)
    if detail == nil or detail.ok ~= true or tonumber(detail.count or 0) <= 0 then
        return nil
    end

    return {
        gong_id = tostring(npc_gong),
        source = npc_source or "NPC current",
        eso_count = detail.count,
    }
end

local function xlf_confirm_and_learn(npc, entry)
    if entry == nil or entry.gong_id == nil then
        xlf_show("ไม่พบวิชาที่สามารถเรียนได้", "Xaou Learn")
        return
    end

    local helper = xlf_helper()
    if helper == nil then
        local result = Xaou_LearnFullGong(npc, entry.gong_id)
        xlf_show_result(result, "เรียนวิชาสำเร็จแล้ว", "ไม่พบวิชาที่สามารถเรียนได้", "Xaou Learn")
        return
    end

    local text = "Xaou Learn\nผู้สร้าง: xaou\n\nต้องการเรียนวิชาปัจจุบันของ NPC ที่เลือกใช่ไหม?"
    helper:ShowSelectBox(text, { "ยืนยัน" }, 1, 1, function(confirm_result)
        local index = xlf_select_index(confirm_result)
        if index == 0 then
            local ok, result = pcall(function()
                return Xaou_LearnFullGong(npc, entry.gong_id)
            end)
            if ok and result ~= nil then
                xlf_show_result(result, "เรียนวิชาสำเร็จแล้ว", "ไม่พบวิชาที่สามารถเรียนได้", "Xaou Learn")
            else
                if xlf_debug_enabled() then
                    xlf_show("LearnFullGong failed:\n" .. xlf_str(result), "Xaou Learn")
                else
                    xlf_show("เรียนวิชาไม่สำเร็จ", "Xaou Learn")
                end
            end
        end
    end)
end

local function xlf_set_obj_text(obj, text)
    if obj == nil then return end
    pcall(function() obj.text = tostring(text or "") end)
    pcall(function() obj.title = tostring(text or "") end)
    pcall(function()
        if obj.m_title ~= nil then obj.m_title.text = tostring(text or "") end
    end)
end

local function xlf_set_obj_icon(obj, icon)
    if obj == nil then return end
    pcall(function() obj.icon = tostring(icon or "") end)
    pcall(function()
        if obj.m_icon ~= nil then obj.m_icon.icon = tostring(icon or "") end
    end)
    pcall(function()
        local c = obj:GetChild("icon")
        if c ~= nil then c.icon = tostring(icon or "") end
    end)
end

local function xlf_set_text_size(obj, size)
    if obj == nil then return end
    pcall(function()
        if obj.m_title ~= nil and obj.m_title.textFormat ~= nil then
            obj.m_title.textFormat.size = size
            obj.m_title:ApplyFormat()
        end
    end)
end

local function xlf_clean_learn_label(obj)
    if obj == nil then return end
    pcall(function()
        local n = tonumber(obj.numChildren) or 0
        for i = 0, n - 1 do
            local child = obj:GetChildAt(i)
            if child ~= nil and child ~= obj.m_title then
                child.visible = false
            end
        end
    end)
    pcall(function() if obj.m_button ~= nil then obj.m_button.visible = false end end)
    pcall(function() if obj.m_icon ~= nil then obj.m_icon.visible = false end end)
    pcall(function() if obj.m_check ~= nil then obj.m_check.visible = false end end)
    pcall(function() if obj.m_checkmark ~= nil then obj.m_checkmark.visible = false end end)
end

local function xlf_center_learn_window(wnd)
    if wnd == nil then return end
    local root = nil
    pcall(function()
        if GRoot ~= nil then root = GRoot.inst end
    end)
    pcall(function()
        if root == nil and CS ~= nil and CS.FairyGUI ~= nil and CS.FairyGUI.GRoot ~= nil then
            root = CS.FairyGUI.GRoot.inst
        end
    end)

    local rw = 1280
    local rh = 720
    if root ~= nil then
        pcall(function() rw = tonumber(root.width) or rw end)
        pcall(function() rh = tonumber(root.height) or rh end)
    end
    pcall(function()
        if CS ~= nil and CS.UnityEngine ~= nil and CS.UnityEngine.Screen ~= nil then
            rw = tonumber(CS.UnityEngine.Screen.width) or rw
            rh = tonumber(CS.UnityEngine.Screen.height) or rh
        end
    end)

    local ww = tonumber(wnd.sx) or 760
    local wh = tonumber(wnd.sy) or 500
    local px = math.floor((rw - ww) / 2)
    local py = math.floor((rh - wh) / 2)
    if px < 0 then px = 0 end
    if py < 20 then py = 20 end

    pcall(function()
        if wnd.window ~= nil and wnd.window.SetXY ~= nil then
            wnd.window:SetXY(px, py)
        elseif wnd.window ~= nil then
            wnd.window.x = px
            wnd.window.y = py
        end
    end)
    pcall(function()
        if wnd.window ~= nil and wnd.window.BringToFront ~= nil then
            wnd.window:BringToFront()
        end
    end)
end

local function xlf_run_learn_all_from_menu(npc)
    local ok, result = pcall(function()
        return xlf_learn_all_gongs(npc)
    end)
    if ok then
        xlf_show_result(result, "เรียนทุกวิชาในสำนักสำเร็จแล้ว", "ไม่พบวิชาที่สามารถเรียนได้", "Xaou Learn")
    else
        if xlf_debug_enabled() then
            xlf_show("Learn All Gongs failed:\n" .. xlf_str(result), "Xaou Learn")
        else
            xlf_show("เรียนทุกวิชาไม่สำเร็จ", "Xaou Learn")
        end
    end
end

local function xlf_run_current_gong_from_menu(npc)
    local entry = xlf_current_gong_entry(npc)
    if entry == nil or entry.gong_id == nil then
        xlf_show("ไม่พบวิชาที่สามารถเรียนได้", "Xaou Learn")
        return
    end

    local ok, result = pcall(function()
        return Xaou_LearnFullGong(npc, entry.gong_id)
    end)
    if ok and result ~= nil then
        xlf_show_result(result, "เรียนวิชาสำเร็จแล้ว", "ไม่พบวิชาที่สามารถเรียนได้", "Xaou Learn")
    else
        if xlf_debug_enabled() then
            xlf_show("LearnFullGong failed:\n" .. xlf_str(result), "Xaou Learn")
        else
            xlf_show("เรียนวิชาไม่สำเร็จ", "Xaou Learn")
        end
    end
end

local function xlf_create_learn_window()
    if XLF_LearnWindow ~= nil then return XLF_LearnWindow end
    if CS == nil or CS.Wnd_Simple == nil or CS.Wnd_Simple.CreateWindow == nil then
        return nil
    end

    local wnd = CS.Wnd_Simple.CreateWindow("XaouLearnWindow")
    XLF_LearnWindow = wnd
    if _G ~= nil then _G.XaouLearnWindow = wnd end

    function wnd:AddLearnLabel(name, text, x, y, w, h, size)
        local obj = self:AddObjectFromUrl("ui://0xrxw6g7hdhl1b", x, y)
        obj.name = name
        xlf_set_obj_text(obj, text)
        pcall(function() obj:SetSize(w or 200, h or 28, false) end)
        xlf_set_text_size(obj, size or 22)
        xlf_clean_learn_label(obj)
        return obj
    end

    function wnd:AddLearnButton(name, text, x, y, w, h, icon, size)
        local obj = self:AddObjectFromUrl("ui://0xrxw6g7hdhl18", x, y)
        obj.name = name
        xlf_set_obj_text(obj, text)
        pcall(function() obj:SetSize(w or 120, h or 42, false) end)
        xlf_set_text_size(obj, size or 24)
        if icon ~= nil and icon ~= "" then
            xlf_set_obj_icon(obj, icon)
            pcall(function()
                if obj.m_icon ~= nil then
                    obj.m_icon.x = 16
                    obj.m_icon.y = 12
                    obj.m_title.x = 72
                    obj.m_title.y = 8
                end
            end)
        end
        return obj
    end

    function wnd:UpdateLearnChoice(kind)
        self.selectedKind = kind or "all"
        local all_selected = self.selectedKind == "all"
        local title = nil
        local body = nil
        local icon = nil

        if all_selected then
            title = ""
            body = "เรียนวิชาทั้งหมด\nที่มีอยู่ในสำนัก\nให้กับ NPC ที่เลือก\n\nระบบจะเรียนเฉพาะ\nวิชาที่รองรับ\nและข้ามวิชาที่เรียนไม่ได้\nโดยอัตโนมัติ"
            icon = "Sprs/xaou106.png"
        else
            title = ""
            body = "เรียนเฉพาะวิชา\nที่ NPC กำลังฝึกอยู่\nในปัจจุบัน\n\nเหมาะสำหรับปลดล็อก\nสายวิชาที่เกี่ยวข้อง\nและเรียนรู้คัมภีร์\nของวิชานั้นอย่างรวดเร็ว"
            icon = "Sprs/xaou107.png"
        end

        xlf_set_obj_text(self.btnLearnAll, all_selected and "▶ 📚 เรียนทุกวิชาในสำนัก" or "📚 เรียนทุกวิชาในสำนัก")
        xlf_set_obj_text(self.btnLearnCurrent, all_selected and "📖 เรียนวิชาปัจจุบัน" or "▶ 📖 เรียนวิชาปัจจุบัน")
        xlf_set_obj_text(self.detailTitle, title)
        xlf_set_obj_text(self.detailBody, body)
    end

    function wnd:StartLearnChoice()
        local npc = self.xaouNpc
        local kind = self.selectedKind or "all"
        self:Hide()
        if kind == "all" then
            xlf_run_learn_all_from_menu(npc)
        else
            xlf_run_current_gong_from_menu(npc)
        end
    end

    function wnd:OnInit()
        self.sx = 760
        self.sy = 500
        self:SetTitle("เลือกวิธีเรียนวิชา")
        self:SetSize(self.sx, self.sy)
        self.selectedKind = "all"

        self.header = self:AddLearnLabel("txtXaouLearnHeader", "Xaou Learn", 60, 42, 300, 34, 30)
        self.credit = self:AddLearnLabel("txtXaouLearnCredit", "ผู้สร้าง: xaou", 62, 78, 300, 28, 22)

        self.btnLearnAll = self:AddLearnButton("btnLearnAll", "📚 เรียนทุกวิชาในสำนัก", 58, 125, 335, 105, "Sprs/xaou106.png", 26)
        self.btnLearnCurrent = self:AddLearnButton("btnLearnCurrent", "📖 เรียนวิชาปัจจุบัน", 58, 250, 335, 105, "Sprs/xaou107.png", 26)

        self.detailTitle = self:AddLearnLabel("txtLearnDescTitle", "", 430, 145, 270, 1, 1)
        self.detailBody = self:AddLearnLabel("txtLearnDescBody", "", 442, 168, 250, 205, 22)

        self.btnStart = self:AddLearnButton("btnStartLearn", "เริ่มเรียน", 493, 395, 150, 44, "", 26)

        xlf_center_learn_window(self)
        self:UpdateLearnChoice("all")
    end

    function wnd:OnShown()
        pcall(function() self:SetTitle("เลือกวิธีเรียนวิชา") end)
        xlf_center_learn_window(self)
        self:UpdateLearnChoice(self.selectedKind or "all")
    end

    function wnd:OnHide()
        xlf_restore_main_window()
    end

    function wnd:OnObjectEvent(t, obj, context)
        if t == "onClick" and obj ~= nil then
            local name = tostring(obj.name or "")
            if name == "btnLearnAll" then
                self:UpdateLearnChoice("all")
                return true
            elseif name == "btnLearnCurrent" then
                self:UpdateLearnChoice("current")
                return true
            elseif name == "btnStartLearn" then
                self:StartLearnChoice()
                return true
            end
        end
        return false
    end

    return wnd
end

local function xlf_open_custom_learn_window(npc)
    local wnd = xlf_create_learn_window()
    if wnd == nil then return false end
    wnd.xaouNpc = npc
    wnd.selectedKind = "all"
    pcall(function() wnd:SetTitle("เลือกวิธีเรียนวิชา") end)
    wnd:Show()
    pcall(function() wnd:UpdateLearnChoice("all") end)
    pcall(function()
        if wnd.window ~= nil and wnd.window.BringToFront ~= nil then
            wnd.window:BringToFront()
        end
    end)
    return true
end

local function xlf_open_gong_select(npc)
    if xlf_open_custom_learn_window(npc) then
        return
    end

    xlf_restore_main_window()
    xlf_show("ไม่สามารถเปิดหน้าต่างเลือกวิธีเรียนได้", "Xaou Learn")
end

function Xaou_LearnFullGong_Start()
    xlf_hide_main_window()

    if CS == nil or CS.Wnd_SelectNpc == nil or CS.Wnd_SelectNpc.Instance == nil then
        xlf_show("ไม่สามารถเปิดหน้าเลือก NPC ได้", "Xaou Learn")
        xlf_restore_main_window()
        return
    end

    local wnd = CS.Wnd_SelectNpc.Instance
    local callback = function(result)
        local npc = xlf_decode_npc(result)
        if npc == nil then
            if xlf_debug_enabled() then
                xlf_show("Select NPC failed.\nResult=" .. xlf_str(result), "Xaou Learn")
            else
                xlf_show("เลือก NPC ไม่สำเร็จ", "Xaou Learn")
            end
            xlf_restore_main_window()
            return
        end
        xlf_open_gong_select(npc)
    end
    local condition = function(npc) return xlf_npc_can_work(npc) end
    local attempts = {
        function() return wnd:Select(callback, 0, 1, 1, nil, condition, "เลือก NPC ที่จะเรียนวิชา") end,
        function() return wnd:Select(callback, nil, 1, 1, nil, condition, "เลือก NPC ที่จะเรียนวิชา") end,
        function() return wnd:Select(callback) end,
    }
    for _, fn in ipairs(attempts) do
        local ok = pcall(fn)
        if ok then return end
    end
    xlf_show("เปิดหน้าเลือก NPC ไม่สำเร็จ", "Xaou Learn")
    xlf_restore_main_window()
end

function Xaou_LearnFullGong_InstallUIHook()
    if XaouItemWindow == nil or Xaou_LearnFullGong_UIHooked == true then return false end
    Xaou_LearnFullGong_UIHooked = true

    local oldGetRightModeList = XaouItemWindow.GetRightModeList
    if oldGetRightModeList ~= nil then
        function XaouItemWindow:GetRightModeList()
            local list = oldGetRightModeList(self) or {}
            local out = {}
            local inserted = false
            local function add_learn_button()
                if inserted then return end
                table.insert(out, {
                    mode = "learnfullgong",
                    text = "เรียนคัมภีร์",
                    icon = "Sprs/xaou106.png",
                })
                inserted = true
            end
            for _, mode in ipairs(list) do
                local mode_name = tostring((mode ~= nil and mode.mode) or "")
                table.insert(out, mode)
                if mode_name == "book" then
                    add_learn_button()
                elseif mode_name == "bulkeso" then
                    add_learn_button()
                end
            end
            if not inserted then
                add_learn_button()
            end
            return out
        end
    end

    local oldOnObjectEvent = XaouItemWindow.OnObjectEvent
    function XaouItemWindow:OnObjectEvent(t, obj, context)
        local obj_name = tostring((obj ~= nil and obj.name) or "")
        local mode_value = nil
        if self.modeButtonData ~= nil then mode_value = self.modeButtonData[obj_name] end
        if t == "onClick" and obj ~= nil and (obj_name == "btnModeLearnfullgong" or tostring(mode_value or "") == "learnfullgong") then
            Xaou_LearnFullGong_Start()
            return true
        end
        if oldOnObjectEvent ~= nil then return oldOnObjectEvent(self, t, obj, context) end
        return true
    end

    return true
end

-- Standalone Mod Center uses its own FGUI window. Do not install the legacy UI hook.
function Xaou_LearnAllGongsDirect(npc)
    return xlf_learn_all_gongs(npc)
end

function Xaou_LearnCurrentGongDirect(npc)
    local entry = xlf_current_gong_entry(npc)
    if entry == nil or entry.gong_id == nil then
        return {
            ok = false,
            reason = "ไม่พบวิชาปัจจุบันที่สามารถเรียนได้",
            gong_id = nil,
        }
    end
    return Xaou_LearnFullGong(npc, entry.gong_id)
end

print("[Xaou] Learn Full Gong Core loaded")
