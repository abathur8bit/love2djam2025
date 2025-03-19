# Love2D Jam 2025
Game submission for [love jam 2025](https://itch.io/jam/love2d-jam-2025)

# Running
To run, execute the EXE file, or you need to have love installed and type

```
love .
```

# Notes
- Need to be able to find the object based on the collision from HC.collisions()
- Need to be able to know what the object is, a wall, trigger, key, powerup, monster, monster bullet, player bullet 
- ablity to remove the hitbox from HC, and world


# Collisions
## Player hit something
- Player with wall: not allow to pass through
- Player with door: act like a wall
- Player with key: Opens doors of the same number
- Player with powerup: Allows the player to add to inventory
- Monster: takes damage, remove monster from HC & world
- Bullet: if bullit is not the players, take damage
- Player bullet: ignore, bullet just goes through

## Bullet
- Hits a player (will probably already be processed)
  - player takes damage
  - bullet is removed from HC and world
- Hits a wall
  - bullet is removed from HC and world
  - hits another monster, ignored, keeps going

## Monster
- Hits a player (already processed by player check)
  - player takes damage
  - monster is destroyed, removed from HC and world


# todo
- refactor hitbox creation
- renamed door-01 to key-01 and wall-01 to door-01

# hitbox
.name
.type "trigger" "wall" "bullet" "sprite"
.collider 
.object 

- key
  - type: trigger
  - object name: key-01
    - name key
    - number 01
- door
  - type: trigger
  - object name: door-01
  - name: door
  - number: 01
- wall
  - type: wall
- trigger


shape
 player
 monster
 powerup
 door