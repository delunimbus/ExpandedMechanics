function Mod:init()
    print("------------------------------------")
    print("Loaded "..self.info.name.."!")

    Utils.hook(Utils, "dump", function(orig, o)
		if type(o) == "table" and isClass(o) and o.__tostring then
			return tostring(o)
		end
		return orig(o)
	end)

    Utils.hook(World, "init", function(orig, self, map, ...)
        orig(self, map, ...)
        self.world_caster = nil
    end)

    Utils.hook(World, "setWorldCaster", function(orig, self, caster)

        self.world_caster = caster

    end)

    Utils.hook(World, "getWorldCaster", function(orig, self, caster)

        return self.world_caster

    end)
end


----THIS ALL HAS TO BE PUT IN THE HOOKS AS IT WILL BE A LIB (ok maybe not actually?)
function Mod:postInit(new_file)
    if new_file then
        Game:setFlag("global_starting_stock_limit", 99) --THE ONLY FLAG IN THIS WHOLE LIBRARY AND ITS ABSOLUTELY REDUNDANT SoyPoint
    end
end

function Mod:onBattleMenuSelect(state, item, can_select)
    if state == "DRAWSPELL" and can_select then                         --All this seems really shoddy, so it might break. please let me know if it does.
        local battler = Game.battle.party[Game.battle.current_selecting]
        --print(item.name)
        --print(item.description)
        --print(item.spell_name .. " soos")
        Game.battle:clearMenuItems()
        local spell = item.data
        --print("HELLO HELLO HELLO HELLO HHHEEELLL>OO")
        Game.battle.menu_items = {}
        local color = item.color
        local target = item.data.target
        table.insert(Game.battle.menu_items, {
                ["name"] = "Stock\n" .. item.name,
                ["resource"] = "stock_show",
                ["unusable"] = not spell:isUsable(battler.chara) or (spell:getStock(battler.chara) == spell:getStockLimit(battler.chara)) and not spell:canStock(),
                ["stock"] = spell:getStock(battler.chara),
                ["stock_limit"] = spell:getStockLimit(battler.chara),
                ["color"] = color,
                ["description"] = "Stock\nspell",
                ["data"] = spell,
                ["callback"] = function (menu_item)

                    Game.battle.selected_spell = menu_item

                    Game.battle:pushAction("STOCK", Game.battle.enemies_index[Game.battle.selected_enemy], menu_item)

                end
            })
            --print(item.party)
            --print(target)
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
                ["name"] = "Cast\n" .. item.name,
                --["spell_name"] = item.spell_name,
                --["tp"] = spell:getTPCost(self.battler.chara),
                -------------------------------------------
                --["mp"] = spell:getMPCost(self.battler.chara),
                ["resource"] = "none",
                --["stock"] = spell:getStock(battler.chara),
                --["stock_limit"] = spell:getStockLimit(battler.chara),
                --["hp_cost"] = spell:getBloodPriceFlat(self.battler.chara),
                -------------------------------------------
                ["unusable"] = not spell:isUsable(battler.chara) or not spell:canDrawCast(),
                ["description"] = "Cast\nspell",
                ["party"] = spell.party,
                ["color"] = color,
                ["data"] = spell,
                ["callback"] = function(menu_item)
                    Game.battle.selected_spell = menu_item

                    if not spell.target or spell.target == "none" then
                        Game.battle:pushAction("SPELL", nil, menu_item)
                    elseif spell.target == "ally" then
                        Game.battle:setState("PARTYSELECT", "SPELL")
                    elseif spell.target == "enemy" then
                        Game.battle:setState("ENEMYSELECT", "SPELL")
                    elseif spell.target == "party" then
                        Game.battle:pushAction("SPELL", Game.battle.party, menu_item)
                    elseif spell.target == "enemies" then
                        Game.battle:pushAction("SPELL", Game.battle:getActiveEnemies(), menu_item)
                    end
                end
            })
        Game.battle:setState("MENUSELECT", "DRAWACTION")
    end
end

function Mod:onBattleAction(action, action_type, battler, enemy)

    if action_type == "STOCK" then
        Game.battle.battle_ui:clearEncounterText()

        local worked = false

        battler.chara:setSpellStockData(action.data, -1, -1)

        enemy:flash()

        local result = battler.chara:stockSpell(action.data, enemy, true)

        battler:setAnimation("battle/spell", function()

        if result > 0 then
            if result > 1 then
                if action.data:getStock(battler.chara) == action.data:getStockLimit(battler.chara) then
                    Game.battle:battleText("* " .. battler.chara.name .. " reached max stock for " .. action.data:getCastName() .. "!")
                else
                    Game.battle:battleText("* " .. battler.chara.name .. " got ".. result .. " stocks of " .. action.data:getCastName() .. " from " .. enemy.name .. "!")
                end
            else
                Game.battle:battleText("* " .. battler.chara.name .. " got one stock of " .. action.data:getCastName() .. " from " .. enemy.name .. "!")
            end
            worked = true
        else
            Game.battle:battleText("* " .. battler.chara.name .. " tried to stock ".. action.data:getCastName() .." from " .. enemy.name .. ", but the action failed!")
        end

        if worked then
            --flashy animation based on the stock action from FF8 needed.

            battler:statusMessage("stock", result, COLORS["ltgray"])
            battler:sparkle(0.75, 0.75, 0.75)
            Assets.stopAndPlaySound("PMD2_PP_Up")
            battler.chara:addEncounteredSpell(action.data)
        else Assets.stopAndPlaySound("sonic_death")



        end
        battler:setAnimation("battle/idle")
        battler:flash()
        Game.battle:finishAction(action)
    end)

    end
end

function Mod:onRegistered()
    Mod.passives = {}
    Mod.elements = {}
    --print("ddddddd")
    for _,path,passive in Registry.iterScripts("data/passives") do
        --print("llll")
        assert(passive ~= nil, '"data/passives/'..path..'.lua" does not return value')
        passive.id = passive.id or path
        Mod.passives[passive.id] = passive
        --table.insert(Mod.passives, passive)
        --print(Mod.passives[passive.id].id)
    end
    for _,path,element in Registry.iterScripts("data/elements") do
        --print("rrrr")
        assert(element ~= nil, '"data/elements/'..path..'.lua" does not return value')
        element.id = element.id or path
        Mod.elements[element.id] = element
        --table.insert(Mod.passives, passive)
        --print(Mod.elements[element.id].id)
    end
end

function Mod:registerPassive(id, class)
    Mod.passives[id] = class
end

function Mod:getPassive(id)
    return Mod.passives[id]
end

function Mod:createPassive(id, ...)
    --print("jj"..id)
    if Mod.passives[id] then
        return Mod.passives[id](...)
    else
        error("Attempt to create non existent passive \"" .. tostring(id) .. "\"")
    end
end

function Mod:registerElement(id, class)
    Mod.elements[id] = class
end

function Mod:getElement(id)
    return Mod.elements[id]
end

function Mod:createElement(id, ...)
    --print("jj"..id)
    if Mod.elements[id] then
        return Mod.elements[id](...)
    else
        error("Attempt to create non existent element \"" .. tostring(id) .. "\"")
    end
end
