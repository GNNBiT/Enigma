	--[[-------------------------------------------------------------------------------------------------------
		
								______			______			__		 ____________
							   |  ___ \ 	   |  ___ \	   	   [__]		[_____	_____]
							   | |	 \ \	   | |	 \ \	    __			 |  |
							   | |____| |      | |____| |	   |\ |			 |  |
							   |  _____ /	   |  _____	/      | \|			 |  |
							   | |     \ \	   | |     \ \	   | /|			 |  |
							   | |	    \ \	   | |	    \ \	   |/ |			 |  |
							   | |______/ /	   | |______/ /	   |\ |			 |  |
							   |_________/	   |_________/	   [_\]			 [__]
		
		------------------------------------------- ОСНОВНОЕ МЕНЮ ---------------------------------------------]]--
local Enigma = {}
	Enigma.optionEnable = Menu.AddOptionBool({"Hero Specific","Enigma"}, "Enabled", false)
	Enigma.optionKey = Menu.AddKeyOption({"Hero Specific","Enigma"}, "Auto Procast", Enum.ButtonCode.KEY_C)
	Menu.AddMenuIcon({"Hero Specific", "Enigma"}, "panorama/images/heroes/icons/npc_dota_hero_enigma_png.vtex_c")
	
	Enigma.Hero = nil
	
	Enigma.Delay = 0.2
	Enigma.TimerInfo = 0
	Enigma.TimerCombo = 0
	Enigma.GameTime = 0
	Enigma.NextOrder = 0
	
	Enigma.blink = nil
	Enigma.pulse = nil
	Enigma.black_hole = nil
	Enigma.bkb = nil
	Enigma.shiva = nil
	Enigma.refresher = nil
	Enigma.heroMana = 0
	Enigma.bestPos = nil
	Enigma.enemyes = nil
	
	local blink_radius = 1200
	local black_hole_radius = 420
	function Enigma.OnUpdate()
		if Enigma.Hero == nil then Enigma.Hero = Heroes.GetLocal() end
		if NPC.GetUnitName(Enigma.Hero) ~= 'npc_dota_hero_enigma' then return true end
		if not Entity.IsAlive(Enigma.Hero) then return true end
		if not Menu.IsEnabled(Enigma.optionEnable) then return true end
		Enigma.GameTime = os.clock()
		if Enigma.GameTime - Enigma.Delay > Enigma.TimerInfo then Enigma.DelayUpdate() Enigma.TimerInfo = Enigma.GameTime end
		if not Enigma.black_hole then return end
		if not Ability.IsReady(Enigma.black_hole) or not Ability.IsCastable(Enigma.black_hole, Enigma.heroMana) then 		
			if not Enigma.refresher or not Ability.IsReady(Enigma.refresher) or not Ability.IsCastable(Enigma.refresher, Enigma.heroMana - Ability.GetManaCost(Enigma.black_hole)) then return end
		end	
		if Menu.IsKeyDown(Enigma.optionKey) and Enigma.TimerCombo < Enigma.GameTime then Enigma.Combo() end
	end		
	
	function Enigma.Combo()
		if NPC.GetModifier(Enigma.Hero, 'modifier_enigma_black_hole_thinker') then return end
		if Enigma.NextOrder == 0 then  
		elseif Enigma.NextOrder == 1 then Ability.CastPosition(Enigma.blink, Enigma.bestPos) return
		elseif Enigma.NextOrder == 2 then Ability.CastNoTarget(Enigma.bkb) return
		elseif Enigma.NextOrder == 3 then Ability.CastPosition(Enigma.pulse, Enigma.bestPos) 
		elseif Enigma.NextOrder == 4 then Ability.CastNoTarget(Enigma.shiva) return
		elseif Enigma.NextOrder == 5 then Ability.CastPosition(Enigma.black_hole, Enigma.bestPos)
		elseif Enigma.NextOrder == 6 then Ability.CastNoTarget(Enigma.refresher) return
		else end		
		Enigma.TimerCombo = Enigma.GameTime
	end
	
	function Enigma.DelayUpdate()	
		Enigma.NextOrder = 0
		Enigma.enemyes = nil
		if Entity.GetHeroesInRadius(Enigma.Hero, blink_radius + black_hole_radius, Enum.TeamType.TEAM_ENEMY) then
			Enigma.enemyes = Entity.GetHeroesInRadius(Enigma.Hero, blink_radius + black_hole_radius, Enum.TeamType.TEAM_ENEMY) end
		if not Enigma.enemyes or #Enigma.enemyes == 0 then return end
		Enigma.bestPos = Enigma.BestPosition(Enigma.enemyes, black_hole_radius)
		
		Enigma.blink = NPC.GetItem(Enigma.Hero, "item_blink")
		Enigma.shiva = NPC.GetItem(Enigma.Hero, "item_shivas_guard")
		Enigma.bkb = NPC.GetItem(Enigma.Hero, "item_black_king_bar")
		Enigma.refresher = NPC.GetItem(Enigma.Hero, "item_refresher")
		
		Enigma.pulse = NPC.GetAbility(Enigma.Hero, "enigma_midnight_pulse")
		Enigma.black_hole = NPC.GetAbility(Enigma.Hero, "enigma_black_hole")
		Enigma.heroMana = NPC.GetMana(Enigma.Hero)
		
				
					
		if Enigma.blink and Ability.IsReady(Enigma.blink) then Enigma.NextOrder = 1 return end
		if Enigma.bkb and Ability.IsReady(Enigma.bkb) then Enigma.NextOrder = 2 return end
		
		if not (Enigma.refresher and Ability.IsReady(Enigma.refresher) and not Ability.IsCastable(Enigma.black_hole, Enigma.heroMana - Ability.GetManaCost(Enigma.refresher))) then   
			if Enigma.pulse and Ability.IsReady(Enigma.pulse) and Ability.IsCastable(Enigma.black_hole, Enigma.heroMana - Ability.GetManaCost(Enigma.black_hole)) 	
				then Enigma.NextOrder = 3 return end
			if Enigma.shiva and Ability.IsReady(Enigma.shiva) 
				then Enigma.NextOrder = 4 return end
			end
		
		if Enigma.black_hole and Ability.IsReady(Enigma.black_hole) then Enigma.NextOrder = 5 return end		
		if Enigma.refresher and Ability.IsReady(Enigma.refresher) then Enigma.NextOrder = 6 return end		
		
	end
	
	function Enigma.BestPosition(unitsAround, radius)
		if not unitsAround or #unitsAround <= 0 then return nil end
		local enemyNum = #unitsAround
		if enemyNum == 1 then return Entity.GetAbsOrigin(unitsAround[1]) end
		local maxNum = 1
		local bestPos = Entity.GetAbsOrigin(unitsAround[1])
		for i = 1, enemyNum-1 do
			for j = i+1, enemyNum do
				if unitsAround[i] and unitsAround[j] then
					local pos1 = Entity.GetAbsOrigin(unitsAround[i])
					local pos2 = Entity.GetAbsOrigin(unitsAround[j])
					local mid = pos1:__add(pos2):Scaled(0.5)
					local heroesNum = 0
					for k = 1, enemyNum do
						if NPC.IsPositionInRange(unitsAround[k], mid, radius, 0) then
							heroesNum = heroesNum + 1
						end
					end
					if heroesNum > maxNum then
						maxNum = heroesNum
						bestPos = mid
					end
				end
			end
		end
		return bestPos
	end
	
return Enigma