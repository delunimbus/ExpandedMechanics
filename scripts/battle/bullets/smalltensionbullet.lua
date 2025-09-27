local SmallBullet, super = Class(Bullet)

function SmallBullet:init(x, y, dir, speed)

    -- Last argument = sprite path
    super.init(self, x, y, "bullets/smalltensionbullet")

    -- Move the bullet in dir radians (0 = right, pi = left, clockwise rotation)
    self.physics.direction = dir
    -- Speed the bullet moves (pixels per frame at 30FPS)
    self.physics.speed = speed

    -- TP added when you graze this bullet (Also given each frame after the first graze, 30x less at 30FPS)
    self.tp = (1.6)*2 -- (1/10 of a defend, or cheap spell)
    -- Turn time reduced when you graze this bullet (Also applied each frame after the first graze, 30x less at 30FPS)
    self.time_bonus = 0.8

    self.inv_timer = (1/2)

    ---------
    self.deplete_resources = {"tension"}
    --------

end

--function SmallBullet:onDamage(soul)
    
--end

function SmallBullet:update()
    -- For more complicated bullet behaviours, code here gets called every update

    super.update(self)
end

return SmallBullet