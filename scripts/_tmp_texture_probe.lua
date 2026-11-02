local frames = 0
local asyncDone = false
local texture = nil

local function reportImage(tag, image)
    print("[texture-probe] " .. tag .. " image=" .. tostring(image ~= nil))
    if not image then
        return
    end
    local ok, info = pcall(function()
        return tostring(image:GetWidth()) .. "x" .. tostring(image:GetHeight()) ..
            " compressed=" .. tostring(image:IsCompressed()) ..
            " components=" .. tostring(image:GetComponents()) ..
            " pixel00=" .. tostring(image:GetPixelInt(0, 0))
    end)
    print("[texture-probe] " .. tag .. " details=" .. tostring(ok and info or info))
end

function Start()
    print("[texture-probe] begin path=round2/prop-fence-broken.tga")
    local ok, result = pcall(function()
        return cache:GetResource("Texture2D", "round2/prop-fence-broken.tga")
    end)
    print("[texture-probe] GetResource_ok=" .. tostring(ok))
    if not ok then
        print("[texture-probe] GetResource_error=" .. tostring(result))
        return
    end
    texture = result
    print("[texture-probe] resource_non_nil=" .. tostring(texture ~= nil))
    if not texture then
        return
    end
    local tok, tinfo = pcall(function()
        return "type=" .. tostring(texture:GetTypeName()) ..
            " size=" .. tostring(texture:GetWidth()) .. "x" .. tostring(texture:GetHeight()) ..
            " format=" .. tostring(texture:GetFormat()) ..
            " compressed=" .. tostring(texture:IsCompressed()) ..
            " levels=" .. tostring(texture:GetLevels())
    end)
    print("[texture-probe] texture_details=" .. tostring(tok and tinfo or tinfo))

    local syncOk, syncImage = pcall(function()
        return texture:GetImage()
    end)
    print("[texture-probe] GetImage_ok=" .. tostring(syncOk))
    if not syncOk then
        print("[texture-probe] GetImage_error=" .. tostring(syncImage))
    else
        reportImage("GetImage", syncImage)
    end

    local requestedOk, requestedErr = pcall(function()
        texture:GetImageAsync(0, function(image)
            asyncDone = true
            reportImage("GetImageAsync(0, callback)", image)
        end)
    end)
    print("[texture-probe] GetImageAsync_level_signature_ok=" .. tostring(requestedOk))
    if not requestedOk then
        print("[texture-probe] GetImageAsync_level_signature_error=" .. tostring(requestedErr))
        local asyncOk, asyncErr = pcall(function()
            texture:GetImageAsync(function(image)
                asyncDone = true
                reportImage("GetImageAsync(callback)", image)
            end)
        end)
        print("[texture-probe] GetImageAsync_callback_signature_ok=" .. tostring(asyncOk))
        if not asyncOk then
            asyncDone = true
            print("[texture-probe] GetImageAsync_callback_signature_error=" .. tostring(asyncErr))
        end
    end
    SubscribeToEvent("Update", "TextureProbeUpdate")
end

function TextureProbeUpdate(_, eventData)
    frames = frames + 1
    if frames >= 12 then
        print("[texture-probe] callback_completed=" .. tostring(asyncDone) .. " frames=" .. tostring(frames))
        UnsubscribeFromEvent("Update")
    end
end
