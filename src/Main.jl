module MainLoop
	using ..JulGame
	using ..JulGame: Camera, Component, Input, Math, UI, SceneModule
    import ..JulGame: Component
    import ..JulGame.SceneManagement: SceneBuilderModule
	import ..JulGame

	include("utils/Enums.jl")
	include("utils/Constants.jl")

	export Main
	mutable struct Main
		assets::String
		autoScaleZoom::Bool
		close::Bool
		currentTestTime::Float64
		debugTextBoxes::Vector{UI.TextBoxModule.TextBox}
		fpsManager::Ref{SDL2.LibSDL2.FPSmanager}
		globals::Vector{Any}
		input::Input
		isGameModeRunningInEditor::Bool
		isWindowFocused::Bool
		level::JulGame.SceneManagement.SceneBuilderModule.Scene
		mousePositionWorld::Union{Math.Vector2, Math.Vector2f}
		optimizeSpriteRendering::Bool
		scene::SceneModule.Scene
		selectedEntity::Union{Entity, Nothing}
		selectedUIElementIndex::Int64
		screenSize::Math.Vector2
		shouldChangeScene::Bool
		spriteLayers::Dict
		targetFrameRate::Int32
		testLength::Float64
		testMode::Bool
		window::Ptr{SDL2.SDL_Window}
		windowName::String
		zoom::Float64

		function Main(zoom::Float64 = 1.0)
			this::Main = new()

			SDL2.init()

			this.zoom = zoom
			this.scene = SceneModule.Scene()
			this.input = Input()

			this.close = false
			this.debugTextBoxes = UI.TextBoxModule.TextBox[]
			this.isWindowFocused = false
			this.mousePositionWorld = Math.Vector2f()
			this.optimizeSpriteRendering = false
			this.selectedEntity = nothing
			this.selectedUIElementIndex = -1
			this.screenSize = Math.Vector2(0,0)
			this.shouldChangeScene = false
			this.globals = []
			this.input.main = this
			this.isGameModeRunningInEditor = false

			this.currentTestTime = 0.0
			this.testMode = false
			this.testLength = 0.0

			return this
		end
	end

    function prepare_window_scripts_and_start_loop(size = C_NULL, isResizable::Bool = false, autoScaleZoom::Bool = true)
        @debug "Preparing window"
		if !JulGame.IS_EDITOR
			@debug "Preparing window for game"
            prepare_window(size, isResizable, autoScaleZoom)
        end
		@debug "Initializing scripts and components"
        initialize_scripts_and_components()

        if !JulGame.IS_EDITOR
			@debug "Starting non editor loop"
            full_loop(MAIN)
            return
        end
    end

    function initialize_new_scene(this::Main)
		@debug "Initializing new scene"
		@debug "Deserializing and building scene"
        SceneBuilderModule.deserialize_and_build_scene(this.level)

        initialize_scripts_and_components()

        if !JulGame.IS_EDITOR
			@debug "Starting non editor loop"
            full_loop(this)
            return
        end
    end

    function reset_camera_position(this::Main)
		@debug "Resetting camera position"
		if this.scene.camera === nothing return end

        cameraPosition = Math.Vector2f()
        JulGame.CameraModule.update(this.scene.camera, cameraPosition)
    end
	
    function full_loop(this::Main)
        try
			this.close = false
            startTime = Ref(UInt64(0))
            lastPhysicsTime = Ref(UInt64(SDL2.SDL_GetTicks()))
            while !this.close
                try
                    game_loop(this, startTime, lastPhysicsTime)
                catch e
                    if this.testMode
                        throw(e)
                    else
						if JulGame.IS_EDITOR
							rethrow(e)
						else
							@error string(e)
							Base.show_backtrace(stdout, catch_backtrace())
						end
                    end
                end
                if this.testMode && this.currentTestTime >= this.testLength
                    break
                end
            end
        finally
            for entity in this.scene.entities
                for script in entity.scripts
                    try
                        Base.invokelatest(JulGame.on_shutdown, script)
                    catch e
						if JulGame.IS_EDITOR
							rethrow(e)
						else
							if typeof(e) != ErrorException
								println("Error shutting down script: $(typeof(script))")
								Base.show_backtrace(stdout, catch_backtrace())
							end
						end
                    end
                end
            end
			
            if !this.shouldChangeScene
				@debug "Closing window"
                SDL2.SDL_DestroyRenderer(JulGame.Renderer::Ptr{SDL2.SDL_Renderer})
                SDL2.SDL_DestroyWindow(this.window)
                SDL2.Mix_Quit()
                SDL2.Mix_CloseAudio()
                SDL2.TTF_Quit() # TODO: Close all open fonts with TTF_CloseFont befor this
                SDL2.SDL_Quit()
            else
				@debug "Changing scene"
                this.shouldChangeScene = false
                initialize_new_scene(this)
            end
        end
    end

    function create_new_entity(this::Main)
		@debug "Creating new entity"
        SceneBuilderModule.create_new_entity(this.level)
    end

    function create_new_text_box(this::Main)
		@debug "Creating new text box"
        SceneBuilderModule.create_new_text_box(this.level)
    end

	function create_new_screen_button(this::Main)
		@debug "Creating new screen button"
		SceneBuilderModule.create_new_screen_button(this.level)
	end

    function update_viewport(this::Main, x,y)
		@debug "Updating viewport"
        if !this.autoScaleZoom
            return
        end
		scale_zoom(this, x, y)
        SDL2.SDL_RenderClear(JulGame.Renderer::Ptr{SDL2.SDL_Renderer})
        SDL2.SDL_RenderSetScale(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, 1.0, 1.0)	
		
		if this.scene.camera !== nothing
			this.scene.camera.startingCoordinates = Math.Vector2f(round(x/2) - round(this.scene.camera.size.x/2*this.zoom), round(y/2) - round(this.scene.camera.size.y/2*this.zoom))																																				
			@debug string("Set viewport to: ", this.scene.camera.startingCoordinates)
			SDL2.SDL_RenderSetViewport(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, Ref(SDL2.SDL_Rect(this.scene.camera.startingCoordinates.x, this.scene.camera.startingCoordinates.y, round(this.scene.camera.size.x*this.zoom), round(this.scene.camera.size.y*this.zoom))))
		end

        SDL2.SDL_RenderSetScale(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, this.zoom, this.zoom)
    end

    function scale_zoom(this::Main, x,y)
		@debug "Scaling zoom"
		if this.scene.camera === nothing
			return
		end

        if this.autoScaleZoom
            targetRatio = this.scene.camera.size.x/this.scene.camera.size.y
            if this.scene.camera.size.x == max(this.scene.camera.size.x, this.scene.camera.size.y)
                for i in x:-1:this.scene.camera.size.x
                    value = i/targetRatio
                    isInt = isinteger(value) || (isa(value, AbstractFloat) && trunc(value) == value)
                    if isInt && value <= y
                        this.zoom = i/this.scene.camera.size.x
                        break
                    end
                end
            else
                for i in y:-1:this.scene.camera.size.y
                    value = i*targetRatio
                    isInt = isinteger(value) || (isa(value, AbstractFloat) && trunc(value) == value)
                    if isInt && value <= x
                        this.zoom = i/this.scene.camera.size.y
                        break
                    end
                end
            end
        end
    end
    
	function prepare_window(size = C_NULL, isResizable::Bool = false, autoScaleZoom::Bool = true)
		this::Main = MAIN
		this.autoScaleZoom = autoScaleZoom
		scale_zoom(this, size.x, size.y)

		if this.scene.camera !== nothing
			this.scene.camera.startingCoordinates = Math.Vector2f(round(size.x/2) - round(this.scene.camera.size.x/2*this.zoom), round(size.y/2) - round(this.scene.camera.size.y/2*this.zoom))																																				
			@debug string("Set viewport to: ", this.scene.camera.startingCoordinates)
			SDL2.SDL_RenderSetViewport(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, Ref(SDL2.SDL_Rect(this.scene.camera.startingCoordinates.x, this.scene.camera.startingCoordinates.y, round(this.scene.camera.size.x*this.zoom), round(this.scene.camera.size.y*this.zoom))))
		end

		SDL2.SDL_RenderSetScale(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, this.zoom, this.zoom)
		this.fpsManager = Ref(SDL2.LibSDL2.FPSmanager(UInt32(0), Cfloat(0.0), UInt32(0), UInt32(0), UInt32(0)))
		SDL2.SDL_initFramerate(this.fpsManager)
		SDL2.SDL_setFramerate(this.fpsManager, UInt32(this.targetFrameRate))
	end

