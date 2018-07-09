local roshanPanel = {}

-- *** Get screen size *** --
local size_x, size_y = Renderer.GetScreenSize()

-- *** Menu *** --
roshanPanel.optionEnable = Menu.AddOption({"mlambers", "Roshan Panel"}, "1. Enable", "Enable this script.")
roshanPanel.offsetX = Menu.AddOption({"mlambers", "Roshan Panel"}, "2. Panel x offset", "", 0, size_x-100, 10)
roshanPanel.offsetY = Menu.AddOption({"mlambers", "Roshan Panel"}, "3. Panel y offset", "", 0, size_y-50, 10)
roshanPanel.offsetSize = Menu.AddOption({"mlambers", "Roshan Panel"}, "4. Panel size", "", 28, 56, 1)

-- *** Init variable for assets *** --
roshanPanel.AssetsPath = "~/Extra/"
roshanPanel.ItemsPath	= "resource/flash3/images/items/"
roshanPanel.TotalLoad = 0
local cache_assets = {
	icon_roshan_timerbackground_norosh_psd = nil, 
	icon_roshan_timerbackground_psd = nil, 
	roshan_timer_roshan_psd = nil, 
	aegis = nil
}

-- *** Init variable for core function *** --
roshanPanel.ScriptNeedInit = true
roshanPanel.ShouldDraw = false

roshanPanel.RoshanAlive = true
roshanPanel.RoshanTimeDead = 0
roshanPanel.RoshanMinimumPossibleSpawnTime = 0
roshanPanel.RoshanMaximumPossibleSpawnTime = 0
roshanPanel.aegisTimePickup = 0

roshanPanel.boxSize = nil
roshanPanel.fontRoshanAlive = nil
roshanPanel.fontRoshanDead = nil

-- *** Localize LUA function *** --
local MathematicsFunction = {}
MathematicsFunction.floor = math.floor
MathematicsFunction.ceil = math.ceil

-- *** Config variable *** --
local configDrawing = {}
configDrawing.panelPosX = 0
configDrawing.panelPosY = 0
			
configDrawing.sizeBackground = 0
configDrawing.roshan_background_size = 0
configDrawing.roshan_background_pos_x = 0
configDrawing.roshan_background_pos_y = 0

configDrawing.roshan_size = 0
configDrawing.roshan_pos_x = 0
configDrawing.roshan_pos_y = 0

function roshanPanel.setup_config()
	-- Config panel position
	configDrawing.panelPosX = Menu.GetValue(roshanPanel.offsetX)
	configDrawing.panelPosY = Menu.GetValue(roshanPanel.offsetY)
			
	configDrawing.sizeBackground = Menu.GetValue(roshanPanel.offsetSize)
			
	-- Config roshan background image
	configDrawing.roshan_background_size = configDrawing.sizeBackground - 4
	configDrawing.roshan_background_pos_x = 2 + configDrawing.panelPosX
	configDrawing.roshan_background_pos_y = 2 + configDrawing.panelPosY
				
	-- Config roshan image
	configDrawing.roshan_size = configDrawing.sizeBackground - 14
	configDrawing.roshan_pos_x = configDrawing.roshan_background_pos_x + MathematicsFunction.floor((configDrawing.roshan_background_size - configDrawing.roshan_size) * 0.5)
	configDrawing.roshan_pos_y = configDrawing.roshan_background_pos_y + MathematicsFunction.floor((configDrawing.roshan_background_size - configDrawing.roshan_size) * 0.1)
end

function roshanPanel.load_images(path, name)
	local imageHandle = cache_assets[name]

	if (imageHandle == nil) then
		roshanPanel.TotalLoad = roshanPanel.TotalLoad + 1
		imageHandle = Renderer.LoadImage(path .. name .. ".png")
		cache_assets[name] = imageHandle
	end
end

