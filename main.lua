WINDOW_WIDTH = 640
WINDOW_HEIGHT = 960
-- 628
-- 1200

math.randomseed(os.time())
isAlive = nil
score = 0
gameTime = 0

---------------------==START==-----------------------

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

    -- bullet
    bullets = {}
    bulletImage = nil
    canShoot = true
    canShootTimerMax = 5
    canShootTimer = canShootTimerMax 

    bulletImage = love.graphics.newImage('graphics/bullet.png')
    bulletWidth = bulletImage:getWidth()
    bulletHeight = bulletImage:getHeight()

    -- asteroid
  
    color1 = hex2rgb('#FFC854')
    color2 = hex2rgb('#FF960D')
    color3 = hex2rgb('#F56600')
    color4 = hex2rgb('#B03509')
    color5 = hex2rgb('#FF1D00')

    asteroids = {}
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

    soundtrack:setLooping(false) -- set to true later
    --love.audio.play(soundtrack)
end

function love.keypressed(key, u)
    if key == 'escape' then
        love.event.quit()
    end
    if key == "rctrl" then
        debug.debug()
     end
    if key == 'enter' or key == 'return' then
        gameState = 'play'
        isAlive = true
        initShip()

        for i = 1, 1 do
            table.insert(asteroids, initAstr())
        end
        asteroids[1].y = -.1
    end
end

function love.update(dt)
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

        astrXY = {}
        astRot = {}
        seeds = {}
        colors = {}
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
                    isAlive = false;
                end
            end
            if astr.y > 1.8 then
                asteroids[i] = initAstr()
            end
        end

        asteroidsShader:send("time", gameTime)
        asteroidsShader:send("coords", unpack(astrXY))
        asteroidsShader:send("rotations", unpack(astRot))
        asteroidsShader:send("seeds", unpack(seeds))
        asteroidsShader:send("colors", unpack(colors))

        -- bullet
        canShootTimer = canShootTimer - (1 * dt)
        if canShootTimer < 0 then
            canShoot = true
        end

        if love.keyboard.isDown('space') then
            newBullet = {
                image = bulletImage,
                x = player.x,
                y = player.y,
                speed = 500
            }
            table.insert(bullets, newBullet)
            sounds['shoot']:play()
            canShoot = false
            canShootTimer = canShootTimerMax
        end
        for i, v in ipairs(bullets) do
            v.y = v.y - (v.speed * dt)
            if v.y < 0 then
                table.remove(bullets, i)
            end
        end

        -- reset game
        if not isAlive then
            gameState = 'done'

            player.x = -1
            player.y = -1

            score = 0
            -- isAlive = true
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

        -- if isAlive then
        --     for i, v in ipairs(bullets) do
        --         love.graphics.draw(v.image, v.x, v.y)
        --     end
        -- end
    elseif gameState == 'done' then
        love.graphics.printf("Press Enter to try again!", 0, 140, WINDOW_WIDTH, 'center')
    end
end

-- https://gist.github.com/jasonbradley/4357406
function hex2rgb(hex)
    hex = hex:gsub("#","")
    return {tonumber(hex:sub(1,2), 17) / 255, tonumber(hex:sub(3,4), 17) / 255, tonumber(hex:sub(5,6), 17) / 255}
end

function initAstr()
    asteroid = {
        x = math.random(0, 10) * .1,
        y = math.random(-1, -15) * 0.1,
        speed = 0.2,
        seed = math.random(1, 9000),
        rotation = math.random() * 2 - 0.5,
        color = asteroidsColor[love.math.random(1, #asteroidsColor)],
        size = 0.08
    }
    asteroid.x = math.min(math.max(.1, asteroid.x), .9)
    -- asteroid.y = math.min(math.max(.9, asteroid.y), .1)
    return asteroid
end

function initShip()
    player = {
        x = 0.5,
        y = 1.4,
        size = 0.06
    }
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