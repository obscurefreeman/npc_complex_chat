# Make entities

Play games on any model.

![](https://s2.loli.net/2024/01/26/VHx83KYgzX4idOq.jpg)

## File structure

This is the basic file structure of **entity**.

```
.
├─ lua/
|  └─ entities/
|  |  └─ your_entity/
|  |     └─ ...
|  └─ ofmg_extensions/
|     └─ your_entity_info.lua
└─ materials/
   └─ entities/
      └─ your_entity.png
```

## Fill in extension information

Create a `lua` file in the `ofmg_extensions` folder. Here I name it `your_entity_info.lua`, but please remember to name it with a unique name as much as possible to avoid conflict with other people's extensions.

```lua
OFMGCustomExtensions["Your Entity"] = {
    ["Type"] = "Entity",--Its type is entity.
    ["Info"] = "your_entity",--Fill in the name of your entity.
```

## Write entity code

Get the activated games and determine whether it's **online** or **local** content.


```lua
local page = ofmgactivate

if string.sub(page, 1, 4) == "http" or string.sub(page, 1, 6) == "asset:" then
    self.Panel:OpenURL(page)
    --Open url if it's online.
elseif string.sub(page, -5) == ".html" then
    self.Panel:OpenFile(page)
    --Open file if it is local content.
else
    self.Panel:OpenFile("gamescreen.html")
    --Opens the default local page if not set.
end
```

Paint the panel onto the screen.

```lua
function ENT:Draw()
	self:DrawModel()

	self.ScreenOrigin = self:LocalToWorld(Vector(6,-28.9, 35.7))
	--Position of the screen.
	cam.Start3D2D(self.ScreenOrigin, self:LocalToWorldAngles(Angle(0,90,90)), 0.0304)
		self.Panel:PaintManual()
    	--Paint the panel.
	cam.End3D2D()
end
```

