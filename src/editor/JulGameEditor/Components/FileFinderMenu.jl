imageExtensions = [".png", ".jpg", ".jpeg", ".bmp", ".gif"]
soundExtensions = [".wav", ".ogg", ".flac", ".mp3", ".aac", ".m4a", ".wma", ".aiff", ".aif", ".aifc", ".amr", ".au", ".snd", ".ra", ".rm", ".rmvb", ".mka", ".opus", ".sln", ".voc", ".vox", ".raw", ".wv", ".webm", ".dts", ".ac3", ".ec3", ".mlp", ".tta", ".mka", ".mks", ".m3u", ".m3u8", ".pls", ".asx", ".xspf", ".m4b", ".m4p", ".m4r", ".m4v", ".3gp", ".3g2", ".mp4", ".m4v", ".mkv", ".webm", ".flv", ".vob", ".ogv", ".avi", ".wmv", ".mov", ".qt", ".mpg", ".mpeg", ".m2v", ".m4v", ".svi", ".3gp", ".3g2", ".mxf", ".roq", ".nsv", ".f4v", ".f4p", ".f4a", ".f4b", ".f4m"]
fontExtensions = [".ttf", ".otf", ".ttc", ".woff", ".woff2", ".eot", ".sfnt", ".pfa", ".pfb", ".pfr", ".gsf", ".cid", ".cff", ".bdf", ".pcf", ".snf", ".mm", ".otb", ".dfont", ".bin", ".sfd", ".t42", ".t1", ".fon", ".fnt"]
scriptExtensions = [".jl"]
extensionsDict = Dict("images" => imageExtensions, "sounds" => soundExtensions, "fonts" => fontExtensions, "scripts" => scriptExtensions)

function display_files(base_path::String, file_type::String, title::String = "", depth::Int = 1; default::String = "")::String
    extensions = extensionsDict[file_type] 
    value = ""

    pathName = split(base_path, "/")[end]
    pathName = split(pathName, "\\")[end]

    if title == ""
        title = pathName
    end

    if CImGui.BeginMenu("$(title)") 
        if default != ""
            if CImGui.MenuItem("Default: $(default)")
                value = "Default"
            end
        end
        for file::String in readdir(joinpath(base_path))
            if isdir(joinpath(base_path, file))
                value = display_files(joinpath(base_path, file), file_type, "", depth+1)
                if value != ""
                    break
                end
            else
                extension = ".$(split(file, ".")[end])"
                if extension in extensions
                    if CImGui.MenuItem(file)
                        value = "$(joinpath(base_path, file))"
                        if file_type == "scripts"
                            value = split(file, ".")[1]
                        end
                    end
                end
            end
        end
        CImGui.EndMenu()
    end

    return value
end