function initialize_scripts_and_components()
	this::Main = MAIN
	scripts = []
	for entity in this.scene.entities
		for script in entity.scripts
			push!(scripts, script)
		end
	end

	if !this.isGameModeRunningInEditor
		for uiElement in this.scene.uiElements
			JulGame.initialize(uiElement)
		end
	end

	this.spriteLayers = build_sprite_layers()
	
	if !JulGame.IS_EDITOR || this.isGameModeRunningInEditor

		for script in scripts
			try
				Base.invokelatest(JulGame.initialize, script)
			catch e
				if JulGame.IS_EDITOR
					rethrow(e)
				else
					@error string(e)
					Base.show_backtrace(stdout, catch_backtrace())
				end
			end
		end
		build_sprite_layers()

		for entity in MAIN.scene.entities
			@debug "Checking for a soundSource that needs to be activated"
			if entity.soundSource != C_NULL && entity.soundSource !== nothing && entity.soundSource.playOnStart
				Component.toggle_sound(entity.soundSource)
				@debug("Playing $(entity.name)'s ($(entity.id)) sound source on start")
			end
		end 
	end
              
	MAIN.scene.rigidbodies = []
	MAIN.scene.colliders = []
	for entity in MAIN.scene.entities
		@debug "adding rigidbodies to global list"
		if entity.rigidbody != C_NULL
			push!(MAIN.scene.rigidbodies, entity.rigidbody)
                end
		@debug "adding colliders to global list"
		if entity.collider != C_NULL
			push!(MAIN.scene.colliders, entity.collider)
		end
	end 
