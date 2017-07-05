-- task.lua
-- 2016-02-24
-- KevinYuen
-- 处理任务相关数据

local BaseObject = require( "kernels.object" ) 
local CompTask = class(  "CompTask", BaseObject )
local AdvButton = require( "kernels.node.nodeAniButton" )
local SpineButton = require( "kernels.node.nodeSpineButton" )
local XmlSimple = require("kernels.xml.xmlSimple")
-- 激活
function CompTask:Actived()

    CompTask.super.Actived( self )  

    -- 界面绑定
    self.ui_layer = self.bind_scene:FindRoot():getChildByName( "ui_layer" )
    self.pan_task = self.ui_layer:getChildByName( "pan_task" )
    self.listView_task = self.pan_task:getChildByName( "list" )

    self.pan_taskDisplay = self.ui_layer:getChildByName( "pan_taskDisplay" )
    self.listView_taskDisplay = self.pan_taskDisplay:getChildByName("list")
    self.pan_btnTask = self.ui_layer:getChildByName( "btn_task" )
    
    self.btn_task  =  AdvButton.new("task", "advbtn.taskbutton", handler(self, self.OnMouseListener))
    local size = self.pan_btnTask:getContentSize()
    self.pan_btnTask:addChild( self.btn_task )
    self.btn_task:setPosition( size.width/2,  size.height/2 )


    --button 事件注册
    g_methods:ButtonClicked( self.pan_task, "btn_close",  handler(self, self.OnViewClosed))
    self.btn_more = g_methods:ButtonClicked( self.pan_taskDisplay, "btn_more",  handler(self, self.OnMoreBtnClick))


    -- 消息监听列表
    self.msg_hookers = {         
        { E_CLIENT_OPETASKVIEW,         handler( self, self.OnViewOpened) },
        { E_HALL_TASKLIST,              handler( self, self.OnTaskList)},
        { E_HALL_TASKOPENTREASURE,      handler( self, self.OnOpenTaskTreasure)},
        { E_HALL_TASKUPDATE,            handler( self, self.OnTaskUpdate)},
        { E_CLIENT_ICOMEIN,             handler( self, self.onRecvSefComin ) },
    }
    g_event:AddListeners( self.msg_hookers, "comptask_events" )

    self.pan_task:openMouseTouch(true, self, true, true)
    self.pan_taskDisplay:openMouseTouch(true, self)
     self.pan_btnTask:openMouseTouch(true, self)
    
    self.lstTaskItemView = {}
    self.lstPopDisplayTaskItemView = {}
    self.lstTask = {}
        
    return true

end

--玩家坐下
function CompTask:onRecvSefComin( event_id, event_args )
    self.pan_btnTask:setVisible( not jav_iswatcher( jav_self_uid ) )
    if  event_args.uid == jav_self_uid then
         if jav_iswatcher(jav_self_uid)== false then 
            self:RequsetTaskList()
              
        else
              self.pan_btnTask:setVisible( false )
        end
    
    end
end

--请求任务列表
function CompTask:RequsetTaskList()
    local msg = { key = "cmd", context = E_HALL_REQTASKLIST }
    jav_room.main_connect:SendFrameMsg( json.encode( msg ) )
end

--请求任务列表的返回
function CompTask:OnTaskList( event_id, event_args )
    g_methods:log("任务列表信息")
    self.lstTask = {}
    self:ClearAllTaskListView()

    self:ParserXml( event_args )    

    self:InitPopTaskDisplayView()
    self:InitTaskView()
   
    self:UpdateAllTaskListView()
end

--请求打开任务的返回
function CompTask:OnOpenTaskTreasure( event_id, event_args )

    g_methods:log("打开任务")   
    self:ClearAllTaskListView()
    self:ParserXml( event_args )    
    self:InitPopTaskDisplayView()
    self:InitTaskView()
    self:UpdateAllTaskListView()
end


--任务更新
function CompTask:OnTaskUpdate(  event_id, event_args  )

    g_methods:log( "任务更新" )
    --
    self:ParserXml( event_args )
    self:UpdateAllTaskListView()
  
end

--领取
function CompTask:OnPickUpReward( sender, args )
    local msg = { key = "cmd", context = E_HALL_REQTASKOPENTREASURE, p1 = sender:getParent().taskId }
    jav_room.main_connect:SendFrameMsg( json.encode( msg ) )
end


--请求打开任务
function CompTask:RequestOpenTaskTreasure( taskId )
    local msg = { key = "cmd", context = E_HALL_REQTASKOPENTREASURE, p1 = taskId }
    jav_room.main_connect:SendFrameMsg( json.encode( msg ) )
end



--打开 VIEW 
function CompTask:OnViewOpened( event_id, event_args )
    self.ui_main:setVisible( true )
end


--关闭 VIEW
function CompTask:OnViewClosed( sender, args )
    self.pan_task:setVisible( false )
end


-- 鼠标按下
function CompTask:onMouseTouchDown(  location, args  )
     if self.btn_task then
         self.btn_task:onMouseTouchDown( location, args )
      end
