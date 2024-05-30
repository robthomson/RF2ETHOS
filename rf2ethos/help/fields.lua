return {
--configurationFeatures = { t="<strong>Note:</strong> Not all features are supported by all flight controllers. If you enable a specific feature, and it is disabled after you hit 'Save and Reboot', it means that this feature is not supported." },
--configurationSerialPorts = { t="Select function and speed for each serial port (UART)." },
--configurationRSSI = { t="RSSI is a measurement of signal strength and is very handy so you know when your aircraft is going out of range or if it is suffering RF interference." },
--configurationBoardAlignment = { t="Arbitrary board rotation allows mounting the FC sideways / upside down / rotated etc. When using external sensors, use the sensor alignments to define sensor position independent from the board orientation." },
--configurationAccelTrims = { t="The Accelerometer Trims provide fine tuning to the horizon level, which can be used to decrease drift while in stabilized modes, such as Angle or Rescue." },
--configurationBeeper = { t="Enable or disable when to sound the Buzzer." },
--configurationGPSGalileo = { t="When enabled, this removes the QZSS system (Japanese) and replaces it for the Galileo system (European)." },
--configurationGPSHomeOnce = { t="When enabled, only the first arm after the battery is connected will be used as home point. If not enabled, every time the quad is armed, the home point will be updated." },


--receiverBars = { t="Shows the raw RC channels from the receiver exactly the way they are received. Please select the channel map, i.e. the corrent function for each RC channel." },


--
-- servos.lua
--
servoMid = { t="Servo center position pulse width." },
servoMin = { t="Servo negative travel limit." },
servoMax = { t="Servo positive travel limit." },
servoScaleNeg = { t="Servo negative scaling." },
servoScalePos = { t="Servo positive scaling." },
servoRate = { t="Servo PWM rate." },
servoSpeed = { t="Servo motion speed in milliseconds." },
--servoReverse = { t="Servo reverse." },
--servoGeometryCorrection = { t="Servo geometry correction." },
--servoOverride = { t="Servo override for adjusting center and limits." },


--
-- mixer.lua
--
mixerSwashTrim = { t="Swash trim to level the swash plate when using fixed links." },
mixerTTAPrecomp = { t="Mixer precomp for 0 yaw." }, -- ??? this is not named well in any of the RF LUAs
mixerCollectiveGeoCorrection = { t="Adjust if there is too much negative collective or too much positive collective." },
mixerTotalPitchLimit = { t="Maximum amount of combined cyclic and collective blade pitch." },
mixerSwashPhase = { t="Phase offset for the swashplate controls." },
mixerTailMotorIdle = { t="Minimum throttle signal sent to the tail motor. This should be set just high enough that the motor does not stop." },
mixerTailMotorCenterTrim = { t="Set tail motor throttle value for zero yaw command." },

--mixerMainRotorDirection = { t="Main rotor rotation direction, look down from the above." },
--mixerSwashType = { t="Swash type." },
--mixerElevatorDirection = { t="Mixer pitch/elevator direction." },
--mixerAileronDirection = { t="Mixer roll/aileron direction." },
--mixerCollectiveDirection = { t="Mixer collective direction." },
--mixerCyclicCalibration = { t="Adjust the cyclic gain to match the mechanical gain in the head design." },
--mixerCollectiveCalibration = { t="Adjust the collective gain to match the mechanical gain in the head design." },
--mixerCyclicLimit = { t="Maximum amount of cyclic blade pitch." },
--mixerCollectiveLimit = { t="Maximum amount of collective blade pitch." },
--mixerSwashRing = { t="Swashring limit for controlling combined roll and pitch." },
--mixerTailRotorMode = { t="Tail rotor mode." },
--mixerTailRotorDirection = { t="Mixer yaw direction." },
--mixerTailRotorCalibration = { t="Adjust the yaw gain to match the mechanical gain." },
--mixerTailRotorMinYaw = { t="Blade angle limit for clockwise yaw." },
--mixerTailRotorMaxYaw = { t="Blade angle limit for counter-clockwise yaw." },
--mixerTailMotorMinYaw = { t="Motor output limit for clockwise yaw." },
--mixerTailMotorMaxYaw = { t="Motor output limit for counter-clockwise yaw." },
--mixerTailRotorCenterTrim = { t="Tail rotor trim for zero yaw command (0 blade pitch)." },
--mixerInputChannels = { t="." },
--mixerOverride = { t="This feature is used for setting up the rotor and is part of the <strong>Mixer Calibration</strong> process. When the bypass enable is active the mixer can be commanded to the requested positions directly." },


--
-- motors
--
--motorsEscProtocol = { t="Select your ESC protocol.<br>Traditional helicopter ESCs use PWM. Drone ESCs may use other protocols, like DSHOT. <br>Make sure the protocol is supported by your ESC." },
--motorsEscTelemetryProtocol = { t="Select your ESC Telemetry protocol. The telemetry is transmitted via a separate wire from the ESC." },
--motorsUnsyncedPwm = { t="ESC PWM is running unsyncronised, separate from the PID loop, at the specified frequency." },
--motorsUnsyncedPWMFreq = { t="ESC PWM update frequency in Hz. This is how often the throttle value is sent to the ESC. Usually between 50Hz and 250Hz. Most modern ESCs work fine with 250Hz." },
--motorsDshotBidir = { t="The ESC RPM is sent back to the FC with DShot. <br>Note: Requires a compatible ESC, like BLHeli32, Bluejay or AM32." },
--motorsRPMSensor = { t="Use the RPM Sensor input for motor RPM. You can connect an RPM signal from the ESC, or from an external RPM Sensor dongle." },
--motorsMainRotorGearRatio = { t="Gear ratio between the motor and the main rotor.<br>Use <span class='value'>motor pinion</span> : <span class='value'>main gear</span> tooth count." },
--motorsTailRotorGearRatio = { t="Gear ratio between the tail rotor and the main rotor. Use <span class='value'>tail gear</span> : <span class='value'>autorotation gear</span> tooth count for Torque Tube, or <span class='value'>tail pulley</span> : <span class='value'>front pulley</span> for a belt tail. For a direct drive tail, use <span class='value'>1</span> : <span class='value'>1</span>." },
--motorsThrottleMinimum = { t="This is the PWM value that is sent to the ESCs at zero throttle (when the craft is armed)." },
--motorsThrottleMaximum = { t="This is the PWM value that is sent to the ESCs at full throttle (when the craft is armed)." },
--motorsThrottleMinimumCommand = { t="This is the PWM value that is sent to the ESCs when the craft is disarmed. Set this to a value that allows the ESC to arm (typically 1000)." },


--
-- governor.lua
--
--govMode = { t="<strong>OFF:</strong> Govenor is disabled and the throttle from the Tx is passed through to the ESC.<br><br><strong>PASSTHROUGH:</strong> Throttle passthrough from the Tx, with slow spoolup and autorotation control.<br><br><strong>STANDARD:</strong> Motor speed is controlled by the FC. Equivalent to a typical ESC Governor.<br><br><strong>MODE1:</strong> Like STANDARD but with Collective and Cyclic Precompensation (i.e. collective changes are proactively changing the throttle, just like a throttle curve in the Tx).<br><br><strong>MODE2:</strong> Like MODE1, but with proactive battery voltage sag compensation. Requires fast voltage measurement." },
govHandoverThrottle = { t="Governor activates above this %. Below this the input throttle is passed to the ESC." },
govStartupTime = { t="Time constant for slow startup, in seconds, measuring the time from zero to full headspeed." },
govSpoolupTime = { t="Time constant for slow spoolup, in seconds, measuring the time from zero to full headspeed." },
govTrackingTime = { t="Time constant for headspeed changes, in seconds, measuring the time from zero to full headspeed." },
govRecoveryTime = { t="Time constant for recovery spoolup, in seconds, measuring the time from zero to full headspeed." },

govAutoBailoutTime = { t="Time constant for autorotation bailout spoolup, in seconds, measuring the time from zero to full headspeed." },

govAutoTimeout = { t="Timeout for ending autorotation and moving to normal idle and spoolup." },

govAutoMinEntryTime = { t="Minimum time with governor active before autorotation can be engaged." },

govZeroThrottleTimeout = { t="Timeout for missing throttle signal before governor shutoff. If signal returns within timeout, governor will perform recovery spoolup." },
govLostHeadspeedTimeout = { t="Timeout for missing RPM before spooling down. If RPM returns within timeout, the governor will perform recovery spoolup." },
govHeadspeedFilterHz = { t="Cutoff for the headspeed lowpass filter." },
govVoltageFilterHz = { t="Cutoff for the battery voltage lowpass filter." },
govTTABandwidth = { t="Cutoff for the TTA lowpass filter." },
govTTAPrecomp = { t="Cutoff for the cyclic/collective collective precomp lowpass filter." },


--
-- profile_governor.lua
--
govHeadspeed = { t="Target headspeed for the current profile." },
govMasterGain = { t="Master PID loop gain." },
govPGain = { t="PID loop P-term gain." },
govIGain = { t="PID loop I-term gain." },
govDGain = { t="PID loop D-term gain." },
govFGain = { t="Feedforward gain." },

govYawPrecomp = { t="Yaw precompensation weight - how much yaw is mixed into the feedforward." },
govCyclicPrecomp = { t="Cyclic precompensation weight - how much cyclic is mixed into the feedforward." },
govCollectivePrecomp = { t="Collective precompensation weight - how much collective is mixed into the feedfoward." },

govTTAGain = { t="TTA gain applied to increase headspeed to control the tail in the negative direction (e.g. motorised tail less than idle speed)." },
govTTALimit = { t="TTA max headspeed increase over full headspeed." },

govMaxThrottle = { t="Maximum output throttle the governor is allowed to use." },

--govTTAFilterHz = { t="Cutoff for the TTA lowpass filter." },
--govFFFilterHz = { t="Cutoff for the cyclic/collective precompensation lowpass filter." },


--
-- accelerometer.lua
--
accelerometerTrim = { t = "Use to trim if the heli drifts in one of the stabilized modes (angle, horizon, etc.)." },


--
-- profile.lua
--
profilesErrorDecayGround = { t="Bleeds off the current controller error when the craft is not airborne to stop the craft tipping over." },
profilesErrorDecayGroundCyclicTime = { t="Time constant for bleeding off cyclic I-term. Higher will stabilize hover, lower will drift." },
profilesErrorDecayGroundCyclicLimit = { t="Maximum bleed-off speed for cyclic I-term." },
profilesErrorDecayGroundYawTime = { t="Time constant for bleeding off yaw I-term." },
profilesErrorDecayGroundYawLimit = { t="Maximum bleed-off speed for yaw I-term." },

profilesErrorLimit = { t="Hard limit for the angle error in the PID loop. The absolute error and thus the I-term will never go above these limits." },

profilesErrorHSIOffsetLimit = { t="Hard limit for the High Speed Integral offset angle in the PID loop. The O-term will never go over these limits." },

profilesErrorRotation = { t="Rotates the current roll and pitch error terms around taw when the craft rotates. This is sometimes called Piro Compensation." },

profilesItermRelaxType = { t="Choose the axes in which this is active. RP: Roll, Pitch. RPY: Roll, Pitch, Yaw." },

profilesItermRelax = { t="Helps reduce bounce back after fast stick movements. Can cause inconsistency in small stick movements if too low." },

profilesYawStopGainCW = { t="Stop gain (PD) for clockwise rotation." },
profilesYawStopGainCCW = { t="Stop gain (PD) for counter-clockwise rotation." },

profilesYawPrecompCutoff = { t="Frequency limit for all yaw precompensation actions." },
profilesYawFFCyclicGain = { t="Cyclic feedforward mixed into yaw (cyclic-to-yaw precomp)." },
profilesYawFFCollectiveGain = { t="Collective feedforward mixed into yaw (collective-to-yaw precomp)." },

profilesYawFFImpulseGain = { t="An extra boost of yaw precomp on collective input." },
profilesyawFFImpulseDecay = { t="Decay time for the extra yaw precomp on collective input." },

profilesPitchFFCollective = { t="Increasing will compensate for the pitching up motion caused by tail drag when climbing." },

profilesPIDBandwidth = { t="PID loop overall bandwidth in Hz." },
profilesPIDBandwidthDtermCutoff = { t="D-term cutoff in Hz." },
profilesPIDBandwidthBtermCutoff = { t="B-term cutoff in Hz." },

profilesCyclicCrossCouplingGain = { t="Amount of compensation applied for pitch-to-roll decoupling." },
profilesCyclicCrossCouplingRatio = { t="Amount of roll-to-pitch compensation needed, vs. pitch-to-roll." },
profilesCyclicCrossCouplingCutoff = { t="Frequency limit for the compensation. Higher value will make the compensation action faster." },

profilesAcroTrainerGain = { t="Determines how aggressively the helicopter tilts back to the maximum angle (if exceeded) while in Acro Trainer Mode." },
profilesAcroTrainerLimit = { t="Limit the maximum angle the helicopter will pitch/roll to while in Acro Trainer Mode." },

profilesAngleModeGain = { t="Determines how aggressively the helicopter tilts back to level while in Angle Mode." },
profilesAngleModeLimit = { t="Limit the maximum angle the helicopter will pitch/roll to while in Angle mode." },

profilesHorizonModeGain = { t="Determines how aggressively the helicopter tilts back to level while in Horizon Mode." },


--
-- pids.lua
--

profilesProportional = { t="How tightly the system tracks the desired setpoint." },
profilesIntegral = { t="How tightly the system holds it's position." },
profilesHSI = { t="Used to prevent the craft from pitching up when flying at speed." },
profilesDerivative = { t="Strength of dampening to any motion on the system, including external influences. Also reduces overshoot." },
profilesFeedforward = { t="Helps push P-term based on stick input. Increasing will make response more sharp, but can cause overshoot." },
profilesBoost = { t="Additional boost on the feedforward to make the heli react more to quick stick movements." },

--profilesYawCenterOffset = { t="Center Offset for tail motor or servo." },
--profilesPitchFFCollectiveGain = { t="Amount of collective mixed into the elevator control." },
--profilesCyclicCrossCoupling = { t="Cyclic Cross-Coupling compensation removes the aileron (roll) wobble when only elevator is applied." },


--
-- rates.lua
--
profilesRatesDynamicsTime = { t="Increase or decrease the response time of the rate to smooth heli movements." },
profilesRatesDynamicsAcc = { t="Maximum acceleration of the craft in response to a stick movement." },


--
-- profile_rescue.lua
--
profilesRescueFlipMode = { t="If rescue is activated while inverted, flip to upright - or remain inverted." },

profilesRescuePullupCollective = { t="Collective value for pull-up climb." },
profilesRescuePullupTime = { t="When rescue is activated, helicopter will apply pull-up collective for this time period before moving to flip or climb stage." },

profilesRescueClimbCollective = { t="Collective value for rescue climb." },
profilesRescueClimbTime = { t="Length of time the climb collective is applied before switching to hover." },

profilesRescueHoverCollective = { t="Collective value for hover." },

profilesRescueFlipTime = { t="If the helicopter is in rescue and is trying to flip to upright and does not within this time, rescue will be aborted." },
profilesRescueExitTime = { t="This limits rapid application of negative collective if the helicopter has rolled during rescue." },

profilesRescueLevelGain = { t="Determine how agressively the heli levels during rescue." },
profilesRescueFlipGain = { t="Determine how agressively the heli flips during inverted rescue." },

profilesRescueMaxRate = { t="Limit rescue roll/pitch rate. Larger helicopters may need slower rotation rates." },

profilesRescueMaxAccel = { t="Limit how fast the helicopter accelerates into a roll/pitch. Larger helicopters may need slower acceleration." },

--profilesRescueHoverAltitude = { t="Hovering altitude after rescue action." },
--profilesRescueAltitudePGain = { t="P-gain for altitude control." },
--profilesRescueAltitudeIGain = { t="I-gain for altitude control." },
--profilesRescueAltitudeDGain = { t="D-gain for altitude control (vario)." },
--profilesRescueMaxCollective = { t="Maximum Collective to apply for altitude control." },


--
-- filters.lua
--
gyroLowpassFilterCutoff = { t="Lowpass filter cutoff frequency in Hz." },
gyroLowpassFilterDynamicCutoff = { t="Dynamic filter min/max cutoff in Hz." },
gyroLowpassFilterCenter = { t="Center frequency to which the notch is applied." },
gyroDynamicNotchCount = { t="Without RPM filters, 4-6 is recommended. With the RPM filters, 2-4 is recommended." },
gyroDynamicNotchQ = { t="Values between 2 and 4 recommended. Lower than 2 will increase filter delay and may degrade flight performance." },
gyroDynamicNotchMinHz = { t="Lowest incoming noise frequency to be filtered. Should be slightly below lowest main rotor fundamental, but no less than 20Hz." },
gyroDynamicNotchMaxHz = { t="Highest incoming noise frequency to be filtered. Should be 10-20% above highest tail rotor fundamental." },

--gyroRpmFilterMainRotorMinRPM = { t="Minimum Main Rotor RPM accepted by the filters." },
--gyroRpmFilterTailRotorMinRPM = { t="Minimum Tail Rotor RPM accepted by the filters." },


--vtxFrequencyChannel = { t="If you enable this, the Configurator will let you select a frequency in place of the habitual band/channel. For this to work your VTX must support this feature." },
--vtxBand = { t="You can select here the band for your VTX." },
--vtxChannel = { t="You can select here the channel for your VTX." },
--vtxFrequency = { t="You can select here the frequency for your VTX if it is supported." },
--vtxPower = { t="This is the power selected for the VTX. It can be modified if the $t(vtxPitMode.message) or the $t(vtxLowPowerDisarm.message) is enabled." },
--vtxPitMode = { t="When enabled, the VTX enters in a very low power mode to let the quad be on at the bench without disturbing other pilots. Usually the range of this mode is less than 5m.<br /><br />NOTE: Some protocols, like SmartAudio, can't enable Pit Mode via software after power-up." },
--vtxPitModeFrequency = { t="Frequency at which the Pit Mode changes when enabled." },
--vtxLowPowerDisarm = { t="When enabled, the VTX uses the lowest available power when disarmed (except if a failsafe has occurred)." },
--vtxTablePowerLevels = { t="This defines the number of power levels supported by your VTX." },

--configurationPidProcessDenom = { t="The maximum frequency for the PID loop is limited by the CPU processing power. The Realtime Load should not exceed 70% with the selected loop speed." },
--configurationGyroUse32kHz = { t="32 kHz gyro update frequency is only possible if the gyro chip supports it (currently MPU6500, MPU9250, and ICM20xxx if connected over SPI). If in doubt, consult the specification for your board." },
--configurationAccHardware = { t="Enables the Accelerometer. This is required for all stabilisation modes: Angle, Horizon, Acro Trainer and Rescue." },
--configurationBaroHardware = { t="Enables the Barometer (if available). Altitude is currently not used in Flight Control. It is informative only, available via the Telemetry." },
--configurationMagHardware = { t="Enables the Magnetometer (if available). Compass direction is currently not used in Flight Control. It is informative only, available via the Telemetry." },

--blackboxMode = { t="<strong>OFF:</strong> Disable logging.<br><br><strong>NORMAL:</strong> Enable logging when both ARMED and BLACKBOX switch are active.<br><br><strong>ARMED:</strong> Enable logging when ARMED.<br><br><strong>SWITCH:</strong> Enable logging when BLACKBOX switch is active." },
--blackboxDevice = { t="<strong>No Logging:</strong> Disable logging.<br><br><strong>Onboard Flash:</strong> Log to the onboard flash chip (if available).<br><br><strong>SD Card:</strong> Log to the onboard SD card (if available).<br><br><strong>Serial Port:</strong> Log to an external logger device (e.g OpenLager) connected to a serial port. The serial port must to be configured to 'Blackbox Logging' on the <strong>Configuration</strong> tab." },
--blackboxRateOfLogging = { t="The log data is saved to the log device with this rate. For logging to an external device, lower speed may be required." },
--blackboxDebugMode = { t="Choose what <i>extra</i> data is being logged. If enabled, eight extra debug items are added to the Blackbox Log." },
--blackboxDebugAxis = { t="Choose which <i>axis</i> is being debugged. Applies to some of the debug modes." },
}