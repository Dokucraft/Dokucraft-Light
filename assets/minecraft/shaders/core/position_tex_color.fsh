#version 150

#moj_import <utils.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
// uniform vec2 ScreenSize;

in vec2 texCoord0;
in vec4 vertexColor;
in vec4 Pos;

out vec4 fragColor;

void main() {
    vec4 color = texture(Sampler0, texCoord0) * vertexColor;
    if(Pos.z == -1999)
    {
        vec2 texCord = abs(texCoord0);
        ivec2 block = ivec2(texCord);
        int variate;

        vec2 offset = vec2(0);
        
        //Grass
        if (block.y < 1) offset = vec2(0.2);

        //Dirt/Stone
        if (block.y == 3)
        {
            variate = ((block.x * block.x + 6) % 10) / 5;
            offset = vec2(0.2 * clamp(variate, 0, 1), 0);
        }

        //Stone + ores
        if(block.y > 3 && block.y < 70)
        {
            offset = vec2(0.2, 0); //Stone

            if (int(block.y * 3 + sin(block.x * 5.1) * 2.4) % 10 == 0) offset = vec2(0.6); //Coal

            if(int(block.y * 6.5 + sin(block.x * 3.0 + 2.3) * 32.1) % 25 == 0) offset = vec2(0.4); //Copper
            
            if(block.y >= 6 && int(block.y * 5.5 + sin(block.x * 2.0 + 4.3) * 30.1) % 15 == 0) offset = vec2(0.4, 0.6); //Iron

            if(block.y >= 39)
            {
                if(int(block.y * 8.5 + sin(block.x * 4.05 + 2.7) * 24.7) % 20 == 0) offset = vec2(0.2, 0.6); //Gold
                
                if(int(block.y * 6.2 + sin(block.x * 1.05 + 2.8) * 21.7) % 30 == 0) offset = vec2(0.2, 0.4); //Lapis
                
                if(block.y >= 55)
                {
                    if(int(block.y * 4.5 + sin(block.x * 2.05 + 2.8) * 23.7) % 25 == 0) offset = vec2(0, 0.4); //Redstone

                    if(int(block.y * 1.5 + sin(block.x * 1.05 + 4) * 21.6) % 23 == 0) offset = vec2(0, 0.6); //Diamonds!

                    variate = ((block.x * block.x + 6 * block.y) % 10) / 5;
                    if(block.y >= 68 && clamp(variate, 0, 1) == 1) offset = vec2(0.4, 0.2); //Deepslate
                }

            }
            
        } 
        if(block.y >= 70 && block.y <= 134)// offset = vec2(0.4, 0);
        {
            offset = vec2(0.4, 0.2); //Plain deepslate

            if(int(block.y * 5.5 + sin(block.x * 2.0 + 4.3) * 30.1) % 20 == 0) offset = vec2(0.4, 0.8); //Iron

            if(int(block.y * 8.5 + sin(block.x * 4.05 + 2.7) * 24.7) % 24 == 0) offset = vec2(0.2, 0.8); //Deepslate Gold
        
            if(int(block.y * 6.2 + sin(block.x * 1.05 + 2.8) * 21.7) % 35 == 0) offset = vec2(0.8); //Deepslate Lapis
            
            if(int(block.y * 4.5 + sin(block.x * 2.05 + 2.8) * 23.7) % 27 == 0) offset = vec2(0.8, 0.6); //Deepslate Redstone

            if(int(block.y * 1.5 + sin(block.x * 1.05 + 4) * 21.6) % 30 == 0) offset = vec2(0, 0.8); //Deepslate Diamonds

            variate = ((block.x * block.x + 6 * block.y + 5) % 10) / 5;
            if(block.y >= 132 && clamp(variate, 0, 1) == 1) offset = vec2(0, 0.2); //Bedrock (How did we get here?)
            if(block.y == 134) offset = vec2(0, 0.2);
        }
        if(block.y > 134) offset = vec2(0.4, 0);
        
        color = texture(Sampler0, (texCord - block) / 5.0 + offset) * vertexColor;
    }
    
    if (color.a < 0.1) {
        discard;
    }
    fragColor = color * ColorModulator;
}
