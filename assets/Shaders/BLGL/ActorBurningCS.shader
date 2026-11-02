// Translated from h5/src/techart/actor-burning.ts; original fragment math.
shader_type compute;
workgroup_size(8,8,1);
uniform sampler2D sprite : filter_nearest, repeat_disable;
uniform sampler2D detail : filter_linear, repeat_enable;
uniform sampler2D flow : filter_linear, repeat_enable;
uniform sampler2D fireGradient : filter_linear, repeat_enable;
uniform vec2 atlasSize;
uniform vec4 frame;
uniform vec2 outputSize;
uniform float padding;
uniform float cutY;
uniform float headOnly;
uniform vec2 head;
uniform vec4 state; // breath, fury, light, pulse
uniform float time;
uniform float enemy;
uniform float extinguish;
uniform vec3 mounts[6]; // x, y, exists after clipping

uniform writeonly image2D result : format_rgba8;
vec4 bodyAt(vec2 p){
 if(p.x<0.||p.y<0.||p.x>=frame.z||p.y>=frame.w||p.y>cutY)return vec4(0);
 if(headOnly>.5&&abs(p.x-head.x)>7.)return vec4(0);
 return max(textureLod(sprite,(frame.xy+(floor(p)+.5))/atlasSize,0.),vec4(0));
}
vec3 palette(float x){
 vec3 low=vec3(.59,.10,.018),mid=vec3(1.,.40,.055),hot=vec3(1.,.92,.65);
 return x<.55?mix(low,mid,x/.55):mix(mid,hot,clamp((x-.55)/.45,0.,1.));
}
void compute(){
 vec2 uv=(vec2(GLOBAL_INVOCATION_ID.xy)+vec2(.5))/vec2(DISPATCH_SIZE.xy);
 vec4 color=vec4(0);
 vec2 p=floor(uv*outputSize)-padding;
 vec4 tex=bodyAt(p);float alpha=tex.a;
 float fuel=clamp(.18+state.x*.55+state.y*.25+state.w*.20,0.,1.);
 if(enemy>0.)fuel=clamp(enemy*.6,0.,1.);
 fuel*=1.-extinguish;
 vec2 f=textureLod(flow,p*.013+vec2(time*.016,-time*.028),0.).rg*2.-1.;
 vec2 drift=vec2(p.x*.037+f.x*.17,p.y*.028+time*.72+f.y*.11);
 float n=textureLod(detail,drift,0.).r;
 float n2=textureLod(detail,drift*2.31+vec2(time*.12,0),0.).r;
 float exposed=max(0.,alpha-min(bodyAt(p+vec2(-1,0)).a,min(bodyAt(p+vec2(1,0)).a,bodyAt(p+vec2(0,-1)).a)));
 float seed=0.;
 for(int i=0;i<6;i++){
  vec2 d=p-mounts[i].xy;d.y*=.7;
  float radius=i==0?8.:i==1?10.:6.;
  seed=max(seed,mounts[i].z*bodyAt(mounts[i].xy).a*max(0.,1.-length(d)/radius));
 }
 // Follow actual alpha upstream. The original flow-map and dual-advection detail cause
 // tongues to shear and break apart, rather than moving a static flame polygon.
 float plume=0.;
 for(int j=1;j<=7;j++){
  float rise=float(j)*(1.5+fuel*1.65);
  vec2 origin=p+vec2(f.x*rise*.35+(n-.5)*rise*.40,rise);
  float a=bodyAt(origin).a;
  float ridge=max(0.,a-bodyAt(origin+vec2(0,-3)).a*.78);
  plume=max(plume,ridge*(1.-float(j)/8.));
 }
 float outer=clamp((plume*(.6+fuel*.75)+seed*.12)*(n*.8+n2*.5)-.15,0.,1.);
 outer*=(1.-alpha)*(1.-extinguish);
 float flame=clamp(outer*(2.+fuel*1.4),0.,1.);
 float luminosity=dot(tex.rgb,vec3(.2126,.7152,.0722));
 // Entity Color's source interpolation, then localized heat. Preserve dark anatomy.
 vec3 charred=tex.rgb+(.27+fuel*.14)*(vec3(luminosity*.30+.025,luminosity*.22+.018,luminosity*.18+.014)-tex.rgb);
 float crack=pow(clamp((n2-.73)*5.,0.,1.),2.)*alpha*(.13+fuel*.45);
 float bodyGlow=(exposed*.17+seed*.06+crack)*fuel;
 vec3 bodyColor=charred+palette(.72)*bodyGlow;
 bodyColor=mix(bodyColor,vec3(1.,.82,.50),state.w*.20*alpha);
 float gradient=textureLod(fireGradient,vec2(clamp(flame*(.35+fuel),0.,1.),.5),0.).r;
 vec3 flameColor=palette(clamp(flame*.88+gradient*.12,0.,1.));
 float outAlpha=clamp(alpha+flame*.92,0.,1.);
 
 if(outAlpha>=.015)color=vec4((bodyColor*alpha+flameColor*flame*.92)/max(outAlpha,.001),outAlpha);
 imageStore(result,ivec2(GLOBAL_INVOCATION_ID.xy),color);
}