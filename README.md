# Photon
A fork of the [lite](https://github.com/rxi/lite) editor with just the core
pulled out for building small apps. Lua POC replaced with luajit and the cassowary constraint solver (amoeba) have been added.

## Current Features
* View physics animation via a first degree ODE solver
* Event handling with local and global methods
* Constraint based layout using the cassowary linear constraint solver (which is respected by the physics engine)

![WIP](https://github.com/jmars/photon/raw/master/example.gif)

## TODO
* Set of basic components
* Script to build self contained app
* Networking
* Text layout engine
