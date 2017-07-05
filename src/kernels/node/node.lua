-- node.lua
-- 2014-10-31
-- KevinYuen
-- 基础场景节点

local BaseNode = class( "BaseNode",
    function()
        local node = display.newNode()
        node:setCascadeColorEnabled( true )
        return node
    end )

-- 行为控制器Tag定义
BaseNode.ActionTag = {
    tagSpeedMove = 888,  -- 变速移动
}

-- 初始化
function BaseNode:OnCreate( args )

    -- 变量初始化
    self.body_node = nil                -- 身体节点 
    self.raw_scale = 1.0                -- 原始缩放比例
    self.is_selected = false            -- 是否被选中
    self.is_moving = false              -- 是否移动中
    self.is_paused = false              -- 是否暂停中
    self.configs = {}                   -- 配置属性表
    self.move_pts = {}                  -- 移动路径点
    self:setTag( self.obj_tag )

    -- 行为状态机创建
    self.action_fsm = {}
    cc.GameObject.extend( self.action_fsm )
        : addComponent( "components.behavior.StateMachine" )
        : exportMethods()
        
end

-- 销毁
function BaseNode:OnDestroy() 
end

-- 具体对象加载
function BaseNode:ConfigObject( obj_props )

    -- 属性表拷贝初始化
    g_methods:CopyTable( obj_props, self.configs )
    g_methods:debug( "对象[%s]配置成功...", g_methods:ObjectDetail( self ) )
    return true

end

-- 获取状态对应的动作
function BaseNode:GetActionId( state_name )

    -- 获取状态动作映射表
    local states_map = self.configs["action_states"]
    if not states_map then
        g_methods:error( "没有找到对象[%s]关于行为状态的配置表信息...", g_methods:ObjectDetail( self ) )
        return ""
    end

    -- 查找表项
    local action_id = states_map[state_name]
    if action_id == "" then
        g_methods:error( "没有找到对象[%s]关于状态[%s]的动作配置信息...", g_methods:ObjectDetail( self ), state_name )
        return ""        
    end

    return action_id

end

-- 状态设定
function BaseNode:SetState( state_id, set_args )

    -- 相同状态不重复设定
    local now_state = self.action_fsm:getState()
    if now_state == state_id then
        return true
    end

    if not self.action_fsm:canDoEvent( state_id ) then
        g_methods:warn( "对象[%s]状态设定失败,[%s] to [%s]...", g_methods:ObjectDetail( self ), self.action_fsm:getState(), state_id )
        return false
    end

    local ret = self.action_fsm:doEvent( state_id, set_args )
    -- StateMachine.SUCCEEDED = 1
    if ret == 1 then
        g_methods:debug( "对象[%s]状态设定成功,[%s]...", g_methods:ObjectDetail( self ), state_id )
        return true
    else
        g_methods:warn( "对象[%s]状态设定失败[%d],[%s] to [%s]...", g_methods:ObjectDetail( self ), ret, self.action_fsm:getState(), state_id )
        return false
    end
end

-- 获取状态
function BaseNode:GetState()
    return self.action_fsm:getState()
end

-- 状态切换前
function BaseNode:OnStateChangeBefore( event )
    g_methods:debug( "[FMS] BEFORE EVENT(%s) %s to %s", event.name, event.from, event.to )
end

-- 状态切换后
function BaseNode:OnStateChangeAfter( event )
    g_methods:debug( "[FMS] AFTER EVENT(%s) %s to %s", event.name, event.from, event.to )
end

-- 进入某状态
function BaseNode:OnEnterState( event )
    g_methods:debug( "[FMS] ENTER STATE %s to %s", event.from, event.to )
end

-- 离开某状态
function BaseNode:OnLeaveState( event )
    g_methods:debug( "[FMS] LEAVE STATE %s to %s", event.from, event.to )
end

-- 当前状态改变
function BaseNode:OnCurrentStateChanged( event )
    g_methods:debug( "[FMS] CHANGE STATE %s to %s", event.from, event.to )
    local action_id = self:GetActionId( event.to )
    self:DoAction( action_id )
end

-- 做动作(外部不要直接调用)
function BaseNode:DoAction( action_id )
end

-- 停止动作(外部不要直接调用) 
function BaseNode:StopAction()
end

-- 移动到目标
function BaseNode:MoveTo( tar_x, tar_y, ime )
    self:MoveToEx( tar_x, tar_y, 1.0, ime )
end

-- 移动到目标
function BaseNode:MoveToEx( tar_x, tar_y, _scale, ime )

    -- 暂停中不能移动
    if self.is_paused == true then
        g_methods:warn( "对象[%s]暂停中,无法移动...", g_methods:ObjectDetail( self ) )
        return
    end

    -- 如果是即时移动,清空路径点
    if ime == true then
        self.move_pts = {}
    end

    -- 新路径点加入
    local new_pt = {
        x = tar_x,
        y = tar_y,
        scale = _scale
    }
    table.insert( self.move_pts, new_pt )

    -- 新路径点弹出
    if self.is_moving == false then
        self:PopMovePt()
        self.is_moving = true
    end

