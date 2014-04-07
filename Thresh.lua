_G.Update = true
local UPDATE_SCRIPT_NAME = "Thresh"
local UPDATE_HOST = "raw.githubusercontent.com"
local UPDATE_BitBucket_USER = "Dibesjr"
local UPDATE_BitBucket_FOLDER = "Scripts"
local UPDATE_BitBucket_FILE = "Thresh.lua"
local UPDATE_PATH = "/"..UPDATE_BitBucket_USER.."/"..UPDATE_BitBucket_FOLDER.."/master/"..UPDATE_BitBucket_FILE
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

local ServerData
if _G.Update then
	GetAsyncWebResult(UPDATE_HOST, UPDATE_PATH, function(d) ServerData = d end)
	function update()
		if ServerData ~= nil then
			local ServerVersion
			local send, tmp, sstart = nil, string.find(ServerData, "local version = \"")
			if sstart then
				send, tmp = string.find(ServerData, "\"", sstart+1)
			end
			if send then
				ServerVersion = tonumber(string.sub(ServerData, sstart+1, send-1))
			end

			if ServerVersion ~= nil and tonumber(ServerVersion) ~= nil and tonumber(ServerVersion) > tonumber(version) then
				DownloadFile(UPDATE_URL.."?nocache"..myHero.charName..os.clock(), UPDATE_FILE_PATH, function () print("<font color=\"#FF0000\"><b>"..UPDATE_SCRIPT_NAME..":</b> successfully updated. ("..version.." => "..ServerVersion..")</font>") end)     
			elseif ServerVersion then
				print("<font color=\"#FF0000\"><b>"..UPDATE_SCRIPT_NAME..":</b> You have got the latest version: <u><b>"..ServerVersion.."</b></u></font>")
			end		
			ServerData = nil
		end
	end
	AddTickCallback(update)
end

if myHero.charName ~= "Thresh" then return end
require "VPrediction"
require "Collision"


local VP = nil 
local ts = {}
local ThreshConfig = {}
-- called once when the script is loaded
function OnLoad()
	VP = VPrediction()
	ThreshConfig = scriptConfig("Velox Thresh", "Thresh")
	-- Adds the TS menu
	ts = TargetSelector(TARGET_LESS_CAST, 1100, DAMAGE_MAGIC)
	ts.name = "Velox Thresh"
	ThreshConfig:addTS(ts)
	-- Combo Sub-menu
	ThreshConfig:addSubMenu("Combo Settings", "Combo")
	ThreshConfig:addSubMenu("Flay Settings", "Flay")
	-- Combo menu options
	ThreshConfig.Combo:addParam("combo", "Do Combo", SCRIPT_PARAM_ONKEYDOWN, true, 32)
	ThreshConfig.Combo:addParam("walkToMouse", "Walk to Mouse", SCRIPT_PARAM_ONOFF, true)
	ThreshConfig.Combo:addParam("lantern", "Lantern in Ally", SCRIPT_PARAM_ONOFF, true)
	ThreshConfig.Combo:addParam("accuracy", "Q Accuracy Slider", SCRIPT_PARAM_SLICE, 1, 0, 5, 0)
	-- Flay menu options
	ThreshConfig.Flay:addParam("stopDash", "Stop Dashes", SCRIPT_PARAM_ONOFF, true)
	ThreshConfig.Flay:addParam("flayDir", "Flay Direction (On = back, Off = forwards)", SCRIPT_PARAM_ONOFF, true)
	-- Main Menu options
	ThreshConfig:addParam("pushGapClosers", "Push Away Gap Closers", SCRIPT_PARAM_ONOFF, false);
	
	ProdictQCol = Collision(1061, 1200, 0.500, 60)
end



-- handles script logic, a pure high speed loop
function OnTick()
	-- This just makes sure spells are ready.
	Checks()
	-- This is the combo, ifs are included
	Combo()

	if (ThreshConfig.walkToMouse == true and ThreshConfig.Combo.combo == true) then
		myHero:MoveTo(mousePos.x, mousePos.z) 
	end
end

