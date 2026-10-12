@group(0) @binding(0) var<storage,read> stats:array<u32>;
@group(0) @binding(1) var<storage,read_write> dst:array<f32>;
fn number(j:u32)->f32{return f32(stats[j])+4294967296.*f32(stats[j+1u]);}
@compute @workgroup_size(128) fn main(@builtin(global_invocation_id) g:vec3<u32>){let p=g.x+g.y*4194304u;if(p>=