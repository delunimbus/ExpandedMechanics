local Aiming, super = Class(Wave)

function Aiming:init()

    super.init(self)

    --self.time = 15

end

function Aiming:onStart()
    -- Every 0.5 seconds...
    local magic_bullet = false
    self.timer:every(1/2, function()

        local mana_chance = love.math.random(1, 5)
        -- Get all enemies that selected this wave as their attack
        local attackers = self:getAttackers()

        -- Loop through all attackers
        for _, attacker in ipairs(attackers) do

            -- Get the attacker's center position
            local x, y = attacker:getRelativePos(attacker.width/2, attacker.height/2)

            -- Get the angle between the bullet position and the soul's position
            local angle = Utils.angle(x, y, Game.battle.soul.x, Game.battle.soul.y)

            -- Spawn smallbullet angled towards the player with speed 8 (see scripts/battle/bullets/smallbullet.lua)
            if mana_chance >= 4 then
                self:spawnBullet("smallmanabullet", x, y, angle, 8)
                --magic_bullet = false
            else
                self:spawnBullet("smallbullet", x, y, angle, 8)
                --magic_bullet = true
            end

        end
    end)
end

function Aiming:update()
    -- Code here gets called every frame


    super.update(self)
end

return Aiming