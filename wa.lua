local function GetRioScore(fullname)    
    local score = 0;    
    
    if not RaiderIO then return score end;
    
    if not string.match(fullname, "-") then
        local realmName = string.gsub(GetRealmName(), " ", "");
        fullname = fullname.."-"..realmName;        
    end
    
    local FACTIONS = { Alliance = 1, Horde = 2, Neutral = 3 }
    local playerFactionID = FACTIONS[UnitFactionGroup("player")]    
    local playerProfile = RaiderIO.GetProfile(fullname, playerFactionID);
    local currentScore = 0;
    local previousScore = 0;
    
    if (playerProfile ~= nil) then
        if playerProfile.mythicKeystoneProfile ~= nil then
            currentScore = playerProfile.mythicKeystoneProfile.currentScore or 0;    
            previousScore = playerProfile.mythicKeystoneProfile.previousScore or 0;
        end
    end    
    
    score = currentScore
    
    local previousRIO = _G["ShowRIORaitingWA1PreviousRIO"];
    
    if previousRIO == true and currentScore < previousScore then
        score = previousScore
    end
    
    return score;
end

local function componentToHex(c)
    c = math.floor(c * 255)    
    local hex = string.format("%x", c)    
    if (hex:len() == 1) then
        return "0"..hex;
    end    
    return hex;
end

local function rgbToHex(r, g, b)
    return componentToHex(r)..componentToHex(g)..componentToHex(b);
end

local function getColorStr(hexColor)
    return "|cff"..hexColor.."+|r";
end

local function getRioScoreColorText(rioScore) 
    if not RaiderIO then return nil end;
    
    local r, g, b = RaiderIO.GetScoreColor(rioScore);
    local hex = rgbToHex(r, g, b);    
    return getColorStr(hex);
end

local function getRioScoreText(rioScore)
    local colorText = getRioScoreColorText(rioScore);
    if colorText == nil then return "" end
    
    local rioText = colorText:gsub("+", rioScore);
    
    local textFormat = _G["ShowRIORaitingWA1TextFormatRIO"]
    local trim = _G["ShowRIORaitingWA1Trim"]
    if (textFormat ~= nil and trim ~= nil and trim(textFormat) ~= "") then
        rioText = textFormat:gsub("@rio", rioText)        
    end
    
    return rioText.." ";
end

local function getIndex(values, val)
    local index={};
    
    for k,v in pairs(values) do
        index[v]=k;
    end
    
    return index[val];
end

local function filterTable(t, ids)
    for i, id in ipairs(ids) do
        for j = #t, 1, -1 do
            if ( t[j] == id ) then
                tremove(t, j);
                break;
            end
        end
    end
end

local function addFilteredId(self, id)
    if ( not self.filteredIDs ) then
        self.filteredIDs = { };
    end
    tinsert(self.filteredIDs, id);
end

aura_env.Trim = function(str)
    local match = string.match
    return match(str,'^()%s*$') and '' or match(str,'^%s*(.*%S)')
end

aura_env.UpdateApplicantMember = function(member, appID, memberIdx, ...)     
    if( RaiderIO == nil ) then return; end    
    if( _G["ShowRIORaitingWA1NotShowApplicantRio"] == true ) then return; end
    
    local textName = member.Name:GetText();
    local name, class = C_LFGList.GetApplicantMemberInfo(appID, memberIdx);
    local rioScore = GetRioScore(name);    
    local rioText;    
    if (rioScore > 0) then
        rioText = getRioScoreText(rioScore);
    else
        rioText = "";
    end
    
    if ( memberIdx > 1 ) then
        member.Name:SetText("  "..rioText..textName);
    else
        member.Name:SetText(rioText..textName);
    end
    
    local nameLength = 100;
    if ( relationship ) then
        nameLength = nameLength - 22;
    end
    
    if ( member.Name:GetWidth() > nameLength ) then
        member.Name:SetWidth(nameLength);
    end
end

