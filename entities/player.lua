local Class = require "hump.class"
local Vector = require "hump.vector"
local Constants = require "constants"

local Player = Class(function(self, collider)
    self.SIZE = Vector(32, 32)

    self.shape = collider:addRectangle(0, 0, self.SIZE.x, self.SIZE.y)
    self.shape.kind = "player"
    collider:addToGroup("player", self.shape)

    self.MOVE_SPEED = Constants.PLAYER_SPEED
    self.JUMP_VELOCITY = -Constants.PLAYER_JUMP
	
	-- Animation shenanegans 
	self.anim = {}
	
	-- Animation for idle standing position when facing left
	self.anim.STANDING_LEFT = 1
	self.anim.standLeftImg = love.graphics.newImage("images/gen_stand_left.png")
	self.anim.standLeft = newAnimation(self.anim.standLeftImg, 32, 32, 0.3, 2)
	
	-- Animation for idle standing position when facing right
	self.anim.STANDING_RIGHT = 2
	self.anim.standRightImg = love.graphics.newImage("images/gen_stand_right.png")
	self.anim.standRight = newAnimation(self.anim.standRightImg, 32, 32, 0.3, 2)
	
	-- Animation for idle walking position when facing left
	self.anim.WALKING_LEFT = 3
	self.anim.walkLeftImg = love.graphics.newImage("images/gen_walk_left.png")
	self.anim.walkLeft = newAnimation(self.anim.walkLeftImg, 32, 32, 0.2, 4)
	
	-- Animation for idle walking position when facing right
	self.anim.WALKING_RIGHT = 4
	self.anim.walkRightImg = love.graphics.newImage("images/gen_walk_right.png")
	self.anim.walkRight = newAnimation(self.anim.walkRightImg, 32, 32, 0.2, 4)
	
	-- Facing states
	self.anim.FACING_RIGHT = 1
	self.anim.FACING_LEFT = 2
	
	-- Set default animation states
	self.anim.current = self.anim.STANDING_RIGHT
	self.anim.facing = self.anim.FACING_RIGHT

    self:reset()
end)

function Player:reset()
    self.velocity = Vector(0, 0)
    self.health = 100
    self.drunk = 100
end

function Player:jump()
    --[[
    if self.velocity.y > 0 then
        -- Can't jump!
        return
    end
    --]]

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
    end
end

function Player:update(dt)
    -- Slowly drain the player's drunkeness over time.
    self.drunk = self.drunk - (Constants.PLAYER_DRUNK_DRAIN_RATE * dt)
    if self.drunk < 0 then
        self.drunk = 0
        -- TODO: you lose!
    end

    -- Check for keyboard input.
    self.velocity.x = 0
    if love.keyboard.isDown("a") then
        self.velocity.x = -self.MOVE_SPEED
		self.anim.facing = self.anim.FACING_LEFT
    end
    if love.keyboard.isDown("d") then
        self.velocity.x = self.MOVE_SPEED
		self.anim.facing = self.anim.FACING_RIGHT
    end

    -- Compute player's position based on velocity and gravity.
    local posX, posY = self.shape:center()
    posX = posX + (self.velocity.x * dt) -- No acceleration in X direction.
    posY = posY + (self.velocity.y * dt) + (0.5 * Constants.GRAVITY * dt * dt)

    -- Update the player's velocity due to gravity.
    self.velocity.y = self.velocity.y + (Constants.GRAVITY * dt)

	-- Left facing animations
	if self.anim.facing == self.anim.FACING_LEFT then
	
		if self.velocity.x < -10 then
			self.anim.current = self.anim.WALKING_LEFT
			--self.anim.walkLeft.reset()
		else
			self.anim.current = self.anim.STANDING_LEFT
		end
			
	else
	
		if self.velocity.x > 10 then
			self.anim.current = self.anim.WALKING_RIGHT
			--self.anim.walkRight.reset()
		else
			self.anim.current = self.anim.STANDING_RIGHT
		end
	end
	
	if self.anim.current == self.anim.STANDING_LEFT then
		self.anim.standLeft:update(dt)
	elseif self.anim.current == self.anim.STANDING_RIGHT then
		self.anim.standRight:update(dt)
	elseif self.anim.current == self.anim.WALKING_LEFT then
		self.anim.walkLeft:update(dt)
	elseif self.anim.current == self.anim.WALKING_RIGHT then
		self.anim.walkRight:update(dt)
	end
	
    self.shape:moveTo(posX, posY)
end

function Player:draw()
    local posX, posY = self.shape:center()
    local position = Vector(posX, posY)

	--[[
    love.graphics.setColor(255, 0, 0, 255)
    self.shape:draw("fill") -- for debugging
	--]]
	
	if self.anim.current == self.anim.STANDING_LEFT then
		self.anim.standLeft:draw(posX - (self.anim.standLeft.fw / 2), posY - (self.anim.standLeft.fh / 2))
	elseif self.anim.current == self.anim.STANDING_RIGHT then
		self.anim.standRight:draw(posX - (self.anim.standRight.fw / 2), posY - (self.anim.standRight.fh / 2))
	elseif self.anim.current == self.anim.WALKING_LEFT then
		self.anim.walkLeft:draw(posX - (self.anim.walkLeft.fw / 2), posY - (self.anim.walkLeft.fh / 2))
	elseif self.anim.current == self.anim.WALKING_RIGHT then
		self.anim.walkRight:draw(posX - (self.anim.walkRight.fw / 2), posY - (self.anim.walkRight.fh / 2))
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

    love.graphics.setColor(255, 255, 255, 255)
end

return Player