end

-- 路径点弹出
function BaseNode:PopMovePt()

    -- 如果路径点空了
    if #self.move_pts == 0 then
        -- 如果移动中,那么移动结束
        if self.is_moving then
            self:OnMoveDone()
        end
    else
        -- 计算距离
        local next_pt = self.move_pts[1]
        local now_posx, now_posy = self:getPosition()
        local distance = cc.pGetDistance( cc.p( next_pt.x, next_pt.y ), cc.p( now_posx, now_posy ) )
        -- 速度获取(speed=像素/秒)
        local speed = self.configs["move_speed"] 
        if speed <= 0.1 then
            speed = 1
        end
        -- 耗时计算
        local move_sec = distance / speed
        -- 删除老得移动控制器
        if self:getActionByTag( BaseNode.ActionTag.tagSpeedMove ) then
            self:stopActionByTag( BaseNode.ActionTag.tagSpeedMove )
        end
        -- 创建新移动控制器
        local moveto = cc.MoveTo:create( move_sec, cc.p( next_pt.x, next_pt.y ) )
        local scaleby = cc.ScaleBy:create( move_sec, next_pt.scale )
        local spawn = cc.Spawn:create( { moveto, scaleby } )
        local callback = cc.CallFunc:create( handler( self, self.PopMovePt ) )
        local sequence = cc.Sequence:create( { spawn, callback } )
        local speedmove = cc.Speed:create( sequence, 1.0 )
        speedmove:setTag( BaseNode.ActionTag.tagSpeedMove )
        self:runAction( speedmove )
        table.remove( self.move_pts, 1 )
    end

end

-- 停止移动
function BaseNode:StopMove()
    -- 路径点清空
    self.move_pts = {}
    self.is_moving = false
    -- 删除老得移动控制器
    if self:getActionByTag( BaseNode.ActionTag.tagSpeedMove ) then
        self:stopActionByTag( BaseNode.ActionTag.tagSpeedMove )
    end
end

-- 是否在移动
function BaseNode:IsMoving()
    return self.is_moving
end

-- 是否在移动
function BaseNode:OnMoveDone()

    self.is_moving = false
    
    -- 消息发布
    g_event:SendEvent( ESE_OBJECT_ARRIVED, { object = self } )
    
end

-- 设定选中
function BaseNode:SetSelected()
    self.is_selected = true
end

-- 取消选中
function BaseNode:CancelSelected()
    self.is_selected = false
end

-- 是否被选中
function BaseNode:IsSelected()
    return self.is_selected
end

-- 暂停
function BaseNode:Paused( pause_all )
    self:pause()
    self.is_paused = true
    if pause_all then
        local children = self:getChildren()
        for i=1, #children do
            local child = children[i]
            child:pause()
        end
    end
end

-- 恢复
function BaseNode:Resumed( resume_all )
    if resume_all then
        local children = self:getChildren()
        for i=1, #children do
            local child = children[i]
            child:resume()
        end
    end
    self:resume()
    self.is_paused = false
end

-- 是否暂停中
function BaseNode:IsPaused()
    return self.is_paused
end

-- 创建动画精灵
function BaseNode:CreateAnimator( anim_id, loop )

    -- 动画查找
    local animation = g_library:CreateAnimation( anim_id )
    if not animation then
        return nil
    end

    -- 动画精灵点创建
    local ani_sprite = cc.Sprite:create()
    if loop == true then
        ani_sprite:playAnimationForever( animation )
    else
        ani_sprite:playAnimationOnce( animation, true )
    end
    ani_sprite:setName( "ani_" .. anim_id )

    return ani_sprite
end

-- 播放辅助动画
function BaseNode:PlayAnimation( anim_id, offset, loop )

    -- 动画精灵创建
    local ani_sprite = self:CreateAnimator( anim_id, loop )
    ani_sprite:setPosition( offset.x, offset.y )
    self:addChild( ani_sprite ) 

    return ani_sprite

end

-- 关闭辅助动画
function BaseNode:StopAnimation( anim_id )

    local ani_sprite = self:getChildByName( "ani_" .. anim_id )
    if not ani_sprite then
        g_methods:warn( "对象[%s]关闭辅助动画失败,动画[%s]不存在...", g_methods:ObjectDetail( self ), anim_id )
        return false
    end

    ani_sprite:removeFromParent()
    return true

end

-- 设置原始缩放比例
function BaseNode:SetRawScale( scale )
    self.raw_scale = scale
end

-- 获取原始缩放比例
function BaseNode:GetRawScale( scale )
    return self.raw_scale
end

return BaseNode