aura_env.SearchEntryUpdate = function(entry, ...)
    if( not LFGListFrame.SearchPanel:IsShown() ) then return; end
    
    local categoryID = LFGListFrame.SearchPanel.categoryID;
    local resultID = entry.resultID;
    local resultInfo = C_LFGList.GetSearchResultInfo(resultID);
    local leaderName = resultInfo.leaderName;
    entry.rioScore = 0;
    
    if (leaderName ~= nil) then
        entry.rioScore = GetRioScore(leaderName);
    end
    
    for i = 1, 5 do
        local texture = "tex"..i;                
        if (entry.DataDisplay.Enumerate[texture]) then
            entry.DataDisplay.Enumerate[texture]:Hide();
        end                
    end
    
    if (categoryID == 2 and _G["ShowRIORaitingWA1NotShowClasses"] ~= true) then
        local numMembers = resultInfo.numMembers;
        local _, appStatus, pendingStatus, appDuration = C_LFGList.GetApplicationInfo(resultID);
        local isApplication = entry.isApplication;
        
        entry.DataDisplay:SetPoint("RIGHT", entry.DataDisplay:GetParent(), "RIGHT", 0, -5);
        
        local orderIndexes = {};
        
        for i=1, numMembers do                    
            local role, class = C_LFGList.GetSearchResultMemberInfo(resultID, i);
            local orderIndex = getIndex(LFG_LIST_GROUP_DATA_ROLE_ORDER, role);
            table.insert(orderIndexes, {orderIndex, class});
        end
        
        table.sort(orderIndexes, function(a,b)
                return a[1] < b[1]
        end);
        
        local xOffset = -88;
        
        for i = 1, numMembers do
            local class = orderIndexes[i][2];
            local classColor = RAID_CLASS_COLORS[class];
            local r, g, b, a = classColor:GetRGBA();
            local texture = "tex"..i;
            
            if (not entry.DataDisplay.Enumerate[texture]) then
                entry.DataDisplay.Enumerate[texture] = entry.DataDisplay.Enumerate:CreateTexture(nil, "ARTWORK");
                entry.DataDisplay.Enumerate[texture]:SetSize(10, 3);
                entry.DataDisplay.Enumerate[texture]:SetPoint("RIGHT", entry.DataDisplay.Enumerate, "RIGHT", xOffset, 15);
            end
            
            entry.DataDisplay.Enumerate[texture]:Show();                    
            entry.DataDisplay.Enumerate[texture]:SetColorTexture(r, g, b, 0.75);
            
            xOffset = xOffset + 18;                    
        end
    end            
    
    local name = entry.Name:GetText() or "";
    
    local rioText;    
    if (entry.rioScore > 0 and _G["ShowRIORaitingWA1NotShowRio"] ~= true) then
        rioText = getRioScoreText(entry.rioScore);
    else
        rioText = "";
    end
    entry.Name:SetText(rioText..name);
end

