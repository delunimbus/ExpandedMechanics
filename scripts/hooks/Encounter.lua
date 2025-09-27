---@class Encounter : Encounter
---
---@field encounter_spells Spells[]
---
---@overload fun(...) : Encounter
local Encounter, super = Class("Encounter", true)

function Encounter:init()

    super.init(self)

    --List of all enemy spells (including duplicates)
    self.encounter_spells = {}

end

function Encounter:getEncounterSpells()

    --print("aaaaaaa")
    self.encounter_spells = {}

    for _,enemy in ipairs(Game.battle:getActiveEnemies()) do
        --print("bbbbbb")
        for _,spell in ipairs(enemy:getEnemySpells()) do
            --print("cccccc")
            table.insert(self.encounter_spells, spell)
        end
    end

    return self.encounter_spells

end

return Encounter