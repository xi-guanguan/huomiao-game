-- Scalar CPU translation of the existing Nocturnal/Fluxy single-container passes.
-- Sources: h5/src/fluid/shaders/{splat-0,1,simulation-0..7,11..13,mist*}.
-- No new emitter replaces the solver. All fields retain all RGBA channels.
-- Intentional platform difference: Lua numeric fields, rather than RGBA16F storage.
local C=require('platform.canvas')
local S=require('platform.techart-sampling')
local clamp,fract=S.clamp,S.fract
local floor,min,max,abs,sqrt=math.floor,math.min,math.max,math.abs,math.sqrt
---@class FlameScalarFluid
---@field width number
---@field height number
---@field n number
---@field velocityA FlameFluidField
---@field velocityB FlameFluidField
---@field stateA FlameFluidField
---@field stateB FlameFluidField
---@field textures table<string,any>
---@field options table<string,any>
---@field flowR table<number,number>
---@field flowG table<number,number>
---@field flowA table<number,number>
---@field left table<number,number>
---@field right table<number,number>
---@field up table<number,number>
---@field down table<number,number>
---@field insideL table<number,number>
---@field insideR table<number,number>
---@field insideU table<number,number>
---@field insideD table<number,number>
---@field kernelX table<number,table<number,number>>
---@field kernelY table<number,table<number,number>>
---@field canvas FlameCanvas
local F={};F.__index=F
---@return FlameFluidField
local function field(n)local f={r={},g={},b={},a={}};for i=1,n do f.r[i]=0;f.g[i]=0;f.b[i]=0;f.a[i]=0 end;return f end
local function bilinear4(src,w,h,x,y)
 local ix,iy=floor(x),floor(y);local fx,fy=x-ix,y-iy
 local x0,x1=max(0,min(w-1,ix)),max(0,min(w-1,ix+1));local y0,y1=max(0,min(h-1,iy)),max(0,min(h-1,iy+1))
 local i0,i1,i2,i3=y0*w+x0+1,y0*w+x1+1,y1*w+x0+1,y1*w+x1+1
 local p,q,r,s=(1-fx)*(1-fy),fx*(1-fy),(1-fx)*fy,fx*fy
 if ix<0 or ix>=w then p=0;r=0 end;if ix+1<0 or ix+1>=w then q=0;s=0 end
 if iy<0 or iy>=h then p=0;q=0 end;if iy+1<0 or iy+1>=h then r=0;s=0 end
 local a,b,c,d=src.r,src.g,src.b,src.a
 return a[i0]*p+a[i1]*q+a[i2]*r+a[i3]*s,b[i0]*p+b[i1]*q+b[i2]*r+b[i3]*s,c[i0]*p+c[i1]*q+c[i2]*r+c[i3]*s,d[i0]*p+d[i1]*q+d[i2]*r+d[i3]*s
end
function F.new(opts)
 opts=opts or {};local w,h=opts.width or 192,opts.height or 108
 assert(w==floor(w)and h==floor(h)and w>=8 and h>=8 and w<=1024 and h<=1024,'Invalid fluid grid')
 local base=(opts.base or 'assets/round4/techart/mist/'):gsub('/*$','/')
 local names={detail='mist-details',gradient='mist-gradient2',flow='flowmap',fire='mistfire-gradient',splat='SplatTexture'}
 local textures={};for key,name in pairs(names)do local im=C.load(base..name..'.png');textures[key]=S.texture(im,true,key=='detail'or key=='flow',key=='detail'or key=='flow',true)end
 local self=setmetatable({width=w,height=h,n=w*h,textures=textures,canvas=S.canvas(w,h),time=0,steps=0,drawCalls=0,disposed=false,
  velocityA=field(w*h),velocityB=field(w*h),stateA=field(w*h),stateB=field(w*h),
  options={dissipation=.92,turbulence=8,viscosity=.2,buoyancy=.32,pressure=.8,flowWeight=.2,flowScale=.11,boundary='closed',
   opacity=.87,detailAdvection=.65,distortion=.18,color={.29,.12,.055},shadows={.025,.018,.015,.22},backgroundColor={.72,.46,.28},fireIntensity=1.65}},F)
 self.left={};self.right={};self.down={};self.up={};self.insideL={};self.insideR={};self.insideD={};self.insideU={}
 self.flowR={};self.flowG={};self.flowA={};self.kernelX={};self.kernelY={}
 for x=0,w-1 do local taps={};for k=1,6 do taps[k*2-1]=max(0,x-k)+1;taps[k*2]=min(w-1,x+k)+1 end;self.kernelX[x+1]=taps end
 for y=0,h-1 do local taps={};for k=1,6 do taps[k*2-1]=max(0,y-k)*w;taps[k*2]=min(h-1,y+k)*w end;self.kernelY[y+1]=taps end
 for y=0,h-1 do for x=0,w-1 do local i=y*w+x+1
  self.left[i]=y*w+max(0,x-1)+1;self.right[i]=y*w+min(w-1,x+1)+1
  self.down[i]=max(0,y-1)*w+x+1;self.up[i]=min(h-1,y+1)*w+x+1
  self.insideL[i]=x>0 and 1 or 0;self.insideR[i]=x<w-1 and 1 or 0;self.insideD[i]=y>0 and 1 or 0;self.insideU[i]=y<h-1 and 1 or 0
  local r,g,_,a=S.sample(textures.flow,(x+.5)/w,(y+.5)/h);self.flowR[i]=r;self.flowG[i]=g;self.flowA[i]=a
 end end
 self:reset();return self
