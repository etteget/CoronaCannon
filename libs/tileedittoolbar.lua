--[[

#Tile Edit Toolbabr

* A scroll view that shows tiles and command buttons
* Modified dragitemscroll view used to offer possibility to
  add and remove tiles from level map
* Positioned automatically at the bottom of the screen.
* Save button
* Remove tile button

* For this to make sense creator should register a listener
  for onDropTile, onRemoveTileButton and onSaveButton
* Also, caller could add lines to indicate tile borders

]]--


-- adds dragItemScrollView2 into widget library
require("libs.dragitemscrollview2")

require("libs.extio")
require("libs.extwidget")

local widget = require( "widget" )
local tiled = require('libs.tiled') -- Tiled map loader


local M = {}

-- The item that is being moved from the toolbar to the tiled map.
M.currentItem = nil

-- The toolbabr instance created in .new
M.instance = nil

local function addCurrentItemIntoTileMap(event)
  local tile = {}

  -- tile.fileName = currentItem.fileLocation.fileName
  tile.type = "ground"
  tile.width = M.instance.levelEditor.map.map.tilewidth
  tile.height = M.instance.levelEditor.map.map.tileheight
  tile.properties = {}
  tile.properties.bodyType = "static"
  tile.properties.friction = 1.0

  -- We do use outline physics.
  tile.properties.autoShape = 7

  tile.baseDir = M.instance.tileBaseDir
  tile.image = M.currentItem.image

  M.instance.levelEditor:setEditorPosition(event)
  tile.x = M.instance.levelEditor.editor.x
  tile.y = M.instance.levelEditor.editor.y

  M.instance.levelEditor.editor.mode = 'tile'
  M.instance.levelEditor:addBlockOrBug(tile)

  M.currentItem:removeSelf()
  M.currentItem = nil
end

local tileMovingListener
tileMovingListener = function(event)
  assert(M.currentItem ~= nil, "tileMovingListener requires currentItem")

  local x, y = event.x, event.y
  M.currentItem.x = x
  M.currentItem.y = y
  -- currentItem.anchorX = 1
  -- currentItem.anchorY = 1

  if event.phase == "moved" then

    print("moved to point:", x, y)

  elseif event.phase == "ended" then

    print("ended to:", x, y)
    M.currentItem:removeEventListener("touch", tileMovingListener)

    display.currentStage:setFocus( event.target, nil )
    event.target.hasFocus = nil

    addCurrentItemIntoTileMap(event)

  end

  return true
end


local function tileDraggedListener(item, event)
  event.target.hasFocus = false

  -- Move item away from the scroll view. User friendly and
  -- a simple solution is to create another item based on the
  -- currentItem and move it.
  M.currentItem = display.newImageRect(
    item.fileLocation.fileName,
    item.fileLocation.baseDir,
    item.width,
    item.height)

  M.currentItem.fileLocation = item.fileLocation

  -- File name of the tile - referencesed as image in tiled format.
  M.currentItem.image = item.image

  -- We scale the item to be compatible with the scale
  -- of the map.
  -- currentItem.xScale = levelMap.xScale
  -- currentItem.yScale = levelMap.yScale

  -- The current item is not creted in any group, therefore
  -- it exists in global coordinates.
  local x = event.x
  local y = event.y

  M.currentItem.x = x
  M.currentItem.y = y

  M.currentItem:addEventListener("touch", tileMovingListener)
  display.currentStage:setFocus( M.currentItem, event.id )

  -- shaking = shakeObject(item)




  -- We start shaking and listen the event until it ends
  -- to be able to figure end point.

end


local function positionItemInScrollViewAndIncreaseIndex(self, item)
  item.x = self.index * self.buttonSize + self.buttonSize / 2 + self.margin * self.index
  item.y = self.buttonSize / 2

  self.index = self.index + 1
end


function M.new(o)

  assert(o.buttonSize, "o.buttonSize required")
  assert(o.tileBaseDir, "o.tileBaseDir required")

  local buttonSize = o.buttonSize
  local xMargin = buttonSize * 0.1
  local yMargin = buttonSize * 0.1


  local SCREEN_BOTTOM = display.actualContentHeight - display.screenOriginY
  local SCREEN_LEFT = display.screenOriginX
  local SCREEN_WIDTH = display.actualContentWidth

  -- By default located at screen bottom.
  local startY = display.actualContentHeight - display.screenOriginY - buttonSize / 2


    -- create drag-item scrollview
  local instance = widget.newDragItemsScrollView{
    backgroundColor = { 0.5, 0.5, 0.5, 0.9 },
    left = SCREEN_LEFT,
    top = SCREEN_BOTTOM - buttonSize,
    width = SCREEN_WIDTH,
    height = buttonSize,
    verticalScrollDisabled = true
  }

  instance.buttonSize = o.buttonSize
  instance.tileBaseDir = o.tileBaseDir
  instance.margin = 10
  instance.index = 0
  instance.levelEditor = o.levelEditor

  M.addTiles(instance)
  M.addTrashButton(instance)
  M.addSaveButton(instance)

  M.instance = instance

  return instance
end


--
-- Add a button that stays in the Toolbar even if
-- dragged. Reacts to a tap.
--
function M.addStaticButton(self, button, tapListener)
  positionItemInScrollViewAndIncreaseIndex(self, button)

  self:add(button, nil, nil, nil, nil, nil)
  button:addEventListener("tap", tapListener)
end


function M.addDragableButton(self, button, draggedListener)
  positionItemInScrollViewAndIncreaseIndex(self, button)
  self:add(button, draggedListener, -90, 140)
end

-- 1. Loads tiles from the given tilesLocation.
-- 2. Shows them in the toolbar
function M.addTiles(self)
  local dir = self.tileBaseDir
  local path = system.pathForFile(dir, system.ResourceDirectory )
  local tiles = io.getFiles(path)

  for _,tile in pairs(tiles) do

    if string.ends(tile, ".png") and not string.ends(tile, "2x.png") then
      local fileName = dir .. "/" .. tile
      local image = display.newImageRect(fileName, system.ResourceDirectory, self.buttonSize, self.buttonSize)
      image.image = tile
      image.fileLocation = {
        fileName = fileName,
        baseDir = system.ResourceDirectory
      }

      M.addDragableButton(self, image, tileDraggedListener)
    end
  end

end

function M.addTrashButton(self)
  local button = widget.newFontAwesomeButton({
    label = "",
    fontAwesomeFont = "regular",
    fontSize = self.buttonSize * 0.6
  })

  local tapListener = function()
    M.instance.levelEditor:removeBlockOrBug()

    return true
  end

  M.addStaticButton(self, button, tapListener)
end


function M.addCloseButton(self)
  local button = widget.newFontAwesomeButton({
    label = "",
    fontAwesomeFont = "solid",
    fontSize = self.buttonSize * 0.6
  })

  local tapListener = function()

    -- We save here
    -- levelMapObject:saveLevelMap(mapData)

    self:clean()

  end

  M.addStaticButton(self, button, tapListener)
end


function M.addSaveButton(self)
  local button = widget.newFontAwesomeButton({
    label = "",
    fontAwesomeFont = "regular",
    fontSize = self.buttonSize * 0.6
  })

  local tapListener = function()
    M.instance.levelEditor:saveLevel()
  end

  M.addStaticButton(self, button, tapListener)
end



return M