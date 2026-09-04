
-- @description Translates RGB and Hex and SWS color codes
-- @author nightsharks
-- @version 1.0
-- @about
-- Function to convert a hex color code to RGB values and SWS values because SWS color codes are fucked
if not reaper.ImGui_GetBuiltinPath then
    return reaper.MB('ReaImGui is not installed or too old.', 'My script', 0)
end 

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9.2'
local font = ImGui.CreateFont('sans-serif', 13)
local ctx = ImGui.CreateContext('My script')

-- Attach font to context
ImGui.Attach(ctx, font)

  userInputHex = ""
  userInputSWS = ""
  userInputR = "0"
  userInputG= "0"
  userInputB= "0"

 intSWS = 0
 intR = 0
 intG = 0
 intB = 0

 strHex = ""

local retval = false

local transformButtonClick = 0
local items = {"Hex Values", "RGB Values", "SWS Value"}
local resultText = ""
local resultInt = 0
local widgets = {
    combos = {
        current_item1 = 1,  -- Initialize with a default value
        current_item2 = 1  -- Initialize with a default value
    }
}

HexCodes = {}
---------------------------------------
---READING USER INPUTS---
---------------------------------------
    -- Read in user hex input --
function HexInput()
    ImGui.SetNextItemWidth(ctx, 100)
    retval, userInputHex = ImGui.InputText(ctx, 'Current Hex Code', userInputHex, ImGui.InputTextFlags_CharsHexadecimal) 
    strHex = CheckIfStringNil(userInputHex)
    print(userInputHex)
end
    -- Read in user RGB input --
function RGBInput()

    ImGui.Text(ctx, "Current RGB Code")
    ImGui.SetNextItemWidth(ctx, 75)
    retval, userInputR = ImGui.InputText(ctx, 'R', userInputR, ImGui.InputTextFlags_CharsDecimal)
    ImGui.SameLine(ctx);
    ImGui.SetNextItemWidth(ctx, 75)
    retval, userInputG = ImGui.InputText(ctx, 'G', userInputG, ImGui.InputTextFlags_CharsDecimal)
    ImGui.SameLine(ctx);
    ImGui.SetNextItemWidth(ctx, 75)
    retval, userInputB = ImGui.InputText(ctx, 'B', userInputB, ImGui.InputTextFlags_CharsDecimal)
    userInputR, userInputG, userInputB = CheckIfStringNil(userInputR, userInputG, userInputB)
    intR = StringToInt(userInputR)
    intG = StringToInt(userInputG)
    intB = StringToInt(userInputB)
end
    --Read in user SWS input--
function SWSInput()
    ImGui.SetNextItemWidth(ctx, 100)
    retval, userInputSWS = ImGui.InputText(ctx, 'Current SWS Code', userInputSWS, ImGui.InputTextFlags_CharsDecimal)
    userInputSWS = CheckIfStringNil(userInputSWS)
    intSWS = StringToInt(userInputSWS)
end
-------------------------------------------
---CONVERTING USER INPUT TO DESIRED FORM---
-------------------------------------------
--Take input and return a hex code as a string--
function ToHex()
    local hexResult = "blank"
    local intResult
    local selectedHex = false
    --if user has hex and hex selected--
    if items[widgets.combos.current_item1]== "Hex Values" then
        selectedHex = true
        resultText = "You've already got hex!"
        elseif items[widgets.combos.current_item1]== "RGB Values" then
            hexResult = RGBToHex(intR, intG, intB)
            selectedHex = false
        elseif items[widgets.combos.current_item1]== "SWS Value" then
            hexResult =  SWSToHex(intSWS)
            selectedHex = false
    end
    if not selectedHex then
        resultText = string.format("Hex Code: %s", hexResult)--string.format("Hex code: %s", hexResult) -- returns the string  as a string result
        else resultText = "You've already got hex!"
    end
end
--Take input and return an RGB code--
function ToRGB()
    local r = 1
    local g = 1
    local b = 1
    local rgbStringResult = ""
    local selectedRGB = false
    if items[widgets.combos.current_item1]== "Hex Values" then
      r, g, b = HexToRGB(strHex)
      selectedRGB = false
        elseif items[widgets.combos.current_item1] == "RGB Values" then
            selectedRGB = true
            resultText = "You've already got RGB!"
        elseif items[widgets.combos.current_item1] == "SWS Values" then
            r, g, b = SWSToRGB(intSWS)
            selectedRGB = false                          
    end
    r, g, b = CheckIfNil(r, g, b)
    if not selectedRGB then
        resultText = string.format("R: %d".."\nG: %d".."\nB: %d", r, g, b) -- returns the ints as a string result
        else resultText = "You've already got RGB!"
    end
end

--Take input and return an SWS code--
function ToSWS()
    local selectedSWS = false
    local swsInt
    if items[widgets.combos.current_item1]== "Hex Values" then
      swsInt = HexToSWS(strHex)
        elseif items[widgets.combos.current_item1] == "RGB Values" then
            swsInt = RGBToSWS(intR, intG, intB)
        elseif items[widgets.combos.current_item1] == "SWS Values" then
            resultText = "You've already got SWS!"            
    end
    if not selectedSWS then
        if type(swsInt) == "number" then
        local testint = 99
              resultText = string.format("SWS: %d", swsInt) -- returns the ints as a string result
        end
    end
end
---------------------------------------
---TRANSLATING HEX INTO OTHER VALUES---
---------------------------------------
---- translates hex to SWS -----
function HexToSWS(hexInput)
    hexInput = CheckIfStringNil(hexInput)
    local r = 0
    local g = 0
    local b = 0
    r, g, b = HexToRGB(hexInput)
    local swsint = RGBToSWS(r, g, b)
    return swsint
