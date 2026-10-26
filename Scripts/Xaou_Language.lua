-- Shared TH/EN localization for every Xaou standalone window.

Xaou_ModCenter_Language = Xaou_ModCenter_Language or "th"

local XAOU_EN = {
    ["ทั้งหมด"]="All", ["อาหาร"]="Food", ["โอสถ"]="Pills", ["ยารักษา"]="Medicine",
    ["ยันต์"]="Talismans", ["อาวุธ"]="Weapons", ["วัสดุ"]="Materials", ["อื่นๆ"]="Other",
    ["ด่วน"]="Quick", ["ตัวละคร"]="Character", ["ต่อสู้"]="Combat", ["ยกเลิกบัฟ"]="Remove Buffs",
    ["เพิ่มเติม"]="More", ["โลก"]="World", ["ฤดูกาล"]="Season", ["อากาศ"]="Weather",
    ["เมนูหลัก"]="Main Menu", ["งาน"]="Work", ["สำนัก"]="Sect", ["โลก/เวลา"]="World / Time",
    ["สัตว์อสูร"]="Beasts", ["จักรวาลย่อส่วน"]="Mini Universe", ["ระบบ"]="System",
    ["อาคารพิเศษ"]="Special Buildings", ["คัมภีร์"]="Manuals", ["หนังสือคัมภีร์"]="Manual Books",
    ["ปลดล็อกวิชา"]="Unlock Arts", ["วาร์ป"]="Teleport", ["สถานะ"]="Status",
    ["รีเฟรช"]="Refresh", ["ปิด"]="Close", ["กลับ Mod Center"]="Back to Mod Center",
    ["◀ ย้อนกลับ"]="◀ Previous", ["ถัดไป ▶"]="Next ▶", ["◀ กลับ"]="◀ Back",
    ["เลือก NPC"]="Select NPC", ["พร้อมใช้งาน"]="Ready", ["พร้อมเรียนวิชา"]="Ready to learn",
    ["ยังอ่านไม่ได้"]="Unavailable", ["เปิดใช้งาน"]="Enabled", ["ปิดอยู่"]="Disabled",
    ["เปิดแล้ว"]="Opened", ["ยังไม่เปิด"]="Not opened", ["ยังไม่รู้จัก"]="Unknown",
    ["อยู่"]="Present", ["เสียชีวิต"]="Deceased", ["ออกไปแล้ว"]="Left",

    ["จัดการ NPC"]="Manage NPC", ["เลือกคำสั่งที่ต้องการ"]="Choose a command",
    ["ตั่งค่าด่วน"]="Quick Settings", ["การหลอมโอสถ"]="Alchemy", ["NPC สำนักอื่น"]="Other Sect NPCs",
    ["กำลังใช้คำสั่ง"]="Running command", ["สำเร็จ"]="Success", ["ไม่สำเร็จ"]="Failed",
    ["ระบบไม่ยืนยันผลลัพธ์"]="The game did not confirm the result",
    ["คำสั่งนี้ยังไม่รองรับในหน้าใหม่"]="This command is not supported in the new window",

    ["เรียนวิชาอัตโนมัติ"]="Automatic Learning", ["เรียนทุกวิชาในสำนัก"]="Learn All Sect Arts",
    ["เรียนวิชาปัจจุบัน"]="Learn Current Art", ["เรียนคัมภีร์ทั้งหมดในหอ"]="Learn All Library Manuals",
    ["ทุกวิชา"]="All Arts", ["วิชาปัจจุบัน"]="Current Art", ["คัมภีร์ในหอ"]="Library Manuals",
    ["เริ่มเรียน"]="Start Learning", ["เรียนวิชาปัจจุบันสำเร็จแล้ว"]="Current art learned successfully",
    ["เรียนคัมภีร์ทั้งหมดในหอสำเร็จแล้ว"]="All library manuals learned successfully",
    ["เรียนทุกวิชาในสำนักสำเร็จแล้ว"]="All sect arts learned successfully",
    ["กำลังเรียนวิชา กรุณารอสักครู่..."]="Learning arts. Please wait...",
    ["ไม่พบวิชาที่สามารถเรียนได้"]="No learnable arts found",
    ["ไม่พบวิชาที่สามารถเรียนได้ หรือมีข้อมูลบางส่วนไม่รองรับ"]="No learnable arts were found, or some data is unsupported",

    ["เมนูคัมภีร์"]="Manual Menu", ["Xaou Book Center"]="Xaou Book Center",
    ["เลือกคำสั่งคัมภีร์ที่ต้องการ"]="Choose a manual command",
    ["ใช้เป็นผู้รับคัมภีร์และคำสั่งวิชา"]="Recipient for manuals and cultivation-art commands",
    ["เปิดคำสั่ง"]="Opened command",
    ["วิชาสายหลักทั้งหมด"]="Unlock All Main Arts", ["วิชาระดับสวรรค์ สุ่ม 20 ครั้ง"]="Random Heaven-Tier Arts ×20",
    ["วาร์ป1"]="Teleport", ["เปิดคำสั่งแล้ว"]="Command opened", ["เปิดเมนูวาร์ปแล้ว"]="Teleport menu opened",
    ["เปิดแผนที่วาร์ปแล้ว"]="Teleport map opened", ["ไม่พบ NPC เป้าหมาย"]="Target NPC not found",
    ["ไม่พบคำสั่ง"]="Command not found", ["คำสั่งไม่มี Story"]="This command has no Story entry",

    ["เก็บคัมภีร์เข้าหอ"]="Store Manuals in Library", ["คัมภีร์บนแผนที่"]="Manuals on the Map",
    ["ใช้เป็นผู้บันทึกคัมภีร์เข้าหออัตโนมัติ"]="Used to register manuals in the library automatically",
    ["▶ เก็บคัมภีร์"]="▶ Store Manuals", ["กำลังเก็บคัมภีร์ กรุณารอสักครู่..."]="Storing manuals. Please wait...",
    ["ยืนยันว่าจะเก็บคัมภีร์ทั้งหมดบนแผนที่เข้าหอ ใช่ไหม?"]="Store every manual on the map in the library?",
    ["ไม่ทราบสาเหตุ"]="Unknown reason", ["เก็บคัมภีร์เข้าหอสำเร็จแล้ว"]="Manuals stored successfully",

    ["เครื่องมือก่อสร้าง"]="Construction Tools", ["ควบคุมระบบช่วยสร้างของ Xaou"]="Xaou construction assistance",
    ["สถานะการก่อสร้าง"]="Construction Status", ["▶ เครื่องมือสร้าง"]="▶ Build Tools",
    ["สร้างด่วน"]="Quick Build", ["สร้างฟรี"]="Free Build", ["เลือกโหมดก่อสร้าง"]="Choose Construction Mode",
    ["แตะปุ่มเพื่อเปิดหรือปิด ระบบจะแสดงสถานะล่าสุดทันที"]="Tap a button to toggle it. The latest state appears immediately.",
    ["ปิดเครื่องมือทั้งหมด"]="Disable All Tools", ["รีเฟรชสถานะ"]="Refresh Status",
    ["ไม่พบรายการอาคาร"]="Building definitions not found", ["เปลี่ยนสถานะไม่สำเร็จ"]="Failed to change state",
    ["ปิดเครื่องมือไม่สำเร็จ"]="Failed to disable tools",

    ["เตาควบคุมอุณหภูมิ"]="Temperature Furnace", ["กำหนดอุณหภูมิเป้าหมายของห้อง"]="Set the target temperature for this room",
    ["ลด 10°C"]="Decrease 10°C", ["ลด 1°C"]="Decrease 1°C", ["เพิ่ม 1°C"]="Increase 1°C",
    ["เพิ่ม 10°C"]="Increase 10°C", ["คืนค่า 20°C"]="Reset to 20°C", ["ค่าอุณหภูมิที่ใช้บ่อย"]="Common Temperatures",
    ["เลือกค่าหรือปรับทีละองศา แล้วกดบันทึกค่า"]="Choose a preset or adjust the value, then save.",
    ["ไม่พบอาคารเป้าหมาย"]="Target building not found",
    ["ระบบอาคาร Xaou009"]="Xaou009 Building System",
    ["เรียนเฉพาะวิชาที่ NPC กำลังฝึก พร้อมปลดล็อกคัมภีร์และสายวิชาที่รองรับ"]="Learn only the NPC's current art and unlock its supported manuals and branches.",
    ["เรียนคัมภีร์ทุกเล่มที่เก็บในหอ โดยใช้ระบบเรียนจริงของเกมและข้ามเล่มที่เรียนแล้ว"]="Learn every library manual through the game's real learning system and skip manuals already learned.",
    ["เรียนวิชาทั้งหมดที่มีในสำนัก และข้ามวิชาหรือโหนดที่เกมไม่รองรับโดยอัตโนมัติ"]="Learn all sect arts and automatically skip unsupported arts or nodes.",

    ["เครื่องมือโลกและไอเทม"]="World and Item Tools", ["เครื่องมือส่วนกลาง"]="Shared Tools",
    ["ตั้งค่า FPS"]="Frame Rate Settings", ["ตั้งค่าเฟรมเรต"]="Frame Rate Settings",
    ["กำหนดอัตราเฟรมสำหรับหน้าจอมือถือ"]="Set the frame rate for the mobile display",
    ["เฟรมเรต"]="Frame Rate", ["เฟรมเรตเป้าหมาย"]="Target Frame Rate",
    ["เฟรมเรตที่วัดจริง"]="Measured Frame Rate", ["กำลังวัด..."]="Measuring...",
    ["ประหยัดพลังงาน"]="Power Saving", ["สมดุล"]="Balanced", ["ลื่นไหล"]="Smooth", ["สูงสุด"]="Maximum",
    ["เลือกเฟรมเรต"]="Choose Frame Rate", ["อัตโนมัติ"]="Automatic",
    ["ค่าจริงขึ้นอยู่กับจอ อุปกรณ์ และข้อจำกัดความร้อน"]="Actual performance depends on the display, device, and thermal limits.",
    ["ค่าจริงขึ้นอยู่กับจอและอุปกรณ์"]="Actual performance depends on the display and device.",
    ["การตั้งค่านี้ไม่เปลี่ยนความเร็วเวลาและระบบฟิสิกส์ของเกม"]="This setting does not change game speed or physics.",
    ["ตั้งค่าเฟรมเรตไม่สำเร็จ"]="Failed to set frame rate",
    ["ไอเทม"]="Items", ["หมอก"]="Fog", ["คลังอัตโนมัติ"]="Auto Storage",
    ["เปิด"]="On", ["ปิด"]="Off", ["กลับ Mod Center"]="Back to Mod Center",

    ["เสกไอเทม"]="Spawn Items", ["เลือกไอเทม"]="Select Item", ["แตะไอเทมเพื่อดูรายละเอียด"]="Tap an item to view details",
    ["เลือกหมวดและไอเทมที่ต้องการ"]="Choose a category and an item",
    ["จำนวน"]="Amount", ["หมวด"]="Category", ["รายการ"]="items", ["ค้นหา"]="Search",
    ["เสกไอเทมสำเร็จ"]="Items spawned successfully", ["เสกไอเทมไม่สำเร็จ"]="Failed to spawn items",
    ["ไม่พบไอเทม"]="Item not found", ["หาตำแหน่งวางของไม่พบ"]="No valid drop position found",
    ["ไม่พบหน้าต่างเสกไอเทม"]="Item Spawner window not found", ["เปิดหน้าต่างไม่สำเร็จ"]="Failed to open window",

    ["NPC สำนักอื่น"]="Other Sect NPCs", ["สถานะ: -\nความชอบ: -\nความระแวง: -\nเปิดใจ: -"]="Status: -\nFavor: -\nVigilance: -\nHeart: -",
    ["เลือกตัวละครเพื่อเปิดใจหรือเพิ่มความสัมพันธ์"]="Select a character to open their heart or increase favor.",
    ["เปิดใจ"]="Open Heart", ["เปิดใจ + สัมพันธ์เต็ม"]="Open Heart + Max Favor",
    ["ทดสอบปุ่ม"]="Test button", ["เรียกสัตว์เทพ"]="Summon divine beast",
    ["เรียกสัตว์เทพไม่สำเร็จ"]="Failed to summon divine beast", ["สร้างศัตรูชั้นยอดแล้ว"]="Elite enemies created",
    ["สร้างศัตรูชั้นยอดไม่สำเร็จ"]="Failed to create elite enemies", ["ไม่พบ GameUlt.CallBoss"]="GameUlt.CallBoss not found",
    ["เรียกบอส"]="Summon Boss", ["เรียกบอสไม่สำเร็จ"]="Failed to summon boss",

    ["เวลา / ฤดูกาล / อากาศ"]="Time / Season / Weather",
    ["เลือกช่วงเวลา หรือเปิดหน้าตั้งค่าฤดูกาลและสภาพอากาศ"]="Choose a time of day, season, or weather setting.",
    ["ตอนเช้า"]="Morning", ["ตอนเที่ยง"]="Noon", ["ตอนเย็น"]="Evening", ["ตอนกลางคืน"]="Night",
    ["เลือกฤดูกาล"]="Choose Season", ["เลือกสภาพอากาศ"]="Choose Weather",
    ["เครื่องมือไอเทม"]="Item Tools", ["เลือกไอเทมบนพื้น แล้วเปิดเครื่องมือ Xaou เพื่อใช้งานคำสั่งเหล่านี้"]="Select an item on the ground, then use a Xaou tool.",
    ["คูณจำนวนไอเทม ×2"]="Double Item Stack ×2", ["หลอมอสูร / เพิ่มระดับ"]="Demon Refining / Raise Tier",
    ["หลอมจิต"]="Spirit Refining", ["เติมพลังวิญญาณเต็ม"]="Fill Spiritual Energy",
    ["ทัณฑ์สวรรค์อาวุธเวท 36 ครั้ง"]="36 Artifact Tribulations",
    ["เครื่องมือโลก"]="World Tools", ["ควบคุมแผนที่ หมอก และการเก็บของอัตโนมัติ"]="Control the map, fog, and automatic storage.",
    ["เปิดสถานที่ทั้งหมดบนแผนที่"]="Reveal All Map Locations", ["เปิด / ปิดหมอกแผนที่"]="Toggle Map Fog",
    ["เปิด / ปิดเก็บเข้าคลังอัตโนมัติ"]="Toggle Automatic Storage", ["สั่งเก็บเข้าคลังตอนนี้"]="Store Items Now",
    ["เปลี่ยนวันของโลกไปยังช่วงต้นของฤดูกาลที่เลือก"]="Move the world date to the beginning of the selected season.",
    ["ฤดูใบไม้ผลิ"]="Spring", ["ฤดูร้อน"]="Summer", ["ฤดูใบไม้ร่วง"]="Autumn", ["ฤดูหนาว"]="Winter",
    ["เปลี่ยนสภาพอากาศปัจจุบันด้วยระบบ BuildModeHelper ของเกม"]="Change current weather through the game's BuildModeHelper.",
    ["อากาศปกติ"]="Clear Weather", ["ฝน / หิมะเบา"]="Light Rain / Snow", ["ฝน / หิมะหนัก"]="Heavy Rain / Snow",
    ["พายุฝุ่น"]="Dust Storm", ["กลางคืนถาวร"]="Permanent Night", ["พายุสายฟ้า"]="Lightning Storm",
    ["อาคารพิเศษ Xaou"]="Xaou Special Buildings", ["สร้างจากหมวด อาคารพิเศษ แล้วเลือกอาคารเพื่อใช้ปุ่มเฉพาะของมัน"]="Build from Special Buildings, then select the building to use its controls.",
    ["ค่ายกลถ่ายพลังวิญญาณ"]="Spiritual Energy Transfer Array",
    ["กำลังจัดการไอเทมที่เลือก"]="Managing Selected Item", ["เครื่องมือเสริมของ Xaou สำหรับระบบเดิมของเกม"]="Xaou tools for the original game systems",

    ["มังกรคราม"]="Azure Dragon", ["หงส์เพลิง"]="Flame Phoenix", ["จูหลง"]="Zhulong",
    ["ภัยพิบัติ Fei"]="Fei Calamity", ["ศัตรูชั้นยอด"]="Elite Enemy", ["ทดสอบข้อความ"]="Message Test",
    ["ช่องว่าง 1"]="Empty Slot 1", ["ช่องว่าง 2"]="Empty Slot 2", ["ช่องว่าง 3"]="Empty Slot 3",
    ["บอสสายมังกร / ทดสอบระบบเรียกบอส\nใช้สำหรับลองปุ่มและการต่อสู้"]="Dragon boss / summon-system test\nUse it to test the controls and combat.",
    ["บอสสายไฟ / เหมาะสำหรับทดสอบเอฟเฟกต์ต่อสู้\nเรียกผ่าน GameUlt.CallBoss"]="Fire boss / suitable for combat-effect tests\nSummoned through GameUlt.CallBoss.",
    ["บอสระดับสูงสำหรับทดสอบ\nถ้า ID นี้ไม่ตรง เกมอาจไม่เรียกออกมา"]="High-level test boss\nThe summon may fail if this ID differs in your game build.",
    ["เรียกสัตว์เทพ Fei ผ่าน Map:AddGodAnimal\nใช้คนละระบบกับ CallBoss"]="Summon divine beast Fei through Map:AddGodAnimal\nThis uses a different system from CallBoss.",
    ["สร้างศัตรูชั้นยอดที่ขอบแผนที่\nเหมาะสำหรับทดสอบศึกทั่วไป"]="Create elite enemies at the map edge\nSuitable for general combat tests.",
    ["ปุ่มทดสอบเท่านั้น\nกดแล้วแสดงข้อความ ไม่เรียกบอสจริง"]="Test button only\nShows a message without summoning a boss.",
    ["เตรียมไว้สำหรับเพิ่มบอสตัวใหม่"]="Reserved for a future boss.",
    ["ไม่พบ FairyGUI / GRoot"]="FairyGUI / GRoot not found", ["เปิด XaouUI/BossSummon ไม่ได้"]="Could not open XaouUI/BossSummon",
}

