--[[
	Name: DataStore_Quests
	Revision: 1
	Developed by: Logon 
	Inspired By: DataStore from retail
	Website: https://github.com/AeroScripts/QuestieDev
	Description: DataStore_Quests is a library that stores current questlog, and seen / completed quests.
]]

-----------------------------------------------------------------------------
--Storing global functions as local speeds up it's use. also fuck you lua why u do dis --PERFORMANCE CHANGE--
-----------------------------------------------------------------------------
local strfind = string.find
local strlen = string.len
local gsub = gsub
local pairs = pairs
local ipairs = ipairs
local type = type
local tinsert = table.insert
local tremove = table.remove
local unpack = unpack
local max = math.max
local floor = floor
local ceil = ceil
local loadstring = loadstring
local tostring = tostring
local setmetatable = setmetatable
local getmetatable = getmetatable
local getn = table.getn
local format = format
local sin = math.sin
local min = math.min;
local byte = string.byte;
-----------------------------------------------------------------------------
--End of globals
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
--WoW Functions --PERFORMANCE CHANGE--
-----------------------------------------------------------------------------
local L_GetQuestLogTitle = GetQuestLogTitle;
local L_GetNumQuestLeaderBoards = GetNumQuestLeaderBoards;
local L_SelectQuestLogEntry = SelectQuestLogEntry;
local L_GetQuestLogLeaderBoard = GetQuestLogLeaderBoard; 
local L_GetAbandonQuestName = GetAbandonQuestName;
local L_GetQuestLogQuestText = GetQuestLogQuestText;
local L_GetTitleText = GetTitleText;
-----------------------------------------------------------------------------
--End of WoW Functions
-----------------------------------------------------------------------------

local DEBUG = nil

--Namespace
DataStore_Quests_API = {};
local DataStore_Quests = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0",  "AceDB-2.0", "AceDebug-2.0", "AceEvent-2.0", "AceHook-2.1");
local name, _ = UnitName("player");
DataStore_Quests:RegisterDB("DB_SeenQuests", name);

if(DB_SeenQuests == nil) then
	DB_SeenQuests = {};
end

local Registered_Addons = {};
local DataStore_CurrentQuestLog = {};


local LastQuestLogEntry = 1;
local Old_QuestLogTitle = {};

--Example how DataStore_CurrentQuestLog Stores its stuff
ExampleTable = 
{
	[0000] = {--ID
		Title = "",
		QuestID = 0000,
		Desc = "",
		Level = 00,
		isComplete = "",
		Watched = 1 or nil,
		RawObjectives = {
			["desc"] = {type="", desc="", done=""},
			["desc"] = {type="", desc="", done=""},
			["desc"] = {type="", desc="", done=""},
		}
	}
}
ExampleTable = nil; --gotta save dat memory

__QuestRewardCompleteButton_OnClick=nil; 
---Saved for my own stuff breaks out questDesc in objectives to better parts.
--local i, j, itemName, numItems, numNeeded = strfind(desc, "(.*):%s*([%d]+)%s*/%s*([%d]+)");

-----------------------------------------------------------------------------
--------------Self explanetory, check above to see layout of the returned table, if it doesn't exist returns nil
-----------------------------------------------------------------------------
function DataStore_Quests_API:GetQuestFromLog(id)
	if(DataStore_CurrentQuestLog[id]) then
		return DataStore_CurrentQuestLog[id];
	else
		return nil;
	end
end

function DataStore_Quests_API:GetQuestByQuestID(QuestID)
	local q =DataStore_CurrentQuestLog[QuestID];
	if(q) then
		return q;
	end
	return nil;
end

function DataStore_Quests_API:OnQuest(QuestID)
	if(DataStore_CurrentQuestLog[QuestID]) then
		return true;
	end
	return nil;
end



