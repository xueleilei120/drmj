-- base_event.lua
-- 2014-10-28
-- KevinYuen
-- 基础消息定义
     
ESE_SCENE_ACTIVED    = "scene_actived"       -- 场景激活{ scene_class, scene_id }
ESE_SCENE_INACTIVED  = "scene_inactived"     -- 场景反激活{ scene_class, scene_id }
ESE_SCENE_READY      = "scene_ready"         -- 场景数据准备完毕{ scene_class, scene_id, step[preload,load_scene,load_layouts,prepare_done] }

ESE_OBJECT_PROPCHG   = "object_propchanged"  -- 对象属性改变{ object, prop_name, old_value, value }
ESE_OBJECT_ARRIVED   = "object_movedone"     -- 对象移动完毕{ object }

ESE_STATE_WAITING    = "state_waitting"      -- 对象的非行为状态启动{ object, state }
ESE_STATE_WORKING    = "state_working"       -- 对象的非行为状态激活{ object, state }
ESE_STATE_OUTDATE    = "state_outdate"       -- 对象的非行为状态过期{ object, state }

ESE_SKILL_BOOTING    = "skill_booting"       -- 对象的技能启动{ object, skill }
ESE_SKILL_PAUSED     = "skill_paused"        -- 对象的技能暂停{ object, skill }
ESE_SKILL_FIRED      = "skill_fired"         -- 对象的技能释放{ object, skill }
ESE_SKILL_BREAKED    = "skill_breaked"       -- 对象的技能打断{ object, skill }
ESE_SKILL_MISSED     = "skill_missed"        -- 对象的技能闪避{ object, skill }
ESE_SKILL_CDING      = "skill_cding"         -- 对象的技能冷却{ object, skill }
ESE_SKILL_CDTICKER   = "skill_cdtick"        -- 对象的技能冷却心跳{ object, skill, remain_secs }
ESE_SKILL_CDOVER     = "skill_cdover"        -- 对象的技能冷却结束{ object, skill }
ESE_SKILL_LEVELUP    = "skill_levelup"       -- 对象的技能升级{ object, skill_id, add_level }

ESE_COMMAND_REG      = "command_regist"      -- 命令注册{ cmd }
ESE_COMMAND_UNREG    = "command_unregist"    -- 命令注销{ cmd }
ESE_COMMAND_START    = "command_start"       -- 命令队列执行开始{ object }
ESE_COMMAND_END      = "command_end"         -- 命令队列执行结束{ object }
ESE_COMMAND_PAUSED   = "command_paused"      -- 命令队列暂停{ object }
ESE_COMMAND_RESUMED  = "command_resumed"     -- 命令队列暂停恢复{ object }