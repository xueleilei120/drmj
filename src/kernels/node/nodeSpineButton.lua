-- redpack_tape.lua
-- 2014-10-20
-- KevinYuen
-- 卡带

local SpineButton = class( "spineButton" ,  function()
    return display.newNode()
end)

-- 构造初始化
function SpineButton:ctor( btnName, spineRes, callback,strcheck )

    self.btnName = btnName
    self.spineRes = spineRes
    
    if strcheck == nil then
        self.strcheck = nil
    else
        self.strcheck = strcheck     -- 保留按下态标志
    end
    self.callback = callback
    
    self:setAnchorPoint(cc.p(0, 0))
    
    -- 默认不支持触摸
    self:setTouchEnabled( false )
    
    self.anim = sp.SkeletonAnimation:create( spineRes..".json", spineRes..".atlas", 1.0 )
    self:removeAllChildren()
    self:addChild( self.anim )


    self.anim:registerSpineEventHandler( function( event ) 
        if event.animation~="normal" and 
            event.animation~="pressed" and
            event.animation~="disabled" and 
            event.animation~="hoverd"  then
            self.anim:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function()
                self:setAnimation("normal", true ) 
                self.animAction = "normal"
             end
            )))
            end
        end, sp.EventType.ANIMATION_COMPLETE )
    
    self:setAnimation("normal", true ) 
    self.animAction = "normal" 
end

--设置animation  
function SpineButton:setAnimation( name , isLoop )
    self.anim:setToSetupPose()
    self.anim:setAnimation( 0, name, isLoop ) 
end

function SpineButton:SetContentSize( width, height )
    self:setContentSize( cc.size( width,  height))
    self.anim:setPosition( width/2,  height/2)

end


--开启/关闭(鼠标/触摸)
function SpineButton:SetTouchEnabled( enable )
    self:openMouseTouch( enable, self )
    self.animAction = "disabled"
    if enable then
        self.animAction = "normal"
    end

    self:setAnimation( self.animAction, true )
    
end

-- 设置为正常态
function SpineButton:onSetNormal()
    self:setAnimation("normal",true)
    self.animAction = "normal"
end

-- 设置骨骼按钮为透明态(即按下态)
function SpineButton:setClarity()
    self:setAnimation("pressed",false)
    self.animAction = "pressed"
end

--
-- 鼠标按下
function SpineButton:onMouseTouchDown( location, args )
    
    if self:isPickup( location ) then         
        self:setAnimation("pressed",  true )
        -- 如果按钮已经是按下状态，再次点击就不处理
        if self.animAction == "pressed" then
            return true
        end
        
        if self.callback then 
            self.callback( self, "pressedDown" )
        end
        self.animAction = "pressed"
        return true
    end 
        return false
end

-- 鼠标弹起
function SpineButton:onMouseTouchUp( location, args )
    
    if self:isPickup( location ) then 
        if self.strcheck == "checkbox" then
            self:setAnimation("pressed",  true )
            self.animAction = "pressed"
        else
            self.animAction = "hoverd"
            self:setAnimation( self.animAction, true )
        end
         
        if self.callback then 
            self.callback( self, "pressedUp" )
        end
        return true
    end 
        return false
end

-- 鼠标滚动
function SpineButton:onMouseTouchMove( location, args )

    local animAction = "normal"
    if self:isPickup( location ) then 
        animAction = "hoverd"                
    end 
    
    -- 如果包含check属性，则特殊处理
    if self.strcheck == "checkbox" then
        if self.animAction == "pressed" then
            animAction = "pressed"
        end
    else
    end
    
    --设置Button 动画
    if animAction == self.animAction then
        return false
    end

    self.animAction = animAction
    self:setAnimation( self.animAction, true )
    
    -- callback
    if self.callback then 
        self.callback( self, animAction )
    end
    return true
end

function SpineButton:getAnimationNode()
	  return self.anim
end

function SpineButton:onExit()

    self:openMouseTouch( false, self )
end

return SpineButton