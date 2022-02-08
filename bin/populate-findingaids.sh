#!/bin/sh

CSV2DOCSTORE=`which csv2docstore`
GIT=`which git`

CREDENTIALS="iam:"
REGION="us-west-2"

FINDINGAIDS=/usr/local/data/sfomuseum-findingaid

while getopts "C:R:h" opt; do
    case "$opt" in
        h) 
	    USAGE=1
	    ;;
	C)
	    CREDENTIALS=$OPTARG
	    ;;	
	R)
	    REGION=$OPTARG
	    ;;
	:   )
	    echo "WHAT WHAT WHAT"
	    ;;
    esac
done

if [ "${USAGE}" = "1" ]
then
    echo "usage: update.sh"
    echo "options:"
    echo "...please write me"
    exit 0
fi

echo ${REGION}

${GIT} clone https://github.com/sfomuseum-data/sfomuseum-findingaids.git ${FINDINGAIDS}

${CSV2DOCSTORE} -docstore-uri "awsdynamodb://findingaid?region=${REGION}&credentials=${CREDENTIALS}&partition_key=id" ${FINDINGAIDS}/data/*.tar.gz

rm -rf ${FINDINGAIDS}
