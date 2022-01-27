--[[
  Author: Laresi
  Version: 27.1.2022

  This version of the program runs as a server machine by directly connecting
  the computer to an Energy Pylon on the Draconic Evolution core.
  The server will listen for requests sent to port 100. You can change this
  port by modifying the code.
]]

-- The port that will be used in data transfer
local port = 100

local comp = require("component")
local term = require("term")
local event = require("event")
local modem = comp.modem
local storage = comp.draconic_rf_storage
local hasGpu = true

local maxEnergy = storage.getMaxEnergyStored()

-- Check if computer has a screen connected to it and has gpu installed.
if not (term.isAvailable()) then
  print("Error displaying output on screen.")
  print("Either the computer is missing a screen or a gpu isn't installed.")
  print("How are you even able to read this?")
  hasGpu = false
end

if (hasGpu) then
  local gpu = comp.gpu
  local w, h = gpu.maxResolution()
  if (w > 80) then w = w/2 end
  if (h > 25) then h = h/2 end
  gpu.setResolution(w, h)
  w, h = gpu.getResolution()
  local barXStart = w/8
  local barYStart = h/2 + h/4
  term.setCursorBlink(false)
end

-- If computer isn't connected to Draconic Energy Core, stop execution.
if not (comp.isAvailable("draconic_rf_storage")) then
  print("No Draconic Energy Core found.")
  print("Please connect the computer to the Draconic Evolution core")
  print("by connecting an Adapter block to Energy Pylon block and try again")
  os.exit()
end

-- If computer doesn't have a network card, stop execution
if not (comp.isAvailable("modem")) then
  print("No network card was found.")
  print("Please insert a network card in to the computer and try again.")
  os.exit()
end


modem.open(port)
-- Should trigger only in rare cases if the port is already in use
if not (modem.isOpen(port)) then
  print("Encountered an issue opening the port. Please try again.")
  os.exit()
end
print("Listening on port " .. port)


--- Checks that the received request is correct and responds accordingly
-- @server address that received the request
-- @target where the request will be sent
-- @msg message sent by the target
local function handleRequest(target, msg)
  if (string.match(msg, "draconic")) then
    print("Received request, sending core data")
    -- Energy stored
    local energy = storage.getEnergyStored()
    -- Energy transfer rate from the core. Can be positive or negative
    local transfer = storage.getTransferPerTick()

    if (msg == "draconicStatus") then
      modem.send(target, port, transfer, energy)
    elseif (msg == "draconicInit") then
      modem.send(target, port, transfer, energy, maxEnergy)
    else
      print("Request was invalid: " .. msg)
    end
  end
end


--- Loop events until an interrupt is received
while (true) do
  local id, server, sender, _port, _distance, message = event
    .pullMultiple("interrupted", "modem_message")
  print(id)
  if (id) then
    if (id == "modem_message") then
      print("message received!" .. message)
      handleRequest(sender, message)
    elseif (id == "interrupted") then
      term.clear()
      print("Program stopping")
      break
    end
  end
end
