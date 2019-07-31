local thorns = require("thornsgui")

local ENABLE_DISPLAY_NAME_CACHE = true --disable to enter the stone age (or if you RAM < 100K and you CPU-FQ > 100G)
local CONFIG_PATH = "/etc/item-control/"
local EXPORT_CONFIG_FILE = "export_rules"
local LOOP_RUN_UNTIL_YIELD = 10 -- prevents too long without yielding errors
--table utils
function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end
function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end
function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end
--table utils end
local int = componet["me-interface"] -- todo
local items
local function getAllItems()
    return int.getAvailableItems()
end
local function boolToString(b)
    if b then return "true" 
    else return "false" end
end
local function getItemDetail(fingerprint)
    --if fingerprint== nil then error ("fingerprint expected (got nil)") end
    local itd = int.getItemDetail(fingerprint)
    --if (itd == nil) then error("couldn't get itemdetails of " .. fingerprint.id..":"..fingerprint.dmg.."\nDump:\n"..table.tostring(fingerprint)) end
    return itd
end
local function getItemName(fingerprint)
    if(fingerprint == nil ) then error ("fingerprint expected (got nil)") end
    if(fingerprint.display_name ~= nil) then return fingerprint.display_name end
    local itd = getItemDetail(fingerprint)
    if(itd==nil) then return fingerprint.id end
    local name = itd.basic().display_name
    if ENABLE_DISPLAY_NAME_CACHE then fingerprint.display_name = name end
    return name
end
local function getItemMod(fingerprint)
    local itd = getItemDetail(fingerprint)
    if itd == nil then return "<err_mod_mis>" end
    return itd.basic().mod_id
end
local function isStoredItem(item)
    if item.is_fluid then return false end
    if item.is_craftable then return false end
    if item.size <= 0 then return false end
    return item.is_item
end
local function str_splitChar(str,c)
    local s = {}
    local last = 1
    for i=1,string.len(str) do
        if(string.byte(str,i)==string.byte(c)) then
            table.insert(s,string.sub(str,last,i-1))
            last = i+1
        end
    end
    table.insert(s,string.sub(str,last))
    return s
end
local function sortItems(compf,rev) --bubblesort with compf(function) comparefunction to sort items and optional rev(bool) to sort reverse --TODO replace with table native sort
    rev = not not rev -- make false if nil
    local changed
	local loopRuns = 0
    repeat
        changed = false
		loopRuns = loopRuns + 1
        for i=1,#items-1 do
            local b = compf(items[i],items[i+1])
            if rev then b = not b end
            if ( b ) then
                changed = true
                local t = items[i]
                items[i] = items[i+1]
                items[i+1] = t
            end
        end
		if loopRuns == LOOP_RUN_UNTIL_YIELD then 
			os.sleep(0)
			loopRuns = 0 
		end
    until (not changed)
end

local function saveExportConfig()
    f = io.open(CONFIG_PATH .. EXPORT_CONFIG_FILE,"w")
    for i=1,#items do 
        if items[i].fingerprint.export ~= nil then
            local iname = ""
            if items[i].fingerprint.display_name ~= nil then iname = items[i].fingerprint.display_name end 
            f.writeLine(items[i].fingerprint.id..","..items[i].fingerprint.dmg..","..items[i].fingerprint.export..","..iname)
            f.flush()
        end
    end
    f.close()
end

local function loadExportConfig()
    if not fs.exists(CONFIG_PATH .. EXPORT_CONFIG_FILE) then
        return -- nothing to load
    end
    f = fs.open(CONFIG_PATH .. EXPORT_CONFIG_FILE,"r")
    local line = f.readLine()
    while(line ~= nil) do
        local p = str_splitChar(line,",")
        local found = false
        for i =1,#items do
            if( items[i].fingerprint.id==p[1] and items[i].fingerprint.dmg == tonumber(p[2])) then
                found = true
                items[i].fingerprint.export = p[3]
                if (p[4]~="" and p[4]~=nil) then 
                    items[i].fingerprint.display_name = p[4]
                end
            end
        end
        if (not found) then 
            local e = {}
            e.size = 0
            e.is_item = true
            e.is_fluid = false
            e.is_craftable = false
            e.fingerprint = {}
            e.fingerprint.id = p[1]
            e.fingerprint.dmg = tonumber(p[2])
            e.fingerprint.export = p[3]
            if (p[4]~="" and p[4]~=nil) then 
                    e.fingerprint.display_name = p[4]
                end
            table.insert(items,e)
        end
        line = f.readLine()
    end
    
    f.close()
