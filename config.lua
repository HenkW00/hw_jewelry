Config = {}
Config.Lang = 'en' -- You can add/change in locales.lua

----------------
----SETTINGS----
----------------
Config.Mode = 'debug' -- Possible values: 'active', 'test', 'debug'
Config.checkForUpdates = true -- Recommended to leave on true
Config.Webhook = "https://discord.com/api/webhooks/1218962573156814898/OWs4X7x4nTiCZCnz7Vth6YmD7puo54K2MIsxCsrpaAM9n-psdrhGGLDjrnDF1GFldYCv" -- For discord logging :)

-------------
----UTILS----
-------------
Config.CopsRequired = 0 -- Required cops needed for the robbery to start
Config.PoliceJobs = {'police', 'sheriff'} -- Jobs that will be known as police
Config.Weapons = {'WEAPON_PISTOL', 'WEAPON_ASSAULTRIFLE'} -- Weapons for starting robbery

-------------
---ROBBERY---
-------------
Config.RobberyDuration = {active = 900000, test = 60000, debug = 1800000} -- Duration in milliseconds
Config.RewardItems = {'diamond', 'ring', 'goldbar', 'rolex'} -- Reward items for collecting
Config.Payout = 50000 -- Payout that player will receive after robbery duration
Config.Time = 10 -- Time in minutes for the robbery

--------------
---LOCATION---
--------------
Config.StartLocation = {x = -630.79, y = -229.25, z = 38.06} -- Location where player needs to start robbery
Config.RobPoints = { -- Collecting points for robbery
    {x = -626.16, y = -238.13, z = 38.06},
    {x = -626.33, y = -234.97, z = 38.06},
    {x = -627.43, y = -233.54, z = 38.06},
    {x = -624.67, y = -230.89, z = 38.06},
    {x = -622.96, y = -233.1, z = 38.06},
    {x = -620.14, y = -233.44, z = 38.06},
    {x = -619.47, y = -230.67, z = 38.06},
    {x = -621.18, y = -228.4, z = 38.06},
    {x = -617.86, y = -230.11, z = 38.06},
    {x = -620.12, y = -227.1, z = 38.06},
    {x = -624.03, y = -228.19, z = 38.06},
}
