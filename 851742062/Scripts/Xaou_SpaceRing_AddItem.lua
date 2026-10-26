-- ============================================================
-- Xaou SpaceRing Standalone
-- Uses the original game Map.SpaceRing / RemoteStorage only.
-- It never creates custom storage and never edits Storage directly.
-- ============================================================

local XaouSpaceRing = GameMain:NewMod("Xaou_SpaceRing_AddItem")

local function xs_str(value)
    if value == nil then return "nil" end
    return tostring(value)
end

local function xs_show(text, title)
    title = title or "Xaou SpaceRing"
    if Xaou_LocalizeText then
        text = Xaou_LocalizeText(text)
        title = Xaou_LocalizeText(title)
    end
    if world ~= nil and world.ShowMsgBox ~= nil then
        local ok = pcall(function() world:ShowMsgBox(tostring(text), title) end)
        if ok then return true end
    end
    local ok_helper, helper = pcall(function()
        if CS ~= nil and CS.WorldLuaHelper ~= nil then return CS.WorldLuaHelper() end
        return nil
    end)
    if ok_helper and helper ~= nil then
        local ok = pcall(function() helper:ShowMsgBox(tostring(text), title) end)
        if ok then return true end
    end
    pcall(function()
        if CS ~= nil and CS.Wnd_Message ~= nil then
            CS.Wnd_Message.Show(tostring(text), 1, nil, true, title, 0, 0, "")
        end
    end)
    pcall(function() print("[XaouSpaceRing] " .. tostring(text)) end)
    return false
end

local function xs_list_count(list)
    if list == nil then return 0 end
    local ok, value = pcall(function() return list.Count end)
    if ok and value ~= nil then return tonumber(value) or 0 end
    ok, value = pcall(function() return list:get_Count() end)
    if ok and value ~= nil then return tonumber(value) or 0 end
    return 0
end

local function xs_list_item(list, index)
    if list == nil then return nil end
    local ok, value = pcall(function() return list[index] end)
    if ok and value ~= nil then return value end
    ok, value = pcall(function() return list:get_Item(index) end)
    if ok and value ~= nil then return value end
    return nil
end

local function xs_get_map()
    if Map ~= nil then return Map end
    local ok, value = pcall(function()
        if World ~= nil and World.Map ~= nil then return World.Map end
        if World ~= nil and World.map ~= nil then return World.map end
        return nil
    end)
    if ok then return value end
    return nil
end

local function xs_get_thing_mgr()
    if ThingMgr ~= nil then return ThingMgr end
    local ok, mgr = pcall(function()
        if CS ~= nil and CS.XiaWorld ~= nil and CS.XiaWorld.ThingMgr ~= nil then
            return CS.XiaWorld.ThingMgr.Instance
        end
        return nil
    end)
    if ok then return mgr end
    return nil
end

local function xs_get_space_ring(map)
    if map == nil then return nil end
    local ok, value = pcall(function() return map.SpaceRing end)
    if ok then return value end
    return nil
end

local function xs_get_remote_item_type()
    local ok, value = pcall(function()
        if ThingMgr ~= nil and ThingMgr.RemoteItemType ~= nil then return ThingMgr.RemoteItemType end
        if CS ~= nil and CS.XiaWorld ~= nil and CS.XiaWorld.ThingMgr ~= nil then
            return CS.XiaWorld.ThingMgr.RemoteItemType
        end
        return nil
    end)
    if ok then return value end
    return nil
end

local function xs_remote_allowed(item_name)
    item_name = tostring(item_name or "")
    if item_name == "" then return false, "itemName empty" end

    local remote = xs_get_remote_item_type()
    if remote == nil then return false, "ThingMgr.RemoteItemType=nil" end

    local ok, value = pcall(function()
        if remote.ContainsKey ~= nil then return remote:ContainsKey(item_name) end
        return nil
    end)
    if ok and value == true then return true, "ContainsKey" end

    ok, value = pcall(function() return remote[item_name] end)
    if ok and value ~= nil then return true, "index" end

    ok, value = pcall(function()
        if remote.TryGetValue ~= nil then return remote:TryGetValue(item_name) end
        return nil
    end)
    if ok and value == true then return true, "TryGetValue" end

    return false, "not in RemoteItemType"
end

local function xs_starts_with(text, prefix)
    text = tostring(text or "")
    prefix = tostring(prefix or "")
    return string.sub(text, 1, string.len(prefix)) == prefix
end

local function xs_infer_remote_type(item, item_name)
    item_name = tostring(item_name or "")
    if xs_starts_with(item_name, "Item_Dan_") then return "โอสถ" end
    if xs_starts_with(item_name, "Item_Fabao_") then return "สมบัติ" end
    if xs_starts_with(item_name, "Item_Equip_") then return "อุปกรณ์" end
    if xs_starts_with(item_name, "Item_Plant_") then return "วัตถุดิบ" end
    if xs_starts_with(item_name, "Item_Material_") then return "วัตถุดิบ" end

    local remote_type = nil
    pcall(function()
        if item ~= nil and item.def ~= nil and item.def.ItemType ~= nil then
            remote_type = tostring(item.def.ItemType)
        end
    end)
    if remote_type ~= nil and remote_type ~= "" then return remote_type end
    return "อื่นๆ"
end

