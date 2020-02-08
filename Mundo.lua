local Heroes = {"Mundo"}

if not table.contains(Heroes, myHero.charName) then return end


----------------------------------------------------
--|          Lib and Update Checks               |--
----------------------------------------------------

if not FileExist(COMMON_PATH .. "PussyDamageLib.lua") then
	print("PussyDamageLib. installed Press 2x F6")
	DownloadFileAsync("https://raw.githubusercontent.com/Pussykate/GoS/master/PussyDamageLib.lua", COMMON_PATH .. "PussyDamageLib.lua", function() end)
	while not FileExist(COMMON_PATH .. "PussyDamageLib.lua") do end
end
    
require('PussyDamageLib')

if not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") then
	print("GsoPred. installed Press 2x F6")
	DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-EXT/master/Common/GamsteronPrediction.lua", COMMON_PATH .. "GamsteronPrediction.lua", function() end)
	while not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") do end
end
    
require('GamsteronPrediction')


--[[
-- [ AutoUpdate ]
do
    
    local Version = 0.01
    
    local Files = {
        Lua = {
            Path = SCRIPT_PATH,
            Name = "Mundo.lua",
            Url = "https://raw.githubusercontent.com/Pussykate/GoS/master/PussyIrelia.lua"
        },
        Version = {
            Path = SCRIPT_PATH,
            Name = "Mundo.version",
            Url = "https://raw.githubusercontent.com/Pussykate/GoS/master/PussyIrelia.version"
        }
    }
    
    local function AutoUpdate()
        
        local function DownloadFile(url, path, fileName)
            DownloadFileAsync(url, path .. fileName, function() end)
            while not FileExist(path .. fileName) do end
        end
        
        local function ReadFile(path, fileName)
            local file = io.open(path .. fileName, "r")
            local result = file:read()
            file:close()
            return result
        end
        
        DownloadFile(Files.Version.Url, Files.Version.Path, Files.Version.Name)
        local textPos = myHero.pos:To2D()
        local NewVersion = tonumber(ReadFile(Files.Version.Path, Files.Version.Name))
        if NewVersion > Version then
            DownloadFile(Files.Lua.Url, Files.Lua.Path, Files.Lua.Name)
            print("New Yoshi-Mundo Version Press 2x F6")
        else
            print("Mundo loaded")
        end
    
    end
    
    AutoUpdate()

end
]]


----------------------------------------------------
--|      Utils  --- Need for all Champs ---      |--
----------------------------------------------------

local TEAM_ALLY = myHero.team
local TEAM_ENEMY = 300 - myHero.team
local TEAM_JUNGLE = 300
local Orb
local Allies, Enemies, Turrets, Units = {}, {}, {}, {}
local TableInsert = table.insert

function LoadUnits()
	for i = 1, Game.HeroCount() do
		local unit = Game.Hero(i); Units[i] = {unit = unit, spell = nil}
		if unit.team ~= myHero.team then TableInsert(Enemies, unit)
		elseif unit.team == myHero.team and unit ~= myHero then TableInsert(Allies, unit) end
	end
	for i = 1, Game.TurretCount() do
		local turret = Game.Turret(i)
		if turret and turret.isEnemy then TableInsert(Turrets, turret) end
	end
end

local function EnemyHeroes()
	return Enemies
end

local function Ready(spell)
    return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana and Game.CanUseSpell(spell) == 0
end

local function IsValid(unit)
    if (unit and unit.valid and unit.isTargetable and unit.alive and unit.visible and unit.networkID and unit.pathing and unit.health > 0) then
        return true;
    end
    return false;
end

local function IsRecalling(unit)
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff and buff.name == 'recall' and buff.duration > 0 then
            return true, Game.Timer() - buff.startTime
        end
    end
    return false
end

local function MyHeroNotReady()
    return myHero.dead or Game.IsChatOpen() or (_G.JustEvade and _G.JustEvade:Evading()) or (_G.ExtLibEvade and _G.ExtLibEvade.Evading) or IsRecalling(myHero)
