---@class Spell : Spell
---
---@field revive boolean                    Used for the `"traditional"` down mode of a party member.
---
---@field spell_power integer               Used for the universal value calulations.
---@field alt_spell_powers table<table>     Table of alternative spell powers.
---
---@field mana_cost integer                 The MP cost of the spell.
---
---@field starting_stock_limit integer      The default/starting stock limit of the spell.
---@field draw_resistance number            The resitance of the spell from being drawn.
---@field stock_action_max integer          Sets the max amount of units that a spell can be stocked at a time.
---@field can_draw_cast boolean             Whether the spell can be directly cast from the draw skill.
---@field can_stock boolean                 Whether the spell can be stocked.
---
---@field hp_cost_flat integer              The flat HP cost of a spell.
---@field hp_cost_fractional table<table>   Fractional HP cost
---
---@field graze_points_cost integer         The cost of graze points...
---
---@field cast_count integer                How many times to cast the spell
---
---@overload fun(...) : Spell
local Spell, super = Class("Spell", true)

function Spell:init()

    super.init(self)

    self.spell_power = 18           --Spell powers of Fire/Blizzard/Thunder/Cure in FF8 are 18

    --To be turned a propper table
    self.alt_spell_powers = {

        {
            ["alt_power"] =     "ff7",
            ["value"]     =     8
        }

    }

    self.revive = false

    --self.default_resource = "tension"

    self.mana_cost = 0

    self.starting_stock_limit = 99  --It's 100 in FF8 but 3 digits will put the "UNTS" off-screen.
    self.draw_resistance = 0        --FF8 value range: Fire/Blizzard/Thunder/Cure = 0, Ultima = 45.
    self.stock_action_max = 9       --FF8 value is 9
    self.can_draw_cast = true
    self.can_stock = true

    self.hp_cost_flat = 0
    self.hp_cost_fractional = {}

    self.graze_points_cost = 0      --Jamm what are you thinking brother? (not yet implemented)

    self.cast_count = 1

end

--Gets the spell power of the spell.
---@param chara PartyMember The `PartyMember` the check is being run for
---@return number
function Spell:getSpellPower(chara)
    return self.spell_power
end

--Gets an alternative spell power.
---@param chara PartyMember The `PartyMember` the check is being run for
---@param alt_power string       The name of the alternative spell power
---@return number
function Spell:getAltSpellPower(chara, alt_power)

    local exists = false

    if self.alt_spell_powers ~= nil then
        for _,p in ipairs(self.alt_spell_powers) do
            if p.alt_power == alt_power then
                exists = true
                return p.value
            end
        end
    end

    if not exists --[[and self:getResourceType(chara) == "stock"]] then
        Kristal.Console:warn("Provided alternative spell power does not exist. Returned default spell power instead.")
    end

    return self:getSpellPower(chara)

end

--Uses a universal value calculation for spells. Use it on the onCast function.
---@param chara PartyMember         The `PartyMember` the calculation is being run for
---@param target Battler[]|EnemyBattler|PartyBattler|EnemyBattler[]|PartyBattler[]
---@param option string             The settings(?) of the value calculation.   (Create new calculation options in the hook function!)
---@param spell_power string|nil    The spell power to use from the alt_spell_powers table. Leave nil for default spell power.
---@return number
function Spell:useSpellValueCalculation(chara, target, option, spell_power)

    local value = 0

    local chara_level = chara:getLevel()

    local magic_stat = chara:getStat("magic")

    local target_spirit = target:getSpirit()

    if option == "ff8_hurt" then
        value = magic_stat + spell_power
        value = value * (265 - target_spirit) / 4
        value = value * spell_power / 256
    elseif option == "ff8_heal" then
        value = (spell_power * magic_stat) / 2
    elseif option == "ff7_hurt" then
        value = (spell_power / 16) * ((chara_level + magic_stat) * 6)
    elseif option == "ff7_heal" then
        value = (spell_power * 22) + ((50 + 150) * 6)
    end

    return Utils.round(value)

end

