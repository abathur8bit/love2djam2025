--[[
    Things to do :
    - Finish ghost stats
    - Add a ghost sprite as it currently just copies a generic bad guy one
]]

local Behaviours = require('monsters.monster_behaviours')

-- Images
local Assets = {
    badguy1 = love.graphics.newImage("assets/badguy-01-sheet-48x48.png"),
    badguy2 = love.graphics.newImage("assets/badguy-02-sheet-48x48.png"),
    king = love.graphics.newImage("assets/kingsprites.png"),
    ghost = love.graphics.newImage("assets/badguy-01-sheet-48x48.png"),
}

local Monsters = {

    -- Ghost
    ghost = function()
        return {
            name = 'ghost',
            type = 'monster',
            behaviour = Behaviours.ghost,
            sheet = Assets.ghost,
            w = 48,
            h = 48,
            health = 999999999999,
            speed = 50,
            meleeDamage = 999999999999,
        }
    end,

    -- Basic
    basic = function()
        return {
            name = 'basic',
            type = 'monster',
            behaviour = Behaviours.basic,
            sheet = Assets.badguy1,
            w = 48,
            h = 48,
            health = 1000,
            speed = 100,
            meleeDamage= 100,
            meleeTimer = 1,
            fireRate = 2,
            fireRange = 2,
            firePower = 'monster',
        }
    end,

    -- Sense    
    sense = function()
        return {
            name = 'sense',
            type = 'monster',
            behaviour = Behaviours.sense,
            sheet = Assets.badguy1,
            w = 48,
            h = 48,
            health = 1000,
            speed = 100,
            meleeDamage= 100,
            meleeTimer = 1,
            fireRate = 2,
            fireRange = 2,
            firePower = 'monster',
        }
    end,

    -- Basic ranger
    basic_ranger = function()
        return {
            name = 'basic_ranger',
            type = 'monster',
            behaviour = Behaviours.basic_ranger,
            sheet = Assets.badguy2,
            w = 48,
            h = 48,
            health = 500,
            speed = 100,
            meleeDamage= 100,
            meleeTimer = 1,
            fireRate = 2,
            fireRange = 2,
            firePower = 'monster',
        }
    end,

    -- Sense ranger
    sense_ranger = function()
        return {
            name = 'sense_ranger',
            type = 'monster',
            behaviour = Behaviours.sense_ranger,
            sheet = Assets.badguy2,
            w = 48,
            h = 48,
            health = 500,
            speed = 100,
            meleeDamage= 100,
            meleeTimer = 1,
            fireRate = 2,
            fireRange = 2,
            firePower = 'monster',
        }
    end,

    -- Boss
    boss = function()
        return {
            name = 'boss',
            type = 'monster',
            behaviour = Behaviours.boss,
            sheet = Assets.king,
            w = 192,
            h = 192,
            health = 80000,
            speed = 100,
            meleeDamage= 100,
            meleeTimer = 1,
            fireRate = 2,
            fireRange = 2,
            firePower = 'monster',
        }
    end,
}
return Monsters