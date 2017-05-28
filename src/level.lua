
require "class"
require "levelgenerator"

Level = class()

--[[
Level is where the whole level gets stored, and when I draw the game this gets drawn with an offset specific to the canvas
it's drawing to. Yes. My pretty. Currently I'll probably load the level from a text file, but I may try for procedurally generated
stuff slightly later.
I'll probably do a single text file with two characters per tile? That way I can store more things which is a yay!
]]--
local totalNumSides = 0
local totalNumWalls = 0

function Level:_init(game)
	self.game = game

	self.crawlerChance = 1
	self.spitterChance = 1
	self.ballChance = 1
	self.maxNumberOfEnemies = 50

	self.tilesetFilename = "tileset" -- it adds on the rest of the path itself.
	self.tilesetHeight = 6
	self.tilesetWidth = 8
	self.tileScale = 4
	self.tileWidth = 32*self.tileScale
	self.tileHeight = 32*self.tileScale

	self.levelWidth = 60
	self.levelHeight = 30
	self.numberOfRoomsToTry = 20
	self.startRoomFilename = "rooms/startRoom1.txt"
	self.endRoomFilename = "rooms/endRoom1.txt"
	self.otherRoomFilenames = {3, 4, 5}
	for i = 1, #self.otherRoomFilenames do
		self.otherRoomFilenames[i] = "rooms/room"..self.otherRoomFilenames[i]..".txt"
	end
	self.levelGenerator = LevelGenerator(self.levelWidth, self.levelHeight, self.numberOfRoomsToTry, self.startRoomFilename,
									{x = 5, y = -10}, self.endRoomFilename, {x = 60, y = -10}, self.otherRoomFilenames)
	-- width, height, startRoom, startRoomLoc, endRoom, endRoomLoc, otherRooms
	
	self:reloadLevel()
	self:loadTileset(self.tilesetFilename)

	self:loadCollidingTiles()
	self.debugCollisionHighlighting = {}
end

function Level:generateNewLevel()
	self.levelGenerator:generateLevel()
	self.level = self.levelGenerator.level
end

function Level:reloadLevel()
	print("Loading Level")
	self:resetLevel()
	if self.game.useOldLevel then
		local level = self:loadLevelTableFromFile("level1.txt")
		self:interpretLevelTable(level.levelTable)
	else
		self:generateNewLevel()
		self:interpretLevelTable(self.level)
	end
	print("total num sides: "..totalNumSides)
	print("total num walls: "..totalNumWalls)
	print("Average number of sides per wall: "..totalNumSides/totalNumWalls)
	print("Finished Loading Level")
end

function Level:loadCollidingTiles()
	self.collidingTiles = {}
	for line in love.filesystem.lines("rooms/collidingtilesetkey.txt") do
		self.collidingTiles[line] = true
	end
end

