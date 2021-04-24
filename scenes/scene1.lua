FirstScene = class()

function FirstScene:new()
    self.thingList = {}
    self.player = Player(400,400)
    table.insert(self.thingList, self.player)
    lg.setBackgroundColor(lume.color("#A7BFEF"))
end

function FirstScene:update()
    for i, thing in ipairs(self.thingList) do
        thing:update()
    end
end

function FirstScene:draw()
    for i, thing in ipairs(self.thingList) do
        thing:draw()
    end
end
