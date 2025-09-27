local Unscarred, super = Class(Passive)

function Unscarred:init()
    super.init(self)

    self.name = "Unscarred"
    self.activation_name = nil

    self.effect = "50%+ base stats if max HP."
    self.description = "Increases Attack, Defense, Magic, and Spirit by 50% when at max HP."

    self.active = false
    self.activation_type = "health"

    self.usable = true

    self.target = "none"

    --self.bonuses = {}
    self.modifiers = {
        attack = 1.5,
        defense = 1.5,
        magic = 1.5,
        spirit = 1.5
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

function Unscarred:checkActivationConditionHealth(current_health, user_max)
    if current_health >= user_max then
        --print("sooooooooooos")
        --user.passive_active = false
        return true
    else
        --print("gggggggg")
        --user.passive_active = true
        return false
    end
end

return Unscarred