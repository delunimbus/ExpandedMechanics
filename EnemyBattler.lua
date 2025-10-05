---@class EnemyBattler : EnemyBattler
---@field magic integer
---@field spirit integer
---@field level integer
---@field enemy_spells Spell[]
---@field has_spells boolean
---@overload fun(...) : EnemyBattler
local EnemyBattler, super = Class("EnemyBattler", true)

function EnemyBattler:init()

    super.init(self)

    --Magic stat for the enemy.
    self.magic = 0

    --Magic counterpart of defense
    self.spirit = 0

    --Sets the level of the enemy (also used for the draw action).
    self.level = 1

    --List of spells that the enemy has.
    self.enemy_spells = {}

    --If the enemy has spells that can be drawn from.
    self.has_spells = false

end

--Gets the enemy's defense stat
function EnemyBattler:getDefense() return self.defense end

--Gets the enemy's defense stat
function EnemyBattler:getSpirit() return self.spirit end

--Gets the level of the enemy.
function EnemyBattler:getLevel() return self.level end

--Registers a spell to the enemy.
---@param spell string|Spell
function EnemyBattler:registerEnemySpell(spell)

    if type(spell) == "string" then
        spell = Registry.createSpell(spell)
    end

    table.insert(self.enemy_spells, spell)

end

function EnemyBattler:getEnemySpells()
    return self.enemy_spells
end

function EnemyBattler:onAct(battler, name)
    if name == "Check" then
        self:onCheck(battler)
        if type(self.check) == "table" then
            local tbl = {}
            for i,check in ipairs(self.check) do
                if i == 1 then
                    table.insert(tbl, "* " .. string.upper(self.name) .. " - " .. check)
                else
                    table.insert(tbl, "* " .. check)
                end
            end
            return tbl
        else
            return "* " .. string.upper(self.name) .. " - " .. "LV " .. self.level .. " " .. self.check
        end
    end
end


--- *(Override)* Gets the magic damage dealt to this enemy based on its spirit stat
--- *By default, returns `damage` if it is a number greater than 0, otherwise using the attacking `battler` and `points` against this enemy's `defense` to calculate damage*
---@param damage    number
---@param battler   PartyBattler
---@param points    number          The points of the hit, based on closeness to the target box when attacking, maximum value is `150`
---@return number
function EnemyBattler:getMagicDamage(damage, battler, points)
    if damage > 0 then
        return damage
    end
    return ((battler.chara:getStat("magic") * points) / 20) - (self.spirit * 3)
end

--- Registers a new ACT for this enemy that uses mana. This function is best called in [`EnemyBattler:init()`](lua://EnemyBattler.init) for most acts, unless they only appear under specific conditions. \
--- What happens when this act is used is controlled by [`EnemyBattler:onAct()`](lua://EnemyBattler.onAct) - acts that do not return text there will **softlock** Kristal.
---@param name          string          The name of the act
---@param description?  string          The short description of the act that appears in the menu
---@param spenders      string[]|string A list of party member ids that will use their mana. Alternatively, the keyword `"all"` can be used to insert the entire current party
---@param mp?           number          An amount of MP required to use this act
---@param split_cost?   boolean         Whether to split the cost amongst the spenders, otherwise all spenders will spend the MP amount
---@param party?        string[]|string A list of party member ids required to use this act. Alternatively, the keyword `"all"` can be used to insert the entire current party
---@param highlight?    Battler[]       A list of battlers that will be highlighted when the act is used, overriding default highlighting logic             
---@param icons?        string[]        A list of texture paths to icons that will display next to the name of this act (party member heads are drawn automatically as required)
---@return table act    The data of the act, also added to the `acts` table
function EnemyBattler:registerManaAct(name, description, spenders, mp, split_cost, party,  highlight, icons)

    split_cost = split_cost or false

    if type(spenders) == "string" then
        if spenders == "all" then
            spenders = {}
            for _,chara in ipairs(Game.party) do
                --print(chara.id)
                table.insert(spenders, chara.id)
            end
        else
            spenders = {spenders}
        end
    end
    if type(party) == "string" then
        if party == "all" then
            party = {}
            for _,chara in ipairs(Game.party) do
                --print(chara.id)
                table.insert(party, chara.id)
            end
        else
            party = {party}
        end
    end

    --print("BABUSHKA")
    --for _,act in ipairs(enemy.acts) do
            --print(act.mp)
            local act_cost = {
            ["name"] = name,
            ["resource"] = "mana",
            ["cost"] = mp --for now
        }
            --print(act_cost.name)
            --print(act_cost.name)
            --print(act_cost.mp)
        table.insert(Game.battle.act_resources, act_cost)
        --print(Game.battle.act_resources[1])
    --end

    --[[if split_cost then
        local spenders_present = 0

        for _,spender in ipairs(spenders) do
            local party_index = Game.battle:getPartyIndex(spender)
            local battler = Game.battle.party[party_index]
            if battler --[[and battler:isActive()then
                spenders_present = spenders_present + 1
            end
        end
        if spenders_present > 0 then
            mp = Utils.getFractional(mp, 1, spenders_present)
        end
    end]]
    --print("bbbbbasasasa")
    --print(split_cost)
    local act = {
        ["character"] = nil,
        ["name"] = name,
        ["resource"] = "mana",
        ["spenders"] = spenders,
        ["split_cost"] = split_cost,
        ["description"] = description,
        ["party"] = party,
        ["mp"] = mp,
        ["highlight"] = highlight,
        ["short"] = false,
        ["icons"] = icons
    }
    table.insert(self.acts, act)
    --print("huhhhhhhhh " .. mp)
    return act
end

function EnemyBattler:statusMessageMana(...)
    return super.super.statusMessage(self, self.width/2, self.height/2, ...)
end

return EnemyBattler