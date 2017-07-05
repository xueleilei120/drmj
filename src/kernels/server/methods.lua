-- methods.lua
-- 2014-10-28
-- KevinYuen
-- 核心方法定义


local BaseObject = require( "kernels.object" )
local KernelMethods = class( "KernelMethods", BaseObject )

-- 日志等级划分
LOG_LEVEL_DEBUG     = 1
LOG_LEVEL_NORMAL    = 2
LOG_LEVEL_WARN      = 3
LOG_LEVEL_ERROR     = 4
LOG_LEVEL_IMPORT    = 5

-- 调试日志
function KernelMethods:debug( fmt, ... )
    
    if jav_is_debugmode() == false then return end
    local text = string.format( fmt, ... )
    self:_output( LOG_LEVEL_DEBUG, text )
    
end

-- 普通日志(DEBUG>=2时输出)
function KernelMethods:log( fmt, ... )

    if DEBUG < 2 then return end 
    local text = string.format( fmt, ... )
    self:_output( LOG_LEVEL_NORMAL, text )
    
end

-- 警告日志(DEBUG>=1时输出) 
function KernelMethods:warn( fmt, ... )

    if DEBUG < 1 then return end 
    local text = string.format( fmt, ... )
    self:_output( LOG_LEVEL_WARN, text )
        
end

-- 错误日志(DEBUG>=0时输出) 
function KernelMethods:error( fmt, ... )

    if DEBUG < 0 then return end
    local text = string.format( fmt, ... )
    self:_output( LOG_LEVEL_ERROR, text )
    release_print( debug.traceback( "", 2 ) )
    --device.showAlert( "脚本错误", string.format( fmt, ... ), { "OK" } ) 
    
end

-- 直接输出日志
function KernelMethods:output( fmt, ... )

    local text = string.format( fmt, ... )
    self:_output( LOG_LEVEL_IMPORT, text )

end

-- 输出日志
function KernelMethods:_output( lv, text )

    if text == nil or text == "" then
        return
    end
    
    local   prefix
    if      lv == LOG_LEVEL_DEBUG   then    prefix = "|调试-->"
    elseif  lv == LOG_LEVEL_NORMAL  then    prefix = "|日志-->"
    elseif  lv == LOG_LEVEL_WARN    then    prefix = "|警告-->"
    elseif  lv == LOG_LEVEL_ERROR   then    prefix = "|错误-->"
    elseif  lv == LOG_LEVEL_IMPORT  then    prefix = "|输出-->"
    else                                    prefix = "|未知-->"
    end
    release_print( os.date() .. prefix .. text )
    
end

-- 获取文本库文本配置
function KernelMethods:text( text_key )

    return g_library:QueryConfig( text_key )
    
end

-- 导入JSON配置文件
function KernelMethods:ImportJson( json_file )

    local file_sys = cc.FileUtils:getInstance()
    local full_path = file_sys:fullPathForFilename( json_file )
    local json_data = file_sys:getStringFromFile( full_path )
    if not json_data or json_data == "" then
        g_methods:warn( "导入JSON配置文件失败,找不到合法的JSON文件:%s...", full_path ) 
        return nil
    else
        local json_tbl = json.decode( json_data )
        if json_tbl then
            g_methods:debug( "导入JSON配置文件成功:%s...", json_file )
        else
            g_methods:error( "导入JSON配置文件失败,文件无法解析,请检查格式是否正确:%s...", json_file )
        end
        return json_tbl
    end 

end

-- 输出JSON配置文件
function KernelMethods:ExportJson( json_file, json_tbl )

    local file_sys = cc.FileUtils:getInstance()
    local full_path = json_file
    local json_str = json.encode( json_tbl )
    if not json_str or json_str == "" then
        g_methods:error( "输出JSON配置文件失败,没有有效的参数或者JSON化失败:%s...", full_path )
        return false
    else
        local ret = io.writefile( full_path, json_str )
        if ret == true then
            g_methods:debug( "输出JSON配置文件成功:%s...", full_path )
        else
            g_methods:error( "输出JSON配置文件失败,保存操作失败:%s...", full_path )
        end
        return ret
    end

end

-- 输出一个table的信息
function KernelMethods:DumpTable( tab, deep )

    deep = deep or 1
    local step_flag = ""
    for index = 1, deep do
        step_flag = step_flag .. "\t"
    end

    for i,v in pairs( tab ) do
        if type(v) == "table" then
            printf( "%s[%s] {", step_flag, i )
            g_methods:DumpTable( v, deep + 1 )
            printf( "%s}", step_flag )
        else
            printf( "%s[%s]: %s", step_flag, tostring(i), tostring(v) )
        end
    end
end

-- 查找表中第一个不是指定参数的表项
function KernelMethods:FindFirstNot( tbl, nval )
    for _, item in pairs( tbl ) do
        if item ~= nval then
            return item
        end
    end
    return nil
    
end

-- 查找表中是否含有指定参数(表中不含表)
function KernelMethods:IsInTable( tbl, nval )
    
    if not tbl then return false end
    
    for index, item in pairs(tbl) do 
        if nval == item then
            return true
        end
    end
    return false

