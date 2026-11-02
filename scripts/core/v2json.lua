-- Small standalone JSON codec for V2 saves and native differential replay.
-- Native arrays are 1-based; persisted encounter/chapter/slot fields stay 0-based.
local C=require('core.compat')
local M={null={}}
local arrays={events=true,pendingHits=true,pendingEnemyHits=true,equipped=true,acceptedStrokeIds=true,acceptedSemanticIds=true,acceptedSegments=true,completedMilestones=true,rewardedEncounters=true,props=true,burns=true,SKILLS=true,BRANCHES=true,MEMORIES=true,SEMANTIC_THEMES=true,STORIES=true,ENEMIES=true,ENCOUNTERS=true,ENVIRONMENTS=true,CHAPTERS=true,encounters=true,levels=true,visibleSkills=true,GROWTH_ROUTE=true}
local function quote(s)
  s=string.gsub(s,'[%z\1-\31\\"]',function(c)
    if c=='"' then return '\\"' elseif c=='\\' then return '\\\\' end
    return string.format('\\u%04x',string.byte(c))
  end)
  -- JavaScript slice can leave a lone UTF-16 surrogate. Escape it as valid JSON.
  s=string.gsub(s,'\237[\160-\191][\128-\191]',function(c)
    local a,b,d=string.byte(c,1,3);return string.format('\\u%04x',(a-224)*4096+(b-128)*64+d-128)
  end)
  return '"'..s..'"'
end
local function encode(v,key,state,path)
  local t=type(v)
  if v==nil or v==M.null then return 'null' end
  if t=='boolean' then return v and 'true' or 'false' end
  if t=='number' then if v~=v or v==math.huge or v==-math.huge then return 'null' end;return string.format('%.17g',v) end
  if t=='string' then return quote(v) end
  if t~='table' then error('Cannot JSON-encode '..t) end
  local mt=getmetatable(v)
  local array=arrays[key] or mt and mt.__js_array or v[1]~=nil
  local out={}
  if array then
    for i=1,#v do out[#out+1]=encode(v[i],nil,state,path..'[]') end
    return '['..table.concat(out,',')..']'
  end
  local keys,seen={},{}
  for k,value in pairs(v) do if type(k)=='string' and type(value)~='function' then keys[#keys+1]=k;seen[k]=true end end
  if mt and mt.__nulls then for k in pairs(mt.__nulls) do if not seen[k] then keys[#keys+1]=k;seen[k]=true end end end
  if state then
    local required=path=='$' and {'enemy','qte','headthrow'} or path=='$.beat' and {'arenaCamera'} or path=='$.qte' and {'remaining'} or path=='$.events[]' and v.type=='qte' and v.stage=='start' and {'remaining'} or {}
    for _,k in ipairs(required) do if not seen[k] then keys[#keys+1]=k;seen[k]=true end end
  end
  table.sort(keys)
  for _,k in ipairs(keys) do out[#out+1]=quote(k)..':'..encode(v[k],k,state,path..'.'..k) end
  return '{'..table.concat(out,',')..'}'
end
function M.stringify(value) return encode(value,nil,false,'$') end
function M.stringifyState(value) return encode(value,nil,true,'$') end
function M.parse(text)
  local i,n=1,#text
  local function skip() while i<=n and string.find(' \t\r\n',string.sub(text,i,i),1,true) do i=i+1 end end
  local parseValue
  local function parseString()
    assert(string.sub(text,i,i)=='"','Expected JSON string');i=i+1
    local out={}
    while i<=n do
      local c=string.sub(text,i,i);i=i+1
      if c=='"' then return table.concat(out) end
      if c=='\\' then
        local e=string.sub(text,i,i);i=i+1
        local escapes={['"']='"',['\\']='\\',['/']='/',b='\b',f='\f',n='\n',r='\r',t='\t'}
        if e=='u' then
          local cp=tonumber(string.sub(text,i,i+3),16);assert(cp,'Bad JSON unicode escape');i=i+4
          if cp>=55296 and cp<=56319 and string.sub(text,i,i+1)=='\\u' then
            local lo=tonumber(string.sub(text,i+2,i+5),16)
            if lo and lo>=56320 and lo<=57343 then cp=65536+(cp-55296)*1024+lo-56320;i=i+6 end
          end
          out[#out+1]=C.utf8(cp)
        else assert(escapes[e],'Bad JSON escape');out[#out+1]=escapes[e] end
      else assert(string.byte(c)>=32,'Control character in JSON string');out[#out+1]=c end
    end
    error('Unterminated JSON string')
  end
  parseValue=function()
    skip();local c=string.sub(text,i,i)
    if c=='"' then return parseString() end
    if c=='{' then
      i=i+1;local mt={__js_object=true,__nulls={}};local object=setmetatable({},mt);skip()
      if string.sub(text,i,i)=='}' then i=i+1;return object end
      while true do
        skip();local k=parseString();skip();assert(string.sub(text,i,i)==':','Missing JSON colon');i=i+1
        local value=parseValue();if value==M.null then mt.__nulls[k]=true;object[k]=nil else object[k]=value;mt.__nulls[k]=nil end
        skip();local endc=string.sub(text,i,i);i=i+1;if endc=='}' then return object end;assert(endc==',','Missing JSON object comma')
      end
    end
    if c=='[' then
      i=i+1;local array=setmetatable({},{__js_array=true});skip()
      if string.sub(text,i,i)==']' then i=i+1;return array end
      while true do array[#array+1]=parseValue();skip();local endc=string.sub(text,i,i);i=i+1;if endc==']' then return array end;assert(endc==',','Missing JSON array comma') end
    end
    for literal,value in pairs({['true']=true,['false']=false,['null']=M.null}) do if string.sub(text,i,i+#literal-1)==literal then i=i+#literal;return value end end
    local number=string.match(string.sub(text,i),'^-?%d+%.?%d*[eE]?[+-]?%d*');assert(number and tonumber(number),'Invalid JSON token at '..i);i=i+#number;return tonumber(number)
  end
  local value=parseValue();skip();assert(i>n,'Trailing JSON content');return value
end
function M.restore(text) return require('core.engine').restoreGame(M.parse(text)) end
return M
