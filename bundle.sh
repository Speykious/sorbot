#!/bin/bash

# ... Well this looks kinda like the rustc compiler 🤔
bred='\e[1m\e[38;2;255;100;50m'
bgrn='\e[1m\e[38;2;50;255;150m'
u='\e[4m'
c='\e[0m'

echo -e "  ${bred}Clearing$c    the ${u}sorbot-min/$c folder"
rm -r sorbot-min/
mkdir sorbot-min/

echo -e "  ${bred}Compiling$c   the coffeescript code into javascript code"
coffee -bcmo client src

echo -e "  ${bred}Minifying$c   the javascript code"
ncc build client/index.js -mo sorbot-min/bin/

echo -e "  ${bred}Copying$c     the needed resources to ${u}sorbot-min/$c"
rsync -rah --progress resources sorbot-min/
rsync -ah --progress credentials.yaml token.yaml sorbot-min/
rsync -ah --progress bundle.env sorbot-min/.env

echo -e "  ${bred}Removing$c    the ${u}bin/lib/$c folder"
rm -rf sorbot-min/bin/lib/

echo -e "  ${bgrn}Success.$c"