aura_env.SortSearchResults = function(results)    
    local sortMethod = _G["ShowRIORaitingWA1SortMethod"] or 1;
    local removeRole = _G["ShowRIORaitingWA1RemoveWithoutRole"] or false;
    local minRio = _G["ShowRIORaitingWA1MinRio"] or -1;
    local maxRio = _G["ShowRIORaitingWA1MaxRio"] or 9999;
    local filterRIO = _G["ShowRIORaitingWA1FilterRIO"] or false;
    local categoryID = LFGListFrame.SearchPanel.categoryID;
    
    local function RemainingSlotsForLocalPlayerRole(lfgSearchResultID)    
        local roleRemainingKeyLookup = {
            ["TANK"] = "TANK_REMAINING",
            ["HEALER"] = "HEALER_REMAINING",
            ["DAMAGER"] = "DAMAGER_REMAINING",
        };
        local roles = C_LFGList.GetSearchResultMemberCounts(lfgSearchResultID);
        local playerRole = GetSpecializationRole(GetSpecialization());
        return roles[roleRemainingKeyLookup[playerRole]];
    end
    
    local function FilterSearchResults(searchResultID)
        local searchResultInfo = C_LFGList.GetSearchResultInfo(searchResultID);
        
        if (searchResultInfo == nil) then
            return;
        end        
        
        local remainingRole = RemainingSlotsForLocalPlayerRole(searchResultID) > 0
        
        if removeRole == true then            
            if (remainingRole == false) then
                addFilteredId(LFGListFrame.SearchPanel, searchResultID);
            end
        end 
        
        local leaderName = searchResultInfo.leaderName;
        local rioScore = 0;
        
        if (leaderName ~= nil) then
            rioScore = GetRioScore(leaderName);
        end 
        
        if (not RaiderIO) then filterRIO = false end
        
        if (filterRIO == true) then            
            if (rioScore < minRio or rioScore > maxRio) then
                addFilteredId(LFGListFrame.SearchPanel, searchResultID);
            end
        end
    end
    
    local function SortSearchResultsCB(searchResultID1, searchResultID2)
        local searchResultInfo1 = C_LFGList.GetSearchResultInfo(searchResultID1);
        local searchResultInfo2 = C_LFGList.GetSearchResultInfo(searchResultID2);
        
        if (searchResultInfo1 == nil) then
            return false;
        end        
        
        if (searchResultInfo2 == nil) then
            return true;
        end    
        
        local remainingRole1 = RemainingSlotsForLocalPlayerRole(searchResultID1) > 0;
        local remainingRole2 = RemainingSlotsForLocalPlayerRole(searchResultID2) > 0;
        
        local leaderName1 = searchResultInfo1.leaderName;
        local leaderName2 = searchResultInfo2.leaderName;
        
        local rioScore1 = 0;
        local rioScore2 = 0;       
        
        if (leaderName1 ~= nil) then
            rioScore1 = GetRioScore(leaderName1);
        end   
        if (leaderName2 ~= nil) then
            rioScore2 = GetRioScore(leaderName2);
        end       
        
        if (remainingRole1 ~= remainingRole2) then
            return remainingRole1;
        end
        
        if (sortMethod == 3) then
            return rioScore1 > rioScore2;
        else
            return rioScore1 < rioScore2;
        end
    end
    
    if (#results > 0 and categoryID == 2) then
        for i,id in ipairs(results) do
            FilterSearchResults(id)
        end
        
        if (LFGListFrame.SearchPanel.filteredIDs) then
            filterTable(LFGListFrame.SearchPanel.results, LFGListFrame.SearchPanel.filteredIDs);
            LFGListFrame.SearchPanel.filteredIDs = nil;
        end
    end
    
    if sortMethod ~= 1 then
        table.sort(results, SortSearchResultsCB);
    end
    
    if #results > 0 then
        LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel);
    end
end

