/// @description Initialize the loading screen scene
#region Initialize functions
/// @function				LoadingScreenUpdate(log, title, progress, overrideLast);
/// @param {String} log			A new log or "".
/// @param {String} title		The big title text or "".
/// @param {Real} progress		The loading progress 0-1.
/// @param {Bool} overrideLast	        Override the last entry?
/// @description			Loads a scene.
LoadingScreenUpdate = function(log, title, progress, overrideLast) {
	if (log != "") {
		if (overrideLast) ds_list_delete(loadingScreenLog, ds_list_size(loadingScreenLog) - 1);
		
		ds_list_add(loadingScreenLog, log + "\n");
	}
	if (title != "") loadingScreenTitleText = title;
	loadingScreenProgress = progress;
};
#endregion

// Initialize display variables
loadingScreenLog = ds_list_create();
loadingScreenTitleText = "";
loadingScreenProgress = 0;
loadingScreenIndex = irandom(sprite_get_number(sUILoadingScreenBg));
compressLog = false;
transition = new Transition(TRANSITION.DIAMOND, oCamera.windowResolution.x, oCamera.windowResolution.y, 2);

// Initialize scene variables
sceneToLoad = undefined;
newScene = undefined;

// Initialize map generator variables
mapGenStage = MAP_GEN_STAGE.NONE;
mapGenProcessorIndex = -1;

// Initialize variables used during map generation
mapGenGroupList = ds_list_create();
mapGenGroupAmount = 0;
