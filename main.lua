-- Required for bit operations in Lua 5.1
bit = require("bit");

-- CONTROL CONSTANTS
inputA = {A=true};
inputB = {B=true};
inputStart = {start=true};
inputSelect = {select=true};
inputUp = {up=true};
inputDown = {down=true};
inputLeft = {left=true};
inputRight = {right=true};

inputLeftB = {left=true,B=true};
inputLeftBA = {left=true,B=true,A=true};
inputLeftA = {left=true,A=true};
inputRightB = {right=true,B=true};
inputRightBA = {right=true,B=true,A=true};
inputRightA = {right=true,A=true};
inputLeftRightB = {left=true,right=true,B=true};
inputLeftRightBA = {left=true,right=true,B=true,A=true};
inputLeftRightA = {left=true,right=true,A=true};

-- SETTING CONSTANTS
ENABLE_TURBO = true;
SHOW_DISPLAY = true;
DISABLE_FAILSAFE = false;
DISABLE_DELAYS = false;
PROGRESS_CHECK_FREQUENCY = 0;
STARTING_FRAMERULE = 548;
SET_STARTING_CONFIGURATION = false;
STARTING_DELAYS = {0, 0, 0, 0, 0};
STARTING_SUBRANGE = -5;
STARTING_LAKITU_STATE = 1;
STARTING_KOOPA_PAIR_STATE = {"X", "X"};
CLOSE_CALL_LENIENCY = 1;
CLOSE_CALL_ALLOW_OPPOSITE_SIDES = true;
DOUBLE_FRAME_BUZZY_STOMP = false;
-- 0 -> single accel, 1 -> TAS accel, 2 -> L+R TAS accel
ACCEL_MODE = 0;

-- FILE-RELEVANT GLOBAL VARIABLES
logFile = "log_v2.txt";

-- Create the necessary result directories, if they don't already exist
os.execute("mkdir \"despawns\"");
os.execute("mkdir \"close calls\"");

-- GAMEPLAY-RELEVANT GLOBAL VARIABLES
first_framerule = true;
current_framerule = STARTING_FRAMERULE;
iteration = 1;
timer = 0;
iteration_data = {
	delay_list = nil,
	despawn_type = nil,
	subpixel_range = nil,
	lakitu_state = nil,
	koopa_pair_state = nil,
	phase_1_stomps = nil,
	phase_2_stomps = nil,
	phase_3_stomps = nil,
	phase_4_stomps = nil,
	phase_5_stomps = nil,
	phase_6_stomps = nil
};

-- Each value corresponds to a frame where doing running fast accel or a length of frames of D+R that puts Mario in a unique 8-subpixel range
-- There are 5 ranges accessible with a running fast accel that exceed normal R+B movement, and 5 ranges accessible via slowdowns that are still fast enough for TAS 8-2
-- The array is ordered from slowest to fastest corresponding values
-- In addition, we define a few extra ranges which are used specifically for the TAS accels
subpixel_range_indices = {-5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5};
subpixel_range_indices_tas_accel = {0, 1, 2, 3};
subpixel_range_indices_lr_tas_accel = {0, 1, 2};
ongoing_offset_frame = false;

-- Each slot in the larger array denotes a subpixel range
-- Each slot in the smaller arrays list off each possible bop combo of the koopa pair with that subpixel range (and cointoss)
-- The 2-value arrays represent the timer frames at which the koopas should be stomped for that combo ("X" means that koopa is not stomped in that combo)
koopa_pair_frames = {};

koopa_pair_frames_range = {{"X", "X"}, {2, "X"}, {2, 22}, {4, 22}, {6, 22}, {6, 24}, {8, 24}, {8, 26}, {"X", 22}, {"X", 24}, {"X", 26}, {"X", 28}};
koopa_pair_frames[11] = koopa_pair_frames_range;

koopa_pair_frames_range = {{"X", "X"}, {2, "X"}, {4, 22}, {6, 22}, {6, 24}, {8, 24}, {8, 26}, {"X", 22}, {"X", 24}, {"X", 26}, {"X", 28}};
koopa_pair_frames[10] = koopa_pair_frames_range;

koopa_pair_frames_range = {{"X", "X"}, {2, "X"}, {4, 22}, {6, 22}, {6, 24}, {8, 24}, {8, 26}, {"X", 22}, {"X", 24}, {"X", 26}, {"X", 28}};
koopa_pair_frames[9] = koopa_pair_frames_range;

koopa_pair_frames_range = {{"X", "X"}, {2, "X"}, {2, 22}, {4, 22}, {6, 22}, {6, 24}, {8, 24}, {8, 26}, {"X", 22}, {"X", 24}, {"X", 26}, {"X", 28}};
koopa_pair_frames[8] = koopa_pair_frames_range;

koopa_pair_frames_range = {{"X", "X"}, {3, 21}, {5, 21}, {5, 23}, {7, 23}, {7, 25}, {"X", 21}, {"X", 23}, {"X", 25}, {"X", 27}};
koopa_pair_frames[7] = koopa_pair_frames_range;

koopa_pair_frames_range = {{"X", "X"}, {3, 21}, {5, 21}, {5, 23}, {7, 23}, {7, 25}, {9, 25}, {9, 27}, {"X", 21}, {"X", 23}, {"X", 25}, {"X", 27}};
koopa_pair_frames[6] = koopa_pair_frames_range;

koopa_pair_frames_range = {{"X", "X"}, {3, 21}, {5, 21}, {5, 23}, {7, 23}, {7, 25}, {9, 25}, {9, 27}, {"X", 21}, {"X", 23}, {"X", 25}, {"X", 27}};
koopa_pair_frames[5] = koopa_pair_frames_range;

koopa_pair_frames_range = {{"X", "X"}, {3, 21}, {5, 21}, {5, 23}, {7, 23}, {7, 25}, {9, 25}, {9, 27}, {"X", 21}, {"X", 23}, {"X", 25}, {"X", 27}};
koopa_pair_frames[4] = koopa_pair_frames_range;

koopa_pair_frames_range = {{"X", "X"}, {3, 21}, {5, 21}, {5, 23}, {7, 23}, {7, 25}, {9, 25}, {9, 27}, {"X", 21}, {"X", 23}, {"X", 25}, {"X", 27}};
koopa_pair_frames[3] = koopa_pair_frames_range;

koopa_pair_frames_range = {{"X", "X"}, {2, 22}, {4, 22}, {6, 22}, {6, 24}, {8, 24}, {8, 26}, {"X", 22}, {"X", 24}, {"X", 26}, {"X", 28}};
koopa_pair_frames[2] = koopa_pair_frames_range;

koopa_pair_frames_range = {{"X", "X"}, {2, 22}, {4, 22}, {6, 22}, {6, 24}, {8, 24}, {8, 26}, {"X", 22}, {"X", 24}, {"X", 26}, {"X", 28}};
koopa_pair_frames[1] = koopa_pair_frames_range;

-- Index 1 denotes the x-position for the delay location, index 2 denotes the maximum capacity for subpixel range loss
delay_location_list = {{1364, 1}, {1488, 1}, {1680, 1}, {1834, 1}, {1997, 1}};
ongoing_delay_frame = false;

-- Used to ensure each delay only occurs for 1 frame
active_delays = {};
for i = 1,#delay_location_list,1 do
	active_delays[i] = 1;
end

-- Each of the 7 lists are used to store lists of states, one for each phase as well as the final loop
state_list = {{}, {}, {}, {}, {}, {}, {}};

-- GET FUNCTIONS
function getMarioXSpeed()
	return memory.readbyte(0x0057);
end
function getMarioXSubpixel()
	return memory.readbyte(0x0400);
end
function getMarioXPosition()
	return (memory.readbyte(0x006D) * 256) + memory.readbyte(0x0086);
end
function getEnemyXSpeed(slot)
	return memory.readbyte(0x0057 + slot);
end
function getEnemyXPosition(slot)
	return (memory.readbyte(0x006D + slot) * 256) + memory.readbyte(0x0086 + slot);
end
function getFirstThreeEnemyXPositions()
	return {getEnemyXPosition(1), getEnemyXPosition(2), getEnemyXPosition(3)};
end
function getAllEnemyXPositions()
	return {getEnemyXPosition(1), getEnemyXPosition(2), getEnemyXPosition(3), getEnemyXPosition(4), getEnemyXPosition(5)};
end
function getEnemyYPosition(slot)
	return memory.readbyte(0x00CE + slot);
end
-- Get functions for miscellaneous, manipulatable values which help capture the current "state", which is used for differentiating despawns
-- If two despawns produce the same values here, it is safe to assume that the enemy behaviour afterwards (including the final bullet shot) will be identical
-- The get functions for the precise speeds are handled as strings instead of numbers due to the more complex nature of speed values with respect to position
function getEnemyXPositionPrecise(slot)
	return (memory.readbyte(0x006D + slot) * 65536) + (memory.readbyte(0x0086 + slot) * 256) + memory.readbyte(0x0400 + slot);
end
function getAllEnemyXPositionsPrecise()
	return {getEnemyXPositionPrecise(1), getEnemyXPositionPrecise(2), getEnemyXPositionPrecise(3), getEnemyXPositionPrecise(4), getEnemyXPositionPrecise(5)};
end
function getEnemyYPositionPrecise(slot)
	return (memory.readbyte(0x00CE + slot) * 256) + memory.readbyte(0x0416 + slot);
end
function getAllEnemyYPositionsPrecise()
	return {getEnemyYPositionPrecise(1), getEnemyYPositionPrecise(2), getEnemyYPositionPrecise(3), getEnemyYPositionPrecise(4), getEnemyYPositionPrecise(5)};
end
function getEnemyXSpeedPrecise(slot)
	speed = memory.readbyte(0x0057 + slot);
	if speed >= 128 then
		speed = -(256 - speed);
	end
	return tostring(speed) .. ":" .. tostring(memory.readbyte(0x0705 + slot));
end
function getAllEnemyXSpeedsPrecise()
	return getEnemyXSpeedPrecise(1) .. ", " .. getEnemyXSpeedPrecise(2) .. ", " .. getEnemyXSpeedPrecise(3) .. ", " .. getEnemyXSpeedPrecise(4) .. ", " .. getEnemyXSpeedPrecise(5);
end
function getEnemyYSpeedPrecise(slot)
	speed = memory.readbyte(0x009F + slot);
	if speed >= 128 then
		speed = -(256 - speed);
	end
	return tostring(speed) .. ":" .. tostring(memory.readbyte(0x0433 + slot));