end
function F:ensure()assert(not self.disposed,'Fluid instance disposed')end
function F:reset(density)
 self:ensure();density=clamp(density or 0)
 for i=1,self.n do for _,v in ipairs({self.velocityA,self.velocityB})do v.r[i]=0;v.g[i]=0;v.b[i]=0;v.a[i]=0 end
  for _,v in ipairs({self.stateA,self.stateB})do v.r[i]=0;v.g[i]=.6;v.b[i]=.66;v.a[i]=density end
 end
 self.time=0;self.steps=0
end
function F:splat(s)
 self:ensure();if not s.radius or s.radius<=0 then return end
 local w,h=self.width,self.height;local r=clamp(s.radius,.004,.5);local rx=r*h/w
 local x0,x1=max(0,floor((s.x-rx)*w)),min(w-1,math.ceil((s.x+rx)*w)-1)
 local y0,y1=max(0,floor((s.y-r)*h)),min(h-1,math.ceil((s.y+r)*h)-1)
 local color=s.color or{0,.6,.66};local amount=max(0,s.amount or 1);local heat=max(0,s.heat or color[1]);local st,v=self.stateA,self.velocityA
 for y=y0,y1 do for x=x0,x1 do local u=((x+.5)/w-s.x)/(rx*2)+.5;local vv=((y+.5)/h-s.y)/(r*2)+.5
  local rr,gg,bb,aa=S.sample(self.textures.splat,u,vv);local i=y*w+x+1
  if s.erase then local k=1-aa*clamp(amount);st.r[i]=st.r[i]*k;st.g[i]=st.g[i]*k;st.b[i]=st.b[i]*k;st.a[i]=st.a[i]*k
  else local noise=.15*(S.red(self.textures.detail,(u+self.time/20*.2)*2,(vv+self.time/20*.2)*2)-1)+1
   st.r[i]=st.r[i]+rr*heat*noise;st.g[i]=st.g[i]+gg*color[2]*noise;st.b[i]=st.b[i]+bb*color[3]*noise;st.a[i]=st.a[i]+aa*amount*noise
  end
  if(s.vx or 0)~=0 or(s.vy or 0)~=0 then
   -- Original splat-1: alpha-gradient, neutral velocity map, zero angular/noise strength.
   local tw,th=self.textures.splat.width,self.textures.splat.height
   local _,_,_,al=S.sample(self.textures.splat,u-1/tw,vv);local _,_,_,ar=S.sample(self.textures.splat,u+1/tw,vv)
   local _,_,_,ad=S.sample(self.textures.splat,u,vv-1/th);local _,_,_,au=S.sample(self.textures.splat,u,vv+1/th)
   local vx=aa*(s.vx or 0)-(ar-al)*.5;local vy=aa*(s.vy or 0)-(au-ad)*.5
   v.r[i]=vx*aa+v.r[i]*(1-aa);v.g[i]=vy*aa+v.g[i]*(1-aa)
  end
 end end
 self.drawCalls=self.drawCalls+1+(((s.vx or 0)~=0 or(s.vy or 0)~=0)and 1 or 0)
end
local function advect(src,dst,velocity,w,h,dt,wrap)
 for y=0,h-1 do for x=0,w-1 do local i=y*w+x+1;local px,py=x-velocity.r[i]*dt*w,y-velocity.g[i]*dt*h
  dst.r[i],dst.g[i],dst.b[i],dst.a[i]=bilinear4(src,w,h,px,py)
 end end
