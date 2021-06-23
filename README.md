## Summary

Video Game, written with [HaxeFlixel](https://haxeflixel.com/), uses [LDtk](https://ldtk.io/) for map editing

## How to get started

Below are instructions for development, and level editing.
It is possible to just run the level editor on it's own, however to see it in action, you'll need to get development working.

### LDtk

1. Install LDtk
2. Load the file in `assets/levels/cart-game.ldtk`

### HaxeFlixel / Development

These instructions are based on [HaxeFlixel's Getting Started Guide](https://haxeflixel.com/documentation/getting-started/)

#### Install Haxe

1. Go to https://haxe.org/download/, and install the installer for your platform.
2. Check that you have `haxelib` as a command in your terminal session
(if you don't, you may need to restart your machine for it to be picked up)

#### Install HaxeFlixel

After you've installed Haxe and `haxelib` functions correctly, you should be able to run the following in the project directory:
```
haxelib install lime
haxelib install openfl
haxelib install flixel

haxelib install deepnightLibs
haxelib install ldtk-haxe-api

haxelib run lime setup flixel
haxelib run lime setup
```

#### Running the Project

At this point, you should have `lime` as a command on your terminal, and be able to run the following
```
lime test html5
```

If you have have Visual Studio Code, you can [setup using tasks](https://haxeflixel.com/documentation/visual-studio-code/)
