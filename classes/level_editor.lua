-- Level Editor
-- Extends scenes/game.lua, classes/bug.lua and classes/block.lua to support visual level editing.
local physics = require('physics')

local _M = {}

local bug = require('classes.bug')
bug._newBug = bug.newBug
local block = require('classes.block')
block._newBlock = block.newBlock

local function pr(s, ...)
    print('Level Editor: ' .. tostring(s), ...)
end

local function printSettings(self)
    if self.editor.mode == 'bug' then
        pr('mode - ' .. self.editor.mode)
    else
        if self.editor.shape == 'circle' then
            pr('mode - ' .. self.editor.mode .. ', material - ' .. self.editor.material .. ', shape - ' .. self.editor.shape)
        else
            pr('mode - ' .. self.editor.mode .. ', material - ' .. self.editor.material .. ', shape - ' .. self.editor.shape .. ', index - ' .. self.editor.index)
        end
    end
end

local function selectMaterial(self, material)
    self.editor.material = material
    self:printSettings()
end

local function selectShape(self, shape)
    self.editor.shape = shape
    self:printSettings()
end

local function selectIndex(self, index)
    self.editor.index = index
    self:printSettings()
end

local function switchMode(self)
    if self.editor.mode == 'block' then
        self.editor.mode = 'bug'
    else
        self.editor.mode = 'block'
    end
    self:printSettings()
end

local function switchPhysics(self)
    if not physics.isPaused then
        physics.pause()
    else
        physics.start()
    end
    physics.isPaused = not physics.isPaused
    pr('physics paused - ' .. tostring(physics.isPaused))
end

local function switchPhysicsDrawMode(self)
    if physics.drawMode == 'normal' then
        physics.setDrawMode('hybrid')
        physics.drawMode = 'hybrid'
    elseif physics.drawMode == 'hybrid' then
        physics.setDrawMode('debug')
        physics.drawMode = 'debug'
    else
        physics.setDrawMode('normal')
        physics.drawMode = 'normal'
    end
    pr('draw mode - ' .. physics.drawMode)
end

local function addBlockOrBug(self, tile)
    if not _M.currentElement then
        if not self.editor.x then
            pr('select position')
            return
        end

        local tilewidth, tileheight = self.map.map.tilewidth, self.map.map.tileheight
        if self.editor.mode == 'tile' then
            local b = block.newBlock({
                g = self.map.physicsGroup,
                x = self.editor.x,
                y = self.editor.y,
                material = self.editor.material,
                name = tile.image,
                width = tilewidth,
                height = tileheight,
                baseDir = tile.baseDir
            })
            b.name = tile.image
            b.baseDir = tile.baseDir
            table.insert(self.blocks, b)
        elseif self.editor.mode == 'bug' then
            local b = bug.newBug({g = self.map.physicsGroup, x = self.editor.x, y = self.editor.y})
            table.insert(self.bugs, b)
        else
            local name = self.editor.shape
            if name == 'rectangle' then
                name = name .. self.editor.index
            end
            local b = block.newBlock({
                g = self.map.physicsGroup,
                x = self.editor.x, y = self.editor.y,
                material = self.editor.material,
                name = name
            })
            table.insert(self.blocks, b)
        end
    else
        pr('something is selected')
    end
end

local function rotateBlock(self, dir)
    if _M.currentElement and _M.currentElement.isBlock then
        if dir == 'counterclockwise' then
            dir = -1
        else
            dir = 1
        end
        local step = 5
        _M.currentElement.rotation = math.floor((_M.currentElement.rotation + dir * step) / step) * step
        pr('rotated')
    else
        pr('nothing is selected')
    end
end

local function removeBlockOrBug(self)
    if _M.currentElement then
        if _M.currentElement.isBug then
            table.remove(self.bugs, table.indexOf(self.bugs, _M.currentElement))
        elseif _M.currentElement.isBlock then
            table.remove(self.blocks, table.indexOf(self.blocks, _M.currentElement))
        end
        _M.currentElement:removeSelf()
        _M.currentElement = nil
        pr('removed')
    else
        pr('nothing is selected')
    end
