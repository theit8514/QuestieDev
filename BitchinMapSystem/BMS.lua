NOTES_DEBUG = true;--Set to nil to not get debug shit

--Contains all the frames ever created, this is not to orphan any frames by mistake...
local AllFrames = {};

--Contains frames that are created but currently not used (Frames can't be deleted so we pool them to save space);
local FramePool = {};

BMS = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0",  "AceDB-2.0", "AceDebug-2.0", "AceEvent-2.0", "AceHook-2.1");
local L_Astrolabe = AceLibrary:GetInstance("Astrolabe-0.2");

NOTES_MAP_ICON_SCALE = 1.2;-- ZoneBMSBMSBMSBMSBMSBMSBMSBMSBMSBMSBMS
NOTES_WORLD_MAP_ICON_SCALE = 0.75;--Full world shown
NOTES_CONTINENT_ICON_SCALE = 0.95;--Continent Shown
NOTES_MINIMAP_ICON_SCALE = 1.0;

L_Astrolabe.MinimapUpdateTime = 0.03; -- Update interval for Minimap, i think 0.03 is the slowest to not have any noticeable jittering.

local Registered_Addons = {};

local FrameLevel = 14;

--DEBUG CODE!
function BitchinMapSystem_SlashHandler(msgbase)

	if(msgbase=="test") then
		--function BMS:AddNoteToMap(continent, zoneid, posx, posy, id, icon, tooltip_function)
		--BMS:AddNoteToMap(2,12,0.5,0.5, 10,"complete",function() 	BMS:debug_Print("test: "..tostring(this.data.customData)); end);
		--BMS:RegisterAddon("TestAddon", BMS);
		--BMS:CLEAR_ALL_NOTES();
		L_Astrolabe.processingFrame:Show();
	elseif(msgbase == "draw") then
		BMS:DRAW_NOTES();
	elseif(msgbase == "frames") then
		for i = 1, table.getn(AllFrames) do
			BMS:debug_Print(AllFrames[i]:GetName());
		end
	else
		BMS:debug_Print("No such command");
	end

end

--GetNodes Example
function BMS:GetNodes(continent, zone)
	Notes = {};

	--Sets values that i want to use for the notes THIS IS WIP MORE INFO MAY BE NEDED BOTH IN PARAMETERS AND NOTES!!!
	Note = {};
	Note.x = 0.5;
	Note.y = 0.5;
	Note.zoneid = 12;
	Note.continent = 2;
	Note.icon = Icons["complete"].path;
	Note.Tooltip = function() 	BMS:debug_Print("test: "..tostring(this.data.customData)); end;
	Note.Click = function() DEFAULT_CHAT_FRAME:AddMessage("Clicky") end;
	Note.customData = 10;
	--Inserts it into the right zone and continent for later use.
	table.insert(Notes, Note);
	return Notes;
end
--DEBUG CODE END!

function BMS:RegisterAddon(name, Addon)
	if(Addon) then
		Registered_Addons[name] = Addon;
		BMS:debug_Print("Registering addon : "..tostring(name));
		for k, v in pairs(Registered_Addons) do
			for k1, v1 in pairs(v) do
				--BMS:debug_Print(k1.." "..tostring(v1))
			end
		end
	end
end


SlashCmdList["BITCHINMAPSYSTEM"] = BitchinMapSystem_SlashHandler;
SLASH_BITCHINMAPSYSTEM1 = "/bms";

--Gets a blank frame either from Pool or creates a new one!
function BMS:GetBlankNoteFrame()
	if(table.getn(FramePool)==0) then
		BMS:CreateBlankFrameNote();
	end
	f = FramePool[1];
	table.remove(FramePool, 1);
	return f;
end


CREATED_NOTE_FRAMES = 1;
--Creates a blank frame for use within the map system
function BMS:CreateBlankFrameNote()
	local f = CreateFrame("Button","MapNotesFrame"..CREATED_NOTE_FRAMES,WorldMapFrame)
	f:SetFrameLevel(FrameLevel);
	f:SetWidth(16*NOTES_MAP_ICON_SCALE)  -- Set These to whatever height/width is needed 
	f:SetHeight(16*NOTES_MAP_ICON_SCALE) -- for your Texture
	local t = f:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\AddOns\\MapNotes\\Icons\\complete")
	t:SetAllPoints(f)
	f.texture = t
	CREATED_NOTE_FRAMES = CREATED_NOTE_FRAMES+1;
	table.insert(FramePool, f);
	table.insert(AllFrames, f);
end

TICK_DELAY = 0.01;--0.1 Atm not to get spam while debugging should probably be a lot faster...
LAST_TICK = GetTime();

UIOpen = false;

NATURAL_REFRESH = 60;
NATRUAL_REFRESH_SPACING = 2;

--Inital pool size (Not tested how much you can do before it lags like shit, from experiance 11 is good)
INIT_POOL_SIZE = 11;
function BMS:NOTES_LOADED()
	BMS:debug_Print("Loading MapNotes");
	if(table.getn(FramePool) < 10) then--For some reason loading gets done several times... added this in as safety
		for i = 1, INIT_POOL_SIZE do
			BMS:CreateBlankFrameNote();
		end
	end
	BMS:debug_Print("Done Loading MapNotes");
end

local lastC, lastZ = GetCurrentMapContinent(), GetCurrentMapZone();
function BMS:Refresh(force)
	local c, z = GetCurrentMapContinent(), GetCurrentMapZone();
	if((c ~= lastC or z ~= lastZ) or force) then
		BMS:CLEAR_ALL_NOTES();
		Polygon:CLEAR_ALL_NOTES();
		for Name, Addon in pairs(Registered_Addons) do
			BMS:DRAW_NOTES(Name, Addon);
		end
		lastC = c;
		lastZ = z;
		if(L_Astrolabe.processingFrame:IsVisible() == nil) then
			L_Astrolabe.processingFrame:Show();
		end
	end
end

--Reason this exists is to be able to call both clearnotes and drawnotes without doing 2 function calls, and to be able to force a redraw
function BMS:RedrawNotes()
	local time = GetTime();
	BMS:CLEAR_ALL_NOTES();
	BMS:DRAW_NOTES();
	BMS:debug_Print("Notes redrawn time:", tostring((GetTime()- time)*1000).."ms");
	time = nil;
end

function BMS:Clear_Note(v)
	v:SetParent(nil);
	v:Hide();
	v:SetAlpha(1);
	v:SetFrameLevel(FrameLevel);
	v:SetHighlightTexture(nil, "ADD");
	v.data = nil;
	table.insert(FramePool, v);
end

local UsedNoteFrames = {};
--Clears the notes, goes through the usednoteframes and clears them. Then sets the QuestieUsedNotesFrame to new table;
function BMS:CLEAR_ALL_NOTES()
	BMS:debug_Print("CLEAR_NOTES");
	L_Astrolabe:RemoveAllMinimapIcons();
	for k, v in pairs(UsedNoteFrames) do
		--BMS:debug_Print("Hash:"..v.questHash,"Type:"..v.type);
		BMS:Clear_Note(v);
	end
	UsedNoteFrames = {};
end


--2 / 12

--Checks first if there are any notes for the current zone, then draws the desired icon
function BMS:DRAW_NOTES(Name, Addon)
	local c, z = GetCurrentMapContinent(), GetCurrentMapZone();
		BMS:debug_Print("DRAWING ADDON: "..Name);
		local data = Addon:GetNodes(c, z);
		if(data == nil) then return; end
		for k, v in pairs(data) do
			if true then
				Icon = BMS:GetBlankNoteFrame();
				--Here more info should be set but i CBA at the time of writing
				Icon.data = v;
				Icon:SetParent(WorldMapFrame);
				Icon:SetPoint("CENTER",0,0)
				Icon.type = "WorldMapNote";
				if(v.Tooltip) then
					Icon:SetScript("OnEnter", v.Tooltip); --Script Toolip
					if(v.TooltipLeave) then
						Icon:SetScript("OnLeave", v.TooltipLeave);
					else
						Icon:SetScript("OnLeave", function() if(WorldMapTooltip) then WorldMapTooltip:Hide() end if(GameTooltip) then GameTooltip:Hide() end end) --Script Exit Tooltip
					end
				end
				if(v.Click) then
					Icon:RegisterForClicks("LeftButtonDown", "RightButtonDown");
					Icon:SetScript("OnClick", function() this.data.Click(arg1,arg2,arg3) end);
				end
				
				if(z == 0 and c == 0) then--Both continents
					Icon:SetWidth(16*NOTES_WORLD_MAP_ICON_SCALE)  -- Set These to whatever height/width is needed 
					Icon:SetHeight(16*NOTES_WORLD_MAP_ICON_SCALE) -- for your Texture
				elseif(z == 0) then--Single continent
					Icon:SetWidth(16*NOTES_CONTINENT_ICON_SCALE)  -- Set These to whatever height/width is needed 
					Icon:SetHeight(16*NOTES_CONTINENT_ICON_SCALE) -- for your Texture
				else
					Icon:SetWidth(16*NOTES_MAP_ICON_SCALE)  -- Set These to whatever height/width is needed 
					Icon:SetHeight(16*NOTES_MAP_ICON_SCALE) -- for your Texture
				end

				--Set the texture to the right type
				Icon.texture:SetTexture(v.icon);
				Icon:SetHighlightTexture(v.icon, "ADD");
				Icon.texture:SetAllPoints(Icon)
				Icon:SetFrameLevel(FrameLevel);

				--Shows and then calls L_Astrolabe to place it on the map.
				Icon:Show();
				
				xx, yy = L_Astrolabe:PlaceIconOnWorldMap(WorldMapButton,Icon,v.continent ,v.zoneid ,v.x, v.y); --WorldMapFrame is global
				if(xx and yy and xx > 0 and xx < 1 and yy > 0 and yy < 1) then
					--Questie:debug_Print(Icon:GetFrameLevel());
					table.insert(UsedNoteFrames, Icon);			
				else
					--Questie:debug_Print("Outside map, reseting icon to pool");
					BMS:Clear_Note(Icon);
				end


				--Lets not draw Minimap notes for zones we are not in.
				if(z == v.zoneid) then
					MMIcon = BMS:GetBlankNoteFrame();
					--Here more info should be set but i CBA at the time of writing
					MMIcon.data = v;
					MMIcon:SetParent(Minimap);
					MMIcon:SetFrameLevel(FrameLevel);
					MMIcon:SetPoint("CENTER",0,0)
					MMIcon:SetWidth(16*NOTES_MINIMAP_ICON_SCALE)  -- Set These to whatever height/width is needed 
					MMIcon:SetHeight(16*NOTES_MINIMAP_ICON_SCALE) -- for your Texture
					MMIcon.type = "MiniMapNote";
					--Sets highlight texture (Nothing stops us from doing this on the worldmap aswell)
					MMIcon:SetHighlightTexture(v.icon, "ADD");
					--Set the texture to the right type
					MMIcon.texture:SetTexture(v.icon);
					MMIcon.texture:SetAllPoints(MMIcon)
					if(v.Tooltip) then
						MMIcon:SetScript("OnEnter", v.Tooltip); --Script Toolip
						if(v.TooltipLeave) then
							MMIcon:SetScript("OnLeave", v.TooltipLeave);
						else
							MMIcon:SetScript("OnLeave", function() if(WorldMapTooltip) then WorldMapTooltip:Hide() end if(GameTooltip) then GameTooltip:Hide() end end) --Script Exit Tooltip
						end
					end
					if(v.Click) then
						MMIcon:RegisterForClicks("LeftButtonDown", "RightButtonDown");
						MMIcon:SetScript("OnClick", function() this.data.Click(arg1,arg2,arg3) end);
					end
					--Shows and then calls L_Astrolabe to place it on the map.
					--MMIcon:Show();
					--Questie:debug_Print(v.continent,v.zoneid,v.x,v.y);
					L_Astrolabe:PlaceIconOnMinimap(MMIcon, v.continent, v.zoneid, v.x, v.y);
					--Questie:debug_Print(MMIcon:GetFrameLevel());
					table.insert(UsedNoteFrames, MMIcon);
				end
			end
		end
end

--Debug print function
function BMS:debug_Print(...)
	local debugWin = 0;
	local name, shown;
	for i=1, NUM_CHAT_WINDOWS do
		name,_,_,_,_,_,shown = GetChatWindowInfo(i);
		if (string.lower(name) == "mndebug") then debugWin = i; break; end
	end
	if (debugWin == 0) then return end

	local out = "";
	for i = 1, arg.n, 1 do
		if (i > 1) then out = out .. ", "; end
		local t = type(arg[i]);
		if (t == "string") then
			out = out .. '"'..arg[i]..'"';
		elseif (t == "number") then
			out = out .. arg[i];
		else
			out = out .. dump(arg[i]);
		end
	end
	getglobal("ChatFrame"..debugWin):AddMessage(out, 1.0, 1.0, 0.3);
end











--Sets the icons
Icons = {
	["complete"] = {
		text = "Complete",
		path = "Interface\\AddOns\\!Questie\\Icons\\complete"
	},
	["available"] = {
		text = "Complete",
		path = "Interface\\AddOns\\!Questie\\Icons\\available"
	},
	["loot"] = {
		text = "Complete",
		path = "Interface\\AddOns\\!Questie\\Icons\\loot"
	},
	["item"] = {
		text = "Complete",
		path = "Interface\\AddOns\\!Questie\\Icons\\loot"
	},
	["event"] = {
		text = "Complete",
		path = "Interface\\AddOns\\!Questie\\Icons\\event"
	},
	["object"] = {
		text = "Complete",
		path = "Interface\\AddOns\\!Questie\\Icons\\object"
	},
	["slay"] = {
		text = "Complete",
		path = "Interface\\AddOns\\!Questie\\Icons\\slay"
	}
}

function BMS:Update()
	BMS:Refresh();
end

function BMS:CloseWorldMap()
	lastC = -1;
	lastZ = -1;
	BMS:Refresh(true);
end

BMS:NOTES_LOADED();
--WorldMapFrame:SetScript("OnUpdate", BMS.Update)


BMS:RegisterEvent("ZONE_CHANGED", BMS.Update)
BMS:ScheduleRepeatingEvent("ZONE_CHANGED", 0.016);
BMS:RegisterEvent("CLOSE_WORLD_MAP", BMS.CloseWorldMap);
L_Astrolabe.processingFrame:Show();