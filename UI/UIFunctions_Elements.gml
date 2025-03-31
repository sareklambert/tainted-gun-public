/// @function		UICanvasElement();
/// @description	Constructor for a UICanvasElement.
function UICanvasElement() : UIElement() constructor {
	SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FILL);
	blockMouse = false;
};

/// @function					UIBoxElement(color, alpha, sprite);
/// @description				Constructor for a UIBoxElement.
/// @param {Constant.Color} color		The color of the box.
/// @param {Real} alpha				The alpha of the box.
/// @param {Asset.GMSprite} [sprite]	The sprite of the box (optional).
function UIBoxElement(color, alpha, sprite) : UIElement() constructor {
	// Get input values
	self.color = color;
	self.alpha = alpha;
	self.sprite = is_undefined(sprite) ? -1 : sprite;
	
	// Define functions
	DrawElement = function() {
		// Draw the box
		if (sprite == -1) {
			draw_clear_alpha(color, alpha);
		} else {
			Draw9SliceExt(sprite, 0, 0, 0, oCamera.zoom.base, width.current * oMain.uiGridCurrentSize, height.current * oMain.uiGridCurrentSize, c_white, 1);
		}
	};
};

/// @function				UILabelElement(text, color, alpha, sprite);
/// @description			Constructor for a UILabelElement.
/// @param {String} text		The text string.
/// @param {Constant.Color} color	The color of the box.
/// @param {Real} alpha			The alpha of the box.
/// @param {Asset.GMSprite} [sprite]	The sprite of the box (optional).
function UILabelElement(text, color, alpha, sprite) : UIBoxElement(color, alpha, sprite) constructor {
	// Create text component
	labelText = new UITextComponent(text);
	
	// Define functions
	DrawOwnTexts = function() {
		labelText.Draw((position.global.x + width.current / 2) * oMain.uiGridCurrentSize, (position.global.y + height.current / 2) * oMain.uiGridCurrentSize);
	};
	
	UpdateTextScale = function() {
		labelText.textStruct.scale_to_box(width.current * oMain.uiGridCurrentSize, height.current * oMain.uiGridCurrentSize);
	};
};

/// @function				UILabeledContainerElement(labelText, containerVisible);
/// @description			Constructor for a UILabeledContainerElement.
/// @param {String} labelText		The text string.
/// @param {Bool} containerVisible	The color of the box.
function UILabeledContainerElement(labelText, containerVisible) : UIElement() constructor {
	// Create elements
	label = new UILabelElement(labelText, c_black, 0, sGCUIBox);
	
	if (containerVisible) {
		container = new UIBoxElement(c_black, 0, sGCUIBox);
	} else {
		container = new UIBoxElement(c_black, 0);
	}
	
	// Set elements' properties
	label.SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FIXED);
	container.SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FILL);
	container.SetAnchor(UI_CORNER.TOP_LEFT, label, UI_ANCHOR.BOTTOM_LEFT);
	
	// Add elements as children
	self.AddChild(label);
	self.AddChild(container);
};

/// @function				UIDropdownButtonElement(text, listIndex, dropdownElement);
/// @description			Constructor for a UIDropdownButtonElement.
/// @param {String} text		The text string.
/// @param {Real} listIndex		The index of the dropdown list this button refers to.
/// @param {Struct} dropdownElement	The dropdown element this button is a part of.
/// @param {Struct} targetCanvas	The target canvas this button is on.
function UIDropdownButtonElement(text, listIndex, dropdownElement, targetCanvas) : UIElement() constructor {
	self.listIndex = listIndex;
	self.dropdownElement = dropdownElement;
	self.targetCanvas = targetCanvas;
	
	// Create text component
	labelText = new UITextComponent("[c_gray]" + text, fa_left);
	
	OnClick = function(mouseButton, mouseWheelState) {
		if (mouseButton == mb_none || !mouse_check_button_pressed(mouseButton)) return;
		
		// Update dropdown element
		dropdownElement.listIndex.Set(listIndex);
		dropdownElement.UpdateText();
		
		// Invoke event
		EventInvoke(EVENT.ON_UI_ELEMENT_LIST, [self, dropdownElement.list]);
		
		// Clear popup canvas
		UnloadUICollections(targetCanvas);
	};
	
	CleanupAdditionalStuff = function() {
		// Update dropdown element
		dropdownElement.arrowSprite.yScale = 1;
		dropdownElement.isUnfolded = false;
		dropdownElement.UpdateNestedSurface();
	};
	
	DrawOwnTexts = function() {
		labelText.Draw((position.global.x + .2) * oMain.uiGridCurrentSize, (position.global.y + height.current / 2) * oMain.uiGridCurrentSize);
	};
	
	UpdateTextScale = function() {
		labelText.textStruct.scale_to_box(width.current * oMain.uiGridCurrentSize, height.current * oMain.uiGridCurrentSize);
	};
};

/// @function					UIDropdownElement(list, listIndex, boxColor, boxAlpha, boxSprite);
/// @description				Constructor for a UIDropdownElement.
/// @param {Id.DsList<String>} list		The list of options to use.
/// @param {Struct} listIndex			A reference to the variable holding the list index.
/// @param {Constant.Color} boxColor		The color of the box.
/// @param {Real} boxAlpha			The alpha of the box.
/// @param {Asset.GMSprite} [boxSprite]		The sprite of the box (optional).
function UIDropdownElement(list, listIndex, boxColor, boxAlpha, boxSprite) : UIElement() constructor {
	// Get input values
	self.list = list;
	self.listIndex = listIndex;
	self.boxColor = boxColor;
	self.boxAlpha = boxAlpha;
	self.boxSprite = boxSprite;
	
	// Set unfolded variable
	isUnfolded = false;
	
	// Create components
	labelText = {};
	arrowSprite = new UISpriteComponent(sGCUIDropdownArrow, 1, 1, 0, c_white, 1);
	
	// Set elements' properties
	self.SetMouseInteraction(true, true, true);
	
	// Define functions
	DrawElement = function() {
		// Draw the box
		if (boxSprite == -1) {
			draw_clear_alpha(boxColor, boxAlpha);
		} else {
			Draw9SliceExt(boxSprite, 0, 0, 0, oCamera.zoom.base, width.current * oMain.uiGridCurrentSize, height.current * oMain.uiGridCurrentSize, c_white, 1);
		}
		
		// Draw the dropdown arrow sprite
		arrowSprite.Draw((width.current - .7) * oMain.uiGridCurrentSize, .5 * oMain.uiGridCurrentSize);
	};
	
	UpdateText = function() {
		labelText = new UITextComponent("[c_gray]" + list[| listIndex.Get()], fa_left);
		UpdateTextScale();
	};
	
	DrawOwnTexts = function() {
		labelText.Draw((position.global.x + .2) * oMain.uiGridCurrentSize, (position.global.y + height.current / 2) * oMain.uiGridCurrentSize);
	};
	
	UpdateTextScale = function() {
		labelText.textStruct.scale_to_box(width.current * oMain.uiGridCurrentSize, height.current * oMain.uiGridCurrentSize);
	};
	
	OnClick = function(mouseButton, mouseWheelState) {
		if !(mouseButton != mb_none && mouse_check_button_pressed(mouseButton)) return;
		
		// Get options amount
		var optionsAmount = ds_list_size(list);
		if (optionsAmount < 2) return;
		
		// Get target canvas
		var targetCanvas = oGameChanger.uiCanvasPopup; // TEMP
		
		// Set unfolded state
		if (isUnfolded) {
			UnloadUICollections(targetCanvas);
			return;
		}
		isUnfolded = true;
		
		// Flip dropdown sprite
		arrowSprite.yScale = -1;
		UpdateNestedSurface();
		
		// Clear canvas
		UnloadUICollections(targetCanvas);
		
		// Create dropdown menu
		// Create elements
		container = new UIBoxElement(c_black, 0, sGCUIPopupBox);
		scrollView = new UIScrollViewElement(width.current - 1, optionsAmount - 1, false, false);
		scrollBar = new UIScrollBarElement(UI_SCROLLBAR_TYPE.VERTICAL, sGCUIBoxDarkNoLine, sGCUIScrollHandleBox);
		
		var currentButton, lastButton = -1;
		for (var i = 0; i < optionsAmount; i++) {
			// Exclude currently selected option
			if (i == listIndex.Get()) continue;
			
			// Create button
			currentButton = new UIDropdownButtonElement(list[| i], i, self, targetCanvas);
			
			// Set button properties
			if (lastButton != -1) {
				currentButton.SetAnchor(UI_CORNER.TOP_LEFT, lastButton, UI_ANCHOR.BOTTOM_LEFT);
			}
			currentButton.SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FIXED);
			currentButton.SetMouseInteraction(true, true, true);
			
			// Add to hierarchy
			scrollView.content.AddChild(currentButton);
			
			// Set last button
			lastButton = currentButton;
		}
	
		// Set elements' properties
		container.SetDimensions(width.current, -1, UI_ADJUST_MODE.FIXED, optionsAmount - 1, -1, UI_ADJUST_MODE.FIXED);
		container.SetOffset(position.global.x, position.global.y + 1);
		
		scrollView.SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FILL);
		scrollBar.SetDimensions(1, -1, UI_ADJUST_MODE.FIXED, 1, -1, UI_ADJUST_MODE.FILL);
		scrollBar.SetAnchor(UI_CORNER.TOP_RIGHT, container, UI_ANCHOR.TOP_RIGHT);
	
		// Add elements as children
		// Define hierarchy
		targetCanvas.AddChild(container);
		container.AddChild(scrollBar);
		container.AddChild(scrollView);
		
		// Update all UI elements' dimensions
		targetCanvas.UpdateDimensions();
	};
	
	// Set initial text
	UpdateText();
};