end

local function saveLevel(self)
    package.loaded['levels.' .. self.levelId] = nil
    local s = 'return {\n'
    s = s .. '\tmap = ' .. self.level.map .. ',\n'
    s = s .. '\tcannon = {mapX = ' .. self.level.cannon.mapX .. ', mapY = ' .. self.level.cannon.mapY .. '},\n'
    s = s .. '\tammo = {'
    for i = 1, #self.level.ammo do
        s = s .. '\'' .. self.level.ammo[i] .. '\''
        if i < #self.level.ammo then
            s = s .. ', '
        end
    end
    s = s .. '},\n'

    s = s .. '\tbugs = {\n'
    for i = 1, #self.bugs do
        local b = self.bugs[i]
        if b.x then
            s = s .. '\t\t{x = ' .. math.floor(b.x) .. ', y = ' .. math.floor(b.y) .. '}'
            if i < #self.bugs then
                s = s .. ',\n'
            else
                s = s .. '\n'
            end
        end
    end
    s = s .. '\t},\n'

    s = s .. '\tblocks = {\n'
    for i = 1, #self.blocks do
        local b = self.blocks[i]
        if b.rotation then
            b.rotation = b.rotation % 360
            if b.rotation < 5 then
                b.rotation = 0
            elseif math.abs(b.rotation - 90) < 5 then
                b.rotation = 90
            elseif math.abs(b.rotation - 180) < 5 then
                b.rotation = 180
            elseif math.abs(b.rotation - 270) < 5 then
                b.rotation = 270
            elseif math.abs(b.rotation - 360) < 5 then
                b.rotation = 0
            end
            s = s .. '\t\t{material = \'' .. b.material .. '\', name = \'' .. b.name .. '\'' ..
                ', x = ' .. math.floor(b.x) .. ', y = ' .. math.floor(b.y) .. ', rotation = ' .. math.floor(b.rotation)

            if b.baseDir then
                s = s .. ', baseDir=\'' .. b.baseDir .. '\''
            end

            s = s ..  '}'

            if i < #self.blocks then
                s = s .. ',\n'
            else
                s = s .. '\n'
            end
        end
    end
    s = s .. '\t},\n'
    s = s .. '}\n'
    local path = system.pathForFile('levels/' .. self.levelId .. '.lua', system.ResourceDirectory)
    local file = io.open(path, 'w')
    if file then
        file:write(s)
        io.close(file)
    end
    pr('level ' .. self.levelId .. ' saved')
end

local function enableKeyboard(self)
    pr([[instructions:
Select material: [W] wood, [S] stone.
Select shape: [C] circle, [R] rectangle.
Select index: keys from [1] to [8].
[B] switch block/bug.
[A] add block/bug.
Block rotation: [<] counterclockwise, [>] clockwise.
[X] remove block/bug.
[P] start/stop physics.
[D] draw mode for physics - normal, hybrid, debug.
[`] save level.

1. Select element properties.
2. Click on where you want to add an element and then press [A].
3. Modify the element if needed (drag to move, rotate with [<] or [>] while touching or remove with [X]).
4. Save level with [`].
    ]])
    function _M.key(event)
        local key = event.keyName
        if event.phase == 'down' then
            if key == 'w' then
                self:selectMaterial('wood')
            elseif key == 's' then
                self:selectMaterial('stone')
            elseif key == 'c' then
                self:selectShape('circle')
            elseif key == 'r' then
                self:selectShape('rectangle')
            elseif key == ',' then
                self:rotateBlock('counterclockwise')
            elseif key == '.' then
                self:rotateBlock('clockwise')
            elseif key == 'b' then
                self:switchMode()
            elseif key == 'a' then
                self:addBlockOrBug()
            elseif key == 'x' then
                self:removeBlockOrBug()
            elseif key == 'p' then
                self:switchPhysics()
            elseif key == 'd' then
                self:switchPhysicsDrawMode()
            elseif key == '`' then
                self:saveLevel()
            elseif tonumber(key) and tonumber(key) >= 1 and tonumber(key) <= 8 then
                self:selectIndex(tonumber(key))
            end
        end
    end
    Runtime:addEventListener('key', _M.key)
