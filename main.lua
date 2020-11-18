WINDOW_WIDTH = 628
WINDOW_HEIGHT = 1200

math.randomseed(os.time())
isAlive = true
score = 0
gameTime = 0

-- player
player = {}
player.image = love.graphics.newImage('graphics/player.png')
player.width = player.image:getWidth()
player.height = player.image:getHeight()
player.x = WINDOW_WIDTH / 2
player.y = WINDOW_HEIGHT - WINDOW_HEIGHT * 0.2
player.speed = 200

-- asteroid
asteroids = {}
asteroidTimerMax = 1.5
asteroidTimer = asteroidTimerMax
asteroidsColor = {
    {247 / 255, 232 / 255, 225 / 255},
    {185 / 255, 158 / 255, 146 / 255},
    {171 / 255, 160 / 255, 155 / 255},
    {54 / 255, 48 / 255, 46 / 255},
    {140 / 255, 131 / 255, 127 / 255}
}

-- bullet
bullets = {}
bulletImage = nil
canShoot = true
canShootTimerMax = 5
canShootTimer = canShootTimerMax 

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

    for i = 1, 3 do
        asteroid = {
            x = math.random(),
            y = -0.5,
            speed = 0.1,
            seed = math.random(1, 9000),
            rotation = math.random() * 2 - 0.5,
            color = asteroidsColor[love.math.random(1, #asteroidsColor)]
        }
        table.insert(asteroids, asteroid)
    end

    bulletImage = love.graphics.newImage('graphics/bullet.png')
    bulletWidth = bulletImage:getWidth()
    bulletHeight = bulletImage:getHeight()

    skyShader = love.graphics.newShader('graphics/SkyShader.sh')
    asteroidsShader = love.graphics.newShader('graphics/AsteroidsShader.sh')

    song = love.audio.newSource('sounds/soundtrack.ogg', 'stream')

    sounds = {
        ['boom'] = love.audio.newSource('sounds/boom.ogg', 'static'),
        ['shoot'] = love.audio.newSource('sounds/shoot.ogg', 'static'),
    }

    gameState = 'start'

    song:setLooping(false) -- set to true later
    --love.audio.play(song)
end

function love.keypressed(key, u)
    if key == 'escape' then
        love.event.quit()
    end
    if key == "rctrl" then
        debug.debug()
     end
    if key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'play'
        elseif gameState == 'done' then
            gameState = 'play'
        end
    end
end

function love.update(dt)
    gameTime = gameTime + dt
    skyShader:send("time", gameTime)

    -- coords = {{0,0}, {.5, .5}, {1, 1,}}
    -- seeds = {7, 9, 79}
    -- rotations = {-1, 0, 1}
    -- cols = {{.7, .9, .79}, {.7, .2, .4}, {.27, .62, .44}}

    -- asteroidsShader:send("time", gameTime)
    -- asteroidsShader:send("coords", {0,0}, {.5, .5}, {1, 1})--unpack(coords))
    -- asteroidsShader:send("seeds", 7, 9, 79)
    -- asteroidsShader:send("rotations", -1, 0, 1)
    -- asteroidsShader:send("colors", {.7, .9, .79}, {.7, .2, .4}, {.27, .62, .44})

    if gameState == 'play' then

        astrXY = {}
        for i, astr in ipairs(asteroids) do
            astr.y = astr.y + (astr.speed * dt)
            table.insert(astrXY, {astr.x, astr.y})
        end
        print(astrXY[1][2])
        
        asteroidsShader:send("coords", unpack(astrXY))
            -- asteroidsShader:send("coords", map(asteroids, function(item) return item.y end))

        -- player
        if love.keyboard.isDown('left', 'a') then
            if player.x > 0 then -- player doesn't go off screen
                player.x = player.x - (player.speed * dt)
            end
        elseif love.keyboard.isDown('right', 'd') then
            if player.x < (WINDOW_WIDTH - player.width) then
                player.x = player.x + (player.speed * dt)
            end
        end

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
            -- gameState = 'done'
            bullets = {}
            asteroids = {}

            canShootTimer = canShootTimerMax
            asteroidTimer = asteroidTimerMax

            player.x = WINDOW_WIDTH / 2 - player.width / 2
            player.y = WINDOW_HEIGHT - player.height - 20

            score = 0
            isAlive = true
        end
    end
end

function love.draw()
    love.graphics.setShader(skyShader)
    love.graphics.rectangle('fill', 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
    love.graphics.setShader() 

    love.graphics.setShader(asteroidsShader)
    love.graphics.rectangle('fill', 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
    love.graphics.setShader()

    if gameState == 'start' then
        love.graphics.setFont(largeFont)
        love.graphics.printf("Space Shooter CS50!", 0, WINDOW_HEIGHT / 4, WINDOW_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf("Press Enter to begin!", 0, WINDOW_HEIGHT / 2, WINDOW_WIDTH, 'center')
    elseif gameState == 'play' then
        love.graphics.setFont(smallFont)
        love.graphics.print("Score: " .. tostring(score), 100, 10)

        if isAlive then
            love.graphics.draw(player.image, player.x, player.y)

            for i, v in ipairs(bullets) do
                love.graphics.draw(v.image, v.x, v.y)
            end
        end
    elseif gameState == 'done' then
        love.graphics.printf("Press Enter to try again!", 0, 140, WINDOW_WIDTH, 'center')
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

  