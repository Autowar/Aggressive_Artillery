function widget:GetInfo()
  return {
    name      = "Aggressive Artillery",
    desc      = "This widget overrides player control of all artillery units to always attack the nearest enemy building at a safe range and always run away from enemy units.",
    author    = "AutoWar",
    date      = "2015",
    license   = "GNU GPL, v2 or later",
    layer     = 9999,
    enabled   = true
  }
end

-----------------------------------------------------------------

local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spGetAllUnits			= Spring.GetAllUnits	--( ) -> nil | unitTable = { [1] = number unitID, ... }
local spMarkerAddPoint		= Spring.MarkerAddPoint
local spEcho				= Spring.Echo
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spValidUnitID         = Spring.ValidUnitID
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetUnitDefID        = Spring.GetUnitDefID
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spGetUnitStates       = Spring.GetUnitStates
local spGiveOrderToUnitArray= Spring.GiveOrderToUnitArray
local spGetUnitIsDead 		= Spring.GetUnitIsDead
local spValidUnitID			= Spring.ValidUnitID
local spGetTeamUnits		= Spring.GetTeamUnits  --( number teamID ) -> nil | unitTable = { [1] = number unitID, etc... }
local spGetMyTeamID			= Spring.GetMyTeamID
local spGetMyAllyTeamID		= Spring.GetMyAllyTeamID
local spIsUnitIcon			= Spring.IsUnitIcon
local myAllyID = Spring.GetMyAllyTeamID()
local myTeamID = Spring.GetMyTeamID()
local CMD_ATTACK = CMD.ATTACK
local CMD_MOVE = CMD.MOVE
local CMD_UNIT_SET_TARGET = 34923

-----------------------------------------------------------------

local targetTypes = {
	["corrl"]=true,			--defender
	["corllt"]=true,		--Lotus
	["armdeva"]=true,		--stardust
	["armartic"]=true,		--faraday
	["armpb"]=true,			--gauss
	["corhlt"]=true,		--stinger
	["missiletower"]=true,	--hacksaw
	["corflak"]=true,		--cobra
	["armcir"]=true,		--chainsaw
	["screamer"]=true,		--screamer
	["corgrav"]=true,		--newton
	["turrettorp"]=true,	--urchin
	["cordoom"]=true,		--doomsday_machine
	["armanni"]=true,		--annihilator
	["cormist"]=true,		--slasher unit
	["armcrabe"]=true,		--crabe unit
--	["amphcon"]=true,		--conch builder
--	["coracv"]=true,		--welder builder
--	["corfast"]=true,		--freaker builder
--	["arm_spider"]=true,	--weaver builder
--	["corch"]=true,			--quill builder
--	["cornecro"]=true,		--convict
--	["armrectr"]=true,		--conjurer
--	["corned"]=true,		--mason
	["armwin"]=true,		--windmill
	["armsolar"]=true,		--solar
	["armfus"]=true,		--fusion reactor
	["cafus"]=true,			--singularity reactor
	["armmstor"]=true,		--storage
	["armestor"]=true,		--energy pylon
	["armnanotc"]=true,		--caretaker
	["armasp"]=true,		--air repair pad
	["corrad"]=true,		--radar
	["armjamt"]=true,		--sneaky pete
	["armarad"]=true,		--advanced radar
	["missilesilo"]=true,	--missile silo
	["armamd"]=true,		--anti_nuke
	["corbhmth"]=true,		--behemoth
	["corsilo"]=true,		--nuke silo
	["zenith"]=true,		--zenith
	["mahlazer"]=true,		--starlight
	["raveparty"]=true,		--disco_rave_party
	["armbrtha"]=true,		--big_bertha
	["cormex"]=true,		--metal_extractor
	["factorycloak"]=true,
	["factoryshield"]=true,
	["factoryveh"]=true,
	["factoryhover"]=true,
	["factorygunship"]=true,
	["factoryplane"]=true,
	["factoryspider"]=true,
	["factoryjump"]=true,
	["factorytank"]=true,
	["factoryamph"]=true,
	["factoryship"]=true,
}

