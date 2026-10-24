AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
util.AddNetworkString( "beerboileropen" )

-- Works even if lua/dubz_cooking/ (the config) didn't load: falls back to the original numbers
local DEFAULTS = {cookSeconds = 30, donutEnergy = 10, donutHealth = 10, goldenChance = 1000, goldenClass = "dubnut_gold", goldenEnergy = 10, goldenHealth = 10}
local function cfg() return (DubzCooking and DubzCooking.Config) or DEFAULTS end
local function cookingEnabled() return not (DubzCooking and DubzCooking.Enabled) or DubzCooking.Enabled() end


function ENT:Initialize( )
	self:SetModel( "models/props_c17/furnitureStove001a.mdl" )
	self:SetUseType( SIMPLE_USE )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetTimer( -1 )
	self:SetMilkAmount( 0 )
	self:SetIngAmount( 0 )

	self:GetPhysicsObject():SetMass(105);
end

function ENT:SpawnFunction(ply, trace)
	local ent = ents.Create("dub_stove")
	ent:SetPos(trace.HitPos + trace.HitNormal * 8)
	ent:Spawn()
	ent:Activate()
 
	return ent
end

function ENT:PhysicsCollide( data )
	if data.DeltaTime > 0 and data.HitEntity:GetClass( ) == "dub_milk" and self:GetMilkAmount( ) < 1 then
		self:SetMilkAmount( self:GetMilkAmount( ) + 1 )
		data.HitEntity:Remove( )

		self:EmitSound("Computer.ImpactSoft")
	end

	if data.DeltaTime > 0 and data.HitEntity:GetClass( ) == "dub_ingredients" and self:GetIngAmount( ) < 1 then
		self:SetIngAmount( self:GetIngAmount( ) + 1 )
		data.HitEntity:Remove( )

		self:EmitSound("Computer.ImpactSoft")
	end

	if self:GetMilkAmount( ) == 1 and self:GetIngAmount( ) == 1 and self:GetTimer( ) == -1 and cookingEnabled() then
		self:SetTimer( cfg().cookSeconds )
	end
end

function ENT:Think( )
	if not cookingEnabled() then return end

	if ( not self.nextTimer or CurTime( ) >= self.nextTimer ) and ( self:GetTimer( ) > 0 ) then
		self:SetTimer( self:GetTimer( ) - 1 )
		self.nextTimer = CurTime( ) + 1
	end
end

function ENT:Use( _, caller )
	if not cookingEnabled() then return end

	local curTime = CurTime( )

	if ( not self.nextitem or curTime >= self.nextitem ) then
		if self:GetTimer( ) == 0 then
			self:SetMilkAmount( 0 )
			self:SetIngAmount( 0 )
			local dubnut = ents.Create( "dubnut" )
			dubnut:SetPos( self:GetPos( ) + self:GetUp( ) * 27 )
			dubnut:SetAngles( self:GetAngles( ) )
			dubnut:Spawn( )
			dubnut:GetPhysicsObject( ):SetVelocity( self:GetUp( ) * 2 )
			dubnut:SetModel( "models/noesis/donut.mdl" )
			self:SetTimer( -1 )
			self:EmitSound("Town.d1_town_02_elevbell1")

			-- Cooking is honest work: the Karma module's "Karma Sources" table decides what it is worth
			if IsValid( caller ) and DubzKarma and DubzKarma.Reward then DubzKarma.Reward( "cooked", "dubnut", caller, nil ) end
		end

		self.nextitem = curTime + 0.5
	end
end

local function PlayerPickup( ply, ent )
   if ent:GetClass() == "dub_stove" and ply == ent:Getowning_ent() then
      return true
   end
end

hook.Add( "PhysgunPickup", "Allow Player to pickup.", PlayerPickup )