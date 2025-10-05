
--- Passives are data files that extend this `Passive` class to define a castable passive. \
--- Passives are stored in `scripts/data/passives`, and their filepath starting at this location becomes their id, unless an id for them is specified as the second argument to `Class()`.
---
---@class Passive : Class
---
---@field name string               The display name of the passive
---@field activation_name string?   The display name of the passive when activated (optional)
---
---@field effect string             The battle description of the passive
---@field description string        The overworld menu description of the passive
---
---@field active boolean            Whether the passive is active
---@field activation_type string    What type of condition to check for the passive to activate
---
---@field usable boolean            Whether the passive can be activated
---@field resources_to_use table       Whether the passive makes the user spend resources
---
---@field target string             The target mode of the passive - valid options are `"ally"`, `"party"`, `"enemy"`, `"enemies"`, and `"none"`
---
---@field bonuses {attack: number, defense: number, health: number, magic: number, mana: number, spirit: number, graze_time: number, graze_size: number, graze_tp: number}
---@field modifiers {attack: number, defense: number, health: number, magic: number, mana: number, spirit: number}
---@field item_heal_modifier number The healing mult from using a healing item
---@field passive_color table
---
---@field can_equip table<string, boolean>
---@field reactions table<string, string|table<string, string>>
---
---@field resource_type_activation table<string>   What resource type usage will certain passive functions activate for (leave blank for `any`)
---
--- Tags that apply to this passive \
--- Tags are used to identify properties of the passive that can be checked by other pieces of code for certain effects, For example: \
--- The built in tag `spare_tired` will cause the passive to be highlighted if an enemy is TIRED
---@field tags string[]
---
---@field passive_icon string?
---
---@field immediate_activation boolean Whether the passive actives as soon as it is equipped
---
---@overload fun(...) : Passive
local Passive = Class()

function Passive:init()
    --super.init(self)

    self.name = "Test Passive"
    self.activation_name = nil

    self.effect = ""
    self.description = ""

    self.active = true
    self.activation_type = nil

    self.usable = true
    self.resources_to_use = {}

    self.target = "none"

    self.bonuses = {}       --Flat bonuses to stats
    self.modifiers = {}     --Mult modifiers to stats
    self.heal_item_modifier = 1
    self.passive_color = {30/255, 144/255, 255}     --Blue in FFTA and FFTA2

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions (key = party member id)
    self.reactions = {}

    self.resource_type_activation = {}

    self.activation_anim = nil

    self.tags = {}

    self.passive_icon = nil

    self.immediate_activation = false
end

---@return string
function Passive:getName() return self.name end

---@return string
function Passive:getEffect() return self.effect end

---@return string
function Passive:getActivationName() return self.activation_name or self:getName():upper() end

---@return string
function Passive:getDescription() return self.description end

---@return string
function Passive:getBattleDescription() return self.effect end

function Passive:getResourcesToUse() return self.resources_to_use end

function Passive:getStatBonuses() return self.bonuses end
function Passive:getStatModifiers() return self.modifiers end
function Passive:getHealItemMod() return self.heal_item_modifier end

--function Passive:getPassiveName() return self.bonus_name end
function Passive:getPassiveIcon() return self.passive_icon end

function Passive:getReactions() return self.reactions end

function Passive:getResourceTypeActivations() return self.resource_type_activation end

function Passive:getActivationConditionType() return self.activation_type end

--- *(Override)* Gets whether the passive is currently active
---@param user PartyMember|EnemyBattler The battler the check is being run for
---@return boolean
function Passive:isActive(user) return self.active end

--- *(Override)* Check the activation condition for if the required cost of the passive was paid (if any).
function Passive:checkActivationConditionPaymentStatus()
    return false
end

--- *(Override)* Check the activation condition for the passive based on health.
---@param current_health    number The current health of the user.
---@param max_health        number The max health of the user.
function Passive:checkActivationConditionHealth(current_health, max_health)
    return true
end

--- *(Override)* Check the activation condition for the passive based on mana.
---@param current_mana    number The current mana of the user.
---@param max_mana       number The max mana of the user.
function Passive:checkActivationConditionMana(current_mana, max_mana)
    return true
end

--- *(Override)* Gets whether the passive can currently activate
---@param user PartyMember|EnemyBattler The `PartyMember` the check is being run for
---@return boolean
function Passive:isUsable(user) return self.usable end

--- *(Overide)* Whether the passive activates immediately upon equipping
---@param user PartyMember|EnemyBattler
---@return boolean
function Passive:activateOnEquip(user) return self.immediate_activation end

--- *(Override)* Gets whether the passive can be activated in the world \
--- *(Always false by default)*
---@param chara PartyMember The `PartyMember` the check is being run for
---@return boolean
function Passive:hasWorldUsage(chara) return false end

--- *(Override)* Called whenever the passive is activated in the overworld \
--- Code that controls the effect of the passive when activation in the overworld goes here
---@param chara PartyMember
function Passive:onWorldActivation(chara) end

--- Checks whether the passive has a specific tag attached to it
---@param tag string
---@return boolean
function Passive:hasTag(tag)
    return Utils.containsValue(self.tags, tag)
end

--- *(Override)* Gets the message that appears when this passive is activated in battle
---@param user PartyBattler|EnemyBattler
---@param target Battler[]|EnemyBattler|PartyBattler|EnemyBattler[]|PartyBattler[]
---@return string
function Passive:getActivationMessage(user, target)
    return "* "..self:getActivationName().." activated for "..user.chara:getName().."!"
end

--- *(Override)* Gets the animation that is set when this passive is activation in battle
--- @return string
function Passive:getActivationAnimation()
    return self.activation_anim or "battle/passive"
end