function roshanPanel.init_roshan()
	roshanPanel.RoshanAlive = true
	roshanPanel.RoshanTimeDead = 0
	roshanPanel.RoshanMinimumPossibleSpawnTime = 0
	roshanPanel.RoshanMaximumPossibleSpawnTime = 0
	roshanPanel.aegisTimePickup = 0
	
	roshanPanel.boxSize = Menu.GetValue(roshanPanel.offsetSize)
	roshanPanel.fontRoshanAlive = Renderer.LoadFont("Tahoma", MathematicsFunction.floor(roshanPanel.boxSize * 0.5 ), Enum.FontWeight.BOLD)
	roshanPanel.fontRoshanDead = Renderer.LoadFont("Tahoma", MathematicsFunction.floor(roshanPanel.boxSize * (1/3) ), Enum.FontWeight.BOLD)
end

function roshanPanel.OnMenuOptionChange(option, old, new)
    if option == roshanPanel.offsetSize then
        roshanPanel.boxSize = Menu.GetValue(roshanPanel.offsetSize)
		roshanPanel.fontRoshanAlive = Renderer.LoadFont("Tahoma", MathematicsFunction.floor(roshanPanel.boxSize * 0.5 ), Enum.FontWeight.BOLD)
		roshanPanel.fontRoshanDead = Renderer.LoadFont("Tahoma", MathematicsFunction.floor(roshanPanel.boxSize * (1/3) ), Enum.FontWeight.BOLD)
		roshanPanel.setup_config()
	elseif option == roshanPanel.offsetX or option == roshanPanel.offsetY then
		roshanPanel.setup_config()
    end
end

function roshanPanel.OnParticleCreate(particle)
	if not Menu.IsEnabled(roshanPanel.optionEnable) then return end
	if not Heroes.GetLocal() then return end
	
	if particle.name == "roshan_spawn" then
		roshanPanel.RoshanAlive = true
		roshanPanel.RoshanTimeDead = 0
		roshanPanel.RoshanMinimumPossibleSpawnTime = 0
		roshanPanel.RoshanMaximumPossibleSpawnTime = 0
		roshanPanel.aegisTimePickup = 0
	end
end

function roshanPanel.OnChatEvent(chatEvent)
	if not Menu.IsEnabled(roshanPanel.optionEnable) then return end
	if not Heroes.GetLocal() then return end

	if (chatEvent.type == 9 and chatEvent.value == 150) then
		roshanPanel.RoshanAlive = false
		local deadTime = GameRules.GetGameTime()
		local startTime = GameRules.GetGameStartTime()
		roshanPanel.RoshanTimeDead = deadTime - startTime
		roshanPanel.RoshanMinimumPossibleSpawnTime = 480 + (deadTime - startTime)
		roshanPanel.RoshanMaximumPossibleSpawnTime = 660 + (deadTime - startTime)
	end
	
	if (chatEvent.type == 8 or chatEvent.type == 53) then
		roshanPanel.RoshanAlive = false
		roshanPanel.aegisTimePickup = GameRules.GetGameTime() + 300
	end
end

function roshanPanel.OnEntityDestroy(ent)
	if not Menu.IsEnabled(roshanPanel.optionEnable) then return end
	if not Heroes.GetLocal() then return end
	
	if roshanPanel.aegisTimePickup ~= 0 then
		if Entity.GetClassName(ent) == "C_DOTA_Item" and Ability.GetName(ent) == "item_aegis" then
			roshanPanel.aegisTimePickup = 0
		end
	end
end

function roshanPanel.OnUpdate()
	if not Menu.IsEnabled(roshanPanel.optionEnable) then return end
    local myHero = Heroes.GetLocal()
	if not myHero then return end
	
	if roshanPanel.ScriptNeedInit then
        roshanPanel.init_roshan()
		
		roshanPanel.load_images(roshanPanel.AssetsPath, "icon_roshan_timerbackground_norosh_psd")
		roshanPanel.load_images(roshanPanel.AssetsPath, "icon_roshan_timerbackground_psd")
		roshanPanel.load_images(roshanPanel.AssetsPath, "roshan_timer_roshan_psd")
		roshanPanel.load_images(roshanPanel.ItemsPath, "aegis")
		
		Console.Print("\n============================ \n= " .. os.date() .. " =\n============================ \n= " .. "Roshan panel init done   =\n= Total assets loaded: " .. roshanPanel.TotalLoad .. "   =\n============================ \n")
		
		roshanPanel.setup_config()
		roshanPanel.ShouldDraw = true
        roshanPanel.ScriptNeedInit = false
    end
