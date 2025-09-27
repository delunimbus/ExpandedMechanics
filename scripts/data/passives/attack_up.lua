local AttackUp, super = Class(Passive)

function AttackUp:init()
    super.init(self)

    self.name = "Attack+"
    self.activation_name = nil

    self.effect = "25%+ base Atk"
    self.description = "Raises base Attack by 20%."

    self.usable = true

    self.target = "none"

    --self.bonuses = {}
    self.modifiers = {
        attack = 1.2,
    }
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

return AttackUp