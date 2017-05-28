
require "class"

Player = class()

function Player:_init(game, level, inputManager)
	self.game = game
	self.level = level
	self.inputManager = inputManager
	self.loc = {x = 0, y = 500, dx = 0, dy = 1}
	self.maxHorizontalSpeed = 1000 -- 10
	self.width = 50
	self.height = 100
	self.friction = .9
	self.gravity = 10000 -- 100
	self.horizontalAcceleration = 10000000
	self.onFloor = false
	self.onFloorCounter = 0

	self.shotTimer = 0 -- for shooting your gun
end

function Player:setPos(x, y)
	self.loc.x = x
	self.loc.y = y
end

function Player:update(dt)
	-- note that this dt is already changed to be slower if slow mode is running.
	local ax = self.inputManager:getState("moveright") - self.inputManager:getState("moveleft")
	if not self.onFloor then 
		ax = 0
	end

	local ay = self.gravity
	if self.inputManager:isDown("zerogravity") then
		ay = 0
	end
	if self.inputManager:getState("moveup") > 0 and self.onFloor then
		ay = -10000
		self.loc.dy = -2000
	end

	self.loc.dy = self.loc.dy + ay*dt
	self.loc.dx = self.loc.dx + ax*dt*self.horizontalAcceleration

	if ax == 0 and self.onFloor then
		self.loc.dx = self.loc.dx * self.friction
	end
	if self.loc.dx < -self.maxHorizontalSpeed then
		self.loc.dx = -self.maxHorizontalSpeed
	elseif self.loc.dx > self.maxHorizontalSpeed then
		self.loc.dx = self.maxHorizontalSpeed
	end

	-- local afterCollisions = self.world:checkCollisions(self.loc.x, self.loc.y, self.width, self.height, self.loc.dx, self.loc.dy, dt)
	-- self.loc.x = afterCollisions[1]
	-- self.loc.y = afterCollisions[2]
	-- self.loc.dx = afterCollisions[3]
	-- self.loc.dy = afterCollisions[4]
	-- self.onFloor = afterCollisions[5]
	local shotTimeout = .25
	local shotPower = 5000
	if self.shotTimer > 0 then
		self.shotTimer = self.shotTimer - dt
	end
	self.shooting = false
	if love.keyboard.isDown("left") and self.shotTimer <= 0 then
		self.loc.dx = self.loc.dx + shotPower
		self.shooting = true
		-- self.shotTimer = shotTimeout
	end
	if love.keyboard.isDown("right") and self.shotTimer <= 0 then
		self.loc.dx = self.loc.dx - shotPower
		self.shooting = true
		-- self.shotTimer = shotTimeout
	end
	if love.keyboard.isDown("up") and self.shotTimer <= 0 then
		self.loc.dy = self.loc.dy + shotPower
		self.shooting = true
		-- self.shotTimer = shotTimeout
	end
	if love.keyboard.isDown("down") and self.shotTimer <= 0 then
		self.loc.dy = self.loc.dy - shotPower
		self.shooting = true
		-- self.shotTimer = shotTimeout
	end
	if self.shooting then
		self.shotTimer = shotTimeout
	end
	local afterCollisions = self.level:checkBothCollisions(self.loc.x, self.loc.y, self.loc.dx*dt, self.loc.dy*dt, self.width, self.height)
	self.loc.x = afterCollisions[1]
	if afterCollisions[4] then
		if self.loc.dy > 0 and not self.inputManager:isDown("zerogravity") then
			self.onFloorCounter = 5
			self.onFloor = true
			self.loc.dy = 0
			self.loc.y = afterCollisions[2]
		elseif self.loc.dy < 0 then
			self.loc.dy = 0
		elseif self.loc.dy < 0 and self.inputManager:isDown("zerogravity") then
			self.onFloorCounter = self.onFloorCounter - 1
			if self.onFloorCounter <= 0 then
				self.onFloor = false
			end
		end
	else
		self.onFloorCounter = self.onFloorCounter - 1
		if self.onFloorCounter <= 0 then
			self.onFloor = false
		end
		self.loc.y = afterCollisions[2]
	end
	if afterCollisions[3] then
		self.loc.dx = 0
	end
end

function Player:draw(focusX, focusY, width, height, xscale, yscale)
	local drawX = math.floor(self.loc.x-focusX)*xscale
	local drawY = math.floor(self.loc.y-focusY)*yscale
	if self.shooting then
		love.graphics.setColor(255, 0, 0)
	elseif self.onFloor then
		love.graphics.setColor(0, 255, 0)
	else
		love.graphics.setColor(255, 255, 255)
	end
	love.graphics.rectangle("fill", drawX-self.width/2*xscale, drawY-self.height/2*yscale, self.width*xscale, self.height*yscale)
end