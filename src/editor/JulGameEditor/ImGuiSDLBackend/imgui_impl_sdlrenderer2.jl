# https://github.com/ocornut/imgui/blob/master/backends/imgui_impl_sdlrenderer2.cpp
# SDL2.SDL_Renderer data
Base.@kwdef mutable struct ImGui_ImplSDLRenderer2_Data
    SDLRenderer::Ptr{SDL2.SDL_Renderer}
    FontTexture::Ptr{SDL2.SDL_Texture}
end

# Backend data stored in io.BackendRendererUserData to allow support for multiple Dear ImGui contexts
# It is STRONGLY preferred that you use docking branch with multi-viewports (== single Dear ImGui context + multiple windows) instead of multiple Dear ImGui contexts.
function ImGui_ImplSDLRenderer2_GetBackendData()
    io::Ptr{CImGui.ImGuiIO} = CImGui.GetIO()
    ber = unsafe_load(io.BackendRendererUserData)
    return CImGui.GetCurrentContext() != C_NULL ? ber : C_NULL
end

# Functions
function ImGui_ImplSDLRenderer2_Init(renderer::Ptr{SDL2.SDL_Renderer})
    io = CImGui.GetIO()
    @assert unsafe_load(io.BackendRendererUserData) == C_NULL "Already initialized a renderer backend!"
    @assert renderer !== C_NULL && renderer != C_NULL "SDL2.SDL_Renderer not initialized!"

    # Setup backend capabilities flags
    bd = ImGui_ImplSDLRenderer2_Data(renderer, C_NULL)
    io.BackendRendererUserData = pointer_from_objref(bd)
    io.BackendRendererName = pointer("imgui_impl_sdlrenderer2")
    io.BackendFlags = unsafe_load(io.BackendFlags) | CImGui.ImGuiBackendFlags_RendererHasVtxOffset # We can honor the  CImGui.ImDrawCmd::VtxOffset field, allowing for large meshes.
    ImGui_ImplSDLRenderer2_CreateFontsTexture(bd)
    return true
end

function ImGui_ImplSDLRenderer2_Shutdown()
    bd = ImGui_ImplSDLRenderer2_GetBackendData()
#    @assert bd != C_NULL # "No renderer backend to shutdown, or already shutdown?"
    io = CImGui.GetIO()

    ImGui_ImplSDLRenderer2_DestroyDeviceObjects()

    io.BackendRendererName = C_NULL
    io.BackendRendererUserData = C_NULL
    io.BackendFlags &= ~ImGuiBackendFlags_RendererHasVtxOffset
end

function ImGui_ImplSDLRenderer2_SetupRenderState()
    bd = ImGui_ImplSDLRenderer2_GetBackendData()
    # Clear out any viewports and cliprect set by the user
    # FIXME: Technically speaking there are lots of other things we could backup/setup/restore during our render process.
    SDL2.SDL_RenderSetViewport(sdlRenderer, C_NULL)
    SDL2.SDL_RenderSetClipRect(sdlRenderer, C_NULL)
end

function ImGui_ImplSDLRenderer2_NewFrame()
    #todo
    bd = ImGui_ImplSDLRenderer2_GetBackendData()
    @assert bd != C_NULL "Did you call ImGui_ImplSDLRenderer2_Init()?"
    # bd = unsafe_load(bd)

    # if bd.FontTexture == C_NULL
    #   if bd == C_NULL
    #     ImGui_ImplSDLRenderer2_CreateDeviceObjects()
    #   end
    # end
end

# Backup SDL2.SDL_Renderer state that will be modified to restore it afterwards
Base.@kwdef mutable struct BackupSDLRendererState
    Viewport::SDL2.SDL_Rect = SDL2.SDL_Rect(0, 0, 0, 0)
    ClipEnabled::Bool = false
    ClipRect::SDL2.SDL_Rect = SDL2.SDL_Rect(0, 0, 0, 0)
end