aura_env.SortApplicants = function(applicants)    
    local sortMethod = _G["ShowRIORaitingWA1ApplicantSortMethod"] or 1;
    local minRio = _G["ShowRIORaitingWA1ApplicantMinRio"] or -1;
    local maxRio = _G["ShowRIORaitingWA1ApplicantMaxRio"] or 9999;
    local filterRIO = _G["ShowRIORaitingWA1ApplicantFilterRIO"] or false;
    local categoryID = LFGListFrame.CategorySelection.selectedCategory;
    
    local function FilterApplicants(applicantID)
        local applicantInfo = C_LFGList.GetApplicantInfo(applicantID);
        
        if (applicantInfo == nil) then
            return;
        end 
        
        local name = C_LFGList.GetApplicantMemberInfo(applicantInfo.applicantID, 1);
        local rioScore = 0;
        
        if (name ~= nil) then
            rioScore = GetRioScore(name);
        end   
        
        if (filterRIO == true) then
            if (rioScore < minRio or rioScore > maxRio) then
                addFilteredId(LFGListFrame.ApplicationViewer, applicantID)
            end
        end
    end
    
    local function SortApplicantsCB(applicantID1, applicantID2)
        local applicantInfo1 = C_LFGList.GetApplicantInfo(applicantID1);
        local applicantInfo2 = C_LFGList.GetApplicantInfo(applicantID2);
        
        if (applicantInfo1 == nil) then
            return false;
        end        
        
        if (applicantInfo2 == nil) then
            return true;
        end    
        
        local name1 = C_LFGList.GetApplicantMemberInfo(applicantInfo1.applicantID, 1);
        local name2 = C_LFGList.GetApplicantMemberInfo(applicantInfo2.applicantID, 1);
        
        local rioScore1 = 0;
        local rioScore2 = 0;       
        
        if (name1 ~= nil) then
            rioScore1 = GetRioScore(name1);
        end   
        if (name2 ~= nil) then
            rioScore2 = GetRioScore(name2);
        end
        
        if (sortMethod == 3) then
            return rioScore1 > rioScore2;
        else
            return rioScore1 < rioScore2;
        end
    end
    
    if (categoryID == 2 and #applicants > 0) then
        for i,id in ipairs(applicants) do
            FilterApplicants(id)
        end
        
        if (LFGListFrame.ApplicationViewer.filteredIDs) then
            filterTable(applicants, LFGListFrame.ApplicationViewer.filteredIDs);
            LFGListFrame.ApplicationViewer.filteredIDs = nil;
        end
    end
    
    if (sortMethod ~= 1 and #applicants > 1) then 
        table.sort(applicants, SortApplicantsCB);        
        LFGListApplicationViewer_UpdateResults(LFGListFrame.ApplicationViewer);
    end
    
    if (#applicants > 0) then        
        LFGListApplicationViewer_UpdateResults(LFGListFrame.ApplicationViewer);
    end
end

local isLoad = _G["ShowRIORaitingWA1"];

_G["ShowRIORaitingWA1NotShowRio"] = aura_env.config.NotShowRio
_G["ShowRIORaitingWA1NotShowApplicantRio"] = aura_env.config.NotShowApplicantRio
_G["ShowRIORaitingWA1NotShowClasses"] = aura_env.config.NotShowClasses 
_G["ShowRIORaitingWA1TextFormatRIO"] = aura_env.config.TextFormatRIO;
_G["ShowRIORaitingWA1Trim"] = aura_env.Trim;
_G["ShowRIORaitingWA1SortMethod"] = aura_env.config.RioSort;
_G["ShowRIORaitingWA1ApplicantSortMethod"] = aura_env.config.ApplicantRioSort;
_G["ShowRIORaitingWA1RemoveWithoutRole"] = aura_env.config.RemoveWithoutRole;
_G["ShowRIORaitingWA1MinRio"] = aura_env.config.MinRio;
_G["ShowRIORaitingWA1MaxRio"] = aura_env.config.MaxRio;
_G["ShowRIORaitingWA1ApplicantMinRio"] = aura_env.config.ApplicantMinRio;
_G["ShowRIORaitingWA1ApplicantMaxRio"] = aura_env.config.ApplicantMaxRio;
_G["ShowRIORaitingWA1FilterRIO"] = aura_env.config.FilterRIO;
_G["ShowRIORaitingWA1ApplicantFilterRIO"] = aura_env.config.ApplicantFilterRIO;
_G["ShowRIORaitingWA1PreviousRIO"] = aura_env.config.ShowPreviousRIO;

if (not isLoad) then 
    hooksecurefunc("LFGListUtil_SortSearchResults", aura_env.SortSearchResults);
    hooksecurefunc("LFGListSearchEntry_Update", aura_env.SearchEntryUpdate);
    hooksecurefunc("LFGListUtil_SortApplicants", aura_env.SortApplicants);
    hooksecurefunc("LFGListApplicationViewer_UpdateApplicantMember", aura_env.UpdateApplicantMember);
    _G["ShowRIORaitingWA1"] = true;
end