end
---- translates hex to RGB ----
function HexToRGB(hex_code)
    hex_code = CheckIfStringNil(hex_code)
    hex_code = hex_code:gsub("#", "")  -- Remove '#' if present
    local r = tonumber(hex_code:sub(1, 2), 16)
    local g = tonumber(hex_code:sub(3, 4), 16)
    local b = tonumber(hex_code:sub(5, 6), 16)
    return r, g, b
end
---------------------------------------
---TRANSLATING SWS INTO OTHER VALUES---
---------------------------------------
    ---- translates SWS to RGB ----
function SWSToRGB(sws)
    sws = CheckIfNil(sws)
    local r = sws % 256
    local g = math.floor(sws / 256) % 256
    local b = math.floor(sws / 65536) % 256

            -- Ensure h, s, l are integers
            r = math.floor(r + 0.5)  -- Round r to the nearest integer
            g = math.floor(g + 0.5)  -- Round g to the nearest integer
            b = math.floor(b + 0.5)  -- Round b to the nearest integer
    return r, g, b
end
    ----function that turns SWS to hex----
function SWSToHex(sws)
    sws = CheckIfNil(sws)
    local hexValue
    local r, g, b = SWSToRGB(sws)
    hexValue = RGBToHex(r, g, b)
    return hexValue
end
---------------------------------------
---TRANSLATING RGB INTO OTHER VALUES---
---------------------------------------
    ---- function that translates RGB to hex----
function RGBToHex(r, g, b)
    r, g, b = CheckIfNil(r, g, b)
    local hexValue = ""

    if type(r) == "number" and type(g) == "number" and type(g) == "number" then
    hexValue = string.format("#%02X%02X%02X", r, g, b)
    return hexValue
    else
        print(r)
        return "error"
    end
end

    ----function that turns RGB to SWS ----
function RGBToSWS(r, g, b)
    r, g, b = CheckIfNil(r, g, b)
    local swsvalue = 0
    swsvalue = r + g * 256 + b * 65536
    return swsvalue
end

---------------------------
---SWS VALUE CALCULATION---
---------------------------
    ---- Function to calculate the SWS value from RGB values----
function CalculateSWS(r, g, b)
    local swsValue = r + g * 256 + b * 65536
    return swsValue
end

-----------------------
---TYPE TRANSLATIONS---
-----------------------
    ---- turns string input to int ----
function StringToInt(str)
    local num = tonumber(str)
    if num then
        return math.floor(num)  -- Ensure it's an integer
    else
        return 0
    end
end

    ----function that turns int to string----
function IntToStr(intValue)
    if type(intValue) ~= "number" or intValue % 1 ~= 0 then
        return ""
    end
    return tostring(intValue)
end
-------------------
---CHECKS IF NIL---
-------------------
    ---- checks if int values are nil, returns 0 if so ----
function CheckIfNil(x, y, z)
    if x == nil then x = 0 
    end
    if y == nil then y = 0 
    end
    if z == nil then z = 0
    end
    return x, y, z
end
    ---- checks if string values are nil, returns "" if so ----
function CheckIfStringNil(x, y, z)
    if x == nil then x = "" 
    end
    if y == nil then y = "" 
    end
    if z == nil then z = ""
    end
    return x, y, z
end

-----------------
---MAIN WINDOW---
-----------------
local function mainWindow()

    local preview_valueA = items[widgets.combos.current_item1]
    local preview_valueB = items[widgets.combos.current_item2]
    
    ImGui.Text(ctx, "Convert your color codes!")

    --FIRST DROPDOWN--
    ImGui.SetNextItemWidth(ctx, 100)
    if ImGui.BeginCombo(ctx, "Current Code Format", preview_valueA) then
        for i, v in ipairs(items) do
            local is_selected = widgets.combos.current_item1 == i
            if ImGui.Selectable(ctx, items[i], is_selected) then
                widgets.combos.current_item1 = i
                preview_valueA = items[i] -- Update the preview value when selection changes
            end
        end
        ImGui.EndCombo(ctx)
    end

    if items[widgets.combos.current_item1] == "Hex Values" then
        HexInput()
        else if items[widgets.combos.current_item1] == "RGB Values" then
            RGBInput()
        else if items[widgets.combos.current_item1] == "SWS Value" then
            SWSInput()
                 end
            end
        end
    --SECOND DROPDOWN --
    ImGui.SetNextItemWidth(ctx, 100)
    if ImGui.BeginCombo(ctx, "Desired Code Format", preview_valueB) then
        for i, v in ipairs(items) do
            local is_selected = widgets.combos.current_item2 == i
            if ImGui.Selectable(ctx, items[i], is_selected) then
                widgets.combos.current_item2 = i
                preview_valueB = items[i] -- Update the preview value when selection changes
            end
        end
        ImGui.EndCombo(ctx)
    end

    ---TRANSFORM BUTTON---
    if ImGui.Button(ctx, "Transform!") then
        transformButtonClick = 1
        if items[widgets.combos.current_item2] == "Hex Values" then
            ToHex()
            else if items[widgets.combos.current_item2] == "RGB Values" then
                ToRGB()
            else if items[widgets.combos.current_item2] == "SWS Value" then
                ToSWS()
                     end
                end
            end
        end      
    if transformButtonClick > 0 then
        ImGui.Text(ctx, resultText)
    end
end


---- Main function loop ----
local function loop()
    local visible, open = ImGui.Begin(ctx, 'REAsetta Stone', true)
    if visible then
        mainWindow()
        ImGui.End(ctx)
    end
    if open then
        reaper.defer(loop)
    end
end

reaper.defer(loop)
