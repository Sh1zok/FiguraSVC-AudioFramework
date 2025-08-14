--[[
    Name: Voice Chat Framework v1.0
    Description: FiguraSVC v2.0 framework
    Author: Sh1zok
    Credits: https://discordapp.com/users/416278117209079809
]]--

VCFramework = {} -- Framework variable
VCFramework.hostVoiceVolume = 0 -- Decimal number from 0(queit) to INF, but 1 is already loud. Good for calculations and statistics
VCFramework.smoothHostVoiceVolume = 0 -- Decimal number from 0(queit) to INF, but 1 is already loud. Good for voice visualizators.
VCFramework.rawAudioStream = {} -- List of 960 values​(indices from 0 to 959)
for index = 0, 959 do VCFramework.rawAudioStream[index] = 0 end -- Filling the list with zeros to prevent errors
VCFramework.isMicrophoneActive = false -- True if the microphone is active

-- Checking dependencies:
-- If returns 0 | Everything must work correctly
-- If returns 1 | SimpleVoiceChat and FiguraSVC are not installed
-- If returns 2 | SimpleVoiceChat is not installed
-- If returns 3 | FiguraSVC is not installed
function VCFramework.checkDependencies()
    if not client:isModLoaded("voicechat") and not client:isModLoaded("figurasvc") then return 1 end
    if not client:isModLoaded("voicechat") then return 2 end
    if not client:isModLoaded("figurasvc") then return 3 end
    return 0
end

---In fact, the voice volume is simply the arithmetic mean between all the indices of the raw audio
function VCFramework.getVoiceVolume(rawAudio)
    local voiceVolume = 0

    for index = 0, #rawAudio do
        voiceVolume = voiceVolume + math.abs(rawAudio[index])
    end

    return voiceVolume / #rawAudio
end

-- Set the voice volume value for non-hosts
function pings.setCurrentHostVoiceVolume(value)
    VCFramework.hostVoiceVolume = value
end

events.tick:register(function()
    -- Saving old correct voice volume
    local oldHostVoiceVolume = VCFramework.hostVoiceVolume

    -- Сalculating new correct voice volume
    local newHostVoiceVolume = VCFramework.getVoiceVolume(VCFramework.rawAudioStream) / 5250
    if newHostVoiceVolume <= 0.01 then newHostVoiceVolume = 0 end -- Сutting off too small values

    -- Determining microphone state
    VCFramework.isMicrophoneActive = newHostVoiceVolume ~= oldHostVoiceVolume

    -- Setting the voice volume for non-hosts(even for those who do not have FiguraSVC installed)
    if VCFramework.isMicrophoneActive then pings.setCurrentHostVoiceVolume(newHostVoiceVolume) end

    -- Reset variables if microphone in not active
    if not VCFramework.isMicrophoneActive and oldHostVoiceVolume ~= 0 then pings.setCurrentHostVoiceVolume(0) end
end, "VCFramework")

events.RENDER:register(function()
    -- Сalculating the smooth voice volume every render frame
    VCFramework.smoothHostVoiceVolume = math.lerp(VCFramework.smoothHostVoiceVolume, VCFramework.hostVoiceVolume, 1) -- TO-DO: REPLACE THIS FUCKING MAGIC NUMBER
end, "VCFramework")

if VCFramework.checkDependencies() ~= 0 then return end

-- Reading raw audio stream on host side
events.host_microphone:register(function(audio)
    VCFramework.rawAudioStream = audio
end, "VCFramework:ReadingRawAudioStream")

-- Reading host raw audio stream on non-host side
events.microphone:register(function(playername, audio)
    if not player:isLoaded() then return end
    if playername ~= player:getName() then return end

    VCFramework.rawAudioStream = audio
end, "VCFramework:ReadingHostRawAudioStream")
