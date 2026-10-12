u+x];}
fn add64(j:u32,v:u32){let old=atomicAdd(&errors[j],v);if(old>0xffffffffu-v){atomicAdd(&errors[j+1u],1u);}}
@compute @workgroup_size(128) fn main(@builtin(global_invocation_id) g:vec3<u32>){let p=g.x+g.y*4194304u;if(p>=