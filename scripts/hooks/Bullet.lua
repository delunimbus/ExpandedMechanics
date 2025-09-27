---@class Bullet : Bullet
---@field alt_damage        table<table>
---@field deplete_resources string[]
---@field magic_damage      boolean
---@field magic_damage_to_resources string[]
---@field status_conditions string[]
---@field element           string
---@overload fun(...) : Bullet
local Bullet, super = Class(Bullet)


function Bullet:init(x, y, texture)

    super.init(self, x, y)

    self.layer = BATTLE_LAYERS["bullets"]

    -- Set scale and origin
    self:setOrigin(0.5, 0.5)
    self:setScale(2, 2)

    -- Add a sprite, if we provide one
    if texture then
        self:setSprite(texture, 0.25, true)
    end

    -- Default collider to half this object's size
    self.collider = Hitbox(self, self.width/4, self.height/4, self.width/2, self.height/2)

    -- TP added when you graze this bullet (Also given each frame after the first graze, 30x less at 30FPS)
    self.tp = 1.6 -- (1/10 of a defend, or cheap spell)
    -- Turn time reduced when you graze this bullet (Also applied each frame after the first graze, 30x less at 30FPS)
    self.time_bonus = 1

    -- Damage given to the player when hit by this bullet (Defaults to 5x the attacker's attack stat)
    self.damage = nil
    -- Alternative damage values {name: string, value: number}
    self.alt_damage = {}
    -- Invulnerability timer to apply to the player when hit by this bullet (Defaults to 4/3 seconds)
    self.inv_timer = (4/3)
    -- Whether this bullet gets removed on collision with the player (Defaults to `true`)
    self.destroy_on_hit = true

    -- Whether this bullet has already been grazed (reduces graze rewards)
    self.grazed = false

    -- Whether to remove this bullet when it goes offscreen (Defaults to `true`)
    self.remove_offscreen = true

    ------------------------------------------------
    -- What resource(s) to deplete when it hits the soul (defaults to "health" only)
    self.deplete_resources = {"health"}
    -- Whether the damage dealt counts as magic damage and thus have the target's spirit stat be used to calculate damage.  \
    -- (should only be used if damage value is NOT a table.)
    self.magic_damage = false
    -- What resources that are being attacked will count as magic damage (none by default, can only be used if damage value is a table)
    self.magic_damage_to_resources = {}

    --Table of status conditions to give the target in case it hits AND deals damage.
    self.status_conditions = {}
    --(Proposed comapatability option with "StatusCORE")

    -- Element type of the bullet (leave `nil` for non-elemental)
    self.element = nil
    ------------------------------------------------
end

function Bullet:getResourcesToDeplete() return self.deplete_resources end

function Bullet:getStatusConditions() return self.status_conditions end

--- *(Override)* Called when the bullet hits the player's soul without invulnerability frames. \
--- Not calling `super.onDamage()` here will stop the normal damage logic from occurring.
---@param soul Soul
---@param resource_damage_table? boolean
---@return table<PartyBattler> battlers_hit
function Bullet:onDamage(soul, resource_damage_table)

    local damage = nil
    if resource_damage_table then
        damage = self:getDamageTable()
    else
        damage = self:getDamage()
    end

    print(type(damage))

    local luck_evade_chance = love.math.random(1, 12)        --test; to be replaced by "luck" stat

    if luck_evade_chance ~= 12 then
        if type(damage) == "number" and damage > 0 then
            local battlers = Game.battle:depleteResources(self.deplete_resources, damage, false, self:getTarget(), self.magic_damage, self:getStatusConditions(), self.element)
            --Game.battle:inflictStatuses(self.status_conditions, self:getTarget())
            soul.inv_timer = self.inv_timer
            soul:onDamage(self, damage)
            return battlers
        elseif type(damage) == "table" then
            local battlers = Game.battle:depleteResources(self.deplete_resources, damage, false, self:getTarget(), false, self:getStatusConditions(), self.element)
            --Game.battle:inflictStatuses(self.status_conditions, self:getTarget())
            soul.inv_timer = self.inv_timer
            soul:onDamage(self, damage)
            return battlers
        end
    else
        soul.inv_timer = self.inv_timer
        soul:onDamage(self, damage)
        return Game.battle:luckyEvade(self:getTarget())
    end

    return {}
end

---@return number
function Bullet:getDamage()
    return self.damage or (self.attacker and self.attacker.attack * 5) or 0
end

function Bullet:getManaDepletion()
    return self.damage or (self.attacker and self.attacker.magic * 3) or 0
end

--Gets a table of damage values for different resources.
---@return table
function Bullet:getDamageTable()
    local resource_damage = {}

    local health_magic_damage = false
    local mana_magic_damage = false

    for _,r in ipairs(self.magic_damage_to_resources) do
        if r == "health" then
            health_magic_damage = true
        elseif r == "mana" then
            mana_magic_damage = true
        end
    end

    --print(tostring(health_magic_damage) .. " squadala")
    --print(tostring(mana_magic_damage) .. " shamood")

    local health_damage = {
        ["resource"] = "health",
        ["value"]    = self:getDamage(),
        ["magicDamage"] = health_magic_damage
    }
    local mana_depletion = {
        ["resource"] = "mana",
        ["value"]    = self:getManaDepletion(),
        ["magicDamage"] = mana_magic_damage
    }
    table.insert(resource_damage, health_damage)
    table.insert(resource_damage, mana_depletion)
    return resource_damage
end

--Sets up an alternative damage value.
---@param name  string  The name of the alternative value.
---@param value number  The value of the alternative value.
function Bullet:setAltDamage(name, value)
    local alt_damage = {
        ["name"] = name,
        ["value"] = value
    }
    table.insert(self.alt_damage, alt_damage)
end

--Gets an alternative damage value.
---@param name  string The name of the alternative value.
---@return number
function Bullet:getAltDamage(name)
    --local value = self.damage
    for _,v in ipairs(self.alt_damage) do
        if v.name == name then
            return v.value
        end
    end
    return self:getDamage()
end

--- *(Override)* Called when the bullet collides with the player's soul, before invulnerability checks.
---@param soul Soul
function Bullet:onCollide(soul)
    if soul.inv_timer == 0 then
        self:onDamage(soul)
    end

    if self.destroy_on_hit then
        self:remove()
    end
end


return Bullet