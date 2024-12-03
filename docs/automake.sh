#!/bin/bash

counter=0;

while true; do
    inotifywait --recursive --exclude build --format "%e %w%f" \
        --event modify,move,create,delete ./source
    echo "#############################################################################"
    echo "##########################   Building pages   ###############################"
    echo "#############################################################################"
    counter=$((counter+1))
    echo "Detected change #$counter"
    make html
    browser_windows="$(xdotool search --all --onlyvisible --name '.*chFPGA.*(Brave|Firefox)')"
    echo "Will now refresh browser windows ${browser_windows}"
    # Send keystroke
    for bw in $browser_windows; do
        xdotool key --window $bw F5
    done
done