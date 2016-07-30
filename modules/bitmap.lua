-- Class methods:
-- SetTexture(filename(s), border=1)
-- SetSolidColor(color)
-- SetUV(float u0, float v0, float u1, float v1)
-- SetTiled(bool)
-- UseAlphaHitTest(bool)
-- Loop(bool)
-- Play()
-- Stop()
-- SetFrame(int)
-- int GetFrame()
-- int GetNumFrames()
-- SetFrameRate(float fps)
-- SetFramePattern(pattern)
    -- pattern is an array of integers reflecting texture indicies
-- SetForwardPattern()
-- SetBackwardPattern()
-- SetPingPongPattern()
-- SetLoopPingPongPattern()
-- ShareTextures(bitmap) -- allows two bitmaps to share the same textures

-- Frame patterns are arrays that indicate what texture to play at a particular frame index
-- Textures are indexed by the order you pass them in to SetTexture. Note that frames are
-- 0 based, not 1 based.

-- related global function (returns nil if file not found)
-- width, height GetTextureDimensions(filename)

------------------------------------------------------
-- HUSSAR added SetHighlight(bool, float, float)

local Control = import('/lua/maui/control.lua').Control
--TODO-FAF replace above with the following
--local Control = import('control.lua').Control

Bitmap = Class(moho.bitmap_methods, Control) {

    __init = function(self, parent, filename, debugname)
        InternalCreateBitmap(self, parent)
        if debugname then
            self:SetName(debugname)
        end

        local LazyVar = import('/lua/lazyvar.lua')
        self._filename = {_texture = LazyVar.Create(), _border = 1}
        self._color = LazyVar.Create()
        self._color.OnDirty = function(var)
            self:InternalSetSolidColor(self._color())
        end
        self._filename._texture.OnDirty = function(var)
            self:SetNewTexture(self._filename._texture(), self._filename._border)
        end

        if filename then
            self:SetTexture(filename)
        end

        self._highlightEnabled = false
        self._highlightAlphaEnter = 0.8
        self._highlightAlphaExit  = 1.0

        self._soundEnabled = false
        self._soundOverCue = nil
        self._soundClickCue = nil
    end,

    SetTexture = function(self, texture, border)
        if self._filename then
            border = border or 1
            self._filename._border = border
            self._filename._texture:Set(texture)
        end
    end,
    
    SetSolidColor = function(self, color)
        self._color:Set(color)
    end,

    -- set highlight of bitmap on mouse enter/exit events
    SetSounds = function(self, isEnabled, soundClickCue, soundOverCue)
    
        self._soundEnabled = isEnabled
        self._soundOverCue = soundOverCue or 'UI_Tab_Rollover_01'
        self._soundClickCue = soundClickCue or 'UI_Tab_Click_01' 

        self._soundOver  = Sound({Cue = self._soundOverCue, Bank = "Interface",})
        self._soundClick = Sound({Cue = self._soundClickCue, Bank = "Interface",})

    end,

    -- set highlight of bitmap on mouse enter/exit events
    SetHighlight = function(self, isEnabled, alphaEnter, alphaExit)
        --LOG('SetHighlight ' .. tostring(highlightable) .. ' '  .. tostring(alphaEnter) .. ' '  .. tostring(alphaExit) .. ' ' )
        self._highlightEnabled = isEnabled
        self._highlightAlphaEnter = alphaEnter or 0.8
        self._highlightAlphaExit  = alphaExit  or 1.0
        if not isEnabled then
            self:SetAlpha(1, true)
        end
        --LOG('SetHighlight ' .. tostring(self._highlightEnabled) .. ' '  .. tostring(self._highlightAlphaEnter) .. ' '  .. tostring(self._highlightAlphaExit) .. ' ' )
    end,
    
    ResetLayout = function(self)
        Control.ResetLayout(self)
        self.Width:SetFunction(function() return self.BitmapWidth() end)
        self.Height:SetFunction(function() return self.BitmapHeight() end)
    end,

    OnInit = function(self)
        Control.OnInit(self)
    end,
    
    OnDestroy = function(self)
        if self._filename and self._filename._texture then
            self._filename._texture:Destroy()
        end
        self._filename = nil
        if self._color then
            self._color:Destroy()
        end
    end,
    
    -- callback scripts
    OnAnimationFinished = function(self) end,
    OnAnimationStopped = function(self) end,
    OnAnimationFrame = function(self, frameNumber) end,
    
    OnClick = function(self, modifiers)
        return false
    end,    
    
    OnMouseEnter = function(self, event)
        return false
    end,
    
    OnMouseExit = function(self, event)
        return false
    end,
      
    HandleEvent = function(self, event)
        self:HandleHighlight(event)
        self:HandleSound(event)

        if event.Type == 'MouseEnter' then
            return self:OnMouseEnter(event)

        elseif event.Type == 'MouseExit' then
            return self:OnMouseExit(event)

        elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            return self:OnClick(event.Modifiers)
        end
        
        return false
    end,

    HandleSound = function(self, event)
        if not self._soundEnabled then return end

        if event.Type == 'MouseEnter' then 
            if not self._soundOver or 
                   self._soundOverCue == "NO_SOUND" then return end

            --local sound = Sound({Cue = self._soundOverCue, Bank = "Interface",})
            PlaySound(self._soundOver)

        elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            if not self._soundClick or 
                   self._soundClickCue == "NO_SOUND" then return end

             --local sound = Sound({Cue = self._soundClickCue, Bank = "Interface",})
             PlaySound(self._soundClick)
        end 
    end,

    HandleHighlight = function(self, event)
        if not self._highlightEnabled then return end

        if event.Type == 'MouseEnter' then 
            self:SetAlpha(self._highlightAlphaEnter, true) 
        elseif event.Type == 'MouseExit' then 
            self:SetAlpha(self._highlightAlphaExit, true) 
        end
    end,

}