function ImGui_ImplSDLRenderer2_RenderDrawData(draw_data)
    bd = ImGui_ImplSDLRenderer2_GetBackendData()

    # If there's a scale factor set by the user, use that instead
    # If the user has specified a scale factor to SDL2.SDL_Renderer already via SDL2.SDL_RenderSetScale(), SDL will scale whatever we pass
    # to SDL2.SDL_RenderGeometryRaw() by that scale factor. In that case we don't want to be also scaling it ourselves here.
    rsx = Cfloat(1.0)
    rsy = Cfloat(1.0)
    @c SDL2.SDL_RenderGetScale(sdlRenderer, &rsx, &rsy)
    render_scale = ImVec2((rsx == 1.0) ? unsafe_load(draw_data.FramebufferScale.x) : 1.0,(rsy == 1.0) ? unsafe_load(draw_data.FramebufferScale.y) : 1.0)

    # Avoid rendering when minimized, scale coordinates for retina displays (screen coordinates != framebuffer coordinates)
    fb_width = Int(unsafe_load(draw_data.DisplaySize.x) * render_scale.x)
    fb_height = Int(unsafe_load(draw_data.DisplaySize.y) * render_scale.y)
    if fb_width == 0 || fb_height == 0
        return
    end

    old = BackupSDLRendererState()
    old.ClipEnabled = SDL2.SDL_RenderIsClipEnabled(sdlRenderer) == SDL2.SDL_TRUE
    @c SDL2.SDL_RenderGetViewport(sdlRenderer, &old.Viewport)
    @c SDL2.SDL_RenderGetClipRect(sdlRenderer, &old.ClipRect)

    # will project scissor/clipping rectangles into framebuffer space
    clip_off = unsafe_load(draw_data.DisplayPos)         # (0,0) unless using multi-viewports
    clip_scale = render_scale

    # Render command lists
    ImGui_ImplSDLRenderer2_SetupRenderState()
    data = unsafe_load(draw_data)
    GC.@preserve cmd_lists = unsafe_wrap(Vector{Ptr{CImGui.ImDrawList}}, data.CmdLists.Data, data.CmdListsCount)
    for cmd_list in cmd_lists # struct  CImGui.ImDrawList

        vtx_buffer = cmd_list.VtxBuffer |> unsafe_load
        idx_buffer = cmd_list.IdxBuffer |> unsafe_load
        cmd_buffer = cmd_list.CmdBuffer |> unsafe_load
        
        for cmd_i = 0:cmd_buffer.Size-1
            pcmd = cmd_buffer.Data + cmd_i * sizeof(CImGui.ImDrawCmd)

            cb_funcptr = unsafe_load(pcmd.UserCallback)
            if cb_funcptr != C_NULL
                # User callback, registered via  CImGui.ImDrawList::AddCallback()
                # (ImDrawCallback_ResetRenderState is a special callback value used by the user to request the renderer to reset render state.)
                if cb_funcptr == ctx.ImDrawCallback_ResetRenderState
                    ImGui_ImplSDLRenderer2_SetupRenderState()
                else
                    ccall(cb_funcptr, Cvoid, (Ptr{ CImGui.ImDrawList}, Ptr{ CImGui.ImDrawCmd}), cmd_list, pcmd)
                end
            else
                # Project scissor/clipping rectangles into framebuffer space
                clip_min = ImVec2((unsafe_load(pcmd.ClipRect.x) - clip_off.x) * clip_scale.x, (unsafe_load(pcmd.ClipRect.y) - clip_off.y) * clip_scale.y)
                clip_max = ImVec2((unsafe_load(pcmd.ClipRect.z) - clip_off.x) * clip_scale.x , (unsafe_load(pcmd.ClipRect.w) - clip_off.y) * clip_scale.y)
                if clip_min.x < 0.0
                    clip_min = ImVec2(0.0, clip_min.y)
                end
                if clip_min.y < 0.0  
                    clip_min = ImVec2(clip_min.x, 0.0)
                end
                if clip_max.x > fb_width 
                     clip_max = ImVec2(fb_width, clip_max.y)
                end
                if clip_max.y > fb_height 
                    clip_max = ImVec2(clip_max.x, fb_height)
                end
                if clip_max.x <= clip_min.x || clip_max.y <= clip_min.y
                    continue
                end
                r = SDL2.SDL_Rect((Int)(round(clip_min.x)), (Int)(round(clip_min.y)), (Int)(round(clip_max.x - clip_min.x)), (Int)(round(clip_max.y - clip_min.y)))

                @c SDL2.SDL_RenderSetClipRect(sdlRenderer, &r) # This prevents rendering to outside of the current window. For example, if you have a window that is 800x600 and you try to render a 1000x1000 image, it will only render the part that is inside the window.
                
                pos_offset = offsetof(CImGui.ImDrawVert, Val(:pos))
                uv_offset = offsetof(CImGui.ImDrawVert, Val(:uv))
                col_offset = offsetof(CImGui.ImDrawVert, Val(:col))
                xy = Ptr{Cfloat}(Ptr{Cvoid}(Ptr{Cchar}(vtx_buffer.Data + unsafe_load(pcmd.VtxOffset)) + pos_offset))
                uv = Ptr{Cfloat}(Ptr{Cvoid}(Ptr{Cchar}(vtx_buffer.Data + unsafe_load(pcmd.VtxOffset)) + uv_offset))
                color = Ptr{Int}(Ptr{Cvoid}(Ptr{Cchar}(vtx_buffer.Data + unsafe_load(pcmd.VtxOffset)) + col_offset))
                    
                tex = Ptr{SDL2.SDL_Texture}(CImGui.ImDrawCmd_GetTexID(pcmd))
                offset = unsafe_load(pcmd.IdxOffset)*2
               
                elem_count = Int(unsafe_load(pcmd.ElemCount))
                indices = Ptr{CImGui.ImDrawIdx}(idx_buffer.Data + (offset)) 
                
                num_vertices = vtx_buffer.Size-unsafe_load(pcmd.VtxOffset)
                owner_name = cmd_list._OwnerName |> unsafe_load |> unsafe_string # use for debugging

                res = SDL2.SDL_RenderGeometryRaw(sdlRenderer,
                tex,
                xy, Cint(sizeof(CImGui.ImDrawVert)),
                color, Cint(sizeof(CImGui.ImDrawVert)),
                uv, Cint(sizeof(CImGui.ImDrawVert)),
                num_vertices,
                indices, elem_count, sizeof(CImGui.ImDrawIdx))

                if res != 0
                    @error "Error rendering imgui:" exception=unsafe_string(SDL2.SDL_GetError())
                    Base.show_backtrace(stderr, catch_backtrace())
                end
            end
        end
    end

    # Restore modified SDL2.SDL_Renderer state
    @c SDL2.SDL_RenderSetViewport(sdlRenderer, &old.Viewport)
    if old.ClipEnabled == SDL2.SDL_TRUE
        @c SDL2.SDL_RenderSetClipRect(sdlRenderer, &old.ClipRect)
    else
        @c SDL2.SDL_RenderSetClipRect(sdlRenderer, C_NULL)
    end
