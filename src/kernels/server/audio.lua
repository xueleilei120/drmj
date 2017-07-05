-- audio.lua
-- 2014-10-28
-- KevinYuen
-- 音效系统

local BaseObject = require( "kernels.object" )
local AudioManager = class( "AudioManager", BaseObject )

-- 初始化
function AudioManager:OnCreate( args )

    AudioManager.super.OnCreate( self, args )
          
    -- 背景音乐相关
    self.bg_musics = {}
    self.bg_playidx = 0
    self.bg_radplay = true
    self.bg_handle = nil
    
    -- 音效相关
    self.ef_sounds = {}
    
end

-- 销毁
function AudioManager:OnDestroy()

    -- 检测是否有循环音效为释放
    if #self.ef_sounds > 0 then
        g_methods:warn( "有部分循环音效没有正确地主动释放:" )
        for k, inf in pairs( self.ef_sounds ) do
            g_methods:warn( "\t音效:" .. inf.path )
        end
    end

    -- 全停止
    self:StopAll()
    
    AudioManager.super.OnDestroy( self )
     
end

-- 添加背景音乐
function AudioManager:AddBGMusics( musiclst ) 

    -- 背景音乐列表扩充
    g_methods:CopyTable( musiclst, self.bg_musics )
    
    -- 空表不处理
    if #self.bg_musics == 0 then
        g_methods:warn( "添加背景音乐失败,列表为空..." )
        return false
    end
    
    return true
    
end

-- 播放背景音乐
function AudioManager:PlayBG( randplay )

    -- 空表不处理
    if #self.bg_musics == 0 then
        g_methods:warn( "播放背景音乐失败,列表为空..." )
        return false
    end
    
    self.bg_radplay = randplay or self.bg_radplay

    -- 如果已经在播放背景音乐,先关闭
    self:StopBG()

    -- 选择待播放曲目
    if self.bg_radplay == true then
        self.bg_playidx = math.random( 1, #self.bg_musics )
    else
        self.bg_playidx = self.bg_playidx + 1
        if self.bg_playidx > #self.bg_musics then
            self.bg_playidx = self.bg_playidx % #self.bg_musics 
        end        
    end

    -- 播放音乐
    local vol = g_save.configs.system.music_volume or 0.8
    local music = self.bg_musics[self.bg_playidx]
    self.bg_handle = ccexp.AudioEngine:play2d( music, false, vol )
    if self.bg_handle == cc.AUDIO_INVAILD_ID then
        g_methods:warn( "背景音乐[%s]播放失败...", music )
        return false
    end

    -- 回调绑定
    ccexp.AudioEngine:setFinishCallback( self.bg_handle, function ( audioID, filePath )
        self:PlayBG( self.bg_radplay )               
    end )
    
end

-- 停播背景音乐
function AudioManager:StopBG()

    if self.bg_handle then
        ccexp.AudioEngine:stop( self.bg_handle )
        self.bg_handle = nil
    end
    
end

-- 设置背景音量
function AudioManager:SetBGVolume( vol )

    -- 系统变量更新
    if vol < 0 then vol = 0 end
    if vol > 1 then vol = 1 end
    g_save.configs.system.music_volume = vol
    
    -- 当前背景音量更新
    if self.bg_handle then
        ccexp.AudioEngine:setVolume( self.bg_handle, vol )
    end
    
end

-- 获取背景音量
function AudioManager:GetBGVolume()
    return g_save.configs.system.music_volume
end

-- 播放音效
function AudioManager:PlaySound( filepath, loop )

    -- 参数合法检查
    if not filepath or filepath == "" then
        g_methods:warn( "播放音效失败,参数路径为空..." )
        return nil
    end 

    -- 播放音效
    loop = loop or false
    local vol = g_save.configs.system.sound_volume or 0.8
    local handle = ccexp.AudioEngine:play2d( filepath, loop, vol )
    if handle == cc.AUDIO_INVAILD_ID then
        g_methods:warn( "播放音效失败,文件:%s...", filepath )
        return nil
    end
    
    -- 如果是循环音效,那么记录句柄
    if loop == true then
        table.insert( self.ef_sounds, { path = filepath, handle = handle } )
    end
    
    return handle
end

-- 停播音效
function AudioManager:StopSound( handle )

    -- 句柄无效检查
    if handle == nil then return end
    
    -- 音效停止播放
    ccexp.AudioEngine:stop( handle )
    
    -- 从记录中删除
    if #self.ef_sounds > 0 then
        for index = 1, #self.ef_sounds do
            local inf = self.ef_sounds[index]
            if handle == inf.handle then
                table.remove( self.ef_sounds, index )
                break
            end
        end
    end
    
end

-- 设置音效音量
function AudioManager:SetSoundVolume( vol )

    -- 系统变量更新
    if vol < 0 then vol = 0 end
    if vol > 1 then vol = 1 end
    g_save.configs.system.sound_volume = vol

    -- 循环音效音量更新
    for k, inf in pairs( self.ef_sounds ) do
        ccexp.AudioEngine:setVolume( inf.handle, vol )
    end
    
end

-- 获取音效音量
function AudioManager:GetSoundVolume()
    return g_save.configs.system.sound_volume 
end

-- 全停止
function AudioManager:StopAll()

    self.bg_handle = nil
    ccexp.AudioEngine:stopAll()
    
end

return AudioManager