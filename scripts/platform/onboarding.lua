-- Three short lessons, shown once in the first life. Separate from journey saves.
local J=require('core.v2json')
---@class FlameTutorial
---@field path string
---@field testMode boolean
---@field seen table<string,boolean>
---@field current {id:string,text:string}?
local T={};T.__index=T
function T.new(saved,path,testMode)
 local self=setmetatable({path=path,testMode=testMode,seen={},finished=false,gap=0},T)
 if not testMode and fileSystem:FileExists(path)then
  local f=File(path,FILE_READ);local text=f:ReadLine();f:Close()
  local ok,value=pcall(J.parse,text)
  if ok and type(value)=='table'and value.version==1 then self.seen=type(value.seen)=='table'and value.seen or{};self.finished=value.finished==true end
 end
 -- An existing journey belongs to a returning player, including imported H5 saves.
 if saved and saved.phase~='title'then self.finished=true end
 return self
end
function T:save()
 if self.testMode then return end
 local f=File(self.path,FILE_WRITE);assert(f:IsOpen(),'Tutorial preferences unavailable')
 assert(f:WriteLine(J.stringify({version=1,seen=self.seen,finished=self.finished})));f:Close()
end
function T:finish()
 if self.finished then return end
 self.finished=true;self.current=nil;self:save()
end
function T:update(s,dt,modal)
 if self.finished or modal then return end
 if s.kills>0 or s.deaths>0 or s.chapter>0 or s.phase=='fallen'then self:finish();return end
 if self.current then
  self.remaining=self.remaining-dt
  if self.remaining<=0 then self.current=nil;self.gap=3 end
  return
 end
 self.gap=math.max(0,self.gap-dt)
 if self.gap>0 or s.qte then return end
 local id,text
 if s.skillPoints>0 and not self.seen.growth then id='growth';text='打开「生长」，用第一点强化再生。'
 elseif s.phase=='combat'and not self.seen.combat then id='combat';text='敲键出拳，重击将至时按空格架盾。'
 elseif s.phase=='combat'and s.rage>=10 and not self.seen.skill then id='skill';text='连续输入 huoquan，释放火拳。'end
 if id and text then self.seen[id]=true;self.current={id=id,text=text};self.remaining=5;self:save()end
end
return T
