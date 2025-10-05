local item, super = Class(Item, "cell_phone")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Cell Phone"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "key"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "It can be used to make calls."

    -- Default shop price (sell price is halved)
    self.price = 0
    -- Whether the item can be sold
    self.can_sell = false

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "none"
    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "world"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {}
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = nil
    self.bonus_icon = nil

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions (key = party member id)
    self.reactions = {}
end

function item:onWorldUse()
    Game.world:startCutscene(function(cutscene)
        Assets.playSound("phone", 0.7)
        cutscene:text("* (You tried to call on the Cell\nPhone.)", nil, nil, {advance = false})
        cutscene:wait(40/30)
        local was_playing = Game.world.music:isPlaying()
        if was_playing then
            Game.world.music:pause()
        end
        if Game:getSoulPartyMember().id == "kris" and Game:getPartyIndex("noelle") then
            local noelle = cutscene:getCharacter("noelle")
            local ringtone = Assets.getSound("noelle_ringtone")

            ringtone:play()
            ringtone:setLooping(true)
            Assets.playSound("phone", 0.7)
            noelle:shake(5)
            cutscene:wait(60/30)
            Assets.playSound("phone", 0.7)
            noelle:shake(5)
            cutscene:wait(60/30)
            cutscene:text("* ?", "confused_alt", "noelle")
            cutscene:text("* Kris, did you meant to call me?", "confused_alt", "noelle")
            cutscene:wait(30/30)
            ringtone:stop()
            Assets.playSound("item", 0.7)
            cutscene:text("* Huh? [wait:5]The new ringtone?", "blush_big_smile", "noelle")
            cutscene:text("* I know right? it's kind of silly.", "smile_closed_b_dark", "noelle")
            Assets.stopSound("noelle_ringtone")
            if was_playing then
                Game.world.music:resume()
            end
            cutscene:getCharacter("kris"):setFacing("down")
            cutscene:wait(90/30)
            if was_playing then
                Game.world.music:pause()
            end
            cutscene:text("* Wait, didn't you say your phone doesn't work in here?", "confused_alt", "noelle")
            if was_playing then
                Game.world.music:resume()
            end
        else
            Assets.playSound("smile")
            cutscene:wait(200/30)
            if was_playing then
                Game.world.music:resume()
            end
            cutscene:text("* It's nothing but garbage noise.")
        end
    end)
end

return item