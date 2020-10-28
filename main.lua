push = require 'push'

WINDOW_WIDTH = 600
WINDOW_HEIGHT = 900
VIRTUAL_WIDTH = 243
VIRTUAL_HEIGHT = 432

math.randomseed(os.time())
isAlive = true
score = 0

-- player
player = {}
player.image = love.graphics.newImage('graphics/player.png')
player.width = player.image:getWidth()
player.height = player.image:getHeight()
player.x = VIRTUAL_WIDTH / 2 - player.width / 2
player.y = VIRTUAL_HEIGHT - player.height - 20
player.speed = 200

-- enemy
enemies = {}
enemyImage = nil
enemyTimerMax = 1.5
enemyTimer = enemyTimerMax
enemyColor = {
    {247 / 255, 232 / 255, 225 / 255, 255 / 255},
    {185 / 255, 158 / 255, 146 / 255, 255 / 255},
    {171 / 255, 160 / 255, 155 / 255, 255 / 255},
    {54 / 255, 48 / 255, 46 / 255, 255 / 255},
    {140 / 255, 131 / 255, 127 / 255, 255 / 255},
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

    love.graphics.setDefaultFilter('nearest', 'nearest')

    smallFont = love.graphics.newFont('graphics/font.ttf', 5)
    largeFont = love.graphics.newFont('graphics/font.ttf', 18)
    love.graphics.setFont(smallFont)

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
    })

    enemyImage = love.graphics.newImage('graphics/enemy.png')
    enemyWidth = enemyImage:getWidth()
    enemyHeight = enemyImage:getHeight()

    bulletImage = love.graphics.newImage('graphics/bullet.png')
    bulletWidth = bulletImage:getWidth()
    bulletHeight = bulletImage:getHeight()

    song = love.audio.newSource('sounds/soundtrack.ogg', 'stream')

    sounds = {
        ['boom'] = love.audio.newSource('sounds/boom.ogg', 'static'),
        ['shoot'] = love.audio.newSource('sounds/shoot.ogg', 'static'),
    }

    gameState = 'start'

    song:setLooping(false) -- set to true later
    --love.audio.play(song)
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
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
    -- player
    if love.keyboard.isDown('left', 'a') then
        if player.x > 0 then -- player doesn't go off screen
            player.x = player.x - (player.speed * dt)
        end
    elseif love.keyboard.isDown('right', 'd') then
        if player.x < (VIRTUAL_WIDTH - player.width) then
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

    -- enemy
    enemyTimer = enemyTimer - (1 * dt)
    if enemyTimer < 0 then
        enemyTimer = enemyTimerMax
        newEnemy = {
            image = enemyImage,
            x = math.random(30, VIRTUAL_WIDTH - 30),
            y = -30,
            speed = 100,
            color = enemyColor[love.math.random(1, #enemyColor)]
        }
        table.insert(enemies, newEnemy)
    end
    for i, v in ipairs(enemies) do
        v.y = v.y + (v.speed * dt)
        if v.y > VIRTUAL_HEIGHT + enemyHeight then
            table.remove(enemies, i)
        end
    end

    -- collision
    for i, enemy in ipairs(enemies) do
        for j, bullet in ipairs(bullets) do
            if collision(enemy.x, enemy.y, enemyWidth, enemyHeight, bullet.x, bullet.y, bulletWidth, bulletHeight) then
                table.remove(bullets, j)
                table.remove(enemies, i)
                score = score + 1
                sounds['boom']:play()
            end
        end
        if collision(enemy.x, enemy.y, enemyWidth, enemyHeight, player.x, player.y, player.width, player.height) and isAlive then
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
        enemyTimer = enemyTimerMax

        player.x = VIRTUAL_WIDTH / 2 - player.width / 2
        player.y = VIRTUAL_HEIGHT - player.height - 20

        score = 0
        isAlive = true
    end
end

function love.draw()
    push:apply('start')

    if gameState == 'start' then
        love.graphics.setFont(largeFont)
        love.graphics.printf('Space Shooter CS50!', 0, 30, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to begin!', 0, 140, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        love.graphics.setFont(smallFont)
        love.graphics.print("Score: " .. tostring(score), 100, 10)

        if isAlive then
            love.graphics.draw(player.image, player.x, player.y)

            for i, v in ipairs(bullets) do
                love.graphics.draw(v.image, v.x, v.y)
            end
        end
        for i, v in ipairs(enemies) do
            love.graphics.setColor(v.color)
            love.graphics.draw(v.image, v.x, v.y)
        end
    elseif gameState == 'done' then
        love.graphics.printf('Press Enter to try again!', 0, 140, VIRTUAL_WIDTH, 'center')
    end

    push:apply('end')
end