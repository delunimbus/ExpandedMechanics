local TurboMP, super = Class(Passive)

function TurboMP:init()
    super.init(self)

    self.name = "Turbo MP"
    self.activation_name = nil

    self.effect = "2x MP\n2x power"
    self.description = "Doubles the MP cost of spells, but boosts their power by 66%."

    self.usable = true

    self.target = "none"

    self.bonuses = {}
    self.modifiers = {}
    --self.passive_color = COLORS["cyan"]  --Blue/Cyan in FFTA and FFTA2

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions (key = party member id)
    --self.reactions = {}

    self.activation_anim = nil

    --self.tags = {}

    --self.passive_icon = nil

    self.resource_type_activation = {"mana"}

    self.immediate_activation = true
end

function TurboMP:applyMPMod(chara, cost)
    return Utils.round(cost * 1.5)
end

function TurboMP:applySpellDamageMod(user, value, resource)
    local activate = false
    local resource_activations = {}
    print("Resource used: "..resource)
    resource_activations = self:getResourceTypeActivations()
    if resource_activations then
        print("pp")
        activate = false
        for _,r in ipairs(resource_activations) do
            print("Resource to check: "..r)
            if r == resource then
                activate = true
            end
        end
    end
    if activate then
        print("yyyyaaaa")
        return Utils.round(value + Utils.getFractional(value, 2, 3))
    else
        print("ooooaaa")
        return value
    end
end

function TurboMP:applySpellHealMod(user, value, resource)
    local activate = false
    local resource_activations = {}
    print("Resource used: "..resource)
    resource_activations = self:getResourceTypeActivations()
    if resource_activations then
        print("pp")
        activate = false
        for _,r in ipairs(resource_activations) do
            print("Resource to check: "..r)
            if r == resource then
                activate = true
            end
        end
    end
    if activate then
        print("yyyyaaaa")
        return Utils.round(value + Utils.getFractional(value, 2, 3))
    else
        print("ooooaaa")
        return value
    end
end

return TurboMP