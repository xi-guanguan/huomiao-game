-- Pixel Canvas2D implementation on UrhoX Images. World stays at its authored 192px density.
---@class FlameCanvasModule
---@field enableRenderer fun(renderer:table,stage:table)
---@field disposeRenderer fun(renderer:table,vg:NVGContextWrapper)
---@field flushGPU fun()
---@field region fun(canvas:FlameCanvas,x:number,y:number,w:number,h:number,out:FlameCanvas?):FlameCanvas
local C={};local floor,ceil,min,max,abs=math.floor,math.ceil,math.min,math.max,math.abs
local function pack(r,g,b,a)return floor(max(0,min(255,r))+.5)+floor(max(0,min(255,g))+.5)*256+floor(max(0,min(255,b))+.5)*65536+floor(max(0,min(255,a or 255))+.5)*16777216 end
local function rgba(p)p=p or 0;return p & 255,(p >> 8) & 255,(p >> 16) & 255,(p >> 24) & 255 end
C.color=pack;C.rgba=rgba
local colors={white=4294967295,black=4278190080,transparent=0}
function C.parse(value)
 if type(value)=='number'then return value end
 if type(value)~='string'then return 0 end
 if colors[value]then return colors[value]end
 local hex=value:match('^#(%x+)$');local p
 if hex then if #hex==3 or #hex==4 then hex=hex:gsub('(%x)','%1%1')end
  p=pack(tonumber(hex:sub(1,2),16)or 0,tonumber(hex:sub(3,4),16)or 0,tonumber(hex:sub(5,6),16)or 0,tonumber(hex:sub(7,8),16)or 255)
 else local r,g,b,a=value:match('rgba?%(([%d.]+),%s*([%d.]+),%s*([%d.]+),?%s*([%d.]*)%)');p=pack(tonumber(r)or 0,tonumber(g)or 0,tonumber(b)or 0,(tonumber(a)or 1)*255)end
 colors[value]=p;return p
end
local function mul(a,b)return{a[1]*b[1]+a[3]*b[2],a[2]*b[1]+a[4]*b[2],a[1]*b[3]+a[3]*b[4],a[2]*b[3]+a[4]*b[4],a[1]*b[5]+a[3]*b[6]+a[5],a[2]*b[5]+a[4]*b[6]+a[6]}end
local function point(t,x,y)return t[1]*x+t[3]*y+t[5],t[2]*x+t[4]*y+t[6]end
local function inverse(t)local d=t[1]*t[4]-t[2]*t[3];if d==0 then return nil end;return{t[4]/d,-t[2]/d,-t[3]/d,t[1]/d,(t[3]*t[6]-t[4]*t[5])/d,(t[2]*t[5]-t[1]*t[6])/d}end
---@class FlameCanvasContext
---@field canvas FlameCanvas
local Context={};Context.__index=Context
---@class FlameCanvas
---@field width number
---@field height number
---@field _width number
---@field _height number
---@field pixels table<number,number>
---@field nativeTexture Texture2D?
local Canvas={};Canvas.__index=Canvas
---@return FlameCanvas
function C.new(w,h)
 ---@type FlameCanvas
 local canvas=setmetatable({width=w or 300,height=h or 150,pixels={},_width=-1,_height=-1},Canvas);return canvas