end

export change_scene
"""
	change_scene(sceneFileName::String)

Change the scene to the specified `sceneFileName`. This function destroys the current scene, including all entities, textboxes, and screen buttons, except for the ones marked as persistent. It then loads the new scene and sets the camera and persistent entities, textboxes, and screen buttons.

# Arguments
- `sceneFileName::String`: The name of the scene file to load.
"""
function JulGame.change_scene(sceneFileName::String)
	this::Main = MAIN
	@debug "Changing scene to: $(sceneFileName)"
	this.close = true
	this.shouldChangeScene = true
	#destroy current scene 
	@debug "Entity count before destroying: $(length(this.scene.entities))" 
	count = 0
	skipcount = 0
	persistentEntities = []	
	entitiesToDestroy = []

	for entity in this.scene.entities
		if entity.persistentBetweenScenes && (!JulGame.IS_EDITOR || this.isGameModeRunningInEditor)
			@debug("Persistent entity: ", entity.name, " with id: ", entity.id)
			push!(persistentEntities, entity)
			skipcount += 1
			continue
		end

		destroy_entity_components(this, entity)
		if !JulGame.IS_EDITOR
			for script in entity.scripts
				try
					Base.invokelatest(JulGame.on_shutdown, script)
				catch e
					if JulGame.IS_EDITOR
						rethrow(e)
					else
						if typeof(e) != ErrorException
							println("Error shutting down script: $(typeof(script))")
							@error string(e)
							Base.show_backtrace(stdout, catch_backtrace())
						end
					end
				end
			end
		end

		push!(entitiesToDestroy, entity)
		count += 1
	end

	for entity in entitiesToDestroy
		JulGame.destroy_entity(this, entity)
	end
	@debug "Destroyed $count entities while changing scenes"
	@debug "Skipped $skipcount entities while changing scenes"

	@debug "Entities left after destroying while changing scenes (persistent): $(length(persistentEntities)) "

	persistentUIElements = []
	# delete all UIElements
	for uiElement in this.scene.uiElements
		if uiElement.persistentBetweenScenes
			#println("Persistent uiElement: ", uiElement.name)
			push!(persistentUIElements, uiElement)
			skipcount += 1
			continue
		end
        JulGame.destroy(uiElement)
	end
	
	#load new scene 
	camera = this.scene.camera
	this.scene = SceneModule.Scene()
	this.scene.entities = persistentEntities
	this.scene.uiElements = persistentUIElements
	this.scene.camera = camera
	this.level.scene = sceneFileName
	
	if JulGame.IS_EDITOR
		initialize_new_scene(this)
	end
