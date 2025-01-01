---
title: What is JulGame?
description: An explanation of the engine, along with it's current features and wishlist.
---

![JulGame Logo](https://github.com/Kyjor/JulGame.jl/assets/13784123/f68ece3a-62a1-48fb-a905-c7c8b9aa35c1)

![The Jester](https://github.com/Kyjor/JulGame.jl/assets/13784123/61c51bab-557d-4712-86a8-59ab91350667)

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

`] add https://github.com/Kyjor/JulGame.jl` for main - RECOMMENDED as any bug fixes will immediately go here.

`] add https://github.com/Kyjor/JulGame.jl#develop` for develop

Either download the latest release of the editor, or run it using the Julia REPL:

`using JulGame`
`JulGame.Editor.run()`

## How do you use it?

Once you have the editor open, download the [example](https://github.com/Kyjor/JulGame-Example), unzip it, and then enter the path to the root of the project along with the scene name (scene.json) in the editor under the `Project Location` window. Poke and prod around to figure things out until we have some real docs :) 

🔴Warning🔴 Save often! The editor will crash with no remorse! Any big changes you make, save immediately.

![JulGameEditorOpenScene](https://github.com/Kyjor/JulGame.jl/assets/13784123/0e1ab178-c28e-4c9e-b820-6f2d17916085)

### How do you run your scene?
Navigate to your project, and cd to the directory with `Entry.jl`, and run `julia Entry.jl`, and it should start!

## What needs to be done?
#### General 
- [ ] Documentation
- [ ] Video tutorial
### 2D Engine
#### General
- [ ] Entities can be children of other entities, with editor support
- [ ] Tests
- [ ] Prefabs (like Unity Engine)
- [ ] Engine time system
#### Visuals
- [X] Simple Rendering
- [ ] Basic particle system
#### Physics
- [ ] Better physics in general
- [ ] More efficient collision handling
- [ ] Raycasting
#### Animation
- [ ] More options than just item crop
#### Input
- [ ] Controller support
#### Scene Management
- [ ] Multiple scene support
#### Editor Features
- [ ] Sprite cropping tool for animations
- [ ] Hot reloading with [Revise.jl](https://github.com/timholy/Revise.jl) if possible
- [ ] Profiling 
- [ ] Debug console
- [ ] A better way to display the scene. There is no SDL backend support for the port of CImGui, so we are stuck rendering two separate windows at the moment
- [ ] Scene Grid
- [ ] API
- [ ] Tile map editor
- [ ] Multi-select entities
- [ ] Right click context menus
### 3D Engine
- [ ] 3D rendering
- [ ] A robust list of 3D engine features...
### Build Support
- [X] Windows
- [ ] Mac
- [ ] Linux - May have to use LDTK
- [ ] Web ???
- [ ] Mobile ???
- [ ] Console ???


## Inspirations/Credits
This is a list of references that I used in order to get JulGame where it is, along with people who inspired the creation of this (who you should definitely check out!)
- [Solar Lune](https://github.com/SolarLune/tetra3d), who is creating a 3d renderer. This format for the readme is also referencing theirs.
- [Coder Gopher](https://www.youtube.com/channel/UCfiC4q3AahU4Io-s83-CIbQ), who has tutorials that helped me get started with SDL.
- [Lazy foo](https://lazyfoo.net/), who has tutorials that brought me the rest of the way with SDL.
- and so many others who I will note some of in the future :)

## Games Made With JulGame
Here I will be keeping a list for the first games created with JulGame :)

1. [The Jester](https://kyjor.itch.io/the-jester)
2.
3.
4.
5.
6.
7.
8.
9.
10.