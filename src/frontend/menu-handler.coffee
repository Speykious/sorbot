###

Embed menu data will be stored as `*.embed.yaml` files
in the path `src/frontend/pages/`.

EmbedMenu:
  @embed (MessageEmbed) - The actual formatted message on the page
  @reactons (Reactons) - The Reactons (Reaction + Button) for navigation

Reactons:
  A key/value pair
  with the @emoji character of the reaction as the key
  and a @path to the page it links to as the value.

A menu event has to have those informations:
- the id of the discord message
- the id of the user
- the emoji of the reaction

The menu state contains:
- the id of the discord message where the embed page is displayed
- the path to the `.embed.yaml` file corresponding to the page

###