end

local function GetTarget(range) 
	if Orb == 1 then
		if myHero.ap > myHero.totalDamage then
			return EOW:GetTarget(range, EOW.ap_dec, myHero.pos)
		else
			return EOW:GetTarget(range, EOW.ad_dec, myHero.pos)
		end
	elseif Orb == 2 and SDK.TargetSelector then
		if myHero.ap > myHero.totalDamage then
			return SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_MAGICAL)
		else
			return SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_PHYSICAL)
		end
	elseif _G.GOS then
		if myHero.ap > myHero.totalDamage then
			return GOS:GetTarget(range, "AP")
		else
			return GOS:GetTarget(range, "AD")
        end
    elseif _G.gsoSDK then
		return _G.gsoSDK.TS:GetTarget()
	end
end

local function GetMode()
    
    if Orb == 1 then
        if combo == 1 then
            return 'Combo'
        elseif harass == 2 then
            return 'Harass'
        elseif lastHit == 3 then
            return 'Lasthit'
        elseif laneClear == 4 then
            return 'Clear'
        end
    elseif Orb == 2 then
		if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
			return "Combo"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
			return "Harass"	
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
			return "Clear"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
			return "LastHit"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
			return "Flee"
		end
    elseif Orb == 3 then
        return GOS:GetMode()
    elseif Orb == 4 then
        return _G.gsoSDK.Orbwalker:GetMode()
    end
end



----------------------------------------------------
--|                Checks              		|--
----------------------------------------------------


local function GetDistanceSqr(p1, p2)
	if not p1 then return math.huge end
	p2 = p2 or myHero
	local dx = p1.x - p2.x
	local dz = (p1.z or p1.y) - (p2.z or p2.y)
	return dx*dx + dz*dz
end

local function GetKillMinionCount(range, pos)
    local pos = pos.pos
	local Qcount = 0
	local Wcount = 0
	local Ecount = 0	
	for i = 1,Game.MinionCount() do
	local hero = Game.Minion(i)
	local Range = range * range
		if hero.team ~= TEAM_ALLY and hero.dead == false and GetDistanceSqr(pos, hero.pos) < Range then
			local QDmg = getdmg("Q", hero, myHero)
			local WDmg = getdmg("W", hero, myHero)
			local EDmg = getdmg("E", hero, myHero)			
			if hero.health <= QDmg then
				Qcount = Qcount + 1
			end	
			if hero.health <= WDmg then
				Wcount = Wcount + 1
			end
			if hero.health <= EDmg then
				Ecount = Ecount + 1
			end			
		end
	end
	return Qcount,Wcount,Ecount
end

local function GetMinionCount(range, pos)
    local pos = pos.pos
	local count = 0
	for i = 1,Game.MinionCount() do
	local hero = Game.Minion(i)
	local Range = range * range
		if hero.team ~= TEAM_ALLY and hero.dead == false and GetDistanceSqr(pos, hero.pos) < Range then
		count = count + 1
		end
	end
	return count
end

local function GetBuffData(unit, buffname)
  for i = 0, unit.buffCount do
    local buff = unit:GetBuff(i)
    if buff.name == buffname and buff.count > 0 then 
      return buff
    end
  end
  return {type = 0, name = "", startTime = 0, expireTime = 0, duration = 0, stacks = 0, count = 0}
end


----------------------------------------------------
--|                Champion               		|--
----------------------------------------------------

class "Mundo"

function Mundo:__init()	
	self:LoadMenu()                                            
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end) 
	
	if _G.EOWLoaded then
		Orb = 1
	elseif _G.SDK and _G.SDK.Orbwalker then
		Orb = 2
	elseif _G.GOS then
		Orb = 3
	elseif _G.gsoSDK then
		Orb = 4
	end	
end

local QData =
{
Type = _G.SPELLTYPE_LINE, Delay = 0.2, Radius = 60, Range = 975, Speed = 1850, Collision = true
}

function Mundo:LoadMenu()                     
	