/// @function					UILabeledDropdownElement(labelText, list, listIndex);
/// @description				Constructor for a UILabeledDropdownElement.
/// @param {String} labelText			The text string.
/// @param {Id.DsList<String>} list		The color of the box.
/// @param {Struct} listIndex			A reference to the variable holding the list index.
function UILabeledDropdownElement(labelText, list, listIndex) : UIElement() constructor {
	// Create elements
	label = new UILabelElement(labelText, c_black, 0, sGCUIBox);
	dropdown = new UIDropdownElement(list, listIndex, c_black, 0, sGCUIBoxNoLineNoTop);
	
	// Set elements' properties
	label.SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FIXED);
	dropdown.SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FILL);
	dropdown.SetAnchor(UI_CORNER.TOP_LEFT, label, UI_ANCHOR.BOTTOM_LEFT);
	
	// Add elements as children
	self.AddChild(label);
	self.AddChild(dropdown);
};

/// @function		UIScrollBarElement(type, spriteBar, spriteHandle);
/// @description	Constructor for a UIScrollBarElement.
function UIScrollBarElement(type, spriteBar, spriteHandle) : UIElement() constructor {
	// Get input values
	self.type = type;
	self.spriteBar = spriteBar;
	self.spriteHandle = spriteHandle;
	
	// Scrollbar state
	handlePos = 0;
	
	// Create elements
	handle = new UIBoxElement(c_black, 0, spriteHandle);
	
	// Set elements' properties
	if (type == UI_SCROLLBAR_TYPE.HORIZONTAL) {
		handle.SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FILL);
	} else {
		handle.SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FILL);
	}
	
	// Add elements as children
	self.AddChild(handle);
	
	// Define functions
	DrawElement = function() {
		// Draw the bar
		draw_sprite_stretched(spriteBar, 0, 0, 0, width.current * oMain.uiGridCurrentSize, height.current * oMain.uiGridCurrentSize);
	};
};

/// @function			UIScrollViewElement(contentWidth, contentHeight, allowZoom, allowPan);
/// @param {Real} contentWidth	The width of the content.
/// @param {Real} contentHeight	The height of the content.
/// @param {bool} allowZoom	Whether or not to allow manual zoom.
/// @param {bool} allowPan	Whether or not to allow manual pan.
/// @description		Constructor for a UIScrollViewElement.
function UIScrollViewElement(contentWidth, contentHeight, allowZoom, allowPan) : UIElement() constructor {
	// Create elements
	content = new UIElement();
	
	// Set elements' properties
	content.SetDimensions(contentWidth, -1, UI_ADJUST_MODE.FIXED, contentHeight, -1, UI_ADJUST_MODE.FIXED);
	with (content) {
		scrollViewOffset = {x : 0, y : 0};
		zoom = 1;
		
		// Define functions
		DrawSurface = function() {
			// Make sure the own surface exists
			InitSurface(true);
			
			// Draw surface
			draw_surface_ext(surface, scrollViewOffset.x, scrollViewOffset.y, zoom, zoom, 0, c_white, 1);
		};
	}
	
	// Add elements as children
	self.AddChild(content);
	
	#region Define functions
	/// @function		SetScrollViewOffsetPercent(percentX, percentY);
	/// @description	Sets the scroll view offset of the content based on percentages 0-1.
	SetScrollViewOffsetPercent = function(percentX, percentY) {
		var maxOffsetX = width.current - content.width.current * content.zoom;
		var maxOffsetY = height.current - content.height.current * content.zoom;
		
		content.scrollViewOffset.x = percentX * maxOffsetX * oMain.uiGridCurrentSize;
		content.scrollViewOffset.y = percentY * maxOffsetY * oMain.uiGridCurrentSize;
	};
	
	/// @function		ClampScrollViewOffset();
	/// @description	Clamps the scroll view offset to the allowed range.
	ClampScrollViewOffset = function() {
		var maxOffsetX = width.current - content.width.current * content.zoom;
		var maxOffsetY = height.current - content.height.current * content.zoom;
		
		var lowX, lowY, highX, highY;
		if (maxOffsetX * oMain.uiGridCurrentSize > 0) {
			lowX = 0;
			highX = maxOffsetX * oMain.uiGridCurrentSize;
		} else {
			lowX = maxOffsetX * oMain.uiGridCurrentSize;
			highX = 0;
		}
		if (maxOffsetY * oMain.uiGridCurrentSize > 0) {
			lowY = 0;
			highY = maxOffsetY * oMain.uiGridCurrentSize;
		} else {
			lowY = maxOffsetY * oMain.uiGridCurrentSize;
			highY = 0;
		}
		
		content.scrollViewOffset.x = clamp(content.scrollViewOffset.x, lowX, highX);
		content.scrollViewOffset.y = clamp(content.scrollViewOffset.y, lowY, highY);
	};
	
	/// @function		SetZoom(newZoom);
	/// @description	Sets the new zoom factor of the content.
	SetZoom = function(newZoom) {
		// Get mouse pos
		var x1 = position.global.x * oMain.uiGridCurrentSize + content.scrollViewOffset.x;
		var y1 = position.global.y * oMain.uiGridCurrentSize + content.scrollViewOffset.y;
		var mouseX = (window_mouse_get_x() - x1) / content.zoom;
		var mouseY = (window_mouse_get_y() - y1) / content.zoom;
		var mouseXLast = mouseX;
		var mouseYLast = mouseY;
		
		// Apply zoom
		content.zoom = newZoom;
		
		// Correct scroll view offset
		x1 = position.global.x * oMain.uiGridCurrentSize + content.scrollViewOffset.x;
		y1 = position.global.y * oMain.uiGridCurrentSize + content.scrollViewOffset.y;
		mouseX = (window_mouse_get_x() - x1) / content.zoom;
		mouseY = (window_mouse_get_y() - y1) / content.zoom;
		
		content.scrollViewOffset.x += (mouseX - mouseXLast) * content.zoom;
		content.scrollViewOffset.y += (mouseY - mouseYLast) * content.zoom;
		
		// Clamp scroll view offset
		ClampScrollViewOffset();
	};
	
	/// @function		SetPan();
	/// @description	Sets the scroll view offset of the content based on pan input.
	SetPan = function() {
		// Get mouse pos
		var x1 = position.global.x * oMain.uiGridCurrentSize + content.scrollViewOffset.x;
		var y1 = position.global.y * oMain.uiGridCurrentSize + content.scrollViewOffset.y;
		var mouseX = (window_mouse_get_x() - x1) / content.zoom;
		var mouseY = (window_mouse_get_y() - y1) / content.zoom;
		
		if (oMain.mousePanViewOffset.x == -1 || oMain.mousePanViewOffset.y == -1) {
			oMain.mousePanViewOffset.x = mouseX;
			oMain.mousePanViewOffset.y = mouseY;
		}
		
		content.scrollViewOffset.x += (mouseX - oMain.mousePanViewOffset.x) * content.zoom;
		content.scrollViewOffset.y += (mouseY - oMain.mousePanViewOffset.y) * content.zoom;
		
		// Clamp scroll view offset
		ClampScrollViewOffset();
		
		oMain.alarm[0] = 2;
	};
	
	if (allowZoom || allowPan) {
		SetMouseInteraction(true, false, true);
		
		if (!allowZoom) {
			OnClick = function(mouseButton, mouseWheelState) {
				// Pan view
				if (mouseButton == mb_left && mouse_check_button(mouseButton) && keyboard_check(vk_space)) {
					SetPan();
				}
			};
		} else if (!allowPan) {
			OnClick = function(mouseButton, mouseWheelState) {
				// Zoom
				if (mouseWheelState != 0 && !keyboard_check(vk_control)) {
					SetZoom(Approach(content.zoom, mouseWheelState == 1 ? 2 : .5, .2));
				}
			};
		} else {
			OnClick = function(mouseButton, mouseWheelState) {
				// Zoom
				if (mouseWheelState != 0 && !keyboard_check(vk_control)) {
					SetZoom(Approach(content.zoom, mouseWheelState == 1 ? 2 : .5, .2));
				}
				
				// Pan view
				if (mouseButton == mb_left && mouse_check_button(mouseButton) && keyboard_check(vk_space)) {
					SetPan();
				}
			};
		}
		
		DrawElementHovered = function() {};
	}
	#endregion
};