end

-- 鼠标弹起
function CompTask:onMouseTouchUp( location, args )

    if self.pan_task:hitTest( location ) == false then 
        self.pan_task:setVisible( false )
    end
    if self.btn_more:hitTest( location ) == true  and  self.pan_taskDisplay:isVisible() then 
        self.pan_task:setVisible( true )
    end
   if self.btn_task then
    
         self.btn_task:onMouseTouchUp( location, args )
    end
    
end

--更多
function CompTask:OnMoreBtnClick( location, args )
    self.pan_task:setVisible( true )
end

-- 鼠标滚动
function CompTask:onMouseTouchMove( location, args  )
     if self.btn_task then

        local ret_btn_task = self.btn_task:onMouseTouchMove( location, args )
    
    if self.btn_task:getAnimationNode():isPickup( location ) == true then    
            self.pan_taskDisplay:setVisible( true )
         return
    end
        end
    
    if self.pan_taskDisplay:hitTest( location ) == false and self.pan_taskDisplay:isVisible( ) then
    
        self.pan_taskDisplay:setVisible( false )
    end
    
end


-- 触摸事件处理
function CompTask:OnMouseListener( sender, btnState )
    if btnState == "pressedUp" then
        self.pan_task:setVisible( true )
        self.pan_taskDisplay:setVisible( false )  
    end
end



--鼠标悬停在任务button 任务显示
function CompTask:InitPopTaskDisplayView()
    local item = self.pan_taskDisplay:getChildByName( "item" )
    local panSize = self.pan_taskDisplay:getContentSize()
    local listViewSize = self.listView_taskDisplay:getContentSize()
    if #self.lstTask <= 5 then
        self.btn_more:setVisible( false )
    else
        self.btn_more:setVisible( true )
    end
    local ADDITEM = function ( task )
        local temp = item:clone()
        temp:setVisible( true )
        temp.taskId = task.taskId 
        temp.totalTask = task.totalTask
        self.listView_taskDisplay:pushBackCustomItem(temp)
        self.lstPopDisplayTaskItemView[ temp.taskId] = temp
    end
    for idx, task in pairs( self.lstTask ) do 
    
        if task.taskState ~= 3 then
            ADDITEM(task)
       end
    end

    --已领取
    for idx, task in pairs( self.lstTask ) do 
        if task.taskState == 3 then
             ADDITEM(task)
       end
    end
    self.listView_taskDisplay:setJumpToBottom(false)
    self.listView_taskDisplay:refreshView() 
end

-- 任务显示
function CompTask:InitTaskView()    
    local item = self.pan_task:getChildByName( "item" )  
    local ADDITEM = function ( task )
        local temp = item:clone()
        temp:setVisible( true )
        temp.taskId = task.taskId 

        g_methods:ButtonClicked( temp, "btn_pickup",  handler(self, self.OnPickUpReward))
        temp.totalTask = task.totalTask
        self.listView_task:pushBackCustomItem(temp)
        self.lstTaskItemView[ temp.taskId] = temp
    end

    for idx, task in pairs( self.lstTask ) do 
        if task.taskState ~= 3 then
             ADDITEM(task)
        end
    end
    
    --完成
    for idx, task in pairs( self.lstTask ) do 
        if task.taskState == 3 then
          ADDITEM(task)
        end
    end
    
    self.listView_task:setJumpToBottom(false)
    self.listView_task:refreshView() 
end



--更新任务数据
function CompTask:UpdateTaskViewData()

    for idx, task in pairs(self.lstTask) do
        local item =  self.lstTaskItemView[task.taskId]
        if item then 
            local lbl_taskname = item:getChildByName("lbl_taskname")
            local lbl_arward = item:getChildByName("lbl_arward")
            local lbl_prisetype = item:getChildByName("lbl_prisetype")
            local lbl_process = item:getChildByName("lbl_process")
            local lbl_arward = item:getChildByName("lbl_arward")
            local btn_pickup = item:getChildByName("btn_pickup") 
            
            if task.taskDescribe then
                lbl_taskname:setString(task.taskDescribe)
            end
            
            if task.taskAward then
               lbl_arward:setString(task.taskAward)
            end
            
            lbl_prisetype:setString(jav_bg2312_)

            if task.taskState == 1 then 
                if task.taskType == 14 then 
                    lbl_process:setString( "0/1" )
                else
                    if task.totalTask then
                        lbl_process:setString(task.taskProcess.."/"..task.totalTask)
                    end
                end
            elseif task.taskState == 2 then 
                local lbl_process = item:getChildByName("lbl_process")
                local btn_pickup = item:getChildByName("btn_pickup")
                lbl_process:setVisible( false )
                btn_pickup:setVisible( true )
            elseif task.taskState == 3 then 
                local img_finished = item:getChildByName("img_finished")
                local btn_pickup = item:getChildByName("btn_pickup")
                btn_pickup:setVisible( false )
                img_finished:setVisible( true )
            end
        end
    end
    self.listView_task:updateSizeAndPosition()