end

function ImGui_ImplSDLRenderer2_CreateFontsTexture()
    io = CImGui.GetIO()
    bd = ImGui_ImplSDLRenderer2_GetBackendData()

    # Build texture atlas
    pixels, width, height = io.Fonts.GetTexDataAsRGBA32()  # Load as RGBA 32-bit (75% of the memory is wasted, but default font is so small) because it is more likely to be compatible with user's existing shaders. If your ImTextureId represent a higher-level concept than just a GL texture id, consider calling GetTexDataAsAlpha8() instead to save on GPU memory.

    # Upload texture to graphics system
    # (Bilinear sampling is required by default. Set 'io.Fonts.Flags |= ImFontAtlasFlags_NoBakedLines' or 'style.AntiAliasedLinesUseTex = false' to allow point/nearest sampling)
    bd.FontTexture = SDL2.SDL_CreateTexture(sdlRenderer, SDL2.SDL_PIXELFORMAT_ABGR8888, SDL2.SDL_TEXTUREACCESS_STATIC, width, height)
    if bd.FontTexture == C_NULL
        SDL2.SDL_Log("error creating texture")
        println("error creating texture")
        return false
    end
    SDL2.SDL_UpdateTexture(bd.FontTexture, C_NULL, pixels, 4 * width)
    SDL2.SDL_SetTextureBlendMode(bd.FontTexture, SDL2.SDL_BLENDMODE_BLEND)
    SDL2.SDL_SetTextureScaleMode(bd.FontTexture, SDL2.SDL_ScaleModeLinear)

    # Store our identifier
    io.Fonts.SetTexID(unsafe_convert(ImTextureID, pointer_from_objref(bd.FontTexture)))

    return true
end

function ImGui_ImplSDLRenderer2_CreateFontsTexture(bd)
    io = CImGui.GetIO()
    # Build texture atlas
    fonts = unsafe_load(io.Fonts)
    pixels = Ptr{Cuchar}(C_NULL)
    width, height = Cint(0), Cint(0)
    @c CImGui.ImFontAtlas_GetTexDataAsRGBA32(fonts, &pixels, &width, &height, C_NULL)

    # Upload texture to graphics system
    # (Bilinear sampling is required by default. Set 'io.Fonts.Flags |= ImFontAtlasFlags_NoBakedLines' or 'style.AntiAliasedLinesUseTex = false' to allow point/nearest sampling)
    fonts.Flags = CImGui.ImFontAtlasFlags_NoBakedLines
    bd.FontTexture = SDL2.SDL_CreateTexture(bd.SDLRenderer, SDL2.SDL_PIXELFORMAT_ABGR8888, SDL2.SDL_TEXTUREACCESS_STATIC, width, height)
    if bd.FontTexture == C_NULL
        println("error creating texture")
        return false
    end
    
    SDL2.SDL_UpdateTexture(bd.FontTexture, C_NULL, pixels, 4 * width)
    SDL2.SDL_SetTextureBlendMode(bd.FontTexture, SDL2.SDL_BLENDMODE_BLEND)
    SDL2.SDL_SetTextureScaleMode(bd.FontTexture, SDL2.SDL_ScaleModeLinear)

    # store our identifier
    CImGui.ImFontAtlas_SetTexID(fonts, CImGui.ImTextureID(Int(bd.FontTexture)))

    return true
end

function ImGui_ImplSDLRenderer2_DestroyFontsTexture()
    io = CImGui.GetIO()
    bd = ImGui_ImplSDLRenderer2_GetBackendData()
    if bd.FontTexture != C_NULL
        io.Fonts.SetTexID(0)
        SDL2.SDL_DestroyTexture(bd.FontTexture)
        bd.FontTexture = C_NULL
    end
end

function ImGui_ImplSDLRenderer2_CreateDeviceObjects()
    return ImGui_ImplSDLRenderer2_CreateFontsTexture()
end

function ImGui_ImplSDLRenderer2_DestroyDeviceObjects()
    ImGui_ImplSDLRenderer2_DestroyFontsTexture()
end

@generated function offsetof(::Type{X}, ::Val{field}) where {X,field}
    idx = findfirst(f->f==field, fieldnames(X))
    return fieldoffset(X, idx)
end