end

"""
build_sprite_layers()

Builds the sprite layers for the main game.

"""
function build_sprite_layers()
	@debug "Building sprite layers"
	layerDict = Dict{String, Array}()
	layerDict["sort"] = []
	for entity in MAIN.scene.entities
		entitySprite = entity.sprite
		if entitySprite != C_NULL
			if !haskey(layerDict, "$(entitySprite.layer)")
				push!(layerDict["sort"], entitySprite.layer)
				layerDict["$(entitySprite.layer)"] = [entitySprite]
			else
				push!(layerDict["$(entitySprite.layer)"], entitySprite)
			end
		end
	end
	sort!(layerDict["sort"])

	return layerDict
end

export destroy_entity
"""
destroy_entity(entity)

Destroy the specified entity. This removes the entity's sprite from the sprite layers so that it is no longer rendered. It also removes the entity's rigidbody from the main game's rigidbodies array.

# Arguments
- `entity`: The entity to be destroyed.
"""
function JulGame.destroy_entity(this::Main, entity)
	for i = eachindex(this.scene.entities)
		if this.scene.entities[i] == entity
			destroy_entity_components(this, entity)
			deleteat!(this.scene.entities, i)
			this.selectedEntity = nothing
			break
		end
	end
end

function JulGame.destroy_ui_element(this::Main, uiElement)
	for i = eachindex(this.scene.uiElements)
		if this.scene.uiElements[i] == uiElement
			deleteat!(this.scene.uiElements, i)
			JulGame.destroy(uiElement)
			break
		end
	end
end

function destroy_entity_components(this::Main, entity)
	entitySprite = entity.sprite
	if entitySprite != C_NULL
		for j = eachindex(this.spriteLayers["$(entitySprite.layer)"])
			if this.spriteLayers["$(entitySprite.layer)"][j] == entitySprite
				Component.destroy(entitySprite)
				deleteat!(this.spriteLayers["$(entitySprite.layer)"], j)
				break
			end
		end
	end

	entityRigidbody = entity.rigidbody
	if entityRigidbody != C_NULL
		for j = eachindex(this.scene.rigidbodies)
			if this.scene.rigidbodies[j] == entityRigidbody
				deleteat!(this.scene.rigidbodies, j)
				break
			end
		end
	end

	entityCollider = entity.collider
	if entityCollider != C_NULL
		for j = eachindex(this.scene.colliders)
			if this.scene.colliders[j] == entityCollider
				deleteat!(this.scene.colliders, j)
				break
			end
		end
	end

	entitySoundSource = entity.soundSource
	if entitySoundSource != C_NULL
		Component.unload_sound(entitySoundSource)
	end
end