--MainMenu
self.Menu = MenuElement({type = MENU, id = "Mundo", name = "Mundo"})
		
--ComboMenu  
self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo Mode"})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})	
	self.Menu.Combo:MenuElement({id = "UseW", name = "[W]", value = true})
	self.Menu.Combo:MenuElement({id = "UseE", name = "[E]", value = true})	

--LaneClear Menu
self.Menu:MenuElement({type = MENU, id = "Clear", name = "Clear Mode"})	
	self.Menu.Clear:MenuElement({id = "UseQ", name = "[Q]", value = true})
	self.Menu.Clear:MenuElement({id = "UseW", name = "[W]", value = true})
	self.Menu.Clear:MenuElement({id = "countW", name = "[W] min Minions", value = 3, min = 1, max = 7, identifier = "Minion/s"})	
	self.Menu.Clear:MenuElement({id = "UseE", name = "[E]", value = true})

	
--JungleClear Menu
self.Menu:MenuElement({type = MENU, id = "JClear", name = "JungleClear Mode"})
	self.Menu.JClear:MenuElement({id = "UseQ", name = "[Q]", value = true})	
	self.Menu.JClear:MenuElement({id = "UseW", name = "[W]", value = true})
	self.Menu.JClear:MenuElement({id = "UseE", name = "[E]", value = true})	


--LastHitMode Menu
self.Menu:MenuElement({type = MENU, id = "LastHit", name = "LastHit Mode"})
	self.Menu.LastHit:MenuElement({id = "UseQ", name = "[Q]", value = true})
	self.Menu.LastHit:MenuElement({id = "countW", name = "[W] Kill min Minions", value = 2, min = 0, max = 7, identifier = "Minion/s"})	
	self.Menu.LastHit:MenuElement({id = "UseE", name = "[E]", value = true})


--HarassMenu
self.Menu:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})		
	self.Menu.Harass:MenuElement({id = "UseQ", name = "[Q]", value = true})	

	
--Prediction
self.Menu:MenuElement({type = MENU, id = "Pred", name = "Prediction"})
	self.Menu.Pred:MenuElement({id = "PredQ", name = "Hitchance[Q]", value = 1, drop = {"Normal", "High", "Immobile"}})	
	
--JungleSteal
self.Menu:MenuElement({type = MENU, id = "Steal", name = "JungleSteal Settings"})	
	self.Menu.Steal:MenuElement({id = "UseQ", name = "[Q]", value = true})	
	self.Menu.Steal:MenuElement({id = "UseE", name = "[E]", value = true})		

--KillSteal
self.Menu:MenuElement({type = MENU, id = "ks", name = "KillSteal Settings"})	
	self.Menu.ks:MenuElement({id = "UseQ", name = "[Q]", value = true})
	self.Menu.ks:MenuElement({id = "UseW", name = "[E]", value = true})	

--Drawing 
self.Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawings Mode"})
	self.Menu.Drawing:MenuElement({id = "DrawQ", name = "Draw [Q] Range", value = true})

	
end	

function Mundo:Tick()
if MyHeroNotReady() then return end

local Mode = GetMode()
	if Mode == "Combo" then
		self:Combo()
		
	elseif Mode == "Harass" then
		self:Harass()
		
	elseif Mode == "Clear" then
		self:JungleClear()
		self:Clear()
		
	elseif Mode == "LastHit" then
		self:LastHit()	
	end	
	
	self:KillSteal()
	self:JungleSteal()

--[[
local currSpell = myHero.activeSpell
if currSpell and currSpell.valid and myHero.isChanneling then
print ("Width:  "..myHero.activeSpell.width)
print ("Speed:  "..myHero.activeSpell.speed)
print ("Delay:  "..myHero.activeSpell.castFrame)
print ("range:  "..myHero.activeSpell.range)
end
]]	

end
 
