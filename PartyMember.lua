---@class PartyMember : PartyMember
---
---@field stats {magic: number, defense: number, attack: number, health: number, mana: number, spirit: number, luck: number}
---
---@field down_mode string
---
---@field can_use_items boolean
---@field can_auto_heal boolean
---
---@field main_spell_resource string
---@field spell_cost_resources table<table>
---@field spell_used Spell
---@field resource_used string
---
---@field spell_stock_data table<table>
---
---@field encountered_spells string[]
---
---@field passive string
---@field passive_active boolean
---@field passive_paid boolean
---
---@field uses_mana boolean
---@field mana number
---@field lw_mana number
---@field can_auto_regen_mana boolean
---@field mana_mode string
---@field auto_mana_regen_tp_scaling number
---@field auto_mana_regen_flat_increase number
---@field has_draw boolean
---
---@field down_immune boolean
---
---@field learned_passives string[]
---
---@overload fun(...) : PartyMember
local PartyMember, super = Class("PartyMember", true)

function PartyMember:init()

    super.init(self)

    -- Handle downed state:   
    --`deltarune`   = regular Deltarune KOd state (HP can go negative, heal HP on every turn while down),   
    --`traditional` = traditional RPG KOd state (HP cannot go below 0, no autoheal while down, cannot be revived via healing only)
    self.down_mode = "deltarune"
    self.can_use_items = true                   --Whether the party member can use items (defaults to true)
    self.can_auto_heal = true                   --Whether the party member can auto-heal while downed (defults to true)
    self.has_draw = false                       --Whether the party member can draw spells (defaults to false)

    self.main_spell_resource = "tension"        --The default resource the party member uses for their spells. Any subsequent spells added will have their resource type set to this automatically.
    self.spell_cost_resources = {}              --The cost type for spells
    self.resource_used = "tension"              --Resourced used for a spell during a turn during battle (used for the onDeselect actions.) (defaults to tension) (is this still used?)

    self.spell_used = nil                       --The spell that the party member (will) use[d] for the turn
    self.encountered_spells = {}                --The IDs of the spells that the party member has encountered (you decide what "encountered" means).

    self.passive = nil                          --The ID of the passive equipped (I don't know how to save classes)
    self.passive_active = true                  --Whether the passive is currently active
    self.passive_paid = false                   --Whether the neccesary resources were paid to active the passive (if any).

    self.spell_stock_data = {}                  --The stock data for spells that use the "stock" resource

    self.uses_mana = false                      --Whether the party member uses mana (defaults to false)
    self.can_auto_regen_mana = false            --Whether the party member can regenerate mana passively (defaults to false
    self.auto_mana_regen_settings = {}          --Scaling of auto mana regen: {flat_increase: number, tp_scaling: number}   ((TP * (10x))/max MP)
    --Type of mana-based gameplay:  
    -- `traditional`    = standard, 
    -- `gotr`           = Same as FFT A2: GotR (Unsuable outside battle. Starts at 0 in the first turn. Gain mana every subsequent turn. Resets to 0 after battle ends.)
    self.mana_mode = "traditional"
    self.mana = 0                               --Current mana points (saved to the save file)
    self.lw_mana = 0                            -- Current light world mana points (saved to the save file)

    self.down_immune = false                    --Prevents the party member from being downed, never going past down 1 HP.

    self.learned_passives = {}                  --List of the IDs of passives the party member knows.

    self.stats = {
        health = 100,
        attack = 10,
        defense = 2,
        magic = 0,
        spirit = 1,
        mana = 0,
        luck = 0                                --integer from 0 to 255
    }

end

function PartyMember:getDownMode() return self.down_mode end

function PartyMember:isDownImmune() return self.down_immune end

--Sets the party member's downed state mode.
---@param mode string The name of the mode
function PartyMember:setDownMode(mode)
    self.down_mode = mode
end

--Sets whether the party member is immune from being downed/taking fatal damage.
function PartyMember:setDownImmunity(bool)
    self.down_immune = bool
end

function PartyMember:canUseItems() return self.can_use_items end

function PartyMember:hasDrawMagicSkill() return self.has_draw end

--Gets the list of spells that the player has encountered.
---@return table
function PartyMember:getEncounteredSpells()
    return self.encountered_spells
end

--Adds an encountered spell to the party
---@param spell Spell|string The spell to add.
function PartyMember:addEncounteredSpell(spell)

    --print("AAAAAAAAAAAAAAAAAAAAAAAAA")

    local spell_already_added = false

    local exists = false

    local SPELL = spell

    if type(spell) == "string" then
        SPELL = Registry.createSpell(spell)
    end

    if type(spell) ~= "string" then
        spell = spell.id
    end

    for _,s in ipairs(self:getEncounteredSpells()) do
        --print(s)
        if s == spell then
            --print("AMONGUSSSS")
            exists = true
        end
    end

    for _,S in ipairs(self:getSpells()) do
        if S.id == spell then
            --print("YOLOOOOOOOO")
            spell_already_added = true
        end
    end

    if exists and not spell_already_added then

        self:addSpell(spell)

    elseif not exists then Kristal.Console:warn("Spell not found in the encountered spells list.") --Does this work as intended?
    end

end

--Adds the spell to the encountered spells list.
---@param spell Spell|string The spell to add.
function PartyMember:addToEncounteredSpellsList(spell)

    local spell_already_encountered = false

    local SPELL = spell

    if type(spell) == "string" then
        SPELL = Registry.createSpell(spell)
    end

    if type(spell) ~= "string" then
        spell = spell.id
    end

    for _,s in ipairs(self.encountered_spells) do
        if s == spell then
            --print("poppE")
            spell_already_encountered = true
        end
    end

    if not spell_already_encountered then
        --if self:hasDrawMagicSkill()  then
            --self:addSpell(spell)
            --self:setSpellResourceType(spell, "stock")
            --self:setSpellStockData(spell, 0, SPELL:getStartingStockLimit())
        --end
        table.insert(self.encountered_spells, spell)
    end

end

--Adds all spells in the encountered list into the party member's regular spells list.
function PartyMember:addAllEncounteredSpells()

    local spell_already_added = false

    for _,s in ipairs(self:getEncounteredSpells()) do
        for _,spell in ipairs(self:getSpells()) do
            if spell.id == s then
                spell_already_added = true
            end
        end
        if not spell_already_added then
            self:addSpell(s)
        end
        spell_already_added = false
    end

end

--battler.chara:getDownMode() == "traditional"

--Gets whethr the party member can auto-heal while downed.
function PartyMember:canAutoHeal()
    if self:getDownMode() == "traditional" then
        return false
    end
    return self.can_auto_heal
end

--Sets whether the party member can auto-heal while downed.
---@param bool boolean 
function PartyMember:setAutoHeal(bool)
    self.can_auto_heal = bool
end

function PartyMember:increaseStat(stat, amount, max)
    local base_stats = self:getBaseStats()
    base_stats[stat] = (base_stats[stat] or 0) + amount
    max = max or self:getMaxStat(stat)
    if max and base_stats[stat] > max then
        base_stats[stat] = max
    end
    if stat == "health" then
        self:setHealth(math.min(self:getHealth() + amount, base_stats[stat]))
    end
------------------------------------------------------------------------------
    if stat == "mana" then
        self:setMana(math.min(self:getMana() + amount, base_stats[stat]))
    end
------------------------------------------------------------------------------
end

function PartyMember:setHealth(health)
    if Game:isLight() then
        self.lw_health = health
    else
        self.health = health
    end
end

---------------------------------------------Passive Functions----------------------------------------------------------------------

function PartyMember:getPassive()
    if self.passive then
        return Mod:createPassive(self.passive)
    else
        return nil
    end
end

function PartyMember:isPassiveActive() return self.passive_active end

function PartyMember:getPassivePaymentStatus() return self.passive_paid end

--- Checks for the required conditions for the passive to activate.
---@param passive Passive|string The passive to make the check for.
function PartyMember:checkPassiveActivationCondition(passive)

    local con_met = true

    local type = passive:getActivationConditionType()
    --print(type)
    --[[if type then
        print(self:getName().." passive condition type: "..type)
    end]]
    --print("eeeeeees")
    if type == "health" then
        con_met = passive:checkActivationConditionHealth(self:getHealth(), self:getStatBasic("health"))
    elseif type == "mana" then
        con_met = passive:checkActivationConditionMana(self:getMana(), self:getStatBasic("mana"))
    end

    return con_met

end

--- Adds a passive to the party member's known passive list.
---@param passive string|Passive
function PartyMember:addPassive(passive)
    local passive_already_added = false
    local exists = false
    local PASSIVE = passive

    if type(passive) == "string" then
        PASSIVE = Mod:createPassive(passive)
    end

    if type(passive) ~= "string" then
        passive = passive.id
    end

    for _,p in ipairs(self.learned_passives) do
        --print(s)
        if p == passive then
            --print("AMONGUSSSS")
            exists = true
            break
        end
    end

    if exists and not passive_already_added then
        --self:addPassive(passive)
        table.insert(self.learned_passives, passive)
    --elseif not exists then Kristal.Console:warn("Spell not found in the encountered spells list.")
    end
end

---@param passive string|Passive|nil
function PartyMember:setPassive(passive)
    local current_passive = self:getPassive()
    
    --passive:onEquip(character, replacement) return true end
    if passive then
        if type(passive) == "string" then
            passive = Mod:createPassive(passive)
        end
        self.passive = passive.id
        passive:onEquip(self, current_passive)

        if current_passive then
            current_passive:onUnequip(self, passive)
        end
    elseif type(passive) == "nil" then
        self.passive = nil
        if current_passive then
            current_passive:onUnequip(self)
        end
    end
end

--- *(Override)* Checks whether this party member is able to equip a specific item \
--- *By default, calls [`passive:canEquip()`](lua://Passive.canEquip) to check equippability.
---@param passive       Passive|string|nil
---@return boolean
function PartyMember:canEquip(passive)
    --if passive then
        return passive:canEquip(self) or Mod:createPassive(passive):canEquip() or nil
    --end
end


--- Gets this party member's stat bonuses from a passive for a particular stat (bonus only)
---@param stat string
---@return number
function PartyMember:getPassiveBonus(stat)
    local bonus = 0
    local passive = self:getPassive()
    --print(self:getPassive())
    if passive then
        --passive = Mod:createPassive(self:getPassive())
        --print("ppppp")
        --local active = self:checkPassiveActivationCondition(passive)
        --print("ooooo")
        --if active then
            bonus = (passive:getStatBonus(stat) or 0)
        --end
    end
    --print(bonus)
    return bonus
end

--- Gets this party member's stat modifiers from a passive for a particular stat
---@param stat string
---@return number
function PartyMember:getPassiveMod(stat)
    local modifier = 1
    --print(stat)
    local passive = self:getPassive()
    if passive then
        --passive = Mod:createPassive(self:getPassive())
        --local active = self:checkPassiveActivationCondition(passive)
        --if active then
            --print("ffffffffffff")
            modifier = passive:getStatMod(stat)
            --print("a"..modifier)
        --end
    end
    --print(modifier)
    --local has_passive = self:getPassive()
    return modifier
end

---@param light? boolean
function PartyMember:getStats(light)
    local stats = Utils.copy(self:getBaseStats(light))

    local passive = self:getPassive()

    
    if passive then
        local condition_met = true
        local condition_type = self:getPassive():getActivationConditionType(passive)
        if condition_type == "health" then
            condition_met = passive:checkActivationConditionHealth(self:getHealth(), stats["health"])
        end
        if condition_met then
                for stat, amount in pairs(passive:getStatBonuses()) do
                    if stats[stat] then
                        stats[stat] = stats[stat] + amount
                    else
                        stats[stat] = amount
                    end
                end
                for stat, mod in pairs(passive:getStatModifiers()) do
                    if stats[stat] then
                        stats[stat] = Utils.round(stats[stat] * mod)
                    else
                        --stats[stat] = 
                    end
                end
            end
        end
    for _,item in ipairs(self:getEquipment()) do
        for stat, amount in pairs(item:getStatBonuses()) do
            if stats[stat] then
                stats[stat] = stats[stat] + amount
            else
                stats[stat] = amount
            end
        end
    end
    return stats
end

--- Gets the full (buffs applied) stat value for one of the party member's stats
---@param name      string
---@param default?  number
---@param light?    boolean
function PartyMember:getStat(name, default, light)
    local passive = self:getPassive()
    --local health_stat = self:getBaseStat("health")
    local base_stat = (self:getBaseStats(light)[name] or (default or 0))
    local stat = base_stat
    --print(self.passive)
    if passive then
        --print("wwwwwww")
        local condition_met = self:checkPassiveActivationCondition(passive)
        --print("namewwww "..name)
        if condition_met then
            --print("rrrrrrr")
            stat = stat * self:getPassiveMod(name)
        end
        
    --else --print("qqqqqqqqqq")
    end
    stat = stat + self:getEquipmentBonus(name) + self:getStatBuff(name)
    
    return stat

    --self:getPassiveBonus(name)) * (self:getPassiveMod(name) or 1)
end

--- Basic form of `PartyMember:getStat` where passive is not accounted for.
---@param name      string
---@param default?  number
---@param light?    boolean
function PartyMember:getStatBasic(name, default, light)

    return (self:getBaseStats(light)[name] or (default or 0))  + self:getEquipmentBonus(name) + self:getStatBuff(name)

end

---------------------------------------------Resource Functions---------------------------------------------------------------------

--Sets the resource used for the spell.
---@param resource string The resource used. (...)
function PartyMember:setResourceUsed(resource)
    self.resource_used = resource
    --print("Resource used: " .. self.resource_used)
end

--Sets the spell used
---@param spell Spell|nil The spell used...
function PartyMember:setSpellUsed(spell)
    --print(spell)
    self.spell_used = spell or nil
end
--Gets the spell used
---@return Spell
function PartyMember:getSpellUsed()
    return self.spell_used
end

--Gets the party member's main resource type
function PartyMember:getMainSpellResourceType()
    return self.main_spell_resource
end

--Sets the party member's main resource type
---@param resource string The party member's resource type to set as their default/main one.
function PartyMember:setMainSpellResourceType(resource)
    self.main_spell_resource = resource
end

--Sets the type of cost the user will use for the spell.
---@param spell string|Spell The spell to set the resource for
---@param resource string|nil The type of resource to use. (Defaults to "tension" if variable not given.)
function PartyMember:setSpellResourceType(spell, resource)

    local exists = false

    local SPELL = spell

    if type(spell) == "string" then
        SPELL = Registry.createSpell(spell)
    end

    if type(spell) ~= "string" then
        spell = spell.id
    end
    --print(spell)
    resource = resource or self:getMainSpellResourceType()
    --print(resource)

    for _,s in ipairs(self:getSpellResourceTypes()) do
        if s.spell_id == spell then
            exists = true
            s.resource = resource
        end
    end

    if not exists then
        local cost_info = {
        ["spell_id"] = spell,
        ["resource"] = resource
    }
    table.insert(self.spell_cost_resources, cost_info)
    end


end

--Gets the dafault resource that the spell uses.
---@param spell Spell The `Spell` to check for
function PartyMember:getSpellDefaultResourceType(spell)

    local SPELL = spell

    if type(spell) == "string" then
        SPELL = Registry.createSpell(spell)
    end

    return SPELL:getResourceType(self)

end

--Gets the spell resource type that the party member uses for the spell.
---@param spell Spell The `Spell` to check for
function PartyMember:getSpellResourceType(spell)

    local SPELL = spell

    if type(spell) == "string" then
        SPELL = Registry.createSpell(spell)
    end

    local exists = false

    if self:getSpellResourceTypes() ~= nil then
        for _,s in ipairs(self:getSpellResourceTypes()) do
            if s.spell_id == SPELL.id then
                exists = true
                print(s.resource.."yyyysss")
                return s.resource
            end
        end
    end

    if not exists then
        print("ruh roh")
        return self:getSpellDefaultResourceType(spell)
    end
end

--Sets up all the user's available spells to use one resource across all of them.
---@param resource string The resource to set all spells to use.
function PartyMember:setUniformSpellResourceType(resource)

    local exists = false

    for _,spell in ipairs(self:getSpells()) do

        for _,s in ipairs(self:getSpellResourceTypes()) do
            exists = true
            s["resource"] = resource
        end
        if not exists then
            self:setSpellResourceType(spell, resource)
        end
    end

end

--Sets up available spells that are of one specific resource type.
---@param resource string The resource to use for this setup.
function PartyMember:setupSpellsOfOnlyOneResourceType(resource)

    for _,spell in ipairs(self:getSpells()) do
        self:removeSpell(spell)
    end

    for _,s in ipairs(self:getSpellResourceTypes()) do
        if s.resource == resource then
            self:addSpell(s.spell_id)
        end
    end

end

--Gets the spell cost resources attributed to the party member.
function PartyMember:getSpellResourceTypes() return self.spell_cost_resources end

---------------------------------------------Mana Functions---------------------------------------------------------------------

--Checks whether the party member uses mana.
---@return boolean
function PartyMember:usesMana() return self.uses_mana end

--Sets whether the party member uses mana or not.
---@param bool boolean
function PartyMember:setManaUsageStatus(bool)
    self.uses_mana = bool
end

--Gets the current MP of the party member.
---@return integer
function PartyMember:getMana() return Game:isLight() and self.lw_mana or self.mana end

--Gets the mana gameplay mode of the party member.
---@return string
function PartyMember:getManaMode()
    return self.mana_mode
end
--Sets the mana mode of the party member.
---@param mode string the name of the mode
function PartyMember:setManaMode(mode)
    self.mana_mode = mode
end

---Sets this party member's MP value
---@param amount number
function PartyMember:setMana(amount)
    if Game:isLight() then
        self.lw_mana = amount
    else
        self.mana = amount
    end
end

--Simple mana removal function.
---@param amount number
function PartyMember:removeMana(amount)
    self:setMana(self:getMana() - amount)
end

--How much to regenerate mana (works identical to 'PartyMember:heal())
function PartyMember:regenMana(amount, playsound)
    if playsound == nil or playsound then
        Assets.stopAndPlaySound("PMD2_PP_Up", 0.8)
    end
    self:setMana(math.min(self:getStat("mana"), self:getMana() + amount))
    return self:getStat("mana") == self:getMana()
end

function PartyMember:canAutoRegenMana() return self.can_auto_regen_mana end

--- *(Override)* Gets the amount of health this party member should regain mana points each turn (unused by default).
---@param tp_scaling number Sets the scaling of the auto-regen in proportion to current TP: ((TP * (10x))/max MP)
---@param flat_increase number Sets the flat increase number of MP per turn.
---@return number
function PartyMember:autoRegenManaAmount(tp_scaling, flat_increase)
    tp_scaling = self.auto_mana_regen_tp_scaling or 2
    flat_increase = self.auto_mana_regen_flat_increase or 5
    -- TODO: Is this round or ceil? Both were used before this function was added. ---idk

    local bonus = Utils.round((Game:getTension() * (10 * tp_scaling)) / self:getStat("mana"))
    --print(bonus)
    return Utils.round(flat_increase + bonus)
end

---------------------------------------------Stock Functions---------------------------------------------------------------------

--Sets the stock data for a spell.
---@param spell string|Spell
---@param units integer|nil The number of units to add to the stock. (-1 = current) (uses the starting stock limit by default)
---@param limit integer|nil The max number of units that the stock can hold. (-1 = current)
function PartyMember:setSpellStockData(spell, units, limit)

    local SPELL = spell

    if type(spell) == "string" then
        SPELL = Registry.createSpell(spell)
    end

    local established_spell = false

    units = units or SPELL:getStartingStockLimit()
    limit = limit or SPELL:getStartingStockLimit()

    --print("units = " .. units)
    --print("limit = " .. limit)

    if units == -1 then
        units = spell:getStock(self)
    end

    if limit == -1 then
        limit = spell:getStockLimit(self)
    end

    if type(spell) ~= "string" then
        spell = spell.id
    end

    --print(spell)

    if type(spell) ~= "string" then
        error("Invalid spell to create data for.")      --Idk if this is necessary or even valid.
    end

    --print(self:getUserSpellStockData()[1][1])

    if type(self:getUserSpellStockData()) ~= "string" then
        for _,s in ipairs(self:getUserSpellStockData()) do
            if s.spell_id == spell then
                established_spell = true
            end
        end

        if established_spell == false then
        local stock_data = {
            ["spell_id"] = spell,
            ["units"] = units or 0,
            ["limit"] = limit or SPELL:getStockLimit(self)
            }
            table.insert(self.spell_stock_data, stock_data)
        else
            for _,v in ipairs(self.spell_stock_data) do
                if v.spell_id == spell then
                    v["units"] = units
                    v["limit"] = limit
                end
            end
        end
    else local stock_data = {
            ["spell_id"] = spell,
            ["units"] = units or 0,
            ["limit"] = limit or SPELL:getStockLimit(self)
            }
            table.insert(self.spell_stock_data, stock_data)
    end

end

--Gets the party member's spell stock data
---@return table
function PartyMember:getUserSpellStockData()
    return self.spell_stock_data
end

--Sets the stock of a spell for the "stock" resource
---@param spell string|Spell
---@param units integer The number of units to set the stock too.
function PartyMember:setSpellStock(spell, units)

    if type(spell) ~= "string" then
        spell = spell.id
    end

    --print(spell)

    if type(spell) ~= "string" then
        error("Invalid spell to create data for.")
    end

    for _,s in ipairs(self.spell_stock_data) do
        if s.spell_id == spell then
            s["units"] = units
        end
        --print(s.units)
    end
end

--Sets the stock limit of a spell
---@param spell string|Spell The spell to set the stock limit for.
---@param limit integer The stock new limit.
function PartyMember:setSpellStockLimit(spell, limit)

    local SPELL = spell

    if type(spell) == "string" then
        SPELL = Registry.createSpell(spell)
    end

    if type(spell) ~= "string" then
        spell = spell.id
    end

    for _,s in ipairs(self:getUserSpellStockData()) do
        if s.spell_id == spell then
            s["limit"] = limit or SPELL:getStartingStockLimit()
        --else Kristal.Console:warn("Spell not found in the stock data: " .. spell)
        end
    end

    if self:getUserSpellStockData()[1] == nil then
        Kristal.Console:warn("Empty user stock data.")
    end

end

--The function for the stock action.
---@param spell string|Spell The spell to stock.
---@param enemy EnemyBattler The enemy to run the stock calculation for.
---@param tp_assurance boolean|nil Whether to make the higher the TP, the better minimum the random_chance is. (defaults to false)
---@return integer
function PartyMember:stockSpell(spell, enemy, tp_assurance)

    tp_assurance = tp_assurance or false

    self:addToEncounteredSpellsList(spell)

    local SPELL = spell

    if type(spell) == "string" then
        SPELL = Registry.createSpell(spell)
    end

    if type(spell) ~= "string" then
        spell = spell.id
    end

    local result = 0

    local draw_resistance = SPELL:getDrawResistance() or 0

    local enemy_level = enemy:getLevel() or 1

    local magic_stat = self:getStat("magic") or 0

    local random_chance = love.math.random(1, 32)

    if tp_assurance then

        local tp = Game:getTension()

        local min = Utils.ceil((tp / 20) * 2.5)

        random_chance = love.math.random(min, 32)

    end

    result = (magic_stat - enemy_level) / 2 + 4
    result = (result + magic_stat - draw_resistance + random_chance) / 5      --Actual formula provided by the Final Fantasy Wiki

    result = Utils.ceil(result)

    --print("random: " .. random_chance)
    --print(result)

    if result > SPELL:getStockActionMax() then
        result = SPELL:getStockActionMax()
    end

    if result < 0 then
        result = 0
    end

    self:addStock(SPELL, result)

    --print(result)

    self:addToEncounteredSpellsList(spell)

    return result

end

--Simple addition function for a spell stock (caps at stock limit)
---@param spell string|Spell The spell to add to its stock.
---@param units integer Number of units to add.
function PartyMember:addStock(spell, units)

    local SPELL = spell

    if type(spell) == "string" then
        SPELL = Registry.createSpell(spell)
    end

    --print("current stock: " ..SPELL:getStock(self))

    local new_stock = SPELL:getStock(self) + units

    --print(new_stock)

    local limit = SPELL:getStockLimit(self) or SPELL:getStartingStockLimit()

    --print(limit)

    if new_stock >= limit then
        self:setSpellStock(spell, spell:getStockLimit(self))
    else
        self:setSpellStock(spell, spell:getStock(self) + units)
    end

    self:setSpellStockLimit(spell, limit)               --Possibly a case of spaghetti code

end

--Simple subtraction function for a spell stock (caps at 0)
---@param spell string|Spell The spell to remove from its stock.
---@param units integer Number of units to subtract.
function PartyMember:removeStock(spell, units)

    --print("current stock: " ..spell:getStock(self))

    local new_stock = spell:getStock(self) - units

    if new_stock < 0 then
        self:setSpellStock(spell, 0)
    else
        self:setSpellStock(spell, spell:getStock(self) - units)
    end

end

---------------------------------------------Save Data---------------------------------------------------------------------

--- Adds a spell to this party member's set of available spells
---@param spell string|Spell
function PartyMember:addSpell(spell)

    if type(spell) == "string" then
        spell = Registry.createSpell(spell)
    end
    table.insert(self.spells, spell)
---------------------------------------------------
    self:addToEncounteredSpellsList(spell)
    self:setSpellResourceType(spell)
---------------------------------------------------
end

---@return string[] spells An array of the spell IDs this party member has encountered
function PartyMember:saveEncounteredSpells()
    local result = {}
    for _,v in pairs(self.encountered_spells) do
        --print("Save encountered spell for " .. self:getName() .. ": " .. v)
        table.insert(result, v)
    end
    return result
end

---@return table
function PartyMember:saveSpellResourceTypes()
    local result = {}
    for _,v in pairs(self.spell_cost_resources) do
        local spell = v.spell_id
        local resource = v.resource or self:getMainSpellResourceType()
        --print("Save spell resource by " .. self:getName() .. " for " .. Registry.createSpell(spell):getName() .. ": " .. resource)
        local cost_data = {
            ["spell_id"] = spell,
            ["resource"] = resource
        }
        table.insert(result, cost_data)
    end
    return result
end

---@return table
function PartyMember:saveSpellStockData()
    local result = {}
    for _,v in pairs(self.spell_stock_data) do
        --print("v = " .. v.spell_id)
        local spell = v.spell_id
        local stock = v.units or 0
        local limit = v.limit or Registry.getSpell(v.spell_id):getStartingStockLimit()
        --[[print("Save spell stock data for " .. self:getName() .. ": " .. Registry.createSpell(v.spell_id):getName() .. ",")
        print("Stock: " .. stock .. ",")
        print("Limit: " .. limit)]]
        local stock_data = {
            ["spell_id"] = spell,
            ["units"] = stock,
            ["limit"] = limit
        }
        table.insert(result, stock_data)
    end
    return result
end

---@return string?
function PartyMember:savePassive()
    --print(self.passive)
    return self.passive
end

---@return table
function PartyMember:saveLearnedPassives()
    local result = {}
    for _,v in pairs(self.learned_passives) do
        --print("Save known passive for " .. self:getName() .. ": " .. v)
        table.insert(result, v)
    end
    return result
end

---@param data string[] An array of the spell IDs this party member has encountered
function PartyMember:loadEncounteredSpells(data)
    self.encountered_spells = {}
    --print("monkaOmega")
    for _,v in ipairs(data) do
        if Registry.getSpell(v) then
            --print("Load encountered spell for " .. self:getName() .. ": " .. v)
            self:addToEncounteredSpellsList(v)
        else
            Kristal.Console:error("Could not load encountered spell \"".. (v or "nil") .."\"")
        end
    end
end

---@param data table
function PartyMember:loadSpellResourceTypes(data)
    self.spell_cost_resources = {}
    for _,v in ipairs(data) do
        --print("peepeepoopoo")
        if Registry.createSpell(v.spell_id) then
            local spell = v.spell_id
            local resource = v.resource or self:getMainSpellResourceType()
            --print("Load spell resource by " .. self:getName() .. " for " .. Registry.createSpell(spell):getName() .. ": " .. resource)
            self:setSpellResourceType(spell, resource)
        else
            Kristal.Console:error("Could not load spell \"".. (v or "nil") .."\"")
        end
    end
end

---@param data table
function PartyMember:loadSpellStockData(data)
    self.spell_stock_data = {}
    for _,v in ipairs(data) do
        if Registry.createSpell(v.spell_id) then
            local spell = v.spell_id
            local stock = v.units or 0
            local limit = v.limit or Registry.getSpell(v.spell_id):getStartingStockLimit()
            --[[print("Load spell stock data for " .. self:getName() .. ": " .. Registry.createSpell(v.spell_id):getName() .. ",")
            print("Stock: " .. stock .. ",")
            print("Limit: " .. limit)]]
            self:setSpellStockData(spell, stock, limit)
        else
            Kristal.Console:error("Could not load spell \"".. (v or "nil") .."\"")
        end
    end
end

---@param data string?
function PartyMember:loadPassive(data)
    if data then
        self:setPassive(data)
    end
end

---@param data string[] An array of the passive IDs this party member knows
function PartyMember:loadLearnedPassives(data)
    self.learned_passives = {}
    --print("peepoGlad")
    for _,v in ipairs(data) do
        if Mod:getPassive(v) then
            --print("Load passive known for " .. self:getName() .. ": " .. v)
            self:addPassive(v)
        else
            Kristal.Console:error("Could not load passive \"".. (v or "nil") .."\"")
        end
    end
end

---@return PartyMemberSaveData
function PartyMember:save()
    local data = {
        id = self.id,
        title = self.title,
        level = self.level,
        health = self.health,
        stats = self.stats,
        lw_lv = self.lw_lv,
        lw_exp = self.lw_exp,
        lw_health = self.lw_health,
        lw_stats = self.lw_stats,
        spells = self:saveSpells(),
        equipped = self:saveEquipment(),
        flags = self.flags,
------------------------------------------------
        passive = self:savePassive(),
        --learned_passives = self:saveLearnedPassives(),
        uses_mana = self.uses_mana,
        mana_mode = self.mana_mode,
        can_auto_heal = self.can_auto_heal,
        down_mode = self.down_mode,
        --down_immune = self.down_immune,
        main_spell_resource = self.main_spell_resource,
        spell_cost_resources = self:saveSpellResourceTypes(),
        mana = self.mana,
        lw_mana = self.lw_mana,
        auto_mana_regen_flat_increase = self.auto_mana_regen_flat_increase,
        auto_mana_regen_tp_scaling = self.auto_mana_regen_tp_scaling,
        encountered_spells = self:saveEncounteredSpells(),
        spell_stock_data = self:saveSpellStockData(),
-----------------------------------------------
    }
    self:onSave(data)
    return data
end

---@param data PartyMemberSaveData
function PartyMember:load(data)
    self.title = data.title or self.title
    self.level = data.level or self.level
    self.stats = data.stats or self.stats
    self.lw_lv = data.lw_lv or self.lw_lv
    self.lw_exp = data.lw_exp or self.lw_exp
    self.lw_stats = data.lw_stats or self.lw_stats
    if data.spells then
        self:loadSpells(data.spells)
    end
    if data.equipped then
        self:loadEquipment(data.equipped)
    end
------------------------------------------------
    if data.passive then
        self:loadPassive(data.passive)
    end
    --if data.learned_passives then
        --self:loadLearnedPassives(data.learned_passives)
    --end
    self.uses_mana = data.uses_mana or self.uses_mana
    self.mana_mode = data.mana_mode or self.mana_mode
    self.can_auto_heal = data.can_auto_heal or self.can_auto_heal
    self.down_mode = data.down_mode or self.down_mode
    --self.down_immune = data.down_immune or self.down_immune
    self.main_spell_resource = data.main_spell_resource or self.main_spell_resource
    if data.spell_cost_resources then
        self:loadSpellResourceTypes(data.spell_cost_resources)
    end
    self.mana = data.mana or self:getStat("mana", 0, false)
    self.lw_mana = data.lw_mana or self:getStat("mana", 0, true)
    self.auto_mana_regen_flat_increase = data.auto_mana_regen_flat_increase or self.auto_mana_regen_flat_increase
    self.auto_mana_regen_tp_scaling = data.auto_mana_regen_tp_scaling or self.auto_mana_regen_tp_scaling
    if data.encountered_spells then
        self:loadEncounteredSpells(data.encountered_spells)
    end
    if data.spell_stock_data then
        self:loadSpellStockData(data.spell_stock_data)
    end
-----------------------------------------------
    self.flags = data.flags or self.flags
    self.health = data.health or self:getStat("health", 0, false)
    self.lw_health = data.lw_health or self:getStat("health", 0, true)

    self:onLoad(data)
end

return PartyMember