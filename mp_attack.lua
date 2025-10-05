local MPAttack, super = Class(Passive)

function MPAttack:init()
    super.init(self)

    self.name = "MP Attack"
    self.activation_name = nil

    self.effect = "35%+ Atk damage with MP"
    self.description = "Use 20% of max MP to increase attack damage by 35%."

    self.usable = true
    self.resources_to_use = {"mana"}

    self.target = "none"

    --self.bonuses = {}
    self.modifiers = {
        --attack = 1.35,
    }
    --self.passive_color = COLORS["cyan"]  --Blue/Cyan in FFTA and FFTA2

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions (key = party member id)
    --self.reactions = {}

    self.activation_anim = nil

    --self.tags = {}

    --self.passive_icon = nil

    --self.immediate_activation = false
end

function MPAttack:getAttackDamageMod(user)
    if isClass(user) and user:includes(PartyBattler)  then
        --print("jj")
        if user.chara:getPassivePaymentStatus() then
            return 1.35
        else
            return 1
        end
    end
end

function MPAttack:getMPCostAttack(user)
    local mp_cost = 0
    if isClass(user) and user:includes(PartyBattler)  then
        --print("hhhhooohhh")
        --print(user.chara:getMana())
        --print(Utils.round(user.chara:getStat("mana") / 5))
        --print(user.chara:getMana() >= Utils.round(user.chara:getStat("mana") / 5))
        if user.chara:usesMana() and (user.chara:getMana() >= Utils.round(user.chara:getStat("mana") / 5)) then
            mp_cost = Utils.round(user.chara:getStat("mana") / 5)
            user.chara.passive_paid = true
        else
            user.chara.passive_paid = false
        end
        print(user.chara.passive_paid)
    end
    --print(mp_cost.." attack mp cost")
    return mp_cost
end

return MPAttack