function Mundo:Draw()
  if myHero.dead then return end
                                                 
	if self.Menu.Drawing.DrawQ:Value() and Ready(_Q) then
    Draw.Circle(myHero, 925, 1, Draw.Color(225, 225, 0, 10))
	end
	if self.Menu.Drawing.DrawW:Value() and Ready(_W) then
    Draw.Circle(myHero, 625, 1, Draw.Color(225, 225, 125, 10))
	end
	local textPos = myHero.dir	
	if not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") then
		Draw.Text("GsoPred. installed Press 2x F6", 50, textPos.x + 100, textPos.y - 250, Draw.Color(255, 255, 0, 0))
	end			
end

function Mundo:Combo()
local target = GetTarget(1000)     	
if target == nil then return end
	if IsValid(target) then
		
		if myHero.pos:DistanceTo(target.pos) <= 965 and self.Menu.Combo.UseQ:Value() and Ready(_Q) then
			local pred = GetGamsteronPrediction(target, QData, myHero)
			if pred.Hitchance >= self.Menu.Pred.PredQ:Value() + 1 then
				Control.CastSpell(HK_Q, pred.CastPosition)
			end
		end

		if myHero.pos:DistanceTo(target.pos) <= 175 and self.Menu.Combo.UseW:Value() and Ready(_W) then
			Control.CastSpell(HK_W, target.pos)
		end	

		if myHero.pos:DistanceTo(target.pos) <= 175 and self.Menu.Combo.UseE:Value() and Ready(_E) then
			Control.CastSpell(HK_E)
		end			
	end	
end	

function Mundo:Harass()
local target = GetTarget(1000)     	
if target == nil then return end
	if IsValid(target) and myHero.mana/myHero.maxMana >= self.Menu.Harass.Mana:Value() / 100 then
			
		if myHero.pos:DistanceTo(target.pos) <= 965 and self.Menu.Harass.UseQ:Value() and Ready(_Q) then
			local pred = GetGamsteronPrediction(target, QData, myHero)
			if pred.Hitchance >= self.Menu.Pred.PredQ:Value() + 1 then
				Control.CastSpell(HK_Q, pred.CastPosition)
			end
		end

		
function Mundo:LastHit()
	for i = 1, Game.MinionCount() do
    local minion = Game.Minion(i)

		if myHero.pos:DistanceTo(minion.pos) <= 1000 and minion.team == TEAM_ENEMY and IsValid(minion) then
			
			
			if myHero.pos:DistanceTo(minion.pos) <= 925 and self.Menu.LastHit.UseQ:Value() and Ready(_Q) then
				local Qcount = GetKillMinionCount(175, minion)
				if Qcount >= self.Menu.LastHit.countQ:Value() then
					Control.CastSpell(HK_Q, minion.pos)
				end
			end

			
			
			if myHero.pos:DistanceTo(minion.pos) <= 175 and self.Menu.LastHit.UseE:Value() and Ready(_E) then
				local Ecount = GetKillMinionCount(100, minion)
				if Ecount >= self.Menu.LastHit.countE:Value() then
					Control.CastSpell(HK_E)
				end
			end	

				
		end
	end
end

local function CheckJungle(unit)
	if unit.charName ==
		"SRU_Blue" or unit.charName ==
		"SRU_Red" or unit.charName ==
		"SRU_Gromp" or unit.charName ==
		"SRU_Murkwolf" or unit.charName ==
		"SRU_Razorbeak" or unit.charName ==
		"SRU_Krug" or unit.charName ==
		"Sru_Crab" then
		return true
	end
	return false
end	

local function CheckJungleSteal(unit)
	if unit.charName ==
		"SRU_Baron" or unit.charName ==
		"SRU_RiftHerald" or unit.charName ==
		"SRU_Dragon_Water" or unit.charName ==
		"SRU_Dragon_Fire" or unit.charName ==
		"SRU_Dragon_Earth" or unit.charName ==
		"SRU_Dragon_Air" or unit.charName ==
		"SRU_Dragon_Elder" then
		return true
	end
	return false
end

