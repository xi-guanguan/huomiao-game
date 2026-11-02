-- Temporary runtime regression test for the relay gate. Removed after validation.
V.atFrame(120, function()
    V.assert(HUOMIAO ~= nil, "Huomiao app state is missing")
    V.assert(HUOMIAO.relayConfirmed == false, "The relay gate must start closed")
    V.assert(HUOMIAO.gameStarted == false, "The game must not start before confirmation")
    HUOMIAO.relayConfirmed = true
end)

V.atFrame(180, function()
    V.assert(HUOMIAO.gameStarted == true, "Confirmation did not release the game")
    V.assert(HUOMIAO.loadStep >= 1, "First storage loading stage did not run")
    V.assert(HUOMIAO.store ~= nil, "Storage was not initialized after confirmation")
    V.assert(HUOMIAO.saved == nil and HUOMIAO.words ~= nil, "Initial save state was not loaded")
    V.assert(HUOMIAO.ready == true, "The game did not finish loading after confirmation")
    V.assert(HUOMIAO.audio ~= nil, "Audio was not initialized after confirmation")

    local store = require("platform.storage").new({ testMode = true })
    store.path = "huomiao-relay-regression-v2.json"
    V.assert(not fileSystem:FileExists(store.path), "Regression save path is already occupied")
    store:save(HUOMIAO.state, {})
    local saved = store:load()
    V.assert(saved ~= nil, "Relative-path save could not be loaded")
    store:save(HUOMIAO.state, {})
    local resaved = store:load()
    V.assert(resaved ~= nil, "Save replacement could not be loaded")
    V.assert(fileSystem:Delete(store.path), "Regression save cleanup failed")
    if fileSystem:FileExists(store.path .. ".bak") then
        V.assert(fileSystem:Delete(store.path .. ".bak"), "Regression backup cleanup failed")
    end
    if fileSystem:FileExists(store.path .. ".tmp") then
        V.assert(fileSystem:Delete(store.path .. ".tmp"), "Regression temp cleanup failed")
    end
    print("RELAY_REGRESSION_GATE_AND_SAVE_PASSED")
    V.finish()
end)