-----------------------------------------------------------------------------
--------------Gets what quests are currently tracked in the questlog
-----------------------------------------------------------------------------
function DataStore_Quests_API:GetTrackedQuests()
	local Quest = {};
	for QID, Data in DataStore_CurrentQuestLog do
		if(Data.Watched) then
			Quest[QID] = Data;
		end
	end
	return Quest;
end

-----------------------------------------------------------------------------
--------------Registers your addon for indivudual quest updates
-----------------------------------------------------------------------------
function DataStore_Quests_API:RegisterAddon(name, Addon)
	if(Addon) then
		Registered_Addons[name] = Addon;
		--DataStore_Quests:debug_Print("Registering addon : "..tostring(name));
	end
end

-----------------------------------------------------------------------------
--------------Self explantory, check above to see layout of the returned table
-----------------------------------------------------------------------------
function DataStore_Quests_API:GetAllQuestsInLog()
	return DataStore_CurrentQuestLog;
end

-----------------------------------------------------------------------------
--------------Be very careful with this! Only use if you know what you are doing!
-----------------------------------------------------------------------------
function DataStore_Quests_API:ForceCompleteQuest(QuestID)
	DB_SeenQuests[QuestID] = 1;
end

-----------------------------------------------------------------------------
--------------Self explantory, check above to see layout of the returned table
-----------------------------------------------------------------------------
function DataStore_Quests_API:GetAllCompleteQuestsInLog()
	local CompleteQuests = {}
	for Qid, Data in DataStore_CurrentQuestLog do
		if(Data.isComplete == 1 or getn(Data.RawObjectives)==0) then-- -1 if failed, 1 if complete, nil if inprogress
			table.insert(CompleteQuests, Qid);
		end
	end
	return CompleteQuests;
end

-----------------------------------------------------------------------------
--------------Forces a questlog update, please dont use this unless ABSOLUTELY needed.
-----------------------------------------------------------------------------
function DataStore_Quests_API:ForceUpdateQuestLog()
	DataStore_Quests:RefreshQuestlog();
end

-----------------------------------------------------------------------------
--------------Returns nil if false
-----------------------------------------------------------------------------
function DataStore_Quests_API:isQuestCompleted(id)
	--If we pass 0 it always returns 1 this is so we can use it more easily in questie
	if(id == 0) then return 1; end;
	if(DB_SeenQuests[id] and DB_SeenQuests[id] == 1) then
		return DB_SeenQuests[id];
	else
		return nil;
	end
end


function DataStore_Quests:Event(event,arg1,arg2,arg3)

end

function DataStore_Quests:Refresh(QuestID)
	for Name, Addon in pairs(Registered_Addons) do
		Addon:QuestUpdateEvent(QuestID);
	end
end


--Abandon quest hook, used to know when a quest is abandoned.
local PrevAbandonFunc = StaticPopupDialogs["ABANDON_QUEST"].OnAccept;
function DataStore_Quests:AbandonQuestHook()
	--Todo Stuff!
	local qName = L_GetAbandonQuestName();
	local QuestID = DataStore_Quests:getQuestId(qName);
	if(QuestID) then
		DB_SeenQuests[QuestID] = -1;
	else
		DEFAULT_CHAT_FRAME:AddMessage("DataStore_Quests:AbandonQuestHook() ERROR - '"..qName.. "' ID NOT FOUND!")
	end
	if(DEBUG) then
		DEFAULT_CHAT_FRAME:AddMessage("Abandoned '"..qName.."':"..QuestID.. " DBValue: "..DB_SeenQuests[QuestID]);
	end
	DataStore_Quests:SuppressFor(2);
	DataStore_CurrentQuestLog[QuestID] = nil;
	PrevAbandonFunc(); --Should not be needed with ACE 2.0 hook
end

