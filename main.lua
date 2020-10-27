push = require 'push'

WINDOW_WIDTH = 500
WINDOW_HEIGHT = 800
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

---------------------==START==-----------------------

function love.load()
    love.window.setTitle('Space Shooter 50')

    love.graphics.setDefaultFilter('nearest', 'nearest')

    smallFont = love.graphics.newFont('graphics/font.ttf', 5)
    largeFont = love.graphics.newFont('graphics/font.ttf', 18)

    love.graphics.setFont(smallFont)

    song = love.audio.newSource('sounds/soundtrack.ogg', 'stream')

    sounds = {
        ['boom'] = love.audio.newSource('sounds/boom.ogg', 'static'),
        ['shoot'] = love.audio.newSource('sounds/shoot.ogg', 'static'),
        ['win'] = love.audio.newSource('sounds/win.ogg', 'static')
    }

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
    })

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
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'play'
        elseif gameState == 'done' then
            gameState = 'play'
        end
    end
end

function love.update(dt)

end

function love.draw()
    push:apply('start')

    love.graphics.draw(player.image, player.x, player.y)
    if gameState == 'start' then
        love.graphics.setFont(largeFont)
        love.graphics.printf('Space Shooter CS50!', 0, 30, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to begin!', 0, 140, VIRTUAL_WIDTH, 'center')
    end

    push:apply('end')
end