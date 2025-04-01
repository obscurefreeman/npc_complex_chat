# Add online content

![](https://s2.loli.net/2024/01/26/BqfYC37lePSA9wO.jpg)

## File structure

This is the basic file structure of `online content`.

```
.
├─ lua/
|  └─ ofmg_extensions/
|     └─ your_online_games_info.lua
└─ materials/
    └─ entities/
       └─ ofmg_games/
          └─ your_online_game1.png
          └─ your_online_game2.png
          └─ your_online_game3.png
```

This is the basic file structure of a `website`.

```
.
├─ lua/
|  └─ ofmg_extensions/
|     └─ your_websites_info.lua
└─ materials/
    └─ entities/
       └─ ofmg_websites/
          └─ your_website1.png
          └─ your_website2.png
          └─ your_website3.png
```

## Fill in extension information

Create a `lua` file in the `ofmg_extensions` folder, and try to name it with a unique name to avoid conflict with other people's extensions. In this file, create a new table for `OFMGCustomExtensions` and give it a name. Likewise, give this table a unique name.

This is an example of extension information for **Online Games**.

```lua
OFMGCustomExtensions["Your Online Game"] = {
    ["Type"] = "Game online",--Its type is online game.
    ["Info"] = "https://online-game/",--Game websites.
    ["Image"] = "your_online_game1",--Name of the image. Please put the 128*128 preview image in the entities/ofmg_games folder.
```

This is an example of extension information for **Website**.

```lua
OFMGCustomExtensions["Your Website"] = {
    ["Type"] = "Website",--Its type is website.
    ["Info"] = "https://your-website/",--Website link.
    ["Image"] = "your_website1",--Name of the image. Please put the 128*128 preview image in the entities/ofmg_games folder.
```