local Class = require "hump.class"
local Vector = require "hump.vector"
local Constants = require "constants"

local Player = Class(function(self, collider, camera)
    self.collider = collider
    self.camera = camera

    self.SIZE = Vector(32, 32)
    self.GUN_SIZE = Vector(32, 16)

    self.shape = self.collider:addRectangle(0, 0, self.SIZE.x, self.SIZE.y)
    self.shape.kind = "player"
    self.collider:addToGroup("player", self.shape)

    self.MOVE_SPEED = Constants.PLAYER_SPEED
    self.JUMP_VELOCITY = -Constants.PLAYER_JUMP
	
	-- Animation shenanegans 
	self.anim = {}
	
	-- Animation for idle standing position when facing left
	self.anim.idleLeftImg = love.graphics.newImage("images/gen_stand_left.png")
	self.anim.idleLeft = newAnimation(self.anim.idleLeftImg, 32, 32, 0.3, 2)
	
	-- Animation for idle standing position when facing right
	self.anim.idleRightImg = love.graphics.newImage("images/gen_stand_right.png")
	self.anim.idleRight = newAnimation(self.anim.idleRightImg, 32, 32, 0.3, 2)
	
	-- Animation for idle walking position when facing left
	self.anim.walkLeftImg = love.graphics.newImage("images/gen_walk_left.png")
	self.anim.walkLeft = newAnimation(self.anim.walkLeftImg, 32, 32, 0.2, 4)
	
	-- Animation for idle walking position when facing right
	self.anim.walkRightImg = love.graphics.newImage("images/gen_walk_right.png")
	self.anim.walkRight = newAnimation(self.anim.walkRightImg, 32, 32, 0.2, 4)
	
	-- Animation for idle walking position when facing right
	self.anim.walkRightImg = love.graphics.newImage("images/gen_walk_right.png")
	self.anim.walkRight = newAnimation(self.anim.walkRightImg, 32, 32, 0.2, 4)
	
	-- Animation for jumping when facing left
	self.anim.jumpLeftImg = love.graphics.newImage("images/gen_jump_left.png")
	self.anim.jumpLeft = newAnimation(self.anim.jumpLeftImg, 64, 64, 0.2, 2)
	self.anim.jumpLeft:setMode("once")
	
	-- Animation for jumping when facing right
	self.anim.jumpRightImg = love.graphics.newImage("images/gen_jump_right.png")
	self.anim.jumpRight = newAnimation(self.anim.jumpRightImg, 64, 64, 0.2, 2)
	self.anim.jumpRight:setMode("once")
	
	-- Set default animation states
	self.anim.current = "idle"
	self.anim.facing = "left"
    
    self:reset()
end)

function Player:reset()
    self.velocity = Vector(0, 0)
    self.health = 100
    self.drunk = 100
    self.anim.current = "jumping"
    self.gunDirection = Vector(1, 0)
    self.jumping = false
end

function Player:jump()
    if self.velocity.y > 0 then
        return
    end
    
    if self.velocity.y < 0 then     
        return
    end
    
	-- set animation state
    self.anim.current = "jumping"
    
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
		
		-- reset animation state
		if self.anim.current == "jumping" then
			print "setting to idle"
			self.anim.current = "idle"
		end
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
		self.anim.facing = "left"
    end
    if love.keyboard.isDown("d") then
        self.velocity.x = self.MOVE_SPEED
		self.anim.facing = "right"

    end

    -- Compute player's position based on velocity and gravity.
    local posX, posY = self.shape:center()
    posX = posX + (self.velocity.x * dt) -- No acceleration in X direction.
    posY = posY + (self.velocity.y * dt) + (0.5 * Constants.GRAVITY * dt * dt)

    -- Update the player's velocity due to gravity.
    self.velocity.y = self.velocity.y + (Constants.GRAVITY * dt)

	-- Only update if we aren't falling
	if self.anim.current ~= "jumping" then
		if self.anim.facing == "left" then
		
			if self.velocity.x < -10 then
				self.anim.current = "walking"
				--self.anim.walkLeft.reset()
			else
				self.anim.current = "idle"
			end
				
		else
		
			if self.velocity.x > 10 then
				self.anim.current = "walking"
				--self.anim.walkRight.reset()
			else
				self.anim.current = "idle"
			end
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
    local mousePos = self.camera:worldCoords(Vector(love.mouse.getPosition()))
    self.gunDirection.x = mousePos.x - posX
    self.gunDirection.y = mousePos.y - posY
    self.gunDirection:normalize_inplace()
end

function Player:draw()
    local position = Vector(self.shape:center())
	
    local posX, posY = self.shape:center()
	if self.anim.facing == "left" then
		if self.anim.current == "walking" then
			self.anim.walkLeft:draw(posX - (self.anim.walkLeft.fw / 2), posY - (self.anim.walkLeft.fh / 2))
		elseif self.anim.current == "idle" then
			self.anim.idleLeft:draw(posX - (self.anim.idleLeft.fw / 2), posY - (self.anim.idleLeft.fh / 2))
		elseif self.anim.current == "jumping" then
			self.anim.jumpLeft:draw(posX - (self.anim.jumpLeft.fw / 2), posY - (self.anim.jumpLeft.fh / 2))
		else
			print "WHAT IS GOING ON?!"
		end
	else
		if self.anim.current == "walking" then
			self.anim.walkRight:draw(posX - (self.anim.walkRight.fw / 2), posY - (self.anim.walkRight.fh / 2))
		elseif self.anim.current == "idle" then
			self.anim.idleRight:draw(posX - (self.anim.idleRight.fw / 2), posY - (self.anim.idleRight.fh / 2))
		elseif self.anim.current == "jumping" then
			self.anim.jumpRight:draw(posX - (self.anim.jumpRight.fw / 2), posY - (self.anim.jumpRight.fh / 2))
		else
			print "WHAT IS GOING ON?!"
		end
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
    love.graphics.setColor(255, 255, 0, 255)
    love.graphics.push()
    love.graphics.translate(position.x, position.y)
    love.graphics.rotate(math.atan2(self.gunDirection.y, self.gunDirection.x))
    love.graphics.rectangle("fill",
        -self.GUN_SIZE.y / 2, -self.GUN_SIZE.y / 2,
        self.GUN_SIZE.x, self.GUN_SIZE.y
    )
    love.graphics.pop()

    love.graphics.setColor(255, 255, 255, 255)
end

return Player