--Complete quest hook, used to know when a quest is Completed.
local PrevCompleteFunc = QuestRewardCompleteButton_OnClick;
function DataStore_Quests:CompleteQuestHook()
	--Todo Stuff!
	if not ( QuestFrameRewardPanel.itemChoice == 0 and GetNumQuestChoices() > 0 ) then
		--DEFAULT_CHAT_FRAME:AddMessage("Completed quest");
		local qName = L_GetTitleText();
		local QuestID = DataStore_Quests:getQuestId(qName);
		if(QuestID == nil) then
			DEFAULT_CHAT_FRAME:AddMessage("DataStore_Quests: Did you try to complete this quest with full inventory?... The small lag was because i had to check your Quest Log again, no worries!")
			DataStore_Quests:InitialQuestLogPop()
			
			--[[local count = 0;
			local retval = 0;
			local bestDistance = 4294967295; -- some high number (0xFFFFFFFF)

			for k,v in pairs(DB_QuestLookup) do
				if k == qName then
					retval = k; -- exact match
					break;
				end	
				
				local dist = DataStore_Quests:levenshtein(qName, k);
				if dist < bestDistance then
					bestDistance = dist;
					retval = k;
				end
				count = count + 1;
			end
			if not (retval == 0) then
				qName = retval; -- nearest match
			end]]--

			for k, v in pairs(DataStore_CurrentQuestLog) do
				if(v.Title == qName) then
					QuestID = v.QuestID;
					break;
				end
			end
			
		end
		if(QuestID == nil) then
			QuestID = DataStore_Quests:getQuestId(qName);
		end
		if(QuestID) then
			DB_SeenQuests[QuestID] = 1;
			DataStore_Quests:SuppressFor(2);
			DataStore_CurrentQuestLog[QuestID] = nil;
			if(DEBUG) then
				DEFAULT_CHAT_FRAME:AddMessage("Completed '"..tostring(qName).."':"..tostring(QuestID).. " DBValue: "..tostring(DB_SeenQuests[QuestID]));
			end
		else

			DEFAULT_CHAT_FRAME:AddMessage("DataStore_Quests:CompleteQuestHook() ERROR - '"..qName.. "' ID NOT FOUND!")
		end
	end
	PrevCompleteFunc(); --Should not be needed with ACE 2.0 hook
end

function DataStore_Quests:RecursiveQuestCheck(qID)
	local NextQid = qID;
	while(true) do
		local Quest = DB_Quests[NextQid];
		if(Quest) then --Added nil
			if(Quest.reqQuest ~= 0) then
				DB_SeenQuests[Quest.reqQuest] = 1;
				if(DB_Quests[Quest.reqQuest]) then-- Added nil check
					NextQid = DB_Quests[Quest.reqQuest].ID;
				else
					DEFAULT_CHAT_FRAME:AddMessage("Questie ALPHA: Quest with ID: REQ: "..Quest.reqQuest.." does not exist, please report on the Forums or our Github!");
					break;
				end
			else
				break;
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("Questie ALPHA: Quest with ID: NEXT: "..NextQid.." does not exist, please report on the Forums or our Github!");
			break;
		end
	end
end

function DumpQlog()
	for k, v in DataStore_CurrentQuestLog do
		local color = GetDifficultyColor(v.Level);
		DEFAULT_CHAT_FRAME:AddMessage(k..":"..v.Title.." isComplete: "..tostring(v.isComplete).." IsWatched: "..tostring(v.Watched), color.r,color.g,color.b);
		for k, v in pairs(v.RawObjectives) do
			DEFAULT_CHAT_FRAME:AddMessage("--> "..k..":"..v.desc.." : "..v.type, 0,1,1);
		end
	end
end

local SuppressCount = 0;
function DataStore_Quests:SuppressFor(count)
	--DEFAULT_CHAT_FRAME:AddMessage("Fuck you");
	SuppressCount = SuppressCount + count;
