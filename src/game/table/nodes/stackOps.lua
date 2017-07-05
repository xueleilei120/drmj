-- redpack_tape.lua
-- 2014-10-20
-- KevinYuen
-- 卡带
local UIAdvButton = require( "kernels.node.nodeAniButton" )
local SpineButton = require( "kernels.node.nodeSpineButton" )


local MJOpers = class( "MJOpers")

-- 排列方式
MJOpers.SCHEME_L2R     = "SCHEME_L2R"      -- 从左到右(右压左)
MJOpers.SCHEME_R2L     = "SCHEME_R2L"      -- 从右到左(左压右)

-- 对齐方式
MJOpers.ALIGN_CENTER   = "ALIGN_CENTER"    -- 居中
MJOpers.ALIGN_LEFTTOP  = "ALIGN_LEFTTOP"   -- 左上
MJOpers.ALIGN_RIGHTDN  = "ALIGN_RIGHTDN"   -- 右下

-- 构造初始化
function MJOpers:ctor( node , callback)

    self.redpack_size = { width=86, height = 86}
    self.redpack_dim={74,0}
    self.offset = {0, 0}
    
    self.node = node
    self.lstItemNodes = {}
    self.align_type = MJOpers.ALIGN_RIGHTDN
    
    self.callback = callback

end

--显示
function MJOpers:Show( operFlag )

    self:Clear()
    --弃
    if operCanCancel( operFlag ) then
        self:AddItem( "qi", operFlag )
    end
    
    --杠
    if operCanGang( operFlag ) then
        self:AddItem( "gang", operFlag ,"checkbox")
    end

    --碰
    if operCanPeng( operFlag ) then
        self:AddItem( "peng", operFlag,"checkbox")
    end
    --吃
    if operCanChi( operFlag ) then
        self:AddItem( "chi", operFlag,"checkbox" )

    end

	--听
    if operCanTing( operFlag ) then
        self:AddItem( "ting", operFlag,"checkbox" )
    end
    
    
    self.node:runAction(cc.Sequence:create( cc.DelayTime:create(0.5), cc.CallFunc:create(function()
        self:SetMouseEnabled( true )
    end
    )))
end

--清除所有操作
function MJOpers:Clear()
    for idx = 1,  #self.lstItemNodes do
        local pan_item = self.node:getChildByName("oper_"..idx)
         pan_item:setVisible(false)
         pan_item:removeAllChildren()
    end
    self.lstItemNodes = {}
end

-- 是否在显示
function MJOpers:isShow()
    return #self.lstItemNodes > 0
end

--关闭
function MJOpers:Close(  )
   self:SetMouseEnabled( false )
   self:Clear()
end

-- 删除操作行为
function MJOpers:DeleteItem(name)
    for idx =1,#self.lstItemNodes do
        if self.lstItemNodes[idx].oper == name then
            table.remove(self.lstItemNodes,idx)
            local pan_item = self.node:getChildByName("oper_"..idx)
            pan_item:setVisible(false)
            pan_item:removeAllChildren()
            break
        end
    end
end

--增加操作行为
-- strcheck 设置为checkbox样式
function MJOpers:AddItem( name, flag,strcheck )

    local item = SpineButton.new( name, name, handler(self, self.OnMouseListener),strcheck )
    table.insert(self.lstItemNodes,item)
    local pan_item = self.node:getChildByName("oper_"..#self.lstItemNodes)
    pan_item:setVisible(true)
    local size = pan_item:getContentSize()
    item:SetContentSize(size.width,  size.height)
    item.oper = name
    item.operFlag = flag
    pan_item:addChild( item, 0, 0 )
    item:setAnimation( "chuchang", false )
    
end

-- 开启/关闭鼠标监听
function MJOpers:SetMouseEnabled( enable )

    self.node:openMouseTouch( enable, self )
   
end

-- 鼠标按下
function MJOpers:onMouseTouchDown(  location, args  )

    for idx, item in pairs( self.lstItemNodes ) do
        item:onMouseTouchDown( location, args )
    end
end

-- 鼠标弹起
function MJOpers:onMouseTouchUp( location, args )

    for idx, item in pairs( self.lstItemNodes ) do 
        local ret = item:onMouseTouchUp( location, args )
        if ret then
            return
        end
    end


end

-- 鼠标滚动
function MJOpers:onMouseTouchMove( location, args  )

    local foucsItem = nill
    for idx, item in pairs( self.lstItemNodes ) do
        local parent = item:getParent()
        if parent:hitTest(location) == false then
            local ret = item:onMouseTouchMove(location, args )
         else 
            foucsItem = item
         end
    end
    if foucsItem then
        foucsItem:onMouseTouchMove(location, args )
    end

end

-- 重新设置所有按钮的初始状态
function MJOpers:setAllItemNormal()
    for idx,item in pairs(self.lstItemNodes) do
       item:onSetNormal()
    end
end

-- 设置按钮的透明态
---------------------------
--@param 需要设置按钮的名字
--@return nil
function MJOpers:setClarity( btntype)
    for _,item in pairs(self.lstItemNodes) do
       if item.oper == btntype then
           item:setClarity()
       end
    end
end

-- 触摸事件处理
function MJOpers:OnMouseListener( sender, btnState )
    if btnState == "pressedUp" then
        if self.callback then
            self.callback( sender.oper, "click" )
        end
    end
    
    --焦点在button 上
    if btnState == "hoverd" then
        if self.callback then
            self.callback( sender.oper, "focused" )
        end
    end
    
    --焦点不在button 上
    if btnState == "normal" then
        if self.callback then
            self.callback( sender.oper, "unfocused" )
        end
    end
end

return MJOpers