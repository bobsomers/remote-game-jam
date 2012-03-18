local Class = require "hump.class"
local Vector = require "hump.vector"
local Constants = require "constants"
local Beer = require "entities.beer"

local Player = Class(function(self, collider, camera)
    self.collider = collider
    self.camera = camera

    self.SIZE = Vector(32, 64)
    self.GUN_SIZE = Vector(32, 16)

    self.shape = self.collider:addRectangle(0, 0, self.SIZE.x, self.SIZE.y)
    self.shape.kind = "player"
    self.collider:addToGroup("player", self.shape)

    self.beer = Beer(self, collider)

	self.MAX_JUMPS = 2
    self.MOVE_SPEED = Constants.PLAYER_SPEED
    self.JUMP_VELOCITY = -Constants.PLAYER_JUMP
	
	-- Animation shenanegans 
	self.anim = {}
	
	-- Animation for idle standing position when facing left
	self.anim.idleLeftImg = love.graphics.newImage("images/gen_stand_left.png")
	self.anim.idleLeft = newAnimation(self.anim.idleLeftImg, 32, 32, 0.3, 2)
	self.anim.idleLeft.faceCenter = {
		{x=18, y=29}, 
		{x=18, y=30}
	}
	
	-- Animation for idle standing position when facing right
	self.anim.idleRightImg = love.graphics.newImage("images/gen_stand_right.png")
	self.anim.idleRight = newAnimation(self.anim.idleRightImg, 32, 32, 0.3, 2)
	self.anim.idleRight.faceCenter = {
		{x=14, y=29}, 
		{x=14, y=30}
	}
	
	-- Animation for walking position when facing left
	self.anim.walkLeftImg = love.graphics.newImage("images/gen_walk_left.png")
	self.anim.walkLeft = newAnimation(self.anim.walkLeftImg, 32, 32, 0.2, 4)
	self.anim.walkLeft.faceCenter = {
		{x=16, y=32}, 
		{x=17, y=32},
		{x=16, y=32}, 
		{x=17, y=31}
	}
	
	-- Animation for walking position when facing right
	self.anim.walkRightImg = love.graphics.newImage("images/gen_walk_right.png")
	self.anim.walkRight = newAnimation(self.anim.walkRightImg, 32, 32, 0.2, 4)
	self.anim.walkRight.faceCenter = {
		{x=16, y=32}, 
		{x=15, y=32},
		{x=16, y=32}, 
		{x=15, y=31}
	}
	
	-- Animation for jumping when facing left
	self.anim.jumpLeftImg = love.graphics.newImage("images/gen_jump_left.png")
	self.anim.jumpLeft = newAnimation(self.anim.jumpLeftImg, 64, 64, 0.1, 2)
	self.anim.jumpLeft:setMode("once")
	-- Don't question the magic.
	self.anim.jumpLeft.faceCenter = {
		{x=34, y=64-75},
		{x=34, y=64-45}
	}
	
	-- Animation for jumping when facing right
	self.anim.jumpRightImg = love.graphics.newImage("images/gen_jump_right.png")
	self.anim.jumpRight = newAnimation(self.anim.jumpRightImg, 64, 64, 0.1, 2)
	self.anim.jumpRight:setMode("once")
	-- Don't question the magic.
	self.anim.jumpRight.faceCenter = {
		{x=34, y=64-75}, 
		{x=34, y=64-45}
	}
	
	self.anim.faceNeutralLeftImg = love.graphics.newImage("images/gen_head_left.png")
	self.anim.faceNeutralLeft = newAnimation(self.anim.faceNeutralLeftImg, 48, 48, 1, 1)
	self.anim.faceNeutralLeft.center = {x=24, y=8}
	
	self.anim.faceNeutralRightImg = love.graphics.newImage("images/gen_head_right.png")
	self.anim.faceNeutralRight = newAnimation(self.anim.faceNeutralRightImg, 48, 48, 1, 1)
	self.anim.faceNeutralRight.center = {x=24, y=8}
	
	-- Set default animation states
	self.anim.current = "idle"
	self.anim.facing = "left"
    
    self:reset()
end)

function Player:reset()
    self.velocity = Vector(0, 0)
    self.health = 100
    self.drunk = 100
	self:updateAnim("right", "jumping")
    --self.drunk = 0
    self.gunDirection = Vector(1, 0)
	self.jumpCount = self.MAX_JUMPS
end

function Player:jump()
    if self.jumpCount <= 0 then
		return
	end
    
	-- set animation state
	self:updateAnim(self.anim.facing, "jumping")
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
		if self.anim.current == "jumping" then
			self:updateAnim(self.anim.facing, "idle")
		end
    end
end

function Player:updateAnim(facing, state)
	if state == nil then
		state = self.anim.current
	end	
	
	-- Include a special case for while in the air, we want to be able to move around
	-- in the air freely without resetting our animation
	if self.anim.current ~= state or (self.anim.facing ~= facing and self.anim.current ~= "jumping") then
		self.anim.facing = facing
		self.anim.current = state
		self:resetAnim()
	else
		self.anim.facing = facing
		self.anim.current = state
	end
end