end
local function runExportRules()
    for i = 1,#items do
        local am = 1
        while(items[i].fingerprint.export ~= nil and items[i].fingerprint.export ~= "<none>" and items[i].size > 0 and am > 0) do
            am = int.exportItem(items[i].fingerprint,items[i].fingerprint.export).size
            items[i].size = items[i].size - am 
        end
    end
    drawHolePage()
end

items = getAllItems()
loadExportConfig()
--local term_c = term.current()
--mainWindow = window.create(term_c, 1, 1, thornsgui.outDim.x, thornsgui.outDim.y, true)

local function printPage(page)
    local phTxt = thornsgui.Text:create(thornsgui.outDim.x/2 - 2,1,"Page " .. (page+1))
    phTxt:draw()
    local itemTbl = thornsgui.Table:create(3,thornsgui.outDim.y-2,1,3)
    local nameHBtn = thornsgui.Button:create(1,1,6,1,"Name")
    local amountHBtn = thornsgui.Button:create(1,1,6,1,"Amount")
    local compf_name = function(i1,i2) 
        local n1 = getItemName(i1.fingerprint)
        local n2 = getItemName(i2.fingerprint)
        for i = 1,math.min(string.len(n1),string.len(n2)) do 
            if( string.byte(n1,i) > string.byte(n2,i) ) then return true end
            if( string.byte(n1,i) < string.byte(n2,i) ) then return false end
        end
        return false
    end
    local compf_amount = function(i1,i2) 
        return ( i1.size < i2.size )
    end
    nameHBtn.onClick = function() sortItems(compf_name) drawHolePage() end
    amountHBtn.onClick = function() sortItems(compf_amount) drawHolePage() end
    --nameHBtn.registerEventListener()
    --amountHBtn.registerEventListener()
    itemTbl:setElement(1,1,nameHBtn)
    itemTbl:setElement(2,1,amountHBtn)
    for i=0,thornsgui.outDim.y-4 do
        local ind = i+1+(thornsgui.outDim.y-3) * page
        if ind > 0 and ind <= #items then
            local nameTxt = thornsgui.Text:create(1,1,getItemName(items[ind].fingerprint))
            local amTxt = thornsgui.Text:create(1,1," x"..items[ind].size)
            local detailBtn = thornsgui.Button:create(1,1,7,1,"Details")
            local f_d = function()
                -- TODO
                --local detailWin = window.create(term_c,3,2,thornsgui.outDim.x-4,thornsgui.outDim.y-2,true)
                --detailWin.setBackgroundColor(colors.lightGray)
                --detailWin.clear()
                --thornsgui.setOutput(detailWin)
                --local detail_table = thornsgui.createTable(2,5,3,3)
                --local detail_nameTxtLbl  =  thornsgui.createText(1,1,"Name:")
                --local detail_nameTxt = thornsgui.createText(1,1,getItemName(items[ind].fingerprint))
                --local detail_amountTxtLbl = thornsgui.createText(1,1,"Amount:")
                --local detail_amountTxt = thornsgui.createText(1,1,items[ind].size)
                --local detail_modTxtLbl = thornsgui.createText(1,1,"Mod:")
                --local detail_modTxt = thornsgui.createText(1,1,getItemMod(items[ind].fingerprint))
                --local detail_craftTxtLbl = thornsgui.createText(1,1,"Craftable:")
                --local detail_craftItem
                --if (items[ind].is_craftable) then
                --    detail_craftItem = thornsgui.createButton(1,1,5,1,"Craft")
                --    detail_craftItem.setOnClick(function()
                --        int.requestCrafting(items[ind].fingerprint,1)
                --    end)
                --    detail_craftItem.registerEventListener()
                --    detail_craftItem.setColors(colors.white,colors.gray)
                --else
                --    detail_craftItem = thornsgui.createText(1,1,boolToString(items[ind].is_craftable))
                --end
                --local detail_idTxtLbl = thornsgui.createText(1,1,"Id:")
                --local detail_idTxt = thornsgui.createText(1,1,items[ind].fingerprint.id)
                --local detail_dropDSel = thornsgui.createDropdownSelector(3,8) 
                --[[detail_dropDSel.addOption("<none>")
                detail_dropDSel.addOption("north")
                detail_dropDSel.addOption("south")
                detail_dropDSel.addOption("east")
                detail_dropDSel.addOption("west")
                detail_dropDSel.addOption("up")
                detail_dropDSel.addOption("down")
                detail_dropDSel.setOnChange(function(sel,text) 
                    items[ind].fingerprint.export = text
                end)
                if ( items[ind].fingerprint.export ~= nil) then detail_dropDSel.setSelected(items[ind].fingerprint.export) end
                detail_table.setElement(1,1,detail_nameTxtLbl)
                detail_table.setElement(2,1,detail_nameTxt)
                detail_table.setElement(1,2,detail_amountTxtLbl)
                detail_table.setElement(2,2,detail_amountTxt)
                detail_table.setElement(1,3,detail_modTxtLbl)
                detail_table.setElement(2,3,detail_modTxt)
                detail_table.setElement(1,4,detail_craftTxtLbl)
                detail_table.setElement(2,4,detail_craftItem)
                detail_table.setElement(1,5,detail_idTxtLbl)
                detail_table.setElement(2,5,detail_idTxt)
                detail_table.setColors(colors.black,colors.lightGray,"text")
                local closeBtn = thornsgui.createButton(thornsgui.outDim.x-1,1,2,1," X")
                closeBtn.setColors(colors.white,colors.red)
                local closeDWFunc = function()
                    detailWin.setVisible(false)
                    thornsgui.setOutput(mainWindow)
                    mainWindow.redraw()
                end ]]--
                --closeBtn.setOnClick(closeDWFunc)
                --detail_dropDSel.draw()
                --detail_table.draw()
                --closeBtn.draw()
                --
                --closeBtn.registerEventListener()
            end
            detailBtn.onClick = f_d
            --detailBtn.registerEventListener()
            itemTbl:setElement(1,i+2,nameTxt)
            itemTbl:setElement(2,i+2,amTxt)
            itemTbl:setElement(3,i+2,detailBtn)
        end
    end
    itemTbl:draw()
