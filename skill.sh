#!/bin/bash

# Renders a text based list of options that can be selected by the
# user using up, down and enter keys and returns the chosen option.
#
#   Arguments   : list of options, maximum of 256
#                 "opt1" "opt2" ...
#   Return value: selected index (0 for opt1, 1 for opt2 ...)

## settings 
. parser.sh 
if [ -e ~/.skill.conf ]; then 
   do_parsing 
else
   LISTNUM=5
fi


if [ $# -lt 1 ];
then
  echo "Usage: skill pattername"
  exit 1
fi

tmp=$(ps aux | grep $1 | tr '\t' ' ' | tr -s ' ')

## delete the last three entries generated by runing the script itself
## and the `grep $1` command above 
count=$(echo "$tmp" | wc -l)
begin=$((count-2))
end=$count
processes_info=$(echo "$tmp" | sed "${begin},${end}d")
count=$(echo "$processes_info" | sed '/^$/d' | wc -l)

if [ $count -lt 1 ];
then
   echo "No process matches $1"
   exit 0
fi


## extract pid column in given line
function get_pid() {
   local pid=`echo "$1" |  cut -d" " -f2` 
   echo "${pid}" 
}


function generate_indexes(){
   local indexes=`eval echo {0..$1}`   
   echo "${indexes[@]}"
}


mapfile -t opts < <(echo "$processes_info")
let num=${#opts[@]}-1
indexes=( `generate_indexes $num`)

function select_option {
   
    #local opts=(${options[@]}) # convert to array
    local paranum=${#opts[@]}
    
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
                         if [[ $key = $ESC[D ]]; then echo left;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    #for opt in $opts; do printf "\n"; done
    for i in `seq $LISTNUM`; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    # local startrow=$(($lastrow - $#))
    local startrow=$(($lastrow - $LISTNUM))

    local selected=0
    local rendernum=$LISTNUM
    if [ $paranum -lt $LISTNUM ]; then rendernum=$paranum; fi

  
    function clear_region(){
      for (( i=0; i<$rendernum; i++ )); do
          cursor_to $(($startrow + $i ))
           # clear the line from the current cursor to the end of line
          printf "$ESC[0K";
      done
    }


    function update_indexes_down(){
        local tmp=( "${indexes[@]}" )
        local lastindex=$(($rendernum - 1))

        if [ ${indexes[$lastindex]} -eq $(($paranum-1)) ]; then
            indexes=(`generate_indexes $rendernum`)
            return;
        fi

        for (( i=0; i<$rendernum; i++ )); do
           indexes[$i]=$((${tmp[$i]} + 1))
        done

        selected=$lastindex
    }

     function update_indexes_up(){
        local tmp=( "${indexes[@]}" )

        if [ $paranum -le $LISTNUM ]; then return ;fi

        if [ ${indexes[0]} == 0 ]; then 
           for (( i=0; i<$rendernum; i++ )); do
                indexes[$i]=$(($paranum - $rendernum + $i ))
           done
           return;
        fi

        for (( i=0; i<$rendernum; i++ )); do
           indexes[$i]=$((${tmp[$i]} - 1 ))
        done

        selected=0
    }

    function delete_item(){
       local let choice=$1+${indexes[0]}
       local deleted_opt=${opts[$choice]} 

       local pid=$(get_pid "$deleted_opt")
       kill -9 $pid

       # delete array element
       processes_info=$(echo "$processes_info" | awk -v line=$((choice + 1)) '{if(NR != line) print $0}')
       mapfile -t opts < <(echo "$processes_info")

       local lastindex=$(($rendernum - 1))
       if [ ${indexes[$lastindex]} -eq $(($paranum-1)) ] && [ $paranum -gt $LISTNUM ]; then
           for (( i=0; i<$rendernum; i++ )); do
               let indexes[$i]=indexes[$i]-1;
          done
       fi


       ((paranum--))
       
       clear_region

       if [ $paranum -lt $LISTNUM ];then 
          ((rendernum--));
         
          if [ $selected -eq $lastindex ] && [ $selected -gt 0 ];then
             let selected=selected-1
          fi
       fi

       if [ $rendernum -eq 0 ];then 
          cursor_blink_on
          echo "Selectively progress killing session is done."
          exit 0
       fi
    }

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n';exit" 2
    cursor_blink_off

    while true; do
        # print options by overwriting the last lines
        local idx=0;
        clear_region
        for (( i=0; i<$rendernum; i++ )); do
           idx=${indexes[$i]}
           cursor_to $(($startrow + $i))
           if [ $i -eq $selected ]; then
               print_selected "${opts[$idx]}" 
           else
               print_option "${opts[$idx]}" 
           fi
        done

        # user key control
        case `key_input` in
            enter) break;;

            up)    ((selected--));

                   if [ $selected -lt 0 ]; then selected=$(($rendernum - 1)); update_indexes_up; fi;;

            down)  ((selected++));

                   if [ $selected -ge $rendernum ]; then selected=0; update_indexes_down; fi;;

            left)  delete_item $selected;;
        esac
    done
    
    echo 
    echo "Session quits"
    cursor_blink_on
}


echo "Select one option using up/down keys, left key to confirm and enter to quit:"
echo
select_option


