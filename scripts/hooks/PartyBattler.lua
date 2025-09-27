---@class PartyBattler : PartyBattler
---@overload fun(...) : PartyBattler
local PartyBattler, super = Class("PartyBattler", true)

--- Gets the damage reduction multiplier for damage of a particular element
---@param element number
---@return integer multiplier
function PartyBattler:getElementReduction(element)
    -- TODO: this

    if (element == 0) then return 1 end

    -- dummy values since we don't have elements
    local armor_elements = {
        {element = 0, element_reduce_amount = 0},
        {element = 0, element_reduce_amount = 0}
    }

    local reduction = 1
    for i = 1, 2 do
        local item = armor_elements[i]
        if (item.element ~= 0) then
            if (item.element == element)                              then reduction = reduction - item.element_reduce_amount end
            if (item.element == 9 and (element == 2 or element == 8)) then reduction = reduction - item.element_reduce_amount end
            if (item.element == 10)                                   then reduction = reduction - item.element_reduce_amount end
        end
    end
    return math.max(0.25, reduction)
end

---@param amount    number  The damage of the incoming hit
---@param exact?    boolean Whether the damage should be treated as exact damage instead of applying defense and element modifiers
---@param color?    table   The color of the damage number
---@param options?  table   A table defining additional properties to control the way damage is taken
---@param element?  string  The element to make damage calculations with (if any)
---|"all"   # Whether the damage being taken comes from a strike targeting the whole party
---|"magic_damage"  # Whether to use the spirit stat to calculate damage instead of defense
function PartyBattler:hurt(amount, exact, color, element, options)
    local passive = self.chara:getPassive()
    options = options or {}

    if not options["all"] then
        if options["magic_damage"] then
            Assets.stopAndPlaySound("spellcast", 0.7)
        else
            Assets.stopAndPlaySound("hurt")
        end
        if not exact then
            if options["magic_damage"] then
                --print("hamburger")
                amount = self:calculateMagicDamage(amount)
                if passive then
                    --print("tttttt")
                    amount = passive:applyMagicDamageRecievedMod(self, amount, nil, element)
                end
            else
                --print("sadge")
                amount = self:calculateDamage(amount)
                if passive then
                    amount = passive:applyPhysicalDamageRecievedMod(self, amount, nil, element)
                end
            end
            if self.defending then
                amount = math.ceil((2 * amount) / 3)
            end
            -- we don't have elements right now
            --local element = 0
            ----amount = math.ceil((amount * self:getElementReduction(element)))
            --amount = math.ceil
        end

        self:removeHealth(amount)
    else
        -- We're targeting everyone.
        if not exact then
            if options["magic_damage"] then
                --print("HAMNAMNHAMANAHAMAMNAH")
                amount = self:calculateMagicDamage(amount)
                if passive then
                    amount = passive:applyMagicDamageRecievedMod(self, amount, nil, element)
                end
            else
                --print("DIESOFCRINGE")
                amount = self:calculateDamage(amount)
                if passive then
                    amount = passive:applyPhysicalDamageRecievedMod(self, amount, nil, element)
                end
            end
            -- we don't have elements right now
            --local element = 0
            --amount = math.ceil((amount * self:getElementReduction(element)))

            if self.defending then
                amount = math.ceil((3 * amount) / 4) -- Slightly different than the above
            end
        end

        self:removeHealthBroken(amount) -- Use a separate function for cleanliness
    end

    --[[if amount > 0 then
        Game.battle.actual_number_of_resources_depleted = Game.battle.actual_number_of_resources_depleted + 1
    end]]

    if (self.chara:getHealth() <= 0) then
        self:statusMessage("msg", "down", color, true)
    else
        self:statusMessage("damage", amount, color, true)
    end

    self.hurt_timer = 0
    Game.battle:shakeCamera(4)

    if (not self.defending) and (not self.is_down) then

        self.sleeping = false
        self.hurting = true
        self:toggleOverlay(true)
        self.overlay_sprite:setAnimation("battle/hurt", function()
            if self.hurting then
                self.hurting = false
                self:toggleOverlay(false)
            end
        end)
        if not self.overlay_sprite.anim_frames then -- backup if the ID doesn't animate, so it doesn't get stuck with the hurt animation
            Game.battle.timer:after(0.5, function()
                if self.hurting then
                    self.hurting = false
                    self:toggleOverlay(false)
                end
            end)
        end
    end
