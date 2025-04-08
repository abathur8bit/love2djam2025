--[[
    Things to do:
        
    - Make it so we can check if a player is dead
    - Make it so the monsters keeps track of the same target as at the moment, it might randomly switch every frame
    - Finish ghost behaviour
]]

-- List of behaviours for the enemies to use
local Behaviours = {

    -- Ghost behaviour, picks a player and follows them until it touches and kills them instantly
    ghost = function(monster, dt)
        
        -- Reduce melee timer
        monster.meleeTimer = monster.meleeTimer - dt

        -- Select the first player that isn't dead
        local found_player
        for key, player in pairs(monster.world.players) do
        
            -- Set new movement target for the player
            monster.targetMoveTimeout = 0
            monster.targetMove = {{x = player.x, y = player.y}}
            found_player = true
            if found_player then break end
        end
    end,

    -- Basic behaviour, if you see an enemy, move towards them
    basic = function(monster, dt)
        local ts = monster.world.tileSize

        -- Reduce melee timer
        monster.meleeTimer = monster.meleeTimer - dt

        -- Check players to see if it can see one
        local found_player
        for key, player in pairs(monster.world.players) do
            if monster.world:checkPositionVisible(monster.x, monster.y, player.x, player.y) then
                
                -- Set new movement target for the player
                monster.targetMoveTimeout = 0
                monster.targetMove = {{x = player.x, y = player.y}}
                found_player = true
            end
            if found_player then break end
        end
    end,

    -- Sense behaviour, if the enemy is close enough to a player, then will start to path towards their position around the map
    sense = function(monster, dt)
        local ts = monster.world.tileSize

        -- Reduce melee timer
        monster.meleeTimer = monster.meleeTimer - dt

        -- Check players to see if it can see one
        local found_player
        for key, player in pairs(monster.world.players) do
            if monster.world:checkPositionVisible(monster.x, monster.y, player.x, player.y) then
                
                -- Set new movement target for the player
                monster.targetMoveTimeout = 0
                monster.targetMove = {{x = player.x, y = player.y}}
                found_player = true
            
            -- Can't see the player, has no target move, see if it can 'sense' them (up to 8 tiles away)
            elseif not monster.targetMove and checkDistance(monster.x, monster.y, player.x, player.y, ts * 8) then

                -- Path to that position
                monster.targetMoveTimeout = 0
                monster.targetMove = monster.world:getPath(monster.x, monster.y, player.x, player.y)
                found_player = true
            end
            if found_player then break end
        end
    end,

    -- Basic ranger
    basic_ranger = function(monster, dt)
        local ts = monster.world.tileSize

        -- Reduce melee timer
        monster.meleeTimer = monster.meleeTimer - dt

        -- Reduce attack cooldown
        monster.fireRateTimer = monster.fireRateTimer - dt

        -- Check players to see if it can see one
        local found_player
        for key, player in pairs(monster.world.players) do
            if monster.world:checkPositionVisible(monster.x, monster.y, player.x, player.y) then

                -- Check distance
                if not checkDistance(monster.x, monster.y, player.x, player.y, ts * 8) then
                
                -- Set new movement target for the player
                monster.targetMoveTimeout = 0
                monster.targetMove = {{x = player.x, y = player.y}}
                else

                -- Remove targetMove
                monster.targetMove = nil
                end

                -- Check distance in range
                if checkDistance(monster.x, monster.y, player.x, player.y, ts * monster.fireRange) then
                
                -- Fire a bullet
                monster:monsterFireBullet(player.x, player.y)
                end
                found_player = true
            end
            if found_player then break end
        end
    end,

    -- Sense ranger
    sense_ranger = function(monster, dt)
        local ts = monster.world.tileSize

        -- Reduce melee timer
        monster.meleeTimer = monster.meleeTimer - dt

        -- Reduce attack cooldown
        monster.fireRateTimer = monster.fireRateTimer - dt

        -- Check players to see if it can see one
        local found_player
        for key, player in pairs(monster.world.players) do
            if monster.world:checkPositionVisible(monster.x, monster.y, player.x, player.y) then

                -- Check distance
                if not checkDistance(monster.x, monster.y, player.x, player.y, ts * 8) then
                
                -- Set new movement target for the player
                monster.targetMoveTimeout = 0
                monster.targetMove = {{x = player.x, y = player.y}}
                else

                -- Remove targetMove
                monster.targetMove = nil
                end

                -- Check distance in range
                if checkDistance(monster.x, monster.y, player.x, player.y, ts * monster.fireRange) then
                
                -- Fire a bullet
                monster:monsterFireBullet(player.x, player.y)
                end
                found_player = true

            -- Can't see the player, has no target move, see if it can 'sense' them (up to 8 tiles away)
            elseif not monster.targetMove and checkDistance(monster.x, monster.y, player.x, player.y, ts * 8) then

                -- Path to that position
                monster.targetMove = monster.world:getPath(monster.x, monster.y, player.x, player.y)
                found_player = true
            end
            if found_player then break end
        end
    end,

    -- Boss
    boss = function(monster, dt)
        local ts = monster.world.tileSize

        -- Phases
        monster.phaseTimer = monster.phaseTimer or 10
        monster.phase = monster.phase or 1
        monster.targetMoveTimeout = 0

        -- Reduce attack cooldown
        monster.fireRateTimer = monster.fireRateTimer - dt

        -- Phase 1-- Chase the player and fire a burst of 3 shots
        if monster.phase == 1 then

        -- Set speed for this phase
        monster.speed = 175

        -- Increase phase timer
        monster.phaseTimer = math.max(0, monster.phaseTimer - dt)
        
        -- Check players to see if it can see one
        local found_player
        for key, player in pairs(monster.world.players) do
            if monster.world:checkPositionVisible(monster.x, monster.y, player.x, player.y) then

                -- Check distance
                if not checkDistance(monster.x, monster.y, player.x, player.y, ts * 3) then
                    
                    -- Set new movement target for the player
                    monster.targetMove = {{x = player.x, y = player.y}}
                else

                    -- Remove targetMove
                    monster.targetMove = nil
                end

                -- Check distance in range
                if checkDistance(monster.x, monster.y, player.x, player.y, ts * 50) and monster.fireRateTimer <= 0 then

                    -- Get angle of shot
                    local theta = math.atan2(player.y - monster.y, player.x - monster.x)
            
                    -- Fire a barrage of bullets
                    local angle_space = 0.24
                    for i = 1, 3 do
                    monster.fireRateTimer = 0
                    if i==1 then
                        monster:monsterFireBullet(player.x, player.y)
                    elseif i%2==0 then
                        monster:monsterFireBullet(
                        monster.x + math.cos(theta - angle_space * math.floor(i*0.5)) * 50,
                        monster.y + math.sin(theta - angle_space * math.floor(i*0.5)) * 50
                        )
                    else
                        monster:monsterFireBullet(
                        monster.x + math.cos(theta + angle_space * math.floor(i*0.5)) * 50,
                        monster.y + math.sin(theta + angle_space * math.floor(i*0.5)) * 50
                        )
                    end
                    end
                    monster.fireRateTimer = monster.fireRate
                end
                found_player = true
            end
            if found_player then break end
        end
        
        -- Move to one of the corners and change to Phase 2
        if monster.phaseTimer <= 0 then
            monster.phase = 2
            monster.phaseTimer = 10
            monster.fireRate = 2.5
            monster.meleeTimer = 1

            -- Set a movement target
            local world = monster.world
            local map = world.map
            local list = {}
            if map.layers["generators"] then
            for _,generator in pairs(map.layers["generators"].objects) do
                if generator.name=="boss" then
                list[#list + 1] = {x = generator.x, y = generator.y}
                end
            end
            end

            -- Set new movement target for the boss
            monster.targetMove = {list[math.random(1, #list)]}
        end

        -- Phase 2
        elseif monster.phase == 2 then

        -- Set speed for this phase
        monster.speed = 350

        -- Check for no movement
        if not monster.targetMove then

            -- Increase phase timer
            monster.phaseTimer = math.max(0, monster.phaseTimer - dt)

            -- Check players to see if it can see one
            local found_player
            for key, player in pairs(monster.world.players) do
                if monster.world:checkPositionVisible(monster.x, monster.y, player.x, player.y) then

                    -- Check distance in range
                    if checkDistance(monster.x, monster.y, player.x, player.y, ts * 50) and monster.fireRateTimer <= 0 then

                    -- Get angle of shot
                    local theta = math.atan2(player.y - monster.y, player.x - monster.x)
            
                    -- Fire a barrage of bullets
                    local angle_space = 0.25
                    for i = 1, 13 do
                        monster.fireRateTimer = 0
                        if i==1 then
                        monster:monsterFireBullet(player.x, player.y)
                        elseif i%2==0 then
                        monster:monsterFireBullet(
                            monster.x + math.cos(theta - angle_space * math.floor(i*0.5)) * 50,
                            monster.y + math.sin(theta - angle_space * math.floor(i*0.5)) * 50
                        )
                        else
                        monster:monsterFireBullet(
                            monster.x + math.cos(theta + angle_space * math.floor(i*0.5)) * 50,
                            monster.y + math.sin(theta + angle_space * math.floor(i*0.5)) * 50
                        )
                        end
                    end
                    monster.fireRateTimer = monster.fireRate
                    end
                    found_player = true
                end
                if found_player then break end
            end

            -- If it's the end of the phase, change to phase 1
            if monster.phaseTimer <= 0 then
            monster.fireRate = 0.5
            monster.phase = 3
            monster.phaseTimer = 12
            monster.meleeTimer = 1

            -- Spawn in enemies
            local world = monster.world
            local map = world.map
            local list = {}
            if map.layers["generators"] then
                for _,generator in pairs(map.layers["generators"].objects) do
                if generator.name=="generator" then
                    list[#list + 1] = {x = generator.x, y = generator.y}
                end
                end
            end

            -- Spawn an enemy at each generator
            for i = 1, #list do
                local generator = list[i]
                world:addMonster(createMonster(world,1,generator.x,generator.y,"basic"))
                world:addMonster(createMonster(world,1,generator.x,generator.y,"basic"))
                world:addMonster(createMonster(world,1,generator.x,generator.y,"basic_ranger"))
            end
            end
        end

        -- Phase 3
        elseif monster.phase == 3 then

        -- Set speed for this phase
        monster.speed = 350

        -- Increase phase timer
        monster.phaseTimer = math.max(0, monster.phaseTimer - dt)

        -- Check for no movement
        if not monster.targetMove then

            -- Set a movement target
            local world = monster.world
            local map = world.map
            local list = {}
            if map.layers["generators"] then
            for _,generator in pairs(map.layers["generators"].objects) do
                if generator.name=="boss" then
                list[#list + 1] = {x = generator.x, y = generator.y}
                end
            end
            end

            -- Set new movement target for the boss
            monster.targetMove = {list[math.random(1, #list)]}
        end

        -- Check players to see if it can see one
        local found_player
        for key, player in pairs(monster.world.players) do
            if monster.world:checkPositionVisible(monster.x, monster.y, player.x, player.y) then

                -- Check distance in range
                if checkDistance(monster.x, monster.y, player.x, player.y, ts * 50) then
                    monster:monsterFireBullet(player.x, player.y)
                end
                found_player = true
            end
            if found_player then break end
        end

        -- If it's the end of the phase, change to phase 1
        if monster.phaseTimer <= 0 then
            monster.fireRate = 1.25
            monster.phase = 1
            monster.phaseTimer = 10
        end
        end
    end,
}
return Behaviours