function Mundo:JungleSteal()
	for i = 1, Game.MinionCount() do
    local minion = Game.Minion(i)

		if myHero.pos:DistanceTo(minion.pos) <= 600 and minion.team == TEAM_JUNGLE and IsValid(minion) then	
		
			if myHero.pos:DistanceTo(minion.pos) <= 975 and self.Menu.Steal.UseR:Value() and Ready(_Q) and CheckJungleSteal(minion) then
				local QDmg = getdmg("Q", minion, myHero)
				if RDmg >= minion.health then
					Control.CastSpell(HK_R, minion)
				end
			end
		end
	end
end

function Mundo:JungleClear()
	for i = 1, Game.MinionCount() do
    local minion = Game.Minion(i)

		if myHero.pos:DistanceTo(minion.pos) <= 1000 and minion.team == TEAM_JUNGLE and IsValid(minion) and myHero.mana/myHero.maxMana >= self.Menu.JClear.Mana:Value() / 100 then

			if myHero.pos:DistanceTo(minion.pos) <= 925 and self.Menu.JClear.UseQ:Value() and Ready(_Q) then
				Control.CastSpell(HK_Q, minion.pos)
			end

			if myHero.pos:DistanceTo(minion.pos) <= 175 and self.Menu.JClear.UseW:Value() and Ready(_W) then
				Control.CastSpell(HK_W, minion.pos)
			end 
			
			if myHero.pos:DistanceTo(minion.pos) <= 175 and self.Menu.JClear.UseE:Value() and Ready(_E) then
				Control.CastSpell(HK_E)
			end	
			
        end
    end
end
			
function Mundo:Clear()
	for i = 1, Game.MinionCount() do
    local minion = Game.Minion(i)

		if myHero.pos:DistanceTo(minion.pos) <= 1000 and minion.team == TEAM_ENEMY and IsValid(minion) and myHero.mana/myHero.maxMana >= self.Menu.Clear.Mana:Value() / 100 then
		
			
			if myHero.pos:DistanceTo(minion.pos) <= 925 and self.Menu.Clear.UseQ:Value() and Ready(_Q) then
				local Qcount = GetMinionCount(175, minion)
				if Qcount >= self.Menu.Clear.countQ:Value() then
					Control.CastSpell(HK_Q, minion.pos)
				end
			end

			if myHero.pos:DistanceTo(minion.pos) <= 175 and self.Menu.Clear.UseW:Value() and Ready(_W) then
				local Wcount = GetMinionCount(175, minion)
				if Wcount >= self.Menu.Clear.countW:Value() then
					Control.CastSpell(HK_W, minion.pos)
				end
			end 
			
			if myHero.pos:DistanceTo(minion.pos) <= 175 and self.Menu.Clear.UseE:Value() and Ready(_E) then
				local Ecount = GetMinionCount(100, minion)
				if Ecount >= self.Menu.Clear.countE:Value() then
					Control.CastSpell(HK_E)
				end
			end	
		end
    end
end

function Mundo:KillSteal()
	for i, target in pairs(EnemyHeroes()) do
	
		if myHero.pos:DistanceTo(target.pos) <= 1000 and IsValid(target) then
			
			if myHero.pos:DistanceTo(target.pos) <= 975 and self.Menu.ks.UseQ:Value() and Ready(_Q) then
				local pred = GetGamsteronPrediction(target, QData, myHero)
				local QDmg = getdmg("Q", target, myHero)
				if QDmg >= target.health and pred.Hitchance >= self.Menu.Pred.PredQ:Value() + 1 then
					Control.CastSpell(HK_Q, pred.CastPosition)
				end
			end


			if myHero.pos:DistanceTo(target.pos) <= 175 and self.Menu.ks.UseE:Value() and Ready(_E) then
				local EDmg = getdmg("E", target, myHero)
				if EDmg >= target.health then
					Control.CastSpell(HK_E, target)
				end
			end			
		end
	end	
end		

function OnLoad()
	if table.contains(Heroes, myHero.charName) then
		_G[myHero.charName]()
		LoadUnits()
	end
end