end

function PartyBattler:removeHealth(amount)
    if (self.chara:getHealth() <= 0) and self.chara:getDownMode() == "deltarune" then
        amount = Utils.round(amount / 4)
        self.chara:setHealth(self.chara:getHealth() - amount)
    else
        self.chara:setHealth(self.chara:getHealth() - amount)
        if (self.chara:getHealth() <= 0) then
            if self.chara:getDownMode() == "deltarune" then
                amount = math.abs((self.chara:getHealth() - (self.chara:getStat("health") / 2)))
                self.chara:setHealth(Utils.round(((-self.chara:getStat("health")) / 2)))
            elseif self.chara:getDownMode() == "traditional" then
                --print("xxxxxxx")
                self.chara:setHealth(0)
            end
        end
    end
    self:checkHealth()
end

--- Checks whether the battler's down state needs to be changed based on its current health
function PartyBattler:checkHealth()
    print(self.chara:getName().." health: "..self.chara:getHealth())
    if (not self.is_down) and (self.chara:getHealth() <= 0) then

        if self.chara:isDownImmune() then
            self.chara:setHealth(1)

            --[[if self.chara:getDownMode() == "traditional" then
                print("habibi")
                if self.chara:getHealth() < 0 then
                    self.chara:setHealth(0)
                end
                --self:down()
            end]]
        else self:down()
        end
    elseif (self.is_down) and self.chara:getHealth() > 0 and (self.chara:getDownMode() ~= "traditional") then
        print(self.chara:getName())
        self:revive()
    end
end

function PartyBattler:revive()
    self.is_down = false
    self:toggleOverlay(false)
    Game.battle:updateSplitCost()
end

function PartyBattler:down()
    self.is_down = true
    self.sleeping = false
    self.hurting = false
    self:toggleOverlay(true)
    self.overlay_sprite:setAnimation("battle/defeat")
    if self.action then
        Game.battle:removeAction(Game.battle:getPartyIndex(self.chara.id))
    end
    Game.battle:updateSplitCost()
    Game.battle:checkGameOver()
end

--Prevents mana from going below 0
function PartyBattler:checkMana()
    if self.chara:getMana() <= 0 then
        self.chara:setMana(0)
    end
end

---@param amount    number  The depletion from the incoming hit
---@param exact?    boolean Whether the depletion should be treated as exact depletion instead of applying defense and element modifiers
---@param color?    table   The color of the depletion number
---@param element?  string  The element to make damage calculations with (if any)
---@param options?  table   A table defining additional properties to control the way depletion is taken
---|"all"   # Whether the depletion being taken comes from a strike targeting the whole party
---|"magic_damage"  # Whether to use the spirit stat to calculate damage instead of defense
function PartyBattler:depleteMana(amount, exact, color, element, options)
    local passive = self.chara:getPassive()
    options = options or {}

    if not options["all"] then
        if options["magic_damage"] then
            Assets.stopAndPlaySound("spellcast", 0.7)
        end
        Assets.stopAndPlaySound("PMD2_PP_Down", 0.7)
        if not exact then
            if options["magic_damage"] then
                print("BEEEANNZ WTF")
                amount = self:calculateMagicDamage(amount)
            else
                print("mm")
                amount = self:calculateDamage(amount)
                if passive then
                    amount = passive:applyPhysicalDamageRecievedMod(self, amount, nil, element)
                end
            end

            if self.defending then
                amount = math.ceil((2 * amount) / 3)
            end
            -- we don't have elements right now
            --local element = 0
            --amount = math.ceil((amount * self:getElementReduction(element)))
        end

        self:removeMana(amount)
    else
        -- We're targeting everyone.
        if not exact then
            if options["magic_damage"] then
                amount = self:calculateMagicDamage(amount)
            else
                amount = self:calculateDamage(amount)
                if passive then
                    amount = passive:applyPhysicalDamageRecievedMod(self, amount, nil, element)
                end
            end
            -- we don't have elements right now
            --local element = 0
            --amount = math.ceil((amount * self:getElementReduction(element)))

            if self.defending then
                amount = math.ceil((3 * amount) / 4) -- Slightly different than the above
            end
        end

        self:removeMana(amount) -- Use a separate function for cleanliness (nuh uh)
    end

    --[[if amount > 0 and self.chara:getMana() > 0 then
        Game.battle.actual_number_of_resources_depleted = Game.battle.actual_number_of_resources_depleted + 1
    end]]

    if (self.chara:getMana() <= 0) then
        if self.chara:usesMana() then
            self:statusMessageMana("damage", -amount, {30/255, 144/255, 1}, true)
        end
    else
        self:statusMessageMana("damage", -amount or 0, {30/255, 144/255, 1}, true)
    end

    self.hurt_timer = 0
    Game.battle:shakeCamera(4)

    if (not self.defending) and (not self.is_down) then
        self.sleeping = false
        self.hurting = true
        self:toggleOverlay(true)
        self.overlay_sprite:setAnimation("battle/hurt", function()
            if self.hurting then
                self.hurting = false
                self:toggleOverlay(false)
            end
        end)
        if not self.overlay_sprite.anim_frames then -- backup if the ID doesn't animate, so it doesn't get stuck with the hurt animation
            Game.battle.timer:after(0.5, function()
                if self.hurting then
                    self.hurting = false
                    self:toggleOverlay(false)
                end
            end)
        end
    end
