
require "class"

LevelGenerator = class()


function LevelGenerator:_init(width, height, numberOfRoomsToTry, startRoom, startRoomLoc, endRoom, endRoomLoc, otherRooms)
	-- what this does, is it's passed dimensions and filenames for rooms, and number
	-- of rooms, and places to put start and end rooms?
	self.width = width
	self.height = height
	self.numberOfRoomsToTry = numberOfRoomsToTry
	self.startRoomFilename = startRoom
	self.startRoomLoc = startRoomLoc
	self.endRoomFilename = endRoom
	self.endRoomLoc = endRoomLoc
	self.otherRoomFilenames = otherRooms

	self:loadAllRooms()
end

function LevelGenerator:loadAllRooms()
	self.startRoom = self:loadRoom(self.startRoomFilename)
	self.endRoom = self:loadRoom(self.endRoomFilename)
	self.otherRooms = {}
	for i, filename in ipairs(self.otherRoomFilenames) do
		self.otherRooms[#self.otherRooms+1] = self:loadRoom(filename)
	end
end

function LevelGenerator:roomFits(room, loc)
	-- spaces can overlap whatever, but walls + content can only overlap walls in the main level.
	-- this function ensures that that's the case, and that the location/room fits within the bounds of the level
	if loc.x < 1 or loc.y < 1 or loc.x > self.width or loc.y > self.height then
		return false
	end
	for dy = 1, #room.room do
		for dx = 1, #room.room[dy] do
			local y = dy + loc.y
			local x = dx + loc.x
			local tile = room.room[dy][dx]
			if tile ~= " " and (x > self.width or y > self.height) then
				return false -- because the room protrudes outside of the level
			end
			if tile ~= " " and self.level[y][x] ~= "#" then
				return false -- because something overlapped
			end
			-- otherwise it's probably fine, try the next tile.
		end
	end
	return true
end

function LevelGenerator:placeRoomCopy(roomToCopy, loc)
	local room = self:copyRoomTable(roomToCopy)
	room.loc = loc
	-- add it into the level
	for dy = 1, #room.room do
		for dx = 1, #room.room[dy] do
			local tile = room.room[dy][dx]
			if tile ~= " " then
				self.level[loc.y + dy][loc.x + dx] = tile
			end
		end
	end
	-- add the room into the list of rooms so we know to connect it
	table.insert(self.usedRooms, room)
end

function LevelGenerator:randomPlaceRoom(room, maxTries)
	local numTries = 0
	while numTries < maxTries or maxTries == -1 do
		local loc = {x = math.random(1, self.width), y = math.random(1, self.height)}
		if self:roomFits(room, loc) then
			self:placeRoomCopy(room, loc)
			return true
		end
		numTries = numTries + 1
	end
	return false
end

function LevelGenerator:createDirectPath(loc1, loc2)
	if loc1.x >= self.width-1 then
		-- re call it with slightly less wide, so that it can make the paths two wide and still have a wall on the boarder
		return self:createDirectPath({x = loc1.x-1, y = loc1.y}, loc2)
	end
	if loc1.y >= self.height-1 then
		-- re call it with slightly less wide, so that it can make the paths two wide and still have a wall on the boarder
		return self:createDirectPath({x = loc1.x, y = loc1.y-1}, loc2)
	end
	if loc2.x >= self.width-1 then
		-- re call it with slightly less wide, so that it can make the paths two wide
		return self:createDirectPath({x = loc2.x-1, y = loc2.y}, loc1)
	end
	if loc2.y >= self.height-1 then
		-- re call it with slightly less wide, so that it can make the paths two wide
		return self:createDirectPath({x = loc2.x, y = loc2.y-1}, loc1)
	end
	if loc1.x ~= loc2.x and loc1.y ~= loc2.y then
		-- then make two paths recursively, randomly choose to make dx or dy first
		if math.random() > .5 then
			self:createDirectPath(loc1, {x = loc1.x, y = loc2.y})
			self:createDirectPath(loc2, {x = loc1.x, y = loc2.y})
		else
			self:createDirectPath(loc1, {x = loc2.x, y = loc1.y})
			self:createDirectPath(loc2, {x = loc2.x, y = loc1.y})
		end
	else
		-- actually make the path
		local currentX = loc1.x
		local currentY = loc1.y
		while currentX < loc2.x do
			if self.level[currentY][currentX] == "#" then
				self.level[currentY][currentX] = "`"
			end
			if self.level[currentY+1][currentX] == "#" then
				self.level[currentY+1][currentX] = "`"
			end
			currentX = currentX + 1
		end
		while currentX > loc2.x do
			if self.level[currentY][currentX] == "#" then
				self.level[currentY][currentX] = "`"
			end
			if self.level[currentY+1][currentX] == "#" then
				self.level[currentY+1][currentX] = "`"
			end
			currentX = currentX - 1
		end
		-- then set the four things in the corner
		if self.level[currentY+1][currentX+1] == "#" then
			self.level[currentY+1][currentX+1] = "`"
		end
		if self.level[currentY+1][currentX] == "#" then
			self.level[currentY+1][currentX] = "`"
		end
		if self.level[currentY][currentX+1] == "#" then
			self.level[currentY][currentX+1] = "`"
		end
		if self.level[currentY][currentX] == "#" then
			self.level[currentY][currentX] = "`"
		end
		-- then do the y changes.
		while currentY < loc2.y do
			if self.level[currentY][currentX] == "#" then
				self.level[currentY][currentX] = "`"
			end
			if self.level[currentY][currentX+1] == "#" then
				self.level[currentY][currentX+1] = "`"
			end
			currentY = currentY + 1
		end
		while currentY > loc2.y do
			if self.level[currentY][currentX] == "#" then
				self.level[currentY][currentX] = "`"
			end
			if self.level[currentY][currentX+1] == "#" then
				self.level[currentY][currentX+1] = "`"
			end
			currentY = currentY - 1
		end
	end
end

function LevelGenerator:locToString(l)
	return l.x..","..l.y
end

function LevelGenerator:simpleClosest(loc1, loc2)
	return math.abs(loc1.x-loc2.x)+math.abs(loc1.y-loc2.y)
end

function LevelGenerator:checkIfConnected(loc1, loc2)
	local maxNumSteps = 100000
	local defaultGScoreValue = 10000000
	local alreadyEvaluated = {}
	local toEvaluate = {loc1} -- just a table of locations by index, the other ones are by string though
	local toEvaluateDictionary = {[self:locToString(loc1)] = true}
	local cameFrom = {}
	local gScore = {[self:locToString(loc1)] = 0}
	local fScore = {[self:locToString(loc1)] = 0} -- who the hell knows
	local steps = 0
	while #toEvaluate > 0 do
		steps = steps + 1
		if steps > maxNumSteps then
			print("HAD TO RETURN BECAUSE OF STEPS")
			return false, "steps"
		end
		local bestIndex = 1
		for i = 2, #toEvaluate do
			if self:simpleClosest(toEvaluate[i], loc2) < self:simpleClosest(toEvaluate[bestIndex], loc2) then
				bestIndex = i
			end
		end
		local current = toEvaluate[bestIndex] -- because I'm to lazy to evaluate it for now...
		if current.x == loc2.x and current.y == loc2.y then
			-- you've reached the goal
			print("ACTUALLY FOUND IT THE CRAZYNESS HOLY SHIT")
			return true, "connected" -- reconstructPath(cameFrom, current)
		end
		table.remove(toEvaluate, bestIndex)
		toEvaluateDictionary[self:locToString(current)] = nil
		alreadyEvaluated[self:locToString(current)] = true
		for dy = -1, 1, 2 do
			local x = current.x
			local y = current.y+dy
			if y > 1 and y < self.height then
				if self.level[y][x] ~= "#" and self.level[y][x] ~= " " and self.level[y][x] ~= nil then
					if not alreadyEvaluated[self:locToString({x = x, y = y})] then
						alreadyEvaluated[self:locToString({x = x, y = y})] = true
						if not toEvaluateDictionary[self:locToString({x = x, y = y})] then
							toEvaluateDictionary[self:locToString({x = x, y = y})] = true
							table.insert(toEvaluate, {x = x, y = y})
						end
						local tentativeGscore = gScore[self:locToString(current)]+1
						gScore[self:locToString({x = x, y = y})] = tentativeGscore
						-- add the smaller gscore to the gscore dictionary, but I'm probably just doing flood fill?
					end
				end
			end
		end
		for dx = -1, 1, 2 do
			local x = current.x+dx
			local y = current.y
			if x > 1 and x < self.width then
				if self.level[y][x] ~= "#" and self.level[y][x] ~= " " and self.level[y][x] ~= nil then
					if not alreadyEvaluated[self:locToString({x = x, y = y})] then
						alreadyEvaluated[self:locToString({x = x, y = y})] = true
						if not toEvaluateDictionary[self:locToString({x = x, y = y})] then
							toEvaluateDictionary[self:locToString({x = x, y = y})] = true
							table.insert(toEvaluate, {x = x, y = y})
						end
						local tentativeGscore = gScore[self:locToString(current)]+1
						gScore[self:locToString({x = x, y = y})] = tentativeGscore
						-- add the smaller gscore to the gscore dictionary, but I'm probably just doing flood fill?
					end
				end
			end
		end
	end
	print("COULDN'T FIND ITasldfjlkasjdflkajsldkjf")
	return false, "not connected"
end

function LevelGenerator:strFromCoords(x, y)
	return x .. ","..y
end

function LevelGenerator:bruteForceCheckIfConnected()
	local connectedTable = {}
	local toAdd = {{x = self.usedRooms[1].access.x+self.usedRooms[1].loc.x, y = self.usedRooms[1].access.y+self.usedRooms[1].loc.y}}

	while #toAdd > 0 do
		local current = toAdd[1]
		local strLoc = self:locToString(current)
		-- print(strLoc)
		local y = current.y
		local x = current.x
		table.remove(toAdd, 1)
		if not connectedTable[strLoc] then
			-- add it to str loc and add its neighbors
			connectedTable[strLoc] = true
			if x-1 > 0 then
				if self.level[y][x-1] ~= "#" and self.level[y][x-1] ~= " " then
					-- add it to check
					table.insert(toAdd, {x = x-1, y = y})
				end
			end
			if x+1 <= self.width then
				if self.level[y][x+1] ~= "#" and self.level[y][x+1] ~= " " then
					-- add it to check
					table.insert(toAdd, {x = x+1, y = y})
				end
			end
			if y-1 > 0 then
				if self.level[y-1][x] ~= "#" and self.level[y-1][x] ~= " " then
					-- add it to check
					table.insert(toAdd, {x = x, y = y-1})
				end
			end
			if y+1 <= self.height then
				if self.level[y+1][x] ~= "#" and self.level[y+1][x] ~= " " then
					-- add it to check
					table.insert(toAdd, {x = x, y = y+1})
				end
			end
		end
	end

	local numNotConnected = 0
	for y = 1, self.height do
		for x = 1, self.width do
			if self.level[y][x] ~= "#" and self.level[y][x] ~= " " then
				if not connectedTable[self:strFromCoords(x, y)] then
					numNotConnected = numNotConnected + 1
					if self.level[y][x] ~= "_" then
						self.level[y][x] = "f"
					else
						error("Error in map generation: Start is not connected to itself, what?")
					end
				end
			end
		end
	end
	local numUnconnectedRooms = 0
	for i, room in ipairs(self.usedRooms) do
		if not room.connected then
			numUnconnectedRooms = numUnconnectedRooms + 1
		end
	end
	print(numNotConnected.." not connected to the start")
	print(numUnconnectedRooms .. " rooms not connected")
	if numUnconnectedRooms > 0 then
		print("WTF?")
	end
end

function LevelGenerator:generateLevel()
	self.level = {}
	for y = 1, self.height do
		self.level[#self.level+1] = {}
		for x = 1, self.width do
			self.level[#self.level][#self.level[#self.level]+1] = "#" -- set it to be wall.
		end
	end
	self.usedRooms = {}

	if self:roomFits(self.startRoom, self.startRoomLoc) then
		self:placeRoomCopy(self.startRoom, self.startRoomLoc)
	else
		self:randomPlaceRoom(self.startRoom, -1)
		-- local loc = {x = -1, y = -1}
		-- while not self:roomFits(self.startRoom, loc) do
		-- 	loc.x = math.random(1, self.width)
		-- 	loc.y = math.random(1, self.height)
		-- end
		-- self:placeRoomCopy(self.startRoom, loc)
	end
	if self:roomFits(self.endRoom, self.endRoomLoc) then
		self:placeRoomCopy(self.endRoom, self.endRoomLoc)
	else
		self:randomPlaceRoom(self.endRoom, -1)
		-- local loc = {x = -1, y = -1}
		-- while not self:checkRoomPlacement(self.endRoom, loc) do
		-- 	loc.x = math.random(1, self.width)
		-- 	loc.y = math.random(1, self.height)
		-- end
		-- self:placeRoomCopy(self.endRoom, loc)
	end

	local roomsPlaced = 2
	if #self.otherRooms > 0 then
		for i = 1, self.numberOfRoomsToTry do
			print("trying to place a room")
			local tryRoom = self.otherRooms[math.random(1, #self.otherRooms)]
			if self:randomPlaceRoom(tryRoom, 10) then
				roomsPlaced = roomsPlaced + 1
			end
		end
	end
	print(roomsPlaced.." rooms placed into the map.")

	self:connectUsedRooms()
	self:ensureConnected()
	self:bruteForceCheckIfConnected()
end

function LevelGenerator:ensureConnected()
	for i, room in ipairs(self.usedRooms) do
		print("checking if room "..i.." is connected")
		if i > 2 then
			-- the first two rooms are the start room and the end room
			local fixed = false
			local connected, reason = self:checkIfConnected({x = room.access.x+room.loc.x, y = room.access.y+room.loc.y},
					{x = self.usedRooms[1].access.x+self.usedRooms[1].loc.x, y = self.usedRooms[1].access.y+self.usedRooms[1].loc.y})
			while not fixed and not connected do
				if reason == "steps" then
					error("steps")
				end
				-- connect it to a random room that is not itself
				-- local otherRoomI = i
				-- while otherRoomI == i do
				-- 	otherRoomI = math.random(1, i-1)
				-- end
				-- self:connectRooms(room, self.usedRooms[otherRoomI])
				-- the above is connecting to a random room
				-- this is connecting to the closest, not yet connected, room
				self:connectRoomToClosest(room)
				-- fixed = true
				connected, reason = self:checkIfConnected({x = room.access.x+room.loc.x, y = room.access.y+room.loc.y},
					{x = self.usedRooms[1].access.x+self.usedRooms[1].loc.x, y = self.usedRooms[1].access.y+self.usedRooms[1].loc.y})
			end
		end
	end
end

function LevelGenerator:findClosestEntrances(r1, r2)
	local bestEntrance1 = -1
	local bestEntrance2 = -1
	local bestDistance = -1
	for i, e1 in ipairs(r1.entrances) do
		for j, e2 in ipairs(r2.entrances) do
			local dx = (e1.x+r1.loc.x)-(e2.x+r2.loc.x)
			local dy = (e1.y+r1.loc.y)-(e2.y+r2.loc.y)
			local distance = math.sqrt(dx*dx+dy*dy)
			if distance < bestDistance or bestDistance == -1 then
				bestDistance = distance
				bestEntrance2 = e2
				bestEntrance1 = e1
			end
		end
	end
	return {x = bestEntrance1.x+r1.loc.x, y = bestEntrance1.y+r1.loc.y},
				{x = bestEntrance2.x+r2.loc.x, y = bestEntrance2.y+r2.loc.y}, bestDistance
end

function LevelGenerator:connectRooms(r1, r2)
	local l1, l2, dist = self:findClosestEntrances(r1, r2)
	if dist == -1 then
		print("Level Generation Error: UNABLE TO CONNECT ROOMS, IDK WHY")
		return false -- maybe error?
	end
	r1.connected = true -- although not necisarily, because of loops
	r2.connected = true -- although see above
	table.insert(r1.connectedRooms, r2)
	table.insert(r2.connectedRooms, r1)
	self:createDirectPath(l1, l2)
end

function LevelGenerator:findClosestRoom(r1, ignoreList)
	-- finds the closest room to r1
	if ignoreList == nil then
		ignoreList = {}
	end
	local closestRoom = -1
	local closestDistance = -1
	for i, r2 in ipairs(self.usedRooms) do
		local skipRoom = false
		for j, ignoreRoom in ipairs(ignoreList) do
			if ignoreRoom == r2 then
				-- skip it
				skipRoom = true
			end
		end
		if r2 ~= r1 and not skipRoom then
			local l1, l2, distance = self:findClosestEntrances(r1, r2)
			if distance < closestDistance or closestDistance == -1 then
				closestRoom = r2
				closestDistance = distance
			end
		end
	end
	return closestRoom, distance
end

function LevelGenerator:connectUsedRooms()
	for i = #self.usedRooms-1, 1, -1 do
		-- local connectTo = i
		-- while connectTo == i do
		-- 	connectTo = math.random(i, #self.usedRooms)
		-- end
		-- self:connectRooms(self.usedRooms[i], self.usedRooms[connectTo])
		if not self.usedRooms[i].connected then
			self:connectRoomToClosest(self.usedRooms[i])
		end
	end
end

function LevelGenerator:connectRoomToClosest(room)
	local closestRoom, distance = self:findClosestRoom(room, room.connectedRooms)
	if closestRoom == -1 then
		print("CLOSEST ROOM IS -1 OH GOD")
		print(room)
		print(room.filename)
		error()
		closestRoom, distance = self:findClosestRoom(room)
	end
	self:connectRooms(room, closestRoom)
end

function LevelGenerator:loadRoom(filename)
	local roomTable = {connected = false, entrances = {}, room = {}, specialItems = {}, enemies = {},
						loc = {x = -1, y = -1}, chance = 1, access = {x = -1 , y = -1}, connectedRooms = {},
						filename = filename}
	-- chance is a float from 0 to 1 inclusive, if a random number is less than the chance, then it is used. idk.

	-- entrances, enemies, and special items are listed at the end of the file with coordinates
	-- and entrance/special/enemies/chance
	local loadMode = "room" -- or it could be the extras
	local dataMode = ""
	local inData = {}
	-- local roomTable.room = {}
	for line in love.filesystem.lines(filename) do
		if string.sub(line, 1, 2) == "--" then
			-- ignore the line
		elseif #line == 0 then
			-- ignore it as well
		elseif line == "DATA:" then
			loadMode = "data"
		elseif loadMode == "room" then
			roomTable.room[#roomTable.room+1] = {}
			for i = 1, #line do
				 -- add the character to the end of the table
				roomTable.room[#roomTable.room][#roomTable.room[#roomTable.room]+1] = string.sub(line, i, i)
				-- print(#roomTable.room)
				-- print(#roomTable.room[1])
			end
		elseif loadMode == "data" then
			-- then additional stuff is input, maybe enemies or doors or whatever. or chance to be picked
			if dataMode == "" then
				dataMode = line
			elseif dataMode == "entrance" then
				inData = {x = tonumber(line), y = -1}
				dataMode = "entrance2"
			elseif dataMode == "entrance2" then
				inData.y = tonumber(line)
				table.insert(roomTable.entrances, inData)
				dataMode = ""
			elseif dataMode == "access" then
				inData = {x = tonumber(line), y = -1}
				dataMode = "access2"
			elseif dataMode == "access2" then
				inData.y = tonumber(line)
				roomTable.access = inData
				dataMode = ""
			end
		end
	end
	return roomTable
end

function LevelGenerator:copyRoomTable(roomTable)
	local newRoomTable = {connected = false, entrances = roomTable.entrances, room = roomTable.room, connectedRooms = {},
							enemies = roomTable.enemies, loc = {x = -1, y = -1}, access = roomTable.access,
										filename = roomTable.filename}
	return newRoomTable
end