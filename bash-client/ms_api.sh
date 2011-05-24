#!/bin/bash
# USAGE:
# MS_API_KP="MyKey:MySecret" bash ms_api.sh echo a=b

MS_API_EP="http://api.moodstocks.com/v2"
function ms_api {
  case $1 in
    add)    curl -s --digest -u "$MS_API_KP" "$MS_API_EP/ref/$3" \
                 --form image_file=@"$2" -X PUT ;;
    del)    curl -s --digest -u "$MS_API_KP" "$MS_API_EP/ref/$2" -X DELETE ;;
    echo)   curl -s --digest -u "$MS_API_KP" "$MS_API_EP/echo/?$2" ;;
    search) curl -s --digest -u "$MS_API_KP" "$MS_API_EP/search" \
                 --form image_file=@"$2" ;;
    stats)  curl -s --digest -u "$MS_API_KP" "$MS_API_EP/stats/$2" ;;
  esac; echo
}

ms_api $*
