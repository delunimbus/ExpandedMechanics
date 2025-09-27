---@class HealItem : Item
---@overload fun(...) : HealItem
local HealItem, super = Class("HealItem", true)

function HealItem:init()
    super.init(self)


    
end



--- Applies a passive's modifier to the heal amount. Can be overriden to disable or change behaviour.
---@param passive Passive|string
function HealItem:getHealPassiveMod(passive)
    if type(passive) == "string" then
        passive = Mod:createPassive(passive)
    end
    --local amount = self:getBattleHealAmount(id)
    return passive:getHealItemMod()
end

function HealItem:getWorldHealAmount(id)
    
    return self.world_heal_amounts[id] or self.world_heal_amount or self:getHealAmount(id)
    
end




function HealItem:onWorldUse(target)
    if self.target == "ally" then
        -- Heal single party member
        local amount = self:getWorldHealAmount(target.id)
        Game.world:heal(target, amount)
        return true
    elseif self.target == "party" then
        -- Heal all party members
        for _,party_member in ipairs(target) do
            local amount = self:getWorldHealAmount(party_member.id)
            Game.world:heal(party_member, amount)
        end
        return true
    else
        -- No target or enemy target (?), do nothing
        return false
    end
end


function HealItem:onBattleUse(user, target)
    if self.target == "ally" then
        -- Heal single party member
        local amount = self:getBattleHealAmountModified(target.chara.id, user.chara)
        --amount = user:applyPassiveHealMod(base_heal, healer)
        target:heal(amount)
    elseif self.target == "party" then
        -- Heal all party members
        for _,battler in ipairs(target) do
            local amount = self:getBattleHealAmountModified(battler.chara.id, user.chara)
            battler:heal(amount)
        end
    elseif self.target == "enemy" then
        -- Heal single enemy (why)
        local amount = self:getBattleHealAmountModified(target.id, user.chara)
        target:heal(amount)
    elseif self.target == "enemies" then
        -- Heal all enemies (why????)       ---Undead mechanic :)
        for _,enemy in ipairs(target) do
            local amount = self:getBattleHealAmountModified(enemy.id, user.chara)
            enemy:heal(amount)
        end
    else
        -- No target, do nothing
    end

    if self.target == ("ally" or "party") then
        self:battleReviveTarget(target)
    end
end

--- Returns the passive-modified heal amount from a healing action performed by the specified party member
---@param base_heal number      The heal amount to modify
---@param healer PartyMember    The character performing the heal action
function HealItem:applyPassiveHealMod(base_heal, healer)
    local current_heal = base_heal
    local passive = healer:getPassive()
    --for _,party in ipairs(Game.party) do
        --for _,item in ipairs(party:getEquipment()) do
        if passive then
            current_heal = current_heal * passive:getHealItemMod()
        end
    --end
    return current_heal
end


return HealItem