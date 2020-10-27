push = require 'push'

WINDOW_WIDTH = 600
WINDOW_HEIGHT = 900
VIRTUAL_WIDTH = 243
VIRTUAL_HEIGHT = 432

math.randomseed(os.time())

-- player
player = {}
player.image = love.graphics.newImage("graphics/player.png")
player.width = player.image:getWidth()
player.height = player.image:getHeight()
player.x = VIRTUAL_WIDTH / 2 - player.width / 2
player.y = VIRTUAL_HEIGHT - player.height - 20
player.speed = 200

-- enemy
enemies = {}
enemyTimerMax = 1.5
enemyTimer = enemyTimerMax
enemyImg = nil
enemyColor = {
    {247 / 255, 232 / 255, 225 / 255, 255 / 255},
    {185 / 255, 158 / 255, 146 / 255, 255 / 255},
    {171 / 255, 160 / 255, 155 / 255, 255 / 255},
    {54 / 255, 48 / 255, 46 / 255, 255 / 255},
    {140 / 255, 131 / 255, 127 / 255, 255 / 255},
}

---------------------==START==-----------------------

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

    enemyImg = love.graphics.newImage('graphics/enemy.png')
    enemyWidth = enemyImg:getWidth()
    enemyHeight = enemyImg:getHeight()

    song = love.audio.newSource('sounds/soundtrack.ogg', 'stream')

    sounds = {
        ['boom'] = love.audio.newSource('sounds/boom.ogg', 'static'),
        ['shoot'] = love.audio.newSource('sounds/shoot.ogg', 'static'),
        ['win'] = love.audio.newSource('sounds/win.ogg', 'static')
    }

    score = 0

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
    if love.keyboard.isDown("left") then
        player.x = player.x - player.speed * dt
    elseif love.keyboard.isDown("right") then
        player.x = player.x + player.speed * dt
    end
    -- doesn't go off screen
    if player.x < 0 then
        player.x = 0
    elseif player.x + player.width > VIRTUAL_WIDTH then
        player.x = VIRTUAL_WIDTH - player.width
    end

    -- enemy
    enemyTimer = enemyTimer - (1 * dt)
    if enemyTimer < 0 then
        enemyTimer = enemyTimerMax
        enemy = {
            image = enemyImg,
            width = enemyImg:getWidth(),
            height = enemyImg:getHeight(),
            x = math.random(8, VIRTUAL_WIDTH - 8),
            y = -18,
            speed = 100,
            rotation = math.random(0, 360),
            color = enemyColor[love.math.random(1, #enemyColor)]
        }
        table.insert(enemies, enemy)
    end
    for i, v in ipairs(enemies) do
        v.y = v.y + (v.speed * dt)
        if v.y > VIRTUAL_HEIGHT + enemy.height then
            table.remove(enemies, i)
        end
    end
end

function love.draw()
    push:apply('start')

    love.graphics.draw(player.image, player.x, player.y)
    if gameState == 'start' then
        love.graphics.setFont(largeFont)
        love.graphics.printf('Space Shooter CS50!', 0, 30, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to begin!', 0, 140, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        for i, v in ipairs(enemies) do
            love.graphics.setColor(v.color)
            love.graphics.draw(v.image, v.x, v.y, v.rotation, 0.3, 0.3)
        end
    end

    push:apply('end')
end