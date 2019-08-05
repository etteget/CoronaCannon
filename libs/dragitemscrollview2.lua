local widget = require("widget")

-- This is modified from:
-- https://code.coronalabs.com/code/scrollview-draggable-item-adding
-- by horacebury


local function lengthOf( ax, ay, bx, by )
	local width, height = bx-ax, by-ay
	return (width*width + height*height) ^ 0.5 -- math.sqrt(width*width + height*height)
end

function widget.newDragItemsScrollView( params )
	local scrollview = widget.newScrollView( params )

	function scrollview:add( item, listener, angle, radius, touchthreshold )
		scrollview:insert( item )

		local touchevent = nil

		touchthreshold = touchthreshold or display.actualContentWidth*.1

    local function isWithinRadiusModified(e)
      local calculatedAngle = math.atan2( e.y - e.yStart, e.x - e.xStart ) * 180/math.pi
			return (calculatedAngle > angle - radius/2 and calculatedAngle < angle + radius/2)
		end


		local function startDragByTouch()
      -- We do handle start of dragging here, not actual move etc.
      -- Therefore touchevent set to nil.
      if not touchevent then return end

			listener( item, touchevent )
      touchevent = nil
		end

		local touch = function( event )
			touchevent = event

			if (event.phase == "began") then
				display.currentStage:setFocus( event.target, event.id )
				event.target.hasFocus = true

			elseif (event.target.hasFocus) then
				if (event.phase == "moved") then
          if (lengthOf( event.xStart, event.yStart, event.x, event.y ) > touchthreshold) then
						if (angle and radius and isWithinRadiusModified(event)) then
              display.currentStage:setFocus( event.target, nil )
              event.target.hasFocus = nil

              startDragByTouch()
						else
							scrollview:takeFocus(event)
						end
					end
				else
					display.currentStage:setFocus( event.target, nil )
					event.target.hasFocus = nil
				end
			end

			return true
		end

		item:addEventListener( "touch", touch )
	end

	return scrollview
end