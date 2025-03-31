/// @description Clear memory
if (ds_exists(loadingScreenLog, ds_type_list)) ds_list_destroy(loadingScreenLog);
transition.Cleanup();

// Delete temporary data structures in case the game ends during loading
if (ds_exists(mapGenGroupList, ds_type_list)) ds_list_destroy(mapGenGroupList);
