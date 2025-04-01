# Make extensions

My gamebox has received a fair amount of attention since its release. So I created an extension function for the gamebox, allowing players to create custom content.

## Steps

### Step 1: Understanding the Principle

`OFMGCustomExtensions` is a global variable used to store information about third-party extensions. My Gamebox reads all `lua` files under `lua/ofmg_extensions`, so please put the code about extension information under this folder. 

### Step 2: Create a New Extension

1. In your extension file, create a new table for `OFMGCustomExtensions` and name it. To avoid conflicts with other people's extensions, please try to name it with a unique name, adding your own username's initials is a good idea. 

2. Add information about the extension.

`Type`: Specify the type of the extension. For example, `Entity` means that the extension is an entity, `Game` means that it is a game, `Game online` means that it is an online game, `Website` means that it is a website.

`Info`：Provides detailed information about the extension. If the extension is an entity, fill in the name of the entity, its path if it is a local game, and the url for online content. 

`Image`：Specify the name of the preview image, don't fill it if the extension is an entity, the gamebox will automatically read the entity preview image with the same name from the entities folder.

`Compatible`：Indicates whether or not the extension is compatible with Gmods that do not have the CEF installed. If it is compatible, set its value to `true`, otherwise, set it to `false`. (Abandoned)

3. Prepare the preview image of the extension.

Make a 128 x 128 size preview (the image must be square, a larger image can be used, but it is not recommended). Please put the entities preview in the `entities` folder, the game in the `entities/ofmg_games`, and the website in the `ofmg_websites`.

### Step 3: Save and Publish Your Extension

Finish the extension's writing, save it and test it locally. Once the testing is complete you can publish it. Make sure your extension information is added correctly and no errors are reported.

### Step 4: Using the Extension

When players have installed your extension, they can use the extension you made by visiting the corresponding tab on the extension page.

## Creation Convention

1. Don't post extensions with phishing sites, as doing so may compromise users' safety.
2. Don't post inappropriate content, including sensitive topics or unhealthy content.

