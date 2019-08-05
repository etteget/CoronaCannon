--[[

#Functions added to widget library.

Functions added to widget library to make it easier to create
buttons in consistent manner throughout the application.

Also, possibility to create FontAwesome icons easily added.

]]--

local widget = require("widget")

local DEFAULT_BUTTON_WIDTH = 400
local DEFAULT_BUTTON_HEIGHT = 100

--
-- Default button style for buttons with text.
--
widget.newDefaultTextButton = function(o)
  assert(o.label, "option label required")

  o.shape = "roundedRect"
  o.emboss = false
  o.labelColor = { default={ 1, 1, 1 }, over={ 0, 0, 0, 0.5 } }
  o.fontSize = 60
  o.cornerRadius = 10
  o.fillColor = { default= { 1, 0.2, 0.5, 0.7 }, over={ 1, 0.2, 0.5, 1 } }
  o.strokeColor = { default= {1, 0.3, 0.6 }, over={ 1, 0.35, 0.55, 1 } }
  o.strokeWidth = 10

  o.width = o.width or DEFAULT_BUTTON_WIDTH
  o.height = o.height or DEFAULT_BUTTON_HEIGHT

  return widget.newButton(o)
end


--
-- A button for that shows icon using FontAwesome font.
-- FontAwesome fonts that we use may be from fonts set
-- FontAwesomeSolid or FontAwesomeRegular. That is given
-- in in o.fontAwesomeFont as either "solid" or "regular"
--
-- Example usage:
-- local options = { "", fontAwesomeFont = "solid" }
-- local button = widget.newFontAwesomeButton(options)
--
widget.newFontAwesomeButton = function(o)
  assert(o.label, "o.label required")
  assert(o.fontAwesomeFont, "o.fontAwesomeFont required")

  local fontLocation = "libs/res/fonts/"
  if o.fontAwesomeFont == "solid" then
    o.font = fontLocation .. "FontAwesome5FreeSolid900"
  else
    o.font = fontLocation .. "FontAwesome5FreeRegular400"
  end

  o.shape = "circle"
  -- o.emboss = false
  o.labelColor = { default={ 1, 1, 1 }, over={ 0, 0, 0, 0.5 } }
  o.fontSize = o.fontSize or 60
  o.fillColor = { default= { 1, 0.2, 0.5, 0.7 }, over={ 1, 0.2, 0.5, 1 } }
  o.strokeColor = { default= {1, 0.3, 0.6 }, over={ 1, 0.35, 0.55, 1 } }
  o.strokeWidth = 10
  o.radius = o.fontSize / 2 + 10

  -- o.width = o.fontSize + 10
  -- o.height = o.fontSize + 10

  return widget.newButton(o)
end