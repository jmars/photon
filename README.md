# Photon
A fork of the [lite](https://github.com/rxi/lite) editor with just the core
pulled out for building small apps. With the goal of putting together simple concepts in a way that works better than the sum of the parts.

## Current Features
* View physics animation via a first degree ODE solver
* Event handling with local and global methods
* Constraint based layout using the cassowary linear constraint solver (which is respected by the physics engine)
* Multi-container text layout ala iOS TextKit, with batched rendering

![WIP](https://github.com/jmars/photon/raw/master/example.gif)

## TODO
* Set of basic components
* Script to build self contained app
* Networking
* Example HN reader app