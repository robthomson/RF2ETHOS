data = {}

-- PIDS
data["pids"] = {}
data["pids"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/pids.png"
data["pids"]["TEXT"] = {
				"Increase D, P, I in order until each wobbles, then back off.",
				"Set F for a good response in full stick flips and rolls.",
				"If necessary, tweak P:D ratio to set response damping to your liking.",
				"Increase O until wobbles occur when jabbing elevator at full collective, back off a bit.", 
				"Increase B if you want sharper response.",
				}

				

			
-- FLIGHT TUNING RATES
data["rates_1"] = {}
data["rates_1"]["table"] = {}	
data["rates_1"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/rates.png"
data["rates_1"]["TEXT"] = {
				"default - we keep this to make button appear but for rates",
				"we will use the sub keys below"
				}			
-- RATE TABLE NONE
data["rates_1"]["table"][0] = {
				"All values are set to zero because no RATE TABLE is in use.",
				}

-- RATE TABLE BETAFLIGHT
data["rates_1"]["table"][1] = {
				"RC Rate - determines how quickly the heli rotates at full deflection",
				"SuperRate -  increases both max angular velocity and sensitivity around the center stick.",
				"RC Expo - reduces sensitivity near the stick's center where fine controls are needed",
				
				}
				
-- RATE TABLE RACEFLIGHT				
data["rates_1"]["table"][2] = {
				"Rate - defines the heli's rotation speed at full stick deflection. The value entered represents the exact maximum rotational velocity.",
				"Acro+ - allows you to exceed the max rate, based on the speed at which you moved your stick. For simplicity keep it at zero!",
				"Expo - reduces sensitivity near the stick's center where fine controls are needed",
				}	

-- RATE TABLE KISS				
data["rates_1"]["table"][3] = {
				"RC Rate - determines how quickly the heli rotates at full deflection",
				"Rate -  increases both max angular velocity and sensitivity around the center stick.",
				"RC Curve - reduces sensitivity near the stick's center where fine controls are needed",
				}	

-- RATE TABLE ACTUAL				
data["rates_1"]["table"][4] = {
				"Center Sensitivity - A lower value offers finer, smoother control, while a higher value results in a more reactive heli to stick movement.",
				"Max Rate - defines the heli's rotation speed at full stick deflection. The value entered represents the exact maximum rotational velocity. For example, entering 300 means your heli will attempt to rotate at 300 degrees/sec at full stick.",
				"Expo - flattens the curve between center stick and full stick. To achieve a more linear rate, keep Expo low. For a broader center stick region with finer control, increase Expo. "
				}
				
-- RATE TABLE QUICK				
data["rates_1"]["table"][5] = {
				"RC Rate - determines how quickly the heli rotates at full deflection",
				"Max Rate - defines the heli's rotation speed at full stick deflection. The value entered represents the exact maximum rotational velocity. For example, entering 300 means your heli will attempt to rotate at 300 degrees/sec at full stick.",
				"Expo - flattens the curve between center stick and full stick. To achieve a more linear rate, keep Expo low. For a broader center stick region with finer control, increase Expo. "
				}

-- FLIGHT TUNING - MAIN ROTOR
data["profile_4"] = {}
data["profile_4"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/mainrotor.png"
data["profile_4"]["TEXT"] = {
				"Collective Pitch Compensation - increasing this gain will compensate for the pitch back motion caused by tail drag when climbing.",
				"Cross Coupling Gain - removes roll wobble when only elevator is applied",
				"Cross Coupling Ratio - amount of compensation (pitch vs roll) to apply",
				"Cross Coupling Feq. Limit - Frequency limit for the compensation, higher value will make the compensation action faster.",
				}


-- FLIGHT TUNING - TAIL ROTOR
data["profile_2"] = {}
data["profile_2"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/tailrotor.png"
data["profile_2"]["TEXT"] = {
				"Yaw Stop Gain -  Higher stop gain will make the tail stop more aggressively, but may cause oscillations if too high.",
				"Precomp Cutoff -  The frequency at which the precomp will no longer be applied.",
				"Cyclic FF Gain - Tail precompensation for cyclic inputs.",	
				"Collective FF Gain - Tail precompensation for collective inputs.",	
				"Collective Impulse FF - Gain value for collective impulse mixed into yaw",		
				}						

-- FLIGHT TUNING - GOVERNOR
data["profile_governor"] = {}
data["profile_governor"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/governor.png"
data["profile_governor"]["TEXT"] = {
				"Full Headspeed -  Headspeed target when at 100% throttle input.",
				"PID Master Gain - How hard the governor works to hold the RPM ",
				"Gains - Fine tuning of the governor PID loop",
				"Precomp - Determines how much yaw is mixed into the feedforward loop",
				"Max throtle - The maximum throttle % the governor is allowed to use."
				}	

-- ADVANCED TUNING - PID CONTROLLER
data["profile_1"] = {}
data["profile_1"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/pidcontroller.png"
data["profile_1"]["TEXT"] = {
				"Error decay ground - prevents heli tipping over when on ground",
				"Error limit - hard limit for the angle error in the PID loop",
				"Offset limit - hard limit high speed integral. O term will never go above these limits.",					
				"Error rotation - allow errors to be shared betweeen all axis",	
				"I-term relax - limit accumulation I-term during fast movements.  This helps reduce bounceback end ends of flips and rolls.",					
				}	

-- ADVANCED TUNING - PID BANDWIDTH
data["profile_3"] = {}
data["profile_3"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/pidbandwidth.png"
data["profile_3"]["TEXT"] = {
				"PID Bandwidth - overall bandwith in HZ used by the PID loop",
				"D-term cutoff - D-term cutoff frequency in HZ",				
				"B-term cutoff - B-term cutoff frequency in HZ",
				}	

-- ADVANCED TUNING - AUTO LEVEL
data["profile_5"] = {}
data["profile_5"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/autolevel.png"
data["profile_5"]["TEXT"] = {
				"Acro Trainer - how agressively the heli tilts back to level when flying in Acro Trainer Mode",
				"Angle Mode - how agressively the heli tilts back to level when flying  in Angle Mode",
				"Horizon Mode - how agressively the heli tilts back to level when flying  in Horizon Mode",				
				}	

-- ADVANCED TUNING - RESCUE
data["profile_rescue"] = {}
data["profile_rescue"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/rescue.png"
data["profile_rescue"]["TEXT"] = {
				"Flip to upright - flip heli the right way up if rescue enabled.",
				"Pull-up - how much collective and for how long to arrest the fall",
				"Climb - how much collective to maintain a steady climb - and how long",
				"Hover - how much collective to maintain a steady hover",
				"Flip - how long to wait before aborting because the flip did not work",
				"Gains - how hard to fight to keep heli level when engaging rescue mode"			
				}	

-- ADVANCED TUNING - RATES
data["rates_2"] = {}
data["rates_2"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/rates.png"
data["rates_2"]["TEXT"] = {
				"Rates type - choose the rate table you prefer flying with",
				"Dynamics - global values applied regardless of rate table. Typically left on defaults"
				}	

-- HARDWARE - SERVO
data["servos"] = {}
data["servos"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/servos.png"
data["servos"]["TEXT"] = {
				"Servo - select the servo you would like to edit",
				"Center - adjust the center position of the servo",
				"Minimum/Maximum - adjust the end point of the servo.",
				"Scale - adjust the amount the servo moves for a given input",
				"Rate - the frequency the servo runs best at - check with manufacturer",
				"Speed - the speed the servo moves"
				}	

-- HARDWARE - MIXER
data["mixer"] = {}
data["mixer"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/mixer.png"
data["mixer"]["TEXT"] = {
				"Swashplate - adust swash plate geometry, phase angles and limits.",
				"Link trims - use to trim out small leveling issues in your swash plate.  Ideally use mechanical means for best effect.",				
				"Motorised tail - if using a motorised tail, use this to tune set the minimum idle speed and to trim out any yaw drift."
				}	

-- HARDWARE - ACCELEROMETER
data["accelerometer"] = {}
data["accelerometer"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/board-alignment.png"
data["accelerometer"]["TEXT"] = {
				"If your helicopter drifts forward back or left right when in angle mode, use the trim values to compensate.",			
				}	


-- HARDWARE - FILTERS
data["filters"] = {}
data["filters"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/filters.png"
data["filters"]["TEXT"] = {
				"Lowpass filters - adjust the min and max frequencies in which the gyro will ignore inputs.  Typically you would not edit these without checking your black box logs.",
				"Gyro Notches - create a frequency range within the lowpass range; in which the gyro noise will be ignored. Typically you would not edit these without checking your black box logs.",				
				"Dynamic Notches - set the number of dynamic notches to use."
				}	

-- HARDWARE - GOVERNOR
data["governor"] = {}
data["governor"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/governor.png"
data["governor"]["TEXT"] = {
				"These paramers apply globally to the governor - regardless of the profile in use.",
				"Broadly - each parameter is simply a time value in seconds for each governor action",
				}	

--[[
-- HARDWARE - ESC
data["esc"] = {
				"Adjust esc.. blah..",
				"Additional line",				
				}					
]]--

-- TOOLS COPY PROFILES
--[[
data["copy_profiles"] = {
				"Copy profiles",
				"Additional line",				
				}					
]]--


return {
    data = data,
}