local XAOU_PREFIX = {
    {"NPC เป้าหมาย: ", "Target NPC: "}, {"ผู้ดำเนินการ: ", "Operator: "},
    {"ผู้พัฒนา: ", "Developer: "}, {"สำนัก: ", "Sect: "}, {"ขั้นฝึกฝน: ", "Stage: "},
    {"วิชาปัจจุบัน: ", "Current art: "}, {"หน้า ", "Page "}, {"จำนวน: ", "Amount: "},
    {"หมวด: ", "Category: "}, {"ค้นหา: ", "Search: "}, {"เปิดคำสั่ง: ", "Opened command: "},
    {"กำลังใช้คำสั่ง: ", "Running command: "}, {"สำเร็จ: ", "Success: "}, {"ไม่สำเร็จ: ", "Failed: "},
    {"อุณหภูมิเป้าหมาย: ", "Target temperature: "}, {"อุณหภูมิห้องนี้: ", "Room temperature: "},
    {"บันทึกค่า ", "Save "}, {"ตั้งอุณหภูมิเป็น ", "Temperature set to "},
    {"เก็บคัมภีร์ทั้งหมด ", "Store all "}, {"ยืนยันเก็บทั้งหมด ", "Confirm storing all "},
    {"พบคัมภีร์บนแผนที่ ", "Manuals found on map: "}, {"เล่ม", " manuals"},
    {"เรียกบอส: ", "Summoned boss: "}, {"เรียกบอสไม่สำเร็จ: ", "Failed to summon boss: "},
    {"สถานะ: ", "Status: "}, {"ความชอบ: ", "Favor: "}, {"ความระแวง: ", "Vigilance: "},
    {"เปิดใจ: ", "Heart: "}, {"ใจ: ", "Heart: "},
    {"หมอก: ", "Fog: "}, {"คลังอัตโนมัติ: ", "Auto Storage: "},
    {"สร้างด่วน: ", "Quick Build: "}, {"สร้างฟรี: ", "Free Build: "},
    {"เฟรมเรตที่วัดจริง: ", "Measured frame rate: "},
    {"รับคัมภีร์ 20 เล่ม ชุดที่ ", "Receive 20 Manuals, Set "},
    {"ระบบจะเพิ่มเข้าหอก่อนลบของบนพื้น", "The game adds each manual to the library before removing it from the ground."},
    {"แต่ละห้องตั้งค่าแยกกัน", "Each room has an independent setting."},
}

