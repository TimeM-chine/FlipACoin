local audioTextToSpeech: AudioTextToSpeech = Instance.new("AudioTextToSpeech")
audioTextToSpeech.Parent = workspace
audioTextToSpeech.Text = "Hello! Converting text into speech is fun!"
audioTextToSpeech.VoiceId = "1"

local deviceOutput = Instance.new("AudioDeviceOutput")
deviceOutput.Parent = workspace

local wire = Instance.new("Wire")
wire.Parent = workspace

wire.SourceInstance = audioTextToSpeech
wire.TargetInstance = deviceOutput

local count = 0

local connection = nil
connection = audioTextToSpeech.Ended:Connect(function()
	audioTextToSpeech.Text = "I can count to " .. count .. " because I am very smart"
	audioTextToSpeech.VoiceId = "2"
	audioTextToSpeech.TimePosition = 0
	audioTextToSpeech:Play()

	count += 1

	if count > 10 then
		connection:Disconnect()
	end
end)

audioTextToSpeech:Play()

local SpeakModule = {}

return SpeakModule