end
function DataStore_Quests:RefreshQuestlog(remove)
	L_SelectQuestLogEntry(LastQuestLogEntry);
	if(SuppressCount > 0) then
		SuppressCount = SuppressCount -1;
		if(DEBUG) then
			DEFAULT_CHAT_FRAME:AddMessage("Suppressed");
		end
		return;
	end
	--TODO Check if moving local qid up here will save performance.
	--Stores functions that are used a lot. --PERFORMANCE CHANGE--
	--local L_lookupQuestId = DataStore_Quests.lookupQuestId;

	--PERFORMANCE CHANGE-- a var that is reused loads of times.
	local continue = true;

	local numEntries, numQuests = GetNumQuestLogEntries();
	for i = 1, numEntries do
		local q, level, questTag, isHeader, isCollapsed, isComplete = L_GetQuestLogTitle(i);
		continue = true;
		if not isHeader then
			for k, v in DataStore_CurrentQuestLog do
				if(v.Title == q) then 
					--PERFORMANCE CHANGE-- This is also a required change, would have bugged questprogression.
					--TODO Update the QObjectives only.
					L_SelectQuestLogEntry(i);
					local count =  L_GetNumQuestLeaderBoards();
					for obj = 1, count do			
						local desc, _, done = L_GetQuestLogLeaderBoard(obj);
						--Todo: Remove this when testing is done... its ugly

						if(DEBUG) then
							if(v.RawObjectives[obj].desc ~= desc) then
								DEFAULT_CHAT_FRAME:AddMessage("Updated "..v.QuestID.." Desc changed to "..desc);

							end	
						end
						if(isComplete ~= v.isComplete or v.RawObjectives[obj].desc ~= desc) then
							DataStore_Quests:Refresh(v.QuestID);
							--DEFAULT_CHAT_FRAME:AddMessage("Change");
						end	
						v.Watched = IsQuestWatched(i);
						v.isComplete = isComplete;
						v.RawObjectives[obj].desc = desc;
						v.RawObjectives[obj].isDone = done;
					end
					continue=nil; 
					break; 
				end
			end

			--Not found adding it to the currentquest table
			if continue then
				--PERFORMANCE CHANGE-- Setting the lenght by doing a pre init of all values saves time when assigning the values. TODO: Check if this is acually faster.
				--PERFORMANCE CHANGE-- Building the table here makes it always the same size which speeds up table use below.
				local Entry = {Title=nil, QuestID=nil, Desc=nil, Level=nil,isComplete=nil,RawObjectives={}};
				L_SelectQuestLogEntry(i);
				local count =  L_GetNumQuestLeaderBoards();
				--DEFAULT_CHAT_FRAME:AddMessage(q);
				local questText, objectiveText = L_GetQuestLogQuestText();
				--DEFAULT_CHAT_FRAME:AddMessage(questText);
				Entry.Title = q;
				--PERFORMANCE CHANGE-- Keeping the qid in a local var instead of the table because its used in a few places.
				local qid = DataStore_Quests:lookupQuestId(q, questText);
				Entry.QuestID = qid;
				Entry.Desc = questText; --TODO Check if its ObjectiveText or questText that is used! (Think its objectivetext)
				Entry.Level = level;
				Entry.isComplete = isComplete;
				Entry.RawObjectives = {};
				for obj = 1, count do			
					--PERFORMANCE CHANGE-- Setting the lenght by doing a pre init of all values saves time when assigning the values. TODO: Check if this is acually faster.
					--PERFORMANCE CHANGE-- Building the table here makes it always the same size which speeds up table use below.
					local Objective = {type=nil, desc=nil, done=nil}
					local desc, typ, done = L_GetQuestLogLeaderBoard(obj);
					Objective.type = typ;
					Objective.desc = desc;
					Objective.isDone = done;
					Entry.RawObjectives[obj] = Objective;
				end
				if(DB_SeenQuests[qid] == nil) then DB_SeenQuests[qid] = 0; end
				DataStore_CurrentQuestLog[qid] = Entry;
				DataStore_Quests:RecursiveQuestCheck(qid);
				if(DEBUG) then
					DEFAULT_CHAT_FRAME:AddMessage("Added '"..Entry.Title.."':"..qid.." to the QuestLog DB");
				end
			end
		end
	end
	--DEFAULT_CHAT_FRAME:AddMessage("DataStore_Quests:RefreshQuestlog(): Qlog Refreshed");

	L_SelectQuestLogEntry(LastQuestLogEntry);
