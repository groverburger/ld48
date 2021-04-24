Impact = class(Thing)
Impact.sprite = utils.newAnimation("assets/sprites/impact.png")

function Impact:update()
    Impact.super.update(self)

    self.animIndex = self.animIndex + 0.4
    if self.animIndex >= 3 then
        self.dead = true
    end
end