end

function roshanPanel.OnDraw()
	if not Menu.IsEnabled(roshanPanel.optionEnable) then return end
    local myHero = Heroes.GetLocal()
	if not myHero then return end
	
	if roshanPanel.ShouldDraw then	
		if roshanPanel.RoshanAlive then	
			local widthSize, heightSize = Renderer.MeasureText(roshanPanel.fontRoshanAlive, "Roshan Alive")
			
			-- Config rectangle size
			local rectangle_size = 22 + (configDrawing.roshan_background_size + widthSize)
			
			-- Config text
			local text_pos_x = 12 + (configDrawing.panelPosX + configDrawing.roshan_background_size)
			local text_pos_y = MathematicsFunction.ceil((configDrawing.sizeBackground - heightSize) * 0.5) + configDrawing.panelPosY
			
			-- Draw rectangle
			Renderer.SetDrawColor(31, 88, 34, 200)
			Renderer.DrawFilledRect(configDrawing.panelPosX, configDrawing.panelPosY, rectangle_size, configDrawing.sizeBackground)
				
			-- Draw Text
			Renderer.SetDrawColor(5, 228, 225, 255)
			Renderer.DrawText(roshanPanel.fontRoshanAlive, text_pos_x, text_pos_y, "Roshan Alive", 0)
				
			-- Draw Roshan background image
			Renderer.SetDrawColor(255, 255, 255, 255)
			Renderer.DrawImage(cache_assets["icon_roshan_timerbackground_psd"], configDrawing.roshan_background_pos_x, configDrawing.roshan_background_pos_y, configDrawing.roshan_background_size, configDrawing.roshan_background_size)
				
			-- Draw Roshan image
			Renderer.DrawImage(cache_assets["roshan_timer_roshan_psd"], configDrawing.roshan_pos_x, configDrawing.roshan_pos_y, configDrawing.roshan_size, configDrawing.roshan_size)
				
		else
			local notifierText1 = "Time of Death " .. MathematicsFunction.floor(roshanPanel.RoshanTimeDead * (1/60)) .. ":" .. MathematicsFunction.ceil(roshanPanel.RoshanTimeDead % 60)
				
			-- Config text possible spawn time.
			local notifierText2 = "Spawn " .. MathematicsFunction.floor(roshanPanel.RoshanMinimumPossibleSpawnTime * (1/60)) .. ":" .. MathematicsFunction.ceil(roshanPanel.RoshanMinimumPossibleSpawnTime % 60) .. " - " .. MathematicsFunction.floor(roshanPanel.RoshanMaximumPossibleSpawnTime * (1/60)) .. ":" .. MathematicsFunction.ceil(roshanPanel.RoshanMaximumPossibleSpawnTime % 60)
			local widthSize_2, heightSize_2 = Renderer.MeasureText(roshanPanel.fontRoshanDead, notifierText2)
				
			-- Config text roshan dead time
			local widthSize_1, heightSize_1 = Renderer.MeasureText(roshanPanel.fontRoshanDead, notifierText1)
			local text_1_pos_y = MathematicsFunction.ceil((configDrawing.roshan_background_size - heightSize_1) * 0.1) + configDrawing.roshan_background_pos_y
			local text_2_pos_y = MathematicsFunction.ceil((configDrawing.roshan_background_size - heightSize_2) * 0.1) + text_1_pos_y + heightSize_1
				
			-- Config text X position
			local text_pos_x = 12 + (configDrawing.panelPosX + configDrawing.roshan_background_size)
				
			-- Config rectangle size
			local rectangle_size = 22 + (configDrawing.roshan_background_size + widthSize_2)
				
			-- Draw rectangle
			Renderer.SetDrawColor(152, 47, 46, 200)
			Renderer.DrawFilledRect(configDrawing.panelPosX, configDrawing.panelPosY, rectangle_size, configDrawing.sizeBackground)
				
			-- Draw text roshan dead time
			Renderer.SetDrawColor(5, 228, 225, 255)
			Renderer.DrawText(roshanPanel.fontRoshanDead, text_pos_x, text_1_pos_y, notifierText1, 0)
			
			-- Draw text possible spawn time 
			Renderer.DrawText(roshanPanel.fontRoshanDead, text_pos_x, text_2_pos_y, notifierText2, 0)
				
			-- Draw Roshan background image
			Renderer.SetDrawColor(255, 255, 255, 255)
			Renderer.DrawImage(cache_assets["icon_roshan_timerbackground_norosh_psd"], configDrawing.roshan_background_pos_x, configDrawing.roshan_background_pos_y, configDrawing.roshan_background_size, configDrawing.roshan_background_size)
				
			-- Draw Roshan image
			Renderer.DrawImage(cache_assets["roshan_timer_roshan_psd"], configDrawing.roshan_pos_x, configDrawing.roshan_pos_y, configDrawing.roshan_size, configDrawing.roshan_size)
				
			if roshanPanel.aegisTimePickup ~= 0 then
				-- Config aegis image
				local panelPosYaegis = 2 + (configDrawing.panelPosY + configDrawing.sizeBackground)
				local aegisSize =  MathematicsFunction.floor(configDrawing.roshan_size * 0.8)
					
				-- Draw aegis image
				Renderer.SetDrawColor(255, 255, 255, 255)	
				Renderer.DrawImage(cache_assets["aegis"], configDrawing.panelPosX, panelPosYaegis, aegisSize, aegisSize)
				
				local timerAegis = MathematicsFunction.floor(roshanPanel.aegisTimePickup - GameRules.GetGameTime())
					
				if timerAegis == 0 then
					roshanPanel.aegisTimePickup = 0
				end
				
				local notifTextAegisCounter = MathematicsFunction.floor(timerAegis * (1/60)) .. ":" .. MathematicsFunction.floor(timerAegis % 60)
					
				-- Config Aegis timer text
				local aegisTimer_width, aegisTimer_height = Renderer.MeasureText(roshanPanel.fontRoshanDead, notifTextAegisCounter)
				local panelPosXtextAegis = 5 + (configDrawing.panelPosX + aegisSize)
				local panelPosYtextAegis = MathematicsFunction.floor((aegisSize-aegisTimer_height) * 0.5) + panelPosYaegis
				
				-- Draw aegis timer text
				Renderer.DrawText(roshanPanel.fontRoshanDead, panelPosXtextAegis, panelPosYtextAegis, notifTextAegisCounter, 0)
			end
		end
	end
