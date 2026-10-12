@group(0) @binding(0) var<storage,read_write> stats:array<u32>;
@compute @workgroup_size(128) fn main(@builtin(global_invocation_id) g:vec3<u32>){let p=g.x+g.y*4194304u;if(p<