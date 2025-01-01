[![codecov](https://codecov.io/gh/Kyjor/JulGame.jl/graph/badge.svg?token=535VSQ21MJ)](https://codecov.io/gh/Kyjor/JulGame.jl)

[Documentation](https://docs.kyjor.io/JulGame.jl)

[Trello board](https://trello.com/b/M6uH0Jmy/julgame)
![JulGame Logo](https://github.com/Kyjor/JulGame.jl/assets/13784123/f68ece3a-62a1-48fb-a905-c7c8b9aa35c1)

![The Jester](https://github.com/Kyjor/JulGame.jl/assets/13784123/61c51bab-557d-4712-86a8-59ab91350667)
![CoinGrabber](https://github.com/Kyjor/JulGame.jl/assets/13784123/43811fd4-781d-4530-9de0-59c282b27710)

![JulGameEditor](https://github.com/Kyjor/JulGame.jl/assets/13784123/c4ad139f-4d78-47f9-9d13-7bfd150e81bf)


[Example Repo](https://github.com/Kyjor/JulGame-Example)

## Support

If you want to support development, feel free to check out my [discord server](https://discord.gg/RGMkdzW), or my [YouTube channel](https://www.youtube.com/@kyjor_) where I make videos about game development

## What is JulGame?

JulGame is an open-source game engine meant for creating 2D games (and 3d games... eventually) using the [Julia programming language](https://julialang.org/). JulGame uses [SDL2](https://github.com/JuliaMultimedia/SimpleDirectMediaLayer.jl/), and [CImGui](https://github.com/Gnimuc/CImGui.jl) for the editor. The plan for 3d will be to use OpenGL.

## Why did I make it?

Because I find Julia interesting and I've always wanted to create a game engine. I would like to see a game dev scene around it as there isn't much of one now. I am not a Julia programmer (nor an experienced game engine creator), so I am sure there is a lot I am doing wrong. If you see anything that I can fix, please just let me know with a discussion or an issue.

## Why JulGame?

I thought that JulGame would be a great play on Pygame. I also think it just rolls off the tongue. Also, I recently found out that "Jul" is the etymological root of “[jolly](https://en.m.wiktionary.org/wiki/j%C3%B3l#Icelandic)”, so it makes for a great pun :)

## How to get started?

`] add JulGame` for the latest in the package manager

`] add https://github.com/Kyjor/JulGame.jl` for main - RECOMMENDED as this should be the most stable branch.

`] add https://github.com/Kyjor/JulGame.jl#develop` for develop, which will have bleeding edge changes.

Either download the latest release of the editor, or run it by navigating to `JulGame\src\editor\Editor\src\Editor.jl`
and run `julia Editor.jl`

## How do you use it?

Once you have the editor open, download the [example](https://github.com/Kyjor/JulGame-Example), unzip it, and then open the folder with the editor. 

🔴Warning🔴 Save often! The editor may crash! We do attempt to save a backup for unhandled errors though. But it is better to be safe than sorry.

![JulGameEditorOpenScene](https://github.com/Kyjor/JulGame.jl/assets/13784123/0e1ab178-c28e-4c9e-b820-6f2d17916085)

### How do you run your scene?
Navigate to your project, and cd to the directory with `Run.jl`, and run `julia Run.jl`, and it should start!

## What needs to be done?
#### General 
- [ ] Documentation
- [ ] Video tutorial
### 2D Engine
#### General
- [x] Entities can be children of other entities, with editor support
- [x] Tests (continuously improving)
- [ ] Prefabs (like Unity Engine)
- [ ] Engine time system
#### Visuals
- [X] Simple Rendering
- [ ] Basic particle system
#### Physics
- [ ] Implement box2d support
- [ ] Raycasting
#### Animation
- [ ] Animate all properties of entites
#### Input
- [ ] Controller support
#### Scene Management
- [x] Multiple scene support
#### Editor Features
- [x] Sprite cropping tool for animations
- [ ] Hot reloading with [Revise.jl](https://github.com/timholy/Revise.jl) if possible
- [ ] Profiling 
- [x] Debug console
- [x] SDLRenderer Backend
- [x] Scene Grid
- [ ] Tilemap editor
- [ ] Multi-select entities in hierarchy and editor (in progress...)
- [ ] Right click context menus
### 3D Engine
- [ ] SDL renderer geometry
- [ ] OpenGL
- [ ] WebGPU
### Build Support
- [X] Windows
- [ ] Mac
- [ ] Linux
- [ ] Web
- [ ] Mobile
- [ ] Console


## Inspirations/Credits
This is a list of references that I used in order to get JulGame where it is, along with people who inspired the creation of this (who you should definitely check out!)
- [Solar Lune](https://github.com/SolarLune/tetra3d), who is creating a 3d renderer. This format for the readme is also referencing theirs.
- [Coder Gopher](https://www.youtube.com/channel/UCfiC4q3AahU4Io-s83-CIbQ), who has tutorials that helped me get started with SDL.
- [Lazy foo](https://lazyfoo.net/), who has tutorials that brought me the rest of the way with SDL.
- and so many others who I will note some of in the future :)

## Games Made With JulGame
Here I will be keeping a list for the first **original** games created with JulGame by external contributors (aka not me). If you would like to see games that I have made, check them out at https://kyjor.itch.io

1.
2.
3.
4.
5.
6.
7.
8.
9.
10.
