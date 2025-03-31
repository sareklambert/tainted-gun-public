/// @description Load scene draw event
switch (sceneToLoad) {
	case SCENE.DUNGEON:
		#region Generate dungeon
		switch (mapGenStage) {
			case MAP_GEN_STAGE.GENERATE_WALL_SHAPE_1:
				#region Generate wall shape 1
				if (mapGenProcessorIndex == -1) {
					// Log progress
					LoadingScreenUpdate("GENERATE_WALL_SHAPE_1", "Building walls", 0.40, false);
					LoadingScreenUpdate("> Draw tiles", "", 0.40, false);
					
					// Start processor
					mapGenProcessorIndex = 0;
				} else {
					var processorMax = newScene.mapWidthChunks * newScene.mapHeightChunks;
					var maxIteration = min(processorMax, mapGenProcessorIndex + newScene.mapGenProcessMaxChunks);
					
					var currentChunk, currentTile, xx, yy;
					var i, j;
					
					with (newScene) {
						draw_set_color(c_white);
						
						for (other.mapGenProcessorIndex = other.mapGenProcessorIndex; other.mapGenProcessorIndex < maxIteration; other.mapGenProcessorIndex++) {
							i = other.mapGenProcessorIndex div mapHeightChunks;
							j = other.mapGenProcessorIndex mod mapHeightChunks;
							
							currentChunk = chunkGrid[# i, j];
							
							// Draw tiles to chunks
							with (currentChunk) {
								surfData = SurfaceLoad(surfData, bufferData, oMain.chunkSizePixels, oMain.chunkSizePixels);
								surface_set_target(surfData);
								for (var k = 0; k < oMain.chunkSizeTiles; k++) {
									for (var l = 0; l < oMain.chunkSizeTiles; l++) {
										currentTile = tileGrid[# k, l];
										xx = k * oMain.tileSize;
										yy = l * oMain.tileSize;
										switch (currentTile) {
											case TILE.WALL:
												draw_rectangle(xx, yy, xx + oMain.tileSize - 1, yy + oMain.tileSize - 1, false);
												break;
											case TILE.SLOPE_TL:
												draw_triangle(xx - 1, yy - 1, xx - 1 + oMain.tileSize, yy - 1, xx - 1, yy - 1 + oMain.tileSize, false);
												break;
											case TILE.SLOPE_TR:
												draw_triangle(xx - 1, yy - 1, xx - 1 + oMain.tileSize, yy - 1, xx - 1 + oMain.tileSize, yy - 1 + oMain.tileSize, false);
												break;
											case TILE.SLOPE_BL:
												draw_triangle(xx - 1, yy - 1, xx - 1, yy + oMain.tileSize, xx - 1 + oMain.tileSize, yy + oMain.tileSize - 1, false);
												break;
											case TILE.SLOPE_BR:
												draw_triangle(xx - 1 + oMain.tileSize, yy, xx - 1, yy - 1 + oMain.tileSize, xx - 1 + oMain.tileSize, yy + oMain.tileSize - 1, false);
												break;
										}
									}
								}
								surface_reset_target();
							
								// Save chunk surfaces
								bufferData = SurfaceSave(surfData, bufferData, oMain.chunkSizePixels, oMain.chunkSizePixels);
							}
						}
					}
					
					// Log process
					LoadingScreenUpdate("> Drawing tiles at chunk (" + string(mapGenProcessorIndex) + " / " + string(processorMax) + ")", "", 0.40 + 0.10 * mapGenProcessorIndex / processorMax, compressLog);
					
					// Check if processor completed
					if (mapGenProcessorIndex == processorMax) {
						LoadingScreenUpdate("> Drawing tiles completed", "", 0.50, false);
						
						// Advance to next stage
						mapGenProcessorIndex = -1;
						mapGenStage = MAP_GEN_STAGE.GENERATE_WALL_SHAPE_2;
					}
				}
				#endregion
				break;
			case MAP_GEN_STAGE.GENERATE_WALL_SHAPE_2:
				#region Generate wall shape 2
				if (mapGenProcessorIndex == -1) {
					// Log progress
					LoadingScreenUpdate("GENERATE_WALL_SHAPE_2", "Making walls pretty", 0.50, false);
					LoadingScreenUpdate("> Draw polygons", "", 0.50, false);
					
					// Start processor
					mapGenProcessorIndex = 0;
				} else {
					with (newScene) {
						draw_set_color(c_white);
						
						var processorMax = (mapWidthTiles - 1) * (mapHeightTiles - 1);
						var maxIteration = min(processorMax, other.mapGenProcessorIndex + mapGenProcessMaxTiles);
						var i, j;
						
						var maxShift, s;
						var tileTL, tileTR, tileBL, tileBR, tileC;
						for (other.mapGenProcessorIndex = other.mapGenProcessorIndex; other.mapGenProcessorIndex < maxIteration; other.mapGenProcessorIndex++) {
							i = other.mapGenProcessorIndex div (mapHeightTiles - 1) + 1;
							j = other.mapGenProcessorIndex mod (mapHeightTiles - 1) + 1;
							
							// Draw polygons
							if (frac(i / 2) == 0 && frac(j / 2) == 0) {
								maxShift = 0;
								s = 0.6;
							} else {
								maxShift = 2;
								s = 0.6;
							}
							
							tileC = chunkGrid[# i div oMain.chunkSizeTiles, j div oMain.chunkSizeTiles].tileGrid[# i - (i div oMain.chunkSizeTiles * oMain.chunkSizeTiles), j - (j div oMain.chunkSizeTiles * oMain.chunkSizeTiles)];
							tileTL = chunkGrid[# (i - 1) div oMain.chunkSizeTiles, (j - 1) div oMain.chunkSizeTiles].tileGrid[# (i - 1) - ((i - 1) div oMain.chunkSizeTiles * oMain.chunkSizeTiles), (j - 1) - ((j - 1) div oMain.chunkSizeTiles * oMain.chunkSizeTiles)];
							tileBL = chunkGrid[# (i - 1) div oMain.chunkSizeTiles, j div oMain.chunkSizeTiles].tileGrid[# (i - 1) - ((i - 1) div oMain.chunkSizeTiles * oMain.chunkSizeTiles), j - (j div oMain.chunkSizeTiles * oMain.chunkSizeTiles)];
							tileTR = chunkGrid[# i div oMain.chunkSizeTiles, (j - 1) div oMain.chunkSizeTiles].tileGrid[# i - (i div oMain.chunkSizeTiles * oMain.chunkSizeTiles), (j - 1) - ((j - 1) div oMain.chunkSizeTiles * oMain.chunkSizeTiles)];
							
							// Scale down wall detail if there is a hazard
							if (tileC == TILE.MAPGEN_HAZARD || tileTL == TILE.MAPGEN_HAZARD || tileBL == TILE.MAPGEN_HAZARD || tileTR == TILE.MAPGEN_HAZARD) {
								s = 0.25;
								maxShift = 0.75;
							}
							
							tileTL = (tileTL == TILE.WALL);
							tileBL = (tileBL == TILE.WALL);
							tileTR = (tileTR == TILE.WALL);
							tileBR = (tileC == TILE.WALL);
							
							// Slopes
							if (tileC == TILE.SLOPE_TL || tileC == TILE.SLOPE_BR) {
								DrawToChunks(sPolygonSmall, irandom(sprite_get_number(sPolygonSmall)), (i + 0.5) * oMain.tileSize + random_range(-maxShift, maxShift), (j + 0.5) * oMain.tileSize + random_range(-maxShift, maxShift), s, s, irandom(3) * 90, c_white, true, CHUNK_SURF.DATA, false);
								DrawToChunks(sPolygonSmall, irandom(sprite_get_number(sPolygonSmall)), (i + 0.75) * oMain.tileSize + random_range(-maxShift, maxShift), (j + 0.25) * oMain.tileSize + random_range(-maxShift, maxShift), s, s, irandom(3) * 90, c_white, true, CHUNK_SURF.DATA, false);
								DrawToChunks(sPolygonSmall, irandom(sprite_get_number(sPolygonSmall)), (i + 0.25) * oMain.tileSize + random_range(-maxShift, maxShift), (j + 0.75) * oMain.tileSize + random_range(-maxShift, maxShift), s, s, irandom(3) * 90, c_white, true, CHUNK_SURF.DATA, false);
							} else if (tileC == TILE.SLOPE_TR || tileC == TILE.SLOPE_BL) {
								DrawToChunks(sPolygonSmall, irandom(sprite_get_number(sPolygonSmall)), (i + 0.25) * oMain.tileSize + random_range(-maxShift, maxShift), (j + 0.25) * oMain.tileSize + random_range(-maxShift, maxShift), s, s, irandom(3) * 90, c_white, true, CHUNK_SURF.DATA, false);
								DrawToChunks(sPolygonSmall, irandom(sprite_get_number(sPolygonSmall)), (i + 0.5) * oMain.tileSize + random_range(-maxShift, maxShift), (j + 0.5) * oMain.tileSize + random_range(-maxShift, maxShift), s, s, irandom(3) * 90, c_white, true, CHUNK_SURF.DATA, false);
								DrawToChunks(sPolygonSmall, irandom(sprite_get_number(sPolygonSmall)), (i + 0.75) * oMain.tileSize + random_range(-maxShift, maxShift), (j + 0.75) * oMain.tileSize + random_range(-maxShift, maxShift), s, s, irandom(3) * 90, c_white, true, CHUNK_SURF.DATA, false);
							}
							
							// Other
							if (random(1) < .8) if ((tileTL + tileTR + tileBL + tileBR) < 3 && (tileTL + tileTR + tileBL + tileBR) > 0) DrawToChunks(sPolygonSmall, irandom(sprite_get_number(sPolygonSmall)), i * oMain.tileSize + random_range(-maxShift, maxShift), j * oMain.tileSize + random_range(-maxShift, maxShift), s, s, irandom(3) * 90, c_white, true, CHUNK_SURF.DATA, false);
							if (random(1) < .8) if ((tileTR && !tileBR) || (!tileTR && tileBR)) DrawToChunks(sPolygonSmall, irandom(sprite_get_number(sPolygonSmall)), (i + 0.5) * oMain.tileSize, j * oMain.tileSize + random_range(-maxShift, maxShift), s, s, irandom(3) * 90, c_white, true, CHUNK_SURF.DATA, false);
							if (random(1) < .8) if ((tileBL && !tileBR) || (!tileBL && tileBR)) DrawToChunks(sPolygonSmall, irandom(sprite_get_number(sPolygonSmall)), i * oMain.tileSize + random_range(-maxShift, maxShift), (j + 0.5) * oMain.tileSize, s, s, irandom(3) * 90, c_white, true, CHUNK_SURF.DATA, false);
						}
						
						// Save surfaces
						var updateAmount = ds_list_size(updateList);
						for (var i = updateAmount - 1; i >= 0; i--) UpdateListUpdateDraw(i);
					}
					
					// Log process
					LoadingScreenUpdate("> Drawing polygon (" + string(mapGenProcessorIndex) + " / " + string(processorMax) + ")", "", 0.50 + 0.10 * mapGenProcessorIndex / processorMax, compressLog);
					
					// Check if processor completed
					if (mapGenProcessorIndex == processorMax) {
						LoadingScreenUpdate("> Drawing polygons completed", "", 0.60, false);
						
						// Advance to next stage
						mapGenProcessorIndex = -1;
						mapGenStage = MAP_GEN_STAGE.CALCULATE_WALL_DISTANCE;
					}
				}
				#endregion
				break;
			case MAP_GEN_STAGE.CALCULATE_WALL_DISTANCE:
				#region Calculate wall distance
				if (mapGenProcessorIndex == -1) {
					// Log progress
					LoadingScreenUpdate("CALCULATE_WALL_DISTANCE", "Measuring walls", 0.60, false);
					LoadingScreenUpdate("> Calculating distances", "", 0.60, false);
					
					// Start processor
					mapGenProcessorIndex = 0;
				} else {
					with (newScene) {
						var processorMax = mapWidthChunks * mapHeightChunks;
						var maxIteration = min(processorMax, other.mapGenProcessorIndex + mapGenProcessMaxChunks);
						var i, j;
						
						// Create necessary surfaces
						PrepareChunkPaddedSurf();
						var surfPing = surface_create(surface_get_width(surfSysChunkPadded), surface_get_height(surfSysChunkPadded), surface_rgba16float);
						var surfPong = surface_create(surface_get_width(surfSysChunkPadded), surface_get_height(surfSysChunkPadded), surface_rgba16float);
						
						var xx, yy, cx, cy;
						for (other.mapGenProcessorIndex = other.mapGenProcessorIndex; other.mapGenProcessorIndex < maxIteration; other.mapGenProcessorIndex++) {
							i = other.mapGenProcessorIndex div mapHeightChunks;
							j = other.mapGenProcessorIndex mod mapHeightChunks;
							
							surface_set_target(surfSysChunkPadded);
							draw_clear_alpha(c_black, 0);
							
							// Get neighbouring chunks
							for (var k = 0; k < 3; k++) {
								for (var l = 0; l < 3; l++) {
									cx = i - 1 + k;
									cy = j - 1 + l;
									xx = chunkPaddedSurfPadding + oMain.chunkSizePixels * (k - 1);
									yy = chunkPaddedSurfPadding + oMain.chunkSizePixels * (l - 1);
									if (cx < 0 || cy < 0 || cx >= mapWidthChunks || cy >= mapHeightChunks) {
										draw_rectangle(xx, yy, xx + oMain.chunkSizePixels, yy + oMain.chunkSizePixels, false);
									} else {
										with (chunkGrid[# cx, cy]) {
											surfData = SurfaceLoad(surfData, bufferData, oMain.chunkSizePixels, oMain.chunkSizePixels);
											draw_surface(surfData, xx, yy);
										}
									}
								}
							}
							surface_reset_target();
							
							// Get inverted padded chunk surface
							surface_set_target(surfPing);
							draw_clear_alpha(c_black, 0);
							shader_set(shdInvertAlpha);
							draw_surface(surfSysChunkPadded, 0, 0);
							shader_reset();
							surface_reset_target();
							
							#region Generate distance data by jumpflooding
							// Disable blending
							gpu_set_blendenable(false);
							
							// Get variables for the jumpflood algorythm
							var tex = surface_get_texture(surfPing);
							var texelW = texture_get_texel_width(tex);
							var texelH = texture_get_texel_height(tex);
							
							var isFirstPass = true;
							var jumpDist = 128;
							
							var surf1, surf2, surf3;
							surf1 = surfPing;
							surf2 = surfPong;
							
							// Run the jumpflood algorythm
							shader_set(shdJumpflood);
							shader_set_uniform_f(uniformJumpfloodTexelSize, texelW, texelH);
							
							// Repeat pass until jump is one
							while (jumpDist >= 1) {
								// Swap surfaces
								surf3 = surf1;
								surf1 = surf2;
								surf2 = surf3;
								
								// Apply JFA pass
								surface_set_target(surf1);
								shader_set_uniform_f(uniformJumpfloodFirstPass, isFirstPass);
								shader_set_uniform_f(uniformJumpfloodJumpDist, jumpDist);
								draw_surface(surf2, 0, 0);
								surface_reset_target();
								
								// All other passes are false
								isFirstPass = false;
								
								// Half jump size with each pass
								jumpDist /= 2;
							}
							
							shader_reset();
							
							// Enable blending again
							gpu_set_blendenable(true);
							#endregion
							
							with (chunkGrid[# i, j]) {
								// Encode distance info in the data surfaces green and blue channels
								var tex = surface_get_texture(surf1);
								
								surface_set_target(surfData);
								draw_clear_alpha(c_black, 0);
								shader_set(shdEncodeDistanceData);
								texture_set_stage(shader_get_sampler_index(shdEncodeDistanceData, "SDF"), tex);
								draw_surface(oSceneDungeon.surfSysChunkPadded, -oSceneDungeon.chunkPaddedSurfPadding, -oSceneDungeon.chunkPaddedSurfPadding);
								shader_reset();
								surface_reset_target();
								
								// Save chunk surfaces
								bufferData = SurfaceSave(surfData, bufferData, oMain.chunkSizePixels, oMain.chunkSizePixels);
							}
						}
						
						// Destroy temp surfaces
						surface_free(surfPing);
						surface_free(surfPong);
					}
					
					// Log process
					LoadingScreenUpdate("> Calculating distance for chunk (" + string(mapGenProcessorIndex) + " / " + string(processorMax) + ")", "", 0.60 + 0.10 * mapGenProcessorIndex / processorMax, compressLog);
					
					// Check if processor completed
					if (mapGenProcessorIndex == processorMax) {
						LoadingScreenUpdate("> Calculating distances completed", "", 0.70, false);
						
						// Advance to next stage
						mapGenProcessorIndex = -1;
						mapGenStage = MAP_GEN_STAGE.GENERATE_ORES;
					}
				}
				#endregion
				break;
			case MAP_GEN_STAGE.GENERATE_ORES:
				#region Generate ores
				if (mapGenProcessorIndex == -1) {
					// Log progress
					LoadingScreenUpdate("GENERATE_ORES", "Adding something shiny", 0.70, false);
					LoadingScreenUpdate("> Drawing ores", "", 0.70, false);
					
					// Start processor
					mapGenProcessorIndex = 0;
				} else {
					with (newScene) {
						var surfTemp = surface_create(oMain.chunkSizePixels, oMain.chunkSizePixels);
						
						var noiseData;
						noiseData[0] = [0, 0, 0.32, 0];
						noiseData[1] = [0, 0, 0.3, 0];
						noiseData[2] = [0, 0, 0.3, 0];
						noiseData[3] = [0, 0, 0.3, 0];
						noiseData[4] = [0, 0, 0.3, 0];
						noiseData[5] = [0, 0, 0.3, 0];
						
						var processorMax = mapWidthChunks * mapHeightChunks;
						var maxIteration = min(processorMax, other.mapGenProcessorIndex + mapGenProcessMaxChunks);
						var i, j;
						
						var currentChunk, currentTile, xx, yy;
						for (other.mapGenProcessorIndex = other.mapGenProcessorIndex; other.mapGenProcessorIndex < maxIteration; other.mapGenProcessorIndex++) {
							i = other.mapGenProcessorIndex div mapHeightChunks;
							j = other.mapGenProcessorIndex mod mapHeightChunks;
							
							with (chunkGrid[# i, j]) {
								// Generate shape
								surface_set_target(surfTemp);
								draw_clear_alpha(c_black, 0);
								
								shader_set(shdGenerateNoise);
								shader_set_uniform_f(uniformGenerateNoiseTime, oSceneDungeon.levelSeed);
								shader_set_uniform_f(uniformGenerateNoiseOffset, i * oMain.chunkSizePixels, j * oMain.chunkSizePixels);
								for (var k = 0; k < 4; k++) {
									if (noiseData[0][k] > 0) {
										shader_set_uniform_f(shader_get_uniform(shdGenerateNoise, "U" + string(k + 1)), true);
										shader_set_uniform_f(shader_get_uniform(shdGenerateNoise, "S" + string(k + 1)), noiseData[0][k]);
									} else {
										shader_set_uniform_f(shader_get_uniform(shdGenerateNoise, "U" + string(k + 1)), false);
									}
								}
								draw_rectangle(0, 0, oMain.chunkSizePixels, oMain.chunkSizePixels, false);
								shader_reset();
								
								surface_reset_target();
								
								// Write shape
								gpu_set_colorwriteenable(1, 0, 0, 0);
								surface_set_target(surfData);
								draw_surface_ext(surfTemp, 0, 0, 1, 1, 0, make_color_rgb(0, 255, 255), 1);
								//draw_surface_ext(surfTemp, 0, 0, 1, 1, 0, make_color_rgb(l, 255, 255), 1);
								surface_reset_target();
								gpu_set_colorwriteenable(1, 1, 1, 1);
								
								// Save chunk surfaces
								bufferData = SurfaceSave(surfData, bufferData, oMain.chunkSizePixels, oMain.chunkSizePixels);
							}
						}
						
						surface_free(surfTemp);
					}
					
					// Log process
					LoadingScreenUpdate("> Drawing ores to chunk (" + string(mapGenProcessorIndex) + " / " + string(processorMax) + ")", "", 0.70 + 0.10 * mapGenProcessorIndex / processorMax, compressLog);
					
					// Check if processor completed
					if (mapGenProcessorIndex == processorMax) {
						LoadingScreenUpdate("> Drawing ores completed", "", 0.80, false);
						
						// Advance to next stage
						mapGenProcessorIndex = -1;
						mapGenStage = MAP_GEN_STAGE.PREHEAT_CHUNKS;
					}
				}
				#endregion
				break;
			case MAP_GEN_STAGE.PREHEAT_CHUNKS:
				#region Preheat chunks
				if (mapGenProcessorIndex == -1) {
					// Log progress
					LoadingScreenUpdate("PREHEAT_CHUNKS", "It's getting hot!", 0.80, false);
					LoadingScreenUpdate("> Preheating chunks", "", 0.80, false);
					
					// Start processor
					mapGenProcessorIndex = 0;
				} else {
					with (newScene) {
						var processorMax = mapWidthChunks * mapHeightChunks;
						var maxIteration = min(processorMax, other.mapGenProcessorIndex + mapGenProcessMaxChunks);
						var i, j;
						
						for (other.mapGenProcessorIndex = other.mapGenProcessorIndex; other.mapGenProcessorIndex < maxIteration; other.mapGenProcessorIndex++) {
							i = other.mapGenProcessorIndex div mapHeightChunks;
							j = other.mapGenProcessorIndex mod mapHeightChunks;
							
							// Render, save, and free surfaces
							with (chunkGrid[# i, j]) {
								surface_free(surfData);
								
								RenderTextureAlbedo();
								bufferAlbedo = SurfaceSave(surfAlbedo, bufferAlbedo, oMain.chunkSizePixels, oMain.chunkSizePixels);
								surface_free(surfAlbedo);
								
								RenderTextureBack();
								bufferBack = SurfaceSave(surfBack, bufferBack, oMain.chunkSizePixels, oMain.chunkSizePixels);
								surface_free(surfBack);
								
								RenderTextureNormal();
								bufferNormal = SurfaceSave(surfNormal, bufferNormal, oMain.chunkSizePixels, oMain.chunkSizePixels);
								surface_free(surfNormal);
							}
						}
					}
					
					// Log process
					LoadingScreenUpdate("> Preheating chunk (" + string(mapGenProcessorIndex) + " / " + string(processorMax) + ")", "", 0.80 + 0.10 * mapGenProcessorIndex / processorMax, compressLog);
					
					// Check if processor completed
					if (mapGenProcessorIndex == processorMax) {
						LoadingScreenUpdate("> Preheating chunks completed", "", 0.90, false);
						
						// Advance to next stage
						mapGenProcessorIndex = -1;
						mapGenStage = MAP_GEN_STAGE.FINALIZE;
					}
				}
				#endregion
				break;
		}
		#endregion
		break;
}
