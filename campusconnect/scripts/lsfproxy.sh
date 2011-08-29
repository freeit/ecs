#!/bin/sh
#

# Copyright (C) 2007, 2008, 2009, 2011 Heiko Bernloehr (FreeIT.de).
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
ECS_URL="URL to EVS"
DATA_URL1="data url1"
DATA_URL2="data url2"
DATA_URL3="data url3"

# from here you should not have to touch anything

NO_ARGS=0 
E_OPTERROR=85
RESOURCE=
VERBOSE=
CID=
MID=
DATA_URL_ID=
COURSES=
COURSE_MEMBERS=
MEMBERSHIPS=
TREES=
CURL_OPTIONS=

###
### Usage
###
usage() {
  echo "Usage: `basename $0` options <create|get|delete|update>"
  echo "Options:"
  echo "  -c ... courses"
  echo "  -m ... course members"
  echo "  -t ... directory trees"
  echo "  -s ... memberships"
  echo "  -i <resource id>"
  echo "  -k <membership id>"
  echo "  -u <data url id>"
  echo "  -v   ... verbose output"
  echo "  -h|? ... usage"
  echo ""
}
###
### resource select helper
###
resource_selection() {
if [ X$COURSES = Xtrue ]; then RESOURCE="campusconnect/courses"
  else if [ X$COURSE_MEMBERS = Xtrue ]; then RESOURCE="campusconnect/course_members"
    else if [ X$TREES = Xtrue ]; then RESOURCE="campusconnect/directory_trees"
      else if [ X$MEMBERSHIPS = Xtrue ]; then RESOURCE="sys/memberships"
      else echo "ERROR: no resource selection option specified (option -c|m|t)"; exit $E_OPTERROR
      fi
    fi
  fi
fi
}

###
### create resource
###
create() {
resource_selection
if [ X$MEMBERSHIPS = Xtrue ]; then
  echo "ERROR: memberships: only \"get\" operation allowed"
  exit 90
fi
if [ -z $MID ]; then 
  echo "ERROR: no membership id specified (option -k <membership id>)"
  exit $E_OPTERROR
fi
if [ -z $DATA_URL_ID ]; then 
  echo "ERROR: no data url id specified (option -u <data url id>)"
  exit $E_OPTERROR
fi
curl $CURL_OPTIONS --cacert $CACERT --cert $CERT --key $KEY --pass $PASS \
     -H "Content-Type: text/uri-list" \
     -H "X-EcsReceiverMemberships: $MID" \
     -d `eval expr $"DATA_URL$DATA_URL_ID"` \
     -X POST $ECS_URL/$RESOURCE
echo ""
}

###
### update resource
###
update() {
resource_selection
if [ X$MEMBERSHIPS = Xtrue ]; then
  echo "ERROR: memberships: only \"get\" operation allowed"
  exit 90
fi
if [ -z $CID ]; then 
  echo "ERROR: no resource id specified (option -i <resource id>)"
  exit $E_OPTERROR
fi
if [ -z $MID ]; then 
  echo "ERROR: no membership id specified (option -k <membership id>)"
  exit $E_OPTERROR
fi
if [ -z $DATA_URL_ID ]; then 
  echo "ERROR: no data url id specified (option -u <data url id>)"
  exit $E_OPTERROR
fi
curl $CURL_OPTIONS --cacert $CACERT --cert $CERT --key $KEY --pass $PASS \
     -H "Content-Type: text/uri-list" \
     -H "X-EcsReceiverMemberships: $MID" \
     -d `eval expr $"DATA_URL$DATA_URL_ID"` \
     -X PUT $ECS_URL/$RESOURCE/$CID
echo ""
}

###
### delete resource
###
delete() {
resource_selection
if [ X$MEMBERSHIPS = Xtrue ]; then
  echo "ERROR: memberships: only \"get\" operation allowed"
  exit 90
fi
if [ -z $CID ]; then 
  echo "ERROR: no resource id specified (option -i <resource id>)"
  exit $E_OPTERROR
fi
curl $CURL_OPTIONS --cacert $CACERT --cert $CERT --key $KEY --pass $PASS \
     -X DELETE $ECS_URL/$RESOURCE/$CID
echo ""
}

###
### get resource indirectly or resource listing
###
get() {
local url
resource_selection
if [ X$MEMBERSHIPS = Xtrue ]; then
  curl $CURL_OPTIONS --cacert $CACERT --cert $CERT --key $KEY --pass $PASS \
       -X GET  $ECS_URL/$RESOURCE
else
  if [ -z $CID ]; then 
    curl $CURL_OPTIONS --cacert $CACERT --cert $CERT --key $KEY --pass $PASS \
       -H "Accept: text/uri-list" \
       -X GET $ECS_URL/$RESOURCE
  else
    url=`curl -s --cacert $CACERT --cert $CERT --key $KEY --pass $PASS \
         -H "Accept: text/uri-list" \
         -X GET $ECS_URL/$RESOURCE/$CID`
    if [ X$VERBOSE = Xtrue ]; then 
      echo "Indirect URL address from ECS: $url"
      echo "and its representation from lsfproxy:"
    fi
    if [ "X$url" = "XInvalid resource id" ]; then
      echo "ERROR: Invalid resource id"
      exit 99
    else
      curl $CURL_OPTIONS  -H "X-EcsQueryStrings: all=true" -X GET $url
    fi
  fi
fi
echo ""
}


###
### main
###
if [ $# -eq "$NO_ARGS" ]    # Script invoked with no command-line args?
then
  usage
  exit $E_OPTERROR          # Exit and explain usage.
                            # Usage: scriptname -options
                            # Note: dash (-) necessary
fi  

while getopts ":i:k:u:cmtsv" Option
do
  case $Option in
    i) CID=$OPTARG;;
    k) MID=$OPTARG;;
    u) DATA_URL_ID=$OPTARG;;
    v) VERBOSE=true;;
    c) COURSES=true;;
    m) COURSE_MEMBERS=true;;
    t) TREES=true;;
    s) MEMBERSHIPS=true;;
    h) usage; exit 0;;
    ?) usage; exit 0;;
    *) echo "Unimplemented option chosen."; usage; exit $E_OPTERROR;;   # Default.
  esac
done

shift $(($OPTIND - 1))
#  Decrements the argument pointer so it points to next argument.
#  $1 now references the first non-option item supplied on the command-line
#+ if one exists.


if [ X$VERBOSE = Xtrue ]; then 
  CURL_OPTIONS="$CURL_OPTIONS -i"
fi

case $1 in
  "create") create;;
  "get"   ) get;;
  "delete") delete;;
  "update") update;;
  *       ) usage;; 
esac

exit $?
