local scenemanager = {}

local scene

function scenemanager.set(newscene)
    scene = newscene
    scene:init()
    engine.resetFramerateSmoothing()
end

function scenemanager.get()
    return scene
end

return scenemanager
