module PrefHandlerModule
    using ...JulGame

    export get_pref_path
    """
        get_pref_path(org::String, app::String)

    Get the user-and-app-specific path where files can be written. Wrapper for SDL_GetPrefPath.

    # Arguments
    - `org`: The name of your organization.
    - `app`: The name of your application.

    # Returns
    -  Returns a UTF-8 string of the user directory in platform-dependent notation. NULL if there's a problem (creating directory failed, etc.).
    """
    function get_pref_path(org::String, app::String)
        path = SDL2.SDL_GetPrefPath(org, app)
        return unsafe_string(path)
    end
end
