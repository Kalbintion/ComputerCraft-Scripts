--[[
    Written by Kalbintion
	Requires:
      -- Computer to be attached directly to Computer Port
	  -- 5x3 Advanced Monitor
--]]

-- Settings
delay_between_updates = 0.1 -- Time between monitor updates
display_averages = true -- Average Display
max_storable_ticks = 10000 -- Average Storage Max

--[[============================================
     DO NOT MODIFY BELOW, DO SO AT YOUR OWN RISK
    ============================================]]

-- Get Peripherals
br = peripheral.find("BigReactors-Reactor")
mon = peripheral.find("monitor")

width_line = 100
height_line = 64

highRFTick = 0
avgRFTicks = {}
avgRFTickIdx = 1

highFuelReact = 0
avgFuelReact = {}
avgFuelReactIdx = 1

highCasingTemp = 0
avgCasingTemp = {}
avgCasingTempIdx = 1

highFuelTemp = 0
avgFuelTemp = {}
avgFuelTempIdx = 1

-- Functions
function resetMonitor(mon)
  mon.clear()
  mon.setTextScale(1)
  mon.setCursorPos(1,1)
  resetMonitorColors(mon)
end

function resetMonitorColors(mon)
	mon.setTextColor(colors.white)
	mon.setBackgroundColor(colors.black)
end

function printBasicStats(mon, br, x, y)
  -- Get activity information
  mon.setCursorPos(x, y)
  mon.setTextColor(colors.white)
  x, y = writeAdv(x, y, mon, " Reactor Status: ")
  if br.getActive() then
    mon.setTextColor(colors.lime)
	mon.write("Active")
  else
    mon.setTextColor(colors.red)
	mon.write("Inactive")
  end
  
  resetMonitorColors(mon)
  x, y = writeAdv(x, y, mon, padString("    Casing Temp: "..br.getCasingTemperature(), 25).." Fuel Temp: "..br.getFuelTemperature())
  x, y = writeAdv(x, y, mon, padString(" Fuel Rod Count: "..br.getNumberOfControlRods(),25).." Fuel Last Tick: "..br.getFuelConsumedLastTick())
  x, y = writeAdv(x, y, mon, padString("Fuel Reactivity: "..br.getFuelReactivity(),25).." RF/t: "..br.getEnergyProducedLastTick())
  
  -- Averages Tables
  --   Casing Temp
  if avgCasingTempIdx > max_storable_ticks then
    avgCasingTempIdx = 1
  end
  avgCasingTemp[avgCasingTempIdx] = br.getCasingTemperature()
  avgCasingTempIdx = avgCasingTempIdx + 1
  
  --    Fuel Temp
  if avgFuelTempIdx > max_storable_ticks then
    avgFuelTempIdx = 1
  end
  avgFuelTemp[avgFuelTempIdx] = br.getFuelTemperature()
  avgFuelTempIdx = avgFuelTempIdx + 1
  
  --    RF/Tick
  if avgRFTickIdx > max_storable_ticks then
	avgRFTickIdx = 1
  end
  avgRFTicks[avgRFTickIdx] = br.getEnergyProducedLastTick()
  avgRFTickIdx = avgRFTickIdx + 1
  
  --    Fuel Reactivity
  if avgFuelReactIdx > max_storable_ticks then
    avgFuelReactIdx = 1
  end
  avgFuelReact[avgFuelReactIdx] = br.getFuelReactivity()
  avgFuelReactIdx = avgFuelReactIdx + 1
  
  -- Highs
  if br.getCasingTemperature() > highCasingTemp then
    highCasingTemp = br.getCasingTemperature()
  end
  if br.getFuelTemperature() > highFuelTemp then
    highFuelTemp = br.getFuelTemperature()
  end
  if br.getEnergyProducedLastTick() > highRFTick then
    highRFTick = br.getEnergyProducedLastTick()
  end
  if br.getFuelReactivity() > highFuelReact then
    highFuelReact = br.getFuelReactivity()
  end
  
  return x, y
end
  
function printFuelPercentage(mon, br, x, y)
  -- Get the fuel information
  local maxFuel = br.getFuelAmountMax()
  local curFuel = br.getFuelAmount()
  local perFuel = curFuel / maxFuel * 100
  
  -- Print header line
  resetMonitorColors(mon)
  x, y = writeAdv(x, y, mon, "% of Fuel Remaining [")
  printColorPercent(mon, perFuel, 25, 50, 75, 100, colors.red, colors.yellow, colors.orange, colors.lime)
  mon.setTextColor(colors.white)
  mon.write("]")
  
  -- Print % Bar
  mon.setCursorPos(x, y)
  local flrFuel = math.floor(perFuel)
  printProgressBar(mon, 50, flrFuel / 2, colors.green, colors.white)
  
  return x, y
end

