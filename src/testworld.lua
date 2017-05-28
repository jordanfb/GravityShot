
require "class"
require "player"
require "level"

TestWorld = class()

-- _init, load, draw, update(dt), keypressed, keyreleased, mousepressed, mousereleased, resize, (drawUnder, updateUnder)

function TestWorld:_init(game, inputManager)
	-- this is for the draw stack
	self.drawUnder = false
	self.updateUnder = false

	self.game = game
	self.inputManager = inputManager

	self.level = Level(self.game)
	self.level:reloadLevel()

	self.player = Player(self.game, self.level, self.inputManager)
	self.floor = love.graphics.getHeight()


	self.player.loc.x = self.level.playerspawns[1][1]
	self.player.loc.y = self.level.playerspawns[1][2]

	self.timeFractionMax = 8
	self.currentTimeFraction = 1
end

function TestWorld:load()
	-- run when the level is given control
end

function TestWorld:leave()
	-- run when the level no longer has control
end

function TestWorld:draw()
	local scale = .5
	local halfX = love.graphics.getWidth()/2
	local halfY = love.graphics.getHeight()/2
	self.level:drawbase(self.player.loc.x-halfX, self.player.loc.y-halfY, love.graphics.getWidth(), love.graphics.getHeight(), scale, scale)
	self.player:draw(self.player.loc.x-halfX, self.player.loc.y-halfY, love.graphics.getWidth(), love.graphics.getHeight(), scale, scale)
end

function TestWorld:update(dt)
	local worldTime = dt
	if self.inputManager:isDown("zerogravity") then
		self.currentTimeFraction = self.currentTimeFraction + 1
		if self.currentTimeFraction > self.timeFractionMax then
			self.currentTimeFraction = self.timeFractionMax
		end
	else
		self.currentTimeFraction = self.currentTimeFraction - 1
		if self.currentTimeFraction < 1 then
			self.currentTimeFraction = 1
		end
	end
	worldTime = worldTime / self.currentTimeFraction
	self.player:update(worldTime)
	self.level:update(worldTime)
end

function TestWorld:checkCollisions(x, y, width, height, dx, dy, dt)
	-- returns on floor, and new coords/velocity
	local onFloor = false
	if y + height/2 + dy*dt > self.floor then
		y = self.floor-height/2
		dy = 0
		onFloor = true
	else
		y = y + dy
	end
	if x + width/2 + dx*dt > love.graphics.getWidth() and dx > 0 then
		x = love.graphics.getWidth()-width/2
		dx = 0
	elseif x - width/2 + dx*dt < 0 and dx < 0 then
		x = width/2
		dx = 0
	else
		x = x + dx
	end
	return {x, y, dx, dy, onFloor}
end

function TestWorld:resize(w, h)
	--
end

function TestWorld:keypressed(key, unicode)
	--
end

function TestWorld:keyreleased(key, unicode)
	--
end

function TestWorld:mousepressed(x, y, button)
	--
end

function TestWorld:mousereleased(x, y, button)
	--
end

function TestWorld:mousemoved(x, y, dx, dy, istouch)
	--
end