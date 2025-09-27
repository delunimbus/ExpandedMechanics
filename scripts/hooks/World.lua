---@class World : World 
---@overload fun(...) : World
local World, super = Class("World", true)

function World:onKeyPressed(key)
    if Kristal.Config["debug"] and Input.ctrl() then
        if key == "m" then
            if self.music then
                if self.music:isPlaying() then
                    self.music:pause()
                else
                    self.music:resume()
                end
            end
        end
        if key == "s" then
            local save_pos = nil
            if Input.shift() then
                save_pos = {self.player.x, self.player.y}
            end
            if Game:getConfig("smallSaveMenu") then
                self:openMenu(SimpleSaveMenu(Game.save_id, save_pos))
            elseif Game:isLight() then
                self:openMenu(LightSaveMenu(save_pos))
            else
                self:openMenu(SaveMenu(save_pos))
            end
        end
        if key == "h" then
            for _,party in ipairs(Game.party) do
                party:heal(math.huge)
            end
        end
        if key == "b" then
            if Input.shift() then
                Game.world:hurtParty(20)
            else
                Game.world:hurtParty(math.huge)
            end
        end
        if key == "k" then
            Game:setTension(Game:getMaxTension() * 2, true)
        end
        if key == "n" then
            NOCLIP = not NOCLIP
        end
    end

    if Game.lock_movement then return end

    if self.state == "GAMEPLAY" then
        if Input.isConfirm(key) and self.player and not self:hasCutscene() then
            if self.player:interact() then
                Input.clear("confirm")
            end
        elseif Input.isMenu(key) and not self:hasCutscene() then
            self:openMenu(nil, WORLD_LAYERS["ui"] + 1)
            Input.clear("menu")
        end
    elseif self.state == "MENU" then
        if self.menu and self.menu.onKeyPressed then
            self.menu:onKeyPressed(key)
        end
    end
end

return World