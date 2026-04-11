local SitePresets = {}

SitePresets.Lighting = {
    spiderMountain = {
        Ambient = Color3.fromRGB(100, 100, 100),
        Brightness = 0,
        ColorShift_Bottom = Color3.fromRGB(255, 255, 255),
        ColorShift_Top = Color3.fromRGB(255, 255, 255),
        EnvironmentDiffuseScale = 1,
        EnvironmentSpecularScale = 1,
        GlobalShadows = true,
        OutdoorAmbient = Color3.fromRGB(100, 100, 100),
        ShadowSoftness = 0.25,
        ClockTime = 6.5,
        GeographicLatitude = 0,
        ExposureCompensation = 0,
    },
    mainLand = {
        Ambient = Color3.fromRGB(120, 127, 97),
        Brightness = 3,
        ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
        ColorShift_Top = Color3.fromRGB(125, 112, 41),
        EnvironmentDiffuseScale = 1,
        EnvironmentSpecularScale = 1,
        GlobalShadows = true,
        OutdoorAmbient = Color3.fromRGB(0, 0, 0),
        ShadowSoftness = 0.15,
        ClockTime = 11,
        GeographicLatitude = 50.931,
        ExposureCompensation = 0.3,
    },
}


return SitePresets