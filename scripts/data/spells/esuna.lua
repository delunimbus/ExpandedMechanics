local spell, super = Class(Spell, "esuna")

function spell:init()
    super.init(self)

    -- Display name
    self.name = "Esuna"
    -- Name displayed when cast (optional)
    self.cast_name = nil

    -- Battle description
    --if Game.chapter <= 3 then
        self.effect = "Cures\nDebuffs"
    --else
        --self.effect = "Heal\nally"
    --end
    -- Menu description
    self.description = "Heavenly light cures one party member\nfrom all debuffs."

    -- TP cost
    self.cost = 32

    ------------------------
    self.mana_cost = 32

    self.draw_resistance = 16
    -----------------------

    -- Target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"

    -- Tags that apply to this spell
    --self.tags = {"heal"}
end

function spell:onCast(user, target)
    --local battler = Game.battle:getPartyBattler(target.chara.id)
    --print(battler.statuses .. status)
    for _,status in pairs(target.statuses) do
        --print(status.statcon.id)
        if status.statcon.debuff then
            --print("hamood habibi hommd hamood habibi")
            target:cureStatus(status.statcon.id)
        end
    end
    target:flash()
    Assets.stopAndPlaySound("power")
end

function spell:hasWorldUsage(chara)
    return false
end

function spell:onWorldCast(chara)
    --[[for _,status in ipairs(chara.statuses) do
        if status.debuff then
            chara:cureStatus(status)
        end
    end]]
end

return spell