end
page = 0
--thornsgui.setOutput(mainWindow)
--mainWindow.clear()
pb = thornsgui:createButton(1,1,6,1,"  <-  ")
nb = thornsgui:createButton(thornsgui.outDim.x-7,1,6,1,"  ->  ")
cb = thornsgui:createButton(thornsgui.outDim.x-1,1,2,1," X")
exb = thornsgui:createButton(7,1,6,1,"Export")
stbx = thornsgui:createTextBox(1,2,10,1)
-- todo cb.setColors(colors.white,colors.red)
-- todo exb.setColors(colors.white,colors.lightGray)
function drawHolePage()
    --mainWindow.setBackgroundColor(colors.white)
    --mainWindow.clear()
    thornsgui.clearClickListeners()
    pb:draw()
    nb:draw()
    cb:draw()
    exb:draw()
    printPage(page)
    pb.registerEventListener()
    nb.registerEventListener()
    cb.registerEventListener()
    exb.registerEventListener()
end
local stop = false
local p = function() 
    page = page - 1 
    if(page < 0 ) then page = 0 end
    drawHolePage()
end
local n = function() 
    page = page + 1
    drawHolePage()
end
local close = function()
    saveExportConfig()
    stop = true
end
pb.setOnClick(p)
nb.setOnClick(n)
cb.setOnClick(close)
exb.setOnClick(runExportRules)
drawHolePage()
while not stop do
    thornsgui.handleNextEvent()
    os.sleep(0.05)
    --term.setCursorPos(1,1)
    --term.write(os.time())
end
term.clear()
term.setCursorPos(1,1)