/// @function				UIVariableDisplayElement(labelText, variableReference, color, alpha, sprite);
/// @description			Constructor for a UIVariableDisplayElement.
/// @param {String} labelText           The label text to display.
/// @param {Struct} variableReference   A reference to the displayed variable.
/// @param {Constant.Color} color	The color of the box.
/// @param {Real} alpha			The alpha of the box.
/// @param {Asset.GMSprite} [sprite]	The sprite of the box (optional).
function UIVariableDisplayElement(labelText, variableReference, color, alpha, sprite) : UIBoxElement(color, alpha, sprite) constructor {
	// Get input variables
	self.variableReference = variableReference;
	
	if (labelText == "") {
		// Define functions
		DrawOwnTexts = function() {
			variableTextComponent.Draw((position.global.x + width.current / 2) * oMain.uiGridCurrentSize, (position.global.y + height.current / 2) * oMain.uiGridCurrentSize);
		};
		
		UpdateTextScale = function() {
			variableTextComponent.textStruct.scale_to_box(width.current * oMain.uiGridCurrentSize, height.current * oMain.uiGridCurrentSize);
		};
		
		UpdateDisplay = function() {
			variableTextComponent = new UITextComponent("[c_gray]" + string(variableReference.Get()), fa_center);
			UpdateTextScale();
		};
	} else {
		// Create text component
		labelTextComponent = new UITextComponent("[c_gray]" + labelText, fa_left);
		
		// Define functions
		DrawOwnTexts = function() {
			labelTextComponent.Draw((position.global.x + .2) * oMain.uiGridCurrentSize, (position.global.y + height.current / 2) * oMain.uiGridCurrentSize);
			variableTextComponent.Draw((position.global.x + width.current - .2) * oMain.uiGridCurrentSize, (position.global.y + height.current / 2) * oMain.uiGridCurrentSize);
		};
		
		UpdateTextScale = function() {
			labelTextComponent.textStruct.scale_to_box(width.current * oMain.uiGridCurrentSize, height.current * oMain.uiGridCurrentSize);
			variableTextComponent.textStruct.scale_to_box(width.current * oMain.uiGridCurrentSize, height.current * oMain.uiGridCurrentSize);
		};
		
		UpdateDisplay = function() {
			variableTextComponent = new UITextComponent("[c_gray]" + string(variableReference.Get()), fa_right);
			UpdateTextScale();
		};
	}
	
	UpdateDisplay();
};

/// @function					UIListIndexCycleElement(list, listIndex, allowListManipulation, boxColor, boxAlpha, boxSprite);
/// @description				Constructor for a UIListCycleElement.
/// @param {Id.DsList<String>} list		The list of options to use.
/// @param {Struct} listIndex			A reference to the variable holding the list index.
/// @param {Bool} allowListManipulation 	Whether or not to add an add and delete button.
/// @param {Constant.Color} boxColor    	The color of the box.
/// @param {Real} boxAlpha			The alpha of the box.
/// @param {Asset.GMSprite} [boxSprite]	The sprite of the box (optional).
function UIListIndexCycleElement(list, listIndex, allowListManipulation, boxColor, boxAlpha, boxSprite) : UIBoxElement(boxColor, boxAlpha, boxSprite) constructor {
	// Get input values
	self.list = list;
	self.listIndex = listIndex;
	
	// Define functions
	UpdateDisplay = function() {
		variableDisplay.UpdateDisplay();
	};
	
	// Create elements
	cycleLeftButton = new UIElement();
	cycleRightButton = new UIElement();
	variableDisplay = new UIVariableDisplayElement("", listIndex, c_black, 0);
	
	// Set elements' properties
	cycleLeftButton.SetDimensions(1, -1, UI_ADJUST_MODE.FIXED, 1, -1, UI_ADJUST_MODE.FIXED);
	cycleLeftButton.SetMouseInteraction(true, true, true);
	with (cycleLeftButton) {
		sprite = new UISpriteComponent(sGCUICycleArrow, 1, 1, 0, c_white, 1);
		
		DrawElement = function() {
			sprite.Draw(.5 * oMain.uiGridCurrentSize, .5 * oMain.uiGridCurrentSize);
		};
		
		OnClick = function(mouseButton, mouseWheelState) {
			if !(mouseButton != mb_none && mouse_check_button_pressed(mouseButton)) return;
			
			parent.listIndex.Set(Wrap(parent.listIndex.Get() - 1, 0, max(0, ds_list_size(parent.list) - 1)));
			parent.UpdateDisplay();
			
			// Invoke event
			EventInvoke(EVENT.ON_UI_ELEMENT_LIST, [parent, parent.list]);
		};
	}
	
	cycleRightButton.SetDimensions(1, -1, UI_ADJUST_MODE.FIXED, 1, -1, UI_ADJUST_MODE.FIXED);
	cycleRightButton.SetAnchor(UI_CORNER.TOP_RIGHT, noone, UI_ANCHOR.TOP_RIGHT);
	cycleRightButton.SetMouseInteraction(true, true, true);
	with (cycleRightButton) {
		sprite = new UISpriteComponent(sGCUICycleArrow, -1, 1, 0, c_white, 1);
		
		DrawElement = function() {
			sprite.Draw(.5 * oMain.uiGridCurrentSize, .5 * oMain.uiGridCurrentSize);
		};
		
		OnClick = function(mouseButton, mouseWheelState) {
			if !(mouseButton != mb_none && mouse_check_button_pressed(mouseButton)) return;
			
			parent.listIndex.Set(Wrap(parent.listIndex.Get() + 1, 0, max(0, ds_list_size(parent.list) - 1)));
			parent.UpdateDisplay();
			
			// Invoke event
			EventInvoke(EVENT.ON_UI_ELEMENT_LIST, [parent, parent.list]);
		};
	}
	
	variableDisplay.SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FIXED);
	variableDisplay.SetAnchor(UI_CORNER.TOP_LEFT, cycleLeftButton, UI_ANCHOR.TOP_RIGHT);
	with (variableDisplay) {
		UpdateDisplay = function() {
			variableTextComponent = new UITextComponent("[c_gray]" + (ds_list_size(parent.list) == 0 ? "-" : string(variableReference.Get())), fa_center);
			UpdateTextScale();
		};
	}
	
	// Add elements as children
	self.AddChild(cycleLeftButton);
	self.AddChild(cycleRightButton);
	self.AddChild(variableDisplay);
	
	if (allowListManipulation) {
		addButton = new UILabelElement("[c_gray]Add", c_black, 0, sGCUIBoxNoLine);
		addButton.SetDimensions(5, -1, UI_ADJUST_MODE.FIXED, 1, -1, UI_ADJUST_MODE.FIXED);
		addButton.SetAnchor(UI_CORNER.TOP_LEFT, cycleLeftButton, UI_ANCHOR.BOTTOM_LEFT);
		addButton.SetMouseInteraction(true, true, true);
		with (addButton) {
			OnClick = function(mouseButton, mouseWheelState) {
				if !(mouseButton != mb_none && mouse_check_button_pressed(mouseButton)) return;
				
				EventInvoke(EVENT.ON_UI_ELEMENT_BUTTON_ADD, [parent, parent.list]);
				
				parent.listIndex.Set(ds_list_size(parent.list) - 1);
				parent.UpdateDisplay();
				
				EventInvoke(EVENT.ON_UI_ELEMENT_LIST, [parent, parent.list]);
			};
		}
			
		deleteButton = new UILabelElement("[c_gray]Delete", c_black, 0, sGCUIBoxNoLine);
		deleteButton.SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FIXED);
		deleteButton.SetAnchor(UI_CORNER.TOP_RIGHT, cycleRightButton, UI_ANCHOR.BOTTOM_RIGHT);
		deleteButton.SetMouseInteraction(true, true, true);
		with (deleteButton) {
			OnClick = function(mouseButton, mouseWheelState) {
				if !(mouseButton != mb_none && mouse_check_button_pressed(mouseButton)) return;
				
				var listSize = ds_list_size(parent.list);
				
				if (listSize == 0) return;
				
				EventInvoke(EVENT.ON_UI_ELEMENT_BUTTON_DELETE, [parent, parent.list]);
				
				parent.listIndex.Set(max(0, parent.listIndex.Get() - 1));
				parent.UpdateDisplay();
				
				EventInvoke(EVENT.ON_UI_ELEMENT_LIST, [parent, parent.list]);
			};
		}
		
		self.AddChild(addButton);
		self.AddChild(deleteButton);
	}
	
	UpdateDisplay();
};

/// @function					UICheckboxElement(reference, color, alpha, sprite);
/// @description				Constructor for a UICheckboxElement.
/// @param {Struct.Reference} reference		The reference to the boolean this checkbox elements refers to.
/// @param {Constant.Color} color		The color of the box.
/// @param {Real} alpha				The alpha of the box.
/// @param {Asset.GMSprite} [sprite]		The sprite of the box (optional).
function UICheckboxElement(reference, color, alpha, sprite) : UIBoxElement(color, alpha, sprite) constructor {
	// Get input values
	self.reference = reference;
	
	// Set elements' properties
	SetMouseInteraction(true, true, true);
	
	// Define functions
	DrawElement = function() {
		Draw9SliceExt(sprite, 0, 0, 0, oCamera.zoom.base, width.current * oMain.uiGridCurrentSize, height.current * oMain.uiGridCurrentSize, c_white, 1);
		
		// Draw the checkbox mark
		if (!reference.Get()) return;
		
		draw_sprite_ext(sGCUICheckbox, 0, 0, 0, oCamera.zoom.base, oCamera.zoom.base, 0, c_white, 1);
	};
	
	OnClick = function(mouseButton, mouseWheelState) {
		if !(mouseButton == mb_left && mouse_check_button_pressed(mouseButton)) return;
		
		reference.Set(!reference.Get());
		
		// Invoke event
		EventInvoke(EVENT.ON_UI_ELEMENT_CHECKBOX, [reference]);
	}
};

