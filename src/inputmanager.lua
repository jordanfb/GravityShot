
require "class"

InputManager = class()

function InputManager:_init(game)
	self.game = game
	self.joysticks = {}
	self.gamepads = {}
	self.useJoystick = false

	self.deadzone = .2 -- whether or not to ignore it when checking if the action is down
	self.inputs = {moveleft = 0, moveright = 0, moveup = 0, movedown = 0, lookleft = 0, lookright = 0, lookdown = 0, lookup = 0, zerogravity = 0}

	-- this is for keymapping:
	self.actionKeyMap = {moveleft = "a", moveright = "d", movedown = "s", moveup = "w",
				lookleft = "left", lookright = "right", lookup = "up", lookdown = "down", zerogravity = "lshift"}
	self.menuKeyMap = {menuleft = "a", menuright = "d", menuup = "w", menudown = "s"}

	-- this is for mapping presses to actions
	self.keyActionMap = {a = "moveleft", d = "moveright", s = "movedown", w = "moveup",
				left = "lookleft", right = "lookright", up = "lookdown", down = "lookup", lshift = "zerogravity"}
	self.keyMenuMap = {a = "menuleft", d = "menuright", s = "menudown", w = "menuup"}

	self.inMenu = false
end

function InputManager:addjoystick(joystick)
	self:getJoysticks()
end

function InputManager:removejoystick(joystick)
	self:getJoysticks()
end

function InputManager:getJoysticks()
	self.joysticks = love.joystick.getJoysticks()
	for k, v in pairs(self.joysticks) do
		if v:isGamepad() then
			self.gamepads[#self.gamepads+1] = v
		end
	end
	if #self.gamepads == 0 then
		self.useJoystick = false
	else
		self.useJoystick = true
	end
end

function InputManager:hasJoysticks()
	self:getJoysticks()
	return #self.gamepads > 0
end

function InputManager:gamepadpressed(gamepad, button)
	self.game:keypressed("joystick"..button, "")
	love.mouse.setVisible(false)
end

function InputManager:gamepadreleased(gamepad, button)
	self.game:keyreleased("joystick"..button, "")
	love.mouse.setVisible(false)
end

function InputManager:update(dt)
	-- if self.flickTimer > 0 then
	-- 	self.flickTimer = self.flickTimer - dt
	-- 	if self.flickTimer < 0 then
	-- 		self.flickTimer = 0
	-- 	end
	-- end
end

function InputManager:keypressed(key, unicode)
	love.mouse.setVisible(false)
	if self.keyActionMap[key] ~= nil then
		self.inputs[self.keyActionMap[key]] = 1
	end
	if self.inMenu and self.keyMenuMap[key] ~= nil then
		-- send a menu message to the keypresses for use elsewhere.
		self.game:keypressed(self.keyMenuMap[key], "")
	end
end

function InputManager:keyreleased(key, unicode)
	if self.keyActionMap[key] ~= nil then
		self.inputs[self.keyActionMap[key]] = 0
	end
end

function InputManager:isDown(action)
	-- returns whether or not it's greater than whatever deadzone value we specify
	return self.inputs[action] > self.deadzone
end

function InputManager:getState(action)
	return self.inputs[action]
end

function InputManager:gamepadaxis( joystick, axis, value )
	-- if math.abs(value) > .25 then
	-- 	love.mouse.setVisible(false)
	-- end

	-- -- menu flicking:
	-- if axis == "leftx" then
	-- 	local changeX = value-self.leftx
	-- 	if value > .1 then
	-- 		if changeX > 0 then
	-- 			if not self.leftflickright and self.flickTimer <= 0 then
	-- 				self.game:keypressed("menuRight", "")
	-- 				self.leftflickright = true
	-- 				self.flickTimer = self.flickTimerStart
	-- 			end
	-- 		else
	-- 			self.leftflickright = false
	-- 		end
	-- 	elseif value < -.1 then
	-- 		if changeX < 0 then
	-- 			if not self.leftflickleft and self.flickTimer <= 0 then
	-- 				self.game:keypressed("menuLeft", "")
	-- 				self.leftflickleft = true
	-- 				self.flickTimer = self.flickTimerStart
	-- 			end
	-- 		else
	-- 			self.leftflickleft = false
	-- 		end
	-- 	elseif math.abs(value) < .1 then
	-- 		self.leftflickright = false
	-- 		self.leftflickleft = false
	-- 	end
	-- 	self.leftx = value
	-- elseif axis == "lefty" then
	-- 	local changeY = value-self.lefty
	-- 	if value > .1 then -- it's lower half
	-- 		if changeY > 0 then
	-- 			if not self.leftflickdown and self.flickTimer <= 0 then
	-- 				self.game:keypressed("menuDown", "")
	-- 				self.leftflickdown = true
	-- 				self.flickTimer = self.flickTimerStart
	-- 			end
	-- 		else
	-- 			self.leftflickdown = false
	-- 		end
	-- 	elseif value < -.1 then
	-- 		if changeY < 0 then
	-- 			if not self.leftflickup and self.flickTimer <= 0 then
	-- 				self.game:keypressed("menuUp", "")
	-- 				self.leftflickup = true
	-- 				self.flickTimer = self.flickTimerStart
	-- 			end
	-- 		else
	-- 			self.leftflickup = false
	-- 		end
	-- 	elseif math.abs(value) < .1 then
	-- 		self.leftflickup = false
	-- 		self.leftflickdown = false
	-- 	end
	-- 	self.lefty = value
	-- end

	-- if axis == "rightx" then
	-- 	local changeX = value-self.rightx
	-- 	if value > .1 then
	-- 		if changeX > 0 then
	-- 			if not self.rightflickright and self.flickTimer <= 0 then
	-- 				self.game:keypressed("menuRight", "")
	-- 				self.rightflickright = true
	-- 				self.flickTimer = self.flickTimerStart
	-- 			end
	-- 		else
	-- 			self.rightflickright = false
	-- 		end
	-- 	elseif value < -.1 then
	-- 		if changeX < 0 then
	-- 			if not self.rightflickleft and self.flickTimer <= 0 then
	-- 				self.game:keypressed("menuLeft", "")
	-- 				self.rightflickleft = true
	-- 				self.flickTimer = self.flickTimerStart
	-- 			end
	-- 		else
	-- 			self.rightflickleft = false
	-- 		end
	-- 	elseif math.abs(value) < .1 then
	-- 		self.rightflickright = false
	-- 		self.rightflickleft = false
	-- 	end
	-- 	self.rightx = value
	-- elseif axis == "righty" then
	-- 	local changeY = value-self.righty
	-- 	if value > .1 then -- it's lower half
	-- 		if changeY > 0 then
	-- 			if not self.rightflickdown and self.flickTimer <= 0 then
	-- 				self.game:keypressed("menuDown", "")
	-- 				self.rightflickdown = true
	-- 				self.flickTimer = self.flickTimerStart
	-- 			end
	-- 		else
	-- 			self.rightflickdown = false
	-- 		end
	-- 	elseif value < -.1 then
	-- 		if changeY < 0 then
	-- 			if not self.rightflickup and self.flickTimer <= 0 then
	-- 				self.game:keypressed("menuUp", "")
	-- 				self.rightflickup = true
	-- 				self.flickTimer = self.flickTimerStart
	-- 			end
	-- 		else
	-- 			self.rightflickup = false
	-- 		end
	-- 	elseif math.abs(value) < .1 then
	-- 		self.rightflickup = false
	-- 		self.rightflickdown = false
	-- 	end
	-- 	self.lefty = value
	-- end
end