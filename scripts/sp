!#/usr/bin/env bash

# Copyright (C) 2023,  <allbano@gmail.com>.
# License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.
# This is free software: you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.

#!/usr/bin/env bash

echo "Carregando lista de pacotes..."

search=$(apt-cache search ^.*$ | sed 's/ - /: /')

fpkg() {
    opt="--reverse -e -i --tiebreak=begin --prompt=Pesquisa:"
    [[ -n $1 ]] && local q="-q $1"
    p=$(fzf $q $opt --preview='p={};apt-cache show ${p%%:*}' --preview-window=down:50% <<< $search)
    [[ -n $p ]] && apt-cache show ${p%%:*} | less
    return
}

clear
fpkg $1
