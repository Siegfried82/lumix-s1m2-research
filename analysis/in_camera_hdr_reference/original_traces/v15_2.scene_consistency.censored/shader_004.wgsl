@group(0) @binding(0) var<storage,read> labels:array<u32>;
@group(0) @binding(1) var<storage,read> field:array<f32>;
@group(0) @binding(2) var<storage,read> decision:array<f32>;
@group(0) @binding(3) var<storage,read_write> errors:array<atomic<u32>>;
fn val(x:u32,y:u32)->f32{return field[