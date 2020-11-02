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
enemies = {}
asteroidImage = nil
asteroidTimerMax = 1.5
asteroidTimer = asteroidTimerMax
asteroidColor = {
    {247 / 255, 232 / 255, 225 / 255},--, 255 / 255},
    {185 / 255, 158 / 255, 146 / 255},--, 255 / 255},
    {171 / 255, 160 / 255, 155 / 255},--, 255 / 255},
    {54 / 255, 48 / 255, 46 / 255},--, 255 / 255},
    {140 / 255, 131 / 255, 127 / 255}--, 255 / 255},
}

-- bullet
bullets = {}
bulletImage = nil
canShoot = true
canShootTimerMax = 5
canShootTimer = canShootTimerMax 

---------------------==START==-----------------------

-- Collision detection from http://love2d.org/wiki/BoundingBox.lua
function collision(x1,y1,w1,h1, x2,y2,w2,h2)
    return x1 < x2+w2 and
           x2 < x1+w1 and
           y1 < y2+h2 and
           y2 < y1+h1
end

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

    -- enemyImage = love.graphics.newImage('graphics/enemy.png')
    -- enemyWidth = enemyImage:getWidth()
    -- enemyHeight = enemyImage:getHeight()
    asteroidWidth = 30
    asteroidHeight = 30

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

    coords = {{0,0}, {.5, .5}, {1, 1,}}
    seeds = {7, 9, 79}
    rotations = {-1, 0, 1}
    cols = {{.7, .9, .79}, {.7, .2, .4}, {.27, .62, .44}}
    --for i = 0, 3 do
        --coords[i] = {.5, .5}
        --seeds[i] = math.random(1, 9000)
        --rotations[i] = (math.random() * 2 - 0.5) * 0.01
        --cols[i] = asteroidColor[love.math.random(1, #asteroidColor)]
    --end

    asteroidsShader:send("time", gameTime)
    asteroidsShader:send("coords", {0,0}, {.5, .5}, {1, 1})--unpack(coords))
    asteroidsShader:send("seeds", 7, 9, 79)
    asteroidsShader:send("rotations", -1, 0, 1)
    asteroidsShader:send("colors", {.7, .9, .79}, {.7, .2, .4}, {.27, .62, .44})

    if gameState == 'play' then
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

        -- asteroid
        asteroidTimer = asteroidTimer - (1 * dt)
        if asteroidTimer < 0 then
            asteroidTimer = asteroidTimerMax
            newAsteroid = {
                image = asteroidImage,
                x = math.random(30, WINDOW_WIDTH - 30),
                y = -30,
                speed = 100,
                seed = math.random(1, 9000),
                rotation = math.random() * 2 - 0.5,
                color = asteroidColor[love.math.random(1, #asteroidColor)]
            }
            table.insert(enemies, newAsteroid)
        end

        -- updating asteroid movement
        for i, v in ipairs(enemies) do
            v.y = v.y + (v.speed * dt)
            if v.y > WINDOW_WIDTH + asteroidHeight then
                table.remove(enemies, i)
            end
        end

        -- collision
        for i, asteroid in ipairs(enemies) do
            for j, bullet in ipairs(bullets) do
                if collision(asteroid.x, asteroid.y, asteroidWidth, asteroidHeight, bullet.x, bullet.y, bulletWidth, bulletHeight) then
                    table.remove(bullets, j)
                    table.remove(enemies, i)
                    score = score + 1
                    sounds['boom']:play()
                end
            end
            if collision(asteroid.x, asteroid.y, asteroidWidth, asteroidHeight, player.x, player.y, player.width, player.height) and isAlive then
                table.remove(enemies, i)
                sounds['boom']:play()
                isAlive = false
                gameState = 'done'
            end
        end

        -- reset game
        if not isAlive then
            -- gameState = 'done'
            bullets = {}
            enemies = {}

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