local comp = require("component")
local term = require("term")
local event = require("event")

-- The port that will be used in
local port = 100
local modem = comp.modem
local target = ""
local received = false
local confirm = false

local gpu = comp.gpu
local w, h = gpu.getResolution()

gpu.setResolution(w/2, h/2)
w, h = gpu.getResolution()

local barXStart = w/8
local barYStart = h/2 + h/4
term.setCursorBlink(false)
local max = ""



local function handleMessage(from, msg)
    if (msg == "draconicCore") then
        print("Received message from Draconic Core; Sending confirmation")
        target = from
        modem.send(target, port, "draconicOK")
        received = true
    end
    if (msg == "OK" and from == target) then
        print("Connection established")
        confirm = true
    end
end


-- Rounds given float to decimal number
local function round(num)
    if (num % 1 >= 0.5) then
      return math.ceil(num)
    else
      return math.floor(num)
    end
end
  
  
-- Round to two decimal numbers
local function roundTwo(num)
    return round(num*100)/100
end
  
  
local function suffix(num)
    local ret = 0
    if (num / 10^17 > 1) then
        ret = roundTwo(num / 10^18) .. " E RF"
    elseif (num / 10^14 > 1) then
        ret = roundTwo(num / 10^15) .. " P RF"
    elseif (num / 10^11 > 1) then
        ret = roundTwo(num / 10^12) .. " T RF"
    elseif (num / 10^8 > 1) then
        ret = roundTwo(num / 10^9) .. " G RF"
    elseif (num / 10^5 > 1) then
        ret = roundTwo(num / 10^6) .. " M RF"
    elseif (num / 10^2 > 1) then
        ret = roundTwo(num / 10^3) .. " K RF"
    else
        ret = math.floor(num) .. " RF"
    end
    return ret
end

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
  
  
  -- Draws visualization of the energy stored inside the Energy Core
local function draw(transfer, energy)
    gpu.setBackground(0x000000)
    term.clear()
  
    -- Count the amount of energy stored inside the Core of the maximum
    local percentage = energy/max
    local energyWidth = round(percentage * (w - barXStart * 2))
    local temp = ""
  
    term.setCursor(w/11, h/2 + h/6)
    print(suffix(energy))

    temp = suffixTransfer(transfer)
    term.setCursor(w/2 - string.len(temp)/2, h/4)
    if (tonumber(transfer) > 0) then
        gpu.setForeground(0x00FF00)
    else
        gpu.setForeground(0xFF0000)
    end
    print(temp)
    gpu.setForeground(0xFFFFFF)

    temp = roundTwo(percentage*100) .. "%"
    term.setCursor(w/2 - string.len(temp)/2, h/2 + h/6)
    print(temp)

    temp = suffix(max)
    term.setCursor(w-w/11 - string.len(temp)/2, h/2 + h/6)
    print(temp)

    term.setCursor(0, 0)  
    gpu.setBackground(0x0f0f0f)
    gpu.fill(barXStart, barYStart, (w - barYStart), h/6, " ")
  
    gpu.setBackground(0x800080)
    gpu.fill(barXStart, barYStart, energyWidth, h/6, " ")
end


if not (comp.isAvailable("modem")) then
    print("No network card was found. Please insert network card to the\z 
            computer and try again")
    os.exit()
end

-- Check if computer has a screen connected to it and has gpu installed.
if not (term.isAvailable()) then
    print("Error displaying output on screen. Either the computer is missing a screen or a gpu.")
    os.exit()
end


-- Listen on given port
modem.open(port)
if not (modem.isOpen(port)) then
    print("Encountered an issue opening the port. Please try again.")
    os.exit()
end

print("Boot complete, listening for connection...")
while not received do
    local _, _, from, _, _, message = event.pull("modem")
    os.sleep(1)
    handleMessage(from, message)
end



while not confirm do
    local _, _, from, _, _, message = event.pull("modem")
    handleMessage(from, message)
end

while true do
    local _, _, from, _, _, message = event.pull("modem")
    if (from == target) then
        max = message
        break
    end
end
print(max)

-- Loop until the computer is shutdown
while (comp.computer.isRunning())
do
    local _, _, from, _, _, transfer, energy = event.pull("modem")
    if (from == target) then
        draw(transfer, energy)
    end
end