end


local function toMapXY(self, x, y)
  local localX, localY = self.map.group:contentToLocal(x, y)
  -- print("toTiledXY local: ", localX, localY)

  -- x coordinates have floor since x starts from 0 in Tiled coordinates
  -- y coordinates have ceil since y start from tile size in Tiled coordinates
  local tilewidth, tileheight = self.map.map.tilewidth, self.map.map.tileheight

  local rvX, rvY =
    math.floor( x / tilewidth) * tilewidth,
    math.floor( y / tileheight) * tileheight

  -- rvX, rvY = rvX + tilewidth/2, rvY + tileheight/2

  print("toTiledXY after: ", rvX, rvY)

  return rvX, rvY
end


local function selectTile(self, event)
  local super = self

  local map = super.map.map
  local w, h = map.width, map.height
  local tilewidth, tileheight = map.tilewidth, map.tileheight
  --local map = super.map

  local findTile = function(map, event)
    local tileX, tileY = self:toMapXY(event.x, event.y)

    for i = 1, #self.blocks do
        local b = self.blocks[i]
        local blockX, blockY = self:toMapXY(b.x, b.y)
        if tileX == blockX and tileY == blockY then
          print (tileX, tileY, xPos, yPos)
          print("Tile found")
          _M.currentElement = b
          return tileX, tileY
        end
    end
    -- local tileX, tileY = event.x, event.y

--    for i = 1, #map.layers do
--      local l = map.layers[i]
--      if l.type == 'tilelayer' then
--        local d = l.data
--            local gid
--            local y = 0
--            local x = 0
--            for y = 0, h - 1 do
--                for x = 0, w - 1 do
--                    gid = d[x + y * w + 1]
--                    local xPos, yPos = x * tilewidth, y * tileheight

--                    if gid > 0 and tileX == xPos and tileY == yPos then
--                      print (tileX, tileY, xPos, yPos, gid)
--                      print("Tile found")
--                      _M.currentElement = event.target
--                      return gid, tileX, tileY
--                    end
--                end
--            end
--      elseif l.type == 'objectgroup' then
--        for j = 1, #l.objects do
--          local o = l.objects[j]
--          if o.properties.x == tileX and o.properties.y == tileY then
--            _M.currentElement = event.target
--            print("Object found")
--          end
--        end
--      end
--    end
  end

  findTile(super.map.map, event)

  -- check if there is an item in the map at this location



  -- if there is, add a rect to indicate selection
--  local rect = display.newRect(super.editor.x, super.editor.y, super.map.map.tilewidth, super.map.map.tileheight)
--  rect.isVisible = true
--  rect.isHitTestable = true

end


local function selectTileXY(self, event)
  self:setEditorPosition(event)

  self:selectTile({
    target = event.target,
    x = self.editor.x,
    y = self.editor.y
  })

end


local function setEditorPosition(self, event)
  -- _M.currentElement = nil

  local editor = self.editor
  local x, y = self.map.physicsGroup:contentToLocal(event.x, event.y)

  -- So far we have only set editor position to be in the map local coordinates.
  -- We still want to snap the position to the middle of each tile
  local tilewidth, tileheight = self.map.map.tilewidth, self.map.map.tileheight
  x, y =
    math.floor( x / tilewidth) * tilewidth,
    math.floor( y / tileheight) * tileheight

  editor.x, editor.y = x + tilewidth / 2, y + tileheight /2
end


