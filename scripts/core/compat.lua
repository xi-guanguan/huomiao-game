-- JavaScript semantics used by the frozen rules, implemented in native Lua 5.1.
local data = require('core.unicode-data')
local M = {}

function M.codepoints(s)
  local out, i = {}, 1
  while i <= #s do
    local a,b,c,d = string.byte(s,i,i+3)
    local cp,n = a,1
    if a >= 240 and a <= 244 and b and c and d then cp,n=(a-240)*262144+(b-128)*4096+(c-128)*64+d-128,4
    elseif a >= 224 and a <= 239 and b and c then cp,n=(a-224)*4096+(b-128)*64+c-128,3
    elseif a >= 192 and a <= 223 and b then cp,n=(a-192)*64+b-128,2 end
    out[#out+1]=cp; i=i+n
  end
  return out
end
function M.utf8(cp)
  if cp < 128 then return string.char(cp) end
  if cp < 2048 then return string.char(192+math.floor(cp/64),128+cp%64) end
  if cp < 65536 then return string.char(224+math.floor(cp/4096),128+math.floor(cp/64)%64,128+cp%64) end
  return string.char(240+math.floor(cp/262144),128+math.floor(cp/4096)%64,128+math.floor(cp/64)%64,128+cp%64)
end
local function units(s)
  local out={}
  for _,cp in ipairs(M.codepoints(s)) do
    if cp>=65536 then cp=cp-65536;out[#out+1]=55296+math.floor(cp/1024);out[#out+1]=56320+cp%1024 else out[#out+1]=cp end
  end
  return out
end
local function fromUnits(u,first,last)
  local out,i={},first
  while i<=last do
    local cp=u[i]
    if cp>=55296 and cp<=56319 and i<last and u[i+1]>=56320 and u[i+1]<=57343 then cp=65536+(cp-55296)*1024+u[i+1]-56320;i=i+1 end
    out[#out+1]=M.utf8(cp);i=i+1
  end
  return table.concat(out)
end
function M.jsLength(s)
  if not string.find(s,'[\128-\255]') then return #s end
  return #units(s)
end
function M.jsSlice(s,first,last)
  local n=M.jsLength(s)
  first=first or 0;last=last or n
  first=first<0 and math.max(n+first,0) or math.min(first,n)
  last=last<0 and math.max(n+last,0) or math.min(last,n)
  if last<=first then return '' end
  if n==#s then return string.sub(s,first+1,last) end
  return fromUnits(units(s),first+1,last)
end
function M.jsCharAt(s,index)
  if index<0 or index>=M.jsLength(s) then return nil end
  return M.jsSlice(s,index,index+1)
end
function M.jsLower(s)
  if not string.find(s,'[\128-\255]') then return string.lower(s) end
  local out={}
  for _,cp in ipairs(M.codepoints(s)) do
    local mapped=data.lower[cp]
    if mapped then for _,v in ipairs(mapped) do out[#out+1]=M.utf8(v) end else out[#out+1]=M.utf8(cp) end
  end
  return table.concat(out)
end
function M.asciiLetters(s) return (string.gsub(M.jsLower(s),'[^a-z]','')) end
function M.isAsciiKey(s) return #s==1 and string.match(s,'^[A-Za-z]$')~=nil end
function M.isPinyin(s) return #s>=1 and #s<=80 and string.match(s,'^[a-z]+$')~=nil end
local function inRanges(cp,ranges)
  local lo,hi=1,#ranges
  while lo<=hi do local mid=math.floor((lo+hi)/2);local r=ranges[mid];if cp<r[1] then hi=mid-1 elseif cp>r[2] then lo=mid+1 else return true end end
  return false
end
function M.isPrintableKey(s)
  local cp=M.codepoints(s)
  return #cp==1 and inRanges(cp[1],data.printable)
end
function M.hanText(s)
  local out={}
  for _,cp in ipairs(M.codepoints(s)) do
    local mapped=data.normalizedHan[cp]
    if mapped then for _,v in ipairs(mapped) do out[#out+1]=M.utf8(v) end
    elseif inRanges(cp,data.han) then out[#out+1]=M.utf8(cp) end
  end
  return table.concat(out)
end
function M.jsU32(v) return v%4294967296 end
function M.jsSeed(v)
  if type(v)~='number' or v~=v or v==math.huge or v==-math.huge then return 831105 end
  v=M.jsU32(v<0 and math.ceil(v) or math.floor(v));if v==0 then return 1 end;return v
end
function M.jsTruthy(v) return v~=nil and v~=false and v~=0 and v~='' and v==v end
function M.jsAnd(v,other) if M.jsTruthy(v) then return other() end;return v end
function M.jsOr(v,other) if M.jsTruthy(v) then return v end;return other() end
function M.jsXorshift(v)
  local x=(v<0 and math.ceil(v) or math.floor(v)) & 0xffffffff
  x=(x ~ (x << 13)) & 0xffffffff
  x=(x ~ (x >> 17)) & 0xffffffff
  return (x ~ (x << 5)) & 0xffffffff
end
function M.jsIsArray(v)
  if type(v)~='table' then return false end
  local mt=getmetatable(v)
  if mt and mt.__js_array then return true end
  if mt and mt.__js_object then return false end
  return v[1]~=nil or next(v)==nil
end
function M.jsNullProperty(v,key)
  local mt=getmetatable(v)
  if mt and mt.__js_object then return mt.__nulls and mt.__nulls[key]==true or false end
  return v[key]==nil
end
function M.stableSort(a,compare)
  -- Stable insertion sort is sufficient for the finite 14-theme list.
  for i=2,#a do local value,j=a[i],i-1;while j>=1 and compare(a[j],value)>0 do a[j+1]=a[j];j=j-1 end;a[j+1]=value end
  return a
end
return M
