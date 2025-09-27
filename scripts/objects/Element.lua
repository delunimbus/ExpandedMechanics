---Fully fledged elements class
---
---@class Element : Class
---
---@field name          string          Name of the element
---
---@field weaknesses    string[]        Elements that this one is weak to
---@field resistances   string[]        Elements that this one is resistant to
---@field immunities    string[]        Elements that this one is immune to
---@field absorptions   string[]        Elements that this one abosorbs
---
---@field icon          string          The icon of the element.
---
---@overload fun(...) : Element
local Element = Class()

function Element:init()

    self.name = "Test Element"

    self.weaknesses = {}
    self.resistances = {}
    self.immunities = {}
    self.abosorptions = {}

    self.icon = nil

end

return Element