end

function roshanPanel.OnGameEnd()
	cache_assets = {
		icon_roshan_timerbackground_norosh_psd = nil, 
		icon_roshan_timerbackground_psd = nil, 
		roshan_timer_roshan_psd = nil, 
		aegis = nil
	}
	
	roshanPanel.ScriptNeedInit = true
	roshanPanel.ShouldDraw = false
	
	roshanPanel.RoshanAlive = true
	roshanPanel.RoshanTimeDead = 0
	roshanPanel.RoshanMinimumPossibleSpawnTime = 0
	roshanPanel.RoshanMaximumPossibleSpawnTime = 0
	roshanPanel.aegisTimePickup = 0
	roshanPanel.TotalLoad = 0
	
	roshanPanel.boxSize = nil
	roshanPanel.fontRoshanAlive = nil
	roshanPanel.fontRoshanDead = nil
	
	configDrawing.panelPosX = 0
	configDrawing.panelPosY = 0
				
	configDrawing.sizeBackground = 0
	configDrawing.roshan_background_size = 0
	configDrawing.roshan_background_pos_x = 0
	configDrawing.roshan_background_pos_y = 0

	configDrawing.roshan_size = 0
	configDrawing.roshan_pos_x = 0
	configDrawing.roshan_pos_y = 0
	
	Console.Print("\n================================ \n=   " .. os.date() .. "   =\n================================ \n= " .. "Roshan panel reset OnGameEnd =\n" .. "================================ \n")
end

return roshanPanel