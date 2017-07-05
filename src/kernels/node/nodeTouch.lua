-- touch.lua
-- 2016-03-02
-- KevinYuen
-- 触摸控制


----------------------------------------------------------------------------------------
-- cc.Node平台级触摸扩展
----------------------------------------------------------------------------------------

local c = cc
local Node = c.Node

-- 开启触摸监听
function Node:openMouseTouch( opend, listener, exclusive, onlyHitted )
    
    -- 重复监听触摸事件
    if opend and self.mouseTouchHandle then
        g_methods:warn( "重复监听触摸事件!" )
        return
    end
    
    local dispatcher = self:getEventDispatcher()
    
    -- 先注销
    if self.mouseTouchHandle then
        dispatcher:removeEventListener( self.mouseTouchHandle )
        self.mouseTouchHandle = nil
        self.mousetTouchListener = nil
    end
    
    if opend == false then
        return
    end
    
    self.mousetTouchListener = listener
    self.mouseTouchExclusive = exclusive or false
    self.mouseTouchExclusiveOnlyHitted = onlyHitted or false
    self:setTouchEnabled( self.mouseTouchExclusive )
    self:setTouchSwallowEnabled( self.mouseTouchExclusive )
    
    -- PC平台下监听鼠标
    if device.platform == "windows" or device.platform == "mac" then

        local mouse_listener = cc.EventListenerMouse:create()
        mouse_listener:registerScriptHandler(   function( event )
                                                    local parent = self
                                                    while true do 
                                                        if parent:isVisible() == false then
                                                               return 
                                                        end
                                                        parent = parent:getParent()
                                                        if parent == nil then
                                                            break
                                                        end
                                                    end
        
                                                    if  self.mousetTouchListener and 
                                                        self.mousetTouchListener.onMouseTouchDown then
                                                        self.mousetTouchListener:onMouseTouchDown( event:getLocationInView(), event:getMouseButton() )
                                                    end 
                                                    
                                                    if  self.mouseTouchExclusive then
                                                        if  self.mouseTouchExclusiveOnlyHitted == false or
                                                           (self.mouseTouchExclusiveOnlyHitted == true and self:hitTest( event:getLocationInView() ) ) then
                                                            event:stopPropagation()
                                                        end
                                                    end
                                                    
                                                end, cc.Handler.EVENT_MOUSE_DOWN )
                                                
        mouse_listener:registerScriptHandler(   function( event )

                                                    local parent = self
                                                    while true do 
                                                        if parent:isVisible() == false then
                                                               return 
                                                        end
                                                        parent = parent:getParent()
                                                        if parent == nil then
                                                            break
                                                        end
                                                    end
                                                    
                                                    if  self.mousetTouchListener and 
                                                        self.mousetTouchListener.onMouseTouchUp then
                                                        self.mousetTouchListener:onMouseTouchUp( event:getLocationInView(), event:getMouseButton() )
                                                    end 
                                                    
                                                    if  self.mouseTouchExclusive then
                                                        if  self.mouseTouchExclusiveOnlyHitted == false or
                                                           (self.mouseTouchExclusiveOnlyHitted == true and self:hitTest( event:getLocationInView() ) ) then
                                                            event:stopPropagation()
                                                        end
                                                    end
                                                    
                                                end, cc.Handler.EVENT_MOUSE_UP )
                                                
        mouse_listener:registerScriptHandler(   function( event )
                                                    
                                                   local parent = self
                                                    while true do 
                                                        if parent:isVisible() == false then
                                                               return 
                                                        end
                                                        parent = parent:getParent()
                                                        if parent == nil then
                                                            break
                                                        end
                                                    end
                                                    
                                                    if  self.mousetTouchListener and 
                                                        self.mousetTouchListener.onMouseTouchMove then
                                                        self.mousetTouchListener:onMouseTouchMove( event:getLocationInView(), event:getMouseButton() )
                                                    end 
                                                    
                                                    if self.mouseTouchExclusive then
                                                        if  self.mouseTouchExclusiveOnlyHitted == false or
                                                           (self.mouseTouchExclusiveOnlyHitted == true and self:hitTest( event:getLocationInView() ) ) then
                                                            event:stopPropagation()
                                                        end
                                                    end
                                                    
                                                end, cc.Handler.EVENT_MOUSE_MOVE )

        self.mouseTouchHandle = mouse_listener
        dispatcher:addEventListenerWithSceneGraphPriority( mouse_listener, self )
    
    -- 移动平台下监听触摸
    else
    
        local touch_listener = cc.EventListenerTouchOneByOne:create()
        
        touch_listener:registerScriptHandler(   function( event )
        
                                                    if  self:isVisible() == false then
                                                        return
                                                    end
                                                    
                                                    if  self.mousetTouchListener and 
                                                        self.mousetTouchListener.onMouseTouchDown then
                                                        self.mousetTouchListener:onMouseTouchDown( event:getLocationInView() )
                                                    end 
                                                    
                                                    if  self.mouseTouchExclusive then
                                                        event:stopPropagation()
                                                    end
                                                    
                                                end, cc.Handler.EVENT_TOUCH_BEGAN )
                                                
        touch_listener:registerScriptHandler(   function( event )
                                                    
                                                    if  self:isVisible() == false then
                                                        return
                                                    end
                                                    
                                                    if  self.mousetTouchListener and 
                                                        self.mousetTouchListener.onMouseTouchUp then
                                                        self.mousetTouchListener:onMouseTouchUp( self, event:getLocationInView() )
                                                    end 
                                                    
                                                    if  self.mouseTouchExclusive then
                                                        event:stopPropagation()
                                                    end
                                                    
                                                end, cc.Handler.EVENT_TOUCH_ENDED )

        self.mouseTouchHandle = touch_listener
        dispatcher:addEventListenerWithSceneGraphPriority( touch_listener, self )
        
    end
        
end

function Node:isPickup( point, isCascade)

    local nsp = self:convertToNodeSpaceAR(point)
    local rect
    if isCascade then
        rect = self:getCascadeBoundingBox()
    else
        rect = self:getBoundingBox()
    end

    if cc.rectContainsPoint(rect, nsp) then
        return true
    end
    return false
	
end

function Node:hitTestHor( point )

    local nsp = self:convertToNodeSpace(point)
    local rect = self:getCascadeBoundingBox()
    return nsp.x >= 0 and nsp.x <= rect.width    

end