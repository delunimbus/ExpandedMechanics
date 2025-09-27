local HalfMP, super = Class(Passive)

function HalfMP:init()
    super.init(self)

    self.name = "Half MP"
    self.activation_name = nil

    self.effect = "Halves MP"
    self.description = "Halves the MP cost of all spells."

    self.usable = true

    self.target = "none"

    --self.bonuses = {}
    --self.modifiers = {}
    --self.passive_color = COLORS["cyan"]  --Blue/Cyan in FFTA and FFTA2

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions (key = party member id)
    --self.reactions = {}

    self.activation_anim = nil

    --self.tags = {}

    --self.passive_icon = nil

    self.immediate_activation = true
end

function HalfMP:applyMPMod(chara, cost)
    return Utils.round(cost / 2)
end

return HalfMP