end
function getAllEnemyYSpeedsPrecise()
	return getEnemyYSpeedPrecise(1) .. ", " .. getEnemyYSpeedPrecise(2) .. ", " .. getEnemyYSpeedPrecise(3) .. ", " .. getEnemyYSpeedPrecise(4) .. ", " .. getEnemyYSpeedPrecise(5);
end
-- Gets the values of all bullet bill timers
function getBulletBillTimers()
	return {memory.readbyte(0x047D), memory.readbyte(0x047E), memory.readbyte(0x047F), memory.readbyte(0x0480), memory.readbyte(0x0481), memory.readbyte(0x0482)};
end
-- Gets enemy slot data
function getEnemySlots()
	return {memory.readbyte(0x000F), memory.readbyte(0x0010), memory.readbyte(0x0011), memory.readbyte(0x0012), memory.readbyte(0x0013)};
end
-- Get global frame timer
function getFrameTimer()
	return memory.readbyte(0x0009);
end
-- Gets the first 32-bits of RNG, which are the only relevant bits in this case and necessary to stay within the 32-bit range for bit operations
function getTrimmedRNG()
	rng = 0;
	for i = 0,3,1 do
		rng = rng + memory.readbyte(0x07A7 + i) * (256 ^ (3 - i));
	end
	return rng;
end

-- Extract the 3 3-bit values from the given (trimmed) RNG value that are used when handling bullet bill shots
-- If the corresponding enemy slot is empty, that values bullet bill timer (provided it exists and is loaded) is ticked down
function getBulletRNGValues(rng)
	slot = {};
	slot[1] = bit.rshift(bit.band(rng, bit.lshift(0x7, 16)), 16);
	slot[2] = bit.rshift(bit.band(rng, bit.lshift(0x7, 8)), 8);
	slot[3] = bit.band(rng, 0x7);
	return slot;
end

-- HELPER FUNCTIONS
-- Perform the first few inputs to advance to the practice ROM title screen, input the framerule numbers, and begin 8-2 on the set framerule
function advanceToLevel()
	-- Advance to SMB1 (practice ROM) title screen
	while emu.framecount() <= 57 do
		if emu.framecount() == 10 then
			joypad.set(1, inputStart);
		elseif emu.framecount() == 45 then
			joypad.set(1, inputLeft);
		elseif emu.framecount() == 47 or emu.framecount() == 51 or emu.framecount() == 53 or emu.framecount() == 57 then
			joypad.set(1, inputSelect);
		elseif emu.framecount() == 49 or emu.framecount() == 55 then
			joypad.set(1, inputRight);
		end
		
		emu.frameadvance();
	end
	
	-- Find framerule digits
	digit1 = math.floor(current_framerule / 1000);
	digit2 = math.floor(current_framerule / 100) % 10;
	digit3 = math.floor(current_framerule / 10) % 10;
	digit4 = current_framerule % 10;
	
	-- Title screen
	while emu.getscreenpixel(48, 194, true) ~= 252 do
		-- Setting up correct framerule to test
		if emu.framecount() == 78 - (digit4 * 2) and emu.framecount() <= 76 then
			joypad.set(1, inputUp);
			digit4 = digit4 - 1;
		elseif emu.framecount() == 100 - (digit3 * 2) and emu.framecount() <= 98 then
			joypad.set(1, inputUp);
			digit3 = digit3 - 1;
		elseif emu.framecount() == 122 - (digit2 * 2) and emu.framecount() <= 120 then
			joypad.set(1, inputUp);
			digit2 = digit2 - 1;
		elseif emu.framecount() == 144 - (digit1 * 2) and emu.framecount() <= 142 then
			joypad.set(1, inputUp);
			digit1 = digit1 - 1;
		end
		
		-- Shifting to next slot
		if emu.framecount() == 80 or emu.framecount() == 102 or emu.framecount() == 124 then
			joypad.set(1, inputLeft);
		end
		
		-- Start on the title screen
		if emu.framecount() == 146 then
			joypad.set(1, inputStart);
		end
		
		emu.frameadvance();
	end
end

