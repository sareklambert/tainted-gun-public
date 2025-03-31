/// @function				UITextComponent(text, halign);
/// @description			Constructor for a UITextComponent.
/// @param {String} text		The text string.
/// @param {Constant.HAlign} [halign]	The horizontal alignment.
function UITextComponent(text, halign) : UIComponent() constructor {
	// Create text struct
	self.textStruct = scribble(text);
	if (is_undefined(halign)) halign = fa_center;
	
	// Format text
	textStruct.padding(2, 2, 2, 2);
	textStruct.align(halign, fa_middle);
	
	// Define functions
	Draw = function(x, y) {
		textStruct.draw(x, y);
	};
};

/// @function				UISpriteComponent(sprite, xScale, yScale, rot, col, alpha);
/// @description			Constructor for a UISpriteComponent.
/// @param {Asset.GMSprite} sprite	The sprite to use.
/// @param {Real} xScale		The x scale to use.
/// @param {Real} yScale		The y scale to use.
/// @param {Real} rot			The rotation to use.
/// @param {Constant.Color} col		The color to use.
/// @param {Real} alpha			The alpha to use.
function UISpriteComponent(sprite, xScale, yScale, rot, col, alpha) : UIComponent() constructor {
	// Get inputs
	self.sprite = sprite;
	self.xScale = xScale;
	self.yScale = yScale;
	self.rot = rot;
	self.col = col;
	self.alpha = alpha;
	
	// Define functions
	Draw = function(x, y) {
		draw_sprite_ext(sprite, 0, x, y, xScale * oCamera.zoom.base, yScale * oCamera.zoom.base, rot, col, alpha);
	};
};
