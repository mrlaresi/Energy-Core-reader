--[[
  Author: Laresi
  Version: 27.1.2022
  This version of the program runs by directly connecting the computer to
  an Energy Pylon on the Draconic Evolution core.
]]

local comp = require("component")
local term = require("term")


-- Check if computer has a screen connected to it and has gpu installed.
if not (term.isAvailable()) then
  print("Error displaying output on screen.")
  print("Either the computer is missing a screen or a gpu isn't isntalled.")
  print("How are you even able to read this?")
  os.exit()
end


-- If computer isn't connected to Draconic Energy Core, stop execution.
if not (comp.isAvailable("draconic_rf_storage")) then
  print("No Draconic Energy Core found.")
  print("Please connect the computer to the Draconic Evolution core")
  print("by connecting an Adapter block to Energy Pylon block and try again")
  os.exit()
end


local event = require("event")
local gpu = comp.gpu
local storage = comp.draconic_rf_storage


local w, h = gpu.getResolution()
local barXStart = w/8
local barYStart = h/2 + h/4
local maxEnergy = storage.getMaxEnergyStored()
term.setCursorBlink(false)


--- Rounds given float to integer number
-- @num float to be rounded
-- @return rounded integer
local function round(num)
  if (num % 1 >= 0.5) then
    return math.ceil(num)
  else
    return math.floor(num)
  end
end


--- Round to two significant digits
-- @num float value to be rounded
-- @return rounded integer
local function roundTwo(num)
  return round(num*100)/100
end


--- Converts units into a larger one so that screen is not flooded.
-- Appends units and RF (Redstone Flux) after the number
-- @num float value to be converted
-- @return string containing rounded integer and units
local function suffix(num)
  local ret = 0
  if (num / 100000000000000000 > 1) then
    ret =  roundTwo(num/(10^18)) .. "E RF"
  elseif (num / 100000000000000 > 1) then
    ret = roundTwo(num/(10^15)) .. "P RF"
  elseif (num / 100000000000 > 1) then
    ret = roundTwo(num/(10^12)) .. "T RF"
  elseif (num / 100000000 > 1) then
    ret = roundTwo(num/(10^9)) .. "G RF"
  elseif (num / 100000 > 1) then
    ret = roundTwo(num/(10^6)) .. "M RF"
  elseif (num / 100 > 1) then
    ret = roundTwo(num/(10^3)) .. "K RF"
  else
    ret = num .. "RF"
  end
  return ret
end


--- Draws visualization of the energy stored inside the Energy Core
local function draw()
	gpu.setBackground(0x000000)
	term.clear()
  local energy = storage.getEnergyStored()

	-- Count the amount of energy stored inside the Core of the maximum
	local percentage = energy/maxEnergy
	if (percentage < 0.01) then
	  percentage = 0
	end
	-- How much of the visualization should be filled
	local energyWidth = round(percentage * (w - barXStart * 2))

	-- Draw text to the screen
	--[[
	  energy stored         percentage        max capacity
	  [                 *visualization*                  ]
	]]
	term.setCursor(w/11, h/2 + h/6)
	print(suffix(energy))
	term.setCursor(w/2 - w/20, h/2 + h/6)
	print(roundTwo(percentage*100) .. "%")
	term.setCursor(w-w/7, h/2 + h/6)
	print(suffix(maxEnergy))
	term.setCursor(0, 0)

	-- Draw visualization as gray bar
	gpu.setBackground(0x0f0f0f)
	gpu.fill(barXStart, barYStart, (w - barXStart*2), h/6, " ")

	-- Fill in the bar up to energyWidth with specified color
	gpu.setBackground(0x800080)
	gpu.fill(barXStart, barYStart, energyWidth, h/6, " ")
end


--- Loop until an interrupt is received
while (true) do
  draw()
  local id, uptime = event.pull(5, "interrupted")
  if (id) then
    if (id == "interrupted") then
      gpu.setBackground(0x000000)
      term.clear()
      print("Program stopping")
      break
    end
  end
end
