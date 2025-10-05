---@class Battle : Battle
---@field draw_cast                             boolean         Whether the spell was casted from the draw skill.
---@field act_resources                         table<table>    The table of resources that will be used for acts.
---@field number_of_resources_to_deplete        integer         The number of multiple resources to deplete.
---@field actual_number_of_resources_depleted   integer         The actual number of resources depleted.
---@field spenders_to_refund                    table<string>   The spenders to refund when an aciton is canceled.
---@field party_lucky_evade                     boolean         Whether the party avoided a hit.
---@field attack_spenders                       table<table>    Table of party members that spent resources attacking.
---@overload fun(...) : Battle
local Battle, super = Class("Battle", true)

function Battle:init()

    super.init(self)

    self.draw_cast = false

    self.act_resources = {}         --{name: string, resource: string, cost: number}
    --This should be a table and not an array table but whatever

    self.number_of_resources_to_deplete = 0
    self.actual_number_of_resources_depleted = 0

    self.spenders_to_refund = {}

    self.party_lucky_evade = false

    self.attack_spenders = {}

end

function Battle:postInit(state, encounter)

    super.postInit(self, state, encounter)


end

---@param tbl table
---@return table
function Battle:addMenuItem(tbl)
    -- Item colors in Ch3+ can be dynamic (e.g. pacify) so we should use functions for item color.
    -- Table colors can still be used, but we'll wrap them into functions.
    local color = tbl.color or {1, 1, 1, 1}
    local fcolor
    if type(color) == "table" then
        fcolor = function () return color end
    else
        fcolor = color
    end
    tbl = {
        ["name"] = tbl.name or "",
    ---------------------------------
        ["resource"] = tbl.resource or "tension",   --lol
        ["cost_statistic"] = tbl.cost_statistic or "none",
        ["split_cost"] = tbl.split_cost or false,
        ["tp"] = tbl.tp or 0,
        ["mp"] = tbl.mp or 0,
        ["stock"] = tbl.stock or 0,
        ["stock_limit"] = tbl.stock_limit or Game:getFlag("global_starting_stock_limit", 99),
        ["hp_cost"] = tbl.hp_cost or 0,
    ------------------------------
        ["unusable"] = tbl.unusable or false,
        ["description"] = tbl.description or "",
        ["party"] = tbl.party or {},
        ------------------------------
        ["spenders"] = tbl.spenders or {},
        ------------------------------
        ["color"] = fcolor,
        ["data"] = tbl.data or nil,
        ["callback"] = tbl.callback or function() end,
        ["highlight"] = tbl.highlight or nil,
        ["icons"] = tbl.icons or nil
    }
    table.insert(self.menu_items, tbl)
    return tbl
end

---@param key string
function Battle:onKeyPressed(key)

    if Kristal.Config["debug"] and Input.ctrl() then
  
        if key == "h" then
            for _,party in ipairs(self.party) do
                party:heal(math.huge)
                party:revive()
            end
            --self:updateSplitCost()
        end
        if key == "y" then
            Input.clear(nil, true)
            self:setState("VICTORY")
        end
        if key == "m" then
            if self.music then
                if self.music:isPlaying() then
                    self.music:pause()
                else
                    self.music:resume()
                end
            end
        end
        if self.state == "DEFENDING" and key == "f" then
            self.encounter:onWavesDone()
        end
        if self.soul and self.soul.visible and key == "j" then
            local x, y = self:getSoulLocation()
            self.soul:shatter(6)

            -- Prevents a crash related to not having a soul in some waves
            self:spawnSoul(x, y)
            for _,heartbrust in ipairs(Game.stage:getObjects(HeartBurst)) do
                heartbrust:remove()
            end
            self.soul.visible = false
            self.soul.collidable = false
        end
        if key == "b" then
            for _,battler in ipairs(self.party) do
                --[[local v = 0
                v = Utils.getFraction(battler.chara:getStat("health"), 1, 8)
                v = Utils.ceil(v)]]
                if Input.shift() then
                    battler:hurt(Utils.floor(battler.chara:getHealth() / 2)--[[v, true]])
                else
                    battler:hurt(math.huge--[[v, true]])
                end
                    
                --self:updateSplitCost()
            end
        end
        if key == "k" then
            Game:setTension(Game:getMaxTension() * 2, true)
        end
        if key == "n" then
            NOCLIP = not NOCLIP
        end
-------------------------------------------------
        if key == "p" then
            for _,battler in ipairs(self.party) do
                if battler.chara:usesMana() then
                    battler:regenMana(math.huge)
                end
            end
        end
        if key == "l" then
            for _,battler in ipairs(self.party) do
                if battler.chara:usesMana() then
                    Assets.stopAndPlaySound("PMD2_PP_Down", 0.7)
                    battler.chara:setMana(0)
                end
            end
        end
        if key == "u" then
            Game:setTension(0, true)
        end
