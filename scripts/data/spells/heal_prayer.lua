local spell, super = Class(Spell, "heal_prayer")

function spell:init()
    super.init(self)

    -- Display name
    self.name = "Heal Prayer"
    -- Name displayed when cast (optional)
    self.cast_name = nil

    -- Battle description
    if Game.chapter <= 3 then
        self.effect = "Heal\nAlly"
    else
        self.effect = "Heal\nally"
    end
    -- Menu description
    self.description = "Heavenly light restores a little HP to\none party member. Depends on Magic."

    -- TP cost
    self.cost = 32

    ------------------------
    self.mana_cost = 32

    self.draw_resistance = 16
    -----------------------

    -- Target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"

    -- Tags that apply to this spell
    self.tags = {"heal"}
end

function spell:onCast(user, target)
    local base_heal = user.chara:getStat("magic") * 5
    local heal_amount = Game.battle:applyHealBonuses(base_heal, user.chara)
    --heal_amount = self:applyPassiveHealMod(user.chara, heal_amount)

    if target.chara:getDownMode() == "traditional" then
        target:heal(0)
    else
        target:heal(heal_amount)
    end
end

function spell:hasWorldUsage(chara)
    return true
end

function spell:onWorldCast(chara)
    Game.world:heal(chara, self:applyPassiveHealMod(chara, 100))
end

return spell