end

--- Removes MP from the character
---@param amount number
function PartyBattler:removeMana(amount)
    if (self.chara:getMana() <= 0) then
        --amount = Utils.round(amount / 4)
        self.chara:setMana(0)
    else
        self.chara:setMana(self.chara:getMana() - amount)
        --[[if (self.chara:getHealth() <= 0) then
            amount = math.abs((self.chara:getHealth() - (self.chara:getStat("health") / 2)))
            self.chara:setHealth(Utils.round(((-self.chara:getStat("health")) / 2)))
        end]]
    end
    self:checkMana()
end

--- Heals the Battler by `amount` mana and does healing effects
---@param amount            number  The amount of mana to restore
---@param sparkle_color?    table   The color of the heal sparkles (defaults to the standard green)
function PartyBattler:regenMana(amount, sparkle_color)
    Assets.stopAndPlaySound("PMD2_PP_Up")

    amount = math.floor(amount)

    self.chara:setMana(self.chara:getMana() + amount)

    --local was_down = self.is_down
    --self:checkHealth()

    self:flash()

    if self.chara:usesMana() and self.chara:getMana() >= self.chara:getStat("mana") then
        self.chara:setMana(self.chara:getStat("mana"))
        --self:statusMessage("heal", amount)
    else
        --[[if show_up then
            if was_down ~= self.is_down then
                self:statusMessage("msg", "up_mp")
            end
        else]]
            self:statusMessageMana("regen", amount, {30/255, 144/255, 1})
        --end
    end

    self:sparkle(unpack(sparkle_color or {30/255, 144/255, 1}))
end

--- Calculates the damage the battler should take after spirit reductions
---@param amount number
---@return number
function PartyBattler:calculateMagicDamage(amount)
    local spirit = self.chara:getStat("spirit")
    local max_hp = self.chara:getStat("health")

    local threshold_a = (max_hp / 5)
    local threshold_b = (max_hp / 8)
    for i = 1, spirit do
        if amount > threshold_a then
            amount = amount - 3
        elseif amount > threshold_b then
            amount = amount - 2
        else
            amount = amount - 1
        end
        if amount <= 0 or spirit == math.huge then
            amount = 0
            break
        end
    end

    return math.max(amount, 1)
end

function PartyBattler:statusMessageMana(...)    --This is just me being lazy
    --print("Rat")
    local message = super.super.statusMessage(self, 0, (self.height/2) - 10, ...)
    message.y = message.y - 4
    return message
end

function PartyBattler:statusMessage(...)
    local message = super.super.statusMessage(self, 0, self.height/2, ...)
    message.y = message.y - 4
    return message
end

function PartyBattler:playHurtAnim()
    self.hurt_timer = 0
    Game.battle:shakeCamera(4)

    if (not self.defending) and (not self.is_down) then
        self.sleeping = false
        self.hurting = true
        self:toggleOverlay(true)
        self.overlay_sprite:setAnimation("battle/hurt", function()
            if self.hurting then
                self.hurting = false
                self:toggleOverlay(false)
            end
        end)
        if not self.overlay_sprite.anim_frames then -- backup if the ID doesn't animate, so it doesn't get stuck with the hurt animation
            Game.battle.timer:after(0.5, function()
                if self.hurting then
                    self.hurting = false
                    self:toggleOverlay(false)
                end
            end)
        end
    end
end

return PartyBattler