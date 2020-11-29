WINDOW_WIDTH = 640
WINDOW_HEIGHT = 960
-- 628
-- 1200

ASTR_MAX = 5

math.randomseed(os.time())

asteroids = {}
astrDataPools = {}
astrDataPoolsCtr = 1

isAlive = nil
isPaused = nil
score = 0
gameTime = 0

function love.load()
    love.window.setTitle('Space Shooter 50')

    -- love.graphics.setDefaultFilter('nearest', 'nearest')

    smallFont = love.graphics.newFont('graphics/font.ttf', 15)
    largeFont = love.graphics.newFont('graphics/font.ttf', 50)
    love.graphics.setFont(smallFont)

    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
    })

    -- player
    player = {}

    -- asteroid
    color1 = hex2rgb('#FFC854')
    color2 = hex2rgb('#FF960D')
    color3 = hex2rgb('#F56600')
    color4 = hex2rgb('#B03509')
    color5 = hex2rgb('#FF1D00')

    --asteroids = {}
    asteroidsColor = { color1, color2, color3, color4, color5 }

    skyShader = love.graphics.newShader('graphics/SkyShader.sh')
    asteroidsShader = love.graphics.newShader('graphics/AsteroidsShader.sh')
    shipShader = love.graphics.newShader('graphics/ShipShader.sh')
    
    soundtrack = love.audio.newSource('sounds/soundtrack.ogg', 'stream')

    sounds = {
        ['boom'] = love.audio.newSource('sounds/boom.ogg', 'static'),
        ['shoot'] = love.audio.newSource('sounds/shoot.ogg', 'static'),
    }

    gameState = 'start'
    isPaused = false

    soundtrack:setLooping(false) -- set to true later
    --love.audio.play(soundtrack)
end

function love.keypressed(key, u)
    if key == 'escape' then
        love.event.quit()
    end
    if key == "p" then
        isPaused = not isPaused
    end

    if gameState == 'done' or gameState == 'start' then
        if key == 'enter' or key == 'return' then
            gameState = 'play'
            isAlive = true
            initShip()

            asteroids = {}
            astrDataPools = getAstrDataPools()

            for i = 1, ASTR_MAX do
                local asteroid = initAstr()
                table.insert(asteroids, asteroid)
            end
        end
    end
end

function love.update(dt)
    if isPaused then
        return
    end

    gameTime = gameTime + dt
    skyShader:send("time", gameTime)

    if gameState == 'play' then

        -- player
        if love.keyboard.isDown('left', 'a') then
            if player.x > 0 then -- player doesn't go off screen
                player.x = player.x - dt
            end
        elseif love.keyboard.isDown('right', 'd') then
            if player.x < 1 then
                player.x = player.x + dt
            end
        end

        shipShader:send("time", gameTime)
        shipShader:send("position", {player.x, player.y})
        shipShader:send("thrust", 0.45)

        -- asteroid
        local astrXY = {}
        local astRot = {}
        local seeds = {}
        local colors = {}
        for i, astr in ipairs(asteroids) do
            astr.y = astr.y + (astr.speed * dt)
            table.insert(astrXY, {astr.x, astr.y})
            table.insert(astRot, astr.rotation)
            table.insert(seeds, astr.seed)
            table.insert(colors, astr.color)
            if astr.y > 1.2 then
                -- circle collision stolen from https://sheepolution.com/learn/book/21
                distance = math.sqrt((astr.x - player.x)^2 + (astr.y - player.y)^2)
                if distance < astr.size + player.size then
                    isAlive = false
                    asteroids[i] = initAstr()
                end
            end
            if astr.y > 1.8 then
                print("reinit "..i)
                asteroids[i] = initAstr()
            end
        end

        asteroidsShader:send("time", gameTime)
        asteroidsShader:send("coords", unpack(astrXY))
        asteroidsShader:send("rotations", unpack(astRot))
        asteroidsShader:send("seeds", unpack(seeds))
        asteroidsShader:send("colors", unpack(colors))

        -- shoot lasers
        if love.keyboard.isDown('space') then
            -- new bullet was created here
            sounds['shoot']:play()
        end
        -- for i, v in ipairs(bullets) do
        --     v.y = v.y - (v.speed * dt)
        --     if v.y < 0 then
        --         table.remove(bullets, i)
        --     end
        -- end

        -- reset game
        if not isAlive then
            gameState = 'done'

            player.x = -1
            player.y = -1

            score = 0
        end
    end
