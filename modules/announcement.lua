--*****************************************************************************
--* File: lua/modules/ui/game/announcement.lua
--* Author: Ted Snook, HUSSAR
--* Summary: Announcement UI for sending general messages to the user
--*
--* Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

local bg = false

function CreateAnnouncement(text, goalControl, secondaryText, onFinished)   
    local scoreDlg = import('/lua/ui/dialogs/score.lua')
    if scoreDlg.dialog then
        if onFinished then
            onFinished()
        end
        return
    end
    if bg then
        if bg.OnFinished then
            bg.OnFinished()
        end
        bg.OnFrame = function(self, delta)
            local newAlpha = self:GetAlpha() - (delta*2)
            if newAlpha < 0 then
                newAlpha = 0
                self:Destroy()
                bg.OnFinished = nil
                bg = false
                CreateAnnouncement(text, goalControl, secondaryText, onFinished)
            end
            self:SetAlpha(newAlpha, true)
        end
        return
    end
    bg = Bitmap(GetFrame(0), UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_m.dds'))
    bg.Height:Set(0)
    bg.Width:Set(0)
    bg.Depth:Set(GetFrame(0):GetTopmostDepth()+1)
    LayoutHelpers.AtCenterIn(bg, goalControl)
    
    bg.border = CreateBorder(bg)
    PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Announcement_Open'}))
    local textGroup = Group(bg)
    
    local text = UIUtil.CreateText(textGroup, text, 22, UIUtil.titleFont)
    LayoutHelpers.AtCenterIn(text, GetFrame(0), -250)
    text:SetDropShadow(true)
    text:SetColor(UIUtil.fontColor)
    text:SetNeedsFrameUpdate(true)
    
    if secondaryText then
        secText = UIUtil.CreateText(textGroup, secondaryText, 18, UIUtil.bodyFont)
        secText:SetDropShadow(true)
        secText:SetColor(UIUtil.fontColor)
        LayoutHelpers.Below(secText, text, 10)
        LayoutHelpers.AtHorizontalCenterIn(secText, text)
        textGroup.Top:Set(text.Top)
        textGroup.Left:Set(function() return math.min(secText.Left(), text.Left()) end)
        textGroup.Right:Set(function() return math.max(secText.Right(), text.Right()) end)
        textGroup.Bottom:Set(secText.Bottom)
    else
        LayoutHelpers.FillParent(textGroup, text)
    end
    textGroup:SetAlpha(0, true)
    
    bg:DisableHitTest(true)
    
    bg.OnFinished = onFinished
    
    bg.time = 0
    bg:SetNeedsFrameUpdate(true)
    bg.CloseSoundPlayed = false
    bg.OnFrame = function(self, delta)
        self.time = self.time + delta
        if self.time >= 3.5 and self.time < 3.7 then
            if not self.CloseSoundPlayed then
                PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Announcement_Close'}))
                self.CloseSoundPlayed = false
            end
            self.Top:Set(MATH_Lerp(self.time, 3.5, 3.7, textGroup.Top(), goalControl.Top()))
            self.Left:Set(MATH_Lerp(self.time, 3.5, 3.7, textGroup.Left(), goalControl.Left()))
            self.Right:Set(MATH_Lerp(self.time, 3.5, 3.7, textGroup.Right(), goalControl.Right()))
            self.Bottom:Set(MATH_Lerp(self.time, 3.5, 3.7, textGroup.Bottom(), goalControl.Bottom()))
            self.Height:Set(MATH_Lerp(self.time, 3.5, 3.7, textGroup.Height(), goalControl.Height()))
            self.Width:Set(MATH_Lerp(self.time, 3.5, 3.7, textGroup.Width(), goalControl.Width()))
        elseif self.time < .2 then
            self.Top:Set(MATH_Lerp(self.time, 0, .2, goalControl.Top(), textGroup.Top()))
            self.Left:Set(MATH_Lerp(self.time, 0, .2, goalControl.Left(), textGroup.Left()))
            self.Right:Set(MATH_Lerp(self.time, 0, .2, goalControl.Right(), textGroup.Right()))
            self.Bottom:Set(MATH_Lerp(self.time, 0, .2, goalControl.Bottom(), textGroup.Bottom()))
            self.Height:Set(MATH_Lerp(self.time, 0, .2, goalControl.Height(), textGroup.Height()))
            self.Width:Set(MATH_Lerp(self.time, 0, .2, goalControl.Width(), textGroup.Width()))
        elseif self.time > .2 and self.time < 3.5 then
            self.Top:Set(textGroup.Top)
            self.Left:Set(textGroup.Left)
            self.Right:Set(textGroup.Right)
            self.Bottom:Set(textGroup.Bottom)
            self.Height:Set(textGroup.Height)
            self.Width:Set(textGroup.Width)
        end
        
        if self.time > 3 and textGroup:GetAlpha() ~= 0 then
            textGroup:SetAlpha(math.max(textGroup:GetAlpha()-(delta*2), 0), true)
        elseif self.time > .2 and self.time < 3 and text:GetAlpha() ~= 1 then
            textGroup:SetAlpha(math.min(text:GetAlpha()+(delta*2), 1), true)
        end
        
        if self.time > 3.7 then
            if bg.OnFinished then
                bg.OnFinished()
            end
            bg:Destroy()
            bg.OnFinished = nil
            bg = false
        end
    end
    if import('/lua/ui/game/gamemain.lua').gameUIHidden then
        bg:Hide()
    end
end
function CreateFillIcon(partent, iconPath, iconSize, color)
    iconSize = iconSize or 25
    local group = Group(partent)
    group.Height:Set(iconSize)
    group.Width:Set(iconSize)
     
    group.Icon = Bitmap(group)
    group.Icon:SetTexture(iconPath)
    group.Icon.Height:Set(iconSize)
    group.Icon.Width:Set(iconSize)
    group.Icon:DisableHitTest() 
    LayoutHelpers.FillParent(group.Icon, group)
     
    group.Fill = Bitmap(group.Icon)
    group.Fill:SetSolidColor(color or 'FFFFFFFF') --#FFFFFFFF
    group.Fill.Depth:Set(function() return group.Icon.Depth() - 1 end)
    group.Fill:DisableHitTest()
    LayoutHelpers.FillParent(group.Fill, group.Icon)
     
    return group
end

-- gets table bounds of root frame filled horizontally and vertically
function GetFlippedBounds()
    local top = GetFrame(0).Height() 
    local left = GetFrame(0).Width()  
    return { T = top, L = left, R = 0, B = 0} 
end
-- gets center bounds by comparing UI bounds with specified bounds
function GetCenterBounds(ui, bounds)
    if not bounds then 
        bounds = GetFlippedBounds()
    end
    bounds.L = math.min(bounds.L, ui.Left()) 
    bounds.R = math.max(bounds.R, ui.Right())  
    bounds.T = math.min(bounds.T, ui.Top()) 
    bounds.B = math.max(bounds.B, ui.Bottom()) 
    return bounds
end
function CreateInfoLine(partent, info)

    local position = { T = 5, L  = 5, R = 0, B = 0}
 
    local iconSize = 28

    local group = Group(partent)
    group.Height:Set(250)
    group.Width:Set(30)
    
    if info.icon then
        group.Icon = CreateFillIcon(group, info.icon, iconSize, info.fontColor)
        LayoutHelpers.AtLeftTopIn(group.Icon, group, position.L, position.T)
        --position = position + 30
        --position.L = position.L + 30
        position.R = math.max(position.R, iconSize )  
        position.B = math.max(position.B, iconSize )  
       --position.R = math.max(position.R, group.Icon.Right() )  
        --position.B = math.max(position.B, group.Icon.Bottom() )  
        --LayoutHelpers.LeftOf(targetIcon , targetText, 4) 
        --group.Right:Set(function() return group.Icon.Right() + 5 end)
        --group.Bottom:Set(function() return group.Icon.Bottom() + 5 end)

        
        group.Right:Set(function() return group.Icon.Right() + 5 end) 
        group.Bottom:Set(function() return group.Icon.Bottom() + 5 end)

    else
        
        group.Right:Set(function() return 2 end)
        group.Bottom:Set(function() return 2 end)
    end
    if info.value then
        local textValue = info.value or 'value'
        local textSize  = info.fontSize or 22
        local textColor = info.fontColor or UIUtil.fontColor
        local textFont  = info.fontName or UIUtil.titleFont
    
        group.Text = UIUtil.CreateText(group, textValue, textSize, textFont)
        group.Text:SetDropShadow(true)
        group.Text:SetColor(textColor)
        --LayoutHelpers.AtHorizontalCenterIn(group.Text, group, 0)
        --LayoutHelpers.AtLeftTopIn(group.Text, group, position.L, position.T)
        --LayoutHelpers.AtCenterIn(group.Text, group, 2)
        LayoutHelpers.AtHorizontalCenterIn(group.Text, group, 0)
        LayoutHelpers.AtTopIn(group.Text, group, 2)
        --LayoutHelpers.RightOf(group.Text, group.Icon, 4)

        --LayoutHelpers.AtLeftTopIn(group.Text, group, position.L, position.T)
        --position.R = math.max(position.R, group.Text.Right() )  
        --position.B = math.max(position.B, group.Text.Bottom() )  
        
        --LayoutHelpers.LeftOf(targetIcon , targetText, 4) 
        --position.L = math.min(position.L, group.Text.Left() )  
        --position.T = math.min(position.T, group.Text.Top() ) 
        --position.R = math.max(position.R, group.Text.Right() )  
        --position.B = math.max(position.B, group.Text.Bottom() )  
        --group.Right:Set(function() return group.Text.Right() + 5 end)
        --group.Bottom:Set(function() return group.Text.Bottom() + 5 end)
        --group.Bottom:Set(function() return textSize + 5 end)

        
        group.Right:Set(function() return group.Text.Right() + 5 end) 
        group.Bottom:Set(function() return group.Text.Bottom() + 5 end)
    end
    if group.Text and group.Icon then
        LayoutHelpers.RightOf(group.Text, group.Icon, 4)
        --position.R = math.max(position.R, group.Text.Right() )  
        --position.B = math.max(position.B, group.Text.Bottom() )          
        
        group.Right:Set(function() return group.Text.Right() + 5 end) 
        group.Bottom:Set(function() return group.Text.Bottom() + 5 end)
    end

    --table.print(position, 'position')
    --group.Left:Set(function() return position.L end)
    --group.Top:Set(function() return position.T end)
    --group.Right:Set(function() return position.R + 5 end) 
    --group.Bottom:Set(function() return position.B + 5 end)
    
    return group
end
function CreateSmartAnnouncement(parentUI, sender, message, target, onFinished)   
    local scoreDlg = import('/lua/ui/dialogs/score.lua')
    if scoreDlg.dialog then
        if onFinished then
            onFinished()
        end
        return
    end
    if bg then
        if bg.OnFinished then
            bg.OnFinished()
        end
        bg.OnFrame = function(self, delta)
            local newAlpha = self:GetAlpha() - (delta * 2)
            if newAlpha < 0 then
                newAlpha = 0
                self:Destroy()
                bg.OnFinished = nil
                bg = false
                CreateSmartAnnouncement(parentUI, sender, message, target, onFinished)
            end
            self:SetAlpha(newAlpha, true)
        end
        return
    end 
    bg = Bitmap(GetFrame(0), UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_m.dds'))
    --bg = Bitmap(GetFrame(0))
    --bg:SetSolidColor('BF545353') --#BF545353
    bg.Height:Set(0)
    bg.Width:Set(0)
    bg.Depth:Set(GetFrame(0):GetTopmostDepth()+1)
    LayoutHelpers.AtCenterIn(bg, parentUI)
    
    bg.border = CreateBorder(bg)
    PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Announcement_Open'}))
    local textGroup = Group(bg)
    --textGroup.Height:Set(200)
    --textGroup.Width:Set(400)
    --LayoutHelpers.AtCenterIn(textGroup, GetFrame(0))

    local bounds = GetFlippedBounds()  
    local textValue = sender.value or 'SENDER'
    local textSize  = sender.fontSize or 22
    local textColor = sender.fontColor or UIUtil.fontColor
    local textFont  = sender.fontName or UIUtil.titleFont
    local senderText = UIUtil.CreateText(textGroup, textValue, textSize, textFont)
    --LayoutHelpers.AtCenterIn(senderText, GetFrame(0), -250) 
    LayoutHelpers.AtTopIn(senderText, GetFrame(0), 200) 
    LayoutHelpers.AtHorizontalCenterIn(senderText, GetFrame(0))

    senderText:SetDropShadow(true)
    senderText:SetColor(textColor)
    senderText:SetNeedsFrameUpdate(true)
    
    if sender.icon then
        local senderIcon = CreateFillIcon(textGroup, sender.icon, sender.iconSize, sender.fontColor)
        LayoutHelpers.LeftOf(senderIcon, senderText, 5) 
        --LayoutHelpers.AtTopIn(senderIcon, senderText, -2) 
        bounds = GetCenterBounds(senderIcon, bounds)
    end 

    bounds = GetCenterBounds(senderText, bounds)
    
    textValue = message.value or 'MESSAGE'
    textSize  = message.fontSize or 22
    textColor = message.fontColor or UIUtil.fontColor
    textFont  = message.fontName or  UIUtil.titleFont  
    local messageText = UIUtil.CreateText(textGroup, textValue, textSize, textFont)
    messageText:SetDropShadow(true)
    messageText:SetColor(textColor)
    LayoutHelpers.Below(messageText, senderText, 10)
    LayoutHelpers.AtHorizontalCenterIn(messageText, senderText) 
     
    bounds = GetCenterBounds(messageText, bounds)
    
    local targetText = nil
    if target and target.value then 
        textValue = target.value or 'TARGET'
        textSize  = target.fontSize or 22
        textColor = target.fontColor or UIUtil.fontColor
        textFont  = target.fontName or UIUtil.titleFont
        targetText = UIUtil.CreateText(textGroup, textValue, textSize, textFont)
        targetText:SetDropShadow(true)
        targetText:SetColor(textColor)
        LayoutHelpers.Below(targetText, messageText, 10)
        LayoutHelpers.AtHorizontalCenterIn(targetText, senderText)
        
        bounds = GetCenterBounds(targetText, bounds) 
    end  
    
    if target and target.icon then
        local targetIcon = CreateFillIcon(textGroup, target.icon, target.iconSize, target.fontColor)
        LayoutHelpers.LeftOf(targetIcon, targetText, 5)
        --LayoutHelpers.AtTopIn(targetIcon, targetText, -2) 
        bounds = GetCenterBounds(targetIcon, bounds) 
    end

    textGroup.Left:Set(function() return bounds.L - 5  end)
    textGroup.Top:Set(function() return bounds.T - 5 end)
    textGroup.Right:Set(function() return bounds.R + 5 end) 
    textGroup.Bottom:Set(function() return bounds.B + 5 end)
    textGroup:SetAlpha(0, true)
    
    bg:DisableHitTest(true) 
    bg.OnFinished = onFinished
    bg.timeout = 4.0 -- 3.7 --5.0 --
    bg.timein  = bg.timeout - 0.2 --5.0 --
    bg.time = 0
    bg:SetNeedsFrameUpdate(true)
    bg.CloseSoundPlayed = false
    bg.OnFrame = function(self, delta)
        self.time = self.time + delta
        if self.time >= self.timein and self.time < self.timeout then
            if not self.CloseSoundPlayed then
                PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Announcement_Close'}))
                self.CloseSoundPlayed = false
            end
            self.Top:Set(MATH_Lerp(self.time,    self.timein, self.timeout, textGroup.Top(), parentUI.Top()))
            self.Left:Set(MATH_Lerp(self.time,   self.timein, self.timeout, textGroup.Left(), parentUI.Left()))
            self.Right:Set(MATH_Lerp(self.time,  self.timein, self.timeout, textGroup.Right(), parentUI.Right()))
            self.Bottom:Set(MATH_Lerp(self.time, self.timein, self.timeout, textGroup.Bottom(), parentUI.Bottom()))
            self.Height:Set(MATH_Lerp(self.time, self.timein, self.timeout, textGroup.Height(), parentUI.Height()))
            self.Width:Set(MATH_Lerp(self.time,  self.timein, self.timeout, textGroup.Width(), parentUI.Width()))
        elseif self.time < .2 then
            self.Top:Set(MATH_Lerp(self.time, 0, .2, parentUI.Top(), textGroup.Top()))
            self.Left:Set(MATH_Lerp(self.time, 0, .2, parentUI.Left(), textGroup.Left()))
            self.Right:Set(MATH_Lerp(self.time, 0, .2, parentUI.Right(), textGroup.Right()))
            self.Bottom:Set(MATH_Lerp(self.time, 0, .2, parentUI.Bottom(), textGroup.Bottom()))
            self.Height:Set(MATH_Lerp(self.time, 0, .2, parentUI.Height(), textGroup.Height()))
            self.Width:Set(MATH_Lerp(self.time, 0, .2, parentUI.Width(), textGroup.Width()))
        elseif self.time > .2 and self.time < self.timein then
            self.Top:Set(textGroup.Top)
            self.Left:Set(textGroup.Left)
            self.Right:Set(textGroup.Right)
            self.Bottom:Set(textGroup.Bottom)
            self.Height:Set(textGroup.Height)
            self.Width:Set(textGroup.Width)
        end
        
        if self.time > 3 and textGroup:GetAlpha() ~= 0 then
            textGroup:SetAlpha(math.max(textGroup:GetAlpha()-(delta*2), 0), true)
        --elseif self.time > .2 and self.time < 3 and text:GetAlpha() ~= 1 then
        --    textGroup:SetAlpha(math.min(text:GetAlpha()+(delta*2), 1), true)
        elseif self.time > .2 and self.time < 3 and textGroup:GetAlpha() ~= 1 then
            textGroup:SetAlpha(math.min(textGroup:GetAlpha()+(delta*2), 1), true)
        end
        
        if self.time > self.timeout then
            if bg.OnFinished then
                bg.OnFinished()
            end
            bg:Destroy()
            bg.OnFinished = nil
            bg = false
        end
    end
    if import('/lua/ui/game/gamemain.lua').gameUIHidden then
        bg:Hide()
    end
end
 
function Contract()
    if bg then bg:Hide() end
end

function Expand()
    if bg then bg:Show() end
end

function CreateBorder(parent)
    local border = {}
    
    border.tl = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ul.dds'))
    border.tm = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_horz_um.dds'))
    border.tr = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ur.dds'))
    border.ml = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_vert_l.dds'))
    border.mr = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_vert_r.dds'))
    border.bl = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ll.dds'))
    border.bm = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_lm.dds'))
    border.br = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_lr.dds'))
    
    border.tl.Bottom:Set(parent.Top)
    border.tl.Right:Set(parent.Left)
    
    border.bl.Top:Set(parent.Bottom)
    border.bl.Right:Set(parent.Left)
    
    border.tr.Bottom:Set(parent.Top)
    border.tr.Left:Set(parent.Right)
    
    border.br.Top:Set(parent.Bottom)
    border.br.Left:Set(parent.Right)
    
    border.tm.Bottom:Set(parent.Top)
    border.tm.Left:Set(parent.Left)
    border.tm.Right:Set(parent.Right)
    
    border.bm.Top:Set(parent.Bottom)
    border.bm.Left:Set(parent.Left)
    border.bm.Right:Set(parent.Right)
    
    border.ml.Top:Set(parent.Top)
    border.ml.Bottom:Set(parent.Bottom)
    border.ml.Right:Set(parent.Left)
    
    border.mr.Top:Set(parent.Top)
    border.mr.Bottom:Set(parent.Bottom)
    border.mr.Left:Set(parent.Right)
    
    return border
end