# Lightkeepers

Lightkeepers is a __tower defense game about forbidden knowledge to protect a light beacon in an endless night__ made in Godot 4.2 and then updated to Godot 4.3. It is a prototype with many functioning modular components that can (and will be) reused in further projects. This is both a prototype and my first publicly available game to play.

## Development features

It's rather complex as a whole, but all components/scripts are populated with explanations, documentations and examples, for people like me who are used to learn reading and trying it out. It has foundational tools of our workflow, such as:

* Modular CI/CD pipeline with GitHub Actions to upload games directly to itch.io based on repository and environmental variables.
  * The guide to properly configure and use the Actions is public.
  * The pipeline also patches web builds by renaming the <kbd>.html</kbd> file to <kbd>index.html</kbd> during runtime, avoiding manual intervention.

## Game features

Some of the features present on the game code are:

* Singletons (Autoload)
  * Options
    * Sound sliders
    * Language options
    * Keybinding menu for remapping controls
  * UI
    * Interface - Contains HP, coins, menus, and tools all in scalable Control nodes; has a lot of functions to deal with clicks/touch
    * ScreenTransition - Fade-in and fade-out transition using an outdated _but stylish_ shader
* Components
  * HitboxComponent - Recieves data from collision boxes and polygons. Mostly used together with HealthComponent.
  * HealthComponent - Controls the health of all entities of the game, with heal, damage and death functions.
  * DropComponent - Drops items based on the id of the entity that owns it, recieves items from a .JSON file.
  * CombatComponent - Adds targeting system on enemies, debuffs, etc.
* StateMachines
  * A visually comprehensible system of States based on children nodes hierarchy. Used in everthing that has to change behaviors, such as towers and complex enemies.
* Player interaction
  * Camera movement, controls, and zoom - all with mouse. Keyboard is optional!
   * Drag and drop based actions
    * Varying drag and drops tools, such as the Hammer used to demolish turrets 
    * DraggableObjects class and functions composing drag-n-drop elements
    * ControlSlot class to contain DraggableObjects into Control nodes between UI layers
* StageManager
  * StageManager + WaveManager - Event controller and threat spawner based on resources and easy to change directly on the UI.
    * Wave resource (Singular wave with enemy data, positions and schedules)
    * Waves resource (Stores an array of Waves that can be iterated by WaveManager)
* Graphics
  * Pixel art sprites made in Aseprite and Krita (Asset pack is included)
  * Animated sprites
  * Godot Theme template and insights
  * [Using Technogarten palette](https://lospec.com/palette-list/technogarten)
    * Other palettes can be inserted into the ScreenEffect node and change the game visuals easily, but it's not very performatic; This was made before we could use Compositors.

## Planned updates

* Gameplay improvements
  * New stages with dynamic challenges
  * Varied events
  * More combinations of elements
  * Tutorial stage
  * Endless mode
* Balancing
  * More tests and tuning base properties of towers and elements
  * More variety of enemies and specialization
* More animated sprites

## About the concept

It was intended to be part of PirateSoftware's Game Jam 15 with the theme being 'Shadows and Alchemy', but we've got too busy with work to finish it on time. So, we finished it a whole month later when we got time. Game jams are fun anyways! The [GDD is public if you want to take a peak](https://docs.google.com/document/d/1nb8W2nfbvZG5j-VU5RlQVSO8bTTNwSxyx9r4B_TWXfo/edit?usp=sharing).
