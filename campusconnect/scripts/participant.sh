#!/bin/sh
#

# Copyright (C) 2013 Heiko Bernloehr (FreeIT.de).
# 
# This file is part of ECS.
# 
# ECS is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
# 
# ECS is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public
# License along with ECS. If not, see <http://www.gnu.org/licenses/>.


# adjust next lines
CACERT="/path/to/ca.cert.pem"
CERT="/path/to/lsfproxy.cert.pem"
KEY="/path/to/lsfproxy.key.pem"
PASS="secure_password"
ECS_URL="URL to ECS"

# from here you should not have to touch anything

TRUE=0
FALSE=1
NO_ARGS=0 
E_OPTERROR=85
VERBOSE=$FALSE
SENDER=$FALSE
RECEIVER=$FALSE
ALL=$FALSE
CURL_OPTIONS="-s"
REDIRECT_IO=" 2>/dev/null"

###
### Usage
###
usage() {
  echo "Usage: `basename $0` <-r|-s> <get|delete> <resource-name>"
  echo "Options:"
  echo "  -r ... resources you are a receiver (valid for resource lists and deletions, default)"
  echo "  -s ... resources you are the sender (valid for resource lists and deletions)"
  echo "  -a ... all resources (valid for resource lists and deletions)"
  echo "  -v ... verbose output"
  echo "  -h|? ... usage"
  echo ""

cat - <<'EOF'
Examples:

  List all courselinks where I'm a receiver of:
  participant.sh get /campusconnect/courselinks
  or
  participant.sh -r get /campusconnect/courselinks

  List all courselinks where I'm the sender of:
  participant.sh -s get /campusconnect/courselinks

  Show the courselink representation with id 2257:
  participant.sh get /campusconnect/courselinks/2257

  Delete the courselink representation with id 2257:
  participant.sh delete /campusconnect/courselinks/2257

  Delete courselinks where I'm a receiver of:
  participant.sh -r delete /campusconnect/courselinks

  Delete courselinks where I'm the senedr of:
  participant.sh -s delete /campusconnect/courselinks

  Delete courselinks where I'm a receiver or sender of:
  participant.sh -a delete /campusconnect/courselinks

EOF
}

###
### Prerequisites
###
prerequisites() {
for i in curl cut grep; do 
$i --version  >/dev/null 2>&1
if [ "$?" != "0" ]; then
  cat <<-EOF

		-------------------------------------
		ERROR:
		Can't find "$i". Please install it.
		Search-Path: $PATH
		-------------------------------------

	EOF
  exit 1
fi
done
}


###
### delete resource
###
delete() {
namespace=`echo $1 | cut -d'/' -f2`
resourcename=`echo $1 | cut -d'/' -f3`
rid=`echo $1 | cut -d'/' -f4`
if [ "x`echo $rid | grep '^[0-9]\+$'`" != "x" -a "x$namespace" != "x" -a "x$resourcename" != "x" ]; then 
  if [ x$VERBOSE = x$FALSE ]; then
    REDIRECT_IO='2>/dev/null >/dev/null'
  fi
  cmd="curl $CURL_OPTIONS --cacert $CACERT --cert $CERT --key $KEY --pass $PASS \
       -X DELETE ${ECS_URL}$1 $REDIRECT_IO"
  #eval $cmd
  echo $cmd
elif [ "x`echo $rid | grep '^[0-9]\+$'`" = "x" -a "x$namespace" != "x" -a "x$resourcename" != "x" ]; then 
  curl_options="$CURL_OPTIONS"
  CURL_OPTIONS=
  list=`get /$namespace/$resourcename`
  CURL_OPTIONS=$curl_options
  for i in $list; do
    echo Deleting resource representation \"/$namespace/$i\" ...
    delete "/$namespace/$i"
  done
fi
}

###
### get resource
###
get() {
  if [ x$SENDER = x$TRUE ]; then
    cmd="curl $CURL_OPTIONS --cacert $CACERT --cert $CERT --key $KEY --pass $PASS \
      -H \"X-EcsQueryStrings: sender=true\" \
      -X GET ${ECS_URL}$1 $REDIRECT_IO"
  elif [ x$RECEIVER = x$TRUE ]; then
    cmd="curl $CURL_OPTIONS --cacert $CACERT --cert $CERT --key $KEY --pass $PASS \
      -H \"X-EcsQueryStrings: receiver=true\" \
      -X GET ${ECS_URL}$1 $REDIRECT_IO"
  elif [ x$ALL = x$TRUE ]; then
    cmd="curl $CURL_OPTIONS --cacert $CACERT --cert $CERT --key $KEY --pass $PASS \
      -H \"X-EcsQueryStrings: all=true\" \
      -X GET ${ECS_URL}$1 $REDIRECT_IO"
  else
    cmd="curl $CURL_OPTIONS --cacert $CACERT --cert $CERT --key $KEY --pass $PASS \
      -H \"X-EcsQueryStrings: receiver=true\" \
      -X GET ${ECS_URL}$1 $REDIRECT_IO"
  fi
  eval $cmd
}

###
### main
###

prerequisites

if [ $# -eq "$NO_ARGS" ]    # Script invoked with no command-line args?
then
  usage
  exit $E_OPTERROR          # Exit and explain usage.
                            # Usage: scriptname -options
                            # Note: dash (-) necessary
fi  

while getopts ":asrv" Option
do
  case $Option in
    v) VERBOSE=$TRUE;;
    s) SENDER=$TRUE;;
    r) RECEIVER=$TRUE;;
    a) ALL=$TRUE;;
    h) usage; exit 0;;
    ?) usage; exit 0;;
    *) echo "Unimplemented option chosen."; usage; exit $E_OPTERROR;;   # Default.
  esac
done

shift $(($OPTIND - 1))
#  Decrements the argument pointer so it points to next argument.
#  $1 now references the first non-option item supplied on the command-line
#  if one exists.


if [ X$VERBOSE = X$TRUE ]; then 

  CURL_OPTIONS=`echo $CURL_OPTIONS | sed -n -e 's/-s//p'`
  CURL_OPTIONS="$CURL_OPTIONS -i"
fi

case $1 in
  "get"   ) get $2;;
  "delete") delete $2;;
  *       ) usage;; 
esac

exit $?
