local VirusTension, super = Class(Bullet)

function VirusTension:init(x, y)
    super.init(self, x, y)

    self:setSprite("bullets/virovirokun/virus_tension", 3/30, true)
    self:setHitbox(5, 5, 6, 6)

    self.physics.speed = 0.1
    self.physics.friction = -0.1
    self.physics.direction = Utils.angle(self.x, self.y, Game.battle.soul.x, Game.battle.soul.y)

    self.deplete_resources = {"tension"}
end


return VirusTension