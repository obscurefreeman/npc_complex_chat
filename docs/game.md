# Add local content

![](https://s2.loli.net/2024/01/26/VZtdgaEfuvclrjJ.jpg)

## Get the content

Want to add local content to the gamebox? You'll need to get the source code that meets the requirements. Here are a few ways to get the code.

1. Search on [Github](https://github.com/). Look for open-source `HTML5` games and see if their code meets the requirements. Be careful not to choose a game with a lot of pictures. **(Recommended)**
2. Get it from the online code editor, [Code Pen](https://codepen.io/). A lot of front-end developers and designers will share their code and projects on the **Code Pen**, and you can copy their code. **(Very recommended)**
3. Get it from [js13kGames](https://js13kgames.com/). Find a game you like and head over to its open-source repository to get the source code. **js13kGames** is an annual `js` coding contest for web game developers since 2012. There is a condition for participating in this contest, and that is that the size of the game cannot exceed **13KB**. **(Recommended)**
4. Make your own content. If you're familiar with `HTML`, you can make your own games in the gamebox. You can create a game based on your ideas and needs. **(Recommended)**

## File structure

This is the basic file structure of `local content`.

```
.
├─ lua/
|   └─ html/
|   |  └─ includes/
|   |     └─ your_local_game.html.lua
|   |     └─ your_multifile_local_game/
|   |        └─ index.html.lua
|   |        └─ script.js.lua
|   |        └─ style.css.lua
|   └─ ofmg_extensions/
|      └─ your_local_games_info.lua
└─ materials/
   └─ entities/
      └─ ofmg_games/
         └─ your_local_game.png
         └─ your_multifile_local_game.png
```

## Process HTML files

Since the Gmod Workshop doesn't allow `html` files to be uploaded, we can disguise it as a `Lua` file and load it with the HTML Loader.

- If there is only one `html` file, change its suffix to `.html.lua` and place it in the `lua/html/includes/` folder.

- If it has multiple files, you can create a new folder, here take `your_multifile_local_game` as an example, put all the `html`, `js`, `css` files into this folder, and then open the `html` file with `vsc` or notepad (if you don't have `vsc`), and change the paths of `js` and `css`.


### Modify the path of `css`

```html
<link rel="stylesheet" href="your_multifile_local_game/style.css">
```

### Modify the path of `js`

```html
<script src="your_multifile_local_game/script.js"></script>
```

After modifying the files, don’t forget to change the suffix of the `css` file to `css.lua` and the suffix of the `js` file to `js.lua`.

## Fill in extension information

Create a `lua` file in the `ofmg_extensions` folder, and try to name it with a unique name to avoid conflict with other people's extensions. In this file, create a new table for `OFMGCustomExtensions` and give it a name. Likewise, give this table a unique name.

Only **one** HTML file.

```lua
OFMGCustomExtensions["Your Local Game"] = {
    ["Type"] = "Game",--Its type is local game.
    ["Info"] = "your_local_game.html",--Location of the game.
    ["Image"] = "your_local_game",--Name of the image. Please put the 128*128 preview image in the entities/ofmg_games folder.
```

Contains **multiple** HTML files.

```lua
OFMGCustomExtensions["Your Multi-file Local Game"] = {
    ["Type"] = "Game",---Its type is local game.
    ["Info"] = "your_multifile_local_game/index.html",--Location of the game.
    ["Image"] = "your_multifile_local_game",--Name of the image. Please put the 128*128 preview image in the entities/ofmg_games folder.
```