/// @function					UILabeledCheckboxElement(labelText, reference, color, alpha, sprite);
/// @description				Constructor for a UILabeledCheckboxElement.
/// @param {String} labelText			The text string.
/// @param {Struct.Reference} reference		The reference to the boolean this checkbox elements refers to.
/// @param {Constant.Color} color		The color of the box.
/// @param {Real} alpha				The alpha of the box.
/// @param {Asset.GMSprite} [sprite]		The sprite of the box (optional).
function UILabeledCheckboxElement(labelText, reference, color, alpha, sprite) : UIBoxElement(color, alpha, sprite) constructor {
	// Create elements
	labelTextComponent = new UITextComponent("[c_gray]" + labelText, fa_left);
	checkbox = new UICheckboxElement(reference, c_black, 0, sGCUIBoxDarkNoLine);
	
	// Set elements' properties
	checkbox.SetAnchor(UI_CORNER.TOP_RIGHT, noone, UI_ANCHOR.TOP_RIGHT);
	
	// Define functions
	DrawOwnTexts = function() {
		labelTextComponent.Draw((position.global.x + .2) * oMain.uiGridCurrentSize, (position.global.y + height.current / 2) * oMain.uiGridCurrentSize);
	};
	
	UpdateTextScale = function() {
		labelTextComponent.textStruct.scale_to_box(width.current * oMain.uiGridCurrentSize, height.current * oMain.uiGridCurrentSize);
	};
	
	// Add elements as children
	self.AddChild(checkbox);
};

/// @function					UISliderElement(reference, minValue, maxValue, doRound);
/// @description				Constructor for a UISliderElement.
/// @param {Struct.Reference} reference		The reference to the real this slider elements refers to.
/// @param {Real} minValue			The minimum value of the real this slider elements refers to.
/// @param {Real} maxValue			The maximum value of the real this slider elements refers to.
/// @param {Bool} doRound			Whether or not to round the int value or not.
function UISliderElement(reference, minValue, maxValue, doRound) : UIElement() constructor {
	// Get input values
	self.reference = reference;
	self.minValue = minValue;
	self.maxValue = maxValue;
	self.doRound = doRound;
	sliderPos = 0;
	
	// Set elements' properties
	SetMouseInteraction(true, true, true);
	
	// Define functions
	DrawElement = function() {
		// Draw the slider bar
		var sh = sprite_get_height(sGCUISliderBar) * oCamera.zoom.base;
		Draw9SliceExt(sGCUISliderBar, 0, .5 * oMain.uiGridCurrentSize, (height.current * oMain.uiGridCurrentSize - sh) / 2, oCamera.zoom.base, (width.current - 1) * oMain.uiGridCurrentSize, sh, c_white, 1);
		
		// Draw the slider button
		draw_sprite_ext(sGCUISliderButton, 0, (width.current - 1) * oMain.uiGridCurrentSize * sliderPos + .5 * oMain.uiGridCurrentSize, height.current * oMain.uiGridCurrentSize / 2, oCamera.zoom.base, oCamera.zoom.base, 0, c_white, 1);
	};
	
	OverrideSlider = function() {
		sliderPos = MapValue(reference.Get(), minValue, maxValue, 0, 1);
	};
	
	OnClick = function(mouseButton, mouseWheelState) {
		if !(mouseButton == mb_left && mouse_check_button(mouseButton)) return;
		
		// Set slider position
		var mouseX = window_mouse_get_x() - (position.global.x + .5) * oMain.uiGridCurrentSize;
		sliderPos = clamp(mouseX / ((width.current - 1) * oMain.uiGridCurrentSize), 0, 1);
		
		if (doRound) {
			// Round to nearest value
			var pos = lerp(minValue, maxValue, sliderPos);
			pos = round(pos);
			
			sliderPos = MapValue(pos, minValue, maxValue, 0, 1);
		}
		
		// Set reference value
		reference.Set(lerp(minValue, maxValue, sliderPos));
		
		// Invoke event
		EventInvoke(EVENT.ON_UI_ELEMENT_SLIDER, [reference]);
	}
};

/// @function					UILabeledSliderElement(labelText, reference, minValue, maxValue, color, alpha, sprite);
/// @description				Constructor for a UILabeledSliderElement.
/// @param {String} labelText			The text string.
/// @param {Struct.Reference} reference		The reference to the real this slider elements refers to.
/// @param {Real} minValue			The minimum value of the real this slider elements refers to.
/// @param {Real} maxValue			The maximum value of the real this slider elements refers to.
/// @param {Bool} doRound			Whether or not to round the int value or not.
/// @param {Constant.Color} color		The color of the box.
/// @param {Real} alpha				The alpha of the box.
/// @param {Asset.GMSprite} [sprite]		The sprite of the box (optional).
function UILabeledSliderElement(labelText, reference, minValue, maxValue, doRound, color, alpha, sprite) : UIBoxElement(color, alpha, sprite) constructor {
	// Create elements
	label = new UILabelElement(labelText, c_black, 0, sGCUIBox);
	slider = new UISliderElement(reference, minValue, maxValue, doRound);
	
	// Set elements' properties
	label.SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FIXED);
	slider.SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FILL);
	slider.SetAnchor(UI_CORNER.TOP_LEFT, label, UI_ANCHOR.BOTTOM_LEFT);
	
	// Add elements as children
	self.AddChild(label);
	self.AddChild(slider);
};

