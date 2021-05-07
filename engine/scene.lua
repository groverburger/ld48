local scene

return function (newscene)
    if newscene then
        scene = newscene
        love.audio.stop()
        if scene.init then scene:init() end
        engine.resetFramerateSmoothing()
    end

    return scene
end
