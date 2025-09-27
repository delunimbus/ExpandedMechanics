---@class Item : Item
---@field revive boolean
---@overload fun(...) : Item
local Item, super = Class(Item)

function Item:init()
    super.init(self)

    -- Whether the item revives a fallen party member (used for the "traditional" down mode)
    self.revive = true

end

--- Gets whether the item can revive party members with the `"traditional"` down mode.
---@return boolean
function Item:canRevive() return self.revive end

--- Revives party battlers with the `"traditional"` down mode
---@param target PartyBattler|PartyBattler[]
function HealItem:battleReviveTarget(target)
    if self.target == "ally" then
        target:revive()
    elseif self.target == "party" then
        for _,battler in ipairs(target) do
            battler:revive()
        end
    end
end

return Item