end

--50 is a good number
function DumpProf(ittr)
	local itt = tonumber(ittr);
	--local StartTime = time();
	--local func = DataStore_Quests.InitialQuestLogPop;
	--for i = 0,itt do
	--	func();
	--end
	--DEFAULT_CHAT_FRAME:AddMessage("DataStore_Quests:InitialQuestLogPop : "..itt.." itterations : "..time()-StartTime.."s Per: "..(((time()-StartTime)/itt)*1000).."ms");

	local StartTime = time();
	local func = DataStore_Quests.RefreshQuestlog;
	for i = 0,itt do
		func();
	end
	DEFAULT_CHAT_FRAME:AddMessage("DataStore_Quests:RefreshQuestlog : "..itt.." itterations : Total:"..time()-StartTime.."s Per: "..(((time()-StartTime)/itt)*1000).."ms");


	--Manual QuestID input required, if you wanna test this, run /script DumpQlog() and pick a QID you have and insert it below
	--[[StartTime = time();
	func = DataStore_Quests:getQuestId;
	local qName = DataStore_CurrentQuestLog[QID].Title;
	for i = 0,10000 do
		func(qName);
	end
	DEFAULT_CHAT_FRAME:AddMessage("DataStore_Quests:getQuestId : 10000 itterations : "..time()-StartTime.."s")]]--
end



local FirstRun = "tt";
function DataStore_Quests:QuestLogEvents(event, arg1,arg2,arg3,arg4)
	--Todo update logic
	--Force a initial refresh of the current questlog
	DataStore_Quests:RefreshQuestlog();
	if(FirstRun) then
		--DataStore_Quests:InitialQuestLogPop()
		DataStore_Quests:RefreshQuestlog();
		FirstRun = nil;

		if(IsAddOnLoaded("EQL3")) then
			for i = 1, 20 do
				Old_QuestLogTitle[i] = getglobal("EQL3_QuestLogTitle"..i):GetScript("OnClick");
				DataStore_Quests:HookScript(getglobal("EQL3_QuestLogTitle"..i),"OnClick", DataStore_Quests.TrackHook);
			end
		else
			for i = 1, 20 do
				if(getglobal("QuestLogTitle"..i)) then
					Old_QuestLogTitle[i] = getglobal("QuestLogTitle"..i):GetScript("OnClick")--QuestRewardCompleteButton_OnClick
					DataStore_Quests:HookScript(getglobal("QuestLogTitle"..i),"OnClick", DataStore_Quests.TrackHook);
					--DEFAULT_CHAT_FRAME:AddMessage(tostring(getglobal("QuestLogTitle"..i):GetScript("OnClick")).." "..tostring(Old_QuestLogTitle[i]));
				end
			end
		end
	
	end
end

function DataStore_Quests:TrackHook()
	local ID;
	if(IsAddOnLoaded("EQL3")) then
		ID = gsub(this:GetName(), "EQL3_QuestLogTitle","")
	else
		ID = gsub(this:GetName(), "QuestLogTitle", "");
	end
	ID = tonumber(ID);
	local set;
	--DEFAULT_CHAT_FRAME:AddMessage(ID);

	--Todo Take over EQL code stops this!
	local f = Old_QuestLogTitle[ID];
	if(f) then
		f();
	end
	L_SelectQuestLogEntry(ID);
	LastQuestLogEntry = ID;
end

function DataStore_Quests:OtherEvents(event)

end