-------------------------------------------------
    end
    
    if self.state == "MENUSELECT" then
        local menu_width = 2
        local menu_height = math.ceil(#self.menu_items / 2)

        if Input.isConfirm(key) then
            local menu_item = self.menu_items[self:getItemIndex()]
            local can_select = self:canSelectMenuItem(menu_item)
            --self:updateSplitCost()
            if self.encounter:onMenuSelect(self.state_reason, menu_item, can_select) then return end
            if Kristal.callEvent(KRISTAL_EVENT.onBattleMenuSelect, self.state_reason, menu_item, can_select) then return end
            if can_select then
                self.ui_select:stop()
                self.ui_select:play()
                menu_item["callback"](menu_item)
                return
            end
        elseif Input.isCancel(key) then
            local menu_item = self.menu_items[self:getItemIndex()]
            local can_select = self:canSelectMenuItem(menu_item)
            
            if self.encounter:onMenuCancel(self.state_reason, menu_item) then return end
            if Kristal.callEvent(KRISTAL_EVENT.onBattleMenuCancel, self.state_reason, menu_item, can_select) then return end
            self.ui_move:stop()
            self.ui_move:play()
            Game:setTensionPreview(0)
            self:setState("ACTIONSELECT", "CANCEL")
            return
        elseif Input.is("left", key) then -- TODO: pagination
            self.current_menu_x = self.current_menu_x - 1
            if self.current_menu_x < 1 then
                self.current_menu_x = menu_width
                if not self:isValidMenuLocation() then
                    self.current_menu_x = 1
                end
            end
        elseif Input.is("right", key) then
            self.current_menu_x = self.current_menu_x + 1
            if not self:isValidMenuLocation() then
                self.current_menu_x = 1
            end
        end
        if Input.is("up", key) then
            self.current_menu_y = self.current_menu_y - 1
            if self.current_menu_y < 1 then
                self.current_menu_y = 1 -- No wrapping in this menu.
            end
        elseif Input.is("down", key) then
            if self:getItemIndex() % 6 == 0 and #self.menu_items % 6 == 1 and self.current_menu_y == menu_height - 1 then
                self.current_menu_x = self.current_menu_x - 1
            end
            self.current_menu_y = self.current_menu_y + 1
            if (self.current_menu_y > menu_height) or (not self:isValidMenuLocation()) then
                self.current_menu_y = menu_height -- No wrapping in this menu.
                if not self:isValidMenuLocation() then
                    self.current_menu_y = menu_height - 1
                end
            end
        end
    elseif self.state == "ENEMYSELECT" or self.state == "XACTENEMYSELECT" then
        if Input.isConfirm(key) then
            if self.encounter:onEnemySelect(self.state_reason, self.current_menu_y) then return end
            if Kristal.callEvent(KRISTAL_EVENT.onBattleEnemySelect, self.state_reason, self.current_menu_y) then return end
            self.ui_select:stop()
            self.ui_select:play()
            if #self.enemies_index == 0 then return end
            self.selected_enemy = self.current_menu_y
            if self.state == "XACTENEMYSELECT" then
                local xaction = Utils.copy(self.selected_xaction)
                if xaction.default then
                    xaction.name = self.enemies_index[self.selected_enemy]:getXAction(self.party[self.current_selecting])
                end
                self:pushAction("XACT", self.enemies_index[self.selected_enemy], xaction)
            elseif self.state_reason == "SPARE" then
                self:pushAction("SPARE", self.enemies_index[self.selected_enemy])
            elseif self.state_reason == "ACT" then
                self:clearMenuItems()
                local enemy = self.enemies_index[self.selected_enemy]
                for _,v in ipairs(enemy.acts) do
                    local insert = not v.hidden
                    if v.character and self.party[self.current_selecting].chara.id ~= v.character then
                        insert = false
                    end
                    if v.party and (#v.party > 0) then
                        for _,party_id in ipairs(v.party) do
                            if not self:getPartyIndex(party_id) then
                                insert = false
                                break
                            end
                        end
                    end
                    if insert then
                        self:addMenuItem({
                            ["name"] = v.name,
                            ------------------------------------
                            ["resource"] = v.resource or "tension",
                            --["cost_statistic"] = v.cost_statistic or "none",
                            ["tp"] = v.tp or 0,
                            ["mp"] = v.mp or 0,
                            ["stock"] = v.stock or 0,
                            ["stock_limit"] = v.stock_limit or Game:getFlag("global_starting_stock_limit", 9),
                            ["hp_cost"] = v.hp_cost or 0,
                            --------------------------------------
                            ["description"] = v.description,
                            ["party"] = v.party,
                            ["spenders"] = v.spenders,
                            ["split_cost"] = v.split_cost,
                            ["color"] = v.color or {1, 1, 1, 1},
                            ["highlight"] = v.highlight or enemy,
                            ["icons"] = v.icons,
                            ["callback"] = function(menu_item)
                                self:pushAction("ACT", enemy, menu_item)
                            end
                        })
                    end
                end
                self:setState("MENUSELECT", "ACT")
----------------------------------------------------------------------------------------------------------------
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////
            elseif self.state_reason == "DRAW" then
                self:clearMenuItems()
                local current_enemy = self.enemies_index[self.selected_enemy]
                local battler = Game.battle.party[Game.battle.current_selecting]

                for _,spell in ipairs(current_enemy:getEnemySpells()) do
                    ---@type table|function
                    local color = spell.color or {1, 1, 1, 1}
                    if spell:hasTag("spare_tired") then
                        local has_tired = false
                        for _,enemy in ipairs(Game.battle:getActiveEnemies()) do
                            if enemy.tired then
                                has_tired = true
                                break
                            end
                        end
                        if has_tired then
                            color = {0, 178/255, 1, 1}
                            if Game:getConfig("pacifyGlow") then
                                color = function ()
                                    return Utils.mergeColor({0, 0.7, 1, 1}, COLORS.white, 0.5 + math.sin(Game.battle.pacify_glow_timer / 4) * 0.5)
                                end
                            end
                        end
                    end
                    Game.battle:addMenuItem({
                        ["name"] = spell:getName(),
                        ["spell_name"] = spell:getName(),
                        ["resource"] = "stock_show",
                        ["stock"] = spell:getStock(battler.chara),
                        ["stock_limit"] = spell:getStockLimit(battler.chara) or spell:getStartingStockLimit(),
                        ["unusable"] = --[[not spell:isUsable(battler.chara) and]] not spell:canDrawCast() and not spell:canStock(),
                        ["description"] = spell:getBattleDescription(),
                        ["party"] = spell.party,
                        ["color"] = color,
                        ["highlight"] = current_enemy,
                        ["data"] = spell,
                        --[[["callback"] = function(menu_item)
                            --Game.battle.selected_spell = menu_item
                            --This continues within the mod.lua
                        end]]
                    })
                --battler.chara:setSpellStockData(spell, -1, -1)
                end
                Game.battle:setState("MENUSELECT", "DRAWSPELL")
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
----------------------------------------------------------------------------------------------------------------
            elseif self.state_reason == "ATTACK" then
                self:pushAction("ATTACK", self.enemies_index[self.selected_enemy])
            elseif self.state_reason == "SPELL" then
                self:pushAction("SPELL", self.enemies_index[self.selected_enemy], self.selected_spell)
            elseif self.state_reason == "ITEM" then
                self:pushAction("ITEM", self.enemies_index[self.selected_enemy], self.selected_item)
            else
                self:nextParty()
            end
            return
        end
        if Input.isCancel(key) then
            if self.encounter:onEnemyCancel(self.state_reason, self.current_menu_y) then return end
            if Kristal.callEvent(KRISTAL_EVENT.onBattleEnemyCancel, self.state_reason, self.current_menu_y) then return end
            self.ui_move:stop()
            self.ui_move:play()
            if self.state_reason == "SPELL" then
                self:setState("MENUSELECT", "SPELL")
            elseif self.state_reason == "ITEM" then
                self:setState("MENUSELECT", "ITEM")
            else
                self:setState("ACTIONSELECT", "CANCEL")
            end
            return
        end
        if Input.is("up", key) then
            if #self.enemies_index == 0 then return end
            local old_location = self.current_menu_y
            local give_up = 0
            repeat
                give_up = give_up + 1
                if give_up > 100 then return end
                -- Keep decrementing until there's a selectable enemy.
                self.current_menu_y = self.current_menu_y - 1
                if self.current_menu_y < 1 then
                    self.current_menu_y = #self.enemies_index
                end
            until (self.enemies_index[self.current_menu_y] and self.enemies_index[self.current_menu_y].selectable)

            if self.current_menu_y ~= old_location then
                self.ui_move:stop()
                self.ui_move:play()
            end
        elseif Input.is("down", key) then
            if #self.enemies_index == 0 then return end
            local old_location = self.current_menu_y
            local give_up = 0
            repeat
                give_up = give_up + 1
                if give_up > 100 then return end
                -- Keep decrementing until there's a selectable enemy.
                self.current_menu_y = self.current_menu_y + 1
                if self.current_menu_y > #self.enemies_index then
                    self.current_menu_y = 1
                end
            until (self.enemies_index[self.current_menu_y] and self.enemies_index[self.current_menu_y].selectable)

            if self.current_menu_y ~= old_location then
                self.ui_move:stop()
                self.ui_move:play()
            end
        end
    elseif self.state == "PARTYSELECT" then
        if Input.isConfirm(key) then
            if self.encounter:onPartySelect(self.state_reason, self.current_menu_y) then return end
            if Kristal.callEvent(KRISTAL_EVENT.onBattlePartySelect, self.state_reason, self.current_menu_y) then return end
            self.ui_select:stop()
            self.ui_select:play()
            if self.state_reason == "SPELL" then
                self:pushAction("SPELL", self.party[self.current_menu_y], self.selected_spell)
            elseif self.state_reason == "ITEM" then
                self:pushAction("ITEM", self.party[self.current_menu_y], self.selected_item)
            else
                self:nextParty()
            end
            return
        end
        if Input.isCancel(key) then
            if self.encounter:onPartyCancel(self.state_reason, self.current_menu_y) then return end
            if Kristal.callEvent(KRISTAL_EVENT.onBattlePartyCancel, self.state_reason, self.current_menu_y) then return end
            self.ui_move:stop()
            self.ui_move:play()
            if self.state_reason == "SPELL" then
                self:setState("MENUSELECT", "SPELL")
            elseif self.state_reason == "ITEM" then
                self:setState("MENUSELECT", "ITEM")
            else
                self:setState("ACTIONSELECT", "CANCEL")
            end
            return
        end
        if Input.is("up", key) then
            self.ui_move:stop()
            self.ui_move:play()
            self.current_menu_y = self.current_menu_y - 1
            if self.current_menu_y < 1 then
                self.current_menu_y = #self.party
            end
        elseif Input.is("down", key) then
            self.ui_move:stop()
            self.ui_move:play()
            self.current_menu_y = self.current_menu_y + 1
            if self.current_menu_y > #self.party then
                self.current_menu_y = 1
            end
        end
    elseif self.state == "BATTLETEXT" then
        -- Nothing here
    elseif self.state == "SHORTACTTEXT" then
        -- Nothing here
    elseif self.state == "ENEMYDIALOGUE" then
        -- Nothing here
    elseif self.state == "ACTIONSELECT" then
        self:handleActionSelectInput(key)
    elseif self.state == "ATTACKING" then
        self:handleAttackingInput(key)
    end
end

function Battle:commitAction(battler, action_type, target, data, extra)
    data = data or {}
    extra = extra or {}

    local is_xact = action_type:upper() == "XACT"
    if is_xact then
        action_type = "ACT"
    end

    local tp_diff = 0
    local mp_diff = 0
    --local stock_diff = 0
    local hp_diff = 0
    if data.tp then
        tp_diff = Utils.clamp(-data.tp, -Game:getTension(), Game:getMaxTension() - Game:getTension())
    end
    if data.mp then
        --mp_diff = Utils.clamp(-data.mp, -battler.chara:getMana(), battler.chara:getStat("mana") - battler.chara:getMana())
    end
    --if data.stock then
        --stock_diff = Utils.clamp(-data.stock, -battler.chara:getMana(), battler.chara:getStat("mana") - battler.chara:getMana())
    --end
    if data.hp_cost then
        hp_diff = Utils.clamp(-data.hp_cost, -battler.chara:getHealth(), battler.chara:getStat("health") - battler.chara:getHealth())
    end

    local party_id = self:getPartyIndex(battler.chara.id)
    local party_to_add = {}
    local party_list_empty = true

    if data.spenders then
        for _,s in ipairs(data.spenders) do
            local exists = false

            for _,p in ipairs(data.party) do
                party_list_empty = false
                if p == s then
                    exists = true
                    break
                end
            end
            if not exists then
                table.insert(party_to_add, s)
            end
        end
    end

    if party_list_empty then
        --print("lllooolll")
    end

    for _,p in ipairs(party_to_add) do
        --print("pppp  " ..p)
        local index = self:getPartyIndex(p)
        --print(index)
        if  index ~= nil then
            --print("IMA FIRING MY LAZERR")
            data["party"] = p
            table.insert(self.spenders_to_refund, p)
        end
    end

    ---for _,p in ipairs(data.party) do
        
    ---end

    -- Dont commit action for an inactive party member
    if not battler:isActive() then return end

    -- Make sure this action doesn't cancel any uncancellable actions
    if data.party then
        for _,v in ipairs(data.party) do
            --print("vvvvvv" .. v)
            local index = self:getPartyIndex(v)

            if index ~= party_id then
                local action = self.character_actions[index]
                if action then
                    if action.cancellable == false then
                        return
                    end
                    if action.act_parent then
                        local parent_action = self.character_actions[action.act_parent]
                        if parent_action.cancellable == false then
                            return
                        end
                    end
                end
            end
        end
    end

    --[[if data.spenders then
        local spender_id = self:getPartyIndex(battler.chara.id)
        for _,v in ipairs(data.spenders) do
            local index = self:getPartyIndex(v)

            if index ~= spender_id then
                local action = self.character_actions[index]
                if action then
                    if action.cancellable == false then
                        return
                    end
                    if action.act_parent then
                        local parent_action = self.character_actions[action.act_parent]
                        if parent_action.cancellable == false then
                            return
                        end
                    end
                end
            end
        end
    end]]

    self:commitSingleAction(Utils.merge({
        ["character_id"] = party_id,
        ["action"] = action_type:upper(),
        ["party"] = data.party,
        ["spenders"] = data.spenders,
        ["name"] = data.name,
        ["resource"] = data.resource,
        ["target"] = target,
        ["data"] = data.data,
        ["split_cost"] = data.split_cost,
        ["tp"] = tp_diff,
        ["mp"] = data.mp,
        ["stock"] = data.stock,
        ["hp_cost"] = hp_diff,
        ["cancellable"] = data.cancellable,
    }, extra))

    if data.party then
        for _,v in ipairs(data.party) do
            local index = self:getPartyIndex(v)

            if index ~= party_id then
                local action = self.character_actions[index]
                if action then
                    if action.act_parent then
                        self:removeAction(action.act_parent)
                    else
                        self:removeAction(index)
                    end
                end

                self:commitSingleAction(Utils.merge({
                    ["character_id"] = index,
                    ["action"] = "SKIP",
                    ["reason"] = action_type:upper(),
                    ["name"] = data.name,
                    ["target"] = target,
                    ["data"] = data.data,
                    ["act_parent"] = party_id,
                    ["cancellable"] = data.cancellable,
                }, extra))
            end
        end
    end

    --[[if data.spenders then
        local spender_id = self:getPartyIndex(battler.chara.id)
        for _,v in ipairs(data.spenders) do
            local index = self:getPartyIndex(v)

            if index ~= spender_id then
                local action = self.character_actions[index]
                if action then
                    if action.act_parent then
                        self:removeAction(action.act_parent)
                    else
                        self:removeAction(index)
                    end
                end

                self:commitSingleAction(Utils.merge({
                    ["character_id"] = index,
                    ["action"] = "SKIP",
                    ["reason"] = action_type:upper(),
                    ["name"] = data.name,
                    ["target"] = target,
                    ["data"] = data.data,
                    ["act_parent"] = spender_id,
                    ["cancellable"] = data.cancellable,
                }, extra))
            end
        end
    end]]

end

function Battle:processAction(action)
    local battler = self.party[action.character_id]
    local party_member = battler.chara
    local enemy = action.target

    self.current_processing_action = action

    local next_enemy = self:retargetEnemy()
    if not next_enemy then
        return true
    end

    if enemy and enemy.done_state then
        enemy = next_enemy
        action.target = next_enemy
    end

    -- Call mod callbacks for onBattleAction to either add new behaviour for an action or override existing behaviour
    -- Note: non-immediate actions require explicit "return false"!
    local callback_result = Kristal.modCall("onBattleAction", action, action.action, battler, enemy)
    if callback_result ~= nil then
        return callback_result
    end
    for lib_id,_ in Kristal.iterLibraries() do
        callback_result = Kristal.libCall(lib_id, "onBattleAction", action, action.action, battler, enemy)
        if callback_result ~= nil then
            return callback_result
        end
    end

    if action.action == "SPARE" then
        local worked = enemy:canSpare()

        battler:setAnimation("battle/spare", function()
            enemy:onMercy(battler)
            if not worked then
                enemy:mercyFlash()
            end
            self:finishAction(action)
        end)

        local text = enemy:getSpareText(battler, worked)
        if text then
            self:battleText(text)
        end

        return false

    elseif action.action == "ATTACK" or action.action == "AUTOATTACK" then
        local attacksound = battler.chara:getWeapon():getAttackSound(battler, enemy, action.points) or battler.chara:getAttackSound()
        local attackpitch  = battler.chara:getWeapon():getAttackPitch(battler, enemy, action.points) or battler.chara:getAttackPitch()
        local src = Assets.stopAndPlaySound(attacksound or "laz_c")
        src:setPitch(attackpitch or 1)

        self.actions_done_timer = 1.2

        local crit = action.points == 150 and action.action ~= "AUTOATTACK"
        if crit then
            Assets.stopAndPlaySound("criticalswing")

            for i = 1, 3 do
                local sx, sy = battler:getRelativePos(battler.width, 0)
                local sparkle = Sprite("effects/criticalswing/sparkle", sx + Utils.random(50), sy + 30 + Utils.random(30))
                sparkle:play(4/30, true)
                sparkle:setScale(2)
                sparkle.layer = BATTLE_LAYERS["above_battlers"]
                sparkle.physics.speed_x = Utils.random(2, 6)
                sparkle.physics.friction = -0.25
                sparkle:fadeOutSpeedAndRemove()
                self:addChild(sparkle)
            end
        end

        battler:setAnimation("battle/attack", function()
            action.icon = nil

            if action.target and action.target.done_state then
                enemy = self:retargetEnemy()
                action.target = enemy
                if not enemy then
                    self.cancel_attack = true
                    self:finishAction(action)
                    return
                end
            end

            print(battler.chara:getPassive():getAttackDamageMod(battler))
            local damage = Utils.round((enemy:getAttackDamage(action.damage or 0, battler, action.points or 0)) * battler.chara:getPassive():getAttackDamageMod(battler))
            if damage < 0 then
                damage = 0
            end

            if damage > 0 then
                Game:giveTension(Utils.round(enemy:getAttackTension(action.points or 100)))

                local attacksprite = battler.chara:getWeapon():getAttackSprite(battler, enemy, action.points) or battler.chara:getAttackSprite()
                local dmg_sprite = Sprite(attacksprite or "effects/attack/cut")
                dmg_sprite:setOrigin(0.5, 0.5)
                if crit then
                    dmg_sprite:setScale(2.5, 2.5)
                else
                    dmg_sprite:setScale(2, 2)
                end
                local relative_pos_x, relative_pos_y = enemy:getRelativePos(enemy.width/2, enemy.height/2)
                dmg_sprite:setPosition(relative_pos_x + enemy.dmg_sprite_offset[1], relative_pos_y + enemy.dmg_sprite_offset[2])
                dmg_sprite.layer = enemy.layer + 0.01
                dmg_sprite.battler_id = action.character_id or nil
                table.insert(enemy.dmg_sprites, dmg_sprite)
                local dmg_anim_speed = 1/15
                if attacksprite == "effects/attack/shard" then
                    -- Ugly hardcoding BlackShard animation speed accuracy for now
                    dmg_anim_speed = 1/10
                end
                dmg_sprite:play(dmg_anim_speed, false, function(s) s:remove(); Utils.removeFromTable(enemy.dmg_sprites, dmg_sprite) end) -- Remove itself and Remove the dmg_sprite from the enemy's dmg_sprite table when its removed
                enemy.parent:addChild(dmg_sprite)

                local sound = enemy:getDamageSound() or "damage"
                if sound and type(sound) == "string" then
                    Assets.stopAndPlaySound(sound)
                end
                enemy:hurt(damage, battler)

                -- TODO: Call this even if damage is 0, will be a breaking change
                battler.chara:onAttackHit(enemy, damage)
            else
                enemy:hurt(0, battler, nil, nil, nil, action.points ~= 0)
            end

            for _,item in ipairs(battler.chara:getEquipment()) do
                item:onAttackHit(battler, enemy, damage)
            end

            self:finishAction(action)

            Utils.removeFromTable(self.normal_attackers, battler)
            Utils.removeFromTable(self.auto_attackers, battler)

            if not self:retargetEnemy() then
                self.cancel_attack = true
            elseif #self.normal_attackers == 0 and #self.auto_attackers > 0 then
                local next_attacker = self.auto_attackers[1]

                local next_action = self:getActionBy(next_attacker, true)
                if next_action then
                    self:beginAction(next_action)
                    self:processAction(next_action)
                end
            end
        end)

        return false

    elseif action.action == "ACT" then
        -- fun fact: this would have only been a single function call
        -- if stupid multi-acts didn't exist

        -- Check for other short acts
        local self_short = false
        self.short_actions = {}
        for _,iaction in ipairs(self.current_actions) do
            if iaction.action == "ACT" then
                local ibattler = self.party[iaction.character_id]
                local ienemy = iaction.target

                if ienemy then
                    local act = ienemy and ienemy:getAct(iaction.name)

                    if (act and act.short) or (ienemy:getXAction(ibattler) == iaction.name and ienemy:isXActionShort(ibattler)) then
                        table.insert(self.short_actions, iaction)
                        if ibattler == battler then
                            self_short = true
                        end
                    end
                end
            end
        end

        if self_short and #self.short_actions > 1 then
            local short_text = {}
            for _,iaction in ipairs(self.short_actions) do
                local ibattler = self.party[iaction.character_id]
                local ienemy = iaction.target

                local act_text = ienemy:onShortAct(ibattler, iaction.name)
                if act_text then
                    table.insert(short_text, act_text)
                end
            end

            self:shortActText(short_text)
        else
            local text = enemy:onAct(battler, action.name)
            if text then
                self:setActText(text)
            end
        end

        return false

    elseif action.action == "SKIP" then
        return true

    elseif action.action == "SPELL" then
        self.battle_ui:clearEncounterText()

------------------------------------------------------
        --print(action.name)
        local spell_name = action.name
        --print(action.resource)
        if string.find(spell_name, "Cast") then
            self.draw_cast = true
            --print(self.draw_cast)
        end
------------------------------------------------------

        -- The spell itself handles the animation and finishing
        --for i = 1, action.data.cast_count do
            --print(i)
            action.data:onStart(battler, action.target)

        --end
        return false

    elseif action.action == "ITEM" then
        local item = action.data
        if item.instant then
            self:finishAction(action)
        else
            local text = item:getBattleText(battler, action.target)
            if text then
                self:battleText(text)
            end
            battler:setAnimation("battle/item", function()
                local result = item:onBattleUse(battler, action.target)
                if result or result == nil then
                    self:finishAction(action)
                end
            end)
        end
        return false

    elseif action.action == "DEFEND" then
        battler:setAnimation("battle/defend")
        battler.defending = true
        return false

--------------------------------------------------------------
    elseif action.action == "STOCK" then

        --data in mod.lua

        return false
    --end
--------------------------------------------------------------
    else
        -- we don't know how to handle this...
        Kristal.Console:warn("Unhandled battle action: " .. tostring(action.action))
        return true
    end
end

function Battle:processCharacterActions()
    if self.state ~= "ACTIONS" then
        self:setState("ACTIONS", "DONTPROCESS")
    end

    self.current_action_index = 1

    local order = {"ACT", {"STOCK", "SPELL", "ITEM", "SPARE"}}

    for lib_id,_ in Kristal.iterLibraries() do
        order = Kristal.libCall(lib_id, "getActionOrder", order, self.encounter) or order
    end
    order = Kristal.modCall("getActionOrder", order, self.encounter) or order

    -- Always process SKIP actions at the end
    table.insert(order, "SKIP")

    for _,action_group in ipairs(order) do
        if self:processActionGroup(action_group) then
            self:tryProcessNextAction()
            return
        end
    end

    self:setSubState("NONE")
    self:setState("ATTACKING")
    --[[self.timer:after(4 / 30, function()
        self:setState("ENEMYDIALOGUE")
    end)]]
    --self:setState("ACTIONSELECT")
end

function Battle:update()

    --self:updateSplitCost()

    for _,enemy in ipairs(self.enemies_to_remove) do
        Utils.removeFromTable(self.enemies, enemy)
        local enemy_y = Utils.getKey(self.enemies_index, enemy)
        if enemy_y then
            self.enemies_index[enemy_y] = false
        end
    end
    self.enemies_to_remove = {}

    if self.cutscene then
        if not self.cutscene.ended then
            self.cutscene:update()
        else
            self.cutscene = nil
        end
    end
    if Game.battle == nil then return end -- cutscene ended the battle

    if self.state == "TRANSITION" then
        self:updateTransition()
    elseif self.state == "INTRO" then
        self:updateIntro()
    elseif self.state == "ATTACKING" then
        self:updateAttacking()
    elseif self.state == "ACTIONSDONE" then
        self.actions_done_timer = Utils.approach(self.actions_done_timer, 0, DT)
        local any_hurt = false
        for _,enemy in ipairs(self.enemies) do
            if enemy.hurt_timer > 0 then
                any_hurt = true
                break
            end
        end
        if self.actions_done_timer == 0 and not any_hurt then
            self:resetAttackers()
            if not self.encounter:onActionsEnd() then
                self:setState("ENEMYDIALOGUE")
            end
        end
    elseif self.state == "DEFENDINGBEGIN" then
        self.defending_begin_timer = self.defending_begin_timer + DTMULT
        if self.defending_begin_timer >= 15 then
            self:setState("DEFENDING")
        end
    elseif self.state == "DEFENDING" then
        self:updateWaves()
    elseif self.state == "ENEMYDIALOGUE" then
        self.textbox_timer = self.textbox_timer - DTMULT
        if (self.textbox_timer <= 0) and self.use_textbox_timer then
            self:advanceBoxes()
        else
            local all_done = true
            for _,textbox in ipairs(self.enemy_dialogue) do
                if not textbox:isDone() then
                    all_done = false
                    break
                end
            end
            if all_done then
                self:setState("DIALOGUEEND")
            end
        end
    elseif self.state == "SHORTACTTEXT" then
        self:updateShortActText()
    end

    if self.state ~= "TRANSITIONOUT" then
        self.encounter:update()
    end
    
    -- prevents the bolts afterimage from continuing till the edge of the screen when all the enemies are defeated but there're still unfinished attacks
    if self.state ~= "ATTACKING" then
        for _,attack in ipairs(self.battle_ui.attack_boxes) do
            if not attack.attacked and attack:getClose() <= -2 then
                attack:miss()
            end
        end
    end

    self.offset = self.offset + 1 * DTMULT

    if self.offset > 100 then
        self.offset = self.offset - 100
    end

    self.pacify_glow_timer = self.pacify_glow_timer + DTMULT

    if (self.state == "ENEMYDIALOGUE") or (self.state == "DEFENDINGBEGIN") or (self.state == "DEFENDING") then
        self.background_fade_alpha = math.min(self.background_fade_alpha + (0.05 * DTMULT), 0.75)
        if not self.darkify then
            self.darkify = true
            for _,battler in ipairs(self.party) do
                battler.should_darken = true
            end
        end
    end

    if Utils.containsValue({"DEFENDINGEND", "ACTIONSELECT", "ACTIONS", "VICTORY", "TRANSITIONOUT", "BATTLETEXT"}, self.state) then
        self.background_fade_alpha = math.max(self.background_fade_alpha - (0.05 * DTMULT), 0)
        if self.darkify then
            self.darkify = false
            for _,battler in ipairs(self.party) do
                battler.should_darken = false
            end
        end
    end

    -- Always sort
    --self.update_child_list = true
    super.super.update(self)

    if self.state == "TRANSITIONOUT" then
        self:updateTransitionOut()
    end
end

--- Hurts the `target` party member(s)
---@param amount        number
---@param exact?        boolean
---@param target?       number|"ALL"|"ANY"|PartyBattler The target battler's index, instance, or strings for specific selection logic (defaults to `"ANY"`)
---@param magic_damage? boolean Whether the damage taken will use the spirit stat to negate damage instead of the defense stats
---@param element?      string The element to make damagae calculations with (if any)
---@return table?
function Battle:hurt(amount, exact, target, magic_damage, element)
    -- If target is a numberic value, it will hurt the party battler with that index
    -- "ANY" will choose the target randomly
    -- "ALL" will hurt the entire party all at once
    target = target or "ANY"

    -- Alright, first let's try to adjust targets.

    if type(target) == "number" then
        target = self.party[target]
    end

    if isClass(target) and target:includes(PartyBattler) then
        if (not target) or (target.chara:getHealth() <= 0) then -- Why doesn't this look at :canTarget()? Weird.
            target = self:randomTargetOld()
        end
    end

    if target == "ANY" --[[or self.multi_resource_depletion_target_is_any]] then
        target = self:randomTargetOld()

        -- Calculate the average HP of the party.
        -- This is "scr_party_hpaverage", which gets called multiple times in the original script.
        -- We'll only do it once here, just for the slight optimization. This won't affect accuracy.

        -- Speaking of accuracy, this function doesn't work at all!
        -- It contains a bug which causes it to always return 0, unless all party members are at full health.
        -- This is because of a random floor() call.
        -- I won't bother making the code accurate; all that matters is the output.

        local party_average_hp = 1

        for _,battler in ipairs(self.party) do
            if battler.chara:getHealth() ~= battler.chara:getStat("health") then
                party_average_hp = 0
                break
            end
        end

        -- Retarget... twice.
        if target.chara:getHealth() / target.chara:getStat("health") < (party_average_hp / 2) then
            target = self:randomTargetOld()
        end
        if target.chara:getHealth() / target.chara:getStat("health") < (party_average_hp / 2) then
            target = self:randomTargetOld()
        end

        -- If we landed on Kris (or, well, the first party member), and their health is low, retarget (plot armor lol)
        if (target == self.party[1]) and ((target.chara:getHealth() / target.chara:getStat("health")) < 0.35) then
            target = self:randomTargetOld()
        end

        -- They got hit, so un-darken them
        target.should_darken = false
        target.targeted = true
    end

    -- Now it's time to actually damage them!
    if isClass(target) and target:includes(PartyBattler) then
        --print(tostring(magic_damage) .. "bababoy")
        if magic_damage then
            --print("awow wa")
            target:hurt(amount, exact, nil, element, {magic_damage = true})
        else
            target:hurt(amount, exact, nil, element)
        end
        return {target}
    end

    if target == "ALL" then
        if magic_damage then
            Assets.playSound("spellcast", 0.7)
        else
            Assets.playSound("hurt")
        end

        local alive_battlers = Utils.filter(self.party, function(battler) return not battler.is_down end)
        for _,battler in ipairs(alive_battlers) do
            if magic_damage then
                battler:hurt(amount, exact, nil, element, {all = true, magic_damage = true})
            else
                battler:hurt(amount, exact, nil, element, {all = true})
            end
        end
        -- Return the battlers who aren't down, aka the ones we hit.
        return alive_battlers
    end
end

--- Depletes the `target` party member(')s(') mana (clone of Battle:hurt)
---@param amount    number
---@param exact?    boolean
---@param target?   number|"ALL"|"ANY"|PartyBattler The target battler's index, instance, or strings for specific selection logic (defaults to `"ANY"`)
---@param magic_damage? boolean Whether the damage taken will use the spirit stat to negate damage instead of the defense stat
---@param element?      string The element to make damagae calculations with (if any)
---@return table?
function Battle:depleteMana(amount, exact, target, magic_damage, element)
    -- If target is a numberic value, it will deplete the party battler with that index
    -- "ANY" will choose the target randomly
    -- "ALL" will hurt the entire party all at once
    --print(target.chara.id)
    target = target or "ANY"

    -- Alright, first let's try to adjust targets.

    if type(target) == "number" then
        target = self.party[target]
    end

    if isClass(target) and target:includes(PartyBattler) then
        if (not target) --[[or (target.chara:getMana() <= 0)]] --[[(not target.chara:usesMana())]] then -- Why doesn't this look at :canTarget()? Weird. (hmm)
            target = self:randomTargetOld()
        end
    end

    if target == "ANY" --[[or self.multi_resource_depletion_target_is_any ]]then
        target = self:randomTargetOld()

        --No plot armor for mana depletion >:)

        -- They got hit, so un-darken them
        target.should_darken = false
        target.targeted = true
    end

    -- Now it's time to actually damage them!
    if isClass(target) and target:includes(PartyBattler) then
        if magic_damage then
            print("WAZAOWSKI!")
            target:depleteMana(amount, exact, nil, element, {magic_damage = true})
        else
            target:depleteMana(amount, exact, nil, element)
        end
        return {target}
    end

    if target == "ALL" then
        if magic_damage then
            Assets.playSound("spellcast", 0.7)
        end
        Assets.playSound("PMD2_PP_Down", 0.7)
        local alive_battlers = Utils.filter(self.party, function(battler) return not battler.is_down end)
        for _,battler in ipairs(alive_battlers) do
            if magic_damage then
                battler:depleteMana(amount, exact, nil, element, {all = true, magic_damage = true})
            else
                battler:depleteMana(amount, exact, nil, element, {all = true})
            end
        end
        -- Return the battlers who aren't down, aka the ones we hit.
        return alive_battlers
    end
end


--Depletes multiple resources at a time.
---@param resources     string[]
---@param amount        number|table<table>
---@param exact?        boolean
---@param target?       number|"ALL"|"ANY"|PartyBattler The target battler's index, instance, or strings for specific selection logic (defaults to `"ANY"`)
---@param magic_damage? boolean Whether to calculate using the spirit stat. (if `amount` is NOT a table, ALL resources will use either the defense or spirit stat for the calculations)
---@param statuses?     string[] The status conditions to inflict (if any).
---@param element?      string    The element to make calculations with
function Battle:depleteResources(resources, amount, exact, target, magic_damage, statuses, element)
    --self.number_of_resources_to_deplete = 0
    --self.actual_number_of_resources_depleted = 0
    --print(target)
    local health_amount      = nil
    local mana_amount        = nil
    local tension_amount     = nil

    local health_magic_damage    = false
    local mana_magic_damage      = false
    local tension_magic_damage   = false

    if type(amount) == "table" then
        for _,v in ipairs(amount) do
            print(v.value)
            if v.resource == "health" then
                health_amount = v.value
                health_magic_damage  = v.magicDamage
            elseif v.resource == "mana" then
                mana_amount = v.value
                mana_magic_damage  = v.magicDamage
            elseif v.resource == "tension" then
                tension_amount = v.value
                tension_magic_damage = v.magicDamage
            end
        end
    end

    if magic_damage then
        health_magic_damage    = true
        mana_magic_damage      = true
        tension_magic_damage   = true
    end

    if target == "ANY" --[[or self.multi_resource_depletion_target_is_any]] then
        target = self:randomTargetOld()

        -- Calculate the average HP of the party.
        -- This is "scr_party_hpaverage", which gets called multiple times in the original script.
        -- We'll only do it once here, just for the slight optimization. This won't affect accuracy.

        -- Speaking of accuracy, this function doesn't work at all!
        -- It contains a bug which causes it to always return 0, unless all party members are at full health.
        -- This is because of a random floor() call.
        -- I won't bother making the code accurate; all that matters is the output.

        local party_average_hp = 1

        for _,battler in ipairs(self.party) do
            if battler.chara:getHealth() ~= battler.chara:getStat("health") then
                party_average_hp = 0
                break
            end
        end

        -- Retarget... twice.
        if target.chara:getHealth() / target.chara:getStat("health") < (party_average_hp / 2) then
            target = self:randomTargetOld()
        end
        if target.chara:getHealth() / target.chara:getStat("health") < (party_average_hp / 2) then
            target = self:randomTargetOld()
        end

        -- If we landed on Kris (or, well, the first party member), and their health is low, retarget (plot armor lol)
        if (target == self.party[1]) and ((target.chara:getHealth() / target.chara:getStat("health")) < 0.35) then
            target = self:randomTargetOld()
        end

        -- They got hit, so un-darken them
        target.should_darken = false
        target.targeted = true
    end

    for _,r in ipairs(resources) do

        if r == "tension" then
            if Game:getTension() > 0 then
                Assets.playSound("awkward", 0.5)
                Game:removeTension(tension_amount or amount)
                --self.actual_number_of_resources_depleted = self.actual_number_of_resources_depleted + 1       exempted?
                if isClass(target) and target:includes(PartyBattler) then
                    --target:statusMessage("damage", -amount, PALETTE["tension_fill"], true)
                    target:playHurtAnim()
                    return {target}
                end
                if target == "ALL" then
                    Assets.playSound("awkward")
                    local alive_battlers = Utils.filter(self.party, function(battler) return not battler.is_down end)
                    --for _,battler in ipairs(alive_battlers) do
                    local battler = alive_battlers[1]
                        --battler:statusMessage("damage", -amount, PALETTE["tension_fill"], true)
                        battler:playHurtAnim()
                        --battler:statusMessage("damage", -amount, PALETTE["tension_fill"], true)
                    --end
                    -- Return the battlers who aren't down, aka the ones we hit.
                    return alive_battlers
                end
            end
        elseif r == "health" then
            if health_magic_damage then
                self:hurt(health_amount or amount, exact, target, true, element)
            else
                self:hurt(health_amount or amount, exact, target, false, element)
            end
        elseif r == "mana" then
            if mana_magic_damage then
                self:depleteMana(mana_amount or amount, exact, target, true, element)
            else
                self:depleteMana(mana_amount or amount, exact, target, false, element)
            end
        end
    end

    if statuses then
        self:inflictStatuses(statuses, target)
    end

    local alive_battlers = Utils.filter(self.party, function(battler) return not battler.is_down end)
    for _,battler in ipairs(alive_battlers) do
        print(battler.chara:getName())
    end
    --print("# of resources to deplete: " .. self.number_of_resources_to_deplete)
    --print("# of resources actually depleted: " .. self.actual_number_of_resources_depleted)
    self.number_of_resources_to_deplete = 0
    self.actual_number_of_resources_depleted = 0
    return alive_battlers
end

--(Proposed compatability feature with "StatusCORE")
--Inflicts a table string of statuses
---@param statuses string[] the names of the statuses to inflict
---@param target  number|"ALL"|"ANY"|PartyBattler The target battler's index, instance, or strings for specific selection logic (defaults to `"ANY"`)
---@return table?
function Battle:inflictStatuses(statuses, target)

    if target == "ANY" --[[or self.multi_resource_depletion_target_is_any]] then
        target = self:randomTargetOld()

        -- Calculate the average HP of the party.
        -- This is "scr_party_hpaverage", which gets called multiple times in the original script.
        -- We'll only do it once here, just for the slight optimization. This won't affect accuracy.

        -- Speaking of accuracy, this function doesn't work at all!
        -- It contains a bug which causes it to always return 0, unless all party members are at full health.
        -- This is because of a random floor() call.
        -- I won't bother making the code accurate; all that matters is the output.

        local party_average_hp = 1

        for _,battler in ipairs(self.party) do
            if battler.chara:getHealth() ~= battler.chara:getStat("health") then
                party_average_hp = 0
                break
            end
        end

        -- Retarget... twice.
        if target.chara:getHealth() / target.chara:getStat("health") < (party_average_hp / 2) then
            target = self:randomTargetOld()
        end
        if target.chara:getHealth() / target.chara:getStat("health") < (party_average_hp / 2) then
            target = self:randomTargetOld()
        end

        -- If we landed on Kris (or, well, the first party member), and their health is low, retarget (plot armor lol)
        if (target == self.party[1]) and ((target.chara:getHealth() / target.chara:getStat("health")) < 0.35) then
            target = self:randomTargetOld()
        end

        -- They got hit, so un-darken them
        target.should_darken = false
        target.targeted = true
    end

    target = target or "ANY"

    -- Alright, first let's try to adjust targets.

    if type(target) == "number" then
        target = self.party[target]
    end

    if isClass(target) and target:includes(PartyBattler) then
        if (not target) --[[or (target.chara:getMana() <= 0)]] --[[(not target.chara:usesMana())]] then -- Why doesn't this look at :canTarget()? Weird. (hmm)
            target = self:randomTargetOld()
        end
    end

    if target == "ANY" --[[or self.multi_resource_depletion_target_is_any ]]then
        target = self:randomTargetOld()

        -- They got hit, so un-darken them
        --target.should_darken = false
        --target.targeted = true
    end

    -- Now it's time to actually damage them!
    if isClass(target) and target:includes(PartyBattler) then
        --Assets.playSound("ttyd_lucky", 0.8)
        --target:statusMessage("msg", "lucky", color, true)
        for _,status in ipairs(statuses) do
            print("thats a peepo")
            target:inflictStatus(status)
        end
        return {target}
    end

    if target == "ALL" then

        --Assets.playSound("ttyd_lucky", 0.8)
        local alive_battlers = Utils.filter(self.party, function(battler) return not battler.is_down end)
        for _,battler in ipairs(alive_battlers) do
            --battler:statusMessage("msg", "lucky", color, true)
            for _,status in ipairs(statuses) do
                battler:inflictStatus(status)
            end
        end
        -- Return the battlers who aren't down, aka the ones we hit.
        return alive_battlers
    end

end

---What happens when a party member evades a hit.
---@param target number|"ALL"|"ANY"|PartyBattler The target battler's index, instance, or strings for specific selection logic (defaults to `"ANY"`)
---@return table?
function Battle:luckyEvade(target)

    if target == "ANY" --[[or self.multi_resource_depletion_target_is_any]] then
        target = self:randomTargetOld()

        -- Calculate the average HP of the party.
        -- This is "scr_party_hpaverage", which gets called multiple times in the original script.
        -- We'll only do it once here, just for the slight optimization. This won't affect accuracy.

        -- Speaking of accuracy, this function doesn't work at all!
        -- It contains a bug which causes it to always return 0, unless all party members are at full health.
        -- This is because of a random floor() call.
        -- I won't bother making the code accurate; all that matters is the output.

        local party_average_hp = 1

        for _,battler in ipairs(self.party) do
            if battler.chara:getHealth() ~= battler.chara:getStat("health") then
                party_average_hp = 0
                break
            end
        end

        -- Retarget... twice.
        if target.chara:getHealth() / target.chara:getStat("health") < (party_average_hp / 2) then
            target = self:randomTargetOld()
        end
        if target.chara:getHealth() / target.chara:getStat("health") < (party_average_hp / 2) then
            target = self:randomTargetOld()
        end

        -- If we landed on Kris (or, well, the first party member), and their health is low, retarget (plot armor lol)
        if (target == self.party[1]) and ((target.chara:getHealth() / target.chara:getStat("health")) < 0.35) then
            target = self:randomTargetOld()
        end

        -- They got hit, so un-darken them
        target.should_darken = false
        target.targeted = true
    end

    target = target or "ANY"

    -- Alright, first let's try to adjust targets.

    if type(target) == "number" then
        target = self.party[target]
    end

    if isClass(target) and target:includes(PartyBattler) then
        if (not target) --[[or (target.chara:getMana() <= 0)]] --[[(not target.chara:usesMana())]] then -- Why doesn't this look at :canTarget()? Weird. (hmm)
            target = self:randomTargetOld()
        end
    end

    if target == "ANY" --[[or self.multi_resource_depletion_target_is_any ]]then
        target = self:randomTargetOld()
    end

    -- Now
    if isClass(target) and target:includes(PartyBattler) then
        Assets.playSound("ttyd_lucky", 0.8)
        target:statusMessage("msg", "lucky", color, true)
        return {target}
    end

    if target == "ALL" then

        Assets.playSound("ttyd_lucky", 0.8)
        local alive_battlers = Utils.filter(self.party, function(battler) return not battler.is_down end)
        for _,battler in ipairs(alive_battlers) do
            battler:statusMessage("msg", "lucky", color, true)
        end
        -- Return the battlers who aren't down, aka the ones we hit.
        return alive_battlers
    end

end

function Battle:canSelectMenuItem(menu_item)
    --print(menu_item.mp)
    --print(Game.battle.state_reason)
    --print(menu_item.name .. " has split cost: " .. tostring(menu_item.split_cost))
    --self:updateSplitCost()
    if menu_item.unusable then
        return false
    end
    if menu_item.tp and menu_item.resource == "tension" and (menu_item.tp > Game:getTension()) then     --let me know if something becomes unsuable from this.
        return false
    end
    if menu_item.resource == "stock" then
        --print(menu_item.stock)
        if menu_item.stock < 1 then
            return false
        end
    end
    if menu_item.resource == "health" then
        if (menu_item.hp_cost >= self.party[self.current_selecting].chara:getHealth()) then
            return false
        end
    end
    if menu_item.resource == "mana" then
        if Game.battle.state_reason == "SPELL" and (menu_item.mp > self.party[self.current_selecting].chara:getMana()) then
            return false
        end
        --if Game.battle.state_reason == "ACT" and (menu_item.mp > )
    end
    --[[if menu_item.resource == "none" then
        if not menu_item.data:canDirectCast() then
            return false
        end
    end]]
    if menu_item.party then
        for _,party_id in ipairs(menu_item.party) do
            local party_index = self:getPartyIndex(party_id)
            local battler = self.party[party_index]
            local action = self.character_actions[party_index]
            if (not battler) or (not battler:isActive()) or (action and action.cancellable == false) then
                -- They're either down, asleep, or don't exist. Either way, they're not here to do the action.
                return false
            end
        end
    end

    if menu_item.spenders then
        local active_spenders = 0
        local has_spenders = false

        --local any_spender_present = false

        for _,s in ipairs(menu_item.spenders) do
            has_spenders = true
            --print("spender: " .. s)
            --print("eeek, a " .. s)
            local cost = menu_item.mp
            local party_index = self:getPartyIndex(s)
            local battler = self.party[party_index]
            --local battler_name = ""
            --local spender = Registry.createPartyMember(s)
            if battler and battler:isActive() then
                --any_spender_present = true
                --print(s .. " smsdklnaskjbfashbj")
                active_spenders = active_spenders + 1
                --table.insert(active_spenders, s)
                --print("auuuuuuuuuuuu")
                if (cost > battler.chara:getMana()) then
                    --if (not battler) or (not battler:isActive()) or (action and action.cancellable == false) then
                        -- They're either down, asleep, or don't exist. Either way, they're not here to do the action.
                        return false
                    --end
                --else return false
                end
            end
        end

        --print("active spenders: " .. active_spenders)

        if has_spenders and active_spenders < 1 then
            return false
        end

    end
    return true
end

function Battle:spendActResources(action)

    --local act_found = false
    --local resource = "none"
    --local resource_used = "none"

    --[[for _,act in ipairs(self.act_resources) do
        if action.name == act.name then
            --act_found = true
            --resource = act.resource
        end
    end]]


    if action.spenders --[[and act_found]] then
        for _,spender in ipairs(action.spenders) do
            local party_index = self:getPartyIndex(spender)
            local battler = self.party[party_index]
            --local resource = "none"
            if battler and battler:isActive() then
                print(battler.chara.name)

                --resource = 
                battler.chara:setResourceUsed(action.resource)
            -- resource_used = battler.chara.resource_used
                --print(resource_used)
                print("Resource used by " .. battler.chara:getName() .. " for " .. action.name .. ": " .. action.resource)
                --print(battler.chara.id)
                print("Spender: " .. battler.chara:getName())
                --print(action.resource)
                --print(action.mp)
                if action.mp and action.resource == "mana" then
                    --print("soooooooooooooooooooo")
                    if action.mp > 0 then
                        --print("wwwwwwwwwwwwwwww")
                        battler.chara:setMana(battler.chara:getMana() - action.mp)
                    elseif action.mp < 0 then
                        battler.chara:setMana(battler.chara:getMana() + action.mp)
                    end
                end
            end
        end
    end

end

function Battle:refundActResources(action)

    --print("RIOT CODE")

    if action.spenders --[[and act_found]] then
        for _,spender in ipairs(action.spenders) do
            local party_index = self:getPartyIndex(spender)
            local battler = self.party[party_index]
            --local resource = "none"
            print(battler.chara.name)

            --resource = 
            if battler:isActive() then
                battler.chara:setResourceUsed(action.resource)
            -- resource_used = battler.chara.resource_used
                print(action.resource)
                print("Resource to refund by " .. battler.chara:getName() .. " for " .. action.name .. ": " .. action.resource)
                print(battler.chara.id)
                print("Spender: " .. battler.chara:getName())
                print(action.mp)
                if action.mp and action.resource == "mana" then
                    --print("aaaaaaaaaaaaaaaaaaa")
                    if action.mp < 0 then
                        battler.chara:setMana(battler.chara:getMana() - action.mp)
                    elseif action.mp > 0 then
                        battler.chara:setMana(battler.chara:getMana() + action.mp)
                    end
                end
            end
        end
    end

    self.spenders_to_refund = {}

end

function Battle:commitSingleAction(action)
    local battler = self.party[action.character_id]

    battler.action = action
    self.character_actions[action.character_id] = action

    if Kristal.callEvent(KRISTAL_EVENT.onBattleActionCommit, action, action.action, battler, action.target) then
        return
    end

    if action.party then
        for _,chara in ipairs(action.party) do
            --print(chara)
        end
    end
    ----------------------------------
    if action.action == "ATTACK" then
        if battler.chara:getPassive() then
            if battler.chara:getPassive():getMPCostAttack(battler) > 0 then
                battler.chara:setMana(battler.chara:getMana() - battler.chara:getPassive():getMPCostAttack(battler))
                --print(battler.chara:getPassive():applyMPCostAttack(battler))
                print("LABUBU")
                local attack_spender = {
                    ["spender"] = battler,
                    ["mp_cost"] = battler.chara:getPassive():getMPCostAttack(battler)
                }
                table.insert(self.attack_spenders, attack_spender)
                --print(self.attack_spenders[1].spender.chara.id)
            end
        end
    end
    ----------------------------------
    if action.action == "ITEM" and action.data then
        local result = action.data:onBattleSelect(battler, action.target)
        if result ~= false then
            local storage, index = Game.inventory:getItemIndex(action.data)
            action.item_storage = storage
            action.item_index = index
            if action.data:hasResultItem() then
                local result_item = action.data:createResultItem()
                Game.inventory:setItem(storage, index, result_item)
                action.result_item = result_item
            else
                Game.inventory:removeItem(action.data)
            end
            action.consumed = true
        else
            action.consumed = false
        end
    end

    --print(action.action)

    local anim = action.action:lower()


    self:spendActResources(action)

    if action.action == "SPELL" and action.data --[[and not action.spenders]] then
        --print(action.mp)
        local result = action.data:onSelect(battler, action.target)
        if result ~= false then
            if action.tp and action.resource == "tension" then
                if action.tp > 0 then
                    Game:giveTension(action.tp)
                elseif action.tp < 0 then
                    Game:removeTension(-action.tp)
                end
            elseif action.mp and action.resource == "mana" then
                --print("AUUUGHHH")
                ---print(action.mp)
                if action.mp > 0 then
                    battler.chara:setMana(battler.chara:getMana() - action.mp)
                elseif action.mp < 0 then
                    battler.chara:setMana(battler.chara:getMana() + action.mp)
                end
            elseif action.stock and action.resource == "stock" then
                battler.chara:removeStock(action.data, 1)
            elseif action.hp_cost and action.resource == "health" then
                if action.hp_cost > 0 then
                    battler.chara:heal(-action.hp_cost)
                elseif action.hp_cost < 0 then
                    self:hurt(-action.hp_cost, true, battler)
                end
            end
        battler:setAnimation("battle/"..anim.."_ready")
        action.icon = anim
        end
    else
        --if not action.spenders then
            if action.tp and (action.resource == "tension" or action.action == "DEFEND") then
                --print(action.tp)
                if action.tp > 0 then
                    Game:giveTension(action.tp)
                elseif action.tp < 0 then
                    Game:removeTension(-action.tp)
                end
            end
            if action.mp and action.resource == "mana"and not action.spenders then
                if action.mp > 0 then
                    battler.chara:setMana(battler.chara:getMana() - action.mp)
                elseif action.mp < 0 then
                    battler.chara:setMana(battler.chara:getMana() + action.mp)
                end
            end
            if action.stock and action.resource == "stock" then
                battler.chara:removeStock(action.data, 1)
            end
            if action.hp_cost and action.resource == "health" then
                if action.hp_cost > 0 then
                    battler.chara:heal(-action.hp_cost)
                elseif action.hp_cost < 0 then
                    self:hurt(-action.hp_cost, true, battler)
                end
            end
        --end

        if action.action == "SKIP" and action.reason then
            anim = action.reason:lower()
        end

----------------------------------------------------------
        if action.action == "STOCK" then
            battler:setAnimation("battle/spell_ready")
        end
----------------------------------------------------------


        if (action.action == "ITEM" and action.data and (not action.data.instant)) or (action.action ~= "ITEM") then
            battler:setAnimation("battle/"..anim.."_ready")
            action.icon = anim
        end
    end
end

function Battle:removeSingleAction(action)
    local battler = self.party[action.character_id]

    if Kristal.callEvent(KRISTAL_EVENT.onBattleActionUndo, action, action.action, battler, action.target) then
        battler.action = nil
        self.character_actions[action.character_id] = nil
        return
    end

    battler:resetSprite()

    --for _,s in ipairs(action.spenders) do
        --print("YYYYYYYY")
    --end

    for attack_spender in pairs(self.attack_spenders) do
        --print(attack_spender)
        if self.attack_spenders[attack_spender].spender == battler then
            battler.chara:setMana(battler.chara:getMana() + self.attack_spenders[attack_spender].mp_cost)
            table.remove(self.attack_spenders, attack_spender)
        end
    end

    --print(battler.chara.resource_used .. "soos")
    if action.spenders ~= nil then
        self:refundActResources(action)
    end

    if action.tp --[[or (action.tp and action.action == "SPELL" and]] and (action.resource == "tension" or action.action == "DEFEND") then
        if action.tp < 0 then
            Game:giveTension(-action.tp)
        elseif action.tp > 0 then
            Game:removeTension(action.tp)
        end
    end

    if action.mp and action.resource == "mana" then
        if action.mp < 0 then
            battler.chara:setMana(battler.chara:getMana() - action.mp)
        elseif action.mp > 0 then
            battler.chara:setMana(battler.chara:getMana() + action.mp)
        end
    end

    if action.stock and action.resource == "stock" then
        --print("huh?")
        if action.action == "SPELL" then
            battler.chara:addStock(action.data, 1)
        end
    end

    if action.hp_cost and action.resource == "health" then
        if action.hp_cost < 0 then
            battler.chara:heal(-action.hp_cost)
        elseif action.hp_cost > 0 then
            self:hurt(action.hp_cost, true, battler)
        end
    end

    if action.action == "ITEM" and action.data then
        if action.item_index and action.consumed then
            if action.result_item then
                Game.inventory:setItem(action.item_storage, action.item_index, action.data)
            else
                Game.inventory:addItemTo(action.item_storage, action.item_index, action.data)
            end
        end
        action.data:onBattleDeselect(battler, action.target)
    elseif action.action == "SPELL" and action.data then
        action.data:onDeselect(battler, action.target)
    end

    battler.action = nil
    self.character_actions[action.character_id] = nil
end

function Battle:onStateChange(old,new)

    --print(new)

    local result = self.encounter:beforeStateChange(old,new)
    if result or self.state ~= new then
        return
    end

    if new == "INTRO" then
        self.seen_encounter_text = false
        self.intro_timer = 0
        Assets.playSound("impact", 0.7)
        Assets.playSound("weaponpull_fast", 0.8)

        for _,battler in ipairs(self.party) do
            battler:setAnimation("battle/intro")
        end

        self.encounter:onBattleStart()
    elseif new == "ACTIONSELECT" then
        --print("DO NOT REDEEM")
        if self.current_selecting < 1 or self.current_selecting > #self.party then
            --print("HOOH")
            self:nextTurn()
            if self.state ~= "ACTIONSELECT" then
                return
            end
        end

        if self.state_reason == "CANCEL" then
            self:setEncounterText(self.battle_ui.current_encounter_text, true)
        end

        local had_started = self.started
        if not self.started then
            self.started = true

            for _,battler in ipairs(self.party) do
                battler:resetSprite()
            end

            if self.encounter.music then
                self.music:play(self.encounter.music)
            end
        end

        self:showUI()

        local party = self.party[self.current_selecting]
        party.chara:onActionSelect(party, false)
        self.encounter:onCharacterTurn(party, false)
    elseif new == "ACTIONS" then
        self.battle_ui:clearEncounterText()
        if self.state_reason ~= "DONTPROCESS" then
            self:tryProcessNextAction()
        end
    elseif new == "ENEMYSELECT" or new == "XACTENEMYSELECT" then
        self.battle_ui:clearEncounterText()
        self.current_menu_y = 1
        self.selected_enemy = 1
---------------------------------------------------------------
        for _,enemy in ipairs(Game.battle:getActiveEnemies()) do
            if not enemy.has_spells and self.state_reason == "DRAW" then
                enemy.selectable = false
            else enemy.selectable = true
            end
        end
---------------------------------------------------------------
        if not (self.enemies_index[self.current_menu_y] and self.enemies_index[self.current_menu_y].selectable) and #self.enemies_index > 0 then
            local give_up = 0
            repeat
                give_up = give_up + 1
                if give_up > 100 then return end
                -- Keep decrementing until there's a selectable enemy.
                self.current_menu_y = self.current_menu_y + 1
                if self.current_menu_y > #self.enemies_index then
                    self.current_menu_y = 1
                end
            until (self.enemies_index[self.current_menu_y] and self.enemies_index[self.current_menu_y].selectable)
        end
    elseif new == "PARTYSELECT" then
        self.battle_ui:clearEncounterText()
        self.current_menu_y = 1
    elseif new == "MENUSELECT" then
        self.battle_ui:clearEncounterText()
        self.current_menu_x = 1
        self.current_menu_y = 1
    elseif new == "ATTACKING" then
        self.battle_ui:clearEncounterText()

        local enemies_left = self:getActiveEnemies()

        if #enemies_left > 0 then
            for i,battler in ipairs(self.party) do
                local action = self.character_actions[i]
                if action and action.action == "ATTACK" then
                    self:beginAction(action)
                    table.insert(self.attackers, battler)
                    table.insert(self.normal_attackers, battler)
                elseif action and action.action == "AUTOATTACK" then
                    table.insert(self.attackers, battler)
                    table.insert(self.auto_attackers, battler)
                end
            end
        end

        self.auto_attack_timer = 0

        if #self.attackers == 0 then
            self.attack_done = true
            self:setState("ACTIONSDONE")
        else
            self.attack_done = false
        end
    elseif new == "ENEMYDIALOGUE" then
        self.battle_ui:clearEncounterText()
        self.textbox_timer = 3 * 30
        self.use_textbox_timer = true
        local active_enemies = self:getActiveEnemies()
        if #active_enemies == 0 then
            self:setState("VICTORY")
        else
            for _,enemy in ipairs(active_enemies) do
                enemy.current_target = enemy:getTarget()
            end
            local cutscene_args = {self.encounter:getDialogueCutscene()}
            if #cutscene_args > 0 then
                self:startCutscene(unpack(cutscene_args)):after(function()
                    self:setState("DIALOGUEEND")
                end)
            else
                local any_dialogue = false
                for _,enemy in ipairs(active_enemies) do
                    local dialogue = enemy:getEnemyDialogue()
                    if dialogue then
                        any_dialogue = true
                        local bubble = enemy:spawnSpeechBubble(dialogue)
                        table.insert(self.enemy_dialogue, bubble)
                    end
                end
                if not any_dialogue then
                    self:setState("DIALOGUEEND")
                end
            end
        end
    elseif new == "DIALOGUEEND" then
        self.battle_ui:clearEncounterText()

        for i,battler in ipairs(self.party) do
            local action = self.character_actions[i]
            if action and action.action == "DEFEND" then
                self:beginAction(action)
                self:processAction(action)
            end
        end

        self.encounter:onDialogueEnd()
    elseif new == "DEFENDING" then
        self.wave_length = 0
        self.wave_timer = 0

        for _,wave in ipairs(self.waves) do
            wave.encounter = self.encounter

            self.wave_length = math.max(self.wave_length, wave.time)

            wave:onStart()

            wave.active = true
        end
    elseif new == "VICTORY" then
        self.current_selecting = 0

        if self.tension_bar then
            self.tension_bar:hide()
        end

        for _,battler in ipairs(self.party) do
            battler:setSleeping(false)
            battler.defending = false
            battler.action = nil

            battler.chara:resetBuffs()

            if battler.chara:getHealth() <= 0 then
                battler:revive()
                battler.chara:setHealth(battler.chara:autoHealAmount())
            end

            battler:setAnimation("battle/victory")

            local box = self.battle_ui.action_boxes[self:getPartyIndex(battler.chara.id)]
            box:resetHeadIcon()
        end

        self.money = self.money + (math.floor(((Game:getTension() * 2.5) / 10)) * Game.chapter)

        for _,battler in ipairs(self.party) do
            for _,equipment in ipairs(battler.chara:getEquipment()) do
                self.money = math.floor(equipment:applyMoneyBonus(self.money) or self.money)
            end
        end

        self.money = math.floor(self.money)

        self.money = self.encounter:getVictoryMoney(self.money) or self.money
        self.xp = self.encounter:getVictoryXP(self.xp) or self.xp
        -- if (in_dojo) then
        --     self.money = 0
        -- end

        Game.money = Game.money + self.money
        Game.xp = Game.xp + self.xp

        if (Game.money < 0) then
            Game.money = 0
        end

        local win_text = "* You won!\n* Got " .. self.xp .. " EXP and " .. self.money .. " "..Game:getConfig("darkCurrencyShort").."."
        -- if (in_dojo) then
        --     win_text == "* You won the battle!"
        -- end
        if self.used_violence and Game:getConfig("growStronger") then
            local stronger = "You"

            local party_to_lvl_up = {}
            for _,battler in ipairs(self.party) do
                table.insert(party_to_lvl_up, battler.chara)
                if Game:getConfig("growStrongerChara") and battler.chara.id == Game:getConfig("growStrongerChara") then
                    stronger = battler.chara:getName()
                end
                for _,id in pairs(battler.chara:getStrongerAbsent()) do
                    table.insert(party_to_lvl_up, Game:getPartyMember(id))
                end
            end
            
            for _,party in ipairs(Utils.removeDuplicates(party_to_lvl_up)) do
                Game.level_up_count = Game.level_up_count + 1
                party:onLevelUp(Game.level_up_count)
            end

            win_text = "* You won!\n* Got " .. self.money .. " "..Game:getConfig("darkCurrencyShort")..".\n* "..stronger.." became stronger."

            Assets.playSound("dtrans_lw", 0.7, 2)
            --scr_levelup()
        end

        win_text = self.encounter:getVictoryText(win_text, self.money, self.xp) or win_text

        if self.encounter.no_end_message then
            self:setState("TRANSITIONOUT")
            self.encounter:onBattleEnd()
        else
            self:battleText(win_text, function()
                self:setState("TRANSITIONOUT")
                self.encounter:onBattleEnd()
                return true
            end)
        end
    elseif new == "TRANSITIONOUT" then
        self.current_selecting = 0

        if self.tension_bar and self.tension_bar.shown then
            self.tension_bar:hide()
        end

        self.battle_ui:transitionOut()
        self.music:fade(0, 20/30)
        for _,battler in ipairs(self.party) do
            local index = self:getPartyIndex(battler.chara.id)
            if index then
                self.battler_targets[index] = {battler:getPosition()}
            end
        end
        if self.encounter_context and self.encounter_context:includes(ChaserEnemy) then
            for _,enemy in ipairs(self.encounter_context:getGroupedEnemies(true)) do
                enemy:onEncounterTransitionOut(enemy == self.encounter_context, self.encounter)
            end
        end
    elseif new == "DEFENDINGBEGIN" then
        if self.state_reason == "CUTSCENE" then
            self:setState("DEFENDING")
            return
        end

        self.current_selecting = 0
        self.battle_ui:clearEncounterText()

        if self.state_reason then
            self:setWaves(self.state_reason)
            local enemy_found = false
            for i,enemy in ipairs(self.enemies) do
                if Utils.containsValue(enemy.waves, self.state_reason[1]) then
                    enemy.selected_wave = self.state_reason[1]
                    enemy_found = true
                end
            end
            if not enemy_found then
                self.enemies[love.math.random(1, #self.enemies)].selected_wave = self.state_reason[1]
            end
        else
            self:setWaves(self.encounter:getNextWaves())
        end

        if self.arena then
            self.arena:remove()
        end

        local soul_x, soul_y, soul_offset_x, soul_offset_y
        local arena_x, arena_y, arena_w, arena_h, arena_shape
        local arena_rotation = 0
        local has_arena = true
        local spawn_soul = true
        for _,wave in ipairs(self.waves) do
            soul_x = wave.soul_start_x or soul_x
            soul_y = wave.soul_start_y or soul_y
            soul_offset_x = wave.soul_offset_x or soul_offset_x
            soul_offset_y = wave.soul_offset_y or soul_offset_y
            arena_x = wave.arena_x or arena_x
            arena_y = wave.arena_y or arena_y
            arena_w = wave.arena_width and math.max(wave.arena_width, arena_w or 0) or arena_w
            arena_h = wave.arena_height and math.max(wave.arena_height, arena_h or 0) or arena_h
            arena_rotation = wave.arena_rotation or arena_rotation
            if wave.arena_shape then
                arena_shape = wave.arena_shape
            end
            if not wave.has_arena then
                has_arena = false
            end
            if not wave.spawn_soul then
                spawn_soul = false
            end
        end

        local center_x, center_y
        if has_arena then
            if not arena_shape then
                arena_w, arena_h = arena_w or 142, arena_h or 142
                arena_shape = {{0, 0}, {arena_w, 0}, {arena_w, arena_h}, {0, arena_h}}
            end

            local arena = Arena(arena_x or SCREEN_WIDTH/2, arena_y or (SCREEN_HEIGHT - 155)/2 + 10, arena_shape)
            arena.rotation = arena_rotation
            arena.layer = BATTLE_LAYERS["arena"]

            self.arena = arena
            self:addChild(arena)
            center_x, center_y = arena:getCenter()
        else
            center_x, center_y = SCREEN_WIDTH/2, (SCREEN_HEIGHT - 155)/2 + 10
        end

        if spawn_soul then
            soul_x = soul_x or (soul_offset_x and center_x + soul_offset_x)
            soul_y = soul_y or (soul_offset_y and center_y + soul_offset_y)
            self:spawnSoul(soul_x or center_x, soul_y or center_y)
        end

        for _,wave in ipairs(Game.battle.waves) do
            if wave:onArenaEnter() then
                wave.active = true
            end
        end

        self.defending_begin_timer = 0
    end

    -- List of states that should remove the arena.
    -- A whitelist is better than a blacklist in case the modder adds more states.
    -- And in case the modder adds more states and wants the arena to be removed, they can remove the arena themselves.
    local remove_arena = {"DEFENDINGEND", "TRANSITIONOUT", "ACTIONSELECT", "VICTORY", "INTRO", "ACTIONS", "ENEMYSELECT", "XACTENEMYSELECT", "PARTYSELECT", "MENUSELECT", "ATTACKING"}

    local should_end = true
    if Utils.containsValue(remove_arena, new) then
        for _,wave in ipairs(self.waves) do
            if wave:beforeEnd() then
                should_end = false
            end
        end
        if should_end then
            self:returnSoul()
            if self.arena then
                self.arena:remove()
                self.arena = nil
            end
            for _,battler in ipairs(self.party) do
                battler.targeted = false
            end
        end
    end

    local ending_wave = self.state_reason == "WAVEENDED"

    if old == "DEFENDING" and new ~= "DEFENDINGBEGIN" and should_end then
        for _,wave in ipairs(self.waves) do
            if not wave:onEnd(false) then
                wave:clear()
                wave:remove()
            end
        end

        local function exitWaves()
            for _,wave in ipairs(self.waves) do
                wave:onArenaExit()
            end
            self.waves = {}
        end

        if self:hasCutscene() then
            self.cutscene:after(function()
                exitWaves()
                if ending_wave then
                    self:nextTurn()
                end
            end)
        else
            self.timer:after(15/30, function()
                exitWaves()
                if ending_wave then
                    --print("HAAH")
                    self:nextTurn()
                end
            end)
        end
    end

    self.encounter:onStateChange(old,new)
end

function Battle:startProcessing()
    self.has_acted = false
    if not self.encounter:onActionsStart() then
        self:setState("ACTIONS")
    end
    self.spenders_to_refund = {}
end

function Battle:nextTurn()

    super.nextTurn(self)

    self:updateSplitCost()

    self.spenders_to_refund = {}
    --print("iiii")

    --print(self.party[self.current_selecting].name)

    for _,battler in ipairs(self.party) do

        battler:checkHealth()       --Hopefully this doesn't mess up anything.

        if battler.chara:getManaMode() == "gotr" and self.turn_count == 1 then
            battler.chara:setMana(0)
        end

        --print(--[[battler.chara:getName() .. " down mode: " .. ]]battler.chara:getDownMode())
        battler.hit_count = 0
        if (battler.chara:getHealth() <= 0) and battler.chara:canAutoHeal() then
            battler:heal(battler.chara:autoHealAmount(), nil, true)
        end
-------------------------------------------------------------------------
        if (battler.chara:getHealth() > 0) and (battler.chara:canAutoRegenMana() or (battler.chara:canAutoRegenMana() and battler.chara:getManaMode() == "gotr")) and self.turn_count > 1 and battler.chara:usesMana() then

            battler:regenMana(battler.chara:autoRegenManaAmount(battler.chara.auto_mana_regen_tp_scaling, battler.chara.auto_mana_regen_flat_increase))
        end
-------------------------------------------------------------------------
        battler.action = nil
        battler.chara:setResourceUsed(battler.chara:getMainSpellResourceType())       --Resets the resource_used variable to the character's default just to be safe.

    end

end

function Battle:updateTransitionOut()

    super.updateTransitionOut(self)

    

    for index, battler in ipairs(self.party) do
        local target_x, target_y = unpack(self.battler_targets[index])

        battler.x = Utils.lerp(self.party_beginning_positions[index][1], target_x, self.transition_timer / 10)
        battler.y = Utils.lerp(self.party_beginning_positions[index][2], target_y, self.transition_timer / 10)
-------------------------------------------------------------------
        if battler.chara:getManaMode() == "gotr" then
            --print("soos")
            battler.chara:setMana(0)
        end
-------------------------------------------------------------------
    end
end

-----------
---(This was so hard to troubleshoot I don't even know if it works properly 100%)
function Battle:updateSplitCost()

    for _,e in ipairs(self.enemies) do
        --print("SUUS")
        --print(e.name)
        for _,v in ipairs(e.acts) do
            if v.spenders and v.resource == "mana" --[[and v.split_cost]] then
                --print("baba is kiki")
                local spenders_active = 0
                local original_cost = 0
                --local spender = Registry.createPartyMember(s)
                for _,act in ipairs(self.act_resources) do
                    if act.name == v.name then
                        original_cost = act.cost
                    end
                end
                --print("babababababa " .. original_cost)
                if v.split_cost then
                    for _,spender in ipairs(v.spenders) do
                        local party_index = Game.battle:getPartyIndex(spender)
                        local battler = Game.battle.party[party_index]
                        if battler then
                            --print(battler.chara:getName())
                            if battler:isActive() then
                                spenders_active = spenders_active + 1
                            end
                        end
                        --print(spenders_active)
                        if spenders_active > 0 then
                            --print(spenders_active)
                            --print("sssssss"  .. mp)
                            v["mp"] = Utils.floor(Utils.getFractional(original_cost, 1, spenders_active))
                            --print("pppppp" .. v.mp)
                        end
                    end
                end
            end
        end
    end

    if self.state_reason == "ACT" then      --Kicks the player out of the ACT menu if any party member is downed/revived.
        self:setState("ACTIONSELECT")
    end
end
----------

--Gets the split cost for each spender for an action.
---@param spenders string[] The table of spenders.
---@param resource string   The resource used for the action.
---@return number
function Battle:getSplitCost(menu_item, spenders, resource)

    local cost = 0

    local result = 0

    if resource == "mana" then
        cost = menu_item.mp
    end

    result = Utils.getFractional(cost, 1, #spenders)

    result = Utils.ceil(result)

    --print(result)

    return result

end

return Battle