--- *(Override)* Called when the player tries to equip this [passive on a character \
--- *If the function returns `false`, the passive will not be equipped*
---@param character     PartyMember The party member equipping the passive
---@param replacement?  Passive     The passive currently in the slot, if one is present
---@return boolean equipped
function Passive:onEquip(character, replacement) return true end

function Passive:onUnequip(character, replacement) return true end

--- *(Override)* Called when the passive is activated \
--- The code for the effects of the passive (such as damage or healing) should go into this function
---@param user PartyBattler|EnemyBattler
---@param target Battler[]|EnemyBattler|PartyBattler|EnemyBattler[]|PartyBattler[]
---@return boolean? finish_action   Whether the passive action finishes automatically, when `false` the action can be manually ended with `Game.battle:finishActionBy(user)` (defaults to `true`) 
function Passive:onActivation(user, target)
    -- Returning false here allows you to call 'Game.battle:finishActionBy(user)' yourself
end


--- *(Override)* Called when the user casts a spell \
---@param user PartyBattler|EnemyBattler
---@param target Battler[]|EnemyBattler|PartyBattler|EnemyBattler[]|PartyBattler[]
function Passive:onSpellCast(user, target)

end

--- *(Override)* If the passive modifies damage dealt by the attack action, it aplies here.
---@param user PartyBattler|EnemyBattler
---@return number damage The multiplier of the damage value
function Passive:getAttackDamageMod(user)
    print("hello, oh no *BOOM*")
    return 1
end

--- *(Override)* If the passive modifies MP cost, it applies its mod here.
---@param user PartyBattler|EnemyBattler
---@param cost number   The current MP cost
---@param resource? string The resource used to check for
---@return number new_cost
function Passive:applyMPMod(user, cost, resource)
    return cost
end

--- *(Override)* If the passive has the user spend MP for the attack action, it applies its mod here.
---@param user PartyBattler|EnemyBattler
---@return number new_cost
function Passive:getMPCostAttack(user)
    return 0
end

--- *(Override)* If the passive modifies HP cost, it applies its mod here.
---@param user PartyBattler|EnemyBattler
---@param cost number   The current MP cost
---@param resource? string The resource used to check for
---@return number new_cost
function Passive:applyHPCostMod(user, cost, resource)
    return cost
end

--- *(Override)* If the passive modifies the spell's damage output, it applies its mod here.
---@param user PartyBattler|EnemyBattler
---@param value number      The current value to modify
---@param resource? string  The resource used to check for
---@return number damage
function Passive:applySpellDamageMod(user, value, resource)
    return value
end

--- *(Override)* If the passive modifies the spell's healing output, it applies its mod here.
---@param user PartyBattler|EnemyBattler
---@param value number      The current value to modify
---@param resource? string  The resource used to check for
---@return number heal
function Passive:applySpellHealMod(user, value, resource)
    return value
end

--- *(Override)* If the passive modifies physical damaged revieved, it applies its mod here.
---@param user PartyBattler|EnemyBattler
---@param value number      The current value to modify
---@param element string    The element to check with
---@param resource? string  The resource used to check for
---@return number damage
function Passive:applyPhysicalDamageRecievedMod(user, value, element, resource)
    return value
end

--- *(Override)* If the passive modifies magic damaged revieved, it applies its mod here.
---@param user PartyBattler|EnemyBattler
---@param value number      The current value to modify
---@param element string    The element to check with
---@param resource? string  The resource used to check for
---@return number damage
function Passive:applyMagicDamageRecievedMod(user, value, element, resource)
    return value
end

--- *(Override)* If the passive modifies an item's healing output, it applies its mod here.
---@param user PartyBattler|EnemyBattler
---@param value number      The current value to modify
---@param resource? string  The resource used to check for
---@return number heal
function Passive:applyItemHealMod(user, value, resource)
    return value
end

--- *(Override)* If the item grants bonus `gold`, it applies its bonus here
---@param gold number   The current amount of victory gold
---@return number new_gold  The amount of gold with the bonus applied
function Passive:applyMoneyBonus(gold)
    return gold
end

--- *(Override)* Applies bonus healing to healing actions performed by a party member in battle
---@param current_heal number   The current heal amount with other bonuses applied
---@param base_heal number      The original heal amount
---@param healer PartyMember|EnemyBattler    The character performing the heal
---@return number new_heal      The new heal amount affected by this item
function Passive:applyHealBonus(current_heal, base_heal, healer)
    return current_heal
end

--- Gets the stat bonus the passive has for a specific stat
---@param stat string
---@return number bonus
function Passive:getStatBonus(stat)
    return self:getStatBonuses()[stat] or 0
end

--- Gets the stat modifier of the passive
---@param stat string
---@return number mod
function Passive:getStatMod(stat)
    --print("uuuuuu")
    --print(stat)
    --print(self:getStatModifiers()[stat])
    return self:getStatModifiers()[stat] or 1
end

--- Gets whether a particular character can equip an passive
---@param character PartyMember The character to check equippability for
---@return boolean  can_equip
function Passive:canEquip(character)
    --if self.type == "armor" then
        --return self.can_equip[character.id] ~= false
    --else
        return self.can_equip[character.id]
    --end
end

--- Gets the reaction for using or equipping an item for a specific user and reactor
---@param user_id       string  The id of the character using/equipping the item
---@param reactor_id    string  The id of the character to get a reaction for
---@return string?  reaction
function Passive:getReaction(user_id, reactor_id)
    local reactions = self:getReactions()
    if reactions[user_id] then
        if type(reactions[user_id]) == "string" then
            if reactor_id == user_id then
                return reactions[user_id]
            else
                return nil
            end
        else
            return reactions[user_id][reactor_id]
        end
    end
end

return Passive