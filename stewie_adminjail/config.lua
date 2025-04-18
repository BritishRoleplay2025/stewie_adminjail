Config = {}

Config.Command = 'adminjail'
Config.AdminLicenses = {
    'license:FIVEMLICENCEEHERE',,
    'license:anotherAdminLicenseHere',
    'license:thirdAdminLicenseHere'
}

Config.EscapeAttempt = {
    penalty = 5, -- In minutes
    message = 'Time is added to your sentence For trying to escape Admin Jail'
}
-- POLYZONE 
Config.JailZone = {
    points = {
        vector2(3057.8, -4826.37),
        vector2(2991.62, -4605.99),
        vector2(2991.62, -4605.99),
        vector2(2999.78, -4513.56),
        vector2(3020.38, -4508.06),
        vector2(3049.91, -4586.47),
        vector2(3073.2, -4592.7),
        vector2(3130.08, -4800.5)
    },
    debugPoly = false    
}

Config.Locations = {
    jail = vector3(3066.8, -4738.24, 15.26), -- put teleport back same location
    release = vector3(219.11, -799.94, 30.74),
    teleportBack = vector3(3066.8, -4738.24, 15.26) -- For escape attempts
}
