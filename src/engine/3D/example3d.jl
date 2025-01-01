using GLFW
using ModernGL
using SimpleDirectMediaLayer
using SimpleDirectMediaLayer.LibSDL2
const SDL = SimpleDirectMediaLayer 

include("../UI/TextBox.jl")

function init()
    success = true
    SDL.init()
    SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, 3 )
    SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, 1 )
    SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE )

    window = SDL_CreateWindow("3D", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 800, 600, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN)
	SDL_SetWindowResizable(window, SDL_FALSE)
	renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC)
    if window == C_NULL
        println(string("Window could not be created! SDL Error: ", unsafe_string(SDL_GetError())))
    else
        context = SDL_GL_CreateContext(window)
        if context == C_NULL
            println(string("OpenGL context could not be created! SDL Error: ", unsafe_string(SDL_GetError())))
        else
            #Use Vsync
            if SDL_GL_SetSwapInterval( 1 ) < 0 
                println( string("Warning: Unable to set VSync! SDL Error: ", unsafe_string(SDL_GetError())) )
            end

            #Initialize OpenGL
            if !initGL() 
                println( "Unable to initialize OpenGL!\n" )
                success = false
            end
        end
    end
    return [success, window, renderer]
end

function initGL()
    success = true
    error = GL_NO_ERROR

    #Initialize Projection Matrix
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    
    #Check for error
    error = glGetError()
    if error != GL_NO_ERROR
        println(string("Error initializing OpenGL! ", error))
        success = false
    end
    #Initialize Modelview Matrix
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()

    #Check for error
    error = glGetError()
    if error != GL_NO_ERROR 
        println(string("Error initializing OpenGL! ", error))
        success = false
    end

    #Initialize clear color
    glClearColor( 0.0, 0.0, 0.0, 1.0 )
    
    #Check for error
    error = glGetError()
    if error != GL_NO_ERROR
        println(string("Error initializing OpenGL! ", error))
        success = false
    end    
    return success
end

function processInput(window)
    if GLFW.GetKey(window, GLFW.KEY_ESCAPE)
        GLFW.SetWindowShouldClose(window, true)
    end
end

function handleKeys(key, x, y)
    if key == SDL_SCANCODE_Q
        return true
    end
    return false
end 

function update()
    
end 

function render()
    #Clear color buffer
    glClearColor(0.2, 0.3, 0.3, 1.0)
    glClear(GL_COLOR_BUFFER_BIT)
    return
    vertexShader = glCreateShader(GL_VERTEX_SHADER)

    vertexShaderSource = "#version 140\nin vec2 LVertexPos2D; void main() { gl_Position = vec4( LVertexPos2D.x, LVertexPos2D.y, 0, 1 ); }"
    #Set vertex source
    glShaderSource( vertexShader, 1, vertexShaderSource, NULL );

    #Compile vertex source
    glCompileShader( vertexShader );

    #Check vertex shader for errors
    vShaderCompiled = GL_FALSE;
    glGetShaderiv( vertexShader, GL_COMPILE_STATUS, vShaderCompiled );
    if vShaderCompiled != GL_TRUE
    
        println( string("Unable to compile vertex shader %d!\n", vertexShader) );
        #printShaderLog( vertexShader );
        success = false;
    else

    end
    # Render quad
    # if(gRenderQuad)
    #     glBegin(GL_QUADS)
    #         glVertex2f( -0.5, -0.5)
    #         glVertex2f( 0.5, -0.5)
    #         glVertex2f( 0.5, 0.5)
    #         glVertex2f( -0.5, 0.5)
    #     glEnd()
    # end
end

function main()

    info = init()
    println(info)
    window = info[2]
    renderer = info[3]
	#Start up SDL and create window
	if !info[1]
		println( "Failed to initialize!\n" )
	else
	
		#Main loop flag
		quit = false

		#Event handler
        event_ref = Ref{SDL_Event}()
		
		#Enable text input
		SDL_StartTextInput()
        renderQuad = false
		#While application is running
		while !quit 
		
			#Handle events on queue
            while Bool(SDL_PollEvent(event_ref))
                evt = event_ref[]
				#User requests quit
				if evt.type == SDL_QUIT
                    println("quit")
					quit = true
                    #Handle keypress with current mouse position
				elseif evt.type == SDL_KEYUP
					x,y = Int32[1], Int32[1]
                    SDL_GetMouseState(pointer(x), pointer(y))
					if handleKeys(evt.key.keysym.scancode, x, y )
                        renderQuad = !renderQuad
                        println(renderQuad)
                    end
				end
			end

			#Render quad
			render()
			#Update screen
			SDL_GL_SwapWindow(window)
		end
		
		#Disable text input
		SDL_StopTextInput()
		SDL_Quit()
        
	end

end
