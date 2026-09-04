-- @description Track Saturation Gradients
-- @author nightsharks
-- @version 1.0
-- @about
--   recolors tracks in a nice way that makes me happy

---------------------------------------------------------
-- Utility: RGB <-> HSL conversions
---------------------------------------------------------

function RGBtoHSL(r, g, b)
    r, g, b = r/255, g/255, b/255
    local maxc, minc = math.max(r,g,b), math.min(r,g,b)
    local h, s, l
    l = (maxc + minc) / 2

    if maxc == minc then
        h, s = 0, 0
    else
        local d = maxc - minc
        s = (l > 0.5) and (d / (2 - maxc - minc)) or (d / (maxc + minc))
        if maxc == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif maxc == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
    end
    return h, s, l
end

function HSLtoRGB(h, s, l)
    local function hue2rgb(p, q, t)
        if t < 0 then t = t + 1 end
        if t > 1 then t = t - 1 end
        if t < 1/6 then return p + (q - p) * 6 * t end
        if t < 1/2 then return q end
        if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
        return p
    end

    local r, g, b
    if s == 0 then
        r, g, b = l, l, l
    else
        local q = l < 0.5 and l * (1 + s) or l + s - l * s
        local p = 2 * l - q
        r = hue2rgb(p, q, h + 1/3)
        g = hue2rgb(p, q, h)
        b = hue2rgb(p, q, h - 1/3)
    end
    return math.floor(r*255), math.floor(g*255), math.floor(b*255)
end

-- Desaturate toward a darker gray (amount = 0 full color, 1 fully gray)
function DesaturateToDarkerGray(r, g, b, amount)
    local h, s, l = RGBtoHSL(r, g, b)
    local targetGrayLightness = 0.35 -- how dark the result gets
    local minSaturation = 0.18       -- minimum tint retained (0 = full gray, higher = more color)
    local topLightnessBoost = 0.08   -- extra lift right under the parent, fading out toward the bottom

    local lightnessAmount = amount * amount -- ease lightness in more slowly than saturation, so the top of a gradient stays lighter while still visibly losing saturation

    local newS = s * (1 - amount) + minSaturation * amount
    local newL = l + topLightnessBoost * (1 - lightnessAmount) + (targetGrayLightness - l) * lightnessAmount
    newL = math.min(newL, 1)

    return HSLtoRGB(h, newS, newL)
end

---------------------------------------------------------
-- Helper functions
---------------------------------------------------------

function hasChildren(track)
    if not track then return false end
    local numTracks = reaper.CountTracks(0)
    for i = 0, numTracks - 1 do
        local t = reaper.GetTrack(0, i)
        if reaper.GetParentTrack(t) == track then
            return true
        end
    end
    return false
end

---------------------------------------------------------
-- Core color application
---------------------------------------------------------

-- Gradients the DIRECT children of parentTrack based on baseColor, then
-- recurses into each child's own children using that child's freshly
-- computed color as the new seed -- so each folder's children form their
-- own gradient group, independent of how many descendants any one sibling
-- has, and nesting compounds the fade deeper going down.
-- Appends {track, color} pairs to `pending` for tracks whose color actually
-- needs to change; nothing is written to the project here.
function computeGradientForGroup(parentTrack, baseColor, pending)
    local childTracks = {}
    local numTracks = reaper.CountTracks(0)
    for i = 0, numTracks - 1 do
        local t = reaper.GetTrack(0, i)
        if reaper.GetParentTrack(t) == parentTrack then
            table.insert(childTracks, t)
        end
    end

    local count = #childTracks
    if count == 0 then return end

    local r, g, b = reaper.ColorFromNative(baseColor)
    local minStepAmount = 0.15 -- first child's minimum step away from the parent's exact color

    for i, childTrack in ipairs(childTracks) do
        local amount = minStepAmount + (i / count) * (1 - minStepAmount)
        local newR, newG, newB = DesaturateToDarkerGray(r, g, b, amount)
        local newColor = reaper.ColorToNative(newR, newG, newB)

        if reaper.GetTrackColor(childTrack) ~= newColor then
            table.insert(pending, {track = childTrack, color = newColor})
        end

        computeGradientForGroup(childTrack, newColor, pending)
    end
end

-- Scans every top-level parent track and collects every pending color write
-- across the whole project.
function computeAllPendingGradientWrites()
    local numTracks = reaper.CountTracks(0)
    local pending = {}

    for i = 0, numTracks - 1 do
        local track = reaper.GetTrack(0, i)
        if reaper.GetParentTrack(track) == nil and hasChildren(track) then
            computeGradientForGroup(track, reaper.GetTrackColor(track), pending)
        end
    end

    return pending
end

---------------------------------------------------------
-- Persistent, reactive main loop
---------------------------------------------------------

local lastStateChangeCount = -1

function loop()
    local stateChangeCount = reaper.GetProjectStateChangeCount(0)
    if stateChangeCount ~= lastStateChangeCount then
        lastStateChangeCount = stateChangeCount

        local pending = computeAllPendingGradientWrites()
        if #pending > 0 then
            for _, write in ipairs(pending) do
                reaper.SetTrackColor(write.track, write.color)
            end
        end
    end

    reaper.defer(loop)
end

---------------------------------------------------------
-- Toggle-action scaffolding: shows this always-on script as on/off in the
-- toolbar and action list, and lets re-running the same action stop it
-- (REAPER terminates the prior deferred instance automatically).
---------------------------------------------------------

local _, _, sectionID, cmdID = reaper.get_action_context()

reaper.atexit(function()
    reaper.SetToggleCommandState(sectionID, cmdID, 0)
    reaper.RefreshToolbar2(sectionID, cmdID)
end)

reaper.SetToggleCommandState(sectionID, cmdID, 1)
reaper.RefreshToolbar2(sectionID, cmdID)

reaper.defer(loop)
