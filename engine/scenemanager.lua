local scenemanager = {}

local scene

function scenemanager.set(newscene)
    scene = newscene
    if scene.init then scene:init() end
    engine.resetFramerateSmoothing()
end

function scenemanager.get()
    return scene
end

return scenemanager
