---@class DarkPowerMenu : Object
---@overload fun(...) : DarkPowerMenu
local DarkPowerMenu, super = Class(Object)

function DarkPowerMenu:init()
    super.init(self, 82, 112, 477, 277)

    self.draw_children_below = 0

    self.font = Assets.getFont("main")

    self.ui_move = Assets.newSound("ui_move")
    self.ui_select = Assets.newSound("ui_select")
    self.ui_cant_select = Assets.newSound("ui_cant_select")
    self.ui_cancel_small = Assets.newSound("ui_cancel_small")

    self.heart_sprite = Assets.getTexture("player/heart")
    self.arrow_sprite = Assets.getTexture("ui/page_arrow_down")

    self.tp_sprite = Game:getConfig("oldUIPositions") and Assets.getTexture("ui/menu/caption_tp_old") or Assets.getTexture("ui/menu/caption_tp")
    self.mp_sprite = Game:getConfig("oldUIPositions") and Assets.getTexture("ui/menu/caption_mp_old") or Assets.getTexture("ui/menu/caption_mp")
    self.hp_sprite = Game:getConfig("oldUIPositions") and Assets.getTexture("ui/menu/caption_mp_old") or Assets.getTexture("ui/menu/caption_hp")
    self.units_sprite = Game:getConfig("oldUIPositions") and Assets.getTexture("ui/menu/caption_units_old") or Assets.getTexture("ui/menu/caption_units")

    self.caption_sprites = {
          ["char"] = Assets.getTexture("ui/menu/caption_char"),
         ["stats"] = Assets.getTexture("ui/menu/caption_stats"),
        ["spells"] = Assets.getTexture("ui/menu/caption_spells"),
    }

    self.stat_icons = {
         ["attack"] = Assets.getTexture("ui/menu/icon/sword"),
        ["defense"] = Assets.getTexture("ui/menu/icon/armor"),
          ["magic"] = Assets.getTexture("ui/menu/icon/magic"),
         ["spirit"] = Assets.getTexture("ui/menu/icon/spirit"),
   }

    self.bg = UIBox(0, 0, self.width, self.height)
    self.bg.layer = -1
    self.bg.debug_select = false
    self:addChild(self.bg)

    self.party = DarkMenuPartySelect(8, 48)
    self.party.focused = true
    self.party.highlight_party = false
    self:addChild(self.party)

    self.party.on_select = function(new, old)
        Game.party[old]:onPowerDeselect(self)
        Game.party[new]:onPowerSelect(self)
    end

    -- PARTY, SPELLS
    self.state = "PARTY"

    self.selected_spell = 1

    self.scroll_y = 1
end

function DarkPowerMenu:getSpellLimit()
    return 6
end

function DarkPowerMenu:getSpells()
    local spells = {}
    local party = self.party:getSelected()
    if party:hasAct() then
        table.insert(spells, Registry.createSpell("_act"))
    end
    for _,spell in ipairs(party:getSpells()) do
        table.insert(spells, spell)
    end
    return spells
end

function DarkPowerMenu:getPassive()
    local passive_preview = {}
    local party = self.party:getSelected()
    local passive = party.passive
    if passive then
        passive = Mod:createPassive(passive)
        passive_preview = { name = passive:getName(), effect = passive:getEffect(), desc = passive:getDescription(), icon = passive.passive_icon, color = passive.passive_color }
    end
    return passive_preview
end

function DarkPowerMenu:showPassiveDescription(passive)
    --setTextColor(r, g, b, a)
    Game.world.menu:setColoredDescription(passive.name and passive.desc or "", true, 30/255, 144/255, 255)
end

function DarkPowerMenu:updateDescription()
    if self.state == "PARTY" then
        Game.world.menu:setDescription("", false)
    elseif self.state == "SPELLS" then
        local spell = self:getSpells()[self.selected_spell]
        Game.world.menu:setDescription(spell and spell:getDescription() or "", true)
    end
end

