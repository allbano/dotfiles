#!/bin/bash

let CASE=0
for A in 'Ge' 'Gi' 'Gy' 'J' ; do
    for B in 'v' 'w' ; do
        for C in 'n' 'nn'; do
            for D in 'e' 'i' 'y' ; do
                let CASE++
                printf "Caso %02d – %so%sa%s%s%s\n" $CASE $A $B $C $D
            done
        done
    done
done


# ./testagiovani.sh | rg '(J|G(e|i|y))ovan{1,2}(e|i|y)'
