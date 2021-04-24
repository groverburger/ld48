local scenemanager = {}

local scene

function scenemanager.set(newscene)
    scene = newscene
    engine.resetFramerateSmoothing()
end

function scenemanager.get()
    return scene
end

return scenemanager
