data = {}

-- PIDS
data["pids"] = {}
data["pids"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/pids.png"
data["pids"]["TEXT"] = {
				"Increase D, P, I in order until each wobbles, then back off.",
				"Set F for a good response in full stick flips and rolls.",
				"If necessary, tweak P:D ratio to set response damping to your liking.",
				"Increase O until wobbles occur when jabbing elevator at full collective, back off a bit.",
				"Increase B if you want sharper response."
				}


-- FLIGHT TUNING RATES
data["rates_1"] = {}
data["rates_1"]["table"] = {}
data["rates_1"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/rates.png"
data["rates_1"]["TEXT"] = {
				"Default: We keep this to make button appear for rates.",
				"We will use the sub keys below."
				}
-- RATE TABLE NONE
data["rates_1"]["table"][0] = {
				"All values are set to zero because no RATE TABLE is in use."
				}

-- RATE TABLE BETAFLIGHT
data["rates_1"]["table"][1] = {
				"RC Rate: Maximum rotation rate at full stick deflection.",
				"SuperRate: Increases maximum rotation rate while reducing sensitivity around half stick.",
				"Expo: Reduces sensitivity near the stick's center where fine controls are needed."
				}

-- RATE TABLE RACEFLIGHT
data["rates_1"]["table"][2] = {
				"Rate: Maximum rotation rate at full stick deflection in degrees per second.",
				"Acro+: Increases the maximum rotation rate while reducing sensitivity around half stick.",
				"Expo: Reduces sensitivity near the stick's center where fine controls are needed."
				}

-- RATE TABLE KISS
data["rates_1"]["table"][3] = {
				"RC Rate: Maximum rotation rate at full stick deflection.",
				"Rate: Increases maximum rotation rate while reducing sensitivity around half stick.",
				"RC Curve: Reduces sensitivity near the stick's center where fine controls are needed."
				}

-- RATE TABLE ACTUAL
data["rates_1"]["table"][4] = {
				"Center Sensitivity: Use to reduce sensitivity around center stick. Center Sensitivity set to the same as Max Rate is linear. A lower number than Max Rate will reduce sensitivity around center stick. Note that higher than Max Rate will increase the Max Rate - not recommended as it causes issues in the Blackbox log.",
				"Max Rate: Maximum rotation rate at full stick deflection in degrees per second.",
				"Expo: Reduces sensitivity near the stick's center where fine controls are needed."
				}

-- RATE TABLE QUICK
data["rates_1"]["table"][5] = {
				"RC Rate: Use to reduce sensitivity around center stick. RC Rate set to one half of the Max Rate is linear. A lower number will reduce sensitivity around center stick. Higher than one half of the Max Rate will also increase the Max Rate.",
				"Max Rate: Maximum rotation rate at full stick deflection in degrees per second.",
				"Expo: Reduces sensitivity near the stick's center where fine controls are needed."
				}

-- FLIGHT TUNING - MAIN ROTOR
data["profile_4"] = {}
data["profile_4"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/mainrotor.png"
data["profile_4"]["TEXT"] = {
				"Collective Pitch Compensation: Increasing will compensate for the pitching motion caused by tail drag when climbing.",
				"Cross Coupling Gain: Removes roll coupling when only elevator is applied.",
				"Cross Coupling Ratio: Amount of compensation (pitch vs roll) to apply.",
				"Cross Coupling Feq. Limit: Frequency limit for the compensation, higher value will make the compensation action faster."
				}


-- FLIGHT TUNING - TAIL ROTOR
data["profile_2"] = {}
data["profile_2"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/tailrotor.png"
data["profile_2"]["TEXT"] = {
				"Yaw Stop Gain: Higher stop gain will make the tail stop more aggressively but may cause oscillations if too high. Adjust CW or CCW to make the yaw stops even.",
				"Precomp Cutoff: Frequency limit for all yaw precompensation actions.",
				"Cyclic FF Gain: Tail precompensation for cyclic inputs.",
				"Collective FF Gain: Tail precompensation for collective inputs.",
				"Collective Impulse FF: Impulse tail precompensation for collective inputs. If you need extra tail precompensation at the beginning of collective input."
				}

-- FLIGHT TUNING - GOVERNOR
data["profile_governor"] = {}
data["profile_governor"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/governor.png"
data["profile_governor"]["TEXT"] = {
				"Full headspeed: Headspeed target when at 100% throttle input.",
				"PID master gain: How hard the governor works to hold the RPM.",
				"Gains: Fine tuning of the governor.",
				"Precomp: Governor precomp gain for yaw, cyclic, and collective inputs.",
				"Max throttle: The maximum throttle % the governor is allowed to use.",
				"Tail Torque Assist: For motorized tails. Gain and limit of headspeed increase when using main rotor torque for yaw assist."
				}


-- ADVANCED TUNING - PID CONTROLLER
data["profile_1"] = {}
data["profile_1"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/pidcontroller.png"
data["profile_1"]["TEXT"] = {
				"Error decay ground: PID decay to help prevent heli from tipping over when on the ground.",
				"Error limit: Angle limit for I-term.",
				"Offset limit: Angle limit for High Speed Integral (O-term).",
				"Error rotation: Allow errors to be shared between all axes.",
				"I-term relax: Limit accumulation of I-term during fast movements - helps reduce bounce back after fast stick movements. Generally needs to be lower for large helis and can be higher for small helis. Best to only reduce as much as is needed for your flying style."
				}

-- ADVANCED TUNING - PID BANDWIDTH
data["profile_3"] = {}
data["profile_3"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/pidbandwidth.png"
data["profile_3"]["TEXT"] = {
				"PID Bandwidth: Overall bandwidth in HZ used by the PID loop.",
				"D-term cutoff: D-term cutoff frequency in HZ.",
				"B-term cutoff: B-term cutoff frequency in HZ."
				}

-- ADVANCED TUNING - AUTO LEVEL
data["profile_5"] = {}
data["profile_5"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/autolevel.png"
data["profile_5"]["TEXT"] = {
				"Acro Trainer: How aggressively the heli tilts back to level when flying in Acro Trainer Mode.",
				"Angle Mode: How aggressively the heli tilts back to level when flying in Angle Mode.",
				"Horizon Mode: How aggressively the heli tilts back to level when flying in Horizon Mode."
				}

-- ADVANCED TUNING - RESCUE
data["profile_rescue"] = {}
data["profile_rescue"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/rescue.png"
data["profile_rescue"]["TEXT"] = {
				"Flip to upright: Flip the heli upright when rescue is activated.",
				"Pull-up: How much collective and for how long to arrest the fall.",
				"Climb: How much collective to maintain a steady climb - and how long.",
				"Hover: How much collective to maintain a steady hover.",
				"Flip: How long to wait before aborting because the flip did not work.",
				"Gains: How hard to fight to keep heli level when engaging rescue mode.",
				"Rate and Accel: Max rotation and acceleration rates when leveling during rescue."
				}

-- ADVANCED TUNING - RATES
data["rates_2"] = {}
data["rates_2"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/rates.png"
data["rates_2"]["TEXT"] = {
				"Rates type: Choose the rate type you prefer flying with. Raceflight and Actual are the most straightforward.",
				"Dynamics: Applied regardless of rates type. Typically left on defaults but can be adjusted to smooth heli movements, like with scale helis."
				}


-- HARDWARE - SERVO
data["servos"] = {}
data["servos"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/servos.png"
data["servos"]["TEXT"] = {
				"Servo: Select the servo you would like to edit.",
				"Center: Adjust the center position of the servo.",
				"Minimum/Maximum: Adjust the end points of the selected servo.",
				"Scale: Adjust the amount the servo moves for a given input.",
				"Rate: The frequency the servo runs best at - check with manufacturer.",
				"Speed: The speed the servo moves. Generally only used for the cyclic servos to help the swash move evenly. Optional - leave all at 0 if unsure."
				}

-- HARDWARE - MIXER
data["mixer"] = {}
data["mixer"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/mixer.png"
data["mixer"]["TEXT"] = {
				"Swashplate: Adust swash plate geometry, phase angles, and limits.",
				"Link trims: Use to trim out small leveling issues in your swash plate. Typically only used if the swash links are non-adjustable.",
				"Motorised tail: If using a motorised tail, use this to set the minimum idle speed and zero yaw."
				}

-- HARDWARE - ACCELEROMETER
data["accelerometer"] = {}
data["accelerometer"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/board-alignment.png"
data["accelerometer"]["TEXT"] = {
				"If your helicopter drifts forward, back, left, or right when in angle mode, use the trim values to compensate."
				}


-- HARDWARE - FILTERS
data["filters"] = {}
data["filters"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/filters.png"
data["filters"]["TEXT"] = {
				"Typically you would not edit this page without checking your Blackbox logs!",
				"Gyro lowpass: Lowpass filters for the gyro signal. Typically left at default.",
				"Gyro notch filters: Use for filtering specific frequency ranges. Typically not needed in most helis.",
				"Dynamic Notch Filters: Automatically creates notch filters within the min and max frequency range."
				}

-- HARDWARE - GOVERNOR
data["governor"] = {}
data["governor"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/governor.png"
data["governor"]["TEXT"] = {
				"These paramers apply globally to the governor - regardless of the profile in use.",
				"Broadly - each parameter is simply a time value in seconds for each governor action."
				}

--[[
-- HARDWARE - ESC
data["esc"] = {
				"Adjust esc.. blah..",
				"Additional line"
				}
]]--

-- TOOLS COPY PROFILES
--[[
data["copy_profiles"] = {
				"Copy profiles",
				"Additional line"
				}
]]--


return {
	data = data,
}