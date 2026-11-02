local Canvas=require('platform.canvas');local JSON=require('core.v2json')
local N={}
function N:newCanvas(w,h)return Canvas.new(w,h)end
function N:loadImage(path)return Canvas.load(path)end
N.techart={}
for _,name in ipairs({'load','actorCreate','worldCreate'})do N.techart[name]=function(_,...)return require('platform.techart')[name](...)end end
function N:now()return os.clock()*1000 end
function N:json(path)local normalized=path:gsub('^%./',''):gsub('^/',''):gsub('^assets/','');local resource=cache:GetResource('JSONFile',normalized);assert(resource,'JSON missing: '..path);return JSON.parse(resource:ToString(''))end
function N:isArray(value)local mt=type(value)=='table'and getmetatable(value);return type(value)=='table'and (mt and mt.__js_array or value[1]~=nil)or false end
function N:hypot(a,b)return math.sqrt(a*a+b*b)end
local function imul(a,b)return (a*b) & 0xffffffff end
function N:hash(seed,i)local n=(math.floor(seed) & 0xffffffff) ~ imul(i+47,0x45d9f3b);n=imul(n ~ (n >> 16),0x45d9f3b);n=(n ~ (n >> 16)) & 0xffffffff;return n/4294967296 end
return N
