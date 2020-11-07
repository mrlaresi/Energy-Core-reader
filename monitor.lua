-- Author: Laresi
-- Version: 7.11.2020

local comp = require("component")
local term = require("term")
local color = require("colors")
local computer = require("computer")


-- If computer isn't connected to Draconic Energy Core, stop execution.
if not (comp.isAvailable("draconic_rf_storage")) then
  print("No Draconic Energy Core found. Please connect the computer to an Energy Core and try again.")
  os.exit()
end


-- Check if computer has a screen connected to it and has gpu installed.
if not (term.isAvailable()) then
  print("Error displaying output on screen. Either the computer is missing a screen or a gpu.")
  os.exit()
end


local storage = comp.draconic_rf_storage
local gpu = comp.gpu
local w, h = gpu.getResolution()
local barXStart = w/8
local barYStart = h/2 + h/4
local max = storage.getMaxEnergyStored()
term.setCursorBlink(false)


-- Rounds given float to decimal number
function round(num)
  if (num % 1 >= 0.5) then
    return math.ceil(num)
  else
    return math.floor(num)
  end
end


function suffix(num)
  local ret = 0
  if (num / 100000000000000000 > 1) then
    ret =  num/(6*1000) .. "E RF"

  elseif (num / 100000000000000 > 1) then
    ret = num/(5*1000) .. "P RF"

  elseif (num / 100000000000 > 1) then
    ret = num/(4*1000) .. "T RF"

  elseif (num / 100000000 > 1) then
    ret = num/(3*1000) .. "G RF"

  elseif (num / 100000 > 1) then
    ret = num/(2*1000) .. "M RF"

  elseif (num / 100 > 1) then
    ret = num/(1000) .. "K RF"

  else
    ret = num .. "RF"
  end
  return ret
end


-- Draws visualization of the energy stored inside the Energy Core
function draw()
  gpu.setBackground(0x000000)
  term.clear()
  local energy = storage.getEnergyStored()

  -- Count the amount of energy stored inside the Core of the maximum
  local percentage = energy/max
  local energyWidth = round(percentage * (w - barXStart * 2))

  term.setCursor(w/11, h/2 + h/6)
  print(energy)
  term.setCursor(w/2, h/2 + h/6)
  print(math.floor(percentage*10000)/100 .. "%")
  term.setCursor(w-w/7, h/2 + h/6)
  print(max)
  term.setCursor(0, 0)

  gpu.setBackground(0x0f0f0f)
  gpu.fill(barXStart, barYStart, (w - barYStart), h/6, " ")

  gpu.setBackground(0x800080)
  gpu.fill(barXStart, barYStart, energyWidth, h/6, " ")
end


-- Loop until the computer is shutdown
while (comp.computer.isRunning())
do
  draw()
  os.sleep(5)
end