local function xs_register_remote_item(item_name, remote_type)
    item_name = tostring(item_name or "")
    if item_name == "" then return false, "itemName empty" end

    local remote = xs_get_remote_item_type()
    if remote == nil then return false, "ThingMgr.RemoteItemType=nil" end

    local allowed = xs_remote_allowed(item_name)
    if allowed == true then return true, "already registered" end

    remote_type = tostring(remote_type or "อื่นๆ")

    local ok, err = pcall(function() remote[item_name] = remote_type end)
    if ok then return true, "index=" .. remote_type end

    ok, err = pcall(function()
        if remote.set_Item ~= nil then
            remote:set_Item(item_name, remote_type)
        else
            error("set_Item=nil")
        end
    end)
    if ok then return true, "set_Item=" .. remote_type end

    ok, err = pcall(function()
        if remote.Add ~= nil then
            remote:Add(item_name, remote_type)
        else
            error("Add=nil")
        end
    end)
    if ok then return true, "Add=" .. remote_type end

    return false, tostring(err)
end



-- ============================================================
-- Xaou Restore Registry
-- SpaceRing.Storage ถูกเซฟ แต่ ThingMgr.RemoteItemType เป็น runtime catalog
-- หลังปิดเกม catalog จะถูกสร้างใหม่จาก RSThingType ของเกมเท่านั้น
-- ฟังก์ชันนี้จึงลงทะเบียนของที่มีอยู่จริงในคลังกลับเข้าหมวด "อื่นๆ"
-- โดยไม่เพิ่ม/ลดจำนวนของ และไม่แตะ StorageItem
-- ============================================================
local function xs_restore_remote_item_registry()
    local map = xs_get_map()
    local ring = xs_get_space_ring(map)
    local remote = xs_get_remote_item_type()
    if ring == nil then return 0, 0, "SpaceRing not ready" end
    if remote == nil then return 0, 0, "RemoteItemType not ready" end

    local restored = 0
    local failed = 0
    local visited = 0
    local routes = {}

    local function restore_one(item_name, count)
        item_name = tostring(item_name or "")
        count = tonumber(count) or 0
        if item_name == "" or count <= 0 then return end
        visited = visited + 1

        local allowed = xs_remote_allowed(item_name)
        if allowed == true then return end

        local ok = xs_register_remote_item(item_name, "อื่นๆ")
        if ok == true then
            restored = restored + 1
        else
            failed = failed + 1
        end
    end

    -- Android XLua บางรุ่นไม่แปลง Lua function เป็น Action<string,int>
    -- จึงอ่าน private Dictionary Storage ด้วย System.Reflection ก่อน
    local reflection_ok = false
    local reflection_err = nil
    local ok_reflect, err_reflect = pcall(function()
        local ring_type = ring:GetType()
        if ring_type == nil then error("ring:GetType()=nil") end

        local flags = nil
        pcall(function()
            flags = CS.System.Reflection.BindingFlags.Instance |
                    CS.System.Reflection.BindingFlags.NonPublic |
                    CS.System.Reflection.BindingFlags.Public
        end)
        -- ค่า enum สำรอง: Instance(4) + Public(16) + NonPublic(32)
        if flags == nil then flags = 52 end

        local field = ring_type:GetField("Storage", flags)
        if field == nil then error("RemoteStorage.Storage field not found") end

        local storage = field:GetValue(ring)
        if storage == nil then error("RemoteStorage.Storage=nil") end

        local enumerator = storage:GetEnumerator()
        if enumerator == nil then error("Storage.GetEnumerator()=nil") end

        while enumerator:MoveNext() do
            local pair = enumerator.Current
            local key = nil
            local value = nil
            pcall(function() key = pair.Key end)
            pcall(function() value = pair.Value end)
            if key == nil then pcall(function() key = pair:get_Key() end) end
            if value == nil then pcall(function() value = pair:get_Value() end) end
            restore_one(key, value)
        end
        reflection_ok = true
        routes[#routes + 1] = "Reflection"
    end)
    if not ok_reflect then reflection_err = tostring(err_reflect) end

    if reflection_ok then
        return restored, failed,
            "Xaou Reflection | visited=" .. tostring(visited)
    end

    -- เส้นทางสำรองจาก API ของเกม หาก XLua รองรับ delegate อัตโนมัติ
    local foreach_ok = false
    local foreach_err = nil
    local ok_foreach, err_foreach = pcall(function()
        if ring.ForeachItemInStorage == nil then
            error("ForeachItemInStorage=nil")
        end
        ring:ForeachItemInStorage(function(item_name, count)
            restore_one(item_name, count)
        end)
        foreach_ok = true
        routes[#routes + 1] = "Foreach"
    end)
    if not ok_foreach then foreach_err = tostring(err_foreach) end

    if foreach_ok then
        return restored, failed,
            "Xaou Foreach | visited=" .. tostring(visited)
    end

    return restored, failed,
        "Restore failed | Reflection=" .. tostring(reflection_err) ..
        " | Foreach=" .. tostring(foreach_err)
end

local function xs_item_name(item)
    if item == nil then return "" end
    local name = ""
    pcall(function()
        if item.def ~= nil and item.def.Name ~= nil then name = tostring(item.def.Name) end
    end)
    if name ~= "" then return name end
    pcall(function()
        if item.Def ~= nil and item.Def.Name ~= nil then name = tostring(item.Def.Name) end
    end)
    if name ~= "" then return name end
    pcall(function()
        if item.Name ~= nil then name = tostring(item.Name) end
    end)
    return name
end

local function xs_item_title(item, item_name)
    if item ~= nil then
        local ok, value = pcall(function() return item:GetName() end)
        if ok and value ~= nil and tostring(value) ~= "" then return tostring(value) end
        ok, value = pcall(function()
            if item.def ~= nil then return item.def.ThingName end
            return nil
        end)
        if ok and value ~= nil and tostring(value) ~= "" then return tostring(value) end
    end
    return tostring(item_name or "item")
end

local function xs_item_title_by_id(item_name)
    item_name = tostring(item_name or "")
    if item_name == "" then return "item" end
    local def = nil
    pcall(function()
        if ThingMgr ~= nil and g_emThingType ~= nil then
            def = ThingMgr:GetDef(g_emThingType.Item, item_name)
        end
    end)
    if def == nil then
        pcall(function()
            if ThingMgr ~= nil and CS ~= nil and CS.XiaWorld ~= nil then
                def = ThingMgr:GetDef(CS.XiaWorld.g_emThingType.Item, item_name)
            end
        end)
    end
    if def ~= nil then
        local title = nil
        pcall(function() title = def.ThingName end)
        if title ~= nil and tostring(title) ~= "" then return tostring(title) end
    end
    return item_name
end

local function xs_item_count(item)
    if item == nil then return 0 end
    local ok, value = pcall(function() return item.FreeCount end)
    if ok and tonumber(value) ~= nil and tonumber(value) > 0 then return tonumber(value) end
    ok, value = pcall(function() return item.Count end)
    if ok and tonumber(value) ~= nil and tonumber(value) > 0 then return tonumber(value) end
    return 1
end

local function xs_is_space_ring_open(map)
    if map == nil then return false, "Map=nil" end
    local ok, value = pcall(function() return map:IsSpaceRingOpen() end)
    if ok then return value == true, "IsSpaceRingOpen=" .. tostring(value) end
    return false, "IsSpaceRingOpen error: " .. tostring(value)
end

local function xs_count_in_ring(map, ring, item_name)
    local ok, value = pcall(function()
        if ring ~= nil and ring.GetItemCount ~= nil then
            return ring:GetItemCount(item_name)
        end
        return nil
    end)
    if ok and value ~= nil then return tonumber(value) or 0 end

    ok, value = pcall(function()
        if map ~= nil and map.GetSpaceRingItemCount ~= nil then
            return map:GetSpaceRingItemCount(item_name)
        end
        return nil
    end)
    if ok and value ~= nil then return tonumber(value) or 0 end
    return 0
end

local function xs_get_remote_type_value(remote, key)
    local value = nil
    pcall(function() value = remote[key] end)
    if value ~= nil then return value end
    pcall(function()
        if remote.get_Item ~= nil then value = remote:get_Item(key) end
    end)
    if value ~= nil then return value end
    pcall(function()
        if remote.TryGetValue ~= nil then
            local ok, v = remote:TryGetValue(key)
            if ok == true then value = v end
        end
    end)
    return value
end

local function xs_get_remote_keys(remote)
    local keys = {}
    if remote == nil then return keys end

    local ok = pcall(function()
        for k, _ in pairs(remote) do
            keys[#keys + 1] = tostring(k)
        end
    end)
    if ok and #keys > 0 then return keys end

    local key_list = nil
    pcall(function() key_list = remote.Keys end)
    if key_list == nil then
        pcall(function()
            if remote.get_Keys ~= nil then key_list = remote:get_Keys() end
        end)
    end
    local count = xs_list_count(key_list)
    for i = 0, count - 1 do
        local key = xs_list_item(key_list, i)
        if key ~= nil then keys[#keys + 1] = tostring(key) end
    end
    return keys
end

local function xs_space_ring_items_snapshot()
    local map = xs_get_map()
    local ring = xs_get_space_ring(map)
    local remote = xs_get_remote_item_type()
    local rows = {}
    local seen = {}

    local function add_key(key)
        key = tostring(key or "")
        if key == "" or seen[key] == true then return end
        seen[key] = true
        local count = xs_count_in_ring(map, ring, key)
        if count > 0 then
            rows[#rows + 1] = {
                id = key,
                count = count,
                title = xs_item_title_by_id(key),
                category = xs_get_remote_type_value(remote, key)
            }
        end
    end

    local remote_keys = xs_get_remote_keys(remote)
    for i = 1, #remote_keys do add_key(remote_keys[i]) end

    return rows
end

local xs_read_select_index

local function xs_category_name(value)
    value = tostring(value or "")
    if value == "" or value == "nil" then return "อื่นๆ" end
    return value
end

local function xs_sort_rows(rows)
    table.sort(rows, function(a, b)
        local ca = xs_category_name(a.category)
        local cb = xs_category_name(b.category)
        if ca ~= cb then return ca < cb end
        return tostring(a.title or a.id) < tostring(b.title or b.id)
    end)
end

local function xs_build_categories(rows)
    local map = {}
    local cats = {}
    for i = 1, #rows do
        local cat = xs_category_name(rows[i].category)
        if map[cat] == nil then
            map[cat] = { name = cat, item_count = 0, total_count = 0 }
            cats[#cats + 1] = map[cat]
        end
        map[cat].item_count = map[cat].item_count + 1
        map[cat].total_count = map[cat].total_count + (tonumber(rows[i].count) or 0)
    end
    table.sort(cats, function(a, b)
        if a.name == "อื่นๆ" and b.name ~= "อื่นๆ" then return false end
        if b.name == "อื่นๆ" and a.name ~= "อื่นๆ" then return true end
        return a.name < b.name
    end)
    return cats
end

local function xs_filter_rows_by_category(rows, category)
    local filtered = {}
    category = xs_category_name(category)
    for i = 1, #rows do
        if xs_category_name(rows[i].category) == category then
            filtered[#filtered + 1] = rows[i]
        end
    end
    return filtered
end

local function xs_open_category_menu(mod, helper, rows)
    xs_sort_rows(rows)
    local cats = xs_build_categories(rows)
    if #cats <= 0 then
        xs_show("คลังจักรวาลยังไม่มีของ", "Xaou SpaceRing")
        return false
    end

    local choices = {}
    local actions = {}

    choices[#choices + 1] = "ทั้งหมด\n" .. tostring(#rows) .. " รายการ"
    actions[#actions + 1] = { kind = "category", name = "__ALL__" }

    for i = 1, #cats do
        local c = cats[i]
        choices[#choices + 1] = tostring(c.name) .. "\n" .. tostring(c.item_count) .. " รายการ / รวม " .. tostring(c.total_count)
        actions[#actions + 1] = { kind = "category", name = c.name }
    end

    helper:ShowSelectBox("คลังจักรวาล: เลือกหมวดหมู่", choices, 1, 1, function(result)
        local index = xs_read_select_index(result)
        if index == nil then return end
        if index == 0 then index = 1 end
        local action = actions[index]
        if action == nil then action = actions[index + 1] end
        if action == nil then return end

        local list = rows
        local title = "ทั้งหมด"
        if action.name ~= "__ALL__" then
            list = xs_filter_rows_by_category(rows, action.name)
            title = action.name
        end
        mod:OpenVirtualWithdrawItemPage(helper, rows, list, title, 1)
    end)
    return true
end

xs_read_select_index = function(result)
    if result == nil then return nil end
    local n = tonumber(result)
    if n ~= nil then return n end

    local ok, count = pcall(function() return result.Count end)
    if ok and tonumber(count) ~= nil and tonumber(count) > 0 then
        local value = nil
        pcall(function() value = result[0] end)
        if value == nil then pcall(function() value = result:get_Item(0) end) end
        n = tonumber(value)
        if n ~= nil then return n end
    end
    return nil
end

local function xs_get_helper()
    local helper = nil
    pcall(function()
        if CS ~= nil and CS.WorldLuaHelper ~= nil then helper = CS.WorldLuaHelper() end
    end)
    return helper
end

local function xs_get_drop_key()
    local key = nil
    pcall(function()
        if Map ~= nil and Map.GetRandomInLifeArea ~= nil then key = Map:GetRandomInLifeArea(4) end
    end)
    if key ~= nil then return key end
    pcall(function()
        if Map ~= nil and Map.GetRandomEmptyKey ~= nil then key = Map:GetRandomEmptyKey() end
    end)
    return key
end

local function xs_drop_item_to_map(item_name, count)
    item_name = tostring(item_name or "")
    count = tonumber(count) or 1
    if item_name == "" or count <= 0 then return false, "invalid item/count" end
    if ItemRandomMachine == nil or Map == nil then return false, "ItemRandomMachine/Map nil" end

    local drop_key = xs_get_drop_key()
    if drop_key == nil then return false, "drop key nil" end

    local ok, err = pcall(function()
        local remain = count
        while remain > 0 do
            local one_count = remain
            if one_count > 9999 then one_count = 9999 end
            local thing = ItemRandomMachine.RandomItem(item_name, nil, 1, 12, 1, one_count)
            Map:DropItem(thing, drop_key, true, true, false, true, 0, false)
            remain = remain - one_count
        end
    end)
    if ok then return true, "DropItem" end
    return false, tostring(err)
end

local function xs_set_ring_count_direct(ring, item_name, new_count)
    if ring == nil then return false, "ring=nil" end
    item_name = tostring(item_name or "")
    new_count = tonumber(new_count) or 0

    local storage = nil
    pcall(function() storage = ring.Storage end)
    if storage == nil then pcall(function() storage = ring.m_Storage end) end
    if storage == nil then pcall(function() storage = ring.storage end) end
    if storage == nil then return false, "Storage field nil" end

    if new_count <= 0 then
        local ok = pcall(function()
            if storage.Remove ~= nil then storage:Remove(item_name) else error("Remove=nil") end
        end)
        if ok then return true, "Storage.Remove" end
    end

    local ok, err = pcall(function() storage[item_name] = new_count end)
    if ok then return true, "Storage[index]" end

    ok, err = pcall(function()
        if storage.set_Item ~= nil then storage:set_Item(item_name, new_count) else error("set_Item=nil") end
    end)
    if ok then return true, "Storage.set_Item" end
    return false, tostring(err)
end

local function xs_sub_from_space_ring(item_name, count)
    local map = xs_get_map()
    local ring = xs_get_space_ring(map)
    if ring == nil then return false, "SpaceRing=nil" end

    item_name = tostring(item_name or "")
    count = tonumber(count) or 1
    local before = xs_count_in_ring(map, ring, item_name)
    if before < count then return false, "not enough count" end

    local method_names = {
        "SubStorage", "RemoveStorage", "DelStorage", "TakeStorage",
        "SubItem", "RemoveItem", "DelItem", "TakeItem"
    }
    for i = 1, #method_names do
        local name = method_names[i]
        local ok = pcall(function()
            local fn = ring[name]
            if fn == nil then error(name .. "=nil") end
            fn(ring, item_name, count, false)
        end)
        local after = xs_count_in_ring(map, ring, item_name)
        if ok and after <= before - count then return true, name end
    end

    local ok = pcall(function() ring:AddStorage(item_name, -count, false) end)
    local after = xs_count_in_ring(map, ring, item_name)
    if ok and after <= before - count then return true, "AddStorage(-count)" end

    return xs_set_ring_count_direct(ring, item_name, before - count)
end

local function xs_find_sleeve_building()
    local mgr = xs_get_thing_mgr()
    if mgr == nil then return nil end

    local list = nil
    pcall(function()
        if g_emThingType ~= nil then list = mgr:GetThingList(g_emThingType.Building) end
    end)
    if list == nil then
        pcall(function()
            if CS ~= nil and CS.XiaWorld ~= nil then
                list = mgr:GetThingList(CS.XiaWorld.g_emThingType.Building)
            end
        end)
    end
    if list == nil then return nil end

    local count = xs_list_count(list)
    for i = 0, count - 1 do
        local thing = xs_list_item(list, i)
        local ok_sleeve = false
        pcall(function()
            if thing ~= nil and thing.IsSleeveSpace ~= nil and thing:IsSleeveSpace() == true then
                ok_sleeve = true
            end
        end)
        pcall(function()
            if thing ~= nil and thing.def ~= nil and tostring(thing.def.Name or "") == "Building_SleeveSpace" then
                ok_sleeve = true
            end
        end)
        if ok_sleeve then return thing end
    end
    return nil
end

local function xs_is_sleeve_building(thing)
    if thing == nil then return false end
    local ok_sleeve = false
    pcall(function()
        if thing.IsSleeveSpace ~= nil and thing:IsSleeveSpace() == true then
            ok_sleeve = true
        end
    end)
    pcall(function()
        if thing.def ~= nil and tostring(thing.def.Name or "") == "Building_SleeveSpace" then
            ok_sleeve = true
        end
    end)
    return ok_sleeve == true
end

local function xs_get_item_list()
    local mgr = xs_get_thing_mgr()
    if mgr == nil then return nil end

    local list = nil
    pcall(function()
        if g_emThingType ~= nil then list = mgr:GetThingList(g_emThingType.Item) end
    end)
    if list == nil then
        pcall(function()
            if CS ~= nil and CS.XiaWorld ~= nil then
                list = mgr:GetThingList(CS.XiaWorld.g_emThingType.Item)
            end
        end)
    end
    return list
end

local function xs_collect_map_items_snapshot()
    local list = xs_get_item_list()
    local items = {}
    local count = xs_list_count(list)
    for i = 0, count - 1 do
        local item = xs_list_item(list, i)
        if item ~= nil then
            items[#items + 1] = item
        end
    end
    return items
end

local function xs_get_remote_storage_wnd()
    local wnd = nil
    pcall(function()
        if CS ~= nil and CS.Wnd_RemoteStorage ~= nil and CS.Wnd_RemoteStorage.Instance ~= nil then
            wnd = CS.Wnd_RemoteStorage.Instance
        end
    end)
    if wnd ~= nil then return wnd end
    pcall(function()
        if Wnd_RemoteStorage ~= nil and Wnd_RemoteStorage.Instance ~= nil then
            wnd = Wnd_RemoteStorage.Instance
        end
    end)
    return wnd
end

local function xs_probe(map, ring, item_name)
    local lines = {}
    lines[#lines + 1] = "คลังจักรวาลยังไม่พร้อม"
    lines[#lines + 1] = "Map=" .. xs_str(map)
    lines[#lines + 1] = "Map.SpaceRing=" .. xs_str(ring)
    local open, open_info = xs_is_space_ring_open(map)
    lines[#lines + 1] = tostring(open_info)
    local working_count = nil
    pcall(function()
        if ring ~= nil and ring.WorkingBuild ~= nil then
            working_count = xs_list_count(ring.WorkingBuild)
        end
    end)
    lines[#lines + 1] = "WorkingBuild.Count=" .. xs_str(working_count)
    lines[#lines + 1] = "Building_SleeveSpace=" .. xs_str(xs_find_sleeve_building())
    if item_name ~= nil then
        local allowed, reason = xs_remote_allowed(item_name)
        lines[#lines + 1] = "RemoteItemType=" .. tostring(allowed) .. " | " .. tostring(reason)
    end
    lines[#lines + 1] = "ยังไม่เพิ่มของ เพื่อป้องกันเซฟเกม"
    return table.concat(lines, "\n")
end

function XaouSpaceRing:AddItemNameToSpaceRing(item_name, count, allow_closed, source_item, quiet)
    item_name = tostring(item_name or "")
    count = tonumber(count) or 1
    if count <= 0 then count = 1 end

    local map = xs_get_map()
    local ring = xs_get_space_ring(map)
    if map == nil or ring == nil then
        if quiet ~= true then xs_show(xs_probe(map, ring, item_name), "Xaou SpaceRing") end
        return false
    end

    local allowed, allowed_reason = xs_remote_allowed(item_name)
    if allowed ~= true then
        local register_type = xs_infer_remote_type(source_item, item_name)
        local registered, register_reason = xs_register_remote_item(item_name, register_type)
        if registered ~= true then
            if quiet ~= true then
                xs_show("เพิ่มไอเทมเข้ารายการคลังจักรวาลไม่สำเร็จ\nID: " .. item_name .. "\nType: " .. tostring(register_type) .. "\n" .. tostring(allowed_reason) .. "\n" .. tostring(register_reason), "Xaou SpaceRing")
            end
            return false
        end
        allowed, allowed_reason = xs_remote_allowed(item_name)
        if allowed ~= true then
            if quiet ~= true then
                xs_show("เพิ่มรายการแล้ว แต่เกมยังไม่ยอมรับไอเทมนี้\nID: " .. item_name .. "\nType: " .. tostring(register_type) .. "\n" .. tostring(allowed_reason) .. "\n" .. tostring(register_reason), "Xaou SpaceRing")
            end
            return false
        end
    end

    local open, open_info = xs_is_space_ring_open(map)
    if open ~= true and allow_closed ~= true then
        if quiet ~= true then xs_show(xs_probe(map, ring, item_name), "Xaou SpaceRing") end
        return false
    end

    local before = xs_count_in_ring(map, ring, item_name)
    local ok, ret = pcall(function() return map:AddToSpaceRing(item_name, count) end)
    local route = "Map:AddToSpaceRing"
    local err = ret

    if not (ok and ret == true) then
        ok, ret = pcall(function()
            ring:AddStorage(item_name, count, false)
            return true
        end)
        if open == true then
            route = "Map.SpaceRing:AddStorage"
        else
            route = "Map.SpaceRing:AddStorage(closed)"
        end
        err = ret
    end

    local after = xs_count_in_ring(map, ring, item_name)
    if ok and after >= before + count then
        return true, after, route
    end
    return false, after, tostring(err) .. " | " .. tostring(open_info)
end

local function xs_remove_source_item(item, count)
    if item == nil then return false end

    local total = nil
    pcall(function() total = tonumber(item.Count) end)
    if total ~= nil and total > count then
        local ok = pcall(function() item:SubCount(count) end)
        if ok then return true end
    end

    local ok = pcall(function() item:ChangeCount(0, false) end)
    if ok then return true end

    ok = pcall(function() item:ChangeCount(0) end)
    if ok then return true end

    ok = pcall(function()
        local mgr = xs_get_thing_mgr()
        if mgr ~= nil then mgr:RemoveThing(item, false, false) end
    end)
    return ok == true
end

function XaouSpaceRing:StoreSelectedItem(item)
    if item == nil then
        xs_show("ไม่พบไอเทมที่เลือก", "Xaou SpaceRing")
        return false
    end

    local item_name = xs_item_name(item)
    local title = xs_item_title(item, item_name)
    local count = xs_item_count(item)

    if item_name == "" then
        xs_show("อ่าน ID ไอเทมไม่ได้", "Xaou SpaceRing")
        return false
    end

    local ok, after, route = self:AddItemNameToSpaceRing(item_name, count, true, item)
    if ok ~= true then
        return false
    end

    local removed = xs_remove_source_item(item, count)
    xs_show("เก็บเข้าคลังจักรวาลสำเร็จ\n" .. title .. "\nจำนวน: " .. tostring(count) .. "\nในคลัง: " .. tostring(after) .. "\nวิธีเพิ่ม: " .. tostring(route) .. "\nลบของบนพื้น: " .. tostring(removed), "Xaou SpaceRing")
    return true
end

function XaouSpaceRing:StoreAllMapItems()
    local items = xs_collect_map_items_snapshot()
    if #items <= 0 then
        xs_show("ไม่พบไอเทมบนแผนที่", "Xaou SpaceRing")
        return false
    end

    local found = 0
    local stored = 0
    local removed = 0
    local failed = 0
    local skipped = 0

    for i = 1, #items do
        local item = items[i]
        local item_name = xs_item_name(item)
        local count = xs_item_count(item)
        if item_name == "" or count <= 0 then
            skipped = skipped + 1
        else
            found = found + 1
            local ok = self:AddItemNameToSpaceRing(item_name, count, true, item, true)
            if ok == true then
                stored = stored + 1
                if xs_remove_source_item(item, count) == true then
                    removed = removed + 1
                end
            else
                failed = failed + 1
            end
        end
    end

    xs_show(
        "เก็บของทั้งแผนที่เสร็จแล้ว\n" ..
        "พบไอเทม: " .. tostring(found) .. "\n" ..
        "เข้าคลังสำเร็จ: " .. tostring(stored) .. "\n" ..
        "ลบของบนพื้น: " .. tostring(removed) .. "\n" ..
        "ข้าม: " .. tostring(skipped) .. "\n" ..
        "ไม่สำเร็จ: " .. tostring(failed),
        "Xaou SpaceRing"
    )
    return stored > 0
end

function XaouSpaceRing:WithdrawFromVirtualStorage(item_name, count)
    item_name = tostring(item_name or "")
    count = tonumber(count) or 1
    if item_name == "" or count <= 0 then return false end

    local current = xs_count_in_ring(xs_get_map(), xs_get_space_ring(xs_get_map()), item_name)
    if current <= 0 then
        xs_show("ไม่มีของรายการนี้ในคลัง", "Xaou SpaceRing")
        return false
    end
    if count > current then count = current end

    local sub_ok, sub_reason = xs_sub_from_space_ring(item_name, count)
    if sub_ok ~= true then
        xs_show(
            "ลดจำนวนในคลังไม่สำเร็จ\n" ..
            xs_item_title_by_id(item_name) .. "\n" ..
            "จำนวน: " .. tostring(count) .. "\n" ..
            tostring(sub_reason),
            "Xaou SpaceRing"
        )
        return false
    end

    local drop_ok, drop_reason = xs_drop_item_to_map(item_name, count)
    if drop_ok ~= true then
        self:AddItemNameToSpaceRing(item_name, count, true, nil, true)
        xs_show("วางของลงพื้นไม่สำเร็จ จึงเติมของกลับเข้าคลังแล้ว\n" .. xs_item_title_by_id(item_name) .. "\n" .. tostring(drop_reason), "Xaou SpaceRing")
        return false
    end

    xs_show(
        "เบิกของจากคลังสำเร็จ\n" ..
        xs_item_title_by_id(item_name) .. "\n" ..
        "จำนวน: " .. tostring(count) .. "\n" ..
        "วิธีลดคลัง: " .. tostring(sub_reason),
        "Xaou SpaceRing"
    )
    return true
end

function XaouSpaceRing:OpenVirtualWithdrawItemPage(helper, all_rows, rows, title, page)
    rows = rows or {}
    page = tonumber(page) or 1
    local page_size = 12
    local max_page = math.floor((#rows + page_size - 1) / page_size)
    if max_page < 1 then max_page = 1 end
    if page < 1 then page = 1 end
    if page > max_page then page = max_page end

    local start_index = (page - 1) * page_size + 1
    local end_index = start_index + page_size - 1
    if end_index > #rows then end_index = #rows end

    local choices = {}
    local actions = {}

    for i = start_index, end_index do
        local row = rows[i]
        choices[#choices + 1] = tostring(row.title) .. "\nx" .. tostring(row.count)
        actions[#actions + 1] = { kind = "item", row = row }
    end

    if page > 1 then
        choices[#choices + 1] = "◀ ย้อนหน้า"
        actions[#actions + 1] = { kind = "page", page = page - 1 }
    end
    if page < max_page then
        choices[#choices + 1] = "ถัดไป ▶"
        actions[#actions + 1] = { kind = "page", page = page + 1 }
    end
    choices[#choices + 1] = "กลับหมวดหมู่"
    actions[#actions + 1] = { kind = "back" }

    local header = "คลังจักรวาล: " .. tostring(title or "ทั้งหมด") ..
        "\nหน้า " .. tostring(page) .. "/" .. tostring(max_page) ..
        " | " .. tostring(#rows) .. " รายการ"

    helper:ShowSelectBox(header, choices, 1, 1, function(result)
        local index = xs_read_select_index(result)
        if index == nil then return end
        if index == 0 then index = 1 end
        local action = actions[index]
        if action == nil then action = actions[index + 1] end
        if action == nil then return end

        if action.kind == "back" then
            xs_open_category_menu(self, helper, all_rows)
            return
        end
        if action.kind == "page" then
            self:OpenVirtualWithdrawItemPage(helper, all_rows, rows, title, action.page)
            return
        end
        if action.kind ~= "item" or action.row == nil then return end

        local row = action.row
        local amount_choices = {
            "x1\nเบิก 1 ชิ้น",
            "x10\nเบิก 10 ชิ้น",
            "x100\nเบิก 100 ชิ้น",
            "ทั้งหมด\nเบิกทั้งหมด"
        }
        helper:ShowSelectBox("เลือกจำนวน\n" .. tostring(row.title) .. "\nมีในคลัง: " .. tostring(row.count), amount_choices, 1, 1, function(amount_result)
            local amount_index = xs_read_select_index(amount_result)
            if amount_index == nil then return end
            if amount_index == 0 then amount_index = 1 end

            local amount = 1
            if amount_index == 2 then amount = 10 end
            if amount_index == 3 then amount = 100 end
            if amount_index == 4 then amount = row.count end
            if amount > row.count then amount = row.count end
            self:WithdrawFromVirtualStorage(row.id, amount)
        end)
    end)
end

function XaouSpaceRing:OpenVirtualWithdrawMenu()
    local rows = xs_space_ring_items_snapshot()
    if #rows <= 0 then
        xs_show("คลังจักรวาลยังไม่มีของ", "Xaou SpaceRing")
        return false
    end

    local helper = xs_get_helper()
    if helper == nil or helper.ShowSelectBox == nil then
        local lines = { "ไม่พบ ShowSelectBox\nรายการในคลัง:" }
        for i = 1, #rows do
            lines[#lines + 1] = tostring(i) .. ". " .. rows[i].title .. " x" .. tostring(rows[i].count)
            if i >= 20 then break end
        end
        xs_show(table.concat(lines, "\n"), "Xaou SpaceRing")
        return false
    end

    xs_open_category_menu(self, helper, rows)
    return true
end

function XaouSpaceRing:GetStorageRows()
    return xs_space_ring_items_snapshot()
end

function XaouSpaceRing:OpenStorageUI(source_thing)
    pcall(xs_restore_remote_item_registry)
    return self:OpenOriginalStorageUI(source_thing)
end

function XaouSpaceRing:OpenOriginalStorageUI(source_thing)
    pcall(xs_restore_remote_item_registry)

    -- Xaou mode: ถ้ามีอาคารให้ใช้จุดถอนของเดิมของเกม
    -- ถ้าไม่มีอาคาร ให้ใช้ตัวละคร/Thing ที่กดปุ่มเป็นจุดวางของแทน
    local from_thing = xs_find_sleeve_building()
    if from_thing == nil then
        from_thing = source_thing
    end
    if from_thing == nil then
        xs_show("ไม่มีอาคารจักรวาลย่อส่วน และไม่พบจุดรับของ\nลองเลือกตัวละครแล้วกด เปิดคลังจักรวาล", "Xaou SpaceRing")
        return false
    end

    local wnd = xs_get_remote_storage_wnd()
    if wnd == nil then
        xs_show("ไม่พบหน้าต่าง Wnd_RemoteStorage", "Xaou SpaceRing")
        return false
    end

    local ok, err = pcall(function() wnd:ShowStorage(from_thing) end)
    if ok then return true end
    xs_show("เปิดคลังเดิมของเกมไม่ได้\n" .. tostring(err), "Xaou SpaceRing")
    return false
end

function Xaou_SpaceRing_StoreSelectedItem(bind)
    local mod = nil
    pcall(function() mod = GameMain:GetMod("Xaou_SpaceRing_AddItem") end)
    if mod == nil or mod.StoreSelectedItem == nil then
        xs_show("กดปุ่มแล้ว แต่หา mod Xaou_SpaceRing_AddItem ไม่เจอ", "Xaou SpaceRing")
        return false
    end
    if bind == nil then
        xs_show("กดปุ่มแล้ว แต่ bind เป็น nil\nให้ลองเลือกไอเทมบนพื้นอีกครั้ง", "Xaou SpaceRing")
        return false
    end
    return mod:StoreSelectedItem(bind)
end

function Xaou_SpaceRing_OpenStorageUI(bind)
    local mod = nil
    pcall(function() mod = GameMain:GetMod("Xaou_SpaceRing_AddItem") end)
    if mod == nil or mod.OpenStorageUI == nil then
        xs_show("กดปุ่มแล้ว แต่หา mod Xaou_SpaceRing_AddItem ไม่เจอ", "Xaou SpaceRing")
        return false
    end
    return mod:OpenStorageUI(bind)
end

function Xaou_SpaceRing_OpenOriginalStorageUI(bind)
    local mod = nil
    pcall(function() mod = GameMain:GetMod("Xaou_SpaceRing_AddItem") end)
    if mod == nil or mod.OpenOriginalStorageUI == nil then
        xs_show("กดปุ่มแล้ว แต่หา mod Xaou_SpaceRing_AddItem ไม่เจอ", "Xaou SpaceRing")
        return false
    end
    return mod:OpenOriginalStorageUI(bind)
end

function XaouSpaceRing:AddBtn2Item(item)
    if item == nil then return end
    local thing_type_ok = false
    pcall(function()
        thing_type_ok = (item.ThingType == g_emThingType.Item)
    end)
    if thing_type_ok ~= true then return end

    pcall(function() item:RemoveBtnData("เก็บเข้าคลังจักรวาล") end)
    pcall(function() item:RemoveBtnData("Xaou SpaceRing") end)
    item:AddBtnData(
        "เก็บเข้าคลังจักรวาล",
        "res/Sprs/ui/icon_hand",
        "Xaou_SpaceRing_StoreSelectedItem(bind)",
        "เก็บไอเทมชิ้นนี้เข้าคลังจักรวาลเดิมของเกม ถ้ายังไม่มีอาคาร จะใช้ SpaceRing:AddStorage แบบตรวจจำนวนก่อน/หลัง",
        nil
    )
end



function XaouSpaceRing:AddBtn2Building(building)
    if xs_is_sleeve_building(building) ~= true then return end

    pcall(function() building:RemoveBtnData("เก็บของทั้งแผนที่") end)
    pcall(function() building:RemoveBtnData("เบิกคลังจักรวาล") end)
    pcall(function() building:RemoveBtnData("เปิดคลังเดิม") end)
    pcall(function() building:RemoveBtnData("เปิดคลังจักรวาล") end)
    building:AddBtnData(
        "เปิดคลังจักรวาล",
        "res/Sprs/ui/icon_hand",
        "Xaou_SpaceRing_OpenOriginalStorageUI(bind)",
        "สไตล์ Xaou: ปลุกหมวดอื่นๆ อัตโนมัติก่อนเปิดคลังเดิมของเกม",
        nil
    )
end

function XaouSpaceRing:OnEnter()
    print("[XaouSpaceRing] OnEnter")
    self._xaouBuildingBtnTimer = 0
    self._xaouRestoreTimer = 0
    self._xaouRestoreRuns = 0
    pcall(function()
        local restored, failed, info = xs_restore_remote_item_registry()
        print("[XaouSpaceRing] restore on enter: " .. tostring(restored) .. "/" .. tostring(failed) .. " | " .. tostring(info))
    end)
    local event_mod = GameMain:GetMod("_Event")
    if event_mod == nil then
        xs_show("ไม่พบ _Event mod", "Xaou SpaceRing")
        return
    end

    event_mod:RegisterEvent(g_emEvent.SelectItem, function(evt, item, objs)
        self:AddBtn2Item(item)
    end, "Xaou_SpaceRing_SelectItem")

    event_mod:RegisterEvent(g_emEvent.SelectNpc, function(evt, npc, objs)
        self:AddBtn2Npc(npc)
    end, "Xaou_SpaceRing_SelectNpc")

    pcall(function()
        if g_emEvent.SelectBuilding ~= nil then
            event_mod:RegisterEvent(g_emEvent.SelectBuilding, function(evt, building, objs)
                self:AddBtn2Building(building)
            end, "Xaou_SpaceRing_SelectBuilding")
        end
    end)
end

function XaouSpaceRing:OnStep(delta_time)
    local dt = tonumber(delta_time) or 0

    self._xaouRestoreTimer = (self._xaouRestoreTimer or 0) + dt
    if (self._xaouRestoreRuns or 0) < 8 and self._xaouRestoreTimer >= 1 then
        self._xaouRestoreTimer = 0
        self._xaouRestoreRuns = (self._xaouRestoreRuns or 0) + 1
        pcall(function()
            local restored, failed, info = xs_restore_remote_item_registry()
            print("[XaouSpaceRing] restore retry " .. tostring(self._xaouRestoreRuns) .. ": " .. tostring(restored) .. "/" .. tostring(failed) .. " | " .. tostring(info))
        end)
    end

    self._xaouBuildingBtnTimer = (self._xaouBuildingBtnTimer or 0) + dt
    if self._xaouBuildingBtnTimer < 2 then return end
    self._xaouBuildingBtnTimer = 0
    local building = xs_find_sleeve_building()
    if building ~= nil then self:AddBtn2Building(building) end
end
