shader_type canvas_item;

// Parámetros controlables desde el Inspector
uniform float intensity : hint_range(0.0, 1.0) = 0.5;
uniform float pixel_size : hint_range(0.001, 4.0, 0.005) = 0.05;
uniform float random_strength : hint_range(0.0, 100.0) = 43.75;
uniform float alpha: hint_range(0.0, 1.0) = 1.0;

float random(vec2 uv) {
    // El valor de random_strength altera la semilla del ruido, cambiando su patrón
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * (random_strength * 1000.0));
}

void fragment() {
    // 1. Conseguimos el tamaño de la textura en píxeles
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    
    // 2. Pixelamos las coordenadas UV basándonos en el pixel_size
    vec2 pixel_uv = floor(UV * tex_size / pixel_size) * pixel_size / tex_size;
    
    // 3. Aplicamos el tiempo para animarlo, manteniendo el efecto pixelado
    vec2 uv_random = pixel_uv + vec2(TIME * 0.1, TIME * -0.1);
    
    float noise = random(uv_random);
    
    // 4. Obtenemos el color del TextureRect (si es transparente, será completamente opaco/negro en base)
    vec4 tex_color = texture(TEXTURE, UV);
    // Mezclamos el fondo con la estática
    vec3 final_color = vec3(noise);
	
    COLOR = vec4(final_color, (alpha * noise) * tex_color.a);
}