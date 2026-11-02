-- CPU material/combustion adapters for the official Maker Lua runtime.
-- A direct translation of the existing H5 passes: no actor state or timer ownership.
local C=require('platform.canvas')
local S=require('platform.techart-sampling')
local Fluid=require('platform.gpu-fluid')
local Compute=require('platform.compute')
local clamp,noise,smooth=S.clamp,S.noise,S.smooth
local floor,min,max,abs,sqrt=math.floor,math.min,math.max,math.abs,math.sqrt
local function basePath(base,default)local value=(base or default):gsub('/*$','/');return value end
local function mistBase(opts)
 local value=basePath(opts and opts.base,'assets/round4/techart/mist/')
 if not value:match('/mist/$')then value=value..'mist/'end;return value
end
local function curve(keys,time)
 if #keys==0 then return 0 end;if time<=keys[1].time then return keys[1].value end
 for i=2,#keys do local a,b=keys[i-1],keys[i];if time<b.time then
  assert((a.weightedMode or 0)==0 and(b.weightedMode or 0)==0,'Weighted source curve unsupported')
  local slope,incoming=tonumber(a.outSlope),tonumber(b.inSlope)
  if not slope or not incoming or abs(slope)==math.huge or abs(incoming)==math.huge then return a.value end
  local dt=b.time-a.time;local t=(time-a.time)/dt;local t2,t3=t*t,t*t*t
  return(2*t3-3*t2+1)*a.value+(t3-2*t2+t)*dt*slope+(-2*t3+3*t2)*b.value+(t3-t2)*dt*incoming
 end end;return keys[#keys].value
end
local function preset(p,t)
 local v=clamp(curve(p.curve.m_Curve,clamp(t)))
 return{p.color[1],p.color[2],p.color[3],p.minAlpha+(p.color[4]-p.minAlpha)*v},p.minDissolve+(p.maxDissolve-p.minDissolve)*v
end
local function threshold(progression,direction)
 direction=clamp(direction,.001,1)
 return clamp(max(2*progression-1,min(2*progression*(1-direction)-direction*(1-progression),progression)),0,2)
end
---@class FlameAtlasFire
---@field settings table<string,any>
---@field atlas FlameCanvas
local Fire={};Fire.__index=Fire
function Fire.new(image,settings)
 local atlas=S.canvas(image.width,image.height);local v,t=settings.startColor,settings.tintColor
 for i=1,image.width*image.height do local r,g,b,a=C.rgba(image.pixels[i]or 0);local alpha=clamp(2*a/255*v[4]*t[4])
  atlas.pixels[i]=C.color(min(1,2*r/255*v[1]*t[1]*alpha)*255,min(1,2*g/255*v[2]*t[2]*alpha)*255,min(1,2*b/255*v[3]*t[3]*alpha)*255,255)
 end;return setmetatable({atlas=atlas,settings=settings},Fire)
end
function Fire:draw(ctx,x,y,size,time,seed,reduced)
 if size<1 then return end;local settings=self.settings;local life=settings.lifetime[1]+(settings.lifetime[2]-settings.lifetime[1])*S.random(seed+17)
 local count=reduced and 1 or 3;local fw,fh=self.atlas.width/settings.columns,self.atlas.height/settings.rows
 ctx:save();ctx.globalCompositeOperation='lighter'
 for i=0,count-1 do local clock=(reduced and .35 or time/life)+S.random(seed+3)+i/count;local age=clock-floor(clock)
  local randomSeed=seed*7919+i*53+floor(clock)*97;local index=floor(S.random(randomSeed)*settings.columns*settings.rows)
  local speed=settings.speed[1]+(settings.speed[2]-settings.speed[1])*S.random(randomSeed+2)
  local height=max(1,size*(1-age*.55));local width=max(1,height*.8);local sway=reduced and 0 or(S.random(randomSeed+7)-.5)*size*.35
  ctx.globalAlpha=(1-age)*.8
  ctx:drawImage(self.atlas,(index%settings.columns)*fw,floor(index/settings.columns)*fh,fw,fh,floor(x-width/2+sway+.5),floor(y-height-age*size*speed+.5),math.ceil(width),math.ceil(height))
 end;ctx:restore()
end
local Tech={};Tech.__index=Tech
function Tech.load(base)
 base=basePath(base,'assets/nocturnal-ta/');local settings=C.json(base..'materials.json');local images,textures={},{}
 for _,record in ipairs(settings.textures)do
  local im=C.load(base..record.image);images[record.role]=im;local p=record.texture_settings
  if record.role:match('^_Dissolve')then textures[record.role]=S.texture(im,p and p.m_FilterMode~=0,p and p.m_WrapU==0,p and p.m_WrapV==0,false)end
 end
 assert(images.fire,'Missing source Fire Add texture')
 return setmetatable({settings=settings,fire=Fire.new(images.fire,settings.fire),textures=textures,disposed=false},Tech)
end
function Tech:sprite(source,frame,status,normalizedTime)
 if self.disposed then return nil end
 local name=status=='death'and'burningDeath'or status;local color,dissolve=preset(assert(self.settings.statuses[name],'Unknown source status'),normalizedTime)
 local useDissolve=status=='burning'or status=='death';if status=='death'then dissolve=clamp(normalizedTime)end
 local out=S.canvas(frame.w,frame.h);local w,h=source.width,source.height
 local mask,dir,gradient=self.textures._DissolveMasking,self.textures._DissolveDirection,self.textures._DissolveGradient
 for y=0,frame.h-1 do for x=0,frame.w-1 do
  local r,g,b,a=C.rgba(source.pixels[(frame.y+y)*w+frame.x+x+1]or 0)
  if a>0 then
   r=r/255;g=g/255;b=b/255;a=a/255
   r=r+color[4]*(color[1]-r);g=g+color[4]*(color[2]-g);b=b+color[4]*(color[3]-b)
   if useDissolve then
    local u,v=(x+.5)/frame.w,(y+.5)/frame.h
    local average=(S.red(mask,u+.005,v)+S.red(mask,u,v+.005)+S.red(mask,u-.005,v)+S.red(mask,u,v-.005))*.25
    local cut=threshold(dissolve,S.red(dir,u,v));local offset=average-cut-.05;local diffusion=self.settings.dissolveDiffusion
    if(cut-.1)*1.1>=average then a=0 else
     local gu=clamp(offset*diffusion+cut-.2,.02,1)
     local rr,gg,bb,aa=S.sample(gradient,gu,0);local r1,g1,b1,a1=S.sample(gradient,gu+.005,0)
     local alpha2=a*a*(aa+(a1-aa)*.5);local mix=clamp(cut*(-offset*diffusion+cut+.8)*10)
     r=r+mix*(alpha2*(rr+(r1-rr)*.5)*1.5-r);g=g+mix*(alpha2*(gg+(g1-gg)*.5)*1.5-g);b=b+mix*(alpha2*(bb+(b1-bb)*.5)*1.5-b)
    end
   end
   out.pixels[y*frame.w+x+1]=C.color(r*255,g*255,b*255,a*255)
  end
 end end
 -- Independent output: the next actor cannot mutate a result still used this frame.
 return out
end
function Tech:dispose()self.disposed=true end

local Actor={};Actor.__index=Actor
local actorFrames=setmetatable({},{__mode='k'})
local function actorFrame(source,frame,dynamic)
 local key=table.concat({frame.x,frame.y,frame.w,frame.h},':');local frames=actorFrames[source]
 if not frames then frames={};actorFrames[source]=frames end;local cached=not dynamic and frames[key]or nil
 if cached then return cached end
 cached={r={},g={},b={},a={},minX=frame.w,minY=frame.h,maxX=0,maxY=0}
 for y=0,frame.h-1 do for x=0,frame.w-1 do local r,g,b,a=C.rgba(source.pixels[(frame.y+y)*source.width+frame.x+x+1]or 0);local i=y*frame.w+x+1
  cached.r[i]=r/255;cached.g[i]=g/255;cached.b[i]=b/255;cached.a[i]=a/255
  if a>0 then cached.minX=min(cached.minX,x);cached.minY=min(cached.minY,y);cached.maxX=max(cached.maxX,x);cached.maxY=max(cached.maxY,y)end
 end end
 if not dynamic then frames[key]=cached end;return cached
end
function Actor.new(opts)
 local base=mistBase(opts)
 if(opts and opts.referenceCPU)or not Compute.supported()then return setmetatable({detail=S.texture(C.load(base..'mist-details.png'),true,true,true,false),flow=S.texture(C.load(base..'flowmap.png'),true,true,true,false),fireGradient=S.texture(C.load(base..'mistfire-gradient.png'),true,true,true,false),renders=0,disposed=false},Actor)end
 local job=Compute.new('ActorBurning')
 for key,file in pairs({detail='mist-details',flow='flowmap',fireGradient='mistfire-gradient'})do Compute.bind(job,key,Compute.texture(C.load(base..file..'.png')))end
 return setmetatable({compute=job,renders=0,disposed=false},Actor)
end
function Actor:render(source,frame,p)
 assert(not self.disposed,'Actor burning disposed')
 local padding,body=20,clamp(p.body);local mounts={};for key,mount in pairs(p.mounts or{})do mounts[key]={x=mount.x,y=mount.y}end
 if not mounts.leftHand and mounts.fistL then mounts.leftHand=mounts.fistL end;if not mounts.rightHand and mounts.fistR then mounts.rightHand=mounts.fistR end
 if p.motion=='headless'then mounts.head=nil end
 local head=mounts.head;local exceptions={crawl=true,fallen=true,headless=true,rebirth=true}
 local materialize=not p.preserveBody and not exceptions[p.motion or'']
 local cut=materialize and head and(head.y+6+body*(p.anchor[2]-head.y-6))or frame.h
 local sink=materialize and head and body<1 and(p.anchor[2]-cut-4)*(1-body*.4)or 0
 for key,m in pairs(mounts)do if m.y>cut or(materialize and body<.04 and head and abs(m.x-head.x)>7)then mounts[key]=nil end end
 local onlyHead=materialize and body<.04 and head~=nil
 if self.compute then
  local job=self.compute;local w,h=frame.w+padding*2,frame.h+padding*2
  if not self.output or self.output.width~=w or self.output.height~=h then self.output=Compute.output(job,w,h)end
  Compute.bind(job,'sprite',Compute.texture(source));Compute.set(job,'atlasSize',Vector2(source.width,source.height));Compute.set(job,'frame',Vector4(frame.x,frame.y,frame.w,frame.h));Compute.set(job,'outputSize',Vector2(w,h))
  Compute.set(job,'padding',padding);Compute.set(job,'cutY',cut);Compute.set(job,'headOnly',onlyHead and 1 or 0);Compute.set(job,'head',Vector2(head and head.x or 0,head and head.y or 0))
  Compute.set(job,'state',Vector4(clamp(p.breath),clamp(p.fury),clamp(p.light or 1),clamp(p.pulse or 0)));Compute.set(job,'time',p.reduced and 0 or p.time)
  Compute.set(job,'enemy',p.burningEnemy==true and 1 or(p.burningEnemy==false and 0 or clamp(p.burningEnemy or 0)))
  Compute.set(job,'extinguish',(p.motion=='fallen'or(p.breath<=0 and p.fury<=0 and(p.light or 0)<=0))and 1 or 0)
  local list={};for _,name in ipairs({'head','chest','leftHand','rightHand','leftShoulder','rightShoulder'})do local m=mounts[name];list[#list+1]=Vector3(m and m.x or 0,m and m.y or 0,m and 1 or 0)end;Compute.set(job,'mounts',list)
  assert(job:DispatchThreads(w,h),job:GetLastError());self.renders=self.renders+1
  return{canvas=self.output,anchor={p.anchor[1]+padding,p.anchor[2]+padding-floor(sink+.5)},mounts=mounts,bodyCutY=cut,mode='gpu-source'}
 end
 local w,h=frame.w+padding*2,frame.h+padding*2;local out=S.canvas(w,h);local pixels=actorFrame(source,frame,p.dynamicSource)
 local function bodyAt(x,y)
  if x<0 or y<0 or x>=frame.w or y>=frame.h or y>cut or(onlyHead and abs(x-head.x)>7)then return 0,0,0,0 end
  local i=floor(y)*frame.w+floor(x)+1;return pixels.r[i],pixels.g[i],pixels.b[i],pixels.a[i]
 end
 local function alphaAt(x,y)
  if x<0 or y<0 or x>=frame.w or y>=frame.h or y>cut or(onlyHead and abs(x-head.x)>7)then return 0 end
  return pixels.a[floor(y)*frame.w+floor(x)+1]
 end
 local breath,fury,pulse=clamp(p.breath),clamp(p.fury),clamp(p.pulse or 0)
 local enemy=p.burningEnemy==true and 1 or(p.burningEnemy==false and 0 or clamp(p.burningEnemy or 0))
 local extinguish=p.motion=='fallen'or(p.breath<=0 and p.fury<=0 and(p.light or 0)<=0)
 local fuel=clamp(.18+breath*.55+fury*.25+pulse*.20);if enemy>0 then fuel=clamp(enemy*.6)end;if extinguish then fuel=0 end
 local time=p.reduced and 0 or p.time
 local names={'head','chest','leftHand','rightHand','leftShoulder','rightShoulder'};local seeds={}
 for index,name in ipairs(names)do local m=mounts[name];if m then seeds[#seeds+1]={x=m.x,y=m.y,radius=index==1 and 8 or(index==2 and 10 or 6),alpha=alphaAt(m.x,m.y)}end end
 -- Source's greatest displacement is 7*(1.5+1.65)*(.35+.2)<13 pixels.
 -- Twenty pixels cover every alpha plume and mount radius; skip only guaranteed zeros.
 local x0,x1=max(0,pixels.minX+padding-20),min(w-1,pixels.maxX+padding+20)
 local y0,y1=max(0,pixels.minY+padding-24),min(h-1,pixels.maxY+padding+15)
 for yy=y0,y1 do for xx=x0,x1 do local x,y=xx-padding,yy-padding;local r,g,b,alpha=bodyAt(x,y)
  local fx,fy=S.sample(self.flow,x*.013+time*.016,y*.013-time*.028);fx=fx*2-1;fy=fy*2-1
  local dx,dy=x*.037+fx*.17,y*.028+time*.72+fy*.11
  local n=S.red(self.detail,dx,dy);local n2=S.red(self.detail,dx*2.31+time*.12,dy*2.31)
  local exposed=max(0,alpha-min(alphaAt(x-1,y),alphaAt(x+1,y),alphaAt(x,y-1)))
  local seed=0;for _,m in ipairs(seeds)do local mx,my=x-m.x,(y-m.y)*.7;seed=max(seed,m.alpha*max(0,1-sqrt(mx*mx+my*my)/m.radius))end
  local plume=0
  if not extinguish and alpha<1 then for j=1,7 do local rise=j*(1.5+fuel*1.65);local ox,oy=x+fx*rise*.35+(n-.5)*rise*.40,y+rise
   local aa=alphaAt(ox,oy);local ridge=max(0,aa-alphaAt(ox,oy-3)*.78);plume=max(plume,ridge*(1-j/8))
  end end
  local outer=clamp((plume*(.6+fuel*.75)+seed*.12)*(n*.8+n2*.5)-.15)*(1-alpha)*(extinguish and 0 or 1)
  local flame=clamp(outer*(2+fuel*1.4));local outAlpha=clamp(alpha+flame*.92)
  if outAlpha>=.015 then
   local lum=r*.2126+g*.7152+b*.0722;local char=.27+fuel*.14
   r=r+char*(lum*.30+.025-r);g=g+char*(lum*.22+.018-g);b=b+char*(lum*.18+.014-b)
   local crack=clamp((n2-.73)*5)^2*alpha*(.13+fuel*.45);local glow=(exposed*.17+seed*.06+crack)*fuel
   local pr,pg,pb=S.palette(.72);r=r+pr*glow;g=g+pg*glow;b=b+pb*glow
   local light=pulse*.20*alpha;r=r+light*(1-r);g=g+light*(.82-g);b=b+light*(.50-b)
   local gradient=S.red(self.fireGradient,clamp(flame*(.35+fuel)),.5);local fr,fg,fb=S.palette(clamp(flame*.88+gradient*.12))
   out.pixels[yy*w+xx+1]=C.color((r*alpha+fr*flame*.92)/max(outAlpha,.001)*255,(g*alpha+fg*flame*.92)/max(outAlpha,.001)*255,(b*alpha+fb*flame*.92)/max(outAlpha,.001)*255,outAlpha*255)
  end
 end end
 self.renders=self.renders+1
 return{canvas=out,anchor={p.anchor[1]+padding,p.anchor[2]+padding-floor(sink+.5)},mounts=mounts,bodyCutY=cut,mode='cpu-source'}
end
function Actor:diagnostics()return{mode=self.compute and'gpu-source'or'cpu-reference',failure=nil,renders=self.renders}end
function Actor:dispose()self.disposed=true end

local World={};World.__index=World
local function valid(b)
 for _,key in ipairs({'x','y','width','height','seed','age','strength'})do local n=b[key];if type(n)~='number'or n~=n or abs(n)==math.huge then return false end end
 return b.width>0 and b.height>0
end
function World.new(opts)
 local gpu=Compute.supported();local solver=gpu and Fluid or require('platform.nocturnal-fluid')
 return setmetatable({fluid=solver.new({width=gpu and 192 or 64,height=gpu and 108 or 36,base=mistBase(opts)}),output=S.canvas(1,1),burns={},view={chapter=0,cameraX=0,ground=0,width=1,height=1},
  active=nil,time=0,disposed=false,seeded=false,hasScenery=false,changedPixels=0,hotPixels=0,frames=0,splatCount=0,secondaryCount=0},World)
end
function World:emit(b,j,amount)
 local n=noise(j,0,b.seed);local ground=clamp(-b.y/b.height,.035,.88)
 self.fluid:splat({x=.065+j*.174+(n-.5)*.035,y=ground+.008+n*.025,radius=.14+n*.065,vx=(n-.5)*.16,vy=.15+n*.18,
  amount=amount,heat=amount*(.6+n*.15),color={amount*.65,amount*.12,amount*.025}});self.splatCount=self.splatCount+1
end
function World:update(burns,view)
 if self.disposed then return end
 self.view={};for key,value in pairs(view)do self.view[key]=value end;self.hasScenery=false;self.burns={};local visible={};local selected=nil
 for _,original in ipairs(burns)do local b={};for key,value in pairs(original)do b[key]=value end;if b.chapter==view.chapter and valid(b)then self.burns[#self.burns+1]=b
  if b.x+b.width>view.cameraX-32 and b.x<view.cameraX+view.width+32 and b.age<18 then visible[#visible+1]=b end
 end end
 for _,b in ipairs(visible)do if b.kind=='nova'and(not selected or b.age<=selected.age)then selected=b end end
 selected=selected or visible[#visible]
 if(selected and selected.id or nil)~=(self.active and self.active.id or nil)then self.seeded=false;self.fluid:reset()end;self.active=selected
 if not selected or view.paused then return end
 local dt=clamp(view.dt or 0,0,4/60);if dt==0 then return end;self.time=self.time+dt
 if not self.seeded then for j=0,5 do self:emit(selected,j,.22)end;self.seeded=true end
 local fuel=clamp(1-selected.age/11)*clamp(selected.strength)
 if fuel>0 then for j=0,5 do self:emit(selected,j,min(.3,dt*3)*fuel)end end
 self.fluid:step(dt)
end
function World:scorch(source,view,surfaceMask)
 view=view or self.view;local w,h=view.width,view.height
 self.hasScenery=false;self.changedPixels=0;self.hotPixels=0;self.output=source
 local visible={};local x0,y0,x1,y1=w,h,0,0
 for _,b in ipairs(self.burns)do if b.x+b.width>view.cameraX and b.x<view.cameraX+w and b.y+b.height>view.ground-h and b.y<view.ground then
  visible[#visible+1]=b;x0=min(x0,max(0,floor(b.x-view.cameraX)));x1=max(x1,min(w-1,math.ceil(b.x+b.width-view.cameraX)));y0=min(y0,max(0,floor(view.ground-b.y-b.height)));y1=max(y1,min(h-1,math.ceil(view.ground-b.y)))
 end end
 if #visible==0 then return source end
 -- Only geometry/noise is cached. Age, strength and the live surface mask still
 -- participate every frame, so moving cameras and disappearing props stay exact.
 local signature={view.cameraX,view.ground,w,h}
 for bi,b in ipairs(visible)do for _,v in ipairs({b.seed,b.x,b.y,b.width,b.height})do signature[#signature+1]=v end;b.nativeIndex=bi;b.nativeGrowth=smooth(0,.6,b.age)*(b.kind=='trail'and .7 or 1);b.nativeHeat=clamp(1-b.age/11)end
 signature=table.concat(signature,':')
 if self.scorchSignature~=signature then self.scorchSignature=signature;self.scorchTerms={};self.scorchAsh={}end
 local mask=surfaceMask and C.region(surfaceMask,x0,y0,x1-x0+1,y1-y0+1,self.maskRead)or nil;self.maskRead=mask
 local bx0,by0,bx1,by1=w,h,-1,-1
 for py=y0,y1 do for px=x0,x1 do
  ---@type number
  local surface=py>=view.ground and 1 or 0
  if mask then local r,g,b,a=C.rgba(mask.pixels[(py-y0)*mask.width+px-x0+1]or 0);surface=(r+g+b)/765*a/255 end
  if surface>=.01 then bx0=min(bx0,px);by0=min(by0,py);bx1=max(bx1,px);by1=max(by1,py)end
 end end
 if bx1<bx0 then return source end
 local patch=C.region(source,bx0,by0,bx1-bx0+1,by1-by0+1,self.patch);self.patch=patch
 for py=by0,by1 do for px=bx0,bx1 do
  ---@type number
  local surface=py>=view.ground and 1 or 0
  if mask then local r,g,b,a=C.rgba(mask.pixels[(py-y0)*mask.width+px-x0+1]or 0);surface=(r+g+b)/765*a/255 end
  if surface>=.01 then local wx,wy=px+view.cameraX,view.ground-py;local char,heat,crack=0,0,0
   for _,b in ipairs(visible)do local u,v=(wx-b.x)/b.width,(wy-b.y)/b.height
    if u>=0 and u<=1 and v>=0 and v<=1 then
     local terms=self.scorchTerms[b.nativeIndex];if not terms then terms={};self.scorchTerms[b.nativeIndex]=terms end
     local at=py*w+px+1;local term=terms[at]
     if not term then local coarse=noise(floor(wx/9),floor(wy/7),b.seed);local fine=noise(floor(wx),floor(wy),b.seed);local edge=min(u,1-u,v,1-v);local vein=noise(floor(wx/3),floor(wy/3),b.seed+817)
      term={smooth(0,.10,edge+(coarse-.5)*.08),.68+fine*.26,1-smooth(0,22,abs(wy))*.67,(vein>.89 and 1 or 0)*(.5+fine*.5)};terms[at]=term
     end
     local coverage=term[1]*b.nativeGrowth*clamp(b.strength)*surface
     char=max(char,coverage*term[2]);local hot=coverage*b.nativeHeat*term[3];heat=max(heat,hot);crack=max(crack,hot*term[4])
    end
   end
   if char>.005 then local i=(py-by0)*patch.width+px-bx0+1;local r,g,b,a=C.rgba(patch.pixels[i]or 0);local lum=r*.2126+g*.7152+b*.0722;local at=py*w+px+1;local ashNoise=self.scorchAsh[at];if not ashNoise then ashNoise=noise(floor(wx/2),floor(wy/2),195)*5;self.scorchAsh[at]=ashNoise end;local ash=lum*.27+ashNoise
    patch.pixels[i]=C.color(r*(1-char)+(ash+5)*char+heat*12+crack*168,g*(1-char)+(ash*.83+2)*char+heat*3+crack*49,b*(1-char)+(ash*.79+2)*char+crack*8,a)
    self.changedPixels=self.changedPixels+1;if crack>.1 then self.hotPixels=self.hotPixels+1 end
   end
  end
 end end
 local ctx=source:getContext();ctx:save();ctx.globalCompositeOperation='copy';ctx:drawImage(patch,bx0,by0);ctx:restore();self.hasScenery=true;return source
end

function World:drawSecondary(ctx,b,x,ground,reduced)
 local fuel=clamp(1-b.age/13)*clamp(b.strength);if fuel==0 then return end
 ctx:save();ctx.globalAlpha=.8*fuel
 local function tongue(points,color)ctx.fillStyle=color;ctx:beginPath();ctx:moveTo(floor(points[1]+.5),floor(points[2]+.5));for i=3,#points,2 do ctx:lineTo(floor(points[i]+.5),floor(points[i+1]+.5))end;ctx:closePath();ctx:fill()end
 for j=0,21 do local n=noise(j,0,b.seed);local phase=reduced and .5 or(self.time*(1.4+n)+n)%1
  local w=2+noise(j,3,b.seed)*3.5;local u=(j+.13+noise(j,2,b.seed)*.74)/22;local xx=x+max(w,min(b.width-w,b.width*u))
  local hh=min(max(1,b.height-2),(8+n*24)*fuel*(.6+phase*.4));local yy=ground+(noise(j,1,b.seed)-.5)*4;local lean=reduced and 0 or math.sin(self.time*(3+n*2)+n*11)*(1+n*2.5)
  tongue({xx-w,yy+1,xx-w*.85,yy-hh*.26,xx-w*.5+lean*.4,yy-hh*.56,xx-w*.35+lean,yy-hh*.78,xx+lean*.5,yy-hh*.62,xx+lean,yy-hh,xx+w*.4+lean*.5,yy-hh*.54,xx+w,yy-hh*.2,xx+w*.6,yy+1},'#66301f')
  tongue({xx-w*.65,yy,xx-w*.4,yy-hh*.24,xx+lean*.3-w*.25,yy-hh*.52,xx+lean*.5,yy-hh*.41,xx+lean*.65,yy-hh*.72,xx+w*.5,yy-hh*.25,xx+w*.5,yy},'#c75525')
  tongue({xx-w*.3,yy,xx-w*.15,yy-hh*.18,xx+lean*.35,yy-hh*.43,xx+w*.22,yy-hh*.2,xx+w*.3,yy},'#eeb55c')
 end;ctx:restore()
end
function World:drawFire(ctx,view,source)
 view=view or self.view;self.secondaryCount=0;local b=self.active;if self.disposed or not b or b.age>=18 then return end
 local secondary={};for _,s in ipairs(self.burns)do if s.id~=b.id and s.age<18 and s.strength>0 and s.x+s.width>view.cameraX and s.x<view.cameraX+view.width and s.y+s.height>view.ground-view.height and s.y<view.ground then secondary[#secondary+1]=s end end
 table.sort(secondary,function(a,c)return a.age<c.age end)
 for i=1,min(2,#secondary)do local s=secondary[i];local left,top=floor(s.x-view.cameraX+.5),floor(view.ground-s.y-s.height+.5)
  ctx:save();ctx:beginPath();ctx:rect(left,top,math.ceil(s.width),max(0,min(math.ceil(s.height),view.ground+6-top)));ctx:clip()
  self:drawSecondary(ctx,s,left,view.ground-max(0,s.y),view.reduced);ctx:restore();self.secondaryCount=self.secondaryCount+1
 end
 local x,y,w,h=floor(b.x-view.cameraX+.5),floor(view.ground-b.y-b.height+.5),math.ceil(b.width),math.ceil(b.height)
 if x+w<0 or x>view.width then return end
 if not self.capture or self.capture.width~=w or self.capture.height~=h then self.capture=S.canvas(w,h)end
 local captureCtx=self.capture:getContext('2d');captureCtx:clearRect(0,0,w,h);local scenery=self.hasScenery and self.output or source
 if scenery then self.capture=C.region(scenery,x,y,w,h,self.capture)end
 local fire=self.fluid:render({background=self.capture,distortion=not view.reduced})
 ctx:save();ctx.globalAlpha=clamp((18-b.age)/4);ctx:beginPath();ctx:rect(x,y,w,max(0,min(h,view.ground+6-y)));ctx:clip();ctx:drawImage(fire,x,y,w,h);ctx:restore();self.frames=self.frames+1
end
function World:diagnostics()
 return{mode='cpu-source',failure=nil,activeId=self.active and self.active.id or nil,secondaryCount=self.secondaryCount,
  region=self.active and{x=self.active.x,y=self.active.y,width=self.active.width,height=self.active.height}or nil,
  changedPixels=self.changedPixels,hotPixels=self.hotPixels,frames=self.frames,splats=self.splatCount,fluid=self.fluid:diagnostics()}
end
function World:inspectField()return self.fluid:readField()end
function World:reset()self.burns={};self.active=nil;self.secondaryCount=0;self.time=0;self.seeded=false;self.scorchSignature=nil;self.fluid:reset()end
function World:dispose()if self.disposed then return end;self.disposed=true;self.fluid:dispose()end
return{load=Tech.load,actorCreate=Actor.new,worldCreate=World.new}
