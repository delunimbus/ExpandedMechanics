local MultiBasic, super = Class(Wave)

function MultiBasic:init()

    super.init(self)

    self.time = 7

end

function MultiBasic:onStart()
    -- Every 0.33 seconds...
    local random_chance = 0
    self.timer:every(1/3, function()
        random_chance = love.math.random(1, 3)

        -- Our X position is offscreen, to the right
        local x = SCREEN_WIDTH + 20
        -- Get a random Y position between the top and the bottom of the arena
        local y = Utils.random(Game.battle.arena.top, Game.battle.arena.bottom)

        local bullet = nil
        -- Spawn smallbullet going left with speed 8 (see scripts/battle/bullets/smallbullet.lua)
        if random_chance == 3 then
            bullet = self:spawnBullet("smalltensionbullet", x, y, math.rad(180), 8)
        else bullet = self:spawnBullet("smallmanabullet", x, y, math.rad(180), 8) end
        -- Dont remove the bullet offscreen, because we spawn it offscreen
        bullet.remove_offscreen = false
    end)
end

function MultiBasic:update()
    -- Code here gets called every frame
    ---print("aaaaaaaaaaaaaaaaaaaaaaaa")
    super.update(self)
end

return MultiBasic