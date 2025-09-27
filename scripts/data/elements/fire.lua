local Fire, super = Class(Element)

function Fire:init()
    super.init(self)

    self.name = "Fire"

    self.weaknesses = {}
    self.resistances = {}
    self.immunities = {}
    self.abosorptions = {}

end

return Fire