local factoryploplist = {
	["factorycloak"]=true,
	["factoryshield"]=true,
	["factoryveh"]=true,
	["factoryhover"]=true,
	["factorygunship"]=true,
	["factoryplane"]=true,
	["factoryspider"]=true,
	["factoryjump"]=true,
	["factorytank"]=true,
	["factoryamph"]=true,
	["factoryship"]=true,
}

local artilleryTypes = {
	["armham"]=true,		--hammer
	["firewalker"]=true,	--firewalker
	["armmerl"]=true,		--impaler
	["armmanni"]=true,		--penetrator
	["cormart"]=true,		--pillager
	["trem"]=true,			--tremor
	["shiparty"]=true,		--crusader
	["reef"]=true,			--reef
	["armraven"]=true,		--catapult
	["corbats"]=true,		--warlord
	["armbrtha"]=true,		--big_bertha
	["corbhmth"]=true,		--behemoth
--	["mahlazer"]=true,		--starlight
--	["raveparty"]=true,		--disco_rave_party
--	["tacnuke"]=true,		--tacnuke
	["corgarp"]=true,		--wolverine
	["amphassault"]=true,	--grizzly
}

-----------------------------------------------------------------

local x1 = 0 --placeholder value will be replaced by the x coordinate of the first unit placed such as the factory plop
local z1 = 0 --placeholder value will be replaced by the z coordinate of the first unit placed such as the factory plop
local tableTargets = {}
local arrayArtillery = {}
local unitIDArray = {}
local distanceArray = {}
local closestTarget = 0
local shortestDistance = 90000

-----------------------------------------------------------------

local function Distance(x1,z1,x2,z2)
	return math.sqrt((x1-x2)^2 + (z1-z2)^2)
end

local function EstablishStartPoint(unitID)
	local x,y,z = spGetUnitPosition (unitID)
	x1=x
	z1=z
end

local function GetUnitName(unitID)
	if spValidUnitID(unitID)==true and spGetUnitDefID(unitID) then
		return UnitDefs[spGetUnitDefID(unitID)].name
	end
end

-----------------------------------------------------------------

local function CleanseEverything()
	tableTargets={}
	arrayArtillery={}
	unitIDArray={}
	distanceArray={}
	closestTarget=0
	shortestDistance=90000
end

local function FindAllArtillery()
local myUnits = spGetTeamUnits(spGetMyTeamID())
	for i=1, #myUnits do
		if artilleryTypes[GetUnitName(myUnits[i])]==true then