function Combo() 
    if ts.target ~= nil and GetDistance(ts.target) <= 1000 and GetDistance(ts.target) >= 60 and ThreshConfig.Combo.combo == true then
        CastPosition,  HitChance,  Position = VP:GetLineCastPosition(ts.target, 0.500, 60, 1061, 1200, myHero.pos, 12)
        local willCollide = ProdictQCol:GetMinionCollision(CastPosition, myHero)
		if ThreshConfig.accuracy <= HitChance and not willCollide then
            CastSpell(_Q, CastPosition.x, CastPosition.z)
        end
    end
	if (ThreshConfig.Combo.combo == true and ThreshConfig.Combo.lantern == true) then
		castW()
	end
	if secondQ and ThreshConfig.Combo.combo == true then
		secondQ()
	end
	if ts.target ~= nil and GetDistance(ts.target) <= 450 and ThreshConfig.Combo.combo == true and EREADY then
		CastPosition, HitChance, Position = VP:GetLineAOECastPosition(ts.target, 0.330, 100, 550, 1100, myHero.pos)
		xPos = myHero.x + (myHero.x - ts.target.x)
		zPos = myHero.z + (myHero.z - ts.target.z)
		CastSpell(_E, xPos, zPos)
    end
end

-- Stops a dasher if VP returns that they are dashing
function StopDash() 
	for i, dasher in pairs(GetEnemyHeroes()) do
		CastPosition, HitChance, Position = VP:GetLineCastPosition(dasher, 0.500, 60, 1061, 1200, myHero.pos, 12)
		if dasher ~= nil and HitChance >= 5 and GetDistance(CastPosition) < 450 then
			if (ThreshConfig.Flay.flayDir == true) then
				xPos = myHero.x + (myHero.x - dasher.x)
				zPos = myHero.z + (myHero.z - dasher.z)
				CastSpell(_E, xPos, zPos)
			else
				CastSpell(_E, CastPosition.x, CastPosition.z)
			end
		end
	end
end

function secondQ()
	if myHero:GetSpellData(_Q).name == "threshqleap" then
		CastSpell(_Q)
	end
end

function castW()
    if (findClosestAlly() == not nil and GetDistance(findClosestAlly()) < 300 and WREADY and myHero:GetSpellData(_Q).name == "threshqleap") then
		PrintChat("Trying Lantern Toss")
        CastSpell(_W, findClosestAlly().x, findClosestAlly().z)
    end
end

function findClosestAlly()
	local closestAlly = nil
	local currentAlly = nil
	for i=1, heroManager.iCount do
			currentAlly = heroManager:GetHero(i)
			if currentAlly.team == myHero.team and not currentAlly.dead and currentAlly.charName ~= myHero.charName then
					if closestAlly == nil then
							closestAlly = currentAlly
					elseif GetDistance(currentAlly) < GetDistance(closestAlly) then
							closestAlly = currentAlly
					end
			end
	end
	return closestAlly
end

function Checks()
  QREADY = ((myHero:CanUseSpell(_Q) == READY) or (myHero:GetSpellData(_Q).level > 0 and myHero:GetSpellData(_Q).currentCd <= 0.4))
  EREADY = ((myHero:CanUseSpell(_E) == READY) or (myHero:GetSpellData(_E).level > 0 and myHero:GetSpellData(_E).currentCd <= 0.4))
  RREADY = ((myHero:CanUseSpell(_R) == READY) or (myHero:GetSpellData(_R).level > 0 and myHero:GetSpellData(_R).currentCd <= 0.4))
  IREADY = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
  ts:update()
end

