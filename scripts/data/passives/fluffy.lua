local Fluffy, super = Class(Passive)

function Fluffy:init()
    super.init(self)

    self.name = "Fluffy"
    self.activation_name = nil

    self.effect = "1/2 PhD\nWeak to fire."
    self.description = "Halves physical damage, but doubles fire-type damage."

end

function Fluffy:applyPhysicalDamageRecievedMod(user, value, resource, element)
    local new_value = value
    print("gfgfgfgfgf")
    if element ~= "fire" then
        new_value = math.ceil(new_value / 2)
    end

    return new_value
end

function Fluffy:applyMagicDamageRecievedMod(user, value, resource, element)
    local new_value = value
    --print("jjjjjj")
    if element == "fire" then
        --print("jjjjjj")
        new_value = math.ceil(new_value * 2)
    end

    return new_value
end

return Fluffy