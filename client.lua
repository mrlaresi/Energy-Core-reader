--[[
  Author: Laresi
  Version: 27.1.2022

  This version of the program runs by connecting to a server computer and
  polling it through OpenComputers network for details about the Energy Core
]]

-- The port that will be used in  data transfer
local port = 100

local comp = require("component")
local term = require("term")
local event = require("event")

local modem = comp.modem

local maxEnergy = ""
local serverAddress = ""


-- Check if computer has a screen connected to it and has gpu installed.
if not (term.isAvailable()) then
  print("Error displaying output on screen.")
  print("Either the computer is missing a screen or a gpu isn't installed.")
  print("How are you even able to read this?")
end

local gpu = comp.gpu

local w, h = gpu.maxResolution()
if (w > 80) then w = w/2 end
if (h > 25) then h = h/2 end
gpu.setResolution(w, h)
w, h = gpu.getResolution()
local barXStart = w/8
local barYStart = h/2 + h/4
term.setCursorBlink(false)

-- If computer doesn't have a network card, stop execution
if not (comp.isAvailable("modem")) then
  print("No network card was found.")
  print("Please insert a network card in to the computer and try again.")
  os.exit()
end

local modem = comp.modem
modem.open(port)
-- Should trigger only in rare cases if the port is already in use
if not (modem.isOpen(port)) then
  print("Encountered an issue opening the port. Please try again.")
  os.exit()
end
print("Using port " .. port .. " for messages.")


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
-- @return string containing rounded energy amount and units
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


--- Converts units into larger one for transfer rate so that the screen is not
-- flooded. Appends units and RF/t (Redstone Flux per tick) after the number.
-- @num float value to be converted
-- @return string containing rounded transfer rate and units
local function suffixTransfer(num)
  local ret = 0
  if (math.abs(num / 10^16) > 1) then
    ret = math.floor(num / 10^15) .. " P RF/t"
  elseif (math.abs(num / 10^13) > 1) then
    ret = math.floor(num / 10^12) .. " T RF/t"
  elseif (math.abs(num / 10^10) > 1) then
    ret = math.floor(num / 10^9) .. " G RF/t"
  elseif (math.abs(num / 10^7) > 1) then
    ret = math.floor(num / 10^6) .. " M RF/t"
  elseif (math.abs(num / 10^4) > 1) then
    ret = math.floor(num / 10^3) .. " K RF/t"
  else
    ret = math.floor(num) .. " RF/t"
  end
  return ret
end


--- Draws visualization of the energy stored inside the Energy Core
local function draw(transfer, energy)
    gpu.setBackground(0x000000)
    term.clear()

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

  local temp = suffixTransfer(transfer)
  term.setCursor(w/2 - string.len(temp)/2, h/4)

  -- Set transfer rate text color depending if it's positive or negative
  if (tonumber(transfer) > 0) then
    gpu.setForeground(0x00FF00)
  else
    gpu.setForeground(0xFF0000)
  end
  print(temp)
  gpu.setForeground(0xFFFFFF)

  -- Percentage stored
  temp = roundTwo(percentage*100) .. "%"
  term.setCursor(w/2 - string.len(temp)/2, h/2 + h/6)
  print(temp)

  -- Maximum available storage space
  temp = suffix(maxEnergy)
  term.setCursor(w-w/11 - string.len(temp)/2, h/2 + h/6)
  print(temp)

	-- Draw visualization as gray bar
  term.setCursor(0, 0)  
  gpu.setBackground(0x0f0f0f)
  gpu.fill(barXStart, barYStart, (w - barXStart*2), h/6, " ")

  -- Fill in the bar up to energyWidth with specified color
  gpu.setBackground(0x800080)
  gpu.fill(barXStart, barYStart, energyWidth, h/6, " ")
end


--- Initialize connection to server by broadcasting to the network until
-- a server responds
-- @return array containing transfer rate and stored energy
local function initMessage()
  local attempt = 1
  while (true) do
    print("Trying to find a server for core data, attempt " .. attempt)
    modem.broadcast(port, "draconicInit")
    local id, _pc, sender, _port, _dist, transfer, energy, max = event
      .pullMultiple(10, "modem_message", "interrupted")
    if (id) then
      if (id == "modem_message") then
        serverAddress = sender
        maxEnergy = max
        return { transfer, energy }
      elseif (id == "interrupted") then
        gpu.setBackground(0x000000)
        term.clear()
        print("Program stopping")
        os.exit()
      end
    end
    attempt = attempt + 1
  end
end


--- Send a request to the server for Core energy status
local function pollEnergy()
  modem.send(serverAddress, port, "draconicStatus")
end


print("Boot complete, initializing connection")
initMessage()
print("Connected!")
print("Starting polling for data...")

--- Loop until an interrupt is received
while (true) do
  local interrupt = event.pull(5, "interrupt")
  if (interrupt) then
    gpu.setBackground(0x000000)
      term.clear()
      print("Program stopping")
      break
  end
  pollEnergy()
  local id, server, sender, _port, _distance, transfer, energy = event
    .pull(.1, "modem_message")

  if (id) then
    draw(transfer, energy)
  end
end