end
function Canvas:ensure()if self.width~=self._width or self.height~=self._height then self._width=self.width;self._height=self.height;self.pixels={};if self.ctx then self.ctx:reset()end end end
function Canvas:getBoundingClientRect()return{width=self.width,height=self.height,left=0,top=0}end
function Canvas:getContext()if not self.ctx then self.ctx=setmetatable({canvas=self},Context);self.ctx:reset()end;self:ensure();return self.ctx end
function Context:reset()self.globalAlpha=1;self.globalCompositeOperation='source-over';self.fillStyle='#000';self.strokeStyle='#000';self.lineWidth=1;self.t={1,0,0,1,0,0};self.stack={};self.path={};self.clips={}end
local function shallow(v)local t={};for k,x in pairs(v)do t[k]=x end;return t end
function Context:save()self.stack[#self.stack+1]={alpha=self.globalAlpha,blend=self.globalCompositeOperation,fill=self.fillStyle,stroke=self.strokeStyle,line=self.lineWidth,t=shallow(self.t),clips=shallow(self.clips)}end
function Context:restore()local s=table.remove(self.stack);if not s then return end;self.globalAlpha=s.alpha;self.globalCompositeOperation=s.blend;self.fillStyle=s.fill;self.strokeStyle=s.stroke;self.lineWidth=s.line;self.t=s.t;self.clips=s.clips end
function Context:translate(x,y)self.t=mul(self.t,{1,0,0,1,x,y})end
function Context:scale(x,y)self.t=mul(self.t,{x,0,0,y,0,0})end
function Context:rotate(a)local s,c=math.sin(a),math.cos(a);self.t=mul(self.t,{c,s,-s,c,0,0})end
function Context:setTransform(a,b,c,d,e,f)self.t={a,b,c,d,e,f}end
function Context:resetTransform()self.t={1,0,0,1,0,0}end
local function inside(poly,x,y)local odd=false;local j=#poly;for i=1,#poly do local a,b=poly[i],poly[j];if(a[2]>y)~=(b[2]>y)and x<(b[1]-a[1])*(y-a[2])/(b[2]-a[2])+a[1]then odd=not odd end;j=i end;return odd end
function Context:allowed(x,y)for _,p in ipairs(self.clips)do if not inside(p,x+.5,y+.5)then return false end end;return true end
function Context:pixel(x,y,p,opacity)
 local canvas=self.canvas;if x<0 or y<0 or x>=canvas.width or y>=canvas.height or not self:allowed(x,y)then return end
 local index=y*canvas.width+x+1;local mode=self.globalCompositeOperation;local alpha=opacity or self.globalAlpha
 if alpha==1 and ((p >> 24)==255 and mode=='source-over' or mode=='copy')then canvas.pixels[index]=p;return end
 local r,g,b,a=rgba(p);a=a/255*alpha
 if mode=='copy'then canvas.pixels[index]=pack(r,g,b,a*255);return end
 local old=canvas.pixels[index]or 0;local dr,dg,db,da=rgba(old);da=da/255
 if mode=='destination-in'then canvas.pixels[index]=pack(dr,dg,db,da*a*255);return end
 if mode=='source-in'then canvas.pixels[index]=pack(r,g,b,a*da*255);return end
 if a<=0 then return end
 if mode=='lighter'then local aa=min(1,a+da);canvas.pixels[index]=pack(min(255,r*a+dr*da)/max(aa,1e-9),min(255,g*a+dg*da)/max(aa,1e-9),min(255,b*a+db*da)/max(aa,1e-9),aa*255);return end
 if mode=='multiply'then r=r*dr/255;g=g*dg/255;b=b*db/255 elseif mode=='screen'then r=255-(255-r)*(255-dr)/255;g=255-(255-g)*(255-dg)/255;b=255-(255-b)*(255-db)/255 end
 if mode=='source-atop'then canvas.pixels[index]=pack(r*a+dr*(1-a),g*a+dg*(1-a),b*a+db*(1-a),da*255);return end
 local aa=a+da*(1-a);if aa>0 then canvas.pixels[index]=pack((r*a+dr*da*(1-a))/aa,(g*a+dg*da*(1-a))/aa,(b*a+db*da*(1-a))/aa,aa*255)end
end
function Context:beginPath()self.path={};self.current=nil end
function Context:moveTo(x,y)local a,b=point(self.t,x,y);local p={{a,b}};self.path[#self.path+1]=p;self.current=p end
function Context:lineTo(x,y)if not self.current then self:moveTo(x,y);return end;local a,b=point(self.t,x,y);self.current[#self.current+1]={a,b}end
function Context:closePath()if self.current and #self.current>1 then self.current.closed=true end end
function Context:rect(x,y,w,h)self:moveTo(x,y);self:lineTo(x+w,y);self:lineTo(x+w,y+h);self:lineTo(x,y+h);self:closePath()end
function Context:ellipse(x,y,rx,ry,rotation,start,finish,ccw)
 local count=max(12,ceil(max(rx,ry)*3));for i=0,count do local a=(start or 0)+((finish or math.pi*2)-(start or 0))*i/count;local px=math.cos(a)*rx;local py=math.sin(a)*ry;local c,s=math.cos(rotation or 0),math.sin(rotation or 0);if i==0 then self:moveTo(x+px*c-py*s,y+px*s+py*c)else self:lineTo(x+px*c-py*s,y+px*s+py*c)end end
 self:closePath()
end
function Context:arc(x,y,r,start,finish,ccw)self:ellipse(x,y,r,r,0,start,finish,ccw)end
function Context:clip()for _,p in ipairs(self.path)do self.clips[#self.clips+1]=p end end
local Gradient={};Gradient.__index=Gradient
function Gradient:addColorStop(at,color)self.stops[#self.stops+1]={at,C.parse(color)};table.sort(self.stops,function(a,b)return a[1]<b[1]end)end
function Context:createLinearGradient(x0,y0,x1,y1)return setmetatable({kind='linear',x0=x0,y0=y0,x1=x1,y1=y1,inv=inverse(self.t),stops={}},Gradient)end
function Context:createRadialGradient(x0,y0,r0,x1,y1,r1)return setmetatable({kind='radial',x0=x0,y0=y0,r0=r0,x1=x1,y1=y1,r1=r1,inv=inverse(self.t),stops={}},Gradient)end
local function sample(style,x,y)
 if type(style)~='table'then return C.parse(style)end
 if style.inv then x,y=point(style.inv,x,y)end
 local t;if style.kind=='linear'then local dx,dy=style.x1-style.x0,style.y1-style.y0;t=((x-style.x0)*dx+(y-style.y0)*dy)/max(1e-9,dx*dx+dy*dy)else t=(math.sqrt((x-style.x1)^2+(y-style.y1)^2)-style.r0)/max(1e-9,style.r1-style.r0)end
 local stops=style.stops;if #stops==0 then return 0 end;if t<=stops[1][1]then return stops[1][2]end
 for i=2,#stops do if t<=stops[i][1]then local a,b=stops[i-1],stops[i];local v=(t-a[1])/max(1e-9,b[1]-a[1]);local r,g,bb,aa=rgba(a[2]);local rr,gg,bbb,aaa=rgba(b[2]);return pack(r+(rr-r)*v,g+(gg-g)*v,bb+(bbb-bb)*v,aa+(aaa-aa)*v)end end
 return stops[#stops][2]
end
function Context:fill()
 self.canvas:ensure();local style=self.fillStyle;local solid=type(style)~='table';local color=solid and C.parse(style)or nil
 for _,poly in ipairs(self.path)do
  local y0,y1=1e9,-1e9;for _,p in ipairs(poly)do y0=min(y0,p[2]);y1=max(y1,p[2])end
  for y=max(0,ceil(y0-.5)),min(self.canvas.height-1,ceil(y1-.5)-1)do
   local edges={};local fy=y+.5;local j=#poly
   for i=1,#poly do local a,b=poly[i],poly[j];if(a[2]>fy)~=(b[2]>fy)then edges[#edges+1]=(b[1]-a[1])*(fy-a[2])/(b[2]-a[2])+a[1]end;j=i end
   table.sort(edges)
   for i=1,#edges-1,2 do local left,right=max(0,ceil(edges[i]-.5)),min(self.canvas.width-1,ceil(edges[i+1]-.5)-1)
    for x=left,right do self:pixel(x,y,color or sample(style,x+.5,fy))end
   end
  end
 end
end
function Context:stroke()
 self.canvas:ensure();local width=self.lineWidth*math.sqrt(abs(self.t[1]*self.t[4]-self.t[2]*self.t[3]));local rr=max(.5,width*.5)
 for _,poly in ipairs(self.path)do for i=1,#poly-(poly.closed and 0 or 1)do local a,b=poly[i],poly[i%#poly+1];local dx,dy=b[1]-a[1],b[2]-a[2];local len=max(1e-9,dx*dx+dy*dy)
  for y=max(0,floor(min(a[2],b[2])-rr)),min(self.canvas.height-1,ceil(max(a[2],b[2])+rr))do for x=max(0,floor(min(a[1],b[1])-rr)),min(self.canvas.width-1,ceil(max(a[1],b[1])+rr))do local t=max(0,min(1,((x+.5-a[1])*dx+(y+.5-a[2])*dy)/len));if(x+.5-a[1]-t*dx)^2+(y+.5-a[2]-t*dy)^2<=rr*rr then self:pixel(x,y,sample(self.strokeStyle,x+.5,y+.5))end end end
 end end
end
function Context:fillRect(x,y,w,h)
 self.canvas:ensure();local t=self.t
 if t[2]==0 and t[3]==0 and #self.clips==0 then
  local ax,ay=point(t,x,y);local bx,by=point(t,x+w,y+h)
  local left,right=max(0,ceil(min(ax,bx)-.5)),min(self.canvas.width-1,ceil(max(ax,bx)-.5)-1)
  local top,bottom=max(0,ceil(min(ay,by)-.5)),min(self.canvas.height-1,ceil(max(ay,by)-.5)-1)
  local style=self.fillStyle;local solid=type(style)~='table';local color=solid and C.parse(style)or nil
  local mode=self.globalCompositeOperation
  if solid and self.globalAlpha==1 and(color >> 24)==255 and mode=='destination-in'then return end
  if solid and self.globalAlpha==1 and(color >> 24)==255 and mode=='source-in'then
   local pixels,width=self.canvas.pixels,self.canvas.width;local rgb=color & 0xffffff
   for yy=top,bottom do local row=yy*width;for xx=left,right do local index=row+xx+1;pixels[index]=rgb | ((pixels[index]or 0) & 0xff000000)end end;return
  end
  if solid and((color >> 24)==0 or self.globalAlpha==0)and(mode=='source-over'or mode=='source-atop'or mode=='lighter'or mode=='screen'or mode=='multiply')then return end
  local vertical=not solid and style.kind=='linear'and style.x0==style.x1 and style.inv[2]==0
  local direct=self.globalAlpha==1 and(self.globalCompositeOperation=='copy'or self.globalCompositeOperation=='source-over')
  local pixels,width=self.canvas.pixels,self.canvas.width
  for yy=top,bottom do local row=yy*width;local p=solid and color or vertical and sample(style,left+.5,yy+.5)or nil
   if direct and p and((p >> 24)==255 or self.globalCompositeOperation=='copy')then for xx=left,right do pixels[row+xx+1]=p end
   else for xx=left,right do self:pixel(xx,yy,p or sample(style,xx+.5,yy+.5))end end
  end;return
 end
 local path,current=self.path,self.current;self:beginPath();self:rect(x,y,w,h);self:fill();self.path=path;self.current=current
end
function Context:clearRect(x,y,w,h)
 self.canvas:ensure();if x==0 and y==0 and w>=self.canvas.width and h>=self.canvas.height then self.canvas.pixels={};return end
 local inv=inverse(self.t);if not inv then return end;for yy=0,self.canvas.height-1 do for xx=0,self.canvas.width-1 do local px,py=point(inv,xx+.5,yy+.5);if px>=x and py>=y and px<x+w and py<y+h and self:allowed(xx,yy)then self.canvas.pixels[yy*self.canvas.width+xx+1]=0 end end end
end
function Context:drawImage(image,...)
 self.canvas:ensure();if image.ensure then image:ensure()end
 local args={...};local sx,sy,sw,sh,dx,dy,dw,dh=0,0,image.width,image.height,0,0,image.width,image.height
 if #args==2 then dx,dy=args[1],args[2]elseif #args==4 then dx,dy,dw,dh=table.unpack(args)elseif #args==8 then sx,sy,sw,sh,dx,dy,dw,dh=table.unpack(args)else error('drawImage argument count '..#args)end
 if not dw or dw==0 or dh==0 then return end
 local inv=inverse(self.t);if not inv then return end
 local x0,y0=point(self.t,dx,dy);local x1,y1=point(self.t,dx+dw,dy+dh);local x2,y2=point(self.t,dx+dw,dy);local x3,y3=point(self.t,dx,dy+dh)
 local pixels=image.pixels;if image==self.canvas then pixels=shallow(pixels)end
 if self.t[2]==0 and self.t[3]==0 and #self.clips==0 then
  local left,right=max(0,floor(min(x0,x1))),min(self.canvas.width-1,ceil(max(x0,x1))-1)
  local top,bottom=max(0,floor(min(y0,y1))),min(self.canvas.height-1,ceil(max(y0,y1))-1)
  local columns={};for x=left,right do local u=((x+.5-self.t[5])/self.t[1]-dx)/dw;if u>=0 and u<1 then local ix=floor(sx+u*sw);if ix>=0 and ix<image.width then columns[x]=ix end end end
  local target,width=self.canvas.pixels,self.canvas.width;local direct=self.globalAlpha==1;local mode=self.globalCompositeOperation
  for y=top,bottom do local v=((y+.5-self.t[6])/self.t[4]-dy)/dh;if v>=0 and v<1 then local iy=floor(sy+v*sh);if iy>=0 and iy<image.height then local row=iy*image.width;local dest=y*width
   for x=left,right do local ix=columns[x];if ix then local p=pixels[row+ix+1]or 0;local alpha=p >> 24
    if direct and(mode=='copy'or mode=='source-over'and(alpha==255 or not target[dest+x+1]or target[dest+x+1]==0))then target[dest+x+1]=p
    elseif alpha>0 or mode=='destination-in'or mode=='source-in'then self:pixel(x,y,p)end
   end end
  end end end;return
 end
 for y=max(0,floor(min(y0,y1,y2,y3))),min(self.canvas.height-1,ceil(max(y0,y1,y2,y3))-1)do for x=max(0,floor(min(x0,x1,x2,x3))),min(self.canvas.width-1,ceil(max(x0,x1,x2,x3))-1)do
  local u,v=point(inv,x+.5,y+.5);u=(u-dx)/dw;v=(v-dy)/dh;if u>=0 and v>=0 and u<1 and v<1 then local ix,iy=floor(sx+u*sw),floor(sy+v*sh);if ix>=0 and iy>=0 and ix<image.width and iy<image.height then self:pixel(x,y,pixels[iy*image.width+ix+1]or 0)end end
 end end
end
function Context:createImageData(w,h)local data={};for i=1,w*h*4 do data[i]=0 end;return{width=w,height=h,data=data}end
function Context:getImageData(x,y,w,h)self.canvas:ensure();local out=self:createImageData(w,h);for yy=0,h-1 do for xx=0,w-1 do local r,g,b,a=rgba(self.canvas.pixels[(y+yy)*self.canvas.width+x+xx+1]);local i=(yy*w+xx)*4;out.data[i+1]=r;out.data[i+2]=g;out.data[i+3]=b;out.data[i+4]=a end end;return out end
function Context:putImageData(data,x,y)self.canvas:ensure();for yy=0,data.height-1 do for xx=0,data.width-1 do local i=(yy*data.width+xx)*4;self.canvas.pixels[(y+yy)*self.canvas.width+x+xx+1]=pack(data.data[i+1]or 0,data.data[i+2]or 0,data.data[i+3]or 0,data.data[i+4]or 0)end end end
local imageCache={}
function C.load(path)
 path=path:gsub('^%./',''):gsub('^/',''):gsub('^assets/','');if imageCache[path]then return imageCache[path]end
 local resource=cache:GetResource('Image',path);assert(resource,'Image missing: '..path);local canvas=C.new(resource.width,resource.height);canvas:ensure();for y=0,canvas.height-1 do for x=0,canvas.width-1 do canvas.pixels[y*canvas.width+x+1]=resource:GetPixelInt(x,y)end end
 canvas.naturalWidth=canvas.width;canvas.naturalHeight=canvas.height;canvas.resourcePath=path;imageCache[path]=canvas;return canvas
end
function C.json(path)local normalized=path:gsub('^%./',''):gsub('^/',''):gsub('^assets/','');local resource=cache:GetResource('JSONFile',normalized);assert(resource,'JSON missing: '..path);return cjson.decode(resource:ToString(''))end
function C.upload(canvas,vg)
 canvas:ensure();if not canvas.texture or canvas.uploadW~=canvas.width or canvas.uploadH~=canvas.height then
  if canvas.handle then nvgDeleteVideo(vg,canvas.handle)end
  canvas.native=Image:new();assert(canvas.native:SetSize(canvas.width,canvas.height,4));canvas.texture=Texture2D:new();canvas.texture:SetNumLevels(1);canvas.texture:SetFilterMode(FILTER_NEAREST);canvas.uploadW=canvas.width;canvas.uploadH=canvas.height;canvas.handle=nil
 end
 for y=0,canvas.height-1 do for x=0,canvas.width-1 do canvas.native:SetPixelInt(x,y,canvas.pixels[y*canvas.width+x+1]or 0)end end
 assert(canvas.texture:SetData(canvas.native,true),'pixel upload failed');if not canvas.handle then canvas.handle=nvgCreateVideo(vg,canvas.texture);assert(canvas.handle>0,'NanoVG image upload failed')end;return canvas.handle
end
function C.dispose(canvas,vg)if canvas.handle then nvgDeleteVideo(vg,canvas.handle);canvas.handle=nil end;canvas.texture=nil;canvas.native=nil;canvas.pixels={}end
require('platform.gpu-canvas').install(C)
return C
