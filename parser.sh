#!/bin/bash

function ini_parser () {

    ini="$(<$1)"                # read the file
    OLDIFS=$IFS
    IFS=$'\n' && ini=( ${ini} ) # convert to line-array
    ini=( ${ini[*]//;*/} )      # remove comments with ;
    ini=( ${ini[*]/\    =/=} )  # remove tabs before =
    ini=( ${ini[*]/=\   /=} )   # remove tabs be =
    ini=( ${ini[*]/\ =\ /=} )   # remove anything with a space around =
    ini+=("[INI_END]") # dummy section to terminate
    sections=()
    section=INI_NULL
    vals=""
    for line in "${ini[@]}"; do

      if [ "${line:0:1}" == "[" ] ; then
        # close previous section
        eval "ini_${section}+=(\"$vals\")"
        if [ "$line" == "[INI_END]" ]; then
           break
        fi

        # new section
        section=${line#[}
        section=${section%]}
        secs="${sections[*]}"
        if [ "$secs" == "${secs/$section//}" ] ; then
          sections+=($section)
          eval "ini_${section}=()"
        fi
        vals=""
        continue
      fi

      key=${line%%=*}
      value=${line#*=}
      value=${value//\"/\\\"}
      if [ "$vals" != "" ] ; then
        vals+=" "
      fi
      vals+="$key='$value'"

    done

    IFS=$OLDIFS
}


function ini_section_keys () {

   # read number of keys (subsections) in a given section
   eval "keys=(\${!ini_$1[@]})"
}


function ini_section () {
 
   # read in settings for a specific key in a given section
   section=$1
   key=$2
   if [ "$key" == "" ] ; then
      key=0
   fi

   eval "vals=\${ini_$section[$key]}"
   eval $vals
}


function ini_section_merge () {
   # read and merge all settings for all keys of a given section
   ini_section_keys $1
   for key in "${keys[@]}"; do
     ini_section $section $key
   done
}


function do_parsing() {

   ini_parser ~/.skill.conf
   for section in ${sections[@]}; do
      ini_section_keys $section

      for key in "${keys[@]}"; do
        ini_section $section $key
      done
   done
}