--Gets the spell resource type that the party member uses for the spell.
---@param chara PartyMember The `PartyMember` the check is being run for
function Spell:getResourceType(chara)

    local exists = false

    if chara.spell_cost_resources ~= nil then
        --table_setup = true
        for _,s in ipairs(chara.spell_cost_resources) do
            if s.spell_id == self.id then
                exists = true
                return s.resource
            end
        end
    end

    if not exists then
        return chara:getMainSpellResourceType()
    end

end


--- Gets whether the spell can revive party members with the `"traditional"` down mode.
---@return boolean
function Spell:canRevive() return self.revive end

--[[Gets the default resource the spell uses.
---@param chara PartyMember The `PartyMember` the check is being run for
function Spell:getDefaultResourceType(chara)
    return self.default_resource
end]]

--- Applies passive modifiers to damage
---@param chara PartyMember The `PartyMember` the check is being run for
---@param value number      The value to modify
function Spell:applyPassiveDamageMod(chara, value)
    local passive = chara:getPassive()
    if passive then
        --print("lll"..chara:getSpellResourceType(self))
        local new_value = passive:applySpellDamageMod(chara, value, chara:getSpellResourceType(self))
        return new_value
    end
    return value
end



--- Applies passive modifiers to healing
---@param chara PartyMember The `PartyMember` the check is being run for
---@param value number      The value to modify
function Spell:applyPassiveHealMod(chara, value)
    local passive = chara:getPassive()
    if passive then
        --passive = Mod:createPassive(passive)
        print("lll"..chara:getSpellResourceType(self))
        local new_value = passive:applySpellHealMod(chara, value, chara:getSpellResourceType(self))
        return new_value
    end
    return value
end

function Spell:onWorldCast(chara)
    --if chara:
end

function Spell:onStart(user, target)
    Game.battle:battleText(self:getCastMessage(user, target))
    user:setAnimation(self:getCastAnimation(), function()
        Game.battle:clearActionIcon(user)
        local result = self:onCast(user, target)
        if result or result == nil then
            Game.battle:finishActionBy(user)
        end
    end)
end

function Spell:canDrawCast() return self.can_draw_cast end

--- Revives party battlers with the `"traditional"` down mode
---@param target PartyBattler|PartyBattler[]
function Spell:battleReviveTarget(target)
    if self.target == "ally" then
        target:revive()
    elseif self.target == "party" then
        for _,battler in ipairs(target) do
            battler:revive()
        end
    end
end

---------------------------------------------Mana-based Functions---------------------------------------------------------------------

--Gets the user's current mana points.
---@param chara PartyMember The `PartyMember` the check is being run for
function Spell:getMPCost(chara)
    local cost = self.mana_cost
    --[[if chara and chara:getPassive() == "half_mp" then
        return Utils.round(self.mana_cost / 2)
    end]]
    local passive = chara:getPassive()
    if passive ~= nil then
        --passive = Mod:createPassive(passive)
        local new_cost = passive:applyMPMod(chara, cost)
        return new_cost
    end
    return cost
end

---------------------------------------------Stock-based Functions---------------------------------------------------------------------

--Gets the starting stock limit of the spell.
function Spell:getStartingStockLimit() return self.starting_stock_limit end

--Gets the number of units within a spell stock for the "stock" resource.
---@param chara PartyMember The `PartyMember` the check is being run for
function Spell:getStock(chara)

    local exists = false

    for _,s in ipairs(chara.spell_stock_data) do
        if s.spell_id == self.id then
            exists = true
            return s.units
        end
    end

    if not exists and self:getResourceType(chara) == "stock" then
        --Kristal.Console:warn("Spell stock not found. Returned 0 instead.")
        return 0
    end

end

--Gets the max number of units possible to stock for the "stock" resource.
---@param chara PartyMember The `PartyMember` the check is being run for
function Spell:getStockLimit(chara)

    local exists = false

    if chara.spell_stock_data ~= nil then
        for _,s in ipairs(chara.spell_stock_data) do
            if s.spell_id == self.id then
                exists = true
                return s.limit
            end
        end
    end

    if not exists and self:getResourceType(chara) == "stock" then
        --Kristal.Console:warn("Spell stock limit not found. Returned starting stock limit instead.")
        return self:getStartingStockLimit()
    end

