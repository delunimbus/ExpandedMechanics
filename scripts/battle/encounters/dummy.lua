local Dummy, super = Class(Encounter)

--sorry, only one encounter was used for this whole time

function Dummy:init()
    super.init(self)

    -- Text displayed at the bottom of the screen at the start of the encounter
    self.text = "* The tutorial begins...?"

    self.background = true

    -- Add the dummy enemy to the encounter
    --self:addEnemy("dummy")

    --- Uncomment this line to add another!
    self:addEnemy("virovirokun")

    self:addEnemy("dummy")

    self:addEnemy("rudinn")
end

return Dummy