/// @function				UIRoomEditorViewElement(boxColor, boxAlpha, boxSprite);
/// @description			Constructor for a UIRoomEditorViewElement.
/// @param {Constant.Color} boxColor	The color of the box.
/// @param {Real} boxAlpha		The alpha of the box.
/// @param {Asset.GMSprite} [boxSprite]	The sprite of the box (optional).
function UIRoomEditorViewElement(boxColor, boxAlpha, boxSprite) : UIBoxElement(boxColor, boxAlpha, boxSprite) constructor {
	// Create elements
	scrollBarSeparator = new UIBoxElement(c_black, 0, sGCUIBoxDarkNoLine);
	scrollBarH = new UIScrollBarElement(UI_SCROLLBAR_TYPE.HORIZONTAL, sGCUIBoxDarkNoLine, sGCUIScrollHandleBox);
	scrollBarV = new UIScrollBarElement(UI_SCROLLBAR_TYPE.VERTICAL, sGCUIBoxDarkNoLine, sGCUIScrollHandleBox);
	view = new UIScrollViewElement(oMain.roomWidthTiles + 8, oMain.roomHeightTiles + 8, true, true);
	roomElement = new UIElement();
	
	// Set elements' properties
	scrollBarSeparator.SetAnchor(UI_CORNER.BOTTOM_RIGHT, noone, UI_ANCHOR.BOTTOM_RIGHT);
	
	scrollBarH.SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FIXED);
	scrollBarH.SetAnchor(UI_CORNER.TOP_RIGHT, scrollBarSeparator, UI_ANCHOR.TOP_LEFT);
	
	scrollBarV.SetDimensions(1, -1, UI_ADJUST_MODE.FIXED, 1, -1, UI_ADJUST_MODE.FILL);
	scrollBarV.SetAnchor(UI_CORNER.BOTTOM_RIGHT, scrollBarSeparator, UI_ANCHOR.TOP_RIGHT);
	
	view.SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FILL);
	view.SetAnchor(UI_CORNER.BOTTOM_RIGHT, scrollBarSeparator, UI_ANCHOR.TOP_LEFT);
	view.content.SetPadding(4, 4);
	
	roomElement.SetDimensions(oMain.roomWidthTiles, -1, UI_ADJUST_MODE.FIXED, oMain.roomHeightTiles, -1, UI_ADJUST_MODE.FIXED);
	roomElement.SetMouseInteraction(true, true, true);
	with (roomElement) {
		DrawElement = function() {
			var sw = surface_get_width(surface), sh = surface_get_height(surface);
			
			// Clear background
			draw_clear_alpha(c_black, 0);
			
			// Get current list and room
			var currentList, currentRoom;
			switch (oGameChanger.patternSelected) {
				case 0: currentList = oGameChanger.roomsHorizontal break;
				case 1: currentList = oGameChanger.roomsVertical break;
				case 2: currentList = oGameChanger.roomsDrop break;
				case 3: currentList = oGameChanger.roomsLand break;
			}
			currentRoom = currentList[| oGameChanger.roomSelected];
			
			// Abort if there is no room selected
			if (ds_list_empty(currentList)) return;
			
			draw_clear_alpha($231C19, 1);
			
			// Draw the grid
			for (var i = 0; i < oMain.roomWidthTiles; i++) {
				for (var j = 0; j < oMain.roomHeightTiles; j++) {
					if (currentRoom.tilesFG[# i, j] == TILE.WALL) {
						draw_set_color($423D39);
						draw_rectangle(i * oMain.uiGridCurrentSize, j * oMain.uiGridCurrentSize, (i + 1) * oMain.uiGridCurrentSize, (j + 1) * oMain.uiGridCurrentSize, false);
					} else if (currentRoom.tilesFG[# i, j] == TILE.MAPGEN_HAZARD) {
						draw_set_color(c_maroon);
						draw_rectangle(i * oMain.uiGridCurrentSize, j * oMain.uiGridCurrentSize, (i + 1) * oMain.uiGridCurrentSize, (j + 1) * oMain.uiGridCurrentSize, false);
					} else if (currentRoom.tilesBG[# i, j] == TILE.WALL) {
						draw_set_color($312C28);
						draw_rectangle(i * oMain.uiGridCurrentSize, j * oMain.uiGridCurrentSize, (i + 1) * oMain.uiGridCurrentSize, (j + 1) * oMain.uiGridCurrentSize, false);
					}
				}
			}
			
			draw_set_color(c_white);
			draw_set_alpha(.1);
			gpu_set_colorwriteenable(true, true, true, false);
			
			shader_set(shdGrid);
			shader_set_uniform_f(shader_get_uniform(shdGrid, "textureSize"), sw, sh);
			shader_set_uniform_f(shader_get_uniform(shdGrid, "cellSize"), oMain.uiGridCurrentSize);
			shader_set_uniform_f(shader_get_uniform(shdGrid, "lineWidth"), 2);
			draw_sprite_stretched(sPixel, 0, 0, 0, sw, sh);
			shader_reset();
			
			gpu_set_colorwriteenable(true, true, true, true);
			draw_set_alpha(1);
			
			// Draw the exit
			if (currentRoom.exitPos.x != -1 && currentRoom.exitPos.y != -1) {
				var xx = currentRoom.exitPos.x * oMain.uiGridCurrentSize;
				var yy = currentRoom.exitPos.y * oMain.uiGridCurrentSize;
				var exitWidth = oMain.exitWidthTiles * oMain.uiGridCurrentSize;
				var exitHeight = oMain.exitHeightTiles * oMain.uiGridCurrentSize;
				
				draw_set_color(c_lime);
				draw_line_width(xx - exitWidth / 2, yy, xx + exitWidth / 2, yy, 2);
				draw_line_width(xx - exitWidth / 2, yy - exitHeight, xx + exitWidth / 2, yy - exitHeight, 2);
				draw_line_width(xx - exitWidth / 2, yy - exitHeight, xx - exitWidth / 2, yy, 2);
				draw_line_width(xx + exitWidth / 2, yy - exitHeight, xx + exitWidth / 2, yy, 2);
				
			}
			
			// Draw the pattern bounds
			draw_set_color(c_ltgray);
			draw_line_width(-2, 0, sw, 0, 2);
			draw_line_width(-2, sh - 2, sw, sh - 2, 2);
			draw_line_width(0, -2, 0, sh, 2);
			draw_line_width(sw - 2, -2, sw - 2, sh, 2);
			
			draw_set_color(c_dkgray);
			switch (oGameChanger.patternSelected) {
				case MAP_GEN_ROOM_PATTERN.CORRIDOR_H:
					draw_line_width(0, 8 * oMain.uiGridCurrentSize, 0, sh - 8 * oMain.uiGridCurrentSize, 2);
					draw_line_width(sw - 2, 8 * oMain.uiGridCurrentSize, sw - 2, sh - 8 * oMain.uiGridCurrentSize, 2);
					break;
				case MAP_GEN_ROOM_PATTERN.CORRIDOR_V:
					draw_line_width(18 * oMain.uiGridCurrentSize, 0, sw - 18 * oMain.uiGridCurrentSize, 0, 2);
					draw_line_width(18 * oMain.uiGridCurrentSize, sh - 2, sw - 18 * oMain.uiGridCurrentSize, sh - 2, 2);
					break;
				case MAP_GEN_ROOM_PATTERN.DROP:
					draw_line_width(18 * oMain.uiGridCurrentSize, sh - 2, sw - 18 * oMain.uiGridCurrentSize, sh - 2, 2);
					draw_line_width(0, 8 * oMain.uiGridCurrentSize, 0, sh - 8 * oMain.uiGridCurrentSize, 2);
					draw_line_width(sw - 2, 8 * oMain.uiGridCurrentSize, sw - 2, sh - 8 * oMain.uiGridCurrentSize, 2);
					break;
				case MAP_GEN_ROOM_PATTERN.LAND:
					draw_line_width(18 * oMain.uiGridCurrentSize, 0, sw - 18 * oMain.uiGridCurrentSize, 0, 2);
					draw_line_width(0, 8 * oMain.uiGridCurrentSize, 0, sh - 8 * oMain.uiGridCurrentSize, 2);
					draw_line_width(sw - 2, 8 * oMain.uiGridCurrentSize, sw - 2, sh - 8 * oMain.uiGridCurrentSize, 2);
					break;
			}
		};
		
		/// @function		GetElementBounds();
		/// @description	Returns a struct of the bounds x1, y1, x2, y2.
		GetElementBounds = function() {
			var offsetX = parent.scrollViewOffset.x;
			var offsetY = parent.scrollViewOffset.y;
			var xx = position.global.x - parent.padding.horizontal + parent.padding.horizontal * parent.zoom;
			var yy = position.global.y - parent.padding.vertical + parent.padding.vertical * parent.zoom;
			
			var _x1 = xx * oMain.uiGridCurrentSize + offsetX;
			var _y1 = yy * oMain.uiGridCurrentSize + offsetY;
			var _x2 = (xx + width.current * parent.zoom) * oMain.uiGridCurrentSize + offsetX;
			var _y2 = (yy + height.current * parent.zoom) * oMain.uiGridCurrentSize + offsetY;
			
			return {x1 : _x1, y1 : _y1, x2 : _x2, y2 : _y2};
		}
		
		CheckMouseHoversElement = function() {
			// Get bounds
			var bounds = GetElementBounds();
			
			return point_in_rectangle(window_mouse_get_x(), window_mouse_get_y(), bounds.x1, bounds.y1, bounds.x2, bounds.y2);
		};
		
		DrawElementHovered = function() {
			// Get mouse and cell pos
			var bounds = GetElementBounds();
			var mouseX = (window_mouse_get_x() - bounds.x1) / parent.zoom;
			var mouseY = (window_mouse_get_y() - bounds.y1) / parent.zoom;
			var cellX = mouseX div oMain.uiGridCurrentSize;
			var cellY = mouseY div oMain.uiGridCurrentSize;
			
			var sw = surface_get_width(surface);
			var sh = surface_get_height(surface);
			
			var brushSize = oGameChanger.brushSizeSelected * 2 + 1;
			cellX -= floor(brushSize / 2);
			cellY -= floor(brushSize / 2);
			
			draw_set_color(c_white);
			gpu_set_colorwriteenable(true, true, true, false);
			
			draw_set_alpha(.2);
			draw_line_width(0, cellY * oMain.uiGridCurrentSize, sw, cellY * oMain.uiGridCurrentSize, 2);
			draw_line_width(0, (cellY + brushSize) * oMain.uiGridCurrentSize, sw, (cellY + brushSize) * oMain.uiGridCurrentSize, 2);
			draw_line_width(cellX * oMain.uiGridCurrentSize, 0, cellX * oMain.uiGridCurrentSize, sh, 2);
			draw_line_width((cellX + brushSize) * oMain.uiGridCurrentSize, 0, (cellX + brushSize) * oMain.uiGridCurrentSize, sh, 2);
			
			draw_set_alpha(1);
			draw_line_width(cellX * oMain.uiGridCurrentSize, cellY * oMain.uiGridCurrentSize, (cellX + brushSize) * oMain.uiGridCurrentSize, cellY * oMain.uiGridCurrentSize, 2);
			draw_line_width(cellX * oMain.uiGridCurrentSize, (cellY + brushSize) * oMain.uiGridCurrentSize, (cellX + brushSize) * oMain.uiGridCurrentSize, (cellY + brushSize) * oMain.uiGridCurrentSize, 2);
			draw_line_width(cellX * oMain.uiGridCurrentSize, cellY * oMain.uiGridCurrentSize, cellX * oMain.uiGridCurrentSize, (cellY + brushSize) * oMain.uiGridCurrentSize, 2);
			draw_line_width((cellX + brushSize) * oMain.uiGridCurrentSize, cellY * oMain.uiGridCurrentSize, (cellX + brushSize) * oMain.uiGridCurrentSize, (cellY + brushSize) * oMain.uiGridCurrentSize, 2);
			
			gpu_set_colorwriteenable(true, true, true, true);
		};
			
		OnClick = function(mouseButton, mouseWheelState) {
			if (mouseWheelState != 0) {
				// Change brush size
				if (!keyboard_check(vk_control)) return;
				
				// Change brush size
				oGameChanger.brushSizeSelected = clamp(oGameChanger.brushSizeSelected + mouseWheelState, 0, ds_list_size(oGameChanger.brushSizeNames) - 1);
				oGameChanger.uiElementBrushSizeSelection.dropdown.UpdateText();
			} else if (mouseButton != mb_none && mouse_check_button(mouseButton)) {
				if (keyboard_check(vk_space)) return;
				
				// Place / remove tile & move exit
				// Get mouse and cell pos
				var bounds = GetElementBounds();
				var mouseX = (window_mouse_get_x() - bounds.x1) / parent.zoom;
				var mouseY = (window_mouse_get_y() - bounds.y1) / parent.zoom;
				var cellX = clamp(mouseX div oMain.uiGridCurrentSize, 0, oMain.roomWidthTiles - 1);
				var cellY = clamp(mouseY div oMain.uiGridCurrentSize, 0, oMain.roomHeightTiles - 1);
				
				var brushSize = oGameChanger.brushSizeSelected * 2 + 1;
				var cellRangeXMin = max(0, cellX - floor(brushSize / 2));
				var cellRangeYMin = max(0, cellY - floor(brushSize / 2));
				var cellRangeXMax = min(oMain.roomWidthTiles - 1, cellX + floor(brushSize / 2));
				var cellRangeYMax = min(oMain.roomHeightTiles - 1, cellY + floor(brushSize / 2));
				
				// Get current list and room
				var currentList, currentRoom;
				switch (oGameChanger.patternSelected) {
					case 0: currentList = oGameChanger.roomsHorizontal break;
					case 1: currentList = oGameChanger.roomsVertical break;
					case 2: currentList = oGameChanger.roomsDrop break;
					case 3: currentList = oGameChanger.roomsLand break;
				}
				currentRoom = currentList[| oGameChanger.roomSelected];
				
				switch (mouseButton) {
					case mb_left:
						// Place tile / move object
						switch (oGameChanger.placementTypeSelected) {
							case 0:
								// Tile FG
								ds_grid_set_region(currentRoom.tilesFG, cellRangeXMin, cellRangeYMin, cellRangeXMax, cellRangeYMax, TILE.WALL);
								break;
							case 1:
								// Tile BG
								ds_grid_set_region(currentRoom.tilesBG, cellRangeXMin, cellRangeYMin, cellRangeXMax, cellRangeYMax, TILE.WALL);
								break;
							case 2:
								// Hazard
								for (var i = cellRangeXMin; i <= cellRangeXMax; i++) {
									for (var j = cellRangeYMin; j <= cellRangeYMax; j++) {
										if (currentRoom.tilesFG[# i, j] == TILE.VOID) currentRoom.tilesFG[# i, j] = TILE.MAPGEN_HAZARD;
									}
								}
								break;
							case 3:
								// Exit
								currentRoom.exitPos.x = cellX;
								currentRoom.exitPos.y = cellY;
								break;
						}
						
						oGameChanger.AddUnsavedChanges();
						break;
					case mb_right:
						// Remove tile
						switch (oGameChanger.placementTypeSelected) {
							case 0:
								// Tile FG
								ds_grid_set_region(currentRoom.tilesFG, cellRangeXMin, cellRangeYMin, cellRangeXMax, cellRangeYMax, TILE.VOID);
								oGameChanger.AddUnsavedChanges();
								break;
							case 1:
								// Tile BG
								ds_grid_set_region(currentRoom.tilesBG, cellRangeXMin, cellRangeYMin, cellRangeXMax, cellRangeYMax, TILE.VOID);
								oGameChanger.AddUnsavedChanges();
								break;
							case 2:
								// Hazard
								for (var i = cellRangeXMin; i <= cellRangeXMax; i++) {
									for (var j = cellRangeYMin; j <= cellRangeYMax; j++) {
										if (currentRoom.tilesFG[# i, j] == TILE.MAPGEN_HAZARD) currentRoom.tilesFG[# i, j] = TILE.VOID;
									}
								}
								oGameChanger.AddUnsavedChanges();
								break;
							case 3:
								// Exit
								break;
						}
						break;
				}
				
				// Update surface
				parent.UpdateNestedSurface();
				
				// Update UI
				oGameChanger.UpdateRoomEditorInfo();
			}
		};
	}
	
	// Add elements as children
	self.AddChild(scrollBarSeparator);
	self.AddChild(scrollBarH);
	self.AddChild(scrollBarV);
	self.AddChild(view);
	view.content.AddChild(roomElement);
};

/// @function				UIPropEditorViewElement(boxColor, boxAlpha, boxSprite);
/// @description			Constructor for a UIPropEditorViewElement.
/// @param {Constant.Color} boxColor	The color of the box.
/// @param {Real} boxAlpha		The alpha of the box.
/// @param {Asset.GMSprite} [boxSprite]	The sprite of the box (optional).
function UIPropEditorViewElement(boxColor, boxAlpha, boxSprite) : UIBoxElement(boxColor, boxAlpha, boxSprite) constructor {
	// Define own variables
	displaySprite = noone;
	spriteWidth = 0;
	spriteHeight = 0;
	
	// Create elements
	scrollBarSeparator = new UIBoxElement(c_black, 0, sGCUIBoxDarkNoLine);
	scrollBarH = new UIScrollBarElement(UI_SCROLLBAR_TYPE.HORIZONTAL, sGCUIBoxDarkNoLine, sGCUIScrollHandleBox);
	scrollBarV = new UIScrollBarElement(UI_SCROLLBAR_TYPE.VERTICAL, sGCUIBoxDarkNoLine, sGCUIScrollHandleBox);
	view = new UIScrollViewElement(1, 1, true, true);
	propElement = new UIElement();
	
	// Set elements' properties
	scrollBarSeparator.SetAnchor(UI_CORNER.BOTTOM_RIGHT, noone, UI_ANCHOR.BOTTOM_RIGHT);
	
	scrollBarH.SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FIXED);
	scrollBarH.SetAnchor(UI_CORNER.TOP_RIGHT, scrollBarSeparator, UI_ANCHOR.TOP_LEFT);
	
	scrollBarV.SetDimensions(1, -1, UI_ADJUST_MODE.FIXED, 1, -1, UI_ADJUST_MODE.FILL);
	scrollBarV.SetAnchor(UI_CORNER.BOTTOM_RIGHT, scrollBarSeparator, UI_ANCHOR.TOP_RIGHT);
	
	view.SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FILL);
	view.SetAnchor(UI_CORNER.BOTTOM_RIGHT, scrollBarSeparator, UI_ANCHOR.TOP_LEFT);
	view.content.SetPadding(4, 4);
	
	propElement.SetDimensions(1, -1, UI_ADJUST_MODE.FIXED, 1, -1, UI_ADJUST_MODE.FIXED);
	with (propElement) {
		DrawElement = function() {
			if (parent.parent.parent.displaySprite == noone) return;
			
			var sw = surface_get_width(surface), sh = surface_get_height(surface);
			
			// Clear background
			draw_clear_alpha($231C19, 1);
			
			// Draw the sprite
			draw_sprite_ext(parent.parent.parent.displaySprite, 0, sw / 2, sh, oCamera.zoom.base, oCamera.zoom.base, 0, c_white, 1);
			
			// Draw the grid
			draw_set_color(c_white);
			draw_set_alpha(.1);
			gpu_set_colorwriteenable(true, true, true, false);
			
			shader_set(shdGrid);
			shader_set_uniform_f(shader_get_uniform(shdGrid, "textureSize"), sw, sh);
			shader_set_uniform_f(shader_get_uniform(shdGrid, "cellSize"), oMain.tileSize * oCamera.zoom.base);
			shader_set_uniform_f(shader_get_uniform(shdGrid, "lineWidth"), 2);
			draw_sprite_stretched(sPixel, 0, 0, 0, sw, sh);
			shader_reset();
			
			gpu_set_colorwriteenable(true, true, true, true);
			draw_set_alpha(1);
			
			// Draw the bounds
			draw_set_color(c_dkgray);
			draw_line_width(-2, 0, sw, 0, 2);
			draw_line_width(-2, sh - 2, sw, sh - 2, 2);
			draw_line_width(0, -2, 0, sh, 2);
			draw_line_width(sw - 2, -2, sw - 2, sh, 2);
		};
	}
	
	// Define functions
	UpdateDisplay = function() {
		displaySprite = asset_get_index(oGameChanger.propNamesListCurrent[| oGameChanger.propNameSelected]);
		spriteWidth = ceil(sprite_get_width(displaySprite) / oMain.tileSize);
		spriteHeight = ceil(sprite_get_height(displaySprite) / oMain.tileSize);
		
		var sw = spriteWidth * oMain.tileSize / oMain.uiGridBaseSize;
		var sh = spriteHeight * oMain.tileSize / oMain.uiGridBaseSize;
		
		view.content.SetDimensions(sw + 8, -1, UI_ADJUST_MODE.FIXED, sh + 8, -1, UI_ADJUST_MODE.FIXED);
		propElement.SetDimensions(sw, -1, UI_ADJUST_MODE.FIXED, sh, -1, UI_ADJUST_MODE.FIXED);
		
		view.content.UpdateDimensions();
		propElement.UpdateDimensions();
		propElement.UpdateNestedSurface();
	};
	
	// Add elements as children
	self.AddChild(scrollBarSeparator);
	self.AddChild(scrollBarH);
	self.AddChild(scrollBarV);
	self.AddChild(view);
	view.content.AddChild(propElement);
};

/// @function				UIGroupEditorViewElement(boxColor, boxAlpha, boxSprite);
/// @description			Constructor for a UIGroupEditorViewElement.
/// @param {Constant.Color} boxColor	The color of the box.
/// @param {Real} boxAlpha		The alpha of the box.
/// @param {Asset.GMSprite} [boxSprite]	The sprite of the box (optional).
function UIGroupEditorViewElement(boxColor, boxAlpha, boxSprite) : UIBoxElement(boxColor, boxAlpha, boxSprite) constructor {
	var gridSize = oGameChanger.groupGridSize * oMain.tileSize / oMain.uiGridBaseSize;
	
	// Create elements
	scrollBarSeparator = new UIBoxElement(c_black, 0, sGCUIBoxDarkNoLine);
	scrollBarH = new UIScrollBarElement(UI_SCROLLBAR_TYPE.HORIZONTAL, sGCUIBoxDarkNoLine, sGCUIScrollHandleBox);
	scrollBarV = new UIScrollBarElement(UI_SCROLLBAR_TYPE.VERTICAL, sGCUIBoxDarkNoLine, sGCUIScrollHandleBox);
	view = new UIScrollViewElement(gridSize + 8, gridSize + 8, true, true);
	groupElement = new UIElement();
	
	// Set elements' properties
	scrollBarSeparator.SetAnchor(UI_CORNER.BOTTOM_RIGHT, noone, UI_ANCHOR.BOTTOM_RIGHT);
	
	scrollBarH.SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FIXED);
	scrollBarH.SetAnchor(UI_CORNER.TOP_RIGHT, scrollBarSeparator, UI_ANCHOR.TOP_LEFT);
	
	scrollBarV.SetDimensions(1, -1, UI_ADJUST_MODE.FIXED, 1, -1, UI_ADJUST_MODE.FILL);
	scrollBarV.SetAnchor(UI_CORNER.BOTTOM_RIGHT, scrollBarSeparator, UI_ANCHOR.TOP_RIGHT);
	
	view.SetDimensions(1, -1, UI_ADJUST_MODE.FILL, 1, -1, UI_ADJUST_MODE.FILL);
	view.SetAnchor(UI_CORNER.BOTTOM_RIGHT, scrollBarSeparator, UI_ANCHOR.TOP_LEFT);
	view.content.SetPadding(4, 4);
	
	groupElement.SetDimensions(gridSize, -1, UI_ADJUST_MODE.FIXED, gridSize, -1, UI_ADJUST_MODE.FIXED);
	groupElement.SetMouseInteraction(true, true, true);
	with (groupElement) {
		DrawElement = function() {
			var sw = surface_get_width(surface), sh = surface_get_height(surface);
			var gridSize = oMain.tileSize * oCamera.zoom.base;
			var groupCurrent = oGameChanger.groupCurrentGroupList[| oGameChanger.groupCurrentGroupListIndexSelected];
			
			// Clear background
			draw_clear_alpha(c_black, 0);
			
			// Abort if the group list is empty
			if (ds_list_empty(oGameChanger.groupCurrentGroupList)) return;
			
			// Measure the group bounds
			var bounds = {xmin : 9999, ymin : 9999, xmax : -9999, ymax : -9999};
			
			draw_clear_alpha($231C19, 1);
			
			// Draw the props
			var currentProp;
			var propListSize = ds_list_size(groupCurrent.propList);
			
			for (var currentDepth = oMain.propDepthRange; currentDepth >= -oMain.propDepthRange; currentDepth --) {
				for (var i = 0; i < propListSize; i++) {
					// Get the current prop
					currentProp = groupCurrent.propList[| i];
					
					// Draw the prop if it matches the current depth
					if (currentProp.depth != currentDepth) continue;
					
					// Draw the prop
					draw_sprite_ext(currentProp.sprite, 0, currentProp.x * oCamera.zoom.base, currentProp.y * oCamera.zoom.base, oCamera.zoom.base, oCamera.zoom.base, currentProp.rotation, c_white, 1);
					
					// Update bounds
					var sprW = sprite_get_width(currentProp.sprite) / 2 * oCamera.zoom.base;
					var sprH = sprite_get_height(currentProp.sprite) * oCamera.zoom.base;
					
					for (var j = 0; j < 4; j++) {
						switch (j) {
							case 0:
								var posX = currentProp.x * oCamera.zoom.base + lengthdir_x(sprW, currentProp.rotation);
								var posY = currentProp.y * oCamera.zoom.base + lengthdir_y(sprW, currentProp.rotation);
								break;
							case 1:
								var posX = currentProp.x * oCamera.zoom.base + lengthdir_x(sprW, currentProp.rotation) + lengthdir_x(sprH, currentProp.rotation + 90);
								var posY = currentProp.y * oCamera.zoom.base + lengthdir_y(sprW, currentProp.rotation) + lengthdir_y(sprH, currentProp.rotation + 90);
								break;
							case 2:
								var posX = currentProp.x * oCamera.zoom.base + lengthdir_x(sprW, currentProp.rotation + 180) + lengthdir_x(sprH, currentProp.rotation + 90);
								var posY = currentProp.y * oCamera.zoom.base + lengthdir_y(sprW, currentProp.rotation + 180) + lengthdir_y(sprH, currentProp.rotation + 90);
								break;
							case 3:
								var posX = currentProp.x * oCamera.zoom.base + lengthdir_x(sprW, currentProp.rotation + 180);
								var posY = currentProp.y * oCamera.zoom.base + lengthdir_y(sprW, currentProp.rotation + 180);
								break;
						}
						
						var left = floor(posX / gridSize) * gridSize;
						var right = ceil(posX / gridSize) * gridSize;
						var top = floor(posY / gridSize) * gridSize;
						var bottom = ceil(posY / gridSize) * gridSize;
						
						if (left < bounds.xmin) bounds.xmin = left;
						if (right > bounds.xmax) bounds.xmax = right;
						if (top < bounds.ymin) bounds.ymin = top;
						if (bottom > bounds.ymax) bounds.ymax = bottom;
					}
				}
			}
			
			// Draw the grid
			draw_set_color($423D39);
			for (var i = 0; i < oGameChanger.groupGridSize; i++) {
				for (var j = 0; j < oGameChanger.groupGridSize; j++) {
					if (groupCurrent.tileGrid[# i, j] == TILE.WALL) {
						// Draw the tile
						draw_rectangle(i * gridSize, j * gridSize, (i + 1) * gridSize, (j + 1) * gridSize, false);
						
						// Update bounds
						if (i * gridSize < bounds.xmin) bounds.xmin = i * gridSize;
						if ((i + 1) * gridSize > bounds.xmax) bounds.xmax = (i + 1) * gridSize;
						if (j * gridSize < bounds.ymin) bounds.ymin = j * gridSize;
						if ((j + 1) * gridSize > bounds.ymax) bounds.ymax = (j + 1) * gridSize;
					}
				}
			}
			
			draw_set_color(c_white);
			draw_set_alpha(.1);
			gpu_set_colorwriteenable(true, true, true, false);
			
			shader_set(shdGrid);
			shader_set_uniform_f(shader_get_uniform(shdGrid, "textureSize"), sw, sh);
			shader_set_uniform_f(shader_get_uniform(shdGrid, "cellSize"), gridSize);
			shader_set_uniform_f(shader_get_uniform(shdGrid, "lineWidth"), 2);
			draw_sprite_stretched(sPixel, 0, 0, 0, sw, sh);
			shader_reset();
			
			gpu_set_colorwriteenable(true, true, true, true);
			draw_set_alpha(1);
			
			// Draw the group bounds
			bounds.xmax = min(bounds.xmax, sw - 2);
			bounds.ymax = min(bounds.ymax, sh - 2);
			
			draw_set_color(c_ltgray);
			draw_line_width(bounds.xmin, bounds.ymin, bounds.xmax, bounds.ymin, 2);
			draw_line_width(bounds.xmin, bounds.ymax, bounds.xmax, bounds.ymax, 2);
			draw_line_width(bounds.xmin, bounds.ymin, bounds.xmin, bounds.ymax, 2);
			draw_line_width(bounds.xmax, bounds.ymin, bounds.xmax, bounds.ymax, 2);
			
			// Draw the currently selected prop bounds
			if (oGameChanger.groupCurrentPropListSelected != -1) {
				var currentProp = groupCurrent.propList[| oGameChanger.groupCurrentPropListSelected];
				
				var sprW = sprite_get_width(currentProp.sprite) / 2 * oCamera.zoom.base;
				var sprH = sprite_get_height(currentProp.sprite) * oCamera.zoom.base;
				
				var left = floor((currentProp.x * oCamera.zoom.base - sprW) / gridSize) * gridSize;
				var right = ceil((currentProp.x * oCamera.zoom.base + sprW) / gridSize) * gridSize;
				var top = floor((currentProp.y * oCamera.zoom.base - sprH) / gridSize) * gridSize;
				var bottom = ceil((currentProp.y * oCamera.zoom.base) / gridSize) * gridSize;
				
				draw_set_color(c_lime);
				draw_line_width(left, top, right, top, 2);
				draw_line_width(left, bottom, right, bottom, 2);
				draw_line_width(left, top, left, bottom, 2);
				draw_line_width(right, top, right, bottom, 2);
			}
			
			// Update UI group dimension info
			oGameChanger.groupInfoDimensions = $"X {max(0, ceil((bounds.xmax - bounds.xmin) / gridSize))}, Y {max(0, ceil((bounds.ymax - bounds.ymin) / gridSize))}";
		};
		
		/// @function		GetElementBounds();
		/// @description	Returns a struct of the bounds x1, y1, x2, y2.
		GetElementBounds = function() {
			var offsetX = parent.scrollViewOffset.x;
			var offsetY = parent.scrollViewOffset.y;
			var xx = position.global.x - parent.padding.horizontal + parent.padding.horizontal * parent.zoom;
			var yy = position.global.y - parent.padding.vertical + parent.padding.vertical * parent.zoom;
			
			var _x1 = xx * oMain.uiGridCurrentSize + offsetX;
			var _y1 = yy * oMain.uiGridCurrentSize + offsetY;
			var _x2 = (xx + width.current * parent.zoom) * oMain.uiGridCurrentSize + offsetX;
			var _y2 = (yy + height.current * parent.zoom) * oMain.uiGridCurrentSize + offsetY;
			
			return {x1 : _x1, y1 : _y1, x2 : _x2, y2 : _y2};
		}
		
		/// @function		CheckMouseHoversElement();
		/// @description	Checks if the mouse is inside the bounds of the UI element. Override if needed.
		/// @return {Bool}
		CheckMouseHoversElement = function() {
			// Get bounds
			var bounds = GetElementBounds();
			
			return point_in_rectangle(window_mouse_get_x(), window_mouse_get_y(), bounds.x1, bounds.y1, bounds.x2, bounds.y2);
		};
		
		/// @function		CheckMouseHoversProp();
		/// @description	Checks if the mouse hovers a prop.
		/// @return {Array<Real>}
		CheckMouseHoversProp = function() {
			var result = [];
			
			// Check if the mouse hovers a prop
			var bounds = GetElementBounds();
			var mouseX = (window_mouse_get_x() - bounds.x1) / parent.zoom;
			var mouseY = (window_mouse_get_y() - bounds.y1) / parent.zoom;
			
			var groupCurrent = oGameChanger.groupCurrentGroupList[| oGameChanger.groupCurrentGroupListIndexSelected];
			var groupPropListSize = ds_list_size(groupCurrent.propList);
			var currentProp;
			
			for (var i = 0; i < groupPropListSize; i++) {
				// Get the prop
				currentProp = groupCurrent.propList[| i];
				
				// Get the props bounds
				var gridSize = oMain.tileSize * oCamera.zoom.base;
				
				var sprW = sprite_get_width(currentProp.sprite) / 2 * oCamera.zoom.base;
				var sprH = sprite_get_height(currentProp.sprite) * oCamera.zoom.base;
				
				var left = floor((currentProp.x * oCamera.zoom.base - sprW) / gridSize) * gridSize;
				var right = ceil((currentProp.x * oCamera.zoom.base + sprW) / gridSize) * gridSize;
				var top = floor((currentProp.y * oCamera.zoom.base - sprH) / gridSize) * gridSize;
				var bottom = ceil((currentProp.y * oCamera.zoom.base) / gridSize) * gridSize;
				
				// Check if the mouse is inside the sprites bounds
				if (point_in_rectangle(mouseX, mouseY, left, top, right, bottom)) {
					result[array_length(result)] = i;
				}
			}
			
			// No prop hovered
			return result;
		};
		
		DrawElementHovered = function() {
			var gridSize = oMain.tileSize * oCamera.zoom.base;
			
			if (oGameChanger.groupPlacementTypeSelected == 0) {
				// Draw the currently hovered tile
				var bounds = GetElementBounds();
				var mouseX = (window_mouse_get_x() - bounds.x1) / parent.zoom;
				var mouseY = (window_mouse_get_y() - bounds.y1) / parent.zoom;
				var cellX = mouseX div gridSize;
				var cellY = mouseY div gridSize;
				
				var sw = surface_get_width(surface);
				var sh = surface_get_height(surface);
				
				var brushSize = 1;
				cellX -= floor(brushSize / 2);
				cellY -= floor(brushSize / 2);
				
				draw_set_color(c_white);
				gpu_set_colorwriteenable(true, true, true, false);
				
				draw_set_alpha(.2);
				draw_line_width(0, cellY * gridSize, sw, cellY * gridSize, 2);
				draw_line_width(0, (cellY + brushSize) * gridSize, sw, (cellY + brushSize) * gridSize, 2);
				draw_line_width(cellX * gridSize, 0, cellX * gridSize, sh, 2);
				draw_line_width((cellX + brushSize) * gridSize, 0, (cellX + brushSize) * gridSize, sh, 2);
				
				draw_set_alpha(1);
				draw_line_width(cellX * gridSize, cellY * gridSize, (cellX + brushSize) * gridSize, cellY * gridSize, 2);
				draw_line_width(cellX * gridSize, (cellY + brushSize) * gridSize, (cellX + brushSize) * gridSize, (cellY + brushSize) * gridSize, 2);
				draw_line_width(cellX * gridSize, cellY * gridSize, cellX * gridSize, (cellY + brushSize) * gridSize, 2);
				draw_line_width((cellX + brushSize) * gridSize, cellY * gridSize, (cellX + brushSize) * gridSize, (cellY + brushSize) * gridSize, 2);
				
				gpu_set_colorwriteenable(true, true, true, true);
			}
		};
			
		OnClick = function(mouseButton, mouseWheelState) {
			if (mouseButton != mb_none && mouse_check_button(mouseButton)) {
				if (keyboard_check(vk_space)) return;
				
				var groupCurrent = oGameChanger.groupCurrentGroupList[| oGameChanger.groupCurrentGroupListIndexSelected];
				
				// Abort if the group list is empty
				if (ds_list_empty(oGameChanger.groupCurrentGroupList)) return;
				
				// Place / remove tile & move exit
				var gridSize = oMain.tileSize * oCamera.zoom.base;
				
				// Get mouse and cell pos
				var bounds = GetElementBounds();
				var mouseX = (window_mouse_get_x() - bounds.x1) / parent.zoom;
				var mouseY = (window_mouse_get_y() - bounds.y1) / parent.zoom;
				var cellX = clamp(mouseX div gridSize, 0, oGameChanger.groupGridSize - 1);
				var cellY = clamp(mouseY div gridSize, 0, oGameChanger.groupGridSize - 1);
				
				var brushSize = 1;
				var cellRangeXMin = max(0, cellX - floor(brushSize / 2));
				var cellRangeYMin = max(0, cellY - floor(brushSize / 2));
				var cellRangeXMax = min(oGameChanger.groupGridSize - 1, cellX + floor(brushSize / 2));
				var cellRangeYMax = min(oGameChanger.groupGridSize - 1, cellY + floor(brushSize / 2));
				
				switch (mouseButton) {
					case mb_left:
						// Place tile / move object
						switch (oGameChanger.groupPlacementTypeSelected) {
							case 0:
								// Tile
								ds_grid_set_region(groupCurrent.tileGrid, cellRangeXMin, cellRangeYMin, cellRangeXMax, cellRangeYMax, TILE.WALL);
								break;
							case 1:
								// Prop
								var currentProp;
								
								var hoveredPropIndexArray = CheckMouseHoversProp();
								if (array_length(hoveredPropIndexArray) > 0) {
									// Select prop
									var foundLast = false;
									for (var i = 0; i < array_length(hoveredPropIndexArray); i ++) {
										if (hoveredPropIndexArray[i] == oGameChanger.groupCurrentPropListSelected) {
											foundLast = true;
										}
									}
									if (!foundLast) oGameChanger.groupCurrentPropListSelected = hoveredPropIndexArray[0];
									
									// Move prop
									currentProp = groupCurrent.propList[| oGameChanger.groupCurrentPropListSelected];
									
									var sprH = sprite_get_height(currentProp.sprite) * oCamera.zoom.base / 2;
									currentProp.x = mouseX / oCamera.zoom.base;
									currentProp.y = (mouseY + sprH) / oCamera.zoom.base;
									if (oGameChanger.groupGridSnapping) {
										currentProp.x = currentProp.x div oMain.tileSize * oMain.tileSize;
										currentProp.y = currentProp.y div oMain.tileSize * oMain.tileSize;
									}
								} else {
									// Make sure the click only triggers once
									if (!mouse_check_button_pressed(mouseButton)) return;
									
									// Spawn new prop
									currentProp = {};
									currentProp.name = oGameChanger.propCurrent.name;
									currentProp.sprite = asset_get_index(currentProp.name);
									currentProp.rotation = 0;
									currentProp.depth = 0;
									
									var sprH = sprite_get_height(currentProp.sprite) * oCamera.zoom.base / 2;
									currentProp.x = mouseX / oCamera.zoom.base;
									currentProp.y = (mouseY + sprH) / oCamera.zoom.base;
									if (oGameChanger.groupGridSnapping) {
										currentProp.x = currentProp.x div oMain.tileSize * oMain.tileSize;
										currentProp.y = currentProp.y div oMain.tileSize * oMain.tileSize;
									}
									
									ds_list_add(groupCurrent.propList, currentProp);
									oGameChanger.groupCurrentPropListSelected = ds_list_size(groupCurrent.propList) - 1;
								}
								
								// Override prop property sliders
								oGameChanger.groupCurrentPropDepth = currentProp.depth;
								oGameChanger.groupCurrentPropRotation = currentProp.rotation;
								
								var slider;
								slider = oGameChanger.uiElementGroupPropDepthSlider.slider;
								slider.OverrideSlider();
								slider.UpdateNestedSurface();
								
								slider = oGameChanger.uiElementGroupPropRotationSlider.slider;
								slider.OverrideSlider();
								slider.UpdateNestedSurface();
								break;
						}
						
						oGameChanger.AddUnsavedChanges();
						break;
					case mb_right:
						// Remove tile
						switch (oGameChanger.groupPlacementTypeSelected) {
							case 0:
								// Tile
								ds_grid_set_region(groupCurrent.tileGrid, cellRangeXMin, cellRangeYMin, cellRangeXMax, cellRangeYMax, TILE.VOID);
								oGameChanger.AddUnsavedChanges();
								break;
							case 1:
								// Prop
								// Make sure the click only triggers once
								if (!mouse_check_button_pressed(mouseButton)) return;
								
								var hoveredPropIndexArray = CheckMouseHoversProp();
								if (array_length(hoveredPropIndexArray) > 0) {
									// Delete prop
									ds_list_delete(groupCurrent.propList, hoveredPropIndexArray[0]);
									oGameChanger.groupCurrentPropListSelected = -1;
								}
								break;
						}
						break;
				}
				
				// Update surface
				parent.UpdateNestedSurface();
				
				// Update UI
				oGameChanger.UpdateGroupEditorInfo();
			}
		};
	}
	
	// Add elements as children
	self.AddChild(scrollBarSeparator);
	self.AddChild(scrollBarH);
	self.AddChild(scrollBarV);
	self.AddChild(view);
	view.content.AddChild(groupElement);
};
