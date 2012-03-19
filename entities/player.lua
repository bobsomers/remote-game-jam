local Class = require "hump.class"
local Vector = require "hump.vector"
local Constants = require "constants"
local gfx = love.graphics
local Beer = require "entities.beer"
local Fire = require "entities.fire"

local Player = Class(function(self, collider, camera)
    self.collider = collider
    self.camera = camera

    self.SIZE = Vector(32, 64)
    self.GUN_SIZE = Vector(32, 16)
	
	-- add 32 to the center of the player
	self.PLAYER_FLOOR = Vector(0, 32)

    self.shape = self.collider:addRectangle(0, 0, self.SIZE.x, self.SIZE.y)
    self.shape.kind = "player"
    self.collider:addToGroup("player", self.shape)

    self.beer = Beer(self, collider)
    self.fire = Fire(self, collider)

	self.MAX_JUMPS = 2
    self.MOVE_SPEED = Constants.PLAYER_SPEED
    self.JUMP_VELOCITY = -Constants.PLAYER_JUMP
	
	----------------------------------------------------------------------------
	-- Animation shenanegans 
	----------------------------------------------------------------------------
	self.anim = {}
	self.anim["left"] = {}
	self.anim["right"] = {}
	-- Animation for idle standing position when facing left
	self.anim["left"]["idle"] = {}
	idleLeftImg = love.graphics.newImage("images/hero/idle_left.png")
	self.anim["left"]["idle"] = newAnimation(idleLeftImg, 32, 32, 0.3, 2)
	self.anim["left"]["idle"].faceCenter = {
		Vector(18, 29), 
		Vector(18, 30)
	}
	self.anim["left"]["idle"].gunCenter = {
		Vector(23, 10), 
		Vector(23, 9)
	}
	
	-- Animation for idle standing position when facing right
	self.anim["right"]["idle"] = {}
	idleRightImg = love.graphics.newImage("images/hero/idle_right.png")
	self.anim["right"]["idle"] = newAnimation(idleRightImg, 32, 32, 0.3, 2)
	self.anim["right"]["idle"].faceCenter = {
		Vector(14, 29), 
		Vector(14, 30)
	}
	self.anim["right"]["idle"].gunCenter = {
		Vector(10, 11), 
		Vector(10, 10)
	}
	
	-- Animation for walking position when facing left
	self.anim["left"]["walk"] = {}
	walkLeftImg = love.graphics.newImage("images/hero/walk_left.png")
	self.anim["left"]["walk"] = newAnimation(walkLeftImg, 32, 32, 0.2, 4)
	self.anim["left"]["walk"].faceCenter = {
		Vector(16, 32), 
		Vector(17, 32),
		Vector(16, 32), 
		Vector(17, 31)
	}
	self.anim["left"]["walk"].gunCenter = {
		Vector(20, 10), 
		Vector(22, 9), 
		Vector(20, 10), 
		Vector(20, 9)
	}
	
	-- Animation for walking position when facing right
	self.anim["right"]["walk"] = {}
	walkRightImg = love.graphics.newImage("images/hero/walk_right.png")
	self.anim["right"]["walk"] = newAnimation(walkRightImg, 32, 32, 0.2, 4)
	self.anim["right"]["walk"].faceCenter = {
		Vector(16, 32), 
		Vector(15, 32),
		Vector(16, 32), 
		Vector(15, 31)
	}
	self.anim["right"]["walk"].gunCenter = {
		Vector(12, 10), 
		Vector(10, 9), 
		Vector(12, 10), 
		Vector(10 , 9)
	}
	
	-- Animation for jumping when facing left
	self.anim["left"]["jump"] = {}
	jumpLeftImg = love.graphics.newImage("images/hero/jump_left.png")
	self.anim["left"]["jump"] = newAnimation(jumpLeftImg, 64, 64, 0.1, 2)
	self.anim["left"]["jump"]:setMode("once")
	-- Don't question the magic.
	self.anim["left"]["jump"].faceCenter = {
		Vector(34, 64-75),
		Vector(34, 64-45)
	}
	self.anim["left"]["jump"].gunCenter = {
		Vector(36, 64-24), 
		Vector(36, 64-40)
	}
	
	-- Animation for jumping when facing right
	self.anim["right"]["jump"] = {}
	jumpRightImg = love.graphics.newImage("images/hero/jump_right.png")
	self.anim["right"]["jump"] = newAnimation(jumpRightImg, 64, 64, 0.1, 2)
	self.anim["right"]["jump"]:setMode("once")
	-- Don't question the magic.
	self.anim["right"]["jump"].faceCenter = {
		Vector(34, 64-75), 
		Vector(34, 64-45)
	}
	self.anim["right"]["jump"].gunCenter = {
		Vector(28, 64-24), 
		Vector(28, 64-40)
	}
	
	-- Animation for head (because I don't want to figure out how to draw with graphics
	-- cause it's different than animations :| )
	self.anim["left"]["head"] = {}
	faceNeutralLeftImg = love.graphics.newImage("images/hero/head_left.png")
	self.anim["left"]["head"] = newAnimation(faceNeutralLeftImg, 48, 48, 1, 1)
	self.anim["left"]["head"].center = Vector(24, 8)
	
	self.anim["right"]["head"] = {}
	faceNeutralRightImg = love.graphics.newImage("images/hero/head_right.png")
	self.anim["right"]["head"] = newAnimation(faceNeutralRightImg, 48, 48, 1, 1)
	self.anim["right"]["head"].center = Vector(24, 8)
	
	-- left gun
	self.anim["left"]["gun"] = {}
	self.anim["left"]["gun"].img = love.graphics.newImage("images/hero/gun_left.png")
	self.anim["left"]["gun"].center = Vector(27, 3)
	
	-- right gun
	self.anim["right"]["gun"] = {}
	self.anim["right"]["gun"].img = love.graphics.newImage("images/hero/gun_right.png")
	self.anim["right"]["gun"].center = Vector(5, 3)
	
	-- Set default animation states
	self.anim.current = "idle"
	self.anim.facing = "left"
    
    self:reset()
end)

function Player:reset()
    self.velocity = Vector(0, 0)
    self.health = 100
    self.drunk = 0
	self:changeAnim("right", "jump")
    self.gunDirection = Vector(1, 0)
	self.jumpCount = self.MAX_JUMPS
end

function Player:jump()
    if self.jumpCount <= 0 then
		return
	end
    
	-- set animation state
	self:changeAnim(self.anim.facing, "jump")
	self.jumpCount = self.jumpCount - 1
    
    -- Apply some instantaneous velocity in the Y direction.
    local x, y = self.shape:center()
    self.shape:moveTo(x, y - 1)
    self.velocity.y = self.JUMP_VELOCITY
end

function Player:collideWorld(tileShape, mtv)
    -- Apply minimum translation vector to resolve the collision.
    self.shape:move(mtv.x, mtv.y)

    -- If we corrected the player in the Y direction, their Y velocity is 0.
    if mtv.y ~= 0 then
        self.velocity.y = 0
		
		if mtv.x > mtv.y then
			self.jumpCount = self.MAX_JUMPS
		end
		
		self.jumping = true
		-- reset animation state
		if self.anim.current == "jump" then
			self:changeAnim(self.anim.facing, "idle")
		end
    end
end

function Player:changeAnim(facing, state)
	local curState = self.anim.current
	local curFacing = self.anim.facing
	
	if state == nil then
		state = curState
	end	
	
	-- Include a special case for while in the air, we want to be able to move around
	-- in the air freely without resetting our animation
	if (curState ~= state) or (curFacing ~= facing and curState ~= "jump") then
		self.anim.facing = facing
		self.anim.current = state
		self:resetAnim()
	else
		self.anim.facing = facing
		self.anim.current = state
	end
end

function Player:updateAnim(dt)
	self.anim[self.anim.facing][self.anim.current]:update(dt)
end

function Player:resetAnim()
	print("resetting " .. self.anim.facing .. "/" .. self.anim.current)
	self.anim[self.anim.facing][self.anim.current]:reset()
	self.anim[self.anim.facing][self.anim.current]:play()
end 

function Player:update(dt)
    -- Slowly drain the player's drunkeness over time.
    self.drunk = self.drunk - (Constants.PLAYER_DRUNK_DRAIN_RATE * dt)
    self.camera.drunk = self.drunk / 100
    if self.drunk < 0 then
        self.drunk = 0
        -- TODO: you lose!
    end

    -- Check for keyboard input.
    self.velocity.x = 0
    if love.keyboard.isDown("a") then
        self.velocity.x = self.velocity.x - self.MOVE_SPEED
		self:changeAnim("left")
    end
    if love.keyboard.isDown("d") then
        self.velocity.x = self.velocity.x + self.MOVE_SPEED
		self:changeAnim("right")

    end

    -- Compute player's position based on velocity and gravity.
    local posX, posY = self.shape:center()
    posX = posX + (self.velocity.x * dt) -- No acceleration in X direction.
    posY = posY + (self.velocity.y * dt) + (0.5 * Constants.GRAVITY * dt * dt)

    -- Update the player's velocity due to gravity.
    self.velocity.y = self.velocity.y + (Constants.GRAVITY * dt)

	-- Only update if we aren't falling
	if self.anim.current ~= "jump" then
		if self.velocity.x < -10 or self.velocity.x > 10 then
			self:changeAnim(self.anim.facing, "walk")
		else
			self:changeAnim(self.anim.facing, "idle")
		end
	end
	
	-- Update the current animation
	self:updateAnim(dt)
	
    self.shape:moveTo(posX, posY)

    -- Gun faces the mouse cursor.
    local mousePos = self.camera.camera:worldCoords(Vector(love.mouse.getPosition()))
    self.gunDirection.x = mousePos.x - posX
    self.gunDirection.y = mousePos.y - posY
    self.gunDirection:normalize_inplace()

    -- Update the beer and fire.
    self.beer:update(dt)
    self.fire:update(dt)
end

function Player:draw()
    local position = Vector(self.shape:center())
	
	-- Retrieve our location
    local posX, posY = self.shape:center()
	local offset = Vector(posX + self.PLAYER_FLOOR.x, posY + self.PLAYER_FLOOR.y)
	
	-- Get the current body animation table
	local currAnim = self.anim[self.anim.facing][self.anim.current]
	
	-- we want the bottom of the image at our 'center' so subtract all of fh
	offset.x = offset.x - (currAnim.fw / 2)
	offset.y = offset.y - (currAnim.fh)
	
	-- Get current head position
	local headOffset = currAnim.faceCenter[currAnim:getCurrentFrame()]
	
	-- Draw the body
	currAnim:draw(offset.x, offset.y)
	
	-- Get the current head animation
	local currHeadAnim = self.anim[self.anim.facing]["head"]
	
	-- Get the offset of the head (subtract headOffset.y because of inverted Y)
	local finaloffset = Vector(
				offset.x + headOffset.x - currHeadAnim.center.x,
				offset.y - headOffset.y - currHeadAnim.center.y
				)
				
	-- Draw the head
	currHeadAnim:draw(finaloffset.x,finaloffset.y)

	-- Get the current gun animation
	local currGun = self.anim[self.anim.facing]["gun"]
	
	-- Get current gun position
	local gunOffset = currAnim.gunCenter[currAnim:getCurrentFrame()]
	
	local gunRotate = math.atan2(self.gunDirection.y, self.gunDirection.x)
	
	--Get the final offset
	finalOffset = offset + gunOffset-- + self.anim[self.anim.facing]["gun"].center
	
	local invertRotation = 0
	if self.anim.facing == "left" then
		invertRotation = 1
	end
	
	-- Draw the arm + gun
	gfx.draw( currGun.img, finalOffset.x, finalOffset.y, gunRotate - (invertRotation*3.14), 1, 1, self.anim[self.anim.facing]["gun"].center.x,self.anim[self.anim.facing]["gun"].center.y )
	--gfx.draw( currGun.img, finalOffset.x, finalOffset.y, 0, 1, 1, 0,0 )


    -- Draw their sobriety meter.
    love.graphics.setColor(255, 200, 0, 255)
    love.graphics.rectangle("fill",
        position.x - (self.SIZE.x / 2), position.y - (self.SIZE.y / 2) - 6,
        self.drunk / 100 * self.SIZE.x, 4
    )

    -- Draw their health meter.
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.rectangle("fill",
        position.x - (self.SIZE.x / 2), position.y - (self.SIZE.y / 2) - 12,
        self.health / 100 * self.SIZE.x, 4
    )
	
	--[[
    -- Draw their gun.
    love.graphics.setColor(255, 255, 0, 255)
    love.graphics.push()
    love.graphics.translate(position.x, position.y)
    love.graphics.rotate(math.atan2(self.gunDirection.y, self.gunDirection.x))
    love.graphics.rectangle("fill",
        -self.GUN_SIZE.y / 2, -self.GUN_SIZE.y / 2,
        self.GUN_SIZE.x, self.GUN_SIZE.y
    )
	
    love.graphics.pop()
    --]]

    love.graphics.setColor(255, 255, 255, 255)

    self.beer:draw()
    self.fire:draw()
end

return Player
