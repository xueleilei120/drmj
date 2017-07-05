
--[[

Copyright (c) 2011-2014 chukong-inc.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

--------------------------------
-- @module AdvanceButton

--[[--

AdvanceButton Button控件

]]

local AdvanceButton = class("AdvanceButton", function()
    return display.newNode()
end)


function AdvanceButton:ctor(btnName, animRes, callback)
    self.btnName = btnName
    self.animRes = animRes
    self.callback = callback
    self.animSprite = cc.Sprite:create()
    self:addChild( self.animSprite )
    --   self:openMouseTouch( true, self )

    self.animAction = "normal"
    self:SetAnimation( self.animAction ) 

end


--
-- 鼠标按下
function AdvanceButton:onMouseTouchDown( location, args )

    if self.animSprite:isPickup( location ) then 
        self:SetAnimation( "pressed" )

        if self.callback then 
            self.callback( self,  "pressedDown" )
        end
        self.animAction = "pressed"
        return true
    end 
        return false
end

-- 鼠标弹起
function AdvanceButton:onMouseTouchUp( location, args )

    if self.animSprite:isPickup( location ) then 

        self.animAction = "hoverd"
        self:SetAnimation( "hoverd" )
        if self.callback then 
            self.callback( self,  "pressedUp" )
        end
        return true
    end 
        return false
end

-- 鼠标滚动
function AdvanceButton:onMouseTouchMove( location, args )

    local animAction = "normal"
    if self.animSprite:isPickup( location ) then 
        animAction = "hoverd"
    end 
    --设置Button 动画
    if animAction == self.animAction then
        return false
    end
    self:SetAnimation( animAction )
    self.animAction = animAction
    -- callback
    if self.callback then 
        self.callback( self,  self.animAction )
    end
    return true
end


--开启/关闭(鼠标/触摸)
function AdvanceButton:SetTouchEnabled( enable )
    self:openMouseTouch( enable, self )
    self.animAction = "disabled"
    if enable then
        self.animAction = "normal"
    end
    self:SetAnimation( self.animAction )

end

function AdvanceButton:SetAnimation( animName )

    if self.anim_action and self.animSprite then
        self.animSprite:stopAction( self.anim_action )
        self.anim_action = nil
    end
    if animName then 
        local anim_config, faild_reason = g_library:QueryConfig( self.animRes )
        if not anim_config then
            g_methods:warn( faild_reason )
            return nil
        end

        local animation =g_library:CreateAnimationEx(anim_config[animName])
        if animation then 
            self.anim_action = self.animSprite:playAnimationForever(animation, animName)
        end
    end
end

function AdvanceButton:getAnimationNode()
      return self.animSprite
end

function AdvanceButton:onExit()
	self:setMouseEnabled(false)
end

return AdvanceButton
