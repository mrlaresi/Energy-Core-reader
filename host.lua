-- The port that will be used in
local port = 100
local comp = require("component")
local event = require("event")
local storage = comp.draconic_rf_storage
local max = storage.getMaxEnergyStored()
local modem = comp.modem
local target = ""
local received = false


local function handleMessage(from, msg)
    if (msg == "draconicOK") then
        print("Received confirmation; Connection established.")
        target = from
        modem.send(target, port, "OK")
        received = true
    end 
end


-- Sends amount of energy currently stored and max amount of energy to
-- the receiving client
local function sendEnergy()
    local energy = storage.getEnergyStored()
    modem.send(target, port, energy)
end


-- If computer isn't connected to Draconic Energy Core, stop execution.
if not (comp.isAvailable("draconic_rf_storage")) then
    print("No Draconic Energy Core found. Please connect the computer to\z
            an Energy Core and try again.")
    os.exit()
end

if not (comp.isAvailable("modem")) then
    print("No network card was found. Please insert network card to the\z 
            computer and try again")
    os.exit()
end



modem.open(port)
print(modem.getStrength())

if not (modem.isOpen(port)) then
    print("Encountered an issue opening the port. Please try again.")
    os.exit()
end


-- Send broadcast message
local sent = modem.broadcast(port, "draconicCore")
print("Message sent; Waiting for connection...")
while not (received) do
    local _, _, from, _, _, message = event.pull("modem")
    os.sleep(1)
    handleMessage(from, message)
end

os.sleep(1)
modem.send(target, port, max)
os.sleep(1)

while (comp.computer.isRunning())
do
    sendEnergy()
    os.sleep(10)
end