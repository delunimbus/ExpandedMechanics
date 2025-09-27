local BloodPrice, super = Class(Passive)

function BloodPrice:init()
    super.init(self)

    self.name = "Blood Price"
    self.activation_name = nil

    self.effect = "2xMP Cost\nas HP"
    self.description = "Use double HP instead of MP for casting."

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

function BloodPrice:applyMPMod(user, cost, resource)
    user:setFlag("BloodPrice_MP_cost"..user.id, cost)
    return cost
end

function BloodPrice:onEquip(character, replacement)
    local old_main_resource = character:getMainSpellResourceType()
    --[[for _,spell in ipairs(character:getSpells()) do
        
    end]]
    character:setUniformSpellResourceType("health")
    character:setFlag("BloodPrice_previous_main_resource"..character.id, old_main_resource)
    print("cccccccc")
    character:setMainSpellResourceType("health")
end

function BloodPrice:onUnequip(character, replacement)
    --local old_main_resource = character:getMainSpellResourceType()
    --character:setFlag("BloodPrice_previous_main_resource", old_main_resource)
    character:setMainSpellResourceType(character:getFlag("BloodPrice_previous_main_resource"..character.id, "tension"))
    character:setUniformSpellResourceType(character:getFlag("BloodPrice_previous_main_resource"..character.id, "tension"))
end

function BloodPrice:applyHPCostMod(user, cost, resource)
    cost = user:getFlag("BloodPrice_MP_cost"..user.id, 0) * 2
    print("lololololool")
    return cost
end

return BloodPrice