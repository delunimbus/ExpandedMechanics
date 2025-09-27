---@class ActionBox : ActionBox
---@overload fun(...) : ActionBox
local ActionBox, super = Class(ActionBox)

function ActionBox:init(x, y, index, battler)
    super.init(self, x, y, index, battler)

    --self.hp_v_sprite = Sprite("ui/hp_v", 109, 22)

    self.mp_sprite = Sprite("ui/mp", 107, 7)
    self.box:addChild(self.mp_sprite)

    self.mp_sprite.visible = false

end

function ActionBox:createButtons()
    
    for _,button in ipairs(self.buttons or {}) do
        button:remove()
    end

    self.buttons = {}

    local btn_types = {"fight", "act", "magic", "item", "spare", "defend"}

    if self.battler.chara:hasDrawMagicSkill() then
        btn_types = {"fight", "act", "drawmagic", "magic", "item", "spare", "defend"}
    end
    if not self.battler.chara:hasAct() then Utils.removeFromTable(btn_types, "act") end
    if not self.battler.chara:hasSpells() then Utils.removeFromTable(btn_types, "magic") end
    if not self.battler.chara:canUseItems() then Utils.removeFromTable(btn_types, "item") end
    

    for lib_id,_ in Kristal.iterLibraries() do
        btn_types = Kristal.libCall(lib_id, "getActionButtons", self.battler, btn_types) or btn_types
    end
    btn_types = Kristal.modCall("getActionButtons", self.battler, btn_types) or btn_types

    local start_x = (213 / 2) - ((#btn_types-1) * 35 / 2) - 1

    if (#btn_types <= 5) and Game:getConfig("oldUIPositions") then
        start_x = start_x - 5.5
    end

    for i,btn in ipairs(btn_types) do
        if type(btn) == "string" then
            local button = ActionButton(btn, self.battler, math.floor(start_x + ((i - 1) * 35)) + 0.5, 21)
            button.actbox = self
            table.insert(self.buttons, button)
            self:addChild(button)
        elseif type(btn) ~= "boolean" then -- nothing if a boolean value, used to create an empty space
            btn:setPosition(math.floor(start_x + ((i - 1) * 35)) + 0.5, 21)
            btn.battler = self.battler
            btn.actbox = self
            table.insert(self.buttons, btn)
            self:addChild(btn)
        end
    end

    self.selected_button = Utils.clamp(self.selected_button, 1, #self.buttons)

end

function ActionBox:update()

    if self.battler.chara:usesMana() then

        self.selection_siner = self.selection_siner + 2 * DTMULT

        if Game.battle.current_selecting == self.index then
            if self.box.y > -32 then self.box.y = self.box.y - 2 * DTMULT end
            if self.box.y > -24 then self.box.y = self.box.y - 4 * DTMULT end
            if self.box.y > -16 then self.box.y = self.box.y - 6 * DTMULT end
            if self.box.y > -8  then self.box.y = self.box.y - 8 * DTMULT end
            -- originally '= -64' but that was an oversight by toby
            if self.box.y < -32 then self.box.y = -32 end
        elseif self.box.y < -14 then
            self.box.y = self.box.y + 15 * DTMULT
        else
            self.box.y = 0
        end

        self.head_sprite.y = 11 - self.data_offset + self.head_offset_y
        if self.name_sprite then
            self.name_sprite.y = 14 - self.data_offset
        end
        self.hp_sprite.x = 107
        self.hp_sprite.y = 8 - self.data_offset

        self.mp_sprite.visible = true
        self.mp_sprite.y = 24 - self.data_offset

        if not self.force_head_sprite then
            local current_head = self.battler.chara:getHeadIcons().."/"..self.battler:getHeadIcon()
            if not self.head_sprite:hasSprite(current_head) then
                current_head = self.battler.chara:getHeadIcons().."/head"
            end

            if not self.head_sprite:isSprite(current_head) then
                self.head_sprite:setSprite(current_head)
            end
        end

        for i,button in ipairs(self.buttons) do
            if (Game.battle.current_selecting == self.index) then
                button.selectable = true
                button.hovered = (self.selected_button == i)
            else
                button.selectable = false
                button.hovered = false
            end
        end

    super.super.update(self)
else super.update(self) end
end

return ActionBox