--			spEcho("artillery unit id is " .. myUnits[i])
			arrayArtillery[#arrayArtillery+1]=myUnits[i]
		end
	end
end

local function FindAllTargets()
local allUnits = spGetAllUnits()
	for i=1, #allUnits do
		if spGetUnitAllyTeam(allUnits[i])~=myAllyID and targetTypes[GetUnitName(allUnits[i])]==true and spGetUnitDefID(allUnits[i]) then
--			spEcho("target unit id is " .. allUnits[i])
			tableTargets[allUnits[i]]=true
		end
	end
end

local function FindAllDistancesToStartpoint()
	for unitID,_ in pairs(tableTargets) do
		local x,y,z = spGetUnitPosition(unitID)
		local x2=x
		local z2=z
		unitIDArray[#unitIDArray+1] = (unitID)
		distanceArray[#unitIDArray] = (Distance(x1,z1,x2,z2))
	end
end

local function FindSmallestDistanceValue()
	for i=1, #unitIDArray  do --this for loop determines the lowest value in the array of distances
		if distanceArray[i]<shortestDistance then
			shortestDistance=distanceArray[i]
			closestTarget=i --this is used to know what key to reference in UnitIDArray to return the correctly closest unitID
		end
	end
end

local function AttackClosestTarget()
	local theClosestTarget=unitIDArray[closestTarget]
	if theClosestTarget then
--		spEcho("closest target unit ID is " .. theClosestTarget)
		spGiveOrderToUnitArray(arrayArtillery, CMD_ATTACK, {theClosestTarget}, {"alt"})
		spGiveOrderToUnitArray(arrayArtillery, CMD_UNIT_SET_TARGET, {theClosestTarget}, {"alt"})
	end
end

--~ function StayOutOfRange()
--~ 	for i=1, #arrayArtillery do
--~ 		local a,b,c = spGetUnitPosition(arrayArtillery[i])
--~ 		--spEcho("artillery located at coordinates "..a..","..b..","..c..".")
--~ 		local nearestEnemyUnitID = spGetUnitNearestEnemy(arrayArtillery[i])
--~ 		if nearestEnemyUnitID~=nil then
--~ 			--spEcho("nearest enemy is currently "..nearestEnemyUnitID..".")
--~ 			local e,f,g = spGetUnitPosition(nearestEnemyUnitID)
--~ 			if math.sqrt((a-e)^2 + (c-g)^2) < 700 then
--~ 				spGiveOrderToUnit(arrayArtillery[i], CMD_MOVE, {x1,0,z1}, {"alt"})
--~ 			elseif math.sqrt((a-e)^2 + (c-g)^2) > 700 then
--~ 				spGiveOrderToUnit(arrayArtillery[i], CMD_MOVE, {a,0,c}, {"alt"})
--~ 			end
--~ 		end
--~ 	end
--~ end

-----------------------------------------------------------------

local function CheckSpecState(widgetname)
	 if (Spring.GetSpectatingState() or Spring.IsReplay()) and (not Spring.IsCheatingEnabled()) then
		Echo("<"..widgetname..">".." Spectator mode or replay. Widget removed.")
		widgetHandler:RemoveWidget()
		return true
	end
	return false
end

function widget:Initialize()
	if not CheckSpecState(widgetName) then
		curModID = string.upper(Game.modShortName or "")
		if ( curModID ~= "ZK" ) then
			widgetHandler:RemoveWidget()
			return
		end
	end
end

-----------------------------------------------------------------

function widget:GameFrame(frameNum)
	if frameNum%30==0 then
			CleanseEverything()
			FindAllArtillery()
			FindAllTargets()
			FindAllDistancesToStartpoint()
			FindSmallestDistanceValue()
			for i=1, #arrayArtillery do
				local a,b,c = spGetUnitPosition(arrayArtillery[i])
				--spEcho("artillery located at coordinates "..a..","..b..","..c..".")
				local nearestEnemyUnitID = spGetUnitNearestEnemy(arrayArtillery[i])
				if nearestEnemyUnitID~=nil then
					--spEcho("nearest enemy is currently "..nearestEnemyUnitID..".")
					local e,f,g = spGetUnitPosition(nearestEnemyUnitID)
					if math.sqrt((a-e)^2 + (c-g)^2) < 700 then
						spGiveOrderToUnit(arrayArtillery[i], CMD_MOVE, {x1,0,z1}, {"alt"})
					elseif math.sqrt((a-e)^2 + (c-g)^2) > 700 then
						AttackClosestTarget()
					end
				end
			end
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
--~ local x,y,z = spGetUnitPosition (unitID) --debug line
--~ spMarkerAddPoint (x,y,z, "name=" .. GetUnitName(unitID))
	if factoryploplist[GetUnitName(unitID)]==true and x1==0 and unitTeam==myTeamID then
		EstablishStartPoint(unitID)
	end
end

function widget:Update()
	if x1==0 then
	local myUnits = spGetTeamUnits(spGetMyTeamID())
		for i=1, #myUnits do
			if factoryploplist[GetUnitName(myUnits[i])]==true then
				EstablishStartPoint(myUnits[i])
				break
			end
		end
	end
end

-----------------------------------------------------------------