function Level:loadTileset(filename)
	-- essentially we have a tileset.png and a tilesetkey.txt
	-- the key has the character used in level files to designate the tile at that spot in the .png
	local tilesetMeaning = {}
	for line in love.filesystem.lines("images/"..filename.."key.txt") do
		for i=1, #line do
			tilesetMeaning[#tilesetMeaning+1] = string.sub(line, i, i)
		end
	end
	self.tilesetImage = love.graphics.newImage("images/"..filename..".png")
	local imageWidth = self.tilesetImage:getWidth()
	local imageHeight = self.tilesetImage:getHeight()
	self.tilesetQuads = {} -- a dictionary from what it's refered to in the levelmap file to the quad
	local i = 1
	for y = 0, self.tilesetHeight-1 do
		for x = 0, self.tilesetWidth-1 do
			-- print(x..", "..y..": "..tilesetMeaning[i])
			self.tilesetQuads[tilesetMeaning[i]] = love.graphics.newQuad(x*self.tileWidth, y*self.tileHeight,
										self.tileWidth, self.tileHeight, imageWidth, imageHeight)
			i = i + 1
		end
	end
end

function Level:resetLevel()
	self.difficulty = 0
	self.score = 0
	self.killed = 0
	-- self.levelWidth = -1
	-- self.levelHeight = -1
	self.playTime = 0
	-- self.levelbase = {} -- what gets drawn below everything?
	-- self.leveltop = {} -- what gets drawn above everything? maybe not happening, but still... doors, railings? lights?
	-- you probably can't collide with anything in leveltop, just levelbase.
	self.bullets = {}
	self.enemies = {}
	self.totalNumberOfEnemies = 0
	self.numberOfEnemies = 0
	self.bloodstainsOffset = math.random(0, 16)
	self.bloodstains = {}
	-- self.blemishes = {} -- the marks made by bullets
end

function Level:determineWall(x, y, levelTable)
	local surroundings = {' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '}
	local checkNumber = 1
	for dy = -1, 1 do
		if (y == 1 and dy == -1) or (y == #levelTable and dy == 1) then
			-- skip it
			checkNumber = checkNumber + 3
		else
			for dx = -1, 1 do
				if (x == 1 and dx == -1) or (x == #levelTable[y] and dx == 1) then
					-- skip it
				else
					-- actually check it
					surroundings[checkNumber] = levelTable[y+dy][x+dx]
				end
				checkNumber = checkNumber + 1
			end
		end
	end
	-- now we know all the tiles, so now we figure out what it should be.
	-- we only know a few things, we know empty tiles, and we know wall tiles.
	-- Assume that everything aside from '#' and ' ' is a floor tile, represented by '_'
	local allSides = ""
	local hasFloor = false
	for i = 1, #surroundings do
		if surroundings[i] ~= " " and surroundings[i] ~= "#" then
			-- print(surroundings[i])
			surroundings[i] = "_"
			hasFloor = true
		end
		allSides = allSides .. surroundings[i]
	end
	if not hasFloor then
		return " "
	end
	local tile = {}
	local numberOfWalls = 0
	if surroundings[2] == "_" then
		-- it has to be a wall there
		tile[#tile+1] = "2"
		numberOfWalls = numberOfWalls + 1
	elseif surroundings[2] == "#" then
		if surroundings[3] == "_" then
			tile[#tile+1] = ","
		end
	end
	if surroundings[4] == "_" then
		-- it has to be a wall there
		tile[#tile+1] = "4"
		numberOfWalls = numberOfWalls + 1
	elseif surroundings[4] == "#" then
		if surroundings[1] == "_" then
			tile[#tile+1] = "."
		end
	end
	if surroundings[6] == "_" then
		-- it has to be a wall there
		tile[#tile+1] = "6"
		numberOfWalls = numberOfWalls + 1
	elseif surroundings[6] == "#" then
		-- if surroundings[3] == "_" then
		-- 	tile[#tile+1] = ","
		-- end
		if surroundings[9] == "_" then
			tile[#tile+1] = ";"
		end
	end
	if surroundings[8] == "_" then
		-- it has to be a wall there
		tile[#tile+1] = "8"
		numberOfWalls = numberOfWalls + 1
	elseif surroundings[8] == "#" then
		if surroundings[7] == "_" then
			tile[#tile+1] = ":"
		end
	end
	local numberOfWallSegmentsPreOptimization = #tile
	local cornerWallReplaceTable = {[{".", "2"}]="2", [{",", "2"}]="2",
								[{".", "4"}]="4", [{":", "4"}]="4",
								[{";", "6"}]="6", [{",", "6"}]="6",
								[{":", "8"}]="8", [{";", "8"}]="8"}
	self:replaceStuff(cornerWallReplaceTable, tile)
	local fourWallReplacementTable = {[{"2", "4", "6", "8"}]="#"}
	self:replaceStuff(fourWallReplacementTable, tile)
	local threeWallReplacementTable = {[{"2", "4", "6"}]="n", [{"8", "4", "6"}]="u", [{"2", "4", "8"}]="<", [{"2", "6", "8"}]=">"}
	self:replaceStuff(threeWallReplacementTable, tile)
	local twoWallReplacementTable = {[{"2", "4"}]="1", [{"2", "6"}]="3", [{"4", "8"}]="7", [{"6", "8"}]="9", [{"6", "4"}]="|", [{"2", "8"}]="="}
	self:replaceStuff(twoWallReplacementTable, tile)
	if #tile > numberOfWallSegmentsPreOptimization then
		error("Wall replacement was worse then leaving it be")
	end
	-- print(#tile)
	totalNumSides = totalNumSides + #tile
	totalNumWalls = totalNumWalls + 1
	if #tile > 2 then
		print(#tile)
	end
	if #tile == 1 then
		return tile[1]
	end
	if #tile > 0 then
		return tile
	end
	return "#"
end

function Level:replaceStuff(replacementGuide, replaceThisTable)
	for k, v in pairs(replacementGuide) do
		local removeTable = {}
		for i, checkIn in ipairs(k) do
			local isIn, index = self:inTable(checkIn, replaceThisTable)
			if isIn then
				removeTable[#removeTable+1] = index
			end
		end
		if #removeTable == #k then
			for i, checkIn in ipairs(k) do
				local isIn, index = self:inTable(checkIn, replaceThisTable)
				table.remove(replaceThisTable, index)
			end
			-- for i, removeIndex in ipairs(removeTable) do
			-- 	table.remove(replaceThisTable, removeIndex)
			-- end
			replaceThisTable[#replaceThisTable+1] = v
		end
	end
end

function Level:inTable(item, t)
	for i = 1, #t do
		if t[i] == item then
			return true, i
		end
	end
	return false, -1
end
-- 	if surroundings[2] == "#" then
-- 		-- it has to be taken care of, right? so check if it is, otherwise, handle it
-- 		if surroundings[3] == "#" then
-- 			-- it will be dealth with, I think?
-- 		end
-- 	end

-- 	local convertTable = {['_#_###_#_'] = {';', ':', ',', '.'},
-- 						['#########'] = {';', ':'},
-- 						['#########'] = {'2', ':', ',', '.'},
-- 						['#########'] = " ",
-- 			}
-- 	if convertTable[allSides] == nil then
-- 		return "#"
-- 	end
-- 	return convertTable[allSides]
-- end

function Level:loadLevelTableFromFile(filename)
	local loadMode = "level" -- or it could be the extras
	local levelTable = {}
	for line in love.filesystem.lines(filename) do
		if line == "DATA:" then
			loadMode = "data"
		elseif loadMode == "level" then
			levelTable[#levelTable+1] = {}
			for i = 1, #line do
				 -- add the character to the end of the table
				levelTable[#levelTable][#levelTable[#levelTable]+1] = string.sub(line, i, i)
			end
		elseif loadMode == "data" then
			-- then additional stuff is input, maybe enemies or doors or whatever.
		end
	end
	local level = {levelTable = levelTable, levelData = {}}
	return level
end

function Level:interpretLevelTable(levelTable)
	self.levelbase = {}
	self.leveltop = {}
	local x = 0
	local y = 0
	self.playerspawns = {}
	self.numberOfEnemies = 0
	self.totalNumberOfEnemies = 0
	for j = 1, #levelTable do
		self.levelbase[#self.levelbase + 1] = {}
		self.leveltop[#self.leveltop + 1] = {}
		x = 0
		for i = 1, #levelTable[j], 1 do
			local base = levelTable[j][i] -- the first character
			-- local top = string.sub(line, i+1, i+1) -- the first character
			if base == "#" then
				base = self:determineWall(i, j, levelTable)
			end
			if base == "_" then
				table.insert(self.playerspawns, {(x+.5)*self.tileWidth, (y+.5)*self.tileHeight})
				-- print(x, y)
				base = "`"
			end
			if base == "O" then
				base = "`"
			end
			if base == "c" then
				base = "`"
			end
			if base == "m" then
				base = "`"
			end
			if base == "`" then
				-- randomly add other tiles to make things interesting
				if math.random() < .25 then
					--wesd
					local t = math.random()
					if t < .25 then
						base = "w"
					elseif t < .5 then
						base = "e"
					elseif t < .75 then
						base = "s"
					else
						base = "d"
					end
				end
			end

			self.levelbase[#self.levelbase][#self.levelbase[#self.levelbase]+1] = base
			self.leveltop[#self.leveltop][#self.leveltop[#self.leveltop]+1] = " "
			x = x + 1
		end
		y = y + 1
	end
	while self.numberOfEnemies > self.maxNumberOfEnemies do
		print("REMOVING ENEMIES")
		table.remove(self.enemies, math.random(1, #self.enemies))
		self.numberOfEnemies = self.numberOfEnemies - 1
		self.totalNumberOfEnemies = self.totalNumberOfEnemies - 1
	end
end

function Level:checkBothCollisions(x, y, dx, dy, width, height)
	-- additional checks whether the current square you're in is a collision square
	local tout = {0, 0, false, false, false}
	local change = self:checkXCollisions(x, y, dx, width, height)
	tout[1] = change[2]
	tout[3] = change[1]
	change = self:checkYCollisions(x, y, dy, width, height)
	tout[2] = change[2]
	tout[4] = change[1]

	tout[5] = self:checkMiddleCurrent(x, y, dx, dy)
	print(tout[3], tout[4])
	return tout
end

function Level:checkMiddleCurrent(x, y, dx, dy)
	local tilex = math.floor(x/self.tileWidth)
	local tiley = math.floor(y/self.tileHeight)
	if self.levelbase[tiley+1] == nil or self.levelbase[tiley+1][tilex+1] == nil then
		return true -- this one is for bullets, so let's have them hit when they get where they shouldn't be
	end
	if self:isCollidingTile(self.levelbase[tiley+1][tilex+1]) then
		-- then you collided, so return true and the correction
		return true
	end
	return false
end

function Level:checkXCollisions(playerX, playerY, dx, playerWidth, playerHeight)
	local halfPlayerWidth = playerWidth/2
	local halfPlayerHeight = playerHeight/2
	-- check the top and bottom corners of the player
	local y1 = playerY - halfPlayerHeight
	local y2 = playerY + halfPlayerHeight
	if dx > 0 then
		local x = playerX + halfPlayerWidth
		local change = self:collisionDetection(x, y1, dx, 0)
		if change[1] then
			return {true, change[2]-halfPlayerWidth}
		else
			change = self:collisionDetection(x, y2, dx, 0)
			if change[1] then
				return {true, change[2]-halfPlayerWidth}
			end
		end
	elseif dx < 0 then
		local x = playerX - halfPlayerWidth
		local change = self:collisionDetection(x, y1, dx, 0)
		if change[1] then
			return {true, change[2]+halfPlayerWidth}
		else
			change = self:collisionDetection(x, y2, dx, 0)
			if change[1] then
				return {true, change[2]+halfPlayerWidth}
			end
		end
	elseif dx == 0 then
		return {true, playerX} -- that way we won't make walking footsteps
	end
	return {false, playerX+dx}
end

function Level:checkYCollisions(playerX, playerY, dy, playerWidth, playerHeight)
	local halfPlayerWidth = playerWidth/2
	local halfPlayerHeight = playerHeight/2
	-- check the left and right corners of the player
	local x1 = playerX - halfPlayerWidth
	local x2 = playerX + halfPlayerWidth
	if dy > 0 then
		local y = playerY + halfPlayerHeight
		local change = self:collisionDetection(x1, y, 0, dy)
		if change[1] then
			return {true, change[2]-halfPlayerHeight}
		else
			change = self:collisionDetection(x2, y, 0, dy)
			if change[1] then
				return {true, change[2]-halfPlayerHeight}
			end
		end
	elseif dy < 0 then
		local y = playerY - halfPlayerHeight
		local change = self:collisionDetection(x1, y, 0, dy)
		if change[1] then
			return {true, change[2]+halfPlayerHeight}
		else
			change = self:collisionDetection(x2, y, 0, dy)
			if change[1] then
				return {true, change[2]+halfPlayerHeight}
			end
		end
	elseif dy == 0 then
		return {true, playerY} -- that way we won't make walking footsteps
	end
	return {false, playerY+dy}
end

function Level:isCollidingTile(tile)
	return type(tile) == "table" or self.collidingTiles[tile] ~= nil
end

function Level:collisionDetection(x, y, dx, dy)
	-- I'm assuming that the tile you're in already is valid, and only checking the ones when you go over an edge?
	-- I'm also only checking one direction at a time
	local tilex = math.floor(x/self.tileWidth)
	local tiley = math.floor(y/self.tileHeight)
	local tile2x = math.floor((x+dx)/self.tileWidth)
	local tile2y = math.floor((y+dy)/self.tileHeight)
	if self.game.debug then
		table.insert(self.debugCollisionHighlighting, {tile2x*self.tileWidth, tile2y*self.tileHeight})
	end
	if tilex ~= tile2x then
		-- then check whether you can move into that tile
		if self.levelbase[tile2y+1] == nil or self.levelbase[tile2y+1][tile2x+1] == nil then
			return {false, 0}
		end
		if self:isCollidingTile(self.levelbase[tile2y+1][tile2x+1]) then
			-- then you collided, so return true and the correction
			if dx > 0 then
				return {true, (tile2x)*self.tileWidth-1} -- moving right
			else
				return {true, (tile2x+1)*self.tileWidth} -- moving left
			end
		end
	elseif tiley ~= tile2y then
		-- then check whether you can move into that tile
		if self.levelbase[tile2y+1] == nil or self.levelbase[tile2y+1][tile2x+1] == nil then
			return {false, 0}
		end
		if self:isCollidingTile(self.levelbase[tile2y+1][tile2x+1]) then
			-- then you collided, so return true and the correction
			if dy > 0 then
				return {true, tile2y*self.tileHeight-1} -- moving down
			else
				return {true, (tile2y+1)*self.tileHeight} -- moving up
			end
		end
	end
	return {false, 0}
end

function Level:drawbase(focusX, focusY, focusWidth, focusHeight, focusHorizontalScale, focusVerticalScale)
	-- only draw the parts that it actually may need to, because why not, right?
	for y = 0, #self.levelbase-1 do
		for x = 0, #self.levelbase[1]-1 do
			-- if self.tilesetQuads[self.levelbase[y+1][x+1]] == nil then
			-- 	print(self.levelbase[y+1][x+1])
			-- end
			-- print(self.levelbase[y+1][x+1])
			local drawX = math.floor((x+.5)*self.tileWidth-focusX)*focusHorizontalScale
			local drawY = math.floor((y+.5)*self.tileHeight-focusY)*focusVerticalScale
			if type(self.levelbase[y+1][x+1]) == "table" then
				for i = 1, #self.levelbase[y+1][x+1] do
					love.graphics.draw(self.tilesetImage, self.tilesetQuads[self.levelbase[y+1][x+1][i]], drawX, drawY, 0, focusHorizontalScale, focusVerticalScale, self.tileWidth/2, self.tileHeight/2)--, 32*2, 32*2)
				end
			else
				love.graphics.draw(self.tilesetImage, self.tilesetQuads[self.levelbase[y+1][x+1]], drawX, drawY, 0, focusHorizontalScale, focusVerticalScale, self.tileWidth/2, self.tileHeight/2)--, 32*2, 32*2)
			end
		end
	end
end

function Level:drawtop(focusX, focusY, focusWidth, focusHeight, focusHorizontalScale, focusVerticalScale)
	-- only draw the parts that it actually may need to, because why not, right?
	love.graphics.setColor(255, 255, 255, 255)
	for y = 0, #self.leveltop-1 do
		for x = 0, #self.leveltop[1]-1 do
			-- print(self.leveltop[y+1][x+1])
			local drawX = math.floor(((x+.5)*self.tileWidth*focusHorizontalScale-focusX))
			local drawY = math.floor(((y+.5)*self.tileHeight*focusVerticalScale-focusY))
			if self.leveltop[y+1][x+1] ~= " " then
				love.graphics.draw(self.tilesetImage, self.tilesetQuads[self.leveltop[y+1][x+1]], drawX, drawY, 0, focusHorizontalScale, focusVerticalScale, self.tileWidth/2, self.tileHeight/2)
			end
		end
	end

	-- then debug for collisions
	if self.game.debug then
		love.graphics.setColor(255, 0, 0)
		for k, v in ipairs(self.debugCollisionHighlighting) do
			love.graphics.rectangle("line", (v[1]-focusX)*focusHorizontalScale, (v[2]-focusY)*focusVerticalScale, self.tileWidth*focusHorizontalScale, self.tileHeight*focusVerticalScale)
			if self.levelbase[v[2]/self.tileHeight+1] ~= nil and self.levelbase[v[2]/self.tileHeight+1][v[1]/self.tileWidth+1] ~= nil then
				if type(self.levelbase[v[2]/self.tileHeight+1][v[1]/self.tileWidth+1]) == "table" then
					local str = ""
					for i, v in ipairs(self.levelbase[v[2]/self.tileHeight+1][v[1]/self.tileWidth+1]) do
						str = str .. v
					end
					love.graphics.print(tostring(str), (v[1]-focusX)*focusHorizontalScale, (v[2]-focusY)*focusVerticalScale)
				else
					love.graphics.print(tostring(self.levelbase[v[2]/self.tileHeight+1][v[1]/self.tileWidth+1]), (v[1]-focusX)*focusHorizontalScale, (v[2]-focusY)*focusVerticalScale)
				end
			end
		end
	end
end

function Level:update(dt)
	self.playTime = self.playTime + dt
	self.debugCollisionHighlighting = {}
end