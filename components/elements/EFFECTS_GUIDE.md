
# Effects Guide

## TYPE | Int

Element types can be either purely ELEMENT (0) or ESSENCE (1)

Elements are basic and can fit in every input slot, essences are a bit different

## RECIPE | Array

Contains an array of elements that were consumed to generate this one. Only present on type 1 elements.

## EFFECT_METADATA | Dictionary / Array

Contains varied values needed for projectile applied effects, and can change based on ___etype___ given. Certain values are converted to a Godot compatible data type, such as a color hex being transformed into a [Color data type](https://docs.godotengine.org/en/stable/classes/class_color.html). This is done by ElementManager itself during load.

In case the EffectMetadata is an Array, this is a complex element that causes a variety of active buffs/debuffs that can differ, such as Ice is capable of dealing Freeze to enemies after completing stacks of Frostbite.

* ### EID | Int

Individual number of each element present in the dictionary. Loads automatically based on the exact order of elements within the file.

Be careful with that! Adding elements within other elements means every other subsequent element will change its EID by one.

* ### LEVELS | Int

Defaults to **zero** and is inserted only when tied to a tower, reflecting the tower level itself.

* ### ETYPES | Int

    Defines how an effect is computed in a match case function by EffectComponent class node.

    - 000 : DEBUG
    - 001 : DAMAGE_PER_TICK
    - 002 : ADD_VULNERABILITY
    - 003 : MOVEMENT_CHANGE
    - 004 : PROJECTILE_CHANGE
    - 005 : TOWER_CHANGE
    - 005 : CONDITIONAL_PROC

## COMBINATIONS | Dictionary

Queryable dictionary of strings that contains references to other elements to combine!
