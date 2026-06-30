--[[
    AK47 压枪脚本示例
    模拟 AK47 的后坐力模式：前几发上跳大，后面趋于稳定
    
    可用 API:
    - move(x, y): 移动鼠标
    - sleep(ms): 延迟执行
    - isButtonDown(button): 检查按键
    - getElapsedTime(): 获取按键按下后经过的时间(毫秒)
    - getShotCount(): 获取当前射击次数
    - log(msg): 输出日志
]]

-- AK47 压枪数据表 (每发的 Y 偏移量)
local recoil_pattern = {
    3.0,  -- 第1发
    3.5,  -- 第2发
    4.0,  -- 第3发
    3.5,  -- 第4发
    3.0,  -- 第5发
    2.5,  -- 第6发
    2.0,  -- 第7发
    1.8,  -- 第8发
    1.5,  -- 第9发
    1.2,  -- 第10发及以后
}

local last_shot = 0

function on_start()
    last_shot = 0
    log("AK47 压枪开始")
end

function on_update()
    local shot = getShotCount()
    
    -- 只在新的一发时处理
    if shot > last_shot then
        last_shot = shot
        
        -- 获取当前发数的压枪量
        local index = math.min(shot, #recoil_pattern)
        local pull = recoil_pattern[index] * recoil_speed
        
        -- 添加轻微的左右随机偏移
        local x_offset = (math.random() - 0.5) * 0.5
        
        move(x_offset, pull)
    end
    
    sleep(10)
end

function on_stop()
    log("AK47 压枪结束, 共 " .. last_shot .. " 发")
end
