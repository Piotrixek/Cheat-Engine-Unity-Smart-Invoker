local al = getAddressList()

function checkMod(n)
  if not getProcessIDFromProcessName then return false end
  local mods = enumModules(getOpenedProcessID())
  if mods == nil then return false end
  
  for i, m in pairs(mods) do
    if string.lower(m.Name) == string.lower(n) then 
      return true 
    end
  end
  return false
end

print(">> veni tool init")

if getOpenedProcessID() == 0 then
  print("!! attach first")
  return
end

if checkMod("mono.dll") or checkMod("mono-2.0-bdwgc.dll") then
elseif checkMod("GameAssembly.dll") then
else
  print("!! no mono or il2cpp found")
end

if LaunchMonoDataCollector() == 0 then
  print("!! launch collector fail")
  return
end

local ns = inputQuery("Veni Invoker", "namespace", "")
if ns == nil then return end 

local cls = inputQuery("Veni Invoker", "class", "Player")
if cls == nil then return end

local hMeth = inputQuery("Veni Invoker", "hook method", "Update")
if hMeth == nil then return end

local iMeth = inputQuery("Veni Invoker", "invoke method", "AddGold")
if iMeth == nil then return end

local midH = mono_findMethod(ns, cls, hMeth)
local midI = mono_findMethod(ns, cls, iMeth)

if midH == 0 or midI == 0 then
  print("!! method not found")
  return
end

local addr = mono_compile_method(midH)
if addr == 0 then print("!! compile fail") return end

local tName = cls .. "_" .. hMeth
registerSymbol(tName, addr)

local hSz = 0
local cSz = 0
while cSz < 5 do
  local sz = getInstructionSize(addr + cSz)
  cSz = cSz + sz
end
hSz = cSz

local bts = readBytes(addr, hSz, true)
local dbStr = ""
for i, b in ipairs(bts) do
  dbStr = dbStr .. string.format("%02X ", b)
end

local sym = "veni_instance_" .. cls

local scr = [[
// =====================================================
//  Target: ]] .. cls .. [[.]] .. hMeth .. [[
//  Made by: Veni (Discord: ._.veni._.)
// =====================================================
[ENABLE]
alloc(newmem, 2048, ]] .. tName .. [[)
label(returnhere)
label(originalcode)

label(]] .. sym .. [[)
registersymbol(]] .. sym .. [[)

newmem:
  pushfq
  push rax
  
  mov rax, ]] .. sym .. "\n" .. [[
  cmp qword ptr [rax], 0
  jne @f

  mov [rax], rcx

@@:
  pop rax
  popfq

originalcode:
  db ]] .. dbStr .. "\n" .. [[
  jmp returnhere

]] .. sym .. [[:
  dq 0

]] .. tName .. [[:
  jmp newmem
  ]] .. (hSz > 5 and "nop " .. (hSz - 5) or "") .. [[

returnhere:

[DISABLE]
]] .. tName .. [[:
  db ]] .. dbStr .. [[

unregistersymbol(]] .. sym .. [[)
dealloc(newmem)
]]

local mr = al.createMemoryRecord()
mr.Description = "[ " .. cls .. " ] Instance Hook (Made by Veni)"
mr.Type = vtAutoAssembler
mr.Script = scr
mr.Color = 0x0080FF 

local disp = al.createMemoryRecord()
disp.Description = "-> Instance Address"
disp.Address = sym
disp.Type = vtQword
disp.ShowAsHex = true
disp.appendToEntry(mr)

local invScr = [[
local addr = getAddress("]] .. sym .. [[")
if addr == 0 then 
  print("!! enable hook first")
  return 
end

local inst = readQword(addr)
if inst == 0 or inst == nil then
  print("!! instance null wait for game update")
  return
end

local aStr = inputQuery("Veni Invoker", "arguments for ]] .. iMeth .. [[\n(comma separated eg: 100, 'test')", "")
if aStr == nil then return end

local args = {}
if aStr ~= "" then
    local f = load("return {" .. aStr .. "}")
    if f then args = f() end
end

print(">> invoking ]] .. iMeth .. [[...")
local dom = mono_enumDomains()[1] 
mono_invoke_method(dom, ]] .. midI .. [[, inst, args)
print(">> done")
]]

local inv = al.createMemoryRecord()
inv.Description = ">> INVOKE: " .. iMeth
inv.Type = vtAutoAssembler
inv.Script = "[ENABLE]\n{$lua}\n" .. invScr .. "\n{$asm}\n[DISABLE]\n"
inv.Color = 0x00FF00
inv.appendToEntry(mr)

print(">> script gen success")