/// @description Load scene step event
switch (sceneToLoad) {
	case SCENE.DUNGEON:
		#region Generate dungeon
		switch (mapGenStage) {
			case MAP_GEN_STAGE.NONE:
				#region Create scene
				newScene = instance_create_layer(0, 0, "System", oSceneDungeon);
				newScene.dungeonType = DUNGEON.OVERRUN_SECTOR; // TEMP dungeonType is hard coded here
				
				// Pause the game
				oMain.gameSpeed = 0;
				
				mapGenStage = MAP_GEN_STAGE.INIT;
				#endregion
				break;
			case MAP_GEN_STAGE.INIT:
				#region Initialize
				// Log progress
				LoadingScreenUpdate("INIT", "Initializing", 0.01, false);
				
				with (newScene) {
					#region Load level data
					var dungeonsArray = tj_get(oMain.fileDungeonsRoot, "dungeons");
					roomsHorizontal = ds_list_create();
					roomsVertical = ds_list_create();
					roomsDrop = ds_list_create();
					roomsLand = ds_list_create();
					
					var currentPatternsArray, currentPatternsArraySize, currentRoom, currentTileString, currentTileStringSize, currentExitPos, currentRoomsList, currentTile;
					for (var i = 0; i < 4; i++) {
						currentPatternsArray = tj_get(dungeonsArray[dungeonType], "mapGenPatterns")[i];
						currentPatternsArraySize = array_length(currentPatternsArray);
						
						switch (i) {
							case 0:
								currentRoomsList = roomsHorizontal;
								break;
							case 1:
								currentRoomsList = roomsVertical;
								break;
							case 2:
								currentRoomsList = roomsDrop;
								break;
							case 3:
								currentRoomsList = roomsLand;
								break;
						}
						
						for (var j = 0; j < currentPatternsArraySize; j++) {
							currentRoom = new MapRoom();
							
							currentTileString = tj_get(currentPatternsArray[j], "tilesFG");
							currentTileStringSize = string_length(currentTileString);
							for (var k = 0; k < currentTileStringSize; k++) {
								switch (string_char_at(currentTileString, k + 1)) {
									case "0":
										currentTile = TILE.VOID;
										break;
									case "1":
										currentTile = TILE.WALL;
										break;
									default:
										currentTile = TILE.MAPGEN_HAZARD;
										break;
								}
								currentRoom.tilesFG[# k - k div oMain.roomWidthTiles * oMain.roomWidthTiles, k div oMain.roomWidthTiles] = currentTile;
							}
							
							currentTileString = tj_get(currentPatternsArray[j], "tilesBG");
							currentTileStringSize = string_length(currentTileString);
							for (var k = 0; k < currentTileStringSize; k++) {
								switch (string_char_at(currentTileString, k + 1)) {
									case "0":
										currentTile = TILE.VOID;
										break;
									case "1":
										currentTile = TILE.WALL;
										break;
									default:
										currentTile = TILE.MAPGEN_HAZARD;
										break;
								}
								currentRoom.tilesBG[# k - k div oMain.roomWidthTiles * oMain.roomWidthTiles, k div oMain.roomWidthTiles] = currentTile;
							}
							
							currentExitPos = tj_get(currentPatternsArray[j], "exit");
							currentRoom.exitPos.x = tj_get(currentExitPos, "x");
							currentRoom.exitPos.y = tj_get(currentExitPos, "y");
							
							ds_list_add(currentRoomsList, currentRoom);
						}
					}
					#endregion
					
					// Initialize map generator variables
					playerSpawnPos = {x : 0, y : 0};
					mapGenRoomGrid = ds_grid_create(1, 1);
					mapGenRoomAmount = 0;
					
					// Get weights and room amount
					mapGenWeights = array_create(4, 0);
					allowPatternCorridorV = tj_get(dungeonsArray[dungeonType], "mapGenAllowPatternV");
					mapGenWeights = tj_get(dungeonsArray[dungeonType], "mapGenWeightsDirection");
					
					mapGenRoomAmount = irandom_range(18, 30); // TEMP hard coded here, load from json
					mapGenRoomAmount = 4; // TEMP hard coded here
				}
				
				// Go to next stage
				mapGenStage = MAP_GEN_STAGE.ASSEMBLE_ROOMS;
				#endregion
				break;
			case MAP_GEN_STAGE.ASSEMBLE_ROOMS:
				#region Assemble rooms
				// Log progress
				LoadingScreenUpdate("ASSEMBLE_ROOMS", "Choosing interesting rooms", 0.02, false);
				
				with (newScene) {
					var mapGenSuccess, mapGenCurrentRoom, mapGenDir, mapGenDirLegal, mapGenPatternOther;
					
					do {
						// Reset generator variables
						mapGenSuccess = true;
						mapGenRoomCount = 1;
						mapGenPos = {x : 0, y : 0};
						ds_grid_resize(mapGenRoomGrid, 1, 1);
						
						// Create starting room
						mapGenRoomGrid[# 0, 0] = new MapRoomPlaceholder();
						mapGenRoomGrid[# 0, 0].isEntrance = true;
						
						// Generate rooms
						while (mapGenRoomCount <= mapGenRoomAmount) {
							// Get current room
							mapGenCurrentRoom = mapGenRoomGrid[# mapGenPos.x, mapGenPos.y];
							
							// Choose new direction
							mapGenDir = RandomWeighted(mapGenWeights);
							
							// Check if we can advance in the direction
							if (!MapGenCheckDir(mapGenDir, allowPatternCorridorV)) {
								// Check if we're stuck
								if !(MapGenCheckDir(0, allowPatternCorridorV) || MapGenCheckDir(1, allowPatternCorridorV) || MapGenCheckDir(2, allowPatternCorridorV) || MapGenCheckDir(3, allowPatternCorridorV)) {
									mapGenSuccess = false;
									break;
								}
							} else {
								// Advance in direction
								switch (mapGenDir) {
									case 0:
										// Set current rooms pattern
										mapGenPatternOther = MapGenGetRoomPattern(mapGenPos.x, mapGenPos.y - 1);
										
										if (mapGenPatternOther == MAP_GEN_ROOM_PATTERN.DROP || mapGenPatternOther == MAP_GEN_ROOM_PATTERN.CORRIDOR_V) {
											mapGenCurrentRoom.pattern = MAP_GEN_ROOM_PATTERN.LAND;
										} else {
											mapGenPatternOther = MapGenGetRoomPattern(mapGenPos.x, mapGenPos.y + 1);
											
											if (mapGenPatternOther == MAP_GEN_ROOM_PATTERN.LAND || mapGenPatternOther == MAP_GEN_ROOM_PATTERN.CORRIDOR_V) {
												mapGenCurrentRoom.pattern = MAP_GEN_ROOM_PATTERN.DROP;
											} else {
												mapGenCurrentRoom.pattern = MAP_GEN_ROOM_PATTERN.CORRIDOR_H;
											}
										}
										
										// Advance left
										MapGenAdvance(-1, 0);
										break;
									case 1:
										// Set current rooms pattern
										mapGenPatternOther = MapGenGetRoomPattern(mapGenPos.x, mapGenPos.y - 1);
										
										if (mapGenPatternOther == MAP_GEN_ROOM_PATTERN.DROP || mapGenPatternOther == MAP_GEN_ROOM_PATTERN.CORRIDOR_V) {
											mapGenCurrentRoom.pattern = MAP_GEN_ROOM_PATTERN.LAND;
										} else {
											mapGenPatternOther = MapGenGetRoomPattern(mapGenPos.x, mapGenPos.y + 1);
											
											if (mapGenPatternOther == MAP_GEN_ROOM_PATTERN.LAND || mapGenPatternOther == MAP_GEN_ROOM_PATTERN.CORRIDOR_V) {
												mapGenCurrentRoom.pattern = MAP_GEN_ROOM_PATTERN.DROP;
											} else {
												mapGenCurrentRoom.pattern = MAP_GEN_ROOM_PATTERN.CORRIDOR_H;
											}
										}
										
										// Advance right
										MapGenAdvance(1, 0);
										break;
									case 2:
										// Set current rooms pattern
										mapGenPatternOther = MapGenGetRoomPattern(mapGenPos.x, mapGenPos.y + 1);
										mapGenDirLegal = true;
										
										if (mapGenPatternOther == MAP_GEN_ROOM_PATTERN.LAND || mapGenPatternOther == MAP_GEN_ROOM_PATTERN.CORRIDOR_V) {
											if (allowPatternCorridorV) {
												mapGenCurrentRoom.pattern = MAP_GEN_ROOM_PATTERN.CORRIDOR_V;
											} else {
												mapGenDirLegal = false;
											}
										} else {
											mapGenCurrentRoom.pattern = MAP_GEN_ROOM_PATTERN.LAND;
										}
										
										// Advance top
										if (mapGenDirLegal) MapGenAdvance(0, -1);
										break;
									case 3:
										// Set current rooms pattern
										mapGenPatternOther = MapGenGetRoomPattern(mapGenPos.x, mapGenPos.y - 1);
										mapGenDirLegal = true;
										
										if (mapGenPatternOther == MAP_GEN_ROOM_PATTERN.DROP || mapGenPatternOther == MAP_GEN_ROOM_PATTERN.CORRIDOR_V) {
											if (allowPatternCorridorV) {
												mapGenCurrentRoom.pattern = MAP_GEN_ROOM_PATTERN.CORRIDOR_V;
											} else {
												mapGenDirLegal = false;
											}
										} else {
											mapGenCurrentRoom.pattern = MAP_GEN_ROOM_PATTERN.DROP;
										}
										
										// Advance bottom
										if (mapGenDirLegal) MapGenAdvance(0, 1);
										break;
								}
							}
						}
						
						// Check if the map generator failed
						if (!mapGenSuccess) {
							// Delete data and try again
							for (var i = 0; i < ds_grid_width(mapGenRoomGrid); i++) {
								for (var j = 0; j < ds_grid_height(mapGenRoomGrid); j++) {
									mapGenCurrentRoom = mapGenRoomGrid[# i, j];
									
									if (is_struct(mapGenCurrentRoom)) delete mapGenRoomGrid[# i, j];
								}
							}
						}
					} until (mapGenSuccess);
					
					// Set exit room
					mapGenCurrentRoom = mapGenRoomGrid[# mapGenPos.x, mapGenPos.y];
					mapGenCurrentRoom.isExit = true;
					
					// Create a one room wide border around the map
					var ww = ds_grid_width(mapGenRoomGrid), hh = ds_grid_height(mapGenRoomGrid);
					
					ds_grid_resize(mapGenRoomGrid, ww + 2, hh + 2);
					ds_grid_set_grid_region(mapGenRoomGrid, mapGenRoomGrid, 0, 0, ww - 1, hh - 1, 1, 1);
					ds_grid_set_region(mapGenRoomGrid, 0, 0, ww + 2, 0, 0);
					ds_grid_set_region(mapGenRoomGrid, 0, 0, 0, hh + 2, 0);
					
					// Calculate map dimensions
					mapWidthChunks = ceil((oMain.tileSize * oMain.roomWidthTiles * ds_grid_width(mapGenRoomGrid)) / oMain.chunkSizePixels);
					mapHeightChunks = ceil((oMain.tileSize * oMain.roomHeightTiles * ds_grid_height(mapGenRoomGrid)) / oMain.chunkSizePixels);
					mapWidthTiles = mapWidthChunks * oMain.chunkSizeTiles;
					mapHeightTiles = mapHeightChunks * oMain.chunkSizeTiles;
					
					// Resize room
					room_width = mapWidthChunks * oMain.chunkSizePixels;
					room_height = mapHeightChunks * oMain.chunkSizePixels;
				}
				
				// Advance to next stage
				mapGenStage = MAP_GEN_STAGE.SEPARATE_CHUNKS;
				#endregion
				break;
			case MAP_GEN_STAGE.SEPARATE_CHUNKS:
				#region Separate chunks
				if (mapGenProcessorIndex == -1) {
					// Log progress
					LoadingScreenUpdate("SEPARATE_CHUNKS", "Making things faster", 0.10, false);
					
					with (newScene) {
						// Set up chunks
						chunkGrid = ds_grid_create(mapWidthChunks, mapHeightChunks);
						for (var i = 0; i < mapWidthChunks; i++) {
							for (var j = 0; j < mapHeightChunks; j++) {
								chunkGrid[# i, j] = new Chunk(i * oMain.chunkSizePixels, j * oMain.chunkSizePixels);
							}
						}
					}
					
					LoadingScreenUpdate("> Created " + string(newScene.mapWidthChunks * newScene.mapHeightChunks) + " chunks", "", 0.10, false);
					LoadingScreenUpdate("> Writing rooms", "", 0.10, false);
					
					// Start processor
					mapGenProcessorIndex = 0;
				} else {
					with (newScene) {
						// Get room pattern and transfer tile data to chunks
						var processorMax = ds_grid_width(mapGenRoomGrid) * ds_grid_height(mapGenRoomGrid);
						var maxIteration = min(processorMax, other.mapGenProcessorIndex + mapGenProcessMaxRooms);
						var i, j;
						
						for (other.mapGenProcessorIndex = other.mapGenProcessorIndex; other.mapGenProcessorIndex < maxIteration; other.mapGenProcessorIndex++) {
							i = other.mapGenProcessorIndex div ds_grid_height(mapGenRoomGrid);
							j = other.mapGenProcessorIndex mod ds_grid_height(mapGenRoomGrid);
							
						    mapGenCurrentRoom = mapGenRoomGrid[# i, j];
							
							if (is_struct(mapGenCurrentRoom)) {
								mapGenCurrentRoom.Generate(i, j);
							}
						}
					}
					
					// Log process
					LoadingScreenUpdate("> Writing room (" + string(mapGenProcessorIndex) + " / " + string(processorMax) + ")", "", 0.10 + 0.10 * mapGenProcessorIndex / processorMax, compressLog);
					
					// Check if processor completed
					if (mapGenProcessorIndex == processorMax) {
						LoadingScreenUpdate("> Writing rooms completed", "", 0.20, false);
						
						// Advance to next stage
						mapGenProcessorIndex = -1;
						mapGenStage = MAP_GEN_STAGE.GENERATE_END_PIECES;
					}
				}
				#endregion
				break;
			case MAP_GEN_STAGE.GENERATE_END_PIECES:
				#region Generate end pieces
				if (mapGenProcessorIndex == -1) {
					// Log progress
					LoadingScreenUpdate("GENERATE_END_PIECES", "Generating cave ends", 0.20, false);
					LoadingScreenUpdate("> Generating cave ends", "", 0.20, false);
					
					// Start processor
					mapGenProcessorIndex = 0;
				} else {
					with (newScene) {
						// Carve out ellipses of room ends
						var processorMax = ds_grid_width(mapGenRoomGrid) * ds_grid_height(mapGenRoomGrid);
						var maxIteration = min(processorMax, other.mapGenProcessorIndex + mapGenProcessMaxRooms);
						var i, j;
						
						var currentChunk, tileX, tileY, chunkX, chunkY;
						var radius, circleOff, measureCircleOff;
						var shift = 6;
						
						var mapGenCurrentRoom;
						for (other.mapGenProcessorIndex = other.mapGenProcessorIndex; other.mapGenProcessorIndex < maxIteration; other.mapGenProcessorIndex++) {
							i = other.mapGenProcessorIndex div ds_grid_height(mapGenRoomGrid);
							j = other.mapGenProcessorIndex mod ds_grid_height(mapGenRoomGrid);
							
						    mapGenCurrentRoom = mapGenRoomGrid[# i, j];
							
							if (!is_struct(mapGenCurrentRoom)) {
								#region Left
								if (i - 1 > 0) {
									mapGenCurrentRoom = mapGenRoomGrid[# i - 1, j];
									
									if (is_struct(mapGenCurrentRoom) && mapGenCurrentRoom.pattern != MAP_GEN_ROOM_PATTERN.CORRIDOR_V) {
										// Get circle radius
										radius = 0;
										circleOff = 0;
										measureCircleOff = true;
										
										for (var k = 0; k < oMain.roomHeightTiles; k++) {
											tileX = i * oMain.roomWidthTiles - 1;
											tileY = j * oMain.roomHeightTiles + k;
											chunkX = tileX div oMain.chunkSizeTiles;
											chunkY = tileY div oMain.chunkSizeTiles;
											
											var tile = chunkGrid[# chunkX, chunkY].tileGrid[# tileX - chunkX * oMain.chunkSizeTiles, tileY - chunkY * oMain.chunkSizeTiles];
											
											if (tile == TILE.VOID) {
												radius ++;
												measureCircleOff = false;
											} else if (measureCircleOff && tile == TILE.WALL) {
												circleOff ++;
											}
										}
										
										// Carve out circle
										for (var k = radius / 2; k <= radius; k++) {
										    for (var l = 0; l <= radius; l++) {
										        if (point_in_circle(k + shift, l, radius / 2, radius / 2, radius / 2)) {
										            tileX = i * oMain.roomWidthTiles + k - radius / 2;
													tileY = j * oMain.roomHeightTiles + l + circleOff;
													chunkX = tileX div oMain.chunkSizeTiles;
													chunkY = tileY div oMain.chunkSizeTiles;
													
													chunkGrid[# chunkX, chunkY].tileGrid[# tileX - chunkX * oMain.chunkSizeTiles, tileY - chunkY * oMain.chunkSizeTiles] = TILE.VOID;
										        }
										    }
										}
									}
								}
								#endregion
								#region Right
								if (i + 1 < mapWidthChunks) {
									mapGenCurrentRoom = mapGenRoomGrid[# i + 1, j];
									
									if (is_struct(mapGenCurrentRoom) && mapGenCurrentRoom.pattern != MAP_GEN_ROOM_PATTERN.CORRIDOR_V) {
										// Get circle radius
										radius = 0;
										circleOff = 0;
										measureCircleOff = true;
										
										for (var k = 0; k < oMain.roomHeightTiles; k++) {
											tileX = (i + 1) * oMain.roomWidthTiles;
											tileY = j * oMain.roomHeightTiles + k;
											chunkX = tileX div oMain.chunkSizeTiles;
											chunkY = tileY div oMain.chunkSizeTiles;
											
											var tile = chunkGrid[# chunkX, chunkY].tileGrid[# tileX - chunkX * oMain.chunkSizeTiles, tileY - chunkY * oMain.chunkSizeTiles];
											
											if (tile == TILE.VOID) {
												radius ++;
												measureCircleOff = false;
											} else if (measureCircleOff && tile == TILE.WALL) {
												circleOff ++;
											}
										}
										
										// Carve out circle
										for (var k = 0; k <= radius / 2; k++) {
										    for (var l = 0; l <= radius; l++) {
										        if (point_in_circle(k - shift, l, radius / 2, radius / 2, radius / 2)) {
												    tileX = (i + 1) * oMain.roomWidthTiles + k - radius / 2;
													tileY = j * oMain.roomHeightTiles + l + circleOff;
													chunkX = tileX div oMain.chunkSizeTiles;
													chunkY = tileY div oMain.chunkSizeTiles;
													
													chunkGrid[# chunkX, chunkY].tileGrid[# tileX - chunkX * oMain.chunkSizeTiles, tileY - chunkY * oMain.chunkSizeTiles] = TILE.VOID;
												}
										    }
										}
									}
								}
								#endregion
								#region Top
								if (j - 1 > 0) {
									mapGenCurrentRoom = mapGenRoomGrid[# i, j - 1];
									
									if (is_struct(mapGenCurrentRoom) && (mapGenCurrentRoom.pattern == MAP_GEN_ROOM_PATTERN.DROP || mapGenCurrentRoom.pattern == MAP_GEN_ROOM_PATTERN.CORRIDOR_V)) {
										// Get circle radius
										radius = 0;
										circleOff = 0;
										measureCircleOff = true;
										
										for (var k = 0; k < oMain.roomHeightTiles; k++) {
											tileX = i * oMain.roomWidthTiles + k;
											tileY = j * oMain.roomHeightTiles - 1;
											chunkX = tileX div oMain.chunkSizeTiles;
											chunkY = tileY div oMain.chunkSizeTiles;
											
											var tile = chunkGrid[# chunkX, chunkY].tileGrid[# tileX - chunkX * oMain.chunkSizeTiles, tileY - chunkY * oMain.chunkSizeTiles];
											
											if (tile == TILE.VOID) {
												radius ++;
												measureCircleOff = false;
											} else if (measureCircleOff && tile == TILE.WALL) {
												circleOff ++;
											}
										}
										
										// Carve out circle
										for (var k = 0; k <= radius; k++) {
										    for (var l = radius / 2; l <= radius; l++) {
										        if (point_in_circle(k, l + shift, radius / 2, radius / 2, radius / 2)) {
												    tileX = i * oMain.roomWidthTiles + k + circleOff;
													tileY = j * oMain.roomHeightTiles + l - radius / 2;
													chunkX = tileX div oMain.chunkSizeTiles;
													chunkY = tileY div oMain.chunkSizeTiles;
													
													chunkGrid[# chunkX, chunkY].tileGrid[# tileX - chunkX * oMain.chunkSizeTiles, tileY - chunkY * oMain.chunkSizeTiles] = TILE.VOID;
												}
										    }
										}
									}
								}
								#endregion
								#region Bottom
								if (j + 1 < mapHeightChunks) {
									mapGenCurrentRoom = mapGenRoomGrid[# i, j + 1];
									
									if (is_struct(mapGenCurrentRoom) && (mapGenCurrentRoom.pattern == MAP_GEN_ROOM_PATTERN.LAND || mapGenCurrentRoom.pattern == MAP_GEN_ROOM_PATTERN.CORRIDOR_V)) {
										// Get circle radius
										radius = 0;
										circleOff = 0;
										measureCircleOff = true;
										
										for (var k = 0; k < oMain.roomHeightTiles; k++) {
											tileX = i * oMain.roomWidthTiles + k;
											tileY = (j + 1) * oMain.roomHeightTiles;
											chunkX = tileX div oMain.chunkSizeTiles;
											chunkY = tileY div oMain.chunkSizeTiles;
											
											var tile = chunkGrid[# chunkX, chunkY].tileGrid[# tileX - chunkX * oMain.chunkSizeTiles, tileY - chunkY * oMain.chunkSizeTiles];
											
											if (tile == TILE.VOID) {
												radius ++;
												measureCircleOff = false;
											} else if (measureCircleOff && tile == TILE.WALL) {
												circleOff ++;
											}
										}
										
										// Carve out circle
										for (var k = 0; k <= radius; k++) {
										    for (var l = 0; l <= radius / 2; l++) {
										        if (point_in_circle(k, l - shift, radius / 2, radius / 2, radius / 2)) {
													tileX = i * oMain.roomWidthTiles + k + circleOff;
													tileY = (j + 1) * oMain.roomHeightTiles + l - radius / 2;
													chunkX = tileX div oMain.chunkSizeTiles;
													chunkY = tileY div oMain.chunkSizeTiles;
													
													chunkGrid[# chunkX, chunkY].tileGrid[# tileX - chunkX * oMain.chunkSizeTiles, tileY - chunkY * oMain.chunkSizeTiles] = TILE.VOID;
												}
										    }
										}
									}
								}
								#endregion
							}
						}
					}
					
					// Log process
					LoadingScreenUpdate("> Generating cave ends for room (" + string(mapGenProcessorIndex) + " / " + string(processorMax) + ")", "", 0.20 + 0.10 * mapGenProcessorIndex / processorMax, compressLog);
					
					// Check if processor completed
					if (mapGenProcessorIndex == processorMax) {
						LoadingScreenUpdate("> Generating cave ends completed", "", 0.30, false);
						
						with (newScene) {
							// Destroy room grid
							ds_grid_destroy(mapGenRoomGrid);
						}
						
						// Advance to next stage
						mapGenProcessorIndex = -1;
						mapGenStage = MAP_GEN_STAGE.GENERATE_PROPS;
					}
				}
				#endregion
				break;
			case MAP_GEN_STAGE.GENERATE_PROPS:
				#region Generate props from groups
				if (mapGenProcessorIndex == -1) {
					// Log progress
					LoadingScreenUpdate("GENERATE_PROPS", "Generating props", 0.30, false);
					LoadingScreenUpdate("> Generating props", "", 0.30, false);
					
					// Set up variables
					// Load group data
					var groupListObject = tj_get(oMain.fileGroupsRoot, "groups");
					var groupArray = [];
					
					switch (newScene.dungeonType) {
						case DUNGEON.OVERRUN_SECTOR:
							groupArray = tj_get(groupListObject, "Overrun Sector");
							break;
					}
					
					mapGenGroupAmount = array_length(groupArray);
					
					for (var i = 0; i < mapGenGroupAmount; i ++) {
						ds_list_add(mapGenGroupList, groupArray[i]);
					}
					
					// Start processor
					mapGenProcessorIndex = 0;
				} else {
					var processorMax = mapGenGroupAmount;
					var maxIteration = min(processorMax, mapGenProcessorIndex + newScene.mapGenProcessMaxPropGroups);
					
					var groupIndex, currentGroupData, currentSpawnAmount, currentGroupTileGridWidth, currentGroupTileGridHeight;
					var currentGroupTileGridString, currentGroupTileGrid, currentGroupIgnoreOthers, spawnOffset, currentSpawnPositionsList;
					var spawnGridWidth, spawnGridHeight, breakCurrentPatternScan, currentSpawnPositionsGrid;
					var currentTileXRaw, currentTileYRaw, currentChunkX, currentChunkY, currentTileXInChunk, currentTileYInChunk, currentTileType;
					var currentSpawnPositionsListIndex, currentSpawnPosition, currentChunk, currentPropArray;
					
					with (newScene) {
						for (other.mapGenProcessorIndex = other.mapGenProcessorIndex; other.mapGenProcessorIndex < maxIteration; other.mapGenProcessorIndex++) {
							// Select a group
							groupIndex = irandom(ds_list_size(other.mapGenGroupList) - 1);
							currentGroupData = other.mapGenGroupList[| groupIndex];
							
							// Get desired spawn amount
							switch (tj_get(currentGroupData, "flagRarity")) {
								case 0:
									// Common
									currentSpawnAmount = round(random_range(mapGenGroupSpawnRatesCommon.minimum, mapGenGroupSpawnRatesCommon.maximum) * mapWidthChunks * mapHeightChunks);
									break;
								case 1:
									// Uncommon
									currentSpawnAmount = round(random_range(mapGenGroupSpawnRatesUncommon.minimum, mapGenGroupSpawnRatesUncommon.maximum) * mapWidthChunks * mapHeightChunks);
									break;
								case 2:
									// Rare
									currentSpawnAmount = round(random_range(mapGenGroupSpawnRatesRare.minimum, mapGenGroupSpawnRatesRare.maximum) * mapWidthChunks * mapHeightChunks);
									break;
								case 3:
									// Very rare
									currentSpawnAmount = round(random_range(mapGenGroupSpawnRatesVeryRare.minimum, mapGenGroupSpawnRatesVeryRare.maximum) * mapWidthChunks * mapHeightChunks);
									break;
							}
							
							// Get group's dimensions
							currentGroupTileGridWidth = tj_get(currentGroupData, "tileGridWidth");
							currentGroupTileGridHeight = tj_get(currentGroupData, "tileGridHeight");
							
							// Get group's tile grid
							currentGroupTileGridString = tj_get(currentGroupData, "tileGrid");
							currentGroupTileGrid = ds_grid_create(currentGroupTileGridWidth, currentGroupTileGridHeight);
							
							currentTileStringSize = string_length(currentGroupTileGridString);
							for (var i = 0; i < currentTileStringSize; i++) {
								currentGroupTileGrid[# i - i div currentGroupTileGridWidth * currentGroupTileGridWidth, i div currentGroupTileGridWidth] = real(string_char_at(currentGroupTileGridString, i + 1));
							}
							
							// Get group's props array
							currentPropArray = tj_get(currentGroupData, "propArray");
							
							// Get group's ignore others flag
							currentGroupIgnoreOthers = tj_get(currentGroupData, "flagIgnoreOthers");
							
							// Initialize the spawn offset and available spawn positions data structures
							spawnOffset = 0;
							currentSpawnPositionsList = ds_list_create();
							currentSpawnPositionsGrid = -1;
							
							while (currentSpawnAmount > 0 && spawnOffset < min(currentGroupTileGridWidth, currentGroupTileGridHeight)) {
								// Get current spawn grid dimensions
								spawnGridWidth = (mapWidthChunks * oMain.chunkSizeTiles - spawnOffset) div currentGroupTileGridWidth;
								spawnGridHeight = (mapHeightChunks * oMain.chunkSizeTiles - spawnOffset) div currentGroupTileGridHeight;
								
								currentSpawnPositionsGrid = ds_grid_create(spawnGridWidth, spawnGridHeight);
								ds_grid_clear(currentSpawnPositionsGrid, false);
								
								// Iterate through the map using the spawn grid dimensions
								// Scan each cell and note down possible spawn positions
								for (var i = 0; i < spawnGridWidth; i ++) {
									for (var j = 0; j < spawnGridHeight; j ++) {
										
										// Check if the current cell matches the pattern of the group we're trying to spawn
										breakCurrentPatternScan = false;
										
										for (var k = 0; k < currentGroupTileGridWidth; k++) {
											for (var l = 0; l < currentGroupTileGridHeight; l++) {
												currentTileXRaw = i * currentGroupTileGridWidth + spawnOffset + k;
												currentTileYRaw = j * currentGroupTileGridHeight + spawnOffset + l;
												currentChunkX = currentTileXRaw div oMain.chunkSizeTiles;
												currentChunkY = currentTileYRaw div oMain.chunkSizeTiles;
												currentTileXInChunk = currentTileXRaw - currentChunkX * oMain.chunkSizeTiles;
												currentTileYInChunk = currentTileYRaw - currentChunkY * oMain.chunkSizeTiles;
												
												currentTileType = chunkGrid[# currentChunkX, currentChunkY].tileGrid[# currentTileXInChunk, currentTileYInChunk];
												
												// Ignore blockers?
												if (currentTileType == TILE.MAPGEN_PROP_BLOCKER && currentGroupIgnoreOthers) currentTileType = TILE.VOID;
												
												if (currentTileType != currentGroupTileGrid[# k, l]) {
													breakCurrentPatternScan = true;
													break;
												}
											}
											
											if (breakCurrentPatternScan) break;
										}
										
										// Check if we found a valid spawn position
										if (!breakCurrentPatternScan) {
											currentSpawnPositionsGrid[# i, j] = true;
											ds_list_add(currentSpawnPositionsList, {x : i, y : j});
										}
									}
								}
								
								// Spawn groups if possible
								while (ds_list_size(currentSpawnPositionsList) > 0) {
									// Get current spawn position
									var currentSpawnPositionsListIndex = irandom(ds_list_size(currentSpawnPositionsList) - 1);
									var currentSpawnPosition = currentSpawnPositionsList[| currentSpawnPositionsListIndex];
									
									// Make sure the spawn position is still valid (spawning a group blocks neightbouring cells)
									if (currentSpawnPositionsGrid[# currentSpawnPosition.x, currentSpawnPosition.y]) {
										// Spawn group
										var currentOffsetX = (currentSpawnPosition.x * currentGroupTileGridWidth + spawnOffset) * oMain.tileSize;
										var currentOffsetY = (currentSpawnPosition.y * currentGroupTileGridHeight + spawnOffset) * oMain.tileSize;
										currentChunkX = currentOffsetX div oMain.chunkSizePixels;
										currentChunkY = currentOffsetY div oMain.chunkSizePixels;
										
										currentChunk = chunkGrid[# currentChunkX, currentChunkY];
										
										for (var i = 0; i < array_length(currentPropArray); i ++) {
											var currentProp = {};
											currentProp.name = tj_get(currentPropArray[i], "name");
											currentProp.sprite = asset_get_index(currentProp.name);
											currentProp.rotation = tj_get(currentPropArray[i], "rotation");
											currentProp.depth = tj_get(currentPropArray[i], "depth");
											currentProp.x = round(tj_get(currentPropArray[i], "x") + currentOffsetX);
											currentProp.y = round(tj_get(currentPropArray[i], "y") + currentOffsetY);
											
											ds_list_add(currentChunk.propList, new Prop(currentProp.x, currentProp.y, currentProp.depth, currentProp.sprite, currentProp.rotation));
										}
										
										// Mark map tiles as blocked for other props
										if (!currentGroupIgnoreOthers) {
											for (var i = 0; i < currentGroupTileGridWidth; i ++) {
												for (var j = 0; j < currentGroupTileGridHeight; j ++) {
													if (currentGroupTileGrid[# i, j] != TILE.VOID) continue;
													
													var currentTileXInChunk = currentSpawnPosition.x * currentGroupTileGridWidth + spawnOffset + i;
													var currentTileYInChunk = currentSpawnPosition.y * currentGroupTileGridHeight + spawnOffset + j;
													currentChunkX = currentTileXInChunk div oMain.chunkSizeTiles;
													currentChunkY = currentTileYInChunk div oMain.chunkSizeTiles;
													currentTileXInChunk -= currentTileXInChunk div oMain.chunkSizeTiles * oMain.chunkSizeTiles;
													currentTileYInChunk -= currentTileYInChunk div oMain.chunkSizeTiles * oMain.chunkSizeTiles;
													
													chunkGrid[# currentChunkX, currentChunkY].tileGrid[# currentTileXInChunk, currentTileYInChunk] = TILE.MAPGEN_PROP_BLOCKER;
												}
											}
										}
										
										// Mark neighbouring cells to not spawn another group
										ds_grid_set_region(currentSpawnPositionsGrid,
															max(0, currentSpawnPosition.x - 1), max(0, currentSpawnPosition.y - 1),
															min(spawnGridWidth - 1, currentSpawnPosition.x + 1), min(spawnGridHeight - 1, currentSpawnPosition.y + 1),
															false);
										
										// Decrease amount of props that need to be spawned
										currentSpawnAmount --;
										if (currentSpawnAmount <= 0) break;
									}
									
									// Remove spawn position from list
									ds_list_delete(currentSpawnPositionsList, currentSpawnPositionsListIndex);
								}
								
								// Increase spawn offset
								spawnOffset ++;
							}
							
							// Clear current data structures
							if (ds_exists(currentGroupTileGrid, ds_type_grid)) ds_grid_destroy(currentGroupTileGrid);
							if (ds_exists(currentSpawnPositionsList, ds_type_list)) ds_list_destroy(currentSpawnPositionsList);
							if (ds_exists(currentSpawnPositionsGrid, ds_type_grid)) ds_grid_destroy(currentSpawnPositionsGrid);
							
							// Delete the group from the list
							ds_list_delete(other.mapGenGroupList, groupIndex);
						}
					}
					
					// Log process
					LoadingScreenUpdate("> Generating prop group (" + string(mapGenProcessorIndex) + " / " + string(mapGenGroupAmount) + ")", "", 0.30 + 0.05 * mapGenProcessorIndex / processorMax, compressLog);
					
					// Check if processor completed
					if (mapGenProcessorIndex == processorMax) {
						LoadingScreenUpdate("> Generating props completed. Cleaning up blockers.", "", 0.35, false);
						
						// Clean up blockers
						with (newScene) {
							for (var i = 0; i < mapWidthChunks; i ++) {
								for (var j = 0; j < mapHeightChunks; j ++) {
									for (var k = 0; k < oMain.chunkSizeTiles; k ++) {
										for (var l = 0; l < oMain.chunkSizeTiles; l ++) {
											if (chunkGrid[# i, j].tileGrid[# k, l] == TILE.MAPGEN_PROP_BLOCKER) chunkGrid[# i, j].tileGrid[# k, l] = TILE.VOID;
										}
									}
								}
							}
						}
						
						// Advance to next stage
						mapGenProcessorIndex = -1;
						mapGenStage = MAP_GEN_STAGE.GENERATE_SLOPES;
					}
				}
				#endregion
				break;
			case MAP_GEN_STAGE.GENERATE_SLOPES:
				#region Generate slopes
				if (mapGenProcessorIndex == -1) {
					LoadingScreenUpdate("GENERATE_SLOPES", "Generating slopes", 0.35, false);
					LoadingScreenUpdate("> Generating slopes", "", 0.35, false);
					
					// Start processor
					mapGenProcessorIndex = 0;
				} else {
					var currentChunk;
					
					with (newScene) {
						// Generate slopes
						var processorMax = mapWidthChunks * mapHeightChunks;
						var maxIteration = min(processorMax, other.mapGenProcessorIndex + mapGenProcessMaxChunks);
						var i, j;
						
						for (other.mapGenProcessorIndex = other.mapGenProcessorIndex; other.mapGenProcessorIndex < maxIteration; other.mapGenProcessorIndex++) {
							i = other.mapGenProcessorIndex div mapHeightChunks;
							j = other.mapGenProcessorIndex mod mapHeightChunks;
							
							currentChunk = chunkGrid[# i, j];
							
							for (var k = 0; k < oMain.chunkSizeTiles; k++) {
								for (var l = 0; l < oMain.chunkSizeTiles; l++) {
									currentChunk.GenerateSlope(k, l);
								}
							}
						}
					}
					
					// Log process
					LoadingScreenUpdate("> Generating slopes at chunk (" + string(mapGenProcessorIndex) + " / " + string(processorMax) + ")", "", 0.35 + 0.05 * mapGenProcessorIndex / processorMax, compressLog);
					
					// Check if processor completed
					if (mapGenProcessorIndex == processorMax) {
						LoadingScreenUpdate("> Generating slopes completed", "", 0.40, false);
						
						// Advance to next stage
						mapGenProcessorIndex = -1;
						mapGenStage = MAP_GEN_STAGE.GENERATE_WALL_SHAPE_1;
					}
				}
				#endregion
				break;
			case MAP_GEN_STAGE.FINALIZE:
				#region Finalize
				LoadingScreenUpdate("FINALIZE", "Wrapping things up", 0.99, false);
				
				with (newScene) {
					// Spawn player
					instance_create_layer(playerSpawnPos.x, playerSpawnPos.y, "Instances", oPlayer);
					oPlayer.UpdateItemAttachmentSprite();
					
					// Reset camera to player
					EventInvoke(EVENT.ON_CAMERA_RESET_TO_PLAYER);
					
					// Delete room lists
					var roomAmount;
					if (ds_exists(roomsHorizontal, ds_type_list)) {
						roomAmount = ds_list_size(roomsHorizontal);
						for (var i = 0; i < roomAmount; i++) roomsHorizontal[| i].Cleanup();
						
						ds_list_destroy(roomsHorizontal);
					}
					if (ds_exists(roomsVertical, ds_type_list)) {
						roomAmount = ds_list_size(roomsVertical);
						for (var i = 0; i < roomAmount; i++) roomsVertical[| i].Cleanup();
						
						ds_list_destroy(roomsVertical);
					}
					if (ds_exists(roomsDrop, ds_type_list)) {
						roomAmount = ds_list_size(roomsDrop);
						for (var i = 0; i < roomAmount; i++) roomsDrop[| i].Cleanup();
						
						ds_list_destroy(roomsDrop);
					}
					if (ds_exists(roomsLand, ds_type_list)) {
						roomAmount = ds_list_size(roomsLand);
						for (var i = 0; i < roomAmount; i++) roomsLand[| i].Cleanup();
						
						ds_list_destroy(roomsLand);
					}
				}
				
				LoadingScreenUpdate("DONE", "", 1, false);
				
				// Advance to next stage
				mapGenStage = MAP_GEN_STAGE.DONE;
				#endregion
				break;
			case MAP_GEN_STAGE.DONE:
				#region Done
				if (keyboard_key != vk_nokey || mouse_button != mb_none) {
					// Advance to next stage
					mapGenStage = MAP_GEN_STAGE.TRANSITION;
				}
				#endregion
				break;
			case MAP_GEN_STAGE.TRANSITION:
				#region Transition
				transition.Step();
				
				if (transition.time == 1) {
					newScene.sceneLoaded = true;
					oMain.currentScene = newScene;
					instance_destroy();
				}
				#endregion
				break;
		}
		#endregion
		break;
}
