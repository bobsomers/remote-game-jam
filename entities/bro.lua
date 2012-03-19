local Class = require "hump.class"
local Vector = require "hump.vector"
local gfx = love.graphics
local Constants = require "constants"

local Bro = Class(function(self, collider)
    self.collider = collider

    self.SIZE = Vector(32, 64)

    -- add 32 to the center of the player
	self.PLAYER_FLOOR = Vector(0, 32)
    
    self.shape = self.collider:addRectangle(0, 0, self.SIZE.x, self.SIZE.y)
    self.shape.kind = "bro"
    self.collider:addToGroup("bro", self.shape)

    self.MOVE_SPEED = (Constants.PLAYER_SPEED / 8)
    self.JUMP_VELOCITY = (-Constants.PLAYER_JUMP / 8)

     ----------------------------------------------------------------------------
	-- Animation shenanegans 
	----------------------------------------------------------------------------
	self.anim = {}
	self.anim["left"] = {}
	self.anim["right"] = {}
	-- Animation for idle standing position when facing left
	self.anim["left"]["idle"] = {}
	idleLeftImg = love.graphics.newImage("images/bro/gen_stand_left.png")
	self.anim["left"]["idle"] = newAnimation(idleLeftImg, 32, 32, 0.3, 2)
	self.anim["left"]["idle"].faceCenter = {
		Vector(18, 29), 
		Vector(18, 30)
	}
	self.anim["left"]["idle"].gunCenter = {
		Vector(-32, 7), 
		Vector(-32, 8)
	}
	
	-- Animation for idle standing position when facing right
	self.anim["right"]["idle"] = {}
	idleRightImg = love.graphics.newImage("images/bro/gen_stand_right.png")
	self.anim["right"]["idle"] = newAnimation(idleRightImg, 32, 32, 0.3, 2)
	self.anim["right"]["idle"].faceCenter = {
		Vector(14, 29), 
		Vector(14, 30)
	}
	self.anim["right"]["idle"].gunCenter = {
		Vector(0, 7), 
		Vector(0, 8)
	}
	
	-- Animation for walking position when facing left
	self.anim["left"]["walk"] = {}
	walkLeftImg = love.graphics.newImage("images/bro/gen_walk_left.png")
	self.anim["left"]["walk"] = newAnimation(walkLeftImg, 32, 32, 0.2, 4)
	self.anim["left"]["walk"].faceCenter = {
		Vector(16, 32), 
		Vector(17, 32),
		Vector(16, 32), 
		Vector(17, 31)
	}
	self.anim["left"]["walk"].gunCenter = {
		Vector(-34, 4), 
		Vector(-32, 5), 
		Vector(-34, 4), 
		Vector(-34, 5)
	}
	
	-- Animation for walking position when facing right
	self.anim["right"]["walk"] = {}
	walkRightImg = love.graphics.newImage("images/bro/gen_walk_right.png")
	self.anim["right"]["walk"] = newAnimation(walkRightImg, 32, 32, 0.2, 4)
	self.anim["right"]["walk"].faceCenter = {
		Vector(16, 32), 
		Vector(15, 32),
		Vector(16, 32), 
		Vector(15, 31)
	}
	self.anim["right"]["walk"].gunCenter = {
		Vector(4, 4), 
		Vector(2, 5), 
		Vector(2, 4), 
		Vector(4 , 5)
	}
	
	-- Animation for jumping when facing left
	self.anim["left"]["jump"] = {}
	jumpLeftImg = love.graphics.newImage("images/bro/gen_jump_left.png")
	self.anim["left"]["jump"] = newAnimation(jumpLeftImg, 64, 64, 0.1, 2)
	self.anim["left"]["jump"]:setMode("once")
	-- Don't question the magic.
	self.anim["left"]["jump"].faceCenter = {
		Vector(34, 64-75),
		Vector(34, 64-45)
	}
	self.anim["left"]["jump"].gunCenter = {
		Vector(-17, 64-28), 
		Vector(-17, 64-46)
	}
	
	-- Animation for jumping when facing right
	self.anim["right"]["jump"] = {}
	jumpRightImg = love.graphics.newImage("images/bro/gen_jump_right.png")
	self.anim["right"]["jump"] = newAnimation(jumpRightImg, 64, 64, 0.1, 2)
	self.anim["right"]["jump"]:setMode("once")
	-- Don't question the magic.
	self.anim["right"]["jump"].faceCenter = {
		Vector(34, 64-75), 
		Vector(34, 64-45)
	}
	self.anim["right"]["jump"].gunCenter = {
		Vector(17, 64-28), 
		Vector(17, 64-46)
	}
	
	-- Animation for head (because I don't want to figure out how to draw with graphics
	-- cause it's different than animations :| )
	self.anim["left"]["head"] = {}
	faceNeutralLeftImg = love.graphics.newImage("images/bro/gen_head_left.png")
	self.anim["left"]["head"] = newAnimation(faceNeutralLeftImg, 48, 48, 1, 1)
	self.anim["left"]["head"].center = Vector(24, 8)
	
	self.anim["right"]["head"] = {}
	faceNeutralRightImg = love.graphics.newImage("images/bro/gen_head_right.png")
	self.anim["right"]["head"] = newAnimation(faceNeutralRightImg, 48, 48, 1, 1)
	self.anim["right"]["head"].center = Vector(24, 8)
	
	-- Set default animation states
	self.anim.current = "idle"
	self.anim.facing = "left"
    
    self:reset()
end)

function Bro:reset()
    self.PUNCH_DAMAGE = math.random(Constants.BRO_PUNCH_DAMAGE_MIN,
        Constants.BRO_PUNCH_DAMAGE_MAX)
    self.velocity = Vector(0, 0)
    self.health = 100
    self.alive = true
    self.collider:setSolid(self.shape)
    self.punchCooldown = 0
    self:changeAnim("left", "jump")
end

function Bro:kill()
    self.alive = false
    self.collider:setGhost(self.shape)
end

function Bro:jump()
    --[[
    if self.velocity.y > 0 then
        -- Can't jump!
        return
    end
    --]]

    -- set animation state
	-- self:changeAnim(self.anim.facing, "jump")
    
    -- Apply some instantaneous velocity in the Y direction.
    local x, y = self.shape:center()
    self.shape:moveTo(x, y - 1)
    self.velocity.y = self.JUMP_VELOCITY
end

function Bro:collideWorld(tileShape, mtv)
    -- Apply minimum translation vector to resolve the collision.
    self.shape:move(mtv.x, mtv.y)    

    -- If we corrected the player in the Y direction, their Y velocity is 0.
    if mtv.y ~= 0 then
        self.velocity.y = 0
    end
    
    if self.anim.current == "jump" then
			self:changeAnim(self.anim.facing, "idle")
		end
end

function Bro:changeAnim(facing, state)
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

function Bro:updateAnim(dt)
	self.anim[self.anim.facing][self.anim.current]:update(dt)
end

function Bro:resetAnim()
	-- print("resetting " .. self.anim.facing .. "/" .. self.anim.current)
	self.anim[self.anim.facing][self.anim.current]:reset()
	self.anim[self.anim.facing][self.anim.current]:play()
end 

function Bro:attackPlayer(player, mtv)
    -- Damage the player.
    if self.punchCooldown < 0 then
        player.health = player.health - self.PUNCH_DAMAGE
        self.punchCooldown = Constants.BRO_PUNCH_COOLDOWN
    end
end

function Bro:attackPubmate(pubmate, mtv)
    -- Damage the pubmate.
    if self.punchCooldown < 0 then
        pubmate.health = pubmate.health - self.PUNCH_DAMAGE
        self.punchCooldown = Constants.BRO_PUNCH_COOLDOWN
    end

    -- Resolve the collision by moving them 10x the MTV away from each other.
    self.shape:move(5 * mtv.x, 5 * mtv.y)
    pubmate.shape:move(-5 * mtv.x, -5 * mtv.y)
end

function Bro:update(dt)
    if not self.alive then return end

    -- Reduce their punch cooldown.
    self.punchCooldown = self.punchCooldown - dt

    -- Always be moving LEFT
    self.velocity.x = -self.MOVE_SPEED

    -- Compute player's position based on velocity and gravity.
    local posX, posY = self.shape:center()
    posX = posX + (self.velocity.x * dt) -- No acceleration in X direction.
    posY = posY + (self.velocity.y * dt) + (0.5 * Constants.GRAVITY * dt * dt)

    -- Update the player's velocity due to gravity.
    self.velocity.y = self.velocity.y + (Constants.GRAVITY * dt)

    self.shape:moveTo(posX, posY)
    
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
end

function Bro:draw()
    if not self.alive then return end

    local posX, posY = self.shape:center()
    local position = Vector(posX, posY)
    
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

	--Get the final offset
	finalOffset = offset -- + self.anim[self.anim.facing]["gun"].center
	
	--local invert
	--if self.anim[self.anim.facing] == left:
	
	
	 -- Draw their health meter.
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.rectangle("fill",
        position.x - (self.SIZE.x / 2), position.y - (self.SIZE.y / 2) - 12,
        self.health / 100 * self.SIZE.x, 4
    )
    
    love.graphics.setColor(255, 255, 255, 255)
end

return Bro