function Player:resetAnim()
	if self.anim.facing == "left" then
		if self.anim.current == "walking" then
			self.anim.walkLeft:reset()
			self.anim.walkLeft:play()
		elseif self.anim.current == "idle" then
			self.anim.idleLeft:reset()
			self.anim.idleLeft:play()
		elseif self.anim.current == "jumping" then
			self.anim.jumpLeft:reset()
			self.anim.jumpLeft:play()
		end
	else
		if self.anim.current == "walking" then
			self.anim.walkRight:reset()
			self.anim.walkRight:play()
		elseif self.anim.current == "idle" then
			self.anim.idleRight:reset()
			self.anim.idleRight:play()
		elseif self.anim.current == "jumping" then
			self.anim.jumpRight:reset()
			self.anim.jumpRight:play()
		end
	end
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
        self.velocity.x = -self.MOVE_SPEED
		self:updateAnim("left")
    end
    if love.keyboard.isDown("d") then
        self.velocity.x = self.MOVE_SPEED
		self:updateAnim("right")

    end

    -- Compute player's position based on velocity and gravity.
    local posX, posY = self.shape:center()
    posX = posX + (self.velocity.x * dt) -- No acceleration in X direction.
    posY = posY + (self.velocity.y * dt) + (0.5 * Constants.GRAVITY * dt * dt)

    -- Update the player's velocity due to gravity.
    self.velocity.y = self.velocity.y + (Constants.GRAVITY * dt)

	-- Only update if we aren't falling
	if self.anim.current ~= "jumping" then
		if self.velocity.x < -10 or self.velocity.x > 10 then
			self:updateAnim(self.anim.facing, "walking")
		else
			self:updateAnim(self.anim.facing, "idle")
		end
	end
	
	if self.anim.facing == "left" then
		if self.anim.current == "walking" then
			self.anim.walkLeft:update(dt)
		elseif self.anim.current == "idle" then
			self.anim.idleLeft:update(dt)
		elseif self.anim.current == "jumping" then
			self.anim.jumpLeft:update(dt)
		end
	else
		if self.anim.current == "walking" then
			self.anim.walkRight:update(dt)
		elseif self.anim.current == "idle" then
			self.anim.idleRight:update(dt)
		elseif self.anim.current == "jumping" then
			self.anim.jumpRight:update(dt)
		end
	end
	
    self.shape:moveTo(posX, posY)

    -- Gun faces the mouse cursor.
    local mousePos = self.camera.camera:worldCoords(Vector(love.mouse.getPosition()))
    self.gunDirection.x = mousePos.x - posX
    self.gunDirection.y = mousePos.y - posY
    self.gunDirection:normalize_inplace()

    -- Update the beer.
    self.beer:update(dt)
end

function Player:draw()
    local position = Vector(self.shape:center())
	
	-- Retrieve our location
    local posX, posY = self.shape:center()
	local headOffset = {}
	local offsetX = 0
	local offsetY = 0
	if self.anim.facing == "left" then
		if self.anim.current == "walking" then
			offsetX = posX - (self.anim.walkLeft.fw / 2)
			offsetY = posY - (self.anim.walkLeft.fh / 2) + 16
			self.anim.walkLeft:draw(offsetX, offsetY)

			-- Get current head position
			headOffset = self.anim.walkLeft.faceCenter[self.anim.walkLeft:getCurrentFrame()]
			
		elseif self.anim.current == "idle" then
			offsetX = posX - (self.anim.idleLeft.fw / 2)
			offsetY = posY - (self.anim.idleLeft.fh / 2) + 16
			self.anim.idleLeft:draw(offsetX, offsetY)
			
			-- Get current head position
			headOffset = self.anim.idleLeft.faceCenter[self.anim.idleLeft:getCurrentFrame()]
			
		elseif self.anim.current == "jumping" then
			offsetX = posX - (self.anim.jumpLeft.fw / 2)
			offsetY = posY - (self.anim.jumpLeft.fh / 2) + 16
			self.anim.jumpLeft:draw(offsetX, offsetY)
			
			-- Get current head position
			headOffset = self.anim.jumpLeft.faceCenter[self.anim.jumpLeft:getCurrentFrame()]
			
		end
	else
		if self.anim.current == "walking" then
			offsetX = posX - (self.anim.walkRight.fw / 2)
			offsetY = posY - (self.anim.walkRight.fh / 2) + 16
			self.anim.walkRight:draw(offsetX, offsetY)
			
			-- Get current head position
			headOffset = self.anim.walkRight.faceCenter[self.anim.walkRight:getCurrentFrame()]
			
		elseif self.anim.current == "idle" then
			offsetX = posX - (self.anim.idleRight.fw / 2)
			offsetY = posY - (self.anim.idleRight.fh / 2) + 16
			self.anim.idleRight:draw(offsetX, offsetY)
			
			-- Get current head position
			headOffset = self.anim.idleRight.faceCenter[self.anim.idleRight:getCurrentFrame()]
			
		elseif self.anim.current == "jumping" then
			offsetX = posX - (self.anim.jumpRight.fw / 2)
			offsetY = posY - (self.anim.jumpRight.fh / 2) + 16
			self.anim.jumpRight:draw(offsetX, offsetY)
			
			-- Get current head position
			headOffset = self.anim.jumpRight.faceCenter[self.anim.jumpRight:getCurrentFrame()]
			
		end
	end
	
	-- Draw their head
	
	if self.anim.facing == "left" then
		local finalOffsetX = offsetX + headOffset.x - self.anim.faceNeutralLeft.center.x
		local finalOffsetY = offsetY - headOffset.y - self.anim.faceNeutralLeft.center.y
		self.anim.faceNeutralLeft:draw(finalOffsetX,finalOffsetY)
	else
		local finalOffsetX = offsetX + headOffset.x - self.anim.faceNeutralRight.center.x
		local finalOffsetY = offsetY - headOffset.y - self.anim.faceNeutralRight.center.y
		self.anim.faceNeutralRight:draw(finalOffsetX,finalOffsetY)
	end
	
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
	
    -- Draw their gun.
    --[[
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
end

return Player
