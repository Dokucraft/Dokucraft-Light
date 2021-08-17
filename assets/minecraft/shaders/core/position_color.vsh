#version 150

in vec3 Position;
in vec4 Color;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec4 vertexColor;
out float isHorizon;

#define HORIZONDIST 128

//fix for float ==
bool aproxEqual(float a, float b)
{
	return (a < b+0.00001 && a > b-0.00001);
}

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    vertexColor = Color;
	
    isHorizon = 0.0;

    if ((ModelViewMat * vec4(Position, 1.0)).z > -HORIZONDIST - 10.0) {
        isHorizon = 1.0;
    }
	
	//is tooltip?
	if (Color.g == 0.0)
	{
		//is background?
		if(aproxEqual(Color.a,0.94118) && aproxEqual(Color.r, 0.06275) && aproxEqual(Color.b, 0.06275))
		{
			//12 ~ 17
			if(gl_VertexID > 7 && gl_VertexID < 12)
			{
				vertexColor.rgba = vec2(0.0,0.9).xxxy;
			}
			else
			{
				vertexColor.a = 0.0;
			}
		}
		
		//is outline?
		else if(aproxEqual(Color.a,0.31373) && ((aproxEqual(Color.b,1.0) && aproxEqual(Color.r,0.31373)) || (aproxEqual(Color.b,0.49804) && aproxEqual(Color.r,0.15686)) ) )
		{
			vertexColor.a = 0.0;
		}
	}
}
