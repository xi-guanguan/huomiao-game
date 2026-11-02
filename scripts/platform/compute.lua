-- Official UrhoX ComputeDispatch. Dispatches are submitted only from Update.
local C=require('platform.canvas');local N={}
function N.supported()return not(HUOMIAO_TEST_MODE and HUOMIAO_NO_COMPUTE)and graphics and graphics.GetComputeShaderSupport and graphics:GetComputeShaderSupport()end
function N.new(name)
 assert(N.supported(),'Compute is unavailable on this device')
 local job=ComputeDispatch:new();assert(job:SetShader('Shaders/BLGL/'..name..'CS.shader'),job:GetLastError());return job
end
function N.set(job,name,value)assert(job:SetShaderParameter(name,value),job:GetLastError())end
function N.bind(job,name,texture)assert(job:SetTexture(name,texture),job:GetLastError())end
function N.texture(canvas)
 if canvas.nativeTexture then return canvas.nativeTexture end
 if canvas.resourcePath then return assert(cache:GetResource('Texture2D',canvas.resourcePath))end
 if not canvas.computeImage then canvas.computeImage=Image:new();canvas.computeTexture=Texture2D:new()end
 assert(canvas.computeImage:SetSize(canvas.width,canvas.height,4));for y=0,canvas.height-1 do for x=0,canvas.width-1 do canvas.computeImage:SetPixelInt(x,y,canvas.pixels[y*canvas.width+x+1]or 0)end end
 assert(canvas.computeTexture:SetData(canvas.computeImage,true));return canvas.computeTexture
end
function N.output(job,w,h)
 ---@type FlameCanvas
 local canvas=C.new(w,h);canvas:ensure();canvas.nativeTexture=assert(job:CreateImage2D('result',w,h),job:GetLastError());canvas.nativeTexture:SetFilterMode(FILTER_NEAREST);return canvas
end
return N