end

--更新任务提示面板数据
function CompTask:UpdatePopDisplayTaskViewData()

    for idx, task in pairs(self.lstTask) do
        ---
        local item = self.lstPopDisplayTaskItemView[task.taskId]
        if item then 
            local lbl_taskname = item:getChildByName("lbl_taskname")
            local lbl_process = item:getChildByName("lbl_process")
            if task.taskDescribe then
                 lbl_taskname:setString(task.taskDescribe)
            end
            if task.taskState == 1 then 
                if task.taskType == 14 then 
                    lbl_process:setString( "0/1" )
                else
                    if task.totalTask then
                        lbl_process:setString(task.taskProcess.."/"..task.totalTask)
                    end 
               end
            elseif task.taskState == 2 then 
                lbl_process:setString( g_library:QueryConfig("text.finish") )
            elseif task.taskState == 3 then 
                lbl_process:setString( g_library:QueryConfig("text.pickup") )
            end
        end
    end
    self.listView_taskDisplay:updateSizeAndPosition()
end

--游戏任务达到的动画
function CompTask:PlayTaskAchievedAnimation()
      local isAchievement = false 
	  for idx, task in pairs(self.lstTask) do
	        if task.taskState == 2 then
            isAchievement = true
        end
    end
    if self.sprite_btnTask then
        self.sprite_btnTask:setVisible( false )
        self.sprite_btnTask:stopAllActions()
        self.sprite_btnTask:removeFromParent()
            self.sprite_btnTask = nil
    end
    if isAchievement then
        self.sprite_btnTask = display.newSprite()
        self.pan_btnTask:addChild(  self.sprite_btnTask )
        self.taskAchievedAnim  = g_library:CreateAnimation( "ani.taskAchieve" )    -- 资源
        local size =  self.pan_btnTask:getContentSize() 
        self.sprite_btnTask:setPosition( cc.p( size.width / 2+2, size.height / 2+ 6 ) )
        self.sprite_btnTask:playAnimationForever( self.taskAchievedAnim )    	 
	 end
	  
end

--解析任务数据
function CompTask:ParserXml( args )

    local xml = XmlSimple.newParser()
    if args.xml and args.xml ~="" then 
        local content = xml:ParseXmlText(args.xml) 
        local items = content["item"]
        local SETDATA = function( value )
            local task = {}
            for idx, data in pairs(self.lstTask) do 
                if data.taskId == tonumber(value["@taskId"]) then 
                    task = data
                    break
                end 
            end 
            if task.taskId == nil then
                table.insert(self.lstTask, task)
            end
            
            if  value["@priseType"] then
                task["priseType"] = value["@priseType"]
            end
            if  value["@taskAward"] then
                task["taskAward"] = value["@taskAward"]
            end
            if  value["@taskDescribe"] then
                task["taskDescribe"] = jav_bg2312_utf8(value["@taskDescribe"])
            end
            if  value["@taskId"] then
                task["taskId"] = tonumber(value["@taskId"])
            end
            if  value["@taskName"] then
                task["taskName"] = jav_bg2312_utf8(value["@taskName"])
            end
            if  value["@taskProcess"] then
                task["taskProcess"] = value["@taskProcess"]
            end
            if  value["@taskState"] then
                task["taskState"] = tonumber(value["@taskState"])
            end
            if  value["@totalTask"] then
                task["totalTask"] = value["@totalTask"]
            end
            if  value["@taskType"] then
                task["taskType"] = tonumber(value["@taskType"])
            end  
            
        
        end
        
        --开始
        if #items == 0 then
            SETDATA( items )
            local task = nil
            for idx, data in pairs(self.lstTask) do 
                if data.taskId == tonumber(items["@taskId"]) then 
                    task = data
                    break
                end 
            end 
            if task and task.taskState ==  3 and items["@isDispTask"]  and items["@isDispTask"] == "1" then
                local wtext = g_library:QueryConfig( "text.taskfinished" )
                local content = string.format( wtext, task.taskName, task.taskAward )  
                jav_room:PushSystemLog( content )
            end
        else
        
            for _1, value in pairs(items) do
                SETDATA( value )
            end
       end
    end

end

function CompTask:ClearAllTaskListView()
    self.listView_task:removeAllItems()
    self.lstTaskItemView ={}
    self.listView_taskDisplay:refreshView() 


    self.listView_taskDisplay:removeAllItems()
    self.lstPopDisplayTaskItemView={}
    self.listView_taskDisplay:refreshView() 
end

function CompTask:UpdateAllTaskListView()
    self:UpdatePopDisplayTaskViewData()
    self:UpdateTaskViewData()
    self:PlayTaskAchievedAnimation()
end


-- 反激活
function CompTask:InActived()

    -- 事件监听注销
    g_event:DelListenersByTag( "comptask_events" )

    CompTask.super.InActived( self )
end


return CompTask