function DataStore_Quests:OnInitialize()
	--Debug level for printing
	DataStore_Quests:SetDebugLevel(3);

	--Event Registers
	DataStore_Quests:RegisterEvent("QUEST_LOG_UPDATE", "QuestLogEvents");
	DataStore_Quests:RegisterEvent("QUEST_ITEM_UPDATE", "QuestLogEvents"); 
	DataStore_Quests:RegisterEvent("UNIT_QUEST_LOG_CHANGED", "QuestLogEvents"); 

	DataStore_Quests:RegisterEvent("OwnEvent", "QuestLogEvents");

	DataStore_Quests:ScheduleRepeatingEvent("OwnEvent", 2);

	DataStore_Quests:RegisterEvent("ZONE_CHANGED", "OtherEvents"); -- this actually is needed 
	DataStore_Quests:RegisterEvent("UI_INFO_MESSAGE", "OtherEvents"); 
	DataStore_Quests:RegisterEvent("CHAT_MSG_SYSTEM", "OtherEvents"); 
	DataStore_Quests:RegisterEvent("CHAT_MSG_SYSTEM", "OtherEvents"); 


	--Probably unneeded TODO
	--[[__QuestRewardCompleteButton_OnClick = QuestRewardCompleteButton_OnClick;
	__QuestAbandonOnAccept = StaticPopupDialogs["ABANDON_QUEST"].OnAccept;

	StaticPopupDialogs["ABANDON_QUEST"].OnAccept = function()
		--local hash = Questie:GetHashFromName(GetAbandonQuestName());
		--QuestieSeenQuests[hash] = nil;
		--Questie:AddEvent("CHECKLOG", 0.135);
		__QuestAbandonOnAccept();
	end]]--


	--Hooks
	--Hooks the SetAbandonQuests which fires when the abandonquest button is pressed
	PrevAbandonFunc = StaticPopupDialogs["ABANDON_QUEST"].OnAccept;
	StaticPopupDialogs["ABANDON_QUEST"].OnAccept = DataStore_Quests.AbandonQuestHook;
	--SetAbandonQuest = DataStore_Quests:AbandonQuestHook;
	--Hooks the CompleteQusetButton which fires when a quest is completed
	DataStore_Quests:Hook("QuestRewardCompleteButton_OnClick", "CompleteQuestHook" ); --TODO Does this work?

	--QuestRewardCompleteButton_OnClick = DataStore_Quests:CompleteQuestHook;
end




function DataStore_Quests:InitialQuestLogPop()
	DataStore_CurrentQuestLog = {};

	--Stores functions that are used a lot. --PERFORMANCE CHANGE--
	--local L_lookupQuestId = DataStore_Quests.lookupQuestId;

	local numEntries, numQuests = GetNumQuestLogEntries();
	for i = 1, numEntries do
		local q, level, questTag, isHeader, isCollapsed, isComplete = L_GetQuestLogTitle(i);

		if not isHeader then
			local Entry = {};
			L_SelectQuestLogEntry(i);
			local count =  L_GetNumQuestLeaderBoards();
			local questText, objectiveText = GetQuestLogQuestText();
			Entry.Title = q;
			Entry.QuestID =  DataStore_Quests:lookupQuestId(q, questText);
			Entry.Desc = questText; --TODO Check if its ObjectiveText or questText that is used! (Think its objectivetext)
			Entry.Level = level;
			Entry.isComplete = isComplete;
			Entry.RawObjectives = {};
			for obj = 1, count do				
				local Objective = {};
				local desc, typ, done = L_GetQuestLogLeaderBoard(obj);
				Objective.type = typ;
				Objective.desc = desc;
				Objective.isDone = done;
				Entry.RawObjectives[obj] = Objective;
			end
			if(DB_SeenQuests[Entry.QuestID] == nil) then DB_SeenQuests[Entry.QuestID] = 0; end
			DataStore_CurrentQuestLog[Entry.QuestID] = Entry;
			--DEFAULT_CHAT_FRAME:AddMessage("Added '"..Entry.Title.."':"..Entry.QuestID.." to the QuestLog DB");
		end
	end
	--DEFAULT_CHAT_FRAME:AddMessage("DataStore_Quests:RefreshQuestlog(): Qlog Refreshed");
