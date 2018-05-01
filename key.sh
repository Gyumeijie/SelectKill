#!/bin/bash
# version 1

#while IFS="" read -r -e -d $'\n' -p 'input> ' line; do 
#   echo "$line"
#   history -s "$line"
#done

#!/usr/bin/env bash

# Renders a text based list of options that can be selected by the
# user using up, down and enter keys and returns the chosen option.
#
#   Arguments   : list of options, maximum of 256
#                 "opt1" "opt2" ...
#   Return value: selected index (0 for opt1, 1 for opt2 ...)

function select_option {
   
    local opts=($@) # convert to array
    local paranum=$#
    
    # little helpers for terminal print control and key input
    # TODO put the following functions into a sole file and include
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "[$ESC[1;91m $1 $ESC[0m]";} 
    print_marked()   { printf "[$ESC[9m $1 $ESC[29m]"; }
    print_selected()   { printf "[$ESC[7m $1 $ESC[27m]"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    #for opt in $opts; do printf "\n"; done
    for num in {1..5}; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    # local startrow=$(($lastrow - $#))
    local startrow=$(($lastrow - 5))

    local selected=0

    function clear_region(){
      for i in {0..4}; do
          cursor_to $(($startrow + $i))
           # clear the line from the current cursor to the end of line
          printf "$ESC[0K";
      done
    }


    function update_indexes_down(){
        local tmp=( "${indexes[@]}" )

        if [ ${indexes[4]} -eq $(($paranum-1)) ]; then
            indexes=({0..4})
            return;
        fi

        for i in {0..4}; do
           indexes[$i]=$((${tmp[$i]} + 1))
        done

        selected=4
    }

     function update_indexes_up(){
        local tmp=( "${indexes[@]}" )

        if [ ${indexes[0]} == 0 ]; then 
                  
           for i in {0..4}; do
                indexes[$i]=$(($paranum - 5 + $i ))
           done
           return;
        fi

        for i in {0..4}; do
           indexes[$i]=$((${tmp[$i]} -1 ))
        done

        selected=0
    }


    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    while true; do
        # print options by overwriting the last lines
        # for opt in $opts; do
         local idx=0;
         clear_region
         for i in {0..4}; do
            idx=${indexes[$i]}
            cursor_to $(($startrow + $i))
            if [ $i -eq $selected ]; then
                print_selected "${opts[$idx]}" 
            else
                print_option "${opts[$idx]}" 
            fi
            # ((idx++))
        done

        # user key control
        case `key_input` in
            enter) cursor_to $(($startrow))
                   break;;
            up)    ((selected--));
                   # if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
                   if [ $selected -lt 0 ]; then selected=$((5 - 1)); update_indexes_up; fi;;
            down)  ((selected++));
                   # if [ $selected -ge $# ]; then selected=0; fi;;
                   if [ $selected -ge 5 ]; then selected=0; update_indexes_down; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected

}

echo "Select one option using up/down keys and enter to confirm:"
echo

indexes=({0..4})
options=("one" "two" "three" "four"  "five" "six" "seven" "eight" "nine" "ten" "eleven" "twelve")

select_option "${options[@]}"
choice=$?
#deleted=${options[$choice]} 
#options=( "${options[@]/$deleted}" )
#select_option "${options[@]}"

index=${indexes[$choice]}
echo "Choosen index = $index"
echo "        value = ${options[$index]}"