end

function love.draw()
    love.graphics.setShader(skyShader)
    love.graphics.rectangle('fill', 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
    love.graphics.setShader() 

    if gameState == 'start' then
        love.graphics.setFont(largeFont)
        love.graphics.printf("Space Shooter CS50!", 0, WINDOW_HEIGHT / 4, WINDOW_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf("Press Enter to begin!", 0, 550, WINDOW_WIDTH, 'center')
    elseif gameState == 'play' then
        love.graphics.setFont(smallFont)
        love.graphics.print("Score: " .. tostring(score), 15, 10)

        love.graphics.setShader(asteroidsShader)
        love.graphics.rectangle('fill', 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
        love.graphics.setShader()

        love.graphics.setShader(shipShader)
        love.graphics.rectangle('fill', 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
        love.graphics.setShader()
    elseif gameState == 'done' then
        love.graphics.printf("Press Enter to try again!", 0, 140, WINDOW_WIDTH, 'center')
    end
end

-- https://gist.github.com/jasonbradley/4357406
function hex2rgb(hex)
    hex = hex:gsub("#","")
    return {tonumber(hex:sub(1,2), 17) / 255, tonumber(hex:sub(3,4), 17) / 255, tonumber(hex:sub(5,6), 17) / 255}
end

function initShip()
    player = {
        x = 0.5,
        y = 1.4,
        size = 0.06
    }
end

function getAstrDataPools()
    local result = {
        Xs = {},
        Ys = {},
        cols = {},
        rots = {}
    }
    local step = 1 / (ASTR_MAX + 1)
    for i = 1, ASTR_MAX do  
        table.insert(result.Xs, i * step)
        table.insert(result.Ys, -i * step * 2)
        table.insert(result.cols, asteroidsColor[i])
        table.insert(result.rots, math.floor(-ASTR_MAX * 0.5))
    end
    -- print("init pool; size:"..tablelength(result.Xs))
    return result
end

function initAstr()
    local poolSize = ASTR_MAX - astrDataPoolsCtr + 1;
    local asteroid = {
        x = astrDataPools.Xs[math.random(1, poolSize)],
        y = astrDataPools.Ys[math.random(1, poolSize)],
        speed = 0.2,
        seed = math.random(1, 9000),
        rotation = astrDataPools.rots[math.random(1, poolSize)],
        color = astrDataPools.cols[math.random(1, poolSize)],
        size = 0.08
    }
    removeTblValue(astrDataPools.Xs, asteroid.x)
    removeTblValue(astrDataPools.Ys, asteroid.y)
    removeTblValue(astrDataPools.rots, asteroid.rotation)
    removeTblValue(astrDataPools.cols, asteroid.color)

    astrDataPoolsCtr = astrDataPoolsCtr + 1
    if astrDataPoolsCtr > ASTR_MAX then
        astrDataPools = getAstrDataPools()
        astrDataPoolsCtr = 1        
    end

    return asteroid
end

function removeTblValue(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            table.remove(tbl, i)
        end
    end
end

-- copy paste code from https://stackoverflow.com/a/11671820
function map(tbl, f)
    local t = {}
    for k,v in pairs(tbl) do
        t[k] = f(v)
    end
    return t
end

-- ofc you have to write your own function for everything
-- https://stackoverflow.com/questions/2705793/how-to-get-number-of-entries-in-a-lua-table
function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

-- clone table
-- https://stackoverflow.com/a/641993 

function tableCopy(t)
    local t2 = {}
    for k,v in pairs(t) do
      t2[k] = v
    end
    return t2
end