end
local weights={-.36519596,-.23187989,-.145295888,-.0881648734,-.0518487282,-.0290646255}
function F:substep(dt)
 local w,h,n,o=self.width,self.height,self.n,self.options;local va,vb,sa,sb=self.velocityA,self.velocityB,self.stateA,self.stateB
 local wrap=o.boundary=='repeat';assert(not wrap,'This single-container translation currently supports the authored closed boundary')
 -- simulation-13: flow-map relaxation, including the source alpha.
 if o.flowWeight>0 then for i=1,n do local r,g,a=self.flowR[i],self.flowG[i],self.flowA[i]
   if r*r+g*g>0 then local v=o.flowWeight*dt;va.r[i]=(va.r[i]+v*((r*2-1)*o.flowScale-va.r[i]))*a;va.g[i]=(va.g[i]+v*((g*2-1)*o.flowScale-va.g[i]))*a end
  end;self.drawCalls=self.drawCalls+2 end
 -- simulation-0 (Adhesion=0 => its alpha-dependent multiplier is exactly 1), then -1.
 advect(sa,sb,va,w,h,dt,wrap);advect(va,vb,va,w,h,dt,wrap)
 -- simulation-2: RGB subtracts the ORIGINAL red channel, not each component.
 for i=1,n do local red=sb.r[i]*dt;sa.r[i]=clamp(sb.r[i]-red);sa.g[i]=clamp(sb.g[i]-red);sa.b[i]=clamp(sb.b[i]-red)
  local a=sb.a[i];local dissip=o.dissipation>0 and(1-a)^2*o.dissipation or a*o.dissipation;sa.a[i]=clamp(a-dt*dissip)
 end
 local left,right,down,up=self.left,self.right,self.down,self.up
 local ml,mr,md,mu=self.insideL,self.insideR,self.insideD,self.insideU
 for i=1,n do
  -- simulation-3's source curl has the documented PLUS convention.
  va.r[i]=vb.r[i];va.g[i]=vb.g[i];va.a[i]=vb.a[i];va.b[i]=.5*(vb.g[right[i]]-vb.g[left[i]]+vb.r[up[i]]-vb.r[down[i]])
  -- simulation-4: normalized density gradient in RG, preserve the advected BA.
  local dx=(sa.a[right[i]]*mr[i]-sa.a[left[i]]*ml[i])*w
  local dy=(sa.a[up[i]]*mu[i]-sa.a[down[i]]*md[i])*h;local inv=1/sqrt(dx*dx+dy*dy+1)
  sb.r[i]=-dx*inv;sb.g[i]=-dy*inv
 end
 -- simulation-12: vorticity + density buoyancy + viscosity. SurfaceTension/NormalScale/ExternalForce are authored zero.
 local viscosity=math.exp(-max(0,o.viscosity)*dt)
 for i=1,n do local gx=.5*(abs(va.b[down[i]])-abs(va.b[up[i]]));local gy=.5*(abs(va.b[right[i]])-abs(va.b[left[i]]));local len=sqrt(gx*gx+gy*gy)
  local force=len>.001 and va.b[i]*o.turbulence/len or 0
  vb.r[i]=va.r[i]*viscosity+gx*force*dt;vb.g[i]=va.g[i]*viscosity+(gy*force+o.buoyancy*sb.a[i])*dt;vb.b[i]=va.b[i];vb.a[i]=va.a[i]
 end
 -- simulation-5: signed divergence, zero contribution beyond the container.
 for i=1,n do va.r[i]=vb.r[i];va.g[i]=vb.g[i];va.a[i]=vb.a[i]
  va.b[i]=-.5*(vb.r[right[i]]*mr[i]-vb.r[left[i]]*ml[i]+vb.g[up[i]]*mu[i]-vb.g[down[i]]*md[i])
  -- simulation-11: xyzz.
  vb.r[i]=va.r[i];vb.g[i]=va.g[i];vb.b[i]=va.b[i];vb.a[i]=va.b[i]
 end
 -- simulation-6: exact 13-tap separable convolution, clamped texture samples.
 for y=0,h-1 do for x=0,w-1 do local i=y*w+x+1;local sum=vb.a[i]*-.578437209
  local taps,row=self.kernelX[x+1],y*w;for k=1,6 do sum=sum+weights[k]*(vb.a[row+taps[k*2-1]]+vb.a[row+taps[k*2]])end
  va.a[i]=sum
 end end
 for y=0,h-1 do for x=0,w-1 do local i=y*w+x+1;local sum=va.a[i]*-.578437209
  local taps=self.kernelY[y+1];for k=1,6 do sum=sum+weights[k]*(va.a[taps[k*2-1]+x+1]+va.a[taps[k*2]+x+1])end
  vb.a[i]=sum
 end end
 -- simulation-7: ADD the pressure gradient, retaining va.BA as the GL color blend does.
 for i=1,n do va.r[i]=va.r[i]-.5*o.pressure*(vb.a[right[i]]-vb.a[left[i]]);va.g[i]=va.g[i]-.5*o.pressure*(vb.a[up[i]]-vb.a[down[i]])end
 self.time=self.time+dt;self.steps=self.steps+1;self.drawCalls=self.drawCalls+11