end

--Changes a value to be used if the spell was casted from the draw action.
---@param value number The value to modify.
---@return number
function Spell:getDrawCastValue(value)
    if Game.battle.draw_cast == true then
        --print("HOLA")
        local new_value = value * ((love.math.random(0, 255) + 10) / 150)       --Just like in FF8. lol (only used for offensive spells)

        Game.battle.draw_cast = false

        return Utils.floor(new_value)

    else return value
    end
end

function Spell:canStock() return self.can_stock end

function Spell:getDrawResistance() return self.draw_resistance end

function Spell:getStockActionMax() return self.stock_action_max end

---------------------------------------------HP-based Functions---------------------------------------------------------------------

--Gets the HP cost of the spell (returns flat hp cost by default).
---@param chara PartyMember The `PartyMember` the check is being run for
function Spell:getHPCost(chara)
    local cost = self:getHPCostFlat(chara)
    local passive = chara:getPassive()
    if passive then
        --passive = Mod:createPassive(passive)
        print("iiiiiiuuuu")
        local new_cost = passive:applyHPCostMod(chara, cost)
        return new_cost
    end
    return cost
end

--Gets the flat HP cost of the spell
---@param chara PartyMember The `PartyMember` the check is being run for
function Spell:getHPCostFlat(chara)
    return self.hp_cost_flat
end

--Gets a fractional value based on current HP, Max HP, or the HP stat itself.
---@param chara PartyMember     The `PartyMember` the check is being run for
---@param numerator number     The numerator
---@param denominator number   The denominator
---@param hp string|nil         What HP statistic to make the fraction out of:
---     "max"       --Max HP (default)
---     "current"   --Current HP
---     "stat"      --The HP stat itself (uses it up)
function Spell:getHPCostFraction(chara, numerator, denominator, hp)

    local hp_cost = 0

    if hp == "max" or "stat" or nil then
        hp_cost = chara:getStat("health")
    elseif hp == "current" then
        hp_cost = chara:getHealth()
    end




    --Utils.getFraction()
end

------------------------------------------------------------------------------------------------------------------------------------

--- *(Override)* Called whenever the spell is selected for use in battle
---@param user PartyBattler
---@param target Battler[]|EnemyBattler|PartyBattler|EnemyBattler[]|PartyBattler[]
function Spell:onSelect(user, target)

    --[[user.chara:setSpellUsed(self)

    if self:getResourceType(user.chara) == "stock" then
        local stock = self:getStock(user.chara)
        user.chara:setSpellStock(self, stock - 1)
        --print("huh")
    elseif self:getResourceType(user.chara) == "health" then
        local bp = self:getHPCost(user.chara)
        Game.battle:hurt(bp, true, user)
        --print("ouch")
    elseif self:getResourceType(user.chara) == "mana" then
        local mp = self:getMPCost(user.chara)
        user.chara:setMana(user.chara:getMana() - mp)
    end]]
end

--- *(Override)* Called whenever the spell use is undone in battle
---@param user PartyBattler
---@param target Battler[]|EnemyBattler|PartyBattler|EnemyBattler[]|PartyBattler[]
function Spell:onDeselect(user, target)

    --[[user.chara:setSpellUsed(nil)

    if self:getResourceType(user.chara) == "stock" then
        local stock = self:getStock(user.chara)
        user.chara:setSpellStock(self, stock + 1)
        --print("hello bruv")
    elseif self:getResourceType(user.chara) == "health" then
        local bp = self:getHPCost(user.chara)
        user.chara:heal(bp)
        --print("ewww")
    elseif self:getResourceType(user.chara) == "mana" then
        local mp = self:getMPCost(user.chara)
        user.chara:setMana(user.chara:getMana() + mp)
    end]]

end

return Spell