function printWastePercentage(mon, br, x, y)
  -- Get the fuel information
  local maxWaste = br.getFuelAmountMax()
  local curWaste = br.getWasteAmount()
  local perWaste = curWaste / maxWaste * 100
  
  -- Print header line
  resetMonitorColors(mon)
  x, y = writeAdv(x, y, mon, "% of Waste [")
  printColorPercent(mon, perWaste, 25, 50, 75, 100, colors.red, colors.yellow, colors.orange, colors.lime)
  mon.setTextColor(colors.white)
  mon.write("]")
  
  -- Print % Bar
  mon.setCursorPos(x, y)
  local flrWaste = math.floor(perWaste)
  printProgressBar(mon, 50, flrWaste / 2, colors.red, colors.white)
  
  return x, y
end

function printPowerPercentage(mon, br, x, y)
  -- Get Power Information
  local curPower = br.getEnergyStored()
  local maxPower = 10000000
  local perPower = curPower / maxPower * 100
  
  -- Print header line
  resetMonitorColors(mon)
  x, y = writeAdv(x, y, mon, "% of Power Stored [")
  printColorPercent(mon, perPower, 25, 50, 75, 100, colors.red, colors.yellow, colors.orange, colors.lime)
  mon.setTextColor(colors.white)
  mon.write("]")
  
  -- Print % Bar
  local flrPower = math.floor(perPower)
  mon.setCursorPos(x, y)
  printProgressBar(mon, 50, flrPower / 2, colors.red, colors.white)
  
  return x, y
end

function printAverages(mon, br, x, y)
  resetMonitorColors(mon)
  x, y = writeAdv(x, y, mon, padString(" # of Stored Values: " .. max_storable_ticks, 35) .. " High")
  x, y = writeAdv(x, y, mon, padString("Avg Fuel Reactivity: " .. avgArray(avgFuelReact, max_storable_ticks), 35) .. " " .. highFuelReact)
  x, y = writeAdv(x, y, mon, padString("           Avg RF/t: " .. avgArray(avgRFTicks, max_storable_ticks), 35) .. " " .. highRFTick)
  x, y = writeAdv(x, y, mon, padString("      Avg Case Temp: " .. avgArray(avgCasingTemp, max_storable_ticks), 35) .. " " .. highCasingTemp)
  x, y = writeAdv(x, y, mon, padString("      Avg Fuel Temp: " .. avgArray(avgFuelTemp, max_storable_ticks), 35) .. " " .. highFuelTemp)
  return x, y
end

function maintainReactor(br)
	local powerStored = br.getEnergyStored()
	if powerStored <= 0 then
	  br.setActive(true)
	else
	  br.setActive(false)
	end
end

-- Helper Functions
function printProgressBar(out, totalWidth, fillWidth, colorFill, colorEmpty)
	fillWidth = math.floor(fillWidth)
	out.setBackgroundColor(colorFill)
	out.write(string.rep(" ",fillWidth))
	out.setBackgroundColor(colorEmpty)
	out.write(string.rep(" ",totalWidth-fillWidth))
end

function printColorPercent(out, value, v1, v2, v3, v4, c1, c2, c3, c4)
  if value <= v1 then
    out.setTextColor(c1)
  elseif value <= v2 then
    out.setTextColor(c2)
  elseif value <= v3 then
    out.setTextColor(c3)
  elseif value <= v4 then
    out.setTextColor(c4)
  end
  out.write(value)
end

function printSeparatorLine(out, char, x, y)
  local w, h = out.getSize()
  out.setCursorPos(x, y)
  out.write(string.rep(char, w))
end

function writeAdv(x, y, out, text)
  out.setCursorPos(x, y)
  out.write(text)
  return x, y+1
end

function avgArray(arr, count)
	local sum = 0
	for i = 1, count, 1 do
	  if arr[i] then
		sum = sum + arr[i]
	  end
	end
	sum = sum / count
	return sum
end

-- Written by dissy @ http://www.computercraft.info/forums2/index.php?/topic/6965-146sspsmp-stringformat-behaves-incorrectly-with-widthprecisions/
function padString (sText, iLen)
  local iTextLen = string.len(sText)
  -- Too short, pad
  if iTextLen < iLen then
        local iDiff = iLen - iTextLen
        return(sText..string.rep(" ",iDiff))
  end
  -- Too long, trim
  if iTextLen > iLen then
        return(string.sub(sText,1,iLen))
  end
  -- Exact length
  return(sText)
end

-- Main Loop
repeat
  x, y = 1, 1
  sleep(delay_between_updates)
  maintainReactor(br)
  resetMonitor(mon)
  x, y = printBasicStats(mon, br, x, y)
  resetMonitorColors(mon)
  x, y = printFuelPercentage(mon, br, x, y + 1)
  resetMonitorColors(mon)
  x, y = printWastePercentage(mon, br, x, y + 2)
  resetMonitorColors(mon)
  x, y = printPowerPercentage(mon, br, x, y + 2)
  resetMonitorColors(mon)
  if display_averages then
    x, y = printAverages(mon, br, x, y + 2)
    resetMonitorColors(mon)
  end
until true==false
