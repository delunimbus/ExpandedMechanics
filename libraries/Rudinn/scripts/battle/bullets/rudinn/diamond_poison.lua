local DiamondPoison, super = Class(Bullet)

function DiamondPoison:init(x, y, dir)
    super.init(self, x, y, "bullets/rudinn/diamond_white")

	self:setScale(1, 1)
    self.rotation = dir
    self.physics.speed = 6
	self.physics.match_rotation = true

	self.status_conditions = {"poison"}
end

function DiamondPoison:update()
	super.update(self)
	self.sprite:setColor(0, 0.5, 0)
end

return DiamondPoison