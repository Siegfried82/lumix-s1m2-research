@group(0) @binding(0) var<storage,read> extended:array<u32>;
@group(0) @binding(1) var<storage,read_write> mask:array<f32>;
@compute @workgroup_size(128) fn main(@builtin(global_invocation_id) gid:vec3<u32>){let i=gid.x+gid.y*4194304u;if(i>=