export create_entity
"""
create_entity(entity)

Create a new entity. Adds the entity to the main game's entities array and adds the entity's sprite to the sprite layers so that it is rendered.

# Arguments
- `entity`: The entity to create.

"""
function JulGame.create_entity(entity)
	this::Main = MAIN
	push!(this.scene.entities, entity)
	if entity.sprite != C_NULL
		if !haskey(this.spriteLayers, "$(entity.sprite.layer)")
			push!(this.spriteLayers["sort"], entity.sprite.layer)
			this.spriteLayers["$(entity.sprite.layer)"] = [entity.sprite]
			sort!(this.spriteLayers["sort"])
		else
			push!(this.spriteLayers["$(entity.sprite.layer)"], entity.sprite)
		end
	end

	if entity.rigidbody != C_NULL
		push!(this.scene.rigidbodies, entity.rigidbody)
	end

	if entity.collider != C_NULL
		push!(this.scene.colliders, entity.collider)
	end

	return entity
end

"""
game_loop(this::Main, startTime::Ref{UInt64} = Ref(UInt64(0)), lastPhysicsTime::Ref{UInt64} = Ref(UInt64(0)), close::Ref{Bool} = Ref(Bool(false)), Vector{Any}} = C_NULL)

Runs the game loop.

Parameters:
- `this`: The main struct.
- `startTime`: A reference to the start time of the game loop.
- `lastPhysicsTime`: A reference to the last physics time of the game loop.
"""
function game_loop(this::Main, startTime::Ref{UInt64} = Ref(UInt64(0)), lastPhysicsTime::Ref{UInt64} = Ref(UInt64(0)), windowPos::Math.Vector2 = Math.Vector2(0,0), windowSize::Math.Vector2 = Math.Vector2(0,0))
	if this.shouldChangeScene && !JulGame.IS_EDITOR
		this.shouldChangeScene = false
		initialize_new_scene(this)
		return
	end
	try
			SDL2.SDL_RenderSetScale(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, this.zoom, this.zoom)

			lastStartTime = startTime[]
			startTime[] = SDL2.SDL_GetPerformanceCounter()

			if JulGame.IS_EDITOR && this.scene.camera !== nothing
				#this.scene.camera.size = Math.Vector2(windowSize.x, windowSize.y)
			end

			DEBUG = false
			#region Input
			if !JulGame.IS_EDITOR
				JulGame.InputModule.poll_input(this.input)
			end

			if this.input.quit && !JulGame.IS_EDITOR
				this.close = true
			end
			DEBUG = this.input.debug

			cameraPosition = Math.Vector2f()

			if !JulGame.IS_EDITOR
				SDL2.SDL_RenderClear(JulGame.Renderer::Ptr{SDL2.SDL_Renderer})
			end

			#region Physics
			if !JulGame.IS_EDITOR || this.isGameModeRunningInEditor
				currentPhysicsTime = SDL2.SDL_GetTicks()
				deltaTime = (currentPhysicsTime - lastPhysicsTime[]) / 1000.0
				JulGame.DELTA_TIME = deltaTime
				this.currentTestTime += deltaTime
				if deltaTime > .25
					lastPhysicsTime[] =  SDL2.SDL_GetTicks()
					# TODO: pause simulation
					#return
				end
				for rigidbody in this.scene.rigidbodies
					try
						JulGame.update(rigidbody, deltaTime)
					catch e
						if JulGame.IS_EDITOR
							rethrow(e)
						else
							println(rigidbody.parent.name, " with id: ", rigidbody.parent.id, " has a problem with it's rigidbody")
							@error string(e)
							Base.show_backtrace(stdout, catch_backtrace())
						end
					end
				end
				lastPhysicsTime[] =  currentPhysicsTime
			end

			#region Rendering
			currentRenderTime = SDL2.SDL_GetTicks()
			if this.scene.camera !== nothing && !JulGame.IS_EDITOR
				JulGame.CameraModule.update(this.scene.camera)
			end

			for entity in this.scene.entities
				if !entity.isActive
					continue
				end

				if !JulGame.IS_EDITOR || this.isGameModeRunningInEditor
					try
                        JulGame.update(entity, deltaTime)
						if this.close && !this.isGameModeRunningInEditor
							@debug "Closing game"
							return
						end
					catch e
						if JulGame.IS_EDITOR
							rethrow(e)
						else
							println(entity.name, " with id: ", entity.id, " has a problem with it's update")
							@error string(e)
							Base.show_backtrace(stdout, catch_backtrace())
						end
					end
					entityAnimator = entity.animator
					if entityAnimator != C_NULL
                        JulGame.update(entityAnimator, currentRenderTime, deltaTime)
					end
				end
			end
			
			cameraPosition = this.scene.camera !== nothing ? this.scene.camera.position : Math.Vector2f(0,0)
			cameraSize = this.scene.camera !== nothing ? this.scene.camera.size : Math.Vector2(0,0)
			
			if !JulGame.IS_EDITOR
				render_scene_sprites_and_shapes(this, this.scene.camera)
			end
			
			render_scene_debug(this, cameraPosition, cameraSize, DEBUG)

			#region UI
			for uiElement in this.scene.uiElements
                JulGame.render(uiElement, DEBUG)
			end

			pos1::Math.Vector2 = windowPos !== nothing ? windowPos : Math.Vector2(0, 0)
			this.mousePositionWorld = Math.Vector2(floor(Int32,(this.input.mousePosition.x + (cameraPosition.x * SCALE_UNITS * this.zoom)) / SCALE_UNITS / this.zoom), floor(Int32,( this.input.mousePosition.y + (cameraPosition.y * SCALE_UNITS * this.zoom)) / SCALE_UNITS / this.zoom))
			rawMousePos = Math.Vector2f(this.input.mousePosition.x - pos1.x , this.input.mousePosition.y - pos1.y )
			#region Debug
			if DEBUG
				# Stats to display
				statTexts = [
					"FPS: $(round(1000 / round((startTime[] - lastStartTime) / SDL2.SDL_GetPerformanceFrequency() * 1000.0)))",
					"Frame time: $(round((startTime[] - lastStartTime) / SDL2.SDL_GetPerformanceFrequency() * 1000.0)) ms",
					"Raw Mouse pos: $(rawMousePos.x),$(rawMousePos.y)",
					"Mouse pos world: $(this.mousePositionWorld.x),$(this.mousePositionWorld.y)"
				]

				if length(this.debugTextBoxes) == 0
				 	fontPath = "FiraCode-Regular.ttf"

					for i = eachindex(statTexts)
				 		textBox = UI.TextBoxModule.TextBox("Debug text", fontPath, 40, Math.Vector2(0, 35 * i), statTexts[i], false, false)
				 		push!(this.debugTextBoxes, textBox)
                         JulGame.initialize(textBox)
				 	end
				 else
				 	for i = eachindex(this.debugTextBoxes)
                         db_textbox = this.debugTextBoxes[i]
                         db_textbox.text = statTexts[i]
                         JulGame.render(db_textbox, false)
			 	  	end
				 end
			end

			if !JulGame.IS_EDITOR
				SDL2.SDL_RenderPresent(JulGame.Renderer::Ptr{SDL2.SDL_Renderer})
				SDL2.SDL_framerateDelay(this.fpsManager)
			end
		catch e
			if JulGame.IS_EDITOR
				rethrow(e)
			else
				@error string(e)
				Base.show_backtrace(stdout, catch_backtrace())
			end
		end
    end

	function render_scene_sprites_and_shapes(this::Main, camera::Camera)
		cameraPosition = camera !== nothing ? camera.position : Math.Vector2f(0,0)
		cameraSize = camera !== nothing ? camera.size : Math.Vector2(0,0)
			
		skipcount = 0
		rendercount = 0
		renderOrder = []
		for entity in this.scene.entities
			spriteExists = entity.sprite != C_NULL && entity.sprite !== nothing
			shapeExists = entity.shape != C_NULL && entity.shape !== nothing
			if !entity.isActive || (!spriteExists && !shapeExists)
				continue
			end

			position = entity.transform.position
			size = entity.transform.scale
			sprite = entity.sprite
			shape = entity.shape

			skipSprite = false
			skipShape = false

			# TODO: consider offset
			if spriteExists && ((position.x + size.x) < cameraPosition.x || position.y < cameraPosition.y || position.x > cameraPosition.x + cameraSize.x/SCALE_UNITS || (position.y - size.y) > cameraPosition.y + cameraSize.y/SCALE_UNITS) && sprite.isWorldEntity && this.optimizeSpriteRendering 
				skipSprite = true
			end

			# TODO: consider offset
			if shapeExists && ((position.x + size.x) < cameraPosition.x || position.y < cameraPosition.y || position.x > cameraPosition.x + cameraSize.x/SCALE_UNITS || (position.y - size.y) > cameraPosition.y + cameraSize.y/SCALE_UNITS) && shape.isWorldEntity && this.optimizeSpriteRendering 
				skipShape = true
			end

			if !skipSprite && spriteExists
				push!(renderOrder, (sprite.layer, sprite))
			end
			if !skipShape && shapeExists
				push!(renderOrder, (shape.layer, shape))
			end
		end

		sort!(renderOrder, by = x -> x[1])
		for i = eachindex(renderOrder)
			try
				rendercount += 1
				Component.draw(renderOrder[i][2], camera)
			catch e
				if JulGame.IS_EDITOR
					rethrow(e)
				else
					println(renderOrder[i][2].parent.name, " with id: ", renderOrder[i][2].parent.id, " has a problem with it's sprite")
					@error string(e)
					Base.show_backtrace(stdout, catch_backtrace())
				end
			end
		end
	end

	function start_game_in_editor(this::Main, path::String)
		this.isGameModeRunningInEditor = true
		SceneBuilderModule.add_scripts_to_entities(path)
		initialize_scripts_and_components()
	end

	function stop_game_in_editor(this::Main)
		this.isGameModeRunningInEditor = false
		SDL2.Mix_HaltMusic()
		if this.scene.camera !== nothing && this.scene.camera != C_NULL
			this.scene.camera.target = C_NULL
		end
	end

	function render_scene_debug(this::Main, cameraPosition, cameraSize, DEBUG)
		colliderSkipCount = 0
		colliderRenderCount = 0
		for entity in this.scene.entities
			if !entity.isActive
				continue
			end
	
			if DEBUG && entity.collider != C_NULL
				rgba = (r = Ref(UInt8(0)), g = Ref(UInt8(0)), b = Ref(UInt8(0)), a = Ref(UInt8(255)))
        		SDL2.SDL_GetRenderDrawColor(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, rgba.r, rgba.g, rgba.b, rgba.a)
				SDL2.SDL_SetRenderDrawColor(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, 0, 255, 0, SDL2.SDL_ALPHA_OPAQUE)
				pos = entity.transform.position
				scale = entity.transform.scale
	
				if ((pos.x + scale.x) < cameraPosition.x || pos.y < cameraPosition.y || pos.x > cameraPosition.x + cameraSize.x/SCALE_UNITS || (pos.y - scale.y) > cameraPosition.y + cameraSize.y/SCALE_UNITS)  && this.optimizeSpriteRendering 
					colliderSkipCount += 1
					continue
				end
				colliderRenderCount += 1
				collider = entity.collider
	
				
				colSize = collider.size
				colSize = Math.Vector2f(colSize.x, colSize.y)
				colOffset = collider.offset
				colOffset = Math.Vector2f(colOffset.x, colOffset.y)
						
				SDL2.SDL_RenderDrawRectF(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, 
				Ref(SDL2.SDL_FRect((pos.x + colOffset.x - cameraPosition.x) * SCALE_UNITS, 
				(pos.y + colOffset.y - cameraPosition.y) * SCALE_UNITS, 
				entity.transform.scale.x * colSize.x * SCALE_UNITS, 
				entity.transform.scale.y * colSize.y * SCALE_UNITS)))
				SDL2.SDL_SetRenderDrawColor(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, rgba.r[], rgba.g[], rgba.b[], rgba.a[]);
			end
		end
	end
end # module

