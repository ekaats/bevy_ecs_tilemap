#version 450

layout(location = 0) in vec3 Vertex_Position;
layout(location = 1) in ivec4 Vertex_Texture;

layout(location = 0) out vec2 v_Uv;

layout(set = 0, binding = 0) uniform CameraViewProj {
    mat4 ViewProj;
};

layout(set = 2, binding = 0) uniform Transform {
    mat4 Model;
};

layout(set = 2, binding = 1) uniform TilemapData {
    vec2 texture_size;
    vec2 tile_size;
    vec2 spacing;
    float time;
};

void main() {
    vec2 uv = vec2(0.0);
    vec2 position = Vertex_Position.xy;
    
    vec2 positions[4] = vec2[4](
        vec2(position.x, position.y),
        vec2(position.x, position.y + 1.0),
        vec2(position.x + 1.0, position.y + 1.0),
        vec2(position.x + 1.0, position.y)
    );

    position = positions[gl_VertexIndex % 4];
    position.xy *= tile_size;

    float frames = float(Vertex_Texture.w - Vertex_Texture.z);

    float current_animation_frame = fract(time * Vertex_Position.z) * frames;

    current_animation_frame = clamp(current_animation_frame, float(Vertex_Texture.z), float(Vertex_Texture.w));

    int texture_index = int(current_animation_frame);
    
    int columns = int(texture_size.x) / int(tile_size.x);

    float sprite_sheet_x = floor(float(texture_index % columns)) * (tile_size.x + spacing.x) - spacing.x;
    float sprite_sheet_y = floor((texture_index / columns)) * (tile_size.y + spacing.y) - spacing.y;

    float start_u = sprite_sheet_x / texture_size.x;
    float end_u = (sprite_sheet_x + tile_size.x) / texture_size.x;
    float start_v = sprite_sheet_y / texture_size.y;
    float end_v = (sprite_sheet_y + tile_size.y) / texture_size.y;

    vec2 atlas_uvs[4];
    
    // Texture flipping..
    if (Vertex_Texture.y == 0) {
        atlas_uvs = vec2[4](
            vec2(start_u, end_v),
            vec2(start_u, start_v),
            vec2(end_u, start_v),
            vec2(end_u, end_v)
        );
    } else if (Vertex_Texture.y == 1) { // flip x
        atlas_uvs = vec2[4](
            vec2(end_u, end_v),
            vec2(end_u, start_v),
            vec2(start_u, start_v),
            vec2(start_u, end_v)
        );
    } else if(Vertex_Texture.y == 2) { // flip y
        atlas_uvs = vec2[4](
            vec2(start_u, start_v),
            vec2(start_u, end_v),
            vec2(end_u, end_v),
            vec2(end_u, start_v)
        );
    } else if(Vertex_Texture.y == 3) { // both
        atlas_uvs = vec2[4](
            vec2(end_u, start_v),
            vec2(end_u, end_v),
            vec2(start_u, end_v),
            vec2(start_u, start_v)
        );
    }

    v_Uv = atlas_uvs[gl_VertexIndex % 4];
    v_Uv += 1e-5;
    gl_Position = ViewProj * Model * vec4(position, 0.0, 1.0);
}