local function enableTouch(self)
    local rect = display.newRect(self.view, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
    rect.isVisible = false
    rect.isHitTestable = true
    local super = self
    function rect:touch(event)
        if event.phase == 'began' then
            -- super.editor.x, super.editor.y = super.map.physicsGroup:contentToLocal(event.x, event.y)
            -- super.editor.x, super.editor.y = math.floor(super.editor.x), math.floor(super.editor.y)
            --super:setEditorPosition(event)
            --pr('position - ' .. super.editor.x .. ', ' .. super.editor.y)

            super:selectTileXY(event)
        end
    end
    rect:addEventListener('touch')
end

local function elementTouch(event)
    local self = event.target
    if event.phase == 'began' then
        display.getCurrentStage():setFocus(self, event.id)
        self.isFocused = true
        self.isBodyActive = false
        self.xStart, self.yStart = self.x, self.y
        _M.currentElement = event.target
    elseif self.isFocused then
        if event.phase == 'moved' then
            self.x, self.y = self.xStart + event.x - event.xStart, self.yStart + event.y - event.yStart
        else
            display.getCurrentStage():setFocus(self, nil)
            self.isFocused = false
            self.isBodyActive = true
            -- _M.currentElement = nil
        end
    end
    return true
end

function bug.newBug(params)
    local b = bug._newBug(params)
    b.isBug = true
    b:addEventListener('touch', elementTouch)
    return b
end

function block.newBlock(params)
    local b = block._newBlock(params)
    b.isBlock = true
    b.material = params.material
    b.name = params.name
    b:addEventListener('touch', elementTouch)
    return b
end


local function drawTileBorders(self)
  local map = self.map.map
  local w, h = map.width, map.height

  local color = { 0.1, 0.1, 0.1, 0.5 }

  for i = 1, w + 1 do
    local line = display.newLine(
      self.map.group,
      (i - 1) * map.tilewidth,
      display.screenOriginY,
      (i -1) * map.tilewidth,
      map.tileheight * h)
    line:setStrokeColor(unpack(color))
    if i == 1 then
      line.strokeWidth = 10
    elseif i == w + 1 then
      line.strokeWidth = 10
    else
      line.strokeWidth = 2
    end
    line.isHitTestable = false
  end

  for i = 1, h + 1 do
    local line = display.newLine(
      self.map.group,
      display.screenOriginX,
      (i - 1) * map.tileheight,
      w * map.tilewidth,
      (i - 1) * map.tileheight)
    line:setStrokeColor(unpack(color))
    if i == 1 then
      line.strokeWidth = 10
    elseif i == h + 1 then
      line.strokeWidth = 10
    else
      line.strokeWidth = 2
    end
    line.isHitTestable = false
  end
end


function _M.enableLevelEditor(self)
    pr('activated')
    self.printSettings = printSettings
    self.enableKeyboard = enableKeyboard
    self.enableTouch = enableTouch
    self.selectMaterial = selectMaterial
    self.selectShape = selectShape
    self.selectIndex = selectIndex
    self.switchMode = switchMode
    self.switchPhysics = switchPhysics
    self.switchPhysicsDrawMode = switchPhysicsDrawMode
    self.saveLevel = saveLevel
    self.addBlockOrBug = addBlockOrBug
    self.rotateBlock = rotateBlock
    self.removeBlockOrBug = removeBlockOrBug

    -- These migh be better at tiled.lua but since we did not want
    -- to touch too many files, these are now here.
    self.drawTileBorders = drawTileBorders
    self.selectTile = selectTile
    self.selectTileXY = selectTileXY
    self.setEditorPosition = setEditorPosition
    -- self.findTile = findTile
    self.toMapXY = toMapXY

    self.editor = {
        material = 'wood',
        mode = 'block',
        shape = 'rectangle',
        index = 1
    }
    physics.drawMode = 'normal'

    self:enableKeyboard()

    timer.performWithDelay(2000, function()
        self:enableTouch()
    end)

    function self:hide(event)
        if event.phase == 'will' then
            Runtime:removeEventListener('key', _M.key)
        end
    end
    self:addEventListener('hide')
end

return _M