end

function DataStore_Quests:getQuestId(qName)
	if(DataStore_CurrentQuestLog) then
		--Assigning the tables and length to local vars should be faster than doing the itteration over a table
		--due to it being continous integers.  --PERFORMANCE CHANGE--
		local table = DataStore_CurrentQuestLog;
		for k, v in table do
			if(v.Title == qName) then
				return v.QuestID;
			end
		end
	end
	return nil;
end

local PlayerName, _ = UnitName("player");
local localizedClass, englishClass, classIndex = UnitClass("player");
local race, raceEn = UnitRace("player");

function DataStore_Quests:lookupQuestId(name, questText)

	--DEFAULT_CHAT_FRAME:AddMessage(name..questText);
	local questLookup = DB_QuestLookup[name];
	local count = 0;
	local retval = 0;
	local bestDistance = 4294967295; -- some high number (0xFFFFFFFF)

	--Storing function saves speed due to how lua does global lookup --PERFORMANCE CHANGE--
	--local levenshtein = DataStore_Quests.levenshtein;

	--DEFAULT_CHAT_FRAME:AddMessage(tostring(questLookup));

	for k,v in pairs(questLookup) do
		if k == questText then
			return v; -- exact match
		end	
		--Replace $N with playername, $c with playerclass and $R with player race, this is to make levenshtein better att finding the right quest.
		--[[local qtext = gsub(k,"$N",PlayerName)
		qtext = gsub(qtext,"$n",PlayerName)
		qtext = gsub(qtext,"$R", race)
		qtext = gsub(qtext,"$r", race)
		qtext = gsub(qtext, "$C", localizedClass);
		qtext = gsub(qtext, "$c", localizedClass);
		qtext = gsub(qtext, "$G (.-):(.-);", (gender==2 and "%1" or "%2")); --Todo Does this work?
		qtext = gsub(qtext, "$g (.-):(.-);", (gender==2 and "%1" or "%2")); --Todo Does this work?]]--
		--Swap $g lad : lady to just the singular gender of the player character.
		--if (gender == 2) then
		--	qtext = gsub(qtext, "$g (.-):(.-)", (gender==2 and "%1" or "%2"));
		--else
		--	qtext = gsub(qtext, "$g (.-):(.-)", "%2");
		--end
		local dist = DataStore_Quests:levenshtein(questText, k);
		if dist < bestDistance then
			bestDistance = dist;
			retval = v;
		end
		count = count + 1;
	end
	if not (retval == 0) then
		return retval; -- nearest match
	end
	
	-- hash lookup did not contain qust name!! LOG THIS!!!
	DEFAULT_CHAT_FRAME:AddMessage("DataStore_Quests:lookupQuestId() ERROR - '"..name.. "' NOT FOUND IN LOOKUP!")
	return nil;
end

-- Returns the Levenshtein distance between the two given strings
-- credit to https://gist.github.com/Badgerati/3261142
function DataStore_Quests:levenshtein(str1, str2)
	local len1 = strlen(str1)
	local len2 = strlen(str2)
	local matrix = {}
	local cost = 0
        -- quick cut-offs to save time
	if (len1 == 0) then
		return len2
	elseif (len2 == 0) then
		return len1
	elseif (str1 == str2) then
		return 0
	end
        -- initialise the base matrix values
	for i = 0, len1, 1 do
		matrix[i] = {}
		matrix[i][0] = i
	end
	for j = 0, len2, 1 do
		matrix[0][j] = j
	end
    -- actual Levenshtein algorithm
	for i = 1, len1, 1 do
		for j = 1, len2, 1 do
			if (byte(str1,i) == byte(str2,j)) then
				cost = 0
			else
				cost = 1
			end
			matrix[i][j] = min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
		end
	end
        -- return the last value - this is the Levenshtein distance
	return matrix[len1][len2]
end
