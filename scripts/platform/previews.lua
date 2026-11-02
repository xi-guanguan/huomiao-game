-- Two isolated real rule/renderer scenes. The player state is only read for rank.
---@class FlamePreviews
---@field vg NVGContextWrapper
---@field manifest table<string,any>
local P={};P.__index=P
local E=require('core.engine')
local Simulation=require('preview.skill-preview')
local NewSimulation=require('preview.lualib_bundle').__TS__New
local Renderer=require('render.renderer').GameRenderer
local NewRenderer=require('render.lualib_bundle').__TS__New
local Canvas=require('platform.canvas')
local W,H=192,112
local function rankValue(value)
 if type(value)~='number' or value~=value or value==math.huge or value==-math.huge then return 0 end
 return math.max(0,math.min(3,value<0 and math.ceil(value) or math.floor(value)))
end
local function assets(manifest,skill)
 local enemy=skill=='lash' and 'stone' or 'melee'
 local keep={hero=true,['hero-ember']=true,['hero-half']=true,['hero-ifrit']=true,tiles=true,head=true,[enemy]=true}
 local result={images={},atlases={},props={},scene=manifest.scene}
 for key,value in pairs(manifest.images or {}) do if keep[key] or key:sub(1,6)=='scene.' then result.images[key]=value end end
 for key,value in pairs(manifest.atlases or {}) do if keep[key] then result.atlases[key]=value end end
 return result
end
function P.new(manifest,vg)
 assert(type(manifest)=='table','Preview assets are required')
 return setmetatable({manifest=manifest,vg=vg,scenes={},disposed=false,scenario='',currentRank=0,nextRank=1,reduced=false},P)
end
function P:releaseScenes(scenes)
 for _,scene in ipairs(scenes) do
  if scene.renderer then Canvas.disposeRenderer(scene.renderer,self.vg) end
  local stage=scene.stage
  if stage then
   Canvas.dispose(stage,self.vg)
  end
 end
end
function P:select(state,skill)
 if self.disposed then return false end
 local valid=false;for _,definition in ipairs(E.SKILLS) do if definition.id==skill then valid=true;break end end
 assert(valid,'Unknown preview skill')
 local rank=rankValue(state.skills[skill])
 local nextRank=math.min(3,rank+1)
 local signature=skill..':'..rank
 if self.signature==signature then return false end
 self:releaseScenes(self.scenes);self.scenes={};self.signature=nil
 local scenes={}
 local ok,message=pcall(function()
  local manifest=assets(self.manifest,skill)
  for _,level in ipairs({rank,nextRank}) do
   local stage=Canvas.new(W,H)
   local renderer=NewRenderer(Renderer,stage);Canvas.enableRenderer(renderer,stage)
   local scene={stage=stage,renderer=renderer,simulation=NewSimulation(Simulation.SkillPreviewSimulation,skill,level),dirty=true}
   scenes[#scenes+1]=scene
   renderer:setReducedMotion(self.reduced);renderer:setAssets(manifest);renderer:reset()
   renderer:render(scene.simulation.state,0)
  end
 end)
 if not ok then self:releaseScenes(scenes);error(message) end
 self.scenes=scenes;self.signature=signature;self.skill=skill;self.currentRank=rank;self.nextRank=nextRank;self.scenario=Simulation.previewScenario(skill)
 return true
end
function P:update(dt)
 if self.disposed or #self.scenes==0 then return end
 local elapsed=type(dt)=='number' and dt==dt and dt~=math.huge and dt~=-math.huge and math.max(0,math.min(.1,dt)) or 0
 for _,scene in ipairs(self.scenes) do
  if scene.simulation:update(elapsed) then scene.renderer:reset() end
  scene.renderer:render(scene.simulation.state,elapsed);scene.dirty=true
 end
end
local function image(vg,handle,x,y,w,h)
 nvgSave(vg);nvgIntersectScissor(vg,x,y,w,h);nvgBeginPath(vg);nvgRect(vg,x,y,w,h)
 nvgFillPaint(vg,nvgImagePattern(vg,x,y,w,h,0,handle,1));nvgFill(vg);nvgRestore(vg)
end
function P:draw(ui,x,y,w,h)
 if self.disposed or #self.scenes==0 or w<=0 or h<=0 then return end
 local reduced=ui.app and ui.app.reduced==true or false
 if reduced~=self.reduced then self.reduced=reduced;for _,scene in ipairs(self.scenes) do scene.renderer:setReducedMotion(reduced) end end
 local gap=6
 local paneW=(w-gap)/2
 local header=h>=90 and 19 or 15
 local footer=h>=90 and 22 or 16
 local caption=h>=150 and 20 or 0
 local innerH=math.max(1,h-header-footer-caption)
 for index,scene in ipairs(self.scenes) do
  local left,level=x+(index-1)*(paneW+gap),scene.simulation.rank
  ui:rect(left,y,paneW,h-caption,'#101c1b')
  local label=index==1 and (level==0 and '未领悟' or '当前 · '..level..'阶') or (self.currentRank>=3 and '已精通 · 3阶' or '下一阶 · '..level..'阶')
  ui:text(label,left+paneW/2,y+1,12,index==1 and '#d1c9ac' or '#ffbc62','center')
  local scale=math.min(paneW/W,innerH/H)
  local drawW,drawH=math.max(1,math.floor(W*scale)),math.max(1,math.floor(H*scale))
  local drawX,drawY=left+math.floor((paneW-drawW)/2),y+header+math.floor((innerH-drawH)/2)
  if scene.dirty or not scene.stage.handle then scene.handle=Canvas.upload(scene.stage,self.vg);scene.dirty=false end
  image(self.vg,scene.handle,drawX,drawY,drawW,drawH)
  local s,statY=scene.simulation.state,y+h-caption-footer
  local life,hp=math.max(0,math.ceil(s.resolve)),scene.simulation.state.enemy and math.max(0,math.ceil(scene.simulation.state.enemy.hp)) or 0
  ui:text('生命 '..life..'  目标 '..hp,left+paneW/2,statY,10,'#a2a48f','center')
  ui:bar(left+5,y+h-caption-5,paneW-10,3,s.resolve/s.maxResolve,'#c8c79b')
 end
 if caption>0 then ui:text(self.scenario,x+w/2,y+h-caption+3,10,'#a2a48f','center') end
end
function P:dispose()
 if self.disposed then return end
 self:releaseScenes(self.scenes);self.scenes={};self.disposed=true;self.signature=nil;self.scenario=''
end
return P