end
function F:step(dt)
 self:ensure();if not dt or dt~=dt or dt<=0 then return end
 local remaining=min(dt,4/60);while remaining>1e-7 do local part=min(remaining,1/60);self:substep(part);remaining=remaining-part end
end
function F:render(opts)
 self:ensure();opts=opts or {};local w,h=self.width,self.height;local sa,v,o=self.stateA,self.velocityA,self.options
 local out=self.canvas;out:ensure();local pixels=out.pixels;local tx=self.textures
 local t0,t1=fract(self.time),fract(self.time+.5);local blend=abs(t0*2-1);local advection=o.detailAdvection*2
 local background=opts.background and S.texture(opts.background,true,false,false,true,true)or nil
 local distort=opts.distortion~=false
 for y=0,h-1 do for x=0,w-1 do local i=y*w+x+1;local u,vv=(x+.5)/w,(y+.5)/h;local vx,vy=v.r[i],v.g[i]
  local n0=S.red(tx.detail,u*2-vx*t0*advection,vv*2-vy*t0*advection);local n1=S.red(tx.detail,u*2-vx*t1*advection,vv*2-vy*t1*advection)
  local gr,gg,gb,ga=S.sample(tx.gradient,sa.a[i]*(n0+(n1-n0)*blend),.5)
  local rr,g,b,a=sa.r[i]*gr,sa.g[i]*gg,sa.b[i]*gb,sa.a[i]*ga
  local shadow=v.a[i]*o.shadows[4];rr=rr+shadow*o.shadows[1];g=g+shadow*o.shadows[2];b=b+shadow*o.shadows[3]
  rr,g,b=rr*a,g*a,b*a
  local edgeX=max(0,(abs(u-.5)*2-.88)/.12);local edgeY=max(0,(abs(vv-.5)*2-.88)/.12);local edge=max(0,1-sqrt(edgeX*edgeX+edgeY*edgeY))
  a=a*clamp(2-a)*edge;rr,g,b=max(0,rr*edge),max(0,g*edge),max(0,b*edge)
  local alpha=a*o.opacity;local packed=0
  if alpha>=.1 then
   rr,g,b=rr+.05,g+.05,b+.05
   if distort then
    local flow=S.red(tx.flow,u+self.time/20*1.1,vv+self.time/20*.9)
    local offset=((flow*2-1)*o.distortion*.005+vx*o.distortion*.15)*a
    local br,bg,bb=.04,.06,.08;if background then br,bg,bb=S.sample(background,u+offset,vv+offset)end
    local pr,pg,pb=(br+.23)^5*.9,(bg+.23)^5*.9,(bb+.23)^5*.9
    local cr,cg,cb=rr*o.color[1],g*o.color[2],b*o.color[3]
    local mr0=1-(cr+(sa.r[i]-cr)*.8)^2;local mg=1-(cg+(sa.g[i]-cg)*.8)^2;local mb=1-(cb+(sa.b[i]-cb)*.8)^2
    local norm=mr0*mr0+mg*mg+mb*mb;local factor=max(norm*sqrt(norm),1-alpha)
    local xr,xg,xb=max(factor*pr,cr)*o.backgroundColor[1],max(factor*pg,cg)*o.backgroundColor[2],max(factor*pb,cb)*o.backgroundColor[3]
    local density=min(sa.a[i],.2);xr=xr+density*(cr*cr-xr);xg=xg+density*(cg*cg-xg);xb=xb+density*(cb*cb-xb)
    local fire=clamp(sa.a[i]*sa.r[i]);local fr,fg,fb=S.sample(tx.fire,fire,.5)
    rr=xr+fire*(fr*o.fireIntensity-xr);g=xg+fire*(fg*o.fireIntensity-xg);b=xb+fire*(fb*o.fireIntensity-xb)
   end
   packed=C.color(clamp(rr,0,1)*255,clamp(g,0,1)*255,clamp(b,0,1)*255,clamp(alpha)*255)
  end
  -- Field bottom-up => visible Canvas top-down, matching WebGL's canvas output.
  pixels[(h-1-y)*w+x+1]=packed
 end end
 self.drawCalls=self.drawCalls+1;return out
end
function F:readField(which)
 local f=which=='velocity'and self.velocityA or self.stateA;local out={}
 for i=1,self.n do local p=(i-1)*4;out[p+1]=f.r[i];out[p+2]=f.g[i];out[p+3]=f.b[i];out[p+4]=f.a[i]end;return out
end
function F:diagnostics()
 return{width=self.width,height=self.height,format='CPU numbers (source RGBA16F)',pressureMode='convolution',steps=self.steps,time=self.time,drawCalls=self.drawCalls,mode='cpu-source',glError=nil}
end
function F:dispose()self.disposed=true end
return F
