
require "class"
require "testworld"
require "inputmanager"

Game = class()

function Game:_init()
	-- these are for draw stacks:
	self.drawUnder = false
	self.updateUnder = false
	math.randomseed(os.time())

	-- here are the actual variables
	self.SCREENWIDTH = 1920
	self.SCREENHEIGHT = 1200
	self.fullscreen = false
	love.window.setFullscreen(self.fullScreen)
	self.playerLimit = 2

	self.inputManager = InputManager(self)

	self.testWorld = TestWorld(self, self.inputManager)
	
	self.screenStack = {}
	
	love.graphics.setBackgroundColor(0, 0, 0)
	self:addToScreenStack(self.testWorld)
	-- self:addToScreenStack(self.gameplay)
	-- self.fullCanvas = love.graphics.newCanvas(self.SCREENWIDTH, self.SCREENHEIGHT)
end

function Game:load(args)
	love.mouse.setVisible(false)
end

function Game:takeScreenshot()
	local screenshot = love.graphics.newScreenshot()
	screenshot:encode('png', os.time()..'.png')
end

function Game:calculateDrawUpdateLevels()
	self.drawLayersStart = 1 -- this will become the index of the lowest item to draw
	for i = #self.screenStack, 1, -1 do
		self.drawLayersStart = i
		if not self.screenStack[i].drawUnder then
			break
		end
	end
end

function Game:draw()
	-- this is so that the things earlier in the screen stack get drawn first, so that things like pause menus get drawn on top.
	for i = self.drawLayersStart, #self.screenStack, 1 do
		self.screenStack[i]:draw()
	end

	-- love.graphics.setCanvas()
	-- love.graphics.setColor(255, 255, 255)
	if self.debug then
		love.graphics.setColor(255, 0, 0)
		love.graphics.print("FPS: "..love.timer.getFPS(), 10, love.graphics.getHeight()-45)
		love.graphics.setColor(255, 255, 255)
	end
end

function Game:update(dt)
	-- self.joystickManager:update(dt)
	for i = #self.screenStack, 1, -1 do
		self.screenStack[i]:update(dt)
		if self.screenStack[i] and not self.screenStack[i].updateUnder then
			break
		end
	end
	self.inputManager:update(dt)
end

function Game:popScreenStack()
	self.screenStack[#self.screenStack]:leave()
	self.screenStack[#self.screenStack] = nil
	self.screenStack[#self.screenStack]:load()
	self:calculateDrawUpdateLevels()
end

function Game:addToScreenStack(newScreen)
	if self.screenStack[#self.screenStack] ~= nil then
		self.screenStack[#self.screenStack]:leave()
	end
	self.screenStack[#self.screenStack+1] = newScreen
	newScreen:load()
	self:calculateDrawUpdateLevels()
end

function Game:resize(w, h)
	-- this is really useless, since it doesn't resize things not on screen, which could cause errors...
	for i = 1, #self.screenStack, 1 do
		self.screenStack[i]:resize(w, h)
	end
end

function Game:keypressed(key, unicode)
	self.screenStack[#self.screenStack]:keypressed(key, unicode)
	if key == "f2" or key == "f11" then
		self.fullscreen = not self.fullscreen
		love.window.setFullscreen(self.fullscreen)
	elseif key == "f3" then
		self:takeScreenshot()
	elseif key == "f1" then
		love.event.quit()
	elseif key == "f8" then
		love.window.setMode(self.SCREENWIDTH/2, self.SCREENHEIGHT/2, {resizable = true})
	end
	self.inputManager:keypressed(key, unicode)
end

function Game:keyreleased(key, unicode)
	self.screenStack[#self.screenStack]:keyreleased(key, unicode)

	self.inputManager:keyreleased(key, unicode)
end

function Game:mousepressed(x, y, button)
	self.screenStack[#self.screenStack]:mousepressed(x, y, button)
	self.useJoystick = false
end

function Game:mousereleased(x, y, button)
	self.screenStack[#self.screenStack]:mousereleased(x, y, button)
end

function Game:joystickadded(joystick)
	self.inputManager:getJoysticks()
end

function Game:joystickremoved(joystick)
	self.inputManager:getJoysticks()
end

function Game:quit()
	--
end

function Game:mousemoved(x, y, dx, dy, istouch)
	self.screenStack[#self.screenStack]:mousemoved(x, y, dx, dy, istouch)
	love.mouse.setVisible(true)
end

function Game:wheelmoved(x, y)
	self.screenStack[#self.screenStack]:wheelmoved(x, y)
end

function Game:gamepadpressed(gamepad, button)
	self.inputManager:gamepadpressed(gamepad, button)
end

function Game:gamepadreleased(gamepad, button)
	self.inputManager:gamepadreleased(gamepad, button)
end

function Game:gamepadaxis(joystick, axis, value)
	self.inputManager:gamepadaxis(joystick, axis, value)
end