/// @function		UIElement();
/// @description	Constructor for UI elements.
function UIElement() constructor {
	// Position, Size and Formatting
	position = {local : {x : 0, y : 0}, global : {x : 0, y : 0}, offset : {x : 0, y : 0}};
	width = {current : 1, minimum : 1, maximum : -1, adjust : UI_ADJUST_MODE.FIXED};
	height = {current : 1, minimum : 1, maximum : -1, adjust : UI_ADJUST_MODE.FIXED};
	anchor = {corner : UI_CORNER.TOP_LEFT, target : {element : noone, position : UI_ANCHOR.TOP_LEFT}};
	padding = {horizontal : 0, vertical : 0};
	
	// Surface
	surface = -1;
	
	// Parent / Child elements
	children = ds_list_create();
	parent = noone;
	
	// Mouse interaction
	blockMouse = true;
	blockChildren = true;
	isClickable = false;
	
	#region Settings functions
	/// @function				SetAnchor(corner, targetElement, targetAnchorPos);
	/// @description			Sets the anchor side and object of the UI element.
	/// @param {Real} corner		The corner of the UI element that should be attached.
	/// @param {Struct} targetElement	The target UI element the corner should be attached to.
	/// @param {Real} targetAnchorPos	The anchor position of the target object where to attach.
	static SetAnchor = function(corner, targetElement, targetAnchorPos) {
		anchor.corner = corner;
		anchor.target.element = targetElement;
		anchor.target.position = targetAnchorPos;
	};
	
	/// @function			SetPadding(horizontal, vertical);
	/// @description		Sets the horizontal and vertical padding of the UI element.
	/// @param {Real} horizontal	The new horizontal padding of the UI element.
	/// @param {Real} vertical	The new vertical padding of the UI element.
	static SetPadding = function(horizontal, vertical) {
		padding.horizontal = horizontal;
		padding.vertical = vertical;
	};
	
	/// @function			SetMouseInteraction(blockMouse, blockChildren, isClickable);
	/// @description		Sets the mouse interaction behavior of the UI element.
	/// @param {Bool} blockMouse	Does the UI element block the mouse from interacting with the game?
	/// @param {Bool} blockChildren	Does the UI element block the checking of child elements?
	/// @param {Bool} isClickable	Is the UI element clickable?
	static SetMouseInteraction = function(blockMouse, blockChildren, isClickable) {
		self.blockMouse = blockMouse;
		self.blockChildren = blockChildren;
		self.isClickable = isClickable;
	};
	
	/// @function			SetOffset(offsetX, offsetY);
	/// @description		Sets the horizontal and vertical offsets of the UI element.
	/// @param {Real} offsetX	The new horizontal offset of the UI element.
	/// @param {Real} offsetY	The new vertical offset of the UI element.
	static SetOffset = function(offsetX, offsetY) {
		position.offset.x = offsetX;
		position.offset.y = offsetY;
	};
	
	/// @function				SetDimensions(widthMin, widthMax, widthAdjust, heightMin, heightMax, heightAdjust);
	/// @description			Sets the dimensions of the UI element.
	/// @param {Real} widthMin		The minimum width of the UI element.
	/// @param {Real} widthMax		The maximum width of the UI element.
	/// @param {Real} widthAdjust	        The automatic adjustment behaviour of the width.
	/// @param {Real} heightMin		The minimum height of the UI element.
	/// @param {Real} heightMax		The maximum height of the UI element.
	/// @param {Real} heightAdjust	        The automatic adjustment behaviour of the height.
	static SetDimensions = function(widthMin, widthMax, widthAdjust, heightMin, heightMax, heightAdjust) {
		width.minimum = widthMin;
		width.maximum = widthMax;
		width.adjust = widthAdjust;
		
		height.minimum = heightMin;
		height.maximum = heightMax;
		height.adjust = heightAdjust;
	};
	
	/// @function			AddChild(child);
	/// @description		Adds a child element to the UI element.
	/// @param {Struct} child	The child element to add.
	static AddChild = function(child) {
		ds_list_add(children, child);
		child.parent = self;
	};
	#endregion
	#region Drawing functions
	/// @function			InitSurface(update);
	/// @description		Creates the surface and updates it.
	/// @param {Bool} update	Whether or not to update the surface after creating it.
	static InitSurface = function(update) {
		if (!surface_exists(surface)) {
			surface = surface_create(width.current * oMain.uiGridCurrentSize, height.current * oMain.uiGridCurrentSize);
			
			if (update) UpdateSurface();
		}
	};
	
	/// @function		UpdateSurface();
	/// @description	Updates the surface.
	static UpdateSurface = function() {
		InitSurface(false);
		
		// Assemble own surface
		surface_set_target(surface);
		draw_clear_alpha(c_black, 0);
		
		// Draw self
		DrawElement();
		
		// Draw self hovered
		var mouseHoveredUIElementsAmount = ds_list_size(oMain.mouseHoveredUIElements);
		for (var i = 0; i < mouseHoveredUIElementsAmount; i++) {
			if (oMain.mouseHoveredUIElements[| i] == self) {
				DrawElementHovered();
				break;
			}
		}
		
		// Draw child elements
		if (ds_exists(children, ds_type_list)) {
			var childrenAmount = ds_list_size(children);
			
			for (var i = 0; i < childrenAmount; i++) {
				children[| i].DrawSurface();
			}
		}
		
		// Reset surface target
		surface_reset_target();
	};
	
	/// @function		UpdateNestedSurface();
	/// @description	Updates the surface and the parent's surfaces until there is no parent higher in the hierarchy.
	static UpdateNestedSurface = function() {
		// Update own surface
		UpdateSurface();
		
		// Update parent
		if (parent != noone) {
			parent.UpdateNestedSurface();
		}
	};
	
	/// @function		DrawSurface();
	/// @description	Draws the surface. Override if needed.
	DrawSurface = function() {
		// Make sure the own surface exists
		InitSurface(true);
		
		// Draw surface
		draw_surface(surface, position.local.x * oMain.uiGridCurrentSize, position.local.y * oMain.uiGridCurrentSize);
	};
	
	/// @function		DrawElement();
	/// @description	Draws the UI element. Override if needed.
	DrawElement = function() {};
	
	/// @function		DrawElementHovered();
	/// @description	Draws the UI element's hovered indicator. Override if needed.
	DrawElementHovered = function() {
		draw_set_color($BECC7A);
		draw_line_width(0, 0, width.current * oMain.uiGridCurrentSize, 0, 1);
		draw_line_width(0, height.current * oMain.uiGridCurrentSize - 1, width.current * oMain.uiGridCurrentSize, height.current * oMain.uiGridCurrentSize - 1, 1);
		
		draw_line_width(0, -1, 0, height.current * oMain.uiGridCurrentSize, 1);
		draw_line_width(width.current * oMain.uiGridCurrentSize - 1, 0, width.current * oMain.uiGridCurrentSize - 1, height.current * oMain.uiGridCurrentSize, 1);
	};
	
	/// @function		DrawOwnTexts();
	/// @description	Draws own texts. Override if needed.
	DrawOwnTexts = function() {};
	
	/// @function		DrawAllTexts();
	/// @description	Draws all texts.
	static DrawAllTexts = function() {
		// Draw own texts
		DrawOwnTexts();
		
		// Draw all child elements texts
		if (ds_exists(children, ds_type_list)) {
			var childrenAmount = ds_list_size(children);
			
			for (var i = 0; i < childrenAmount; i++) {
				children[| i].DrawAllTexts();
			}
		}
	};
	#endregion
	#region Other functions
	/// @function			GetExpandedPosition(sideToExpand, startingPos);
	/// @description		Gets the maximum position an element's side can expand to.
	/// @param {Real} sideToExpand	The side that should be expanded.
	/// @param {Real} startingPos	The starting position.
	static GetExpandedPosition = function(sideToExpand, startingPos) {
		var cap = startingPos, newPos;
		
		// Make sure the children data structure exists
		if !ds_exists(parent.children, ds_type_list) return cap;
		
		// Get opposite side and block dimension
		var oppositeSide, blockDimension;
		switch (sideToExpand) {
			case UI_SIDE.LEFT:
				oppositeSide = UI_SIDE.RIGHT;
				blockDimension = UI_DIMENSION.VERTICAL;
				break;
			case UI_SIDE.RIGHT:
				oppositeSide = UI_SIDE.LEFT;
				blockDimension = UI_DIMENSION.VERTICAL;
				break;
			case UI_SIDE.TOP:
				oppositeSide = UI_SIDE.BOTTOM;
				blockDimension = UI_DIMENSION.HORIZONTAL;
				break;
			case UI_SIDE.BOTTOM:
				oppositeSide = UI_SIDE.TOP;
				blockDimension = UI_DIMENSION.HORIZONTAL;
				break;
		}
		
		// Get child amount
		var childrenAmount = ds_list_size(parent.children);
		var currentTargetElement;
		
		// Loop through parent's children
		for (var i = 0; i < childrenAmount; i++) {
			// Get current child
			currentChild = parent.children[| i];
			
			// Skip self
			if (currentChild == self) continue;
			
			// Check if the child element blocks the expanded side
			if (blockDimension == UI_DIMENSION.VERTICAL) {
				var childYMin = currentChild.position.local.y;
				var childYMax = currentChild.position.local.y + currentChild.height.current;
				var ownYMin = position.local.y;
				var ownYMax = position.local.y + height.current;
				if ((childYMin+1 < ownYMin+1 && childYMax < ownYMin+1) || (childYMin+1 > ownYMax && childYMax > ownYMax)) continue;
			} else {
				var childXMin = currentChild.position.local.x;
				var childXMax = currentChild.position.local.x + currentChild.width.current;
				var ownXMin = position.local.x;
				var ownXMax = position.local.x + width.current;
				if ((childXMin+1 < ownXMin+1 && childXMax < ownXMin+1) || (childXMin+1 > ownXMax && childXMax > ownXMax)) continue;
			}
			
			// Get new position
			newPos = GetTargetElementSidePosition(currentChild, oppositeSide);
			
			// Compare new position with current cap
			if (sideToExpand == UI_SIDE.LEFT || sideToExpand == UI_SIDE.TOP) {
				cap = min(cap, newPos);
			} else {
				cap = max(cap, newPos);
			}
		}
		
		// Return cap
		return cap;
	};
	
	/// @function			GetTargetElementSidePosition(element, side);
	/// @description		Gets the target bbox position of an UI element.
	/// @param {Struct} element	The target UI element.
	/// @param {Real} side		The side to get the position of.
	static GetTargetElementSidePosition = function(element, side) {
		switch (side) {
			case UI_SIDE.LEFT: return element.position.local.x;
			case UI_SIDE.RIGHT: return element.position.local.x + element.width.current;
			case UI_SIDE.TOP: return element.position.local.y;
			case UI_SIDE.BOTTOM: return element.position.local.y + element.height.current;
		}
	};
	
	/// @function		UpdateDimensions();
	/// @description	Updates the dimensions of the UI element and its child elements.
	static UpdateDimensions = function() {
		#region Update self
		// Set position
		var targetElement = anchor.target.element == noone ? parent : anchor.target.element;
		
		if (targetElement != noone) {
			if (targetElement == parent) {
				// Apply padding
				position.local.x = parent.padding.horizontal;
				position.local.y = parent.padding.vertical;
			} else {
				position.local.x = targetElement.position.local.x;
				position.local.y = targetElement.position.local.y;
			}
			
			switch (anchor.target.position) {
				case UI_ANCHOR.TOP_LEFT:
					break;
				case UI_ANCHOR.TOP_RIGHT:
					position.local.x += targetElement.width.current;
					break;
				case UI_ANCHOR.TOP_CENTER:
					position.local.x += floor(targetElement.width.current / 2);
					break;
				case UI_ANCHOR.MIDDLE_LEFT:
					position.local.y += floor(targetElement.height.current / 2);
					break;
				case UI_ANCHOR.MIDDLE_RIGHT:
					position.local.x += targetElement.width.current;
					position.local.y += floor(targetElement.height.current / 2);
					break;
				case UI_ANCHOR.MIDDLE_CENTER:
					position.local.x += floor(targetElement.width.current / 2);
					position.local.y += floor(targetElement.height.current / 2);
					break;
				case UI_ANCHOR.BOTTOM_LEFT:
					position.local.y += targetElement.height.current;
					break;
				case UI_ANCHOR.BOTTOM_RIGHT:
					position.local.x += targetElement.width.current;
					position.local.y += targetElement.height.current;
					break;
				case UI_ANCHOR.BOTTOM_CENTER:
					position.local.x += floor(targetElement.width.current / 2);
					position.local.y += targetElement.height.current;
					break;
			}
		} else {
			position.local.x = 0;
			position.local.y = 0;
		}
		
		// Apply position offsets
		position.local.x += position.offset.x;
		position.local.y += position.offset.y;
		
		// Apply minimum width and height
		width.current = width.minimum;
		height.current = height.minimum;
		
		// Temporary shift the element for the fill calculations
		var shiftX = 0, shiftY = 0, unshifted = false;
		switch (anchor.corner) {
			case UI_CORNER.TOP_LEFT:
				break;
			case UI_CORNER.TOP_RIGHT:
				position.local.x -= width.current;
				shiftX = width.current;
				break;
			case UI_CORNER.BOTTOM_LEFT:
				position.local.y -= height.current;
				shiftY = height.current;
				break;
			case UI_CORNER.BOTTOM_RIGHT:
				position.local.x -= width.current;
				position.local.y -= height.current;
				shiftX = width.current;
				shiftY = height.current;
				break;
		}
		
		// Adjust width
		if (width.adjust == UI_ADJUST_MODE.FILL) {
			if (parent == noone) {
				width.current = oCamera.windowResolution.x div oMain.uiGridCurrentSize;
			} else {
				switch (anchor.corner) {
					case UI_CORNER.TOP_LEFT:
					case UI_CORNER.BOTTOM_LEFT:
						var expandedPos = GetExpandedPosition(UI_SIDE.RIGHT, position.local.x);
						if (expandedPos == position.local.x) expandedPos = parent.width.current;
						
						position.local.x += shiftX;
						position.local.y += shiftY;
						unshifted = true;
						
						width.current = clamp(expandedPos - position.local.x, width.minimum, min(width.maximum > 0 ? width.maximum: 9999, parent.width.current - parent.padding.horizontal * 2));
						break;
					case UI_CORNER.TOP_RIGHT:
					case UI_CORNER.BOTTOM_RIGHT:
						var expandedPos = GetExpandedPosition(UI_SIDE.LEFT, position.local.x);
						if (expandedPos == position.local.x) expandedPos = 0;
						
						position.local.x += shiftX;
						position.local.y += shiftY;
						unshifted = true;
						
						width.current = clamp(position.local.x - expandedPos, width.minimum, min(width.maximum > 0 ? width.maximum: 9999, parent.width.current - parent.padding.horizontal * 2));
						break;
				}
			}
		}
		
		// Temporary shift the element for the fill calculations
		if (!unshifted) {
			position.local.x += shiftX;
			position.local.y += shiftY;
		}
		switch (anchor.corner) {
			case UI_CORNER.TOP_LEFT:
				break;
			case UI_CORNER.TOP_RIGHT:
				position.local.x -= width.current;
				shiftX = width.current;
				break;
			case UI_CORNER.BOTTOM_LEFT:
				position.local.y -= height.current;
				shiftY = height.current;
				break;
			case UI_CORNER.BOTTOM_RIGHT:
				position.local.x -= width.current;
				position.local.y -= height.current;
				shiftX = width.current;
				shiftY = height.current;
				break;
		}
		unshifted = false;
		
		// Adjust height
		if (height.adjust == UI_ADJUST_MODE.FILL) {
			if (parent == noone) {
				height.current = oCamera.windowResolution.y div oMain.uiGridCurrentSize;
			} else {
				switch (anchor.corner) {
					case UI_CORNER.TOP_LEFT:
					case UI_CORNER.TOP_RIGHT:
						var expandedPos = GetExpandedPosition(UI_SIDE.BOTTOM, position.local.y);
						if (expandedPos == position.local.y) expandedPos = parent.height.current;
						
						position.local.x += shiftX;
						position.local.y += shiftY;
						unshifted = true;
						
						height.current = clamp(expandedPos - position.local.y, height.minimum, min(height.maximum > 0 ? height.maximum: 9999, parent.height.current - parent.padding.vertical * 2));
						break;
					case UI_CORNER.BOTTOM_LEFT:
					case UI_CORNER.BOTTOM_RIGHT:
						var expandedPos = GetExpandedPosition(UI_SIDE.TOP, position.local.y);
						if (expandedPos == position.local.y) expandedPos = 0;
						
						position.local.x += shiftX;
						position.local.y += shiftY;
						unshifted = true;
						
						height.current = clamp(position.local.y - expandedPos, height.minimum, min(height.maximum > 0 ? height.maximum: 9999, parent.height.current - parent.padding.vertical * 2));
						break;
				}
			}
		}
		
		// Remove temporary shift
		if (!unshifted) {
			position.local.x += shiftX;
			position.local.y += shiftY;
		}
		
		// Adjust position
		switch (anchor.corner) {
			case UI_CORNER.TOP_LEFT:
				break;
			case UI_CORNER.TOP_RIGHT:
				position.local.x -= width.current;
				break;
			case UI_CORNER.BOTTOM_LEFT:
				position.local.y -= height.current;
				break;
			case UI_CORNER.BOTTOM_RIGHT:
				position.local.x -= width.current;
				position.local.y -= height.current;
				break;
		}
		
		// Get global position
		position.global.x = position.local.x;
		position.global.y = position.local.y;
		if (parent != noone) {
			position.global.x += parent.position.global.x;
			position.global.y += parent.position.global.y;
		}
		
		// Free surface
		if (surface_exists(surface)) surface_free(surface);
		
		// Update text scales
		UpdateTextScale();
		#endregion
		
		// Update child elements
		if (ds_exists(children, ds_type_list)) {
			var childrenAmount = ds_list_size(children);
			
			for (var i = 0; i < childrenAmount; i++) {
				children[| i].UpdateDimensions();
			}
		}
	};
	
	/// @function		Cleanup();
	/// @description	Clear memory.
	static Cleanup = function() {
		// Individual cleanup
		CleanupAdditionalStuff();
		
		// Destroy surface
		if (surface_exists(surface)) surface_free(surface);
		
		// Destroy children
		if (ds_exists(children, ds_type_list)) {
			var childrenAmount = ds_list_size(children);
			
			for (var i = 0; i < childrenAmount; i++) {
				children[| i].Cleanup();
			}
			
			ds_list_destroy(children);
		}
	};
	
	/// @function		CleanupAdditionalStuff();
	/// @description	Additional cleanup. Override if needed.
	CleanupAdditionalStuff = function() {};
	
	/// @function		UpdateTextScale();
	/// @description	Updates the scale of text elements. Override if needed.
	UpdateTextScale = function() {};
	
	/// @function		CheckMouseHoversElement();
	/// @description	Checks, if the mouse is inside the bounds of the UI element. Override if needed.
	/// @return {Bool}
	CheckMouseHoversElement = function() {
		var x1 = position.global.x * oMain.uiGridCurrentSize;
		var y1 = position.global.y * oMain.uiGridCurrentSize;
		var x2 = (position.global.x + width.current) * oMain.uiGridCurrentSize;
		var y2 = (position.global.y + height.current) * oMain.uiGridCurrentSize;
		
		return point_in_rectangle(window_mouse_get_x(), window_mouse_get_y(), x1, y1, x2, y2);
	};
	
	/// @function		UpdateMouseState();
	/// @description	Checks if the mouse hovers the UI element or one of its children.
	static UpdateMouseState = function() {
		// Check self
		if (blockMouse) {
			if (CheckMouseHoversElement()) {
				// Set the mouse focus to the UI
				oMain.mouseFocus = MOUSE_FOCUS.UI;
				
				if (isClickable) {
					// Set new hovered element
					ds_list_add(oMain.mouseHoveredUIElements, self);
					
					if (blockChildren) return;
				}
			}
		}
		
		// Check children
		if (ds_exists(children, ds_type_list)) {
			var childrenAmount = ds_list_size(children);
			
			for (var i = 0; i < childrenAmount; i++) {
				children[| i].UpdateMouseState();
			}
		}
	};
	
	/// @function					OnClick(mouseButton, mouseWheelState);
	/// @description				Function that gets executed when clicking on the UI element. Override if needed.
	/// @param {Constant.MouseButton} mouseButton	The mouse button pressed.
	/// @param {Real} mouseWheelState		The state of the mouse wheel.
	OnClick = function(mouseButton, mouseWheelState) {
		show_debug_message("A button without assigned function was clicked!");
	};
	#endregion
};

/// @function		UIComponent();
/// @description	Constructor for UI components.
function UIComponent() constructor {
	#region Functions
	/// @function		Draw();
	/// @description	Draws the UI component. Override.
	Draw = function() {};
	#endregion
};