-- Obtains data relevant for describing the current phase and then compares it with existing states in the state list
-- If the state has already been visited, no need to check it
function checkState(state_index)
	state = {
		slots = table.concat(getEnemySlots(), ", "),
		timers = table.concat(getBulletBillTimers(), ", "),
		x_pos = table.concat(getAllEnemyXPositionsPrecise(), ", "),
		x_spd = getAllEnemyXSpeedsPrecise(),
		y_pos = table.concat(getAllEnemyYPositionsPrecise(), ", "),
		y_spd = getAllEnemyYSpeedsPrecise(),
		outcome = "none"
	};
	
	key = "[" .. tostring(iteration_data["lakitu_state"]) .. "] [" .. table.concat(iteration_data["koopa_pair_state"], ", ") .. "]";
	
	if state_index >= 2 then
		key = key .. " [" .. table.concat(iteration_data["phase_1_stomps"], ", ") .. "]";
	end
	if state_index >= 3 then
		key = key .. " [" .. table.concat(iteration_data["phase_2_stomps"], ", ") .. "]";
	end
	if state_index >= 4 then
		key = key .. " [" .. table.concat(iteration_data["phase_3_stomps"], ", ") .. "]";
	end
	if state_index >= 5 then
		key = key .. " [" .. table.concat(iteration_data["phase_4_stomps"], ", ") .. "]";
	end
	if state_index >= 6 then
		key = key .. " [" .. table.concat(iteration_data["phase_5_stomps"], ", ") .. "]";
	end
	if state_index >= 7 then
		key = key .. " [" .. table.concat(iteration_data["phase_6_stomps"], ", ") .. "]";
	end
	
	-- Now that we have fully captured the state, we check if this state has already been visited by checking all elements in the state_list at state_index
	for k, v in pairs(state_list[state_index]) do
		if state["slots"] == v["slots"] and state["timers"] == v["timers"] and state["x_pos"] == v["x_pos"] and state["x_spd"] == v["x_spd"] and state["y_pos"] == v["y_pos"] and state["y_spd"] == v["y_spd"] then
			-- We have a match, so searching from here is redundant
			-- Thus, we record this as an alternative if it is identical to a success, and move on
			if v["outcome"] == "success" then
				print("State found identical to a success at index ", state_index);
				
				-- Go to each success file, recording the new stomp arrangement (key) as an alternative if it uses the original stomp arrangement
				for i, d in ipairs({"despawns", "close calls"}) do
					pipe = io.popen("cmd /c dir /b \"" .. d .. "\\*.txt\" 2>nul");
					for file_name in pipe:lines() do
						if string.sub(file_name, 1, #k) == k then
							file = io.open(d .. "/" .. file_name, "a");
							file:write("              ", key, "\n");
							file:close();
						end
					end
				end
			else
				print("State found identical to a failure at index ", state_index);
			end
			
			return true;
		end
	end
	
	-- If we get here, the state is brand new, so we add it to the state list
	state_list[state_index][key] = state;
	
	return false;
end

-- Delay loop function, iterates through all possible arrangements of delays across all delay locations
-- Recursive implementation allows for the amount of nested for loops to be equal to the number of elements in the delay location loop
-- Starting index = 0 -> set starting index for first framerule usage, starting index > 0 -> do normal brute-forcing behaviour
function delayLoop(loop_depth, indices, trackers, delay_capacities, delay_total, run_type)
	if loop_depth == 0 then
		-- Increment loop count
		trackers["count"] = trackers["count"] + 1;
		
		if run_type == "start" then
			-- Once we find the delay arrangement that matches the starting one, we save the loop count so we can jump straight to it in the main execution
			if arraysEqual(indices, STARTING_DELAYS) then
				trackers["start_index"] = trackers["count"];
			end
		elseif run_type == "main" then
			-- Iterate through the delay arrangements until we match the starting index (which is either 1 or changed to match the set starting delays)
			if trackers["count"] >= trackers["start_index"] then
				-- Construct the string of the delay arrangement for the log
				logMessage = "{" .. tostring(indices[1]);
				for i = 2,#indices,1 do
					logMessage = logMessage .. ", " .. tostring(indices[i]);
				end
				logMessage = logMessage .. "}";
				
				writeToLog(logMessage);
				
				iteration_data["delay_list"] = arrayCopy(indices);
				lakituStateSet();
				
				-- Now that the subpixel range and set of delays have been processed, combine all result files
				mergeOutput();
				
				-- Reset the state list, as Mario will now have a different positioning
				state_list = {{}, {}, {}, {}, {}, {}, {}};
			end
		end
	else
		-- Recursive call with loop
		indices_sum = arraySum(indices);
		for x = 0, minimumValue({delay_capacities[#indices + 1], delay_total - indices_sum}), 1 do
			-- Indices are kept track of in an array
			table.insert(indices, x);
			delayLoop(loop_depth - 1, indices, trackers, delay_capacities, delay_total, run_type);
		end
	end
	
	-- Update indices
	table.remove(indices);
end

-- Once a phase has done its first run-through and gathered all stomp data, this function iterates through all the possible stomp frames
function iteratePhase(stomps, name, state, end_distance, next_phase_function, avoid_bullets)
	for i1, t1 in ipairs(stomps[1]) do
		for i2, t2 in ipairs(stomps[2]) do
			for i3, t3 in ipairs(stomps[3]) do
				for i4, t4 in ipairs(stomps[4]) do
					for i5, t5 in ipairs(stomps[5]) do
						-- We already checked the "nothing" combo so we skip it
						if t1 ~= "X" or t2 ~= "X" or t3 ~= "X" or t4 ~= "X" or t5 ~= "X" then
							while getMarioXPosition() < end_distance do
								joypad.set(1, inputRightB);
						
								-- Set Mario's height to the enemy when the timer matches
								if timer == t1 then
									if getEnemyYPosition(1) <= 160 or not avoid_bullets then
										memory.writebyte(0x00CE, getEnemyYPosition(1) - 16);
									else
										memory.writebyte(0x00CE, 160);
									end
								elseif timer == t2 then
									if getEnemyYPosition(2) <= 160 or not avoid_bullets then
										memory.writebyte(0x00CE, getEnemyYPosition(2) - 16);
									else
										memory.writebyte(0x00CE, 160);
									end
								elseif timer == t3 then
									if getEnemyYPosition(3) <= 160 or not avoid_bullets then
										memory.writebyte(0x00CE, getEnemyYPosition(3) - 16);
									else
										memory.writebyte(0x00CE, 160);
									end
								elseif timer == t4 then
									if getEnemyYPosition(4) <= 160 or not avoid_bullets then
										memory.writebyte(0x00CE, getEnemyYPosition(4) - 16);
									else
										memory.writebyte(0x00CE, 160);
									end
								elseif timer == t5 then
									if getEnemyYPosition(5) <= 160 or not avoid_bullets then
										memory.writebyte(0x00CE, getEnemyYPosition(5) - 16);
									else
										memory.writebyte(0x00CE, 160);
									end
								else
									-- Otherwise, hover Mario away from enemies
									memory.writebyte(0x00CE, 45);
								end
								
								-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
								memory.writebyte(0x009F, 1);
								memory.writebyte(0x0433, 0);
							
								-- Display data and advance frame/timer
								displayAndAdvance();
							end
							
							if i1 == 1 then
								slot1 = "X";
							else
								slot1 = i1 - 1;
							end
							if i2 == 1 then
								slot2 = "X";
							else
								slot2 = i2 - 1;
							end
							if i3 == 1 then
								slot3 = "X";
							else
								slot3 = i3 - 1;
							end
							if i4 == 1 then
								slot4 = "X";
							else
								slot4 = i4 - 1;
							end
							if i5 == 1 then
								slot5 = "X";
							else
								slot5 = i5 - 1;
							end
							
							iteration_data[name] = {slot1, slot2, slot3, slot4, slot5};
							next_phase_function();
							
							-- Load back to phase2State
							savestate.load(state);
						end
					end
				end
			end
		end
	end
end

-- Given RNG values (relevant to bullets), bullet timers, enemy slots (on the current and previous frames), and enemy positions, determines the final outcome of the state
-- Assumes only enemy slots 4 and 5 can house the koopa and piranha plant (as required for despawn to occur)
-- Also returns all data relevant for reporting the outcome
function verifyState(val, timer, slot, prev_slot, enemy_pos)
	found = true;
	close_call = true;

	slot_state = {"empty", "empty", "empty"};
	bullet_slot = {};
	bullet_timer = {};
	important_bullet_timers = {};
	
	-- Slots 4 and 5 being occupied by the koopa and piranha plant (the only available non-bullet enemies) is a necessity for despawn
	if slot[4] == 1 and slot[5] == 1 and enemy_pos[4] ~= 2504 and enemy_pos[5] ~= 2504 then
		available_bullets = {1, 2, 3, 4, 5, 6};
		for j = 1,3,1 do
			key_bullet = val[j] + 1;
			bullet_slot[j] = key_bullet - 1;
			if key_bullet <= 6 then
				bullet_timer[j] = timer[key_bullet];
			else
				bullet_timer[j] = -1;
			end
			-- If the enemy slot is occupied by a bullet bill, nothing went wrong here and we proceed
			-- Otherwise, we go into the if block to find out what went wrong
			if slot[j] == 0 then
				-- If we get here even once, then not all slots were occupied and the despawn attempt failed
				found = false;
				-- If the rng value doesn't correspond to a bullet timer, a bullet can't be summoned to this slot on this frame and so despawn can't happen
				if key_bullet > 6 then
					close_call = false;
				else
					table.insert(important_bullet_timers, timer[key_bullet]);
				end
				-- If a previous empty slot had its rng value correspond to the same bullet timer, only one of them can have a bullet bill at once
				-- As such, it will be impossible to fill all slots for despawn to occur
				if removeValue(available_bullets, key_bullet) == false then
					close_call = false;
				end
			else
				-- Check if the filled slot belongs to a normal or phantom bullet bill, based on whether it was present last frame
				if prev_slot[j] == 1 then
					slot_state[j] = "normal";
				else
					slot_state[j] = "phantom";
					-- If a previous empty slot had its rng value correspond to the same bullet timer, only one of them can have a bullet bill at once
					-- As such, it will be impossible to fill all slots for despawn to occur
					if removeValue(available_bullets, key_bullet) == false then
						close_call = false;
					end
				end
			end
		end
		
		-- Ensure the important bullet timers fall within the constraints specified in the constants
		close_call_side = 0;
		for j, v in ipairs(important_bullet_timers) do
			if v <= 13 and v >= 14 - CLOSE_CALL_LENIENCY then
				if close_call_side == 0 then
					close_call_side = 1;
				end
				if not CLOSE_CALL_ALLOW_OPPOSITE_SIDES and close_call_side == -1 then
					close_call = false;
				end
			elseif v >= 0 and v <= CLOSE_CALL_LENIENCY - 1 then
				if close_call_side == 0 then
					close_call_side = -1;
				end
				if not CLOSE_CALL_ALLOW_OPPOSITE_SIDES and close_call_side == 1 then
					close_call = false;
				end
			elseif v ~= 14 then
				close_call = false;
			end
		end
	else
		found = false;
		close_call = false;
	end
	
	return found, close_call, {slot_state = slot_state, bullet_slot = bullet_slot, bullet_timer = bullet_timer};
end

-- (Trimmed) RNG simulator function, for preliminary checks
function iterateTrimmedRNG(rng)
	a = bit.rshift(bit.band(rng, bit.lshift(1, 25)), 25);
	b = bit.rshift(bit.band(rng, bit.lshift(1, 17)), 17);
	n = bit.bxor(a, b);
	rng = bit.rshift(rng, 1) + bit.lshift(n, 31);
	return rng;
end

-- Display data and advance frame/timer
function displayAndAdvance()
	-- Failsafe: If Mario ever goes down to walking speed after the initial stretch, something has gone wrong and we need to stop
	if not DISABLE_FAILSAFE and getMarioXSpeed() <= 24 and not ongoing_delay_frame and not ongoing_offset_frame then
		-- Record details in log and exit
		writeToLog("Something has gone wrong!\nFramerule: " .. tostring(current_framerule) .. "\nIteration: " .. tostring(iteration));
		os.exit();
	end
	
	-- If we're in a delay frame, we exit out now on the next frame
	if ongoing_delay_frame then
		memory.writebyte(0x0700, 40);
		memory.writebyte(0x0057, 40);
		ongoing_delay_frame = false;
	end
	
	-- If Mario has just crossed over a delay location point, we initiate the delay based on the value stored in the iteration data
	for i, v in ipairs(delay_location_list) do
		if getMarioXPosition() >= v[1] and (getMarioXPosition() < v[1] + 2 or (getMarioXPosition() == v[1] + 2 and memory.readbyte(0x0400) < 128)) and active_delays[i] == 1 then
			memory.writebyte(0x0057, 40 - (iteration_data["delay_list"][i] * 8));
			active_delays[i] = 0;
			ongoing_delay_frame = true;
		end
	end
	
	-- Display important values on screen
	if SHOW_DISPLAY then
		gui.text(0,35,"Iteration:");
		gui.text(45,35,iteration);
		gui.text(0,45,"Current Framerule:");
		gui.text(91,45,current_framerule);
		gui.text(0,55,"Timer:");
		gui.text(30,55,timer);
	end
	
	-- Advance frame and timer
	timer = timer + 1;
	emu.frameadvance();
end

-- General use write-to-log function, writing the text string to the log and printing for convenient viewing
function writeToLog(text)
	file = io.open(logFile, "a");
	file:write(text, "\n");
	file:close();
	
	print(text);
end

-- Runs at the end of every iteration, updating the relevant variables and occasionally giving progress checks
function endIteration()
	-- Advance iteration
	iteration = iteration + 1;
	-- Reset the active delay list so we can keep track of which delays have been done 
	for i = 1,#active_delays,1 do
		active_delays[i] = 1;
	end
	-- Progress check after every X iterations
	if PROGRESS_CHECK_FREQUENCY > 0 and iteration % PROGRESS_CHECK_FREQUENCY == 0 then
		writeToLog("Reached iteration" .. tostring(iteration));
	end
	-- Reset timer since we are going back to the loop of a prior function
	timer = 0;
end

-- Runs at the end of every framerule, resetting all relevant variables and writing to the log
function endFramerule()
	-- Report progress
	writeToLog("Framerule done, advancing to " .. tostring(current_framerule + 1));
	
	-- Reset variables for new framerule
	if first_framerule then
		first_framerule = false;
	end
	for i = 1,#delay_location_list,1 do
		active_delays[i] = 1;
	end
	iteration = 1;
	current_framerule = current_framerule + 1;
	timer = 0;
	subpixel_range_indices = {-5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5};
	subpixel_range_indices_tas_accel = {0, 1, 2, 3};
	subpixel_range_indices_lr_tas_accel = {0, 1, 2};
	state_list = {{}, {}, {}, {}, {}, {}, {}};
	
	-- Reset to title
	emu.poweron();
end

-- Generate output for the results file, given the found and close_call statuses as well as all relevant data
function generateOutput(found, close_call, close_call_data, delay)
	if found or close_call then
		print("A success has been found - a file will now be created");
		if found then
			directory = "despawns";
		elseif close_call then
			directory = "close calls";
		end
		stomp_layout = "[" .. tostring(iteration_data["lakitu_state"]) .. "] [" .. table.concat(iteration_data["koopa_pair_state"], ", ") .. "]";
		state_list[1][stomp_layout]["outcome"] = "success";
		stomp_layout = stomp_layout .. " [" .. table.concat(iteration_data["phase_1_stomps"], ", ") .. "]";
		state_list[2][stomp_layout]["outcome"] = "success";
		stomp_layout = stomp_layout .. " [" .. table.concat(iteration_data["phase_2_stomps"], ", ") .. "]";
		state_list[3][stomp_layout]["outcome"] = "success";
		stomp_layout = stomp_layout .. " [" .. table.concat(iteration_data["phase_3_stomps"], ", ") .. "]";
		state_list[4][stomp_layout]["outcome"] = "success";
		stomp_layout = stomp_layout .. " [" .. table.concat(iteration_data["phase_4_stomps"], ", ") .. "]";
		state_list[5][stomp_layout]["outcome"] = "success";
		stomp_layout = stomp_layout .. " [" .. table.concat(iteration_data["phase_5_stomps"], ", ") .. "]";
		state_list[6][stomp_layout]["outcome"] = "success";
		stomp_layout = stomp_layout .. " [" .. table.concat(iteration_data["phase_6_stomps"], ", ") .. "]";
		state_list[7][stomp_layout]["outcome"] = "success";
		
		file = io.open(directory .. "/" .. stomp_layout .. ".txt", "a");
		file:write("------------------------------\n");
		if found then
			file:write("PLANT DESPAWN: FRAMERULE ", current_framerule, "\n");
			file:write("BULLET TIMERS: ", table.concat(getBulletBillTimers(), ", "), "\n");
			file:write("ENEMY X POSITIONS: ", table.concat(getAllEnemyXPositionsPrecise(), ", "), "\n");
			file:write("ENEMY X SPEEDS: ", getAllEnemyXSpeedsPrecise(), "\n");
			file:write("ENEMY Y POSITIONS: ", table.concat(getAllEnemyYPositionsPrecise(), ", "), "\n");
			file:write("ENEMY Y SPEEDS: ", getAllEnemyYSpeedsPrecise(), "\n");
		elseif close_call then
			file:write("CLOSE CALL: FRAMERULE ", current_framerule, "\n");
			file:write("SLOT STATES: [", table.concat(close_call_data["slot_state"], ", "), "]\n");
			file:write("BULLET TIMERS: ", table.concat(close_call_data["bullet_timer"], ", "), "\n");
			file:write("BULLET SLOTS: [", table.concat(close_call_data["bullet_slot"], ", "), "]\n");
		end
		file:write("TYPE: ", iteration_data["despawn_type"], "\n");
		file:write("ITERATION: ", iteration, "\n");
		file:write("------------------------------\n");
		file:write("Initial Subpixel Range: ", iteration_data["subpixel_range"], "\n");
		file:write("Delay Layout: ", table.concat(iteration_data["delay_list"], ", "), "\n");
		if delay then
			file:write("With Delay\n");
		end
		file:write("Stomp Layout: ", stomp_layout, "\n");
		file:write("------------------------------\n");
		file:write("Alternatives:\n");
		file:close();
	end
end

-- Merges all results files in the given directory to a single combined result file for the current framerule, subrange offset and delay arrangement
function mergeOutput()
	-- Performed for each result directory (despawn and close call)
	for i, d in ipairs({"despawns", "close calls"}) do
		files = {};
	
		-- Extract all text file names in the result directory
		pipe = io.popen("cmd /c dir /b \"" .. d .. "\\*.txt\" 2>nul");
		for file_name in pipe:lines() do
			table.insert(files, file_name);
		end
		
		-- Only make the combo file if there are actually files to merge
		if #files > 0 then
			-- For each file name, write its corresponding file contents to the new framerule + range + delay file and delete it
			out = io.open(d .. "/" .. tostring(current_framerule) .. "/" .. tostring(iteration_data["subpixel_range"]) .. " {" .. table.concat(iteration_data["delay_list"], ", ") .. "}.txt", "wb");
			
			for i, n in ipairs(files) do
				file = io.open(d .. "/" .. n, "rb");
				out:write(file:read("*a"), "\n------------------------------\n\n");
				file:close();
				os.remove(d .. "\\" .. n);
			end
			out:close();
		end
	end
end

-- (General Use) Check if two arrays are equal by value, requiring that the two arrays not contain any nested arrays
function arraysEqual(array1, array2)
	if #array1 ~= #array2 then
		return false;
	end
    for i = 1,#array1,1 do
        if array1[i] ~= array2[i] then
			return false;
		end
    end
	return true;
end

-- (General Use) Create a copy of an array
function arrayCopy(array)
	copy = {};
    for k, v in pairs(array) do
        copy[k] = v;
    end
	return copy;
end

-- (General Use) Sum the elements of an array
function arraySum(array)
	sum = 0;
    for i = 1,#array,1 do
        sum = sum + array[i];
    end
	return sum;
end

-- (General Use) Remove value from array by value
function removeValue(array, value)
    for i, v in ipairs(array) do
        if v == value then
            table.remove(array, i)
			return true;
        end
    end
	return false;
end

-- (General Use) Find the index of a value in an array, returning -1 if it doesn't exist
function findValue(array, value)
    for i, v in ipairs(array) do
        if v == value then
			return i;
        end
    end
	return -1;
end

-- (General Use) Check if there exists a certain value in an array
function hasValue(array, value)
    for i, v in ipairs(array) do
        if v == value then
			return true;
        end
    end
	return false;
end

-- (General Use) Check if there exists a value in an array within a certain range
function hasValueInRange(array, min, max)
    for i, v in ipairs(array) do
        if v >= min and v <= max then
			return true;
        end
    end
	return false;
end

-- (General Use) Check if there exists a value in an array higher than a certain value
function hasValueHigherThan(array, high)
    for i, v in ipairs(array) do
		if type(v) == "number" then
			if v > high then
				return true;
			end
		end
    end
	return false;
end

-- (General Use) Check if there exists a value in an array lower than a certain value
function hasValueLowerThan(array, low)
    for i, v in ipairs(array) do
		if type(v) == "number" then
			if v < low then
				return true;
			end
		end
    end
	return false;
end

-- (General Use) Get the minimum value in the array (with at least 1 element)
function minimumValue(array)
    minimum = array[1];
    for i = 2, #array do
        if array[i] < minimum then
            minimum = array[i];
        end
    end
    return minimum;
end

-- PRIMARY FUNCTIONS
-- Handles beginning of execution, including advancing to the point where framerules can be chosen, as well as the main loop
-- The framerule is selected (while ensuring it is viable to check) and the gamestate is advanced to the point where Mario begins to run
function run()
	-- Indicate new session in log
	writeToLog("\n----------------------------------------\n----------------------------------------\n");

	while true do
		-- Advance to the first actionable frame of the level
		advanceToLevel();
		
		-- Preliminary framerule check on first actionable frame
		-- Before we start searching for patterns, lets first make sure a despawn and TAS shot is theoretically possible on this framerule
		rng = getTrimmedRNG();
		
		-- Despawn check
		-- Iterate 907 times to get to the RNG value of the last frame before the 3 frames where the despawn can potentially occur (and be fast enough for TAS 8-2)
		despawn_rng = rng;
		for i = 1,907,1 do
			despawn_rng = iterateTrimmedRNG(despawn_rng);
		end
		valid_val_count = {0, 0, 0};
		
		-- Get bullet bill data on the 3 frames
		for i = 1,3,1 do
			despawn_rng = iterateTrimmedRNG(despawn_rng);
			val = getBulletRNGValues(despawn_rng);
			for j = 1,3,1 do
				if val[j] < 6 then
					valid_val_count[i] = valid_val_count[i] + 1;
				end
			end
		end
		
		-- If the criteria for despawn is not met on a particular frame, no need to check any subpixel ranges that attempt to trigger despawn on that frame
		if valid_val_count[1] < 2 then
			removeValue(subpixel_range_indices, 5);
			removeValue(subpixel_range_indices, 4);
			removeValue(subpixel_range_indices, 3);
		end
		if valid_val_count[2] < 2 then
			removeValue(subpixel_range_indices, 2);
			removeValue(subpixel_range_indices, 1);
			removeValue(subpixel_range_indices, 0);
			removeValue(subpixel_range_indices, -1);
			removeValue(subpixel_range_indices, -2);
		end
		if valid_val_count[3] < 2 then
			removeValue(subpixel_range_indices, -3);
			removeValue(subpixel_range_indices, -4);
			removeValue(subpixel_range_indices, -5);
		end
		
		-- TAS shot check
		-- Iterate 1244 times to get to the RNG value of the last frame before the 3 frames where the TAS shot can potentially occur (and be fast enough for TAS 8-2)
		shot_rng = rng;
		for i = 1,1244,1 do
			shot_rng = iterateTrimmedRNG(shot_rng);
		end
		valid_val_count = {0, 0, 0};
		
		-- Get bullet bill data on the 3 frames
		for i = 1,3,1 do
			shot_rng = iterateTrimmedRNG(shot_rng);
			val = getBulletRNGValues(shot_rng);
			for j = 1,3,1 do
				if val[j] == 3 then
					valid_val_count[i] = valid_val_count[i] + 1;
				end
			end
		end
		
		-- If the criteria for a TAS shot is not met on a final set of frames, no need to check any subpixel ranges that require a TAS shot on one of those frames
		if valid_val_count[3] == 0 then
			removeValue(subpixel_range_indices, -1);
			removeValue(subpixel_range_indices, -2);
			removeValue(subpixel_range_indices, -3);
			removeValue(subpixel_range_indices, -4);
			removeValue(subpixel_range_indices, -5);
			if valid_val_count[2] == 0 then
				removeValue(subpixel_range_indices, 4);
				removeValue(subpixel_range_indices, 3);
				removeValue(subpixel_range_indices, 2);
				removeValue(subpixel_range_indices, 1);
				removeValue(subpixel_range_indices, 0);
				if valid_val_count[1] == 0 then
					removeValue(subpixel_range_indices, 5);
				end
			end
		end
		
		-- The process above has eliminated all subpixels ranges which cannot produce a plant despawn and a TAS shot fast enough for TAS 8-2
		-- Thus, we can proceed with these arrays, since they will be empty if it is impossible
		-- We set Mario to do the necessary fast accel, and then we begin the brute forcing
		while getMarioXSpeed() < 26 do
			joypad.set(1, inputRightB);
		
			-- Advance frame
			emu.frameadvance();
		end
		
		timer = 0;
		
		-- Fast accel movement
		while getMarioXPosition() < 160 do
			if timer == 0 then
				joypad.set(1, inputLeftB);
			elseif timer == 1 then
				joypad.set(1, inputRightBA);
			else
				joypad.set(1, inputRightB);
			end
		
			-- Advance frame and timer
			emu.frameadvance();
			timer = timer + 1;
		end
		
		-- Create the framerule directories before we begin, for storing result files
		os.execute("mkdir \"despawns\\" .. tostring(current_framerule) .. "\"");
		os.execute("mkdir \"close calls\\" .. tostring(current_framerule) .. "\"");
		
		writeToLog("{" .. table.concat(subpixel_range_indices, ", ") .. "}");
		
		subrangeStateSet(subpixel_range_indices);
		
		-- Framerule is complete at this point
		endFramerule();
	end
end

-- Copy of run function for the TAS accel setting
-- A smaller set of possibilities are verified as the goal is to lose no frames
function run_tam()
	-- Indicate new session in log
	writeToLog("\n----------------------------------------\n----------------------------------------\n");

	while true do
		-- Advance to the first actionable frame of the level
		advanceToLevel();
		
		-- Preliminary framerule check on first actionable frame
		-- Before we start searching for patterns, lets first make sure a despawn and TAS shot is theoretically possible on this framerule
		rng = getTrimmedRNG();
		
		-- Despawn check
		-- Iterate 905 times to get to the RNG value of the last frame before the 2 frames where the despawn can potentially occur (and still be perfect)
		despawn_rng = rng;
		for i = 1,905,1 do
			despawn_rng = iterateTrimmedRNG(despawn_rng);
		end
		valid_val_count = {0, 0};
		
		-- Get bullet bill data on the 2 frames
		for i = 1,2,1 do
			despawn_rng = iterateTrimmedRNG(despawn_rng);
			val = getBulletRNGValues(despawn_rng);
			for j = 1,3,1 do
				if val[j] < 6 then
					valid_val_count[i] = valid_val_count[i] + 1;
				end
			end
		end
		
		-- If the criteria for despawn is not met on a particular frame, no need to check any subpixel ranges that attempt to trigger despawn on that frame
		if valid_val_count[1] < 2 then
			removeValue(subpixel_range_indices_tas_accel, 3);
		end
		if valid_val_count[2] < 2 then
			removeValue(subpixel_range_indices_tas_accel, 2);
			removeValue(subpixel_range_indices_tas_accel, 1);
			removeValue(subpixel_range_indices_tas_accel, 0);
		end
		
		-- TAS shot check
		-- Iterate 1244 times to get to the RNG value where the TAS shot must occur to be perfect
		for i = 1,1244,1 do
			shot_rng = iterateTrimmedRNG(shot_rng);
		end
		valid_val_count = 0;
		
		-- Get bullet bill data on that frame
		val = getBulletRNGValues(shot_rng);
		for j = 1,3,1 do
			if val[j] == 3 then
				valid_val_count = valid_val_count + 1;
			end
		end
		
		-- If the criteria for a TAS shot is not met, we don't need to check this framerule, and so we remove all indices
		if valid_val_count == 0 then
			removeValue(subpixel_range_indices_tas_accel, 3);
			removeValue(subpixel_range_indices_tas_accel, 2);
			removeValue(subpixel_range_indices_tas_accel, 1);
			removeValue(subpixel_range_indices_tas_accel, 0);
		end
		
		-- The process above has eliminated all subpixels ranges which cannot produce a plant despawn and a TAS shot that is perfect
		-- Thus, we can proceed with these arrays, since they will be empty if it is impossible
		-- We set Mario to do the necessary fast accel, and then we begin the brute forcing
		timer = 0;
		
		-- First accel movement
		while getMarioXSpeed() < 26 do
			if timer == 0 then
				joypad.set(1, inputLeftB);
			elseif timer == 1 then
				joypad.set(1, inputB);
			elseif timer == 2 then
				joypad.set(1, inputRightBA);
			else
				joypad.set(1, inputRightB);
			end
		
			-- Advance frame and timer
			emu.frameadvance();
			timer = timer + 1;
		end
		
		timer = 0;
		
		-- Second accel movement
		while getMarioXPosition() < 160 do
			if timer == 0 then
				joypad.set(1, inputLeftB);
			elseif timer == 1 then
				joypad.set(1, inputRightBA);
			else
				joypad.set(1, inputRightB);
			end
		
			-- Advance frame and timer
			emu.frameadvance();
			timer = timer + 1;
		end
		
		-- Create the framerule directories before we begin, for storing result files
		os.execute("mkdir \"despawns\\" .. tostring(current_framerule) .. "\"");
		os.execute("mkdir \"close calls\\" .. tostring(current_framerule) .. "\"");
		
		writeToLog("{" .. table.concat(subpixel_range_indices_tas_accel, ", ") .. "}");
		
		subrangeStateSet(subpixel_range_indices_tas_accel);
		
		-- Framerule is complete at this point
		endFramerule();
	end
end

-- Copy of run function for the TAS accel setting
-- A smaller set of possibilities are verified as the goal is to lose no frames
function run_lrtam()
	-- Indicate new session in log
	writeToLog("\n----------------------------------------\n----------------------------------------\n");

	while true do
		-- Advance to the first actionable frame of the level
		advanceToLevel();
		
		-- Preliminary framerule check on first actionable frame
		-- Before we start searching for patterns, lets first make sure a despawn and TAS shot is theoretically possible on this framerule
		rng = getTrimmedRNG();
		
		-- Despawn check
		-- Iterate 904 times to get to the RNG value where the despawn must occur to be perfect
		despawn_rng = rng;
		for i = 1,904,1 do
			despawn_rng = iterateTrimmedRNG(despawn_rng);
		end
		valid_val_count = 0;
		
		-- Get bullet bill data on that frame
		val = getBulletRNGValues(despawn_rng);
		for j = 1,3,1 do
			if val[j] < 6 then
				valid_val_count = valid_val_count + 1;
			end
		end
		
		-- If the criteria for despawn is not met on a particular frame, no need to check any subpixel ranges that attempt to trigger despawn on that frame
		if valid_val_count < 2 then
			removeValue(subpixel_range_indices_lr_tas_accel, 2);
			removeValue(subpixel_range_indices_lr_tas_accel, 1);
			removeValue(subpixel_range_indices_lr_tas_accel, 0);
		end
		
		-- TAS shot check
		-- Iterate 1241 times to get to the RNG value where the TAS shot must occur to be perfect
		for i = 1,1241,1 do
			shot_rng = iterateTrimmedRNG(shot_rng);
		end
		valid_val_count = 0;
		
		-- Get bullet bill data on that frame
		val = getBulletRNGValues(shot_rng);
		for j = 1,3,1 do
			if val[j] == 3 then
				valid_val_count = valid_val_count + 1;
			end
		end
		
		-- If the criteria for a TAS shot is not met, we don't need to check this framerule, and so we remove all indices
		if valid_val_count == 0 then
			removeValue(subpixel_range_indices_lr_tas_accel, 3);
			removeValue(subpixel_range_indices_lr_tas_accel, 2);
			removeValue(subpixel_range_indices_lr_tas_accel, 1);
			removeValue(subpixel_range_indices_lr_tas_accel, 0);
		end
		
		-- The process above has eliminated all subpixels ranges which cannot produce a plant despawn and a TAS shot that is perfect
		-- Thus, we can proceed with these arrays, since they will be empty if it is impossible
		-- We set Mario to do the necessary fast accel, and then we begin the brute forcing
		timer = 0;
		
		-- First accel movement
		while getMarioXSpeed() < 26 do
			if timer == 0 then
				joypad.set(1, inputLeftRightB);
			elseif timer == 1 then
				joypad.set(1, inputRightBA);
			elseif timer == 21 then
				joypad.set(1, inputB);
			else
				joypad.set(1, inputRightB);
			end
		
			-- Advance frame and timer
			emu.frameadvance();
			timer = timer + 1;
		end
		
		timer = 0;
		
		-- Second accel movement
		while getMarioXPosition() < 160 do
			if timer == 0 then
				joypad.set(1, inputLeftB);
			elseif timer == 1 then
				joypad.set(1, inputRightBA);
			else
				joypad.set(1, inputRightB);
			end
		
			-- Advance frame and timer
			emu.frameadvance();
			timer = timer + 1;
		end
		
		-- Create the framerule directories before we begin, for storing result files
		os.execute("mkdir \"despawns\\" .. tostring(current_framerule) .. "\"");
		os.execute("mkdir \"close calls\\" .. tostring(current_framerule) .. "\"");
		
		writeToLog("{" .. table.concat(subpixel_range_indices_lr_tas_accel, ", ") .. "}");
		
		subrangeStateSet(subpixel_range_indices_lr_tas_accel);
		
		-- Framerule is complete at this point
		endFramerule();
	end
end

-- Set the subpixel range, and then proceed with execution
function subrangeStateSet(indices)
	-- Reset timer
	timer = 0;
	
	-- Create a savestate for changing the subpixel range
	subrangeState = savestate.object(1);
	savestate.save(subrangeState);
	
	-- If on the first framerule with a set starting configuration, get the index for the desired subpixel range to start at
	start = 1;
	if SET_STARTING_CONFIGURATION and first_framerule then
		start = findValue(indices, STARTING_SUBRANGE);
		if start == -1 then
			writeToLog("Starting subrange value is not available");
			start = 1;
		end
	end
	
	-- Define the first "perfect" subpixel range, depending on the current accel mode
	perfect = 5;
	if ACCEL_MODE == 1 then
		perfect = 3;
	elseif ACCEL_MODE == 2 then
		perfect = 2;
	end

	-- Cycles through all viable subpixel ranges
	for s, v in ipairs(indices) do
		-- Jump to the desired subpixel range if this is the first framerule
		if s >= start then
			-- First frame, set Mario's height to way up to avoid accidental collision with enemies
			-- After this frame, we also no longer need to use R+B to move forward
			joypad.set(1, inputRightB);
			
			-- Hover Mario away from enemies
			memory.writebyte(0x00CE, 45);
			-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
			memory.writebyte(0x009F, 1);
			memory.writebyte(0x0433, 0);
			
			-- Display data and advance frame/timer
			displayAndAdvance();
			
			-- Get the count of necessary subpixel range delays to perform
			necessary_delays = perfect - v;
			
			while necessary_delays > 0 do
				-- Set this to indicate a delay is occurring, so nothing unintended happens
				ongoing_offset_frame = true;
				
				-- Burn through the necessary delays by slowing down Mario by factors of 8 speed
				if necessary_delays <= 5 then
					memory.writebyte(0x0057, 40 - (necessary_delays * 8));
					necessary_delays = 0;
				else
					memory.writebyte(0x0057, 0);
					necessary_delays = necessary_delays - 5;
				end
				
				-- Hover Mario away from enemies
				memory.writebyte(0x00CE, 45);
				-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
				memory.writebyte(0x009F, 1);
				memory.writebyte(0x0433, 0);
				
				-- Display data and advance frame/timer
				displayAndAdvance();
				
				-- Set this back in case we are done with the delays
				ongoing_offset_frame = false;
			end
			
			-- Bring Mario back up to speed before the next movement
			memory.writebyte(0x0700, 40);
			memory.writebyte(0x0057, 40);
			timer = 0;
			
			while getMarioXPosition() <= 450 do
				if (getMarioXPosition() > 300 and getMarioXPosition() < 400) then
					-- Change Marios height to dodge the lakitu
					memory.writebyte(0x00CE, 0);
				else
					-- Otherwise, keep him hovering at the usual height
					memory.writebyte(0x00CE, 45);
				end
				-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
				memory.writebyte(0x009F, 1);
				memory.writebyte(0x0433, 0);
			
				-- Display data and advance frame/timer
				displayAndAdvance();
			end
			
			iteration_data["subpixel_range"] = v;
			writeToLog(v);
			
			if not DISABLE_DELAYS and #delay_location_list > 0 then
				-- Gather delay data
				-- To get the number of possible slowdowns we can perform, we count the total subsequent subpixel ranges that work, down to 3, 0, -2, or -5
				-- First we find which lower limit applies to this case
				lower_limit = 3;
				if v < 3 then
					lower_limit = 0;
					if v < 1 then
						lower_limit = -2;
						if v < -2 then
							lower_limit = -5;
						end
					end
				end
				
				-- Then we find the number of delays we can do, making sure all subpixel ranges are adjacent
				delay_total = 0;
				last_value = v;
				for i = s-1,1,-1 do
					if subpixel_range_indices[i] >= lower_limit and last_value - subpixel_range_indices[i] == 1 then
						delay_total = delay_total + 1;
						last_value = subpixel_range_indices[i];
					end
				end
				
				-- Now we extract the capacities from the delay location list and use that for the delay loop
				delay_capacities = {};
				for i, d in ipairs(delay_location_list) do
					delay_capacities[i] = d[2];
				end
			
				-- If on the first framerule with a set starting configuration, set the starting index to match that of the given starting delays
				trackers = {count = 0, start_index = 1};
				if SET_STARTING_CONFIGURATION and first_framerule then
					trackers["start_index"] = 0;
					
					-- Run the delay loop with the starting framerule configuration to extract the proper starting index
					delayLoop(#delay_location_list, {}, trackers, delay_capacities, delay_total, "start");
					
					-- If the starting index is still 0, we never found the matching index for the set delays, so we resort to the default
					if trackers["start_index"] == 0 then
						writeToLog("Starting delays are invalid");
						trackers["start_index"] = 1;
					end
				end
				
				-- Run the delay loop again, this time with the main configuration to use each iteration for brute-forcing
				trackers["count"] = 0;
				delayLoop(#delay_location_list, {}, trackers, delay_capacities, delay_total, "main");
			else
				-- If the delay location list is empty, we skip all of that and go straight to the lakitu state function
				iteration_data["delay_list"] = {};
				lakituStateSet();
				
				-- Now that the subpixel range has been processed, combine all result files
				mergeOutput();
			end
			
			-- Reset the state list, as Mario will now have a different positioning
			state_list = {{}, {}, {}, {}, {}, {}, {}};
			
			-- Load back to subrangeState
			savestate.load(subrangeState);
		end
	end
end

-- Set the lakitu state, and then proceed with execution
function lakituStateSet()
	-- Reset timer
	timer = 0;
	
	-- Create a savestate for lakitu behaviour
	lakituState = savestate.object(2);
	savestate.save(lakituState);
	
	-- If on the first framerule with a set starting configuration, get the index for the desired lakitu state to start at
	start = 1;
	if SET_STARTING_CONFIGURATION and first_framerule then
		start = STARTING_LAKITU_STATE;
	end
	
	-- Checks normal, despawned, and bopped states
	-- Starts at the desired lakitu state if this is the first framerule
	for i = start,3,1 do
		-- Lakitu adjustment
		while timer < 30 do
			-- i = 1 -> normal
			if i == 1 then
				-- Keep Marios height the same
				memory.writebyte(0x00CE, 45);
			end
			
			-- i = 2 -> despawn
			if i == 2 then
				-- Set Mario to despawn height
				memory.writebyte(0x00CE, 0);
			end
			
			-- i = 3 -> bop
			if i == 3 then
				if timer > 5 then
					-- Set Mario to bop height
					memory.writebyte(0x00CE, 30);
				else
					-- Otherwise, for the first few frames, keep Marios height the same so the spiny doesn't despawn
					memory.writebyte(0x00CE, 45);
				end
			end
			
			-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
			memory.writebyte(0x009F, 1);
			memory.writebyte(0x0433, 0);
			
			-- Display data and advance frame/timer
			displayAndAdvance();
		end
		
		-- Runs until Mario reaches the koopa pair
		while getMarioXPosition() < 1008 do
			-- Hover Mario away from enemies
			memory.writebyte(0x00CE, 45);
			-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
			memory.writebyte(0x009F, 1);
			memory.writebyte(0x0433, 0);
		
			-- Display data and advance frame/timer
			displayAndAdvance();
		end
		
		iteration_data["lakitu_state"] = i;
		koopaPairStateSet();
		
		-- Load back to lakituState
		savestate.load(lakituState);
	end
end

function koopaPairStateSet()
	-- Reset timer
	timer = 0;
	
	-- Create a savestate for koopa pair behaviour
	koopaPairState = savestate.object(3);
	savestate.save(koopaPairState);
	
	-- If on the first framerule with a set starting configuration, get the index for the desired koopa pair state to start at
	start = 1;
	if SET_STARTING_CONFIGURATION and first_framerule then
		start = 0;
		for i, v in ipairs(koopa_pair_frames[iteration_data["subpixel_range"] + 6]) do
			if arraysEqual(v, STARTING_KOOPA_PAIR_STATE) then
				start = i;
			end
		end
		if start == 0 then
			writeToLog("Starting koopa pair state is not available");
			start = 1;
		end
	end
	
	-- Checks all koopa pair bop combos for the current subpixel range as recorded in the koopa_pair_frames array
	for k, p in ipairs(koopa_pair_frames[iteration_data["subpixel_range"] + 6]) do
		-- Jump to the desired koopa pair state if this is the first framerule
		if k >= start then
			-- Koopa pair stomps
			while getMarioXPosition() < 1104 do
				-- On normal lakitu movement, the first koopa is in slot 4 and the second koopa is in slot 3
				if iteration_data["lakitu_state"] == 1 then
					if timer == p[1] then
						-- Set Mario's Y-pixel to the Y-pixel of the first koopa (in slot 4) to stomp it
						memory.writebyte(0x00CE, memory.readbyte(0x00D2) - 16);
					elseif timer == p[2] then
						-- Set Mario's Y-pixel to the Y-pixel of the second koopa (in slot 3) to stomp it
						memory.writebyte(0x00CE, memory.readbyte(0x00D1) - 16);
					else
						-- Otherwise, hover Mario normally
						memory.writebyte(0x00CE, 45);
					end
				end
				
				-- On despawn lakitu movement, the first koopa is in slot 4 and the second koopa is in slot 1
				if iteration_data["lakitu_state"] == 2 then
					if timer == p[1] then
						-- Set Mario's Y-pixel to the Y-pixel of the first koopa (in slot 4) to stomp it
						memory.writebyte(0x00CE, memory.readbyte(0x00D2) - 16);
					elseif timer == p[2] then
						-- Set Mario's Y-pixel to the Y-pixel of the second koopa (in slot 1) to stomp it
						memory.writebyte(0x00CE, memory.readbyte(0x00CF) - 16);
					else
						-- Otherwise, hover Mario normally
						memory.writebyte(0x00CE, 45);
					end
				end
				
				-- On bopped lakitu movement, the first koopa is in slot 2 and the second koopa is in slot 3
				if iteration_data["lakitu_state"] == 3 then
					if timer == p[1] then
						-- Set Mario's Y-pixel to the Y-pixel of the first koopa (in slot 2) to stomp it
						memory.writebyte(0x00CE, memory.readbyte(0x00D0) - 16);
					elseif timer == p[2] then
						-- Set Mario's Y-pixel to the Y-pixel of the second koopa (in slot 3) to stomp it
						memory.writebyte(0x00CE, memory.readbyte(0x00D1) - 16);
					else
						-- Otherwise, hover Mario normally
						memory.writebyte(0x00CE, 45);
					end
				end
				
				-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
				memory.writebyte(0x009F, 1);
				memory.writebyte(0x0433, 0);
			
				-- Display data and advance frame/timer
				displayAndAdvance();
			end
			
			-- Move to phase 1
			while getMarioXPosition() < 1264 do
				-- Hover Mario away from enemies
				memory.writebyte(0x00CE, 45);
				-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
				memory.writebyte(0x009F, 1);
				memory.writebyte(0x0433, 0);
			
				-- Display data and advance frame/timer
				displayAndAdvance();
			end
			
			iteration_data["koopa_pair_state"] = p;
			phase1();
			
			-- Load back to koopaPairState
			savestate.load(koopaPairState);
		end
	end
end

-- Handles behaviour up to the 1st bullet bill column
-- Expected enemies: None
function phase1()
	-- Reset timer
	timer = 0;
	
	-- Create a savestate for phase 1
	phase1State = savestate.object(4);
	savestate.save(phase1State);
	
	-- Run the state check at the start of the phase, to make sure we aren't unnecessarily checking states we've already visited
	if checkState(1) then
		-- Handle end of iteration behaviour
		endIteration();
		
		return;
	end
	
	-- Initialize array of potential stomp frames
	stomps1 = {{"X"}, {"X"}, {"X"}, {"X"}, {"X"}};
	first_frame_bullet_stomp = true;
	
	-- First pass-through: do the normal movement but map out the potential enemy stomps (bullet bills)
	while getMarioXPosition() < 1344 do
		enemy_pos = getFirstThreeEnemyXPositions();
		mario_pos = getMarioXPosition();
		
		-- If the frame timer is odd, collision with enemies is possible, so we check if Mario's hitbox horizontally aligns with any enemy hitbox
		if getFrameTimer() % 2 == 1 then
			for i = 1,5,1 do
				if getEnemyXSpeed(i) == 24 or getEnemyXSpeed(i) == 232 then
					-- Enemy is bullet bill, hitbox is 11 pixels wide
					if math.abs(mario_pos - enemy_pos[i] - 3) <= 10 then
						if first_frame_bullet_stomp then
							table.insert(stomps1[i], timer - 2);
							first_frame_bullet_stomp = false;
						else
							-- If the bullet is too far, it will be impossible to land on the bullet bill launcher without bonking it
							if mario_pos >= 1325 then
								table.insert(stomps1[i], timer - 2);
							end
						end
					end
				end
			end
		end
		
		-- Hover Mario away from enemies
		memory.writebyte(0x00CE, 45);
		
		-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
		memory.writebyte(0x009F, 1);
		memory.writebyte(0x0433, 0);
	
		-- Display data and advance frame/timer
		displayAndAdvance();
	end
	
	iteration_data["phase_1_stomps"] = {"X", "X", "X", "X", "X"};
	phase2();
	
	-- Load back to phase1State
	savestate.load(phase1State);
	
	-- All subsequent passthroughs: iterate through the possible stomps as recording in the first passthroughs
	iteratePhase(stomps1, "phase_1_stomps", phase1State, 1344, phase2, false);
end

-- Handles behaviour up to the 2nd bullet bill column
-- Expected enemies: 1x Parakoopa
function phase2()
	-- Reset timer
	timer = 0;
	
	-- Create a savestate for phase 2
	phase2State = savestate.object(5);
	savestate.save(phase2State);
	
	-- Run the state check at the start of the phase, to make sure we aren't unnecessarily checking states we've already visited
	if checkState(2) then
		-- Handle end of iteration behaviour
		endIteration();
		
		return;
	end
	
	-- Initialize array of potential stomp frames
	stomps2 = {{"X"}, {"X"}, {"X"}, {"X"}, {"X"}};
	first_frame_koopa_stomp = true;
	
	-- First pass-through: do the normal movement but map out the potential enemy stomps
	while getMarioXPosition() < 1472 do
		enemy_pos = getAllEnemyXPositions();
		mario_pos = getMarioXPosition();
		
		-- If the frame timer is odd, collision with enemies is possible, so we check if Mario's hitbox horizontally aligns with any enemy hitbox
		-- Also ensure that no phantom bullets are getting detected by preventing enemy detection when Mario is over a bullet bill launcher
		if getFrameTimer() % 2 == 1 and timer > 14 then
			for i = 1,5,1 do
				if getEnemyXSpeed(i) == 8 or getEnemyXSpeed(i) == 248 then
					-- Enemy is koopa or buzzy beetle, hitbox is 13 pixels wide
					if math.abs(mario_pos - enemy_pos[i] - 1) <= 11 then
						if first_frame_koopa_stomp then
							table.insert(stomps2[i], timer - 2);
							first_frame_koopa_stomp = false;
						else
							-- If the koopa is too low, it will be impossible to get the stomp on that frame without hitting the bullet bill launcher
							if getEnemyYPosition(i) <= 180 then
								table.insert(stomps2[i], timer - 2);
							end
						end
					end
				end
			end
		end
		
		-- Hover Mario away from enemies
		memory.writebyte(0x00CE, 45);
		
		-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
		memory.writebyte(0x009F, 1);
		memory.writebyte(0x0433, 0);
	
		-- Display data and advance frame/timer
		displayAndAdvance();
	end
	
	iteration_data["phase_2_stomps"] = {"X", "X", "X", "X", "X"};
	phase3();
	
	-- Load back to phase2State
	savestate.load(phase2State);
	
	-- All subsequent passthroughs: iterate through the possible stomps as recording in the first passthroughs
	iteratePhase(stomps2, "phase_2_stomps", phase2State, 1472, phase3, true);
end

-- Handles behaviour up to the 3rd bullet bill column
-- Expected enemies: 1x Parakoopa
function phase3()
	-- Reset timer
	timer = 0;
	
	-- Create a savestate for phase 3
	phase3State = savestate.object(6);
	savestate.save(phase3State);
	
	-- Run the state check at the start of the phase, to make sure we aren't unnecessarily checking states we've already visited
	if checkState(3) then
		-- Handle end of iteration behaviour
		endIteration();
		
		return;
	end
	
	-- Initialize array of potential stomp frames
	stomps3 = {{"X"}, {"X"}, {"X"}, {"X"}, {"X"}};
	first_frame_bullet_stomp = true;
	checked_buzzy_beetle = false;
	
	-- Initial pass-through: do the normal movement but map out the potential enemy stomps
	while getMarioXPosition() < 1664 do
		enemy_pos = getAllEnemyXPositions();
		mario_pos = getMarioXPosition();
		
		-- If the frame timer is odd, collision with enemies is possible, so we check if Mario's hitbox horizontally aligns with any enemy hitbox
		-- Also ensure that no phantom bullets are getting detected by preventing enemy detection when Mario is over a bullet bill launcher
		if getFrameTimer() % 2 == 1 and timer > 14 then
			for i = 1,5,1 do
				if getEnemyXSpeed(i) == 8 or getEnemyXSpeed(i) == 248 then
					-- Enemy is koopa or buzzy beetle, hitbox is 13 pixels wide
					-- Because this koopa always faces right, we expect the left-side stomp to have minimal effect, and so we only check 1 case of it
					-- At the exact midpoint of Mario and the enemy, it is considered a left-side stomp, so we first ensure the difference is greater than 0
					if mario_pos - enemy_pos[i] - 1 > 0 then
						if mario_pos - enemy_pos[i] - 1 <= 4 then
							-- Should only run once
							table.insert(stomps3[i], timer - 6);
							-- A late stomp on this koopa is only possible when the previous koopa was stomped on the first frame
							if hasValue(iteration_data["phase_2_stomps"], 0) or not hasValueHigherThan(iteration_data["phase_2_stomps"], -1) then
								table.insert(stomps3[i], timer - 2);
							end
						elseif mario_pos - enemy_pos[i] - 1 <= 11 then
							-- A late stomp on this koopa is only possible when the previous koopa was stomped on the first frame
							if hasValue(iteration_data["phase_2_stomps"], 0) or not hasValueHigherThan(iteration_data["phase_2_stomps"], -1) then
								table.insert(stomps3[i], timer - 2);
							end
						end
					end
				end
				if getEnemyXSpeed(i) == 24 or getEnemyXSpeed(i) == 232 then
					-- Enemy is bullet bill, hitbox is 11 pixels wide
					if math.abs(mario_pos - enemy_pos[i] - 3) <= 10 then
						if first_frame_bullet_stomp then
							table.insert(stomps3[i], timer - 2);
							first_frame_bullet_stomp = false;
						else
							-- If the bullet is too far, it will be impossible to land on the bullet bill launcher without bonking it
							if mario_pos >= 1645 then
								table.insert(stomps3[i], timer - 2);
							end
						end
					end
				end
			end
		end
		
		-- Run once we pass the point where the first buzzy beetle loads
		if not checked_buzzy_beetle and getMarioXPosition() >= 1632 then
			-- Find the buzzy beetle if it exists, and record the plant despawn type it indicates
			-- We assume for now that the first buzzy beetle of the buzzy beetle pair will load into slots 4 or 5, or be despawned
			-- The above assumption is required for this buzzy beetle loading into slots 1-3 to be indicative of a Type C despawn, instead of being impossible
			iteration_data["despawn_type"] = "B";
			for i = 1,3,1 do
				if getEnemyXPosition(i) >= 1764 and getEnemyXPosition(i) <= 1788 then
					iteration_data["despawn_type"] = "C";
				end
			end
			
			checked_buzzy_beetle = true;
		end
		
		-- Hover Mario away from enemies
		memory.writebyte(0x00CE, 45);
		
		-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
		memory.writebyte(0x009F, 1);
		memory.writebyte(0x0433, 0);
	
		-- Display data and advance frame/timer
		displayAndAdvance();
	end
	
	iteration_data["phase_3_stomps"] = {"X", "X", "X", "X", "X"};
	phase4();
	
	-- Load back to phase3State
	savestate.load(phase3State);
	
	-- All subsequent passthroughs: iterate through the possible stomps as recording in the first passthroughs
	iteratePhase(stomps3, "phase_3_stomps", phase3State, 1664, phase4, false);
end

-- Handles behaviour up to the 4th bullet bill column
-- Expected enemies: 1x Buzzy Beetle
function phase4()
	-- Reset timer
	timer = 0;
	
	-- Create a savestate for phase 4
	phase4State = savestate.object(7);
	savestate.save(phase4State);
	
	-- Run the state check at the start of the phase, to make sure we aren't unnecessarily checking states we've already visited
	if checkState(4) then
		-- Handle end of iteration behaviour
		endIteration();
		
		return;
	end
	
	-- First pass-through: do the normal movement but map out the potential enemy stomps
	-- This is broken up into 3 sections, so we can check certain cases to rule out the combo early
	while getMarioXPosition() < 1792 do
		-- Hover Mario away from enemies
		memory.writebyte(0x00CE, 45);
		-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
		memory.writebyte(0x009F, 1);
		memory.writebyte(0x0433, 0);
	
		-- Display data and advance frame/timer
		displayAndAdvance();
	end
	
	-- If the first buzzy beetle of the buzzy beetle pair spawned into slots 1-3, we correct our assumption from the previous phase
	-- In this case, if this was originally a Type B despawn, it now becomes a Type A (standard) despawn
	-- If this was originally a Type C despawn, despawn is impossible since the earlier buzzy beetle loading into slots 1-3 requires this buzzy beetle to be in slot 4 or 5
	bad_buzzy_1 = false;
	for i = 1,3,1 do
		if getEnemyXPosition(i) >= 1924 and getEnemyXPosition(i) <= 1948 then
			if iteration_data["despawn_type"] == "B" then
				iteration_data["despawn_type"] = "A";
			end
			if iteration_data["despawn_type"] == "C" then
				bad_buzzy_1 = true;
			end
		end
	end
	
	if bad_buzzy_1 then
		-- Handle end of iteration behaviour
		endIteration();
		
		return;
	end
	
	while getMarioXPosition() < 1824 do
		-- Hover Mario away from enemies
		memory.writebyte(0x00CE, 45);
		-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
		memory.writebyte(0x009F, 1);
		memory.writebyte(0x0433, 0);
	
		-- Display data and advance frame/timer
		displayAndAdvance();
	end
		
	-- If the second buzzy beetle of the buzzy beetle pair spawned into slot 4 or 5, despawn is impossible since it is loaded when the last koopa and piranha plant spawn
	bad_buzzy_2 = false;
	for i = 4,5,1 do
		if getEnemyXPosition(i) >= 1956 and getEnemyXPosition(i) <= 1980 then
			bad_buzzy_2 = true;
		end
	end
	
	if bad_buzzy_2 then
		-- Handle end of iteration behaviour
		endIteration();
		
		return;
	end
	
	iteration_data["phase_4_stomps"] = {"X", "X", "X", "X", "X"};
	phase5();
	
	-- Load back to phase4State
	savestate.load(phase4State);
end

-- Handles behaviour up to the 5th bullet bill column
-- Expected enemies: None
function phase5()
	-- Reset timer
	timer = 0;
	
	-- Create a savestate for phase 5
	phase5State = savestate.object(8);
	savestate.save(phase5State);
	
	-- Run the state check at the start of the phase, to make sure we aren't unnecessarily checking states we've already visited
	if checkState(5) then
		-- Handle end of iteration behaviour
		endIteration();
		
		return;
	end
	
	-- First pass-through: do the normal movement but map out the potential enemy stomps
	-- This is broken up into 2 sections, so we can check a certain case to rule out the combo early
	while getMarioXPosition() < 1859 do
		-- Hover Mario away from enemies
		memory.writebyte(0x00CE, 45);
		-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
		memory.writebyte(0x009F, 1);
		memory.writebyte(0x0433, 0);
	
		-- Display data and advance frame/timer
		displayAndAdvance();
	end
	
	-- If the first piranha plant spawned into slot 4 or 5, despawn is impossible since it is loaded when the last koopa and piranha plant spawn
	bad_piranha = false;
	for i = 4,5,1 do
		if getEnemyXPosition(i) == 2104 then
			bad_piranha = true;
		end
	end
	
	if bad_piranha then
		-- Handle end of iteration behaviour
		endIteration();
		
		return
	end
	
	while getMarioXPosition() < 1888 do
		-- Hover Mario away from enemies
		memory.writebyte(0x00CE, 45);
		-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
		memory.writebyte(0x009F, 1);
		memory.writebyte(0x0433, 0);
	
		-- Display data and advance frame/timer
		displayAndAdvance();
	end
	
	iteration_data["phase_5_stomps"] = {"X", "X", "X", "X", "X"};
	phase6();
	
	-- Load back to phase5State
	savestate.load(phase5State);
end

-- Handles behaviour up to the 6th bullet bill column
-- Expected enemies: 2x Buzzy Beetle
function phase6()
	-- Reset timer
	timer = 0;
	
	-- Create a savestate for phase 6
	phase6State = savestate.object(9);
	savestate.save(phase6State);
	
	-- Run the state check at the start of the phase, to make sure we aren't unnecessarily checking states we've already visited
	if checkState(6) then
		-- Handle end of iteration behaviour
		endIteration();
		
		return;
	end
	
	-- Initialize array of potential stomp frames
	stomps6 = {{"X"}, {"X"}, {"X"}, {"X"}, {"X"}};
	stomps6_raw = {{}, {}, {}, {}, {}};
	first_buzzy_slot = -1;
	first_buzzy_despawn = false;
	second_buzzy_despawn = true;
	
	-- First pass-through: do the normal movement but map out the potential enemy stomps
	while getMarioXPosition() < 1984 do
		enemy_pos = getAllEnemyXPositions();
		mario_pos = getMarioXPosition();
		
		-- If the frame timer is odd, collision with enemies is possible, so we check if Mario's hitbox horizontally aligns with any enemy hitbox
		-- Also ensure that no phantom bullets are getting detected by preventing enemy detection when Mario is over a bullet bill launcher
		if getFrameTimer() % 2 == 1 then
			for i = 1,5,1 do
				if getEnemyXSpeed(i) == 8 or getEnemyXSpeed(i) == 248 then
					-- Enemy is koopa or buzzy beetle, hitbox is 13 pixels wide
					if math.abs(mario_pos - enemy_pos[i] - 3) <= 11 and getEnemyYPosition(i) == 184 then
						table.insert(stomps6_raw[i], timer - 2);
						-- Keep track of the first buzzy beetle, because in most cases, that's the only one you can stomp (and only on the last two frames)
						if first_buzzy_slot == -1 then
							first_buzzy_slot = i;
							-- If this runs, the first buzzy beetle was never detected so we conclude that it despawned
							if timer > 12 then
								first_buzzy_despawn = true;
							end
						elseif i ~= first_buzzy_slot then
							-- If this runs, the second buzzy beetle is being detected so we know it hasn't despawned
							second_buzzy_despawn = false;
						end
					end
				end
			end
		end
		
		-- Hover Mario away from enemies
		memory.writebyte(0x00CE, 45);
		-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
		memory.writebyte(0x009F, 1);
		memory.writebyte(0x0433, 0);
	
		-- Display data and advance frame/timer
		displayAndAdvance();
	end
	
	-- Check the contents of stomps6_raw and assign the values to stomps6 based on the spawn states of the buzzy beetles
	if not first_buzzy_despawn and not second_buzzy_despawn then
		-- Both buzzy beetles spawned (as usual), so only the last two frames of the first buzzy beetle can be reached
		if DOUBLE_FRAME_BUZZY_STOMP then
			table.insert(stomps6[first_buzzy_slot], stomps6_raw[first_buzzy_slot][#stomps6_raw[first_buzzy_slot] - 1]);
		end
		table.insert(stomps6[first_buzzy_slot], stomps6_raw[first_buzzy_slot][#stomps6_raw[first_buzzy_slot]]);
	elseif second_buzzy_despawn and not first_buzzy_despawn then
		-- The second buzzy beetle despawned, so every frame on the first buzzy beetle can be used
		for i, v in ipairs(stomps6_raw[first_buzzy_slot]) do
			table.insert(stomps6[first_buzzy_slot], stomps6_raw[first_buzzy_slot][i]);
		end
	end
	
	iteration_data["phase_6_stomps"] = {"X", "X", "X", "X", "X"};
	resultSeekAndCheck();
	
	-- Load back to phase6State
	savestate.load(phase6State);
	
	-- All subsequent passthroughs: iterate through the possible stomps as recording in the first passthroughs
	iteratePhase(stomps6, "phase_6_stomps", phase6State, 1984, resultSeekAndCheck, false);
end

-- After all manipulation has been done, this function is executed, running at most until the frame the plant should spawn to check for a despawn
function resultSeekAndCheck()
	-- Reset timer
	timer = 0;
	
	-- Run the state check at the start of the phase, to make sure we aren't unnecessarily checking states we've already visited
	if checkState(7) then
		-- Handle end of iteration behaviour
		endIteration();
		
		return;
	end

	-- Runs until the last koopa and piranha plant should be loaded in
	while getMarioXPosition() < 2048 do
		-- Hover Mario away from enemies
		memory.writebyte(0x00CE, 45);
		-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
		memory.writebyte(0x009F, 1);
		memory.writebyte(0x0433, 0);
	
		-- Display data and advance frame/timer
		displayAndAdvance();
	end
	
	-- Check if enemy slots 4 and 5 are occupied by the koopa and piranha plant at this point
	-- We only continue if we can confirm this to be the case, since despawn is impossible otherwise
	if getEnemyXPosition(4) > 2144 and getEnemyXPosition(5) > 2144 then
		-- Runs until the frame before the piranha plant should load
		while getMarioXPosition() < 2253 or (getMarioXPosition() == 2253 and getMarioXSubpixel() < 128) do
			-- Hover Mario away from enemies
			memory.writebyte(0x00CE, 45);
			-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
			memory.writebyte(0x009F, 1);
			memory.writebyte(0x0433, 0);
		
			-- Display data and advance frame/timer
			displayAndAdvance();
		end
		
		-- Check the 3 remaining enemy slots at this point
		-- If any of them are occupied by a phantom bullet bill, despawn will be impossible as the filled slot will prevent a bullet timer tick for that slot next frame
		-- However, it could still be occupied by an existing bullet bill, and so we merely take note of it
		prev_slot = getEnemySlots();
		
		-- Now, we advance to the frame where the piranha plant should load in the following few lines
		-- Hover Mario away from enemies
		memory.writebyte(0x00CE, 45);
		-- Ensure Mario stays moving downwards at a controllable speed by constantly resetting y-speed to 1 and y-subspeed to 0
		memory.writebyte(0x009F, 1);
		memory.writebyte(0x0433, 0);
	
		-- Display data and advance frame/timer
		displayAndAdvance();
		
		-- Check the state of the enemies spawned in at this point to evaluate whether the attempt was successful (or came close)
		-- In this case, we define a close call as a despawn attempt where it comes down only to the values of the bullet timers (all enemies are in their correct locations)
		rng = getTrimmedRNG();
		val = getBulletRNGValues(rng);
		timer = getBulletBillTimers();
		slot = getEnemySlots();
		enemy_pos = getAllEnemyXPositions();
		
		-- Remove the piranha plant that we are looking to despawn from the enemy slot list, if it is in the first 3 slots
		-- If it isn't in the first 3 slots, then despawn is impossible with this setup anyway and verifyState will reject it
		for i = 1,3,1 do
			if enemy_pos[i] == 2504 then
				slot[i] = 0;
			end
		end
		
		-- close_call_data has indices "slot_state", "bullet_slot", and "bullet_timer"
		found, close_call, close_call_data = verifyState(val, timer, slot, prev_slot, enemy_pos);
		
		-- Handle output if it was either successful or a close call
		generateOutput(found, close_call, close_call_data, false);
		
		-- Now we check one more possibility - does it work if we delay the spawning of the plant by a frame (if possible / convenient)?
		if (iteration_data["subpixel_range"] >= 3 and iteration_data["subpixel_range"] <= 5 and hasValueInRange(subpixel_range_indices, -2, 2)) or (iteration_data["subpixel_range"] >= -2 and iteration_data["subpixel_range"] <= 2 and hasValueInRange(subpixel_range_indices, -5, -3)) then
			-- Only worth checking if no phantom shots were produced last frame - these will block an attempt for despawn on the next frame anyway
			if not hasValue(close_call_data["slot_state"], "phantom") then
				-- Generate the next frames state
				next_rng = iterateTrimmedRNG(rng);
				next_val = getBulletRNGValues(next_rng);
				next_timer = timer;
				next_slot = getEnemySlots();
				next_prev_slot = getEnemySlots();
				
				-- Remove the piranha plant that we are looking to despawn from the enemy slot list, if it is in the first 3 slots
				for i = 1,3,1 do
					if enemy_pos[i] == 2504 then
						next_slot[i] = 0;
						next_prev_slot[i] = 0;
					end
				end
				
				-- Simulate the decrement of bullet timers and firing of phantom bullets
				for i = 3,1,-1 do
					if next_prev_slot[i] == 0 and next_val[i] < 6 then
						next_timer[next_val[i] + 1] = next_timer[next_val[i] + 1] - 1;
						if next_timer[next_val[i] + 1] < 0 then
							next_timer[next_val[i] + 1] = 14;
							next_slot[i] = 1;
						end
					end
				end
				
				-- Use the new data to check if delaying by a frame would produce a despawn
				-- Reusing enemy_pos here should be fine since the function only checks if one of those enemys is the piranha plant to be despawned, via position
				next_found, next_close_call, next_close_call_data = verifyState(next_val, next_timer, next_slot, next_prev_slot, enemy_pos);
				
				-- Handle output if it was either successful or a close call
				generateOutput(next_found, next_close_call, next_close_call_data, true);
			end
		end
	end
	-- Handle end of iteration behaviour
	endIteration();
end

-- RUN SCRIPT
if ENABLE_TURBO then
	emu.speedmode("turbo");
end

emu.poweron();

if ACCEL_MODE == 1 then
	run_tam();
elseif ACCEL_MODE == 2 then
	run_lrtam();
else
	run();
end