end

-- 查找表中是否含有指定参数(表中元素为表)
function KernelMethods:IsInTables( tbl, nval ) 

    if not tbl then return false end

    for index, item in pairs(tbl) do 
        if #item >= 0 then
            for idx, value in pairs(item) do        
                if nval == value then
                    return true
                end
            end
        end
    end
    return false

end

-- 表乱序
function KernelMethods:RandArray( tab, num, protect )

    num = num or #tab
    local res = {}
    local randTab

    if protect then

        --这里只做了最简单的复制处理
        local function copyTab(oldTab)
            local newTab = {}
            for i,v in pairs(oldTab) do
                newTab[i] = oldTab[i]
            end
            return newTab
        end
        randTab = copyTab(tab)

    else

        randTab = tab

    end

    for i = 1, num do

        local r = math.random(1,#randTab)
        table.insert(res,randTab[r])
        table.remove(randTab,r)

    end

    return res

end

-- 数组键值查找
function KernelMethods:FindTblKey( tbl, key, value )

    if #tbl == 0 then
        return
    end
    
    for index = 1, #tbl do
        if tbl[index][key] == value then
            return tbl[index]
        end
    end
    return nil
    
end

-- 参数:待分割的字符串,分割字符
-- 返回:子串表.(含有空串)
function KernelMethods:SplitString( str, split_char )
    local sub_str_tab = {};
    while (true) do
        local pos = string.find(str, split_char);
        if (not pos) then
            sub_str_tab[#sub_str_tab + 1] = str;
            break;
        end
        local sub_str = string.sub(str, 1, pos - 1);
        sub_str_tab[#sub_str_tab + 1] = sub_str;
        str = string.sub(str, pos + 1, #str);
    end

    return sub_str_tab;
end

-- 整字符分割
function KernelMethods:SplitChar( str ) 
    str = str or ""
    local list = {}
    local len = string.len(str) 
    local i = 1 
    while i <= len do
        local c = string.byte(str, i)
        local shift = 1
        if c > 0 and c <= 127 then
            shift = 1
        elseif (c >= 192 and c <= 223) then
            shift = 2
        elseif (c >= 224 and c <= 239) then
            shift = 3
        elseif (c >= 240 and c <= 247) then
            shift = 4
        end
        local char = string.sub(str, i, i+shift-1)
        i = i + shift
        table.insert(list, char)
    end
    return list, len
end

-- 清空table
function KernelMethods:CleanTable( tbl )
    while true do
        local k =next(tbl)
        if not k then break end
        tbl[k] = nil
    end
end

-- 拷贝table(适用于二级Table,多层次请使用clone)
function KernelMethods:CopyTable( t1, t2 )

    if not t1 or not t2 then
        return false
    end

    for key, var in pairs(t1) do
        t2[key] = var
    end
    
    return true
    
end

-- 表数组整合
function KernelMethods:AppendTable( t1, t2 )    
    if t1 and t2 and #t2 > 0 then
        for _, t in pairs( t2 ) do
            table.insert( t1, t )
        end
    end  
    return t1
end

-- 表项删除
function KernelMethods:RemoveTblItem( tbl, item )
    
    if not tbl or #tbl == 0 then
        return false
    end
    
    for index = 1, #tbl do
        if tbl[index] == item then
            table.remove( tbl, index )
        end
    end
    
    return tbl
end

-- 表项插入
function KernelMethods:InsertTblItem( tbl, item, only )

    -- 重复检查
    if only == true then
        
        for _, tmp in pairs( tbl ) do
            if tmp == item then
                return false
            end
        end
        
    end

    -- 唯一插入
    table.insert( tbl, item )
    return true
    
end

-- 数字字符串判断
function KernelMethods:IsDigit( num_str )

    if num_str == nil then
        return false
    end
    
    local len = string.len( num_str )
    for i = 1, len do
        local ch = string.sub( num_str, i, i )
        if ch < '0' or ch > '9' then
            return false
        end
    end 
    
    return true

end

-- 字母字符串判断
function KernelMethods:IsAlpha( alpha_str )

    if alpha_str == nil then
        return false
    end

    local len = string.len( alpha_str )
    for i = 1, len do
        local ch = string.sub( alpha_str, i, i )
        if not ((ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z')) then 
            return false
        end
    end 

    return true

end

-- 字母+数字字符串判断
function KernelMethods:IsAlphaDigit( aldigit_str )

    if aldigit_str == nil then
        return false
    end

    local len = string.len( aldigit_str )
    for i = 1, len do
        local ch = string.sub( aldigit_str, i, i )
        if not ((ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z') or (ch >= '0' and ch <= '9') ) then 
            return false
        end
    end 

    return true

end

-- 空格去除
function KernelMethods:TrimStr( str )

    if str == nil then
        return nil
    end
     
    str = string.gsub(str, " ", "")
    return str
    
end

-- 获取字典项数量
function KernelMethods:DictCount( dic )

    if not dic then
        return 0
    end

    local count = 0
    for _, var in pairs( dic ) do
        count = count + 1
    end

    return count
    
end

-- 延迟执行
function KernelMethods:DelayCallback( target, func, delay )
    local wait = cc.DelayTime:create(delay)
    target:runAction(cc.Sequence:create(wait, cc.CallFunc:create(func)))
end

-- 按钮点击绑定
function KernelMethods:ButtonClicked( parent, btn_name, clicked_handle, args )
    local button = parent:getChildByName( btn_name )
    button:addTouchEventListener(
        function( sender, eventType )
            if eventType == ccui.TouchEventType.ended then
                clicked_handle( sender, args )
            end
        end )
    return button 
end

-- 复选框点击绑定
function KernelMethods:CheckClicked( parent, chk_name, sel_handle, args )
    local checkbox = parent:getChildByName( chk_name )
    checkbox:addEventListener( 
        function( sender, eventType )
            sel_handle( sender, args )
        end )
end

-- 指定控件无效化
function KernelMethods:WidgetDisable( widget, disable )

    if disable == true then
        widget:setEnabled( false )
        widget:setBright( false ) 
    else
        widget:setEnabled( true )
        widget:setBright( true )
    end
end

-- 指定控件无效化
function KernelMethods:WidgetDisableByName( parent, widget_name, disable )

    local widget = parent:getChildByName( widget_name )
    if widget then
        self:WidgetDisable( widget, disable )
    end
    return widget
end

-- 指定控件隐藏
function KernelMethods:WidgetVisible( parent, widget_name, visible )

    local widget = parent:getChildByName( widget_name )
    if widget then
        widget:setVisible( visible )
    end
    return widget
end


-- 对象细节信息
function KernelMethods:ObjectDetail( object )

    -- 无效对象返回
    if not object then
        return "null-object"
    else
        return string.format( "(%d)%s#%s", object.obj_tag, object.obj_cfgid, object.obj_class )
    end

end

-- 单次计时回调创建
function KernelMethods:CreateOnceCallback( secs, func, args )
    
    -- 回调绑定在当前场景结点上
    local scene = cc.Director:getInstance():getRunningScene()
    if not scene then
        self:error( "创建单次计时回调失败,当前无有效的场景节点~" )
        return nil
    end
    
    -- 参数合法性判断
    if not func then
        self:error( "创建单次计时回调失败,参数回调函数为空~" )
        return nil
    end
    
    -- 参数补全
    args = args or {}
    args.func = func
    
    -- 组件行为序列
    local callback = function( sender, args )
        args.func( args ) 
    end
    
    local delay = cc.DelayTime:create( secs )
    local fback = cc.CallFunc:create( callback, args )
    local sequc = cc.Sequence:create( delay, fback )

    -- 唯一行为ID计数器
    self.actor_tag = self.actor_tag or 1000
    self.actor_tag = self.actor_tag + 1
    
    -- 行为触发
    local act = scene:runAction( sequc )
    act:setTag( self.actor_tag )
    
    return self.actor_tag

end

-- 单次计时回调销毁
function KernelMethods:DeleteOnceCallback( tag )

    -- 回调绑定在当前场景结点上
    local scene = cc.Director:getInstance():getRunningScene()
    if not scene then
        self:error( "销毁单次计时回调失败,当前无有效的场景节点~" )
        return false
    end
    
    -- 参数有效性检查
    if not tag then
        self:error( "创建单次计时回调失败,参数行为Tag为空~" )
        return false        
    end
    
    -- 行为销毁
    local act = scene:getActionByTag( tag )
    if act then
        scene:stopActionByTag( tag )
    end
    
    return true
    
end

-- 多次计时回调创建
function KernelMethods:CreateTickerCallback( tick_secs, func, args )

    -- 参数有效性检查
    if not func then
        self:error( "创建多次计时回调失败,参数回调方法为空~" )
        return false        
    end    

    -- 回调
    local ticker_callback = function( dt )
        func( args )
    end

    -- 注册
    local sched = cc.Director:getInstance():getScheduler()
    local handle = sched:scheduleScriptFunc( ticker_callback, tick_secs, false )

    return handle
    
end

-- 多次计时回调创建
function KernelMethods:DeleteTickerCallback( handle )

    -- 参数有效性检查
    if not handle then
        self:error( "销毁多次计时回调失败,参数句柄无效~" )
        return false        
    end    
    
    -- 注销
    local sched = cc.Director:getInstance():getScheduler()
    if sched then
        sched:unscheduleScriptEntry( handle )
        return true
    end
    
    return false
    
end

-- 设置当前纹理缓存中的纹理抗锯齿特性
function KernelMethods:setTextureAntiAlias( png, enabled )

    local texture = cc.Director:getInstance():getTextureCache():getTextureForKey( png )
    if not texture then
        self:warn( "当前不存在纹理:%s,抗锯齿设定失败!", png )
        return
    end
    
    if enabled then     
        texture:setAntiAliasTexParameters()
    else
        texture:setAliasTexParameters()
    end
    
end
return KernelMethods