-- Common command phrases. These run after exact translations so command lists
-- from the original mod also become readable without changing action IDs.
local XAOU_WORDS = {
    {"ยังไม่เปิด", "Not Opened"}, {"เปิดแล้ว", "Opened"}, {"ยังไม่รู้จัก", "Unknown"},
    {"เสียชีวิต", "Deceased"}, {"ออกไปแล้ว", "Left"},
    {"เพิ่มค่าสถานะทั้ง 5", "Increase All Five Attributes"},
    {"ทะลวงขั้นทันที", "Break Through Now"}, {"ชุบชีวิต NPC", "Revive NPC"},
    {"ขโมยของ NPC", "Claim NPC Secret Treasure"}, {"ยืดเวลาของทัณฑ์สวรรค์", "Delay Heavenly Tribulation"},
    {"โหมดตายยาก", "Survival Mode"}, {"ไม่ต้องกิน/ดื่ม/เหนื่อย", "No Hunger / Thirst / Fatigue"},
    {"พรสวรรค์สูงสุด", "Maximum Talent"}, {"พลังต่อสู้ขั้นสุด", "Maximum Combat Power"},
    {"โบนัสการฝึกฝน", "Training Bonuses"}, {"ความเร็วทำงานสูงสุด", "Maximum Work Speed"},
    {"สัตว์อสูร / ศัตรู", "Beasts / Enemies"}, {"หลอมอาวุธ/โอสถระดับเทพ", "Divine Artifact / Pill Refining"},
    {"ปรุงโอสถได้ x100", "Pill Output ×100"}, {"เปิดเมนูเสกของ", "Open Item Spawner"},
    {"เปิดหมอกแผนที่", "Enable Map Fog"}, {"ข้อมูลม็อด", "Mod Information"},
    {"ผู้พัฒนา", "Developer"}, {"การหลอมโอสถ", "Alchemy"}, {"สำนักอื่น", "Other Sects"},
    {"เรียกอสูร", "Summon Beast"}, {"สุ่มเรียกอสูร", "Summon Random Beast"},
    {"เรียกโจรป่า", "Summon Bandits"}, {"โจรป่าระดับสูง", "Summon Elite Bandits"},
    {"หน้าถัดไป", "Next Page"}, {"ก่อนหน้า", "Previous"}, {"หน้าแรกแล้ว", "First Page"},
    {"สุดท้ายแล้ว", "Last Page"}, {"ดูข้อมูล", "View Details"},
    {"เพิ่มต้านธาตุทั้งห้า", "Increase Five-Element Resistance"},
    {"เพิ่มการฟื้นฟูร่างกาย", "Increase Body Recovery"}, {"เพิ่มความเร็วในการเดิน", "Increase Move Speed"},
    {"เพิ่มค่าอารมณ์พื้นฐาน", "Increase Base Mood"}, {"เพิ่มทนต่อความเจ็บปวด", "Increase Pain Tolerance"},
    {"เพิ่มระยะมองเห็น", "Increase Sight Range"}, {"เพิ่มอายุขัย", "Increase Lifespan"},
    {"เพิ่มเลือด สูงสุด", "Increase Maximum Health"}, {"เพิ่มพลังเวท", "Increase Spell Power"},
    {"เพิ่มเกราะโล่", "Increase Shield Armor"}, {"เพิ่มโอกาสโจมตี", "Increase Hit Chance"},
    {"เพิ่มโอกาสหลบ", "Increase Dodge Chance"}, {"เพิ่ม อาวุธวิเศษ 5 ช่อง", "Add 5 Artifact Slots"},
    {"ความเร็วในการเรียนรู้", "Learning Speed"}, {"ความเร็วงานรวม", "Global Work Speed"},
    {"ค่าพื้นฐานของสภาวะจิต", "Base Mental State"},
    {"ความเร็วโจมตีของอาวุธวิเศษ", "Artifact Attack Speed"},
    {"ความเร็วการดูดซับลมปราณ", "Qi Absorption Speed"},
    {"ความเร็วการบำเพ็ญ", "Cultivation Speed"}, {"ความเร็วการสร้างรากฐาน", "Foundation Training Speed"},
    {"ความเร็วการหลอมโอสถ", "Alchemy Speed"}, {"ความเร็วการหลอมอาวุธวิเศษ", "Artifact Refining Speed"},
    {"ความเร็วการบินระหว่างออกผจญภัย", "Adventure Flight Speed"},
    {"ความเร็วการบินผจญภัย", "Adventure Flight Speed"}, {"ความเร็วการสำรวจผจญภัย", "Adventure Exploration Speed"},
    {"ความแข็งแกร่งโล่พลัง", "Energy Shield Strength"}, {"ความแข็งแกร่งของโล่พลัง", "Energy Shield Strength"},
    {"คุณภาพอาวุธวิเศษ", "Artifact Quality"}, {"พลังอาวุธวิเศษ", "Artifact Power"},
    {"พลังวิญญาณสูงสุดอาวุธวิเศษ", "Maximum Artifact Energy"},
    {"ฟื้นฟูพลังวิญญาณของอาวุธวิเศษ", "Artifact Energy Recovery"},
    {"ระดับขั้นอาวุธวิเศษ", "Artifact Tier"}, {"ระยะกระเด็นของอาวุธวิเศษ", "Artifact Knockback Range"},
    {"คูลดาวน์ของวิชา", "Spell Cooldown"}, {"พลังโจมตีของวิชา", "Spell Attack Power"},
    {"การใช้พลังวิญญาณของวิชา", "Spell Energy Cost"},
    {"ศักยภาพ", "Potential"}, {"ความหยั่งรู้", "Comprehension"},
    {"อัตราความสำเร็จในการหลอมโอสถ", "Alchemy Success Rate"},
    {"อัตราสำเร็จการหลอมอาวุธวิเศษ", "Artifact Refining Success Rate"},
    {"อัตราสำเร็จจากทักษะปรุงโอสถ", "Skill-Based Alchemy Success Rate"},
    {"ปริมาณการผลิตโอสถจากทักษะปรุงโอสถ", "Skill-Based Pill Output"},
    {"ปริมาณการผลิตโอสถ", "Pill Output"}, {"ขีดจำกัดเตาหลอม", "Furnace Limit"},
    {"ขนาดพื้นที่ค่ายกล", "Formation Area"}, {"ความจุค่ายกล", "Formation Capacity"},
    {"ความมั่นคงของสภาวะจิต", "Mental-State Stability"},
    {"ผลกระทบของอารมณ์ต่อสภาวะจิต", "Mood Effect on Mental State"},
    {"พลังวิญญาณสูงสุดของ NPC", "Maximum NPC Energy"}, {"ลมปราณพื้นฐาน", "Base Qi"},
    {"พลังบำเพ็ญแท้เพิ่มเติม", "Additional Cultivation Power"}, {"พลังปราณแท้", "True Qi"},
    {"ความบันเทิง", "Entertainment"}, {"พลังงาน", "Energy"}, {"บริโภคน้ำ", "Water Consumption"},
    {"บริโภคอาหาร", "Food Consumption"}, {"ฟื้นฟูจากการดื่มน้ำ", "Recovery from Drinking"},
    {"ฟื้นฟูจากอาหาร", "Recovery from Food"}, {"ฟื้นฟูบาดแผลภายใน", "Internal-Injury Recovery"},
    {"ฟื้นฟูพลังงาน", "Energy Recovery"}, {"จำนวนคัมภีร์ลับสูงสุด", "Maximum Secret Manuals"},
    {"โอกาสทะลวงคอขวด", "Breakthrough Chance"}, {"เวลาคอขวดจากการผจญภัย", "Adventure Bottleneck Time"},
    {"ชื่อเสียงการผจญภัย", "Adventure Reputation"}, {"บทลงทัณฑ์สวรรค์", "Heavenly Tribulation"},
    {"อัตราสำเร็จพื้นฐานการสร้างศาสตราเทพ", "Base Divine Artifact Success Rate"},
    {"ปรับโบนัส", "Adjust Bonus: "}, {"ปรับตัวคูณ", "Adjust Multiplier: "},
    {"ปรับอัตรา", "Adjust Rate: "}, {"ปรับความเร็ว", "Adjust Speed: "},
    {"ปรับค่า", "Adjust: "}, {"เพิ่มค่า", "Increase: "}, {"เพิ่มพลัง", "Increase Power: "},
    {"รีเซ็ต", "Reset "}, {"ปิด", "Disable "}, {"เปิด", "Enable "},
}

function Xaou_IsEnglish()
    return Xaou_ModCenter_Language == "en"
end

function Xaou_T(thai, english)
    if Xaou_IsEnglish() then return english or XAOU_EN[tostring(thai)] or thai end
    return thai
end

function Xaou_LocalizeText(value)
    local text = tostring(value or "")
    if not Xaou_IsEnglish() then return text end
    if XAOU_EN[text] ~= nil then return XAOU_EN[text] end
    for _, pair in ipairs(XAOU_PREFIX) do
        text = string.gsub(text, pair[1], pair[2])
    end
    for _, pair in ipairs(XAOU_WORDS) do
        text = string.gsub(text, pair[1], pair[2])
    end
    return XAOU_EN[text] or text
end

function Xaou_SetLanguage(language)
    Xaou_ModCenter_Language = tostring(language) == "en" and "en" or "th"
    return Xaou_ModCenter_Language
end