function OnProcessSpell(unit, spell)
    if (ThreshConfig.pushGapClosers == true) then
		local jarvanAddition = unit.charName == "JarvanIV" and unit:CanUseSpell(_Q) ~= READY and _R or _Q -- Did not want to break the table below.
		local isAGapcloserUnit = {
	--        ['Ahri']        = {true, spell = _R, range = 450,   projSpeed = 2200},
			['Aatrox']      = {true, spell = _Q,                  range = 1000,  projSpeed = 1200, },
			['Akali']       = {true, spell = _R,                  range = 800,   projSpeed = 2200, }, -- Targeted ability
			['Alistar']     = {true, spell = _W,                  range = 650,   projSpeed = 2000, }, -- Targeted ability
			['Diana']       = {true, spell = _R,                  range = 825,   projSpeed = 2000, }, -- Targeted ability
			['Gragas']      = {true, spell = _E,                  range = 600,   projSpeed = 2000, },
			['Graves']      = {true, spell = _E,                  range = 425,   projSpeed = 2000, exeption = true },
			['Hecarim']     = {true, spell = _R,                  range = 1000,  projSpeed = 1200, },
			['Irelia']      = {true, spell = _Q,                  range = 650,   projSpeed = 2200, }, -- Targeted ability
			['JarvanIV']    = {true, spell = jarvanAddition,      range = 770,   projSpeed = 2000, }, -- Skillshot/Targeted ability
			['Jax']         = {true, spell = _Q,                  range = 700,   projSpeed = 2000, }, -- Targeted ability
			['Jayce']       = {true, spell = 'JayceToTheSkies',   range = 600,   projSpeed = 2000, }, -- Targeted ability
			['Khazix']      = {true, spell = _E,                  range = 900,   projSpeed = 2000, },
			['Leblanc']     = {true, spell = _W,                  range = 600,   projSpeed = 2000, },
			['LeeSin']      = {true, spell = 'blindmonkqtwo',     range = 1300,  projSpeed = 1800, },
			['Leona']       = {true, spell = _E,                  range = 900,   projSpeed = 2000, },
			['Malphite']    = {true, spell = _R,                  range = 1000,  projSpeed = 1500 + unit.ms},
			['Maokai']      = {true, spell = _Q,                  range = 600,   projSpeed = 1200, }, -- Targeted ability
			['MonkeyKing']  = {true, spell = _E,                  range = 650,   projSpeed = 2200, }, -- Targeted ability
			['Pantheon']    = {true, spell = _W,                  range = 600,   projSpeed = 2000, }, -- Targeted ability
			['Poppy']       = {true, spell = _E,                  range = 525,   projSpeed = 2000, }, -- Targeted ability
			--['Quinn']       = {true, spell = _E,                  range = 725,   projSpeed = 2000, }, -- Targeted ability
			['Renekton']    = {true, spell = _E,                  range = 450,   projSpeed = 2000, },
			['Sejuani']     = {true, spell = _Q,                  range = 650,   projSpeed = 2000, },
			['Shen']        = {true, spell = _E,                  range = 575,   projSpeed = 2000, },
			['Tristana']    = {true, spell = _W,                  range = 900,   projSpeed = 2000, },
			['Tryndamere']  = {true, spell = 'Slash',             range = 650,   projSpeed = 1450, },
			['XinZhao']     = {true, spell = _E,                  range = 650,   projSpeed = 2000, }, -- Targeted ability
		}
		if unit.type == 'obj_AI_Hero' and unit.team == TEAM_ENEMY and isAGapcloserUnit[unit.charName] and GetDistance(unit) < 2000 and spell ~= nil then
			if spell.name == (type(isAGapcloserUnit[unit.charName].spell) == 'number' and unit:GetSpellData(isAGapcloserUnit[unit.charName].spell).name or isAGapcloserUnit[unit.charName].spell) then
				if spell.target ~= nil and spell.target.name == myHero.name or isAGapcloserUnit[unit.charName].spell == 'blindmonkqtwo' then
	--                print('Gapcloser: ',unit.charName, ' Target: ', (spell.target ~= nil and spell.target.name or 'NONE'), " ", spell.name, " ", spell.projectileID)
			CastSpell(_E, unit.x, unit.z)
				else
					spellExpired = false
					informationTable = {
						spellSource = unit,
						spellCastedTick = GetTickCount(),
						spellStartPos = Point(spell.startPos.x, spell.startPos.z),
						spellEndPos = Point(spell.endPos.x, spell.endPos.z),
						spellRange = isAGapcloserUnit[unit.charName].range,
						spellSpeed = isAGapcloserUnit[unit.charName].projSpeed,
						spellIsAnExpetion = isAGapcloserUnit[unit.charName].exeption or false,
					}
				end
			end
		end
	end
end