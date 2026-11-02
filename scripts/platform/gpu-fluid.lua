local N=require('platform.compute');local C=require('platform.canvas')
---@class FlameGPUFluid
---@field width number
---@field height number
local F={};F.__index=F
function F.new(opts)
 local self=setmetatable({width=opts.width,height=opts.height,job=N.new('FluidStep'),renderJob=N.new('FluidRender'),time=0,steps=0,drawCalls=0,targets={}},F)
 for i=1,2 do local target={};for key,name in pairs({state='result_state',velocity='result_velocity',aux='result_aux'})do target[key]=assert(self.job:CreateImage2D(name,self.width,self.height),self.job:GetLastError());target[key]:SetFilterMode(FILTER_NEAREST)end;self.targets[i]=target end
 self.index=1
 for key,file in pairs({detail='mist-details',flow='flowmap',gradient='mist-gradient2',fire='mistfire-gradient',splat='SplatTexture'})do
  local texture=N.texture(C.load(opts.base..file..'.png'))
  if key=='detail'or key=='flow'or key=='splat'then N.bind(self.job,key..'_map',texture)end
  if key~='splat'then N.bind(self.renderJob,key..'_map',texture)end
 end
 self.output=N.output(self.renderJob,self.width,self.height);self:reset();return self
end
function F:dispatch(pass)
 local source=self.targets[self.index];local nextIndex=3-self.index;local target=self.targets[nextIndex]
 for _,key in ipairs({'state','velocity','aux'})do N.bind(self.job,key..'_map',source[key]);assert(self.job:SetImage('result_'..key,target[key]),self.job:GetLastError())end
 N.set(self.job,'pass_id',pass);assert(self.job:DispatchThreads(self.width,self.height),self.job:GetLastError());self.index=nextIndex;self.drawCalls=self.drawCalls+1
end
function F:reset(density)self.time=0;self.steps=0;N.set(self.job,'initial_density',density or 0);self:dispatch(0)end
function F:splat(s)
 local r=math.max(.004,math.min(.5,s.radius));local color=s.color or{0,.6,.66}
 N.set(self.job,'clock',self.time);N.set(self.job,'brush',Vector4(s.x,s.y,r*self.height/self.width,r));N.set(self.job,'weights',Vector4(s.heat or color[1],color[2],color[3],s.amount or 1));N.set(self.job,'impulse',Vector2(s.vx or 0,s.vy or 0));N.set(self.job,'erase',s.erase and 1 or 0);self:dispatch(1)
end
function F:step(dt)
 local remaining=math.min(dt,4/60)
 while remaining>1e-7 do local part=math.min(remaining,1/60);N.set(self.job,'dt',part);for pass=2,9 do self:dispatch(pass)end;self.steps=self.steps+1;self.time=self.time+part;remaining=remaining-part end
end
function F:render(opts)
 local current=self.targets[self.index];N.bind(self.renderJob,'state_map',current.state);N.bind(self.renderJob,'velocity_map',current.velocity);N.bind(self.renderJob,'background_map',N.texture(opts.background));N.set(self.renderJob,'clock',self.time);N.set(self.renderJob,'distortion',opts.distortion==false and 0 or 1)
 assert(self.renderJob:DispatchThreads(self.width,self.height),self.renderJob:GetLastError());self.drawCalls=self.drawCalls+1;return self.output
end
function F:diagnostics()return{mode='gpu-source',width=self.width,height=self.height,format='RGBA16F',pressureMode='convolution',steps=self.steps,time=self.time,drawCalls=self.drawCalls}end
function F:dispose()self.disposed=true;self.targets={};self.job=nil;self.renderJob=nil;self.output=nil end
return F