function DarkPowerMenu:onRemove(parent)
    super.onRemove(self, parent)
    if Game.world.menu then
        Game.world.menu:updateSelectedBoxes()
    end
end

function DarkPowerMenu:update()
    if Input.down("menu") then
        self:showPassiveDescription(self:getPassive())
    else
        self:updateDescription()
    end
    if self.state == "PARTY" then
        if Input.pressed("cancel") then
            self.ui_cancel_small:stop()
            self.ui_cancel_small:play()
            Game.world.menu:closeBox()
            return
        elseif Input.pressed("confirm") then
            if #self:getSpells() > 0 then
                self.state = "SPELLS"

                self.party.focused = false

                self.ui_select:stop()
                self.ui_select:play()

                self.selected_spell = 1
                self.scroll_y = 1

                self:updateDescription()
            else
                self.ui_select:stop()
                self.ui_select:play()
            end
        end
    elseif self.state == "SPELLS" then
        if Input.pressed("cancel") then
            self.state = "PARTY"

            self.ui_cancel_small:stop()
            self.ui_cancel_small:play()

            self.party.focused = true

            self.scroll_y = 1

            self:updateDescription()
            return
        end
        if Input.pressed("confirm") then
            local spell = self:getSpells()[self.selected_spell]
            if self:canCast(spell) then
                self.state = "USE"
                if spell.target == "ally" or spell.target == "party" then

                    local target_type = spell.target == "ally" and "SINGLE" or "ALL"

                    self:selectParty(target_type, spell)
                else
                    Game:removeTension(spell:getTPCost())
                    spell:onWorldCast()
                    self.state = "SPELLS"
                end
            end
        end
        local spells = self:getSpells()
        local old_selected = self.selected_spell
        if Input.pressed("up", true) then
            self.selected_spell = self.selected_spell - 1
        end
        if Input.pressed("down", true) then
            self.selected_spell = self.selected_spell + 1
        end
        self.selected_spell = Utils.clamp(self.selected_spell, 1, #spells)
        if self.selected_spell ~= old_selected then
            local spell_limit = self:getSpellLimit()
            local min_scroll = math.max(1, self.selected_spell - (spell_limit - 1))
            local max_scroll = math.min(math.max(1, #spells - (spell_limit - 1)), self.selected_spell)
            self.scroll_y = Utils.clamp(self.scroll_y, min_scroll, max_scroll)

            self.ui_move:stop()
            self.ui_move:play()
            self:updateDescription()
        end
    end
    super.update(self)
end

function DarkPowerMenu:selectParty(target_type, spell)
    Game.world.menu:partySelect(target_type, function(success, party)
        Game.world:setWorldCaster(self.party:getSelected())
        local main_resource = self.party:getSelected():getMainSpellResourceType()
        if success then
            if main_resource == "tension" then
                Game:removeTension(spell:getTPCost())
            elseif main_resource == "mana" then
                Game.world:getWorldCaster():removeMana(spell:getMPCost(Game.world:getWorldCaster()))
            elseif main_resource == "stock" then
                Game.world:getWorldCaster():removeStock(spell, 1)
            end
            spell:onWorldCast(party)
            if self:canCast(spell) then
                self:selectParty(target_type, spell)
            else
                self.state = "SPELLS"
            end

        else
            Game.world:setWorldCaster(nil)
            self.state = "SPELLS"
        end
    end)
    
end

function DarkPowerMenu:canCast(spell)
    if not Game:getConfig("overworldSpells") then return false end

    local main_resource = self.party:getSelected():getMainSpellResourceType()

    if main_resource == "tension" then
        if Game:getTension() < spell:getTPCost(self.party:getSelected()) then return false end
    elseif main_resource == "mana" then
        if self.party:getSelected():getMana() < spell:getMPCost(self.party:getSelected()) then return false end
    elseif main_resource == "stock" then
        if spell:getStock(self.party:getSelected()) <= 0 then return false end
    end

    return (spell:hasWorldUsage(self.party:getSelected()))
end

function DarkPowerMenu:draw()
    love.graphics.setFont(self.font)

    Draw.setColor(PALETTE["world_border"])
    love.graphics.rectangle("fill", -24, 104, 525, 6)
    if Game:getConfig("oldUIPositions") then
        love.graphics.rectangle("fill", 212, 104, 6, 196)
    else
        love.graphics.rectangle("fill", 212, 104, 6, 200)
    end

    Draw.setColor(1, 1, 1, 1)
    Draw.draw(self.caption_sprites[  "char"],  42, -28, 0, 2, 2)
    Draw.draw(self.caption_sprites[ "stats"],  42,  98, 0, 2, 2)
    Draw.draw(self.caption_sprites["spells"], 298,  98, 0, 2, 2)

    self:drawChar()
    self:drawStats()
    self:drawSpells()

    super.draw(self)
end

function DarkPowerMenu:drawChar()
    local party = self.party:getSelected()
    Draw.setColor(PALETTE["world_text"])
    love.graphics.print(party:getName(), 48, -7)
    love.graphics.print(party:getTitle(), 238, -7)
end

function DarkPowerMenu:drawStats()
    local party = self.party:getSelected()
    Draw.setColor(1, 1, 1, 1)
    Draw.draw(self.stat_icons[ "attack"], -8, 124, 0, 2, 2)
    Draw.draw(self.stat_icons[  "magic"], 108, 124, 0, 2, 2)
    Draw.draw(self.stat_icons["defense"], -8, 149, 0, 2, 2)
    Draw.draw(self.stat_icons[ "spirit"], 108, 149, 0, 2, 2)

    love.graphics.print("A:", 18, 118)
    love.graphics.print("M:", 133, 118)
    love.graphics.print("D:", 18, 143)
    love.graphics.print("S:", 135, 143)

    local stats = party:getStats()
    love.graphics.print(stats[ "attack"], 48, 118)
    love.graphics.print(stats[  "magic"], 168, 118)
    love.graphics.print(stats["defense"], 48, 143)
    love.graphics.print(stats[ "spirit"], 168, 143)

    for i = 1, 3 do
        local x, y = 18, 148 + (i * 25)
        love.graphics.setFont(self.font)
        Draw.setColor(PALETTE["world_text"])
        love.graphics.push()
        if not party:drawPowerStat(i, x, y, self) then
            Draw.setColor(PALETTE["world_dark_gray"])
            love.graphics.print("???", x, y)
        end
        love.graphics.pop()
    end

    local passive = self:getPassive()
    --local passive = self.party:getSelected():getPassive()
    --if passive then
    self:drawPassivePreview(1, -8, 256, passive)
   -- end

end

function DarkPowerMenu:drawPassivePreview(index, x, y, passive--[[, compare]])
    --local name = passives[index] and passives[index].name or nil
    --local comp_name = compare[index] and compare[index].name or nil
    --if passives[index] and passives[index].icon then
        --local yoff = self.state == "ITEMS" and -6 or 2
        local texture = Assets.getTexture(passive.passive_icon) --or Assets.getTexture("ui/menu/icon/alt_up")
        --if texture then
            Draw.setColor(passive.color or {30/255, 144/255, 255})
            Draw.draw(texture or Assets.getTexture("ui/menu/icon/up_alt"), x, y, 0, 2, 2)
        --end
    --end
    --[[if name ~= comp_name then
        if name ~= nil then
            Draw.setColor(1, 1, 0)
        else
            Draw.setColor(1, 0, 0)
        end
    else
        if (name and self.state ~= "ITEMS") or (self.state == "ITEMS" and self.selected_slot == index and self:canEquipSelected()) then
            Draw.setColor(1, 1, 1)
        else
            Draw.setColor(0.25, 0.25, 0.25)
        end
    end]]
    local name = passive.name
    --local effect = passive.effect
    --print(desc)
    if name then
        Draw.setColor(1, 1, 1)
        --love.graphics.print(effect, x + 235, y - 6)
    else
        Draw.setColor(0.25, 0.25, 0.25)
    end
    love.graphics.print(name or "(No passive.)", x + 26, y - 6)

end

function DarkPowerMenu:drawSpells()
    local spells = self:getSpells()

    local tp_x, tp_y
    local name_x, name_y

    if #spells <= 6 then
        tp_x, tp_y = 258, 118
        name_x, name_y = 328, 118
    else
        tp_x, tp_y = 242, 118
        name_x, name_y = 302, 118
    end

    Draw.setColor(1, 1, 1)

    local main_resource = self.party:getSelected():getMainSpellResourceType()

    if main_resource == "tension" then
        Draw.draw(self.tp_sprite, tp_x, tp_y - 5)
    elseif main_resource == "mana" then
        Draw.draw(self.mp_sprite, tp_x, tp_y - 5)
    elseif main_resource == "stock" then
        Draw.draw(self.units_sprite, tp_x, tp_y - 5)
    elseif main_resource == "health" then
        Draw.draw(self.hp_sprite, tp_x, tp_y - 5)
    end
    local spell_limit = self:getSpellLimit()

    for i = self.scroll_y, math.min(#spells, self.scroll_y + (spell_limit - 1)) do
        local spell = spells[i]
        local offset = i - self.scroll_y

        if not self:canCast(spell) then
            Draw.setColor(0.5, 0.5, 0.5)
        else
            Draw.setColor(1, 1, 1)
        end

        if main_resource == "tension" then
            love.graphics.print(tostring(spell:getTPCost(self.party:getSelected())).."%", tp_x, tp_y + (offset * 25))
        elseif main_resource == "mana" then
            love.graphics.print(tostring(spell:getMPCost(self.party:getSelected())), tp_x, tp_y + (offset * 25))
        elseif main_resource == "stock" then
            love.graphics.print(tostring(spell:getStock(self.party:getSelected())), tp_x, tp_y + (offset * 25))
        elseif main_resource == "health" then
            love.graphics.print(tostring(spell:getHPCost(self.party:getSelected())), tp_x, tp_y + (offset * 25))
        end
        love.graphics.print(spell:getName(), name_x, name_y + (offset * 25))

    end

    -- Draw scroll arrows if needed
    if #spells > spell_limit then
        Draw.setColor(1, 1, 1)

        -- Move the arrows up and down only if we're in the spell selection state
        local sine_off = 0
        if self.state == "SPELLS" then
            sine_off = math.sin((Kristal.getTime()*30)/12) * 3
        end

        if self.scroll_y > 1 then
            -- up arrow
            Draw.draw(self.arrow_sprite, 469, (name_y + 25 - 3) - sine_off, 0, 1, -1)
        end
        if self.scroll_y + spell_limit <= #spells then
            -- down arrow
            Draw.draw(self.arrow_sprite, 469, (name_y + (25 * spell_limit) - 12) + sine_off)
        end
    end

    if self.state == "SPELLS" then
        Draw.setColor(Game:getSoulColor())
        Draw.draw(self.heart_sprite, tp_x - 20, tp_y + 10 + ((self.selected_spell - self.scroll_y) * 25))

        -- Draw scrollbar if needed (unless the spell limit is 2, in which case the scrollbar is too small)
        if spell_limit > 2 and #spells > spell_limit then
            local scrollbar_height = (spell_limit - 2) * 25
            Draw.setColor(0.25, 0.25, 0.25)
            love.graphics.rectangle("fill", 473, name_y + 30, 6, scrollbar_height)
            local percent = (self.scroll_y - 1) / (#spells - spell_limit)
            Draw.setColor(1, 1, 1)
            love.graphics.rectangle("fill", 473, name_y + 30 + math.floor(percent * (scrollbar_height-6)), 6, 6)
        end
    end
end

return DarkPowerMenu