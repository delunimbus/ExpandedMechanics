local SmallBullet, super = Class(Bullet)

function SmallBullet:init(x, y, dir, speed)

    -- Last argument = sprite path
    super.init(self, x, y, "bullets/smallmanabullet")

    -- Move the bullet in dir radians (0 = right, pi = left, clockwise rotation)
    self.physics.direction = dir
    -- Speed the bullet moves (pixels per frame at 30FPS)
    self.physics.speed = speed

    ---------
    self.alt_damage = {
        ["name"] = "mana",
        ["value"] = (self.attacker and self.attacker.attack * 5)
    }

    self.deplete_resources = {"mana"}
    --self.magic_damage_to_resources = {"mana"}
    self.magic_damage = true


end

function SmallBullet:onDamage(soul)

    --Use the "true" value as follows to use the table option.
    super.onDamage(self, soul, true)

end

function SmallBullet:update()
    -- For more complicated bullet behaviours, code here gets called every update

    super.update(self)
    

end


return SmallBullet