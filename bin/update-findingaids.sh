#!/bin/sh

# update-findingaids.sh -T 'awsparamstore://{PARAM_NAME}?region={REGION}&credentials=session'
# update-findingaids.sh -T 'constant://?val={TOKEN}'

BIN=/usr/local/sfomuseum/bin

SOURCES=${BIN}/wof-findingaid-sources
POPULATE=${BIN}/wof-findingaid-populate
RUNTIMEVAR=${BIN}/runtimevar
URLENCODE=${BIN}/urlencode

GIT=`which git`
DATE=`which date`
BC=`which bc`

DATA=/usr/local/data

OFFSET=86400	# 24 hours
GITHUB_USER="sfomuseum-bot"

CUSTOM_REPOS=""
TOKEN_URI=""
USAGE=""

CREDENTIALS="iam:"

while getopts "C:D:O:R:T:U:h" opt; do
    case "$opt" in
	C)
	    CREDENTIALS=${OPTARG}
	    ;;
	D)
	    DATA=${OPTARG}
	    ;;
        h) 
	    USAGE=1
	    ;;
	O)
	    OFFSET=$OPTARG
	    ;;	
	R)
	    CUSTOM_REPOS=$OPTARG
	    ;;
	T)
	    TOKEN_URI=$OPTARG
	    ;;
	U)
	    GITHUB_USER=$OPTARG
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

echo "Update finding aids"

echo "Retrieve GitHub acccess token w/ ${TOKEN_URI}"

GITHUB_TOKEN=`${RUNTIMEVAR} -timeout 10 "${TOKEN_URI}"`

if [ "${GITHUB_TOKEN}" = "" ]
then
    echo "Missing GitHub access token"
    exit 1
fi

echo "Fetch repositories in to ${DATA}"

NOW=`${DATE} '+%s'`
SINCE=$((${NOW} - ${OFFSET}))

if [ "${CUSTOM_REPOS}" = "" ]
then
    echo "Fetch repos updated since ${SINCE} (offset ${OFFSET} seconds since now)"
    REPOS=`${SOURCES} -provider-uri "github://sfomuseum-data?prefix=sfomuseum-data-&updated_since=${SINCE}"`    
else
    echo "Update custom repos ${CUSTOM_REPOS}"

    for REPO in ${CUSTOM_REPOS}
    do
	REPOS="${REPOS} https://github.com/sfomuseum-data/${REPO}.git"
    done
fi

if [ "${REPOS}" = "" ]
then
    exit
fi

# Clone the sfomuseum-findingaids repo - we are going to write CSV data to this target

echo "Clone sfomuseum-data/sfomuseum-findingaids as ${GITHUB_USER}"
${GIT} clone --depth 1 https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/sfomuseum-data/sfomuseum-findingaids.git ${DATA}/sfomuseum-findingaids

for REPO in ${REPOS}
do
    NAME=`basename ${REPO} | sed 's/\.git//g'`
    echo "Update finding aid for ${NAME}"

    # Clone the repo once since we want to crawl it with multiple producers (CSV and DynamoDB)
    # We may want to revisit the use of the repo:// iterator and instead generate a "filelist"
    # of updated records and iterate over that. For the time being this will do.
    
    ${GIT} clone --depth 1 ${REPO} ${DATA}/${NAME}
    
    CSV_URI="csv://?archive=${DATA}/sfomuseum-findingaids/data/${NAME}.tar.gz"
    DYNAMODB_URI="awsdynamodb://findingaid?partition_key=id&region=us-west-2&credentials=${CREDENTIALS}"

    ENC_CSV_URI=`echo ${CSV_URI} | urlencode -stdin`
    ENC_DYNAMODB_URI=`echo ${DYNAMODB_URI} | urlencode -stdin`    

    PRODUCER_URI="multi://?producer=${ENC_CSV_URI}&producer=${ENC_DYNAMODB_URI}"
    echo "Populate w/ {$PRODUCER_URI}"

    time ${POPULATE} -iterator-uri repo:// -producer-uri ${PRODUCER_URI}  ${DATA}/${NAME}

    rm -rf ${DATA}/${REPO}
    
done

NAMES=""

for REPO in ${REPOS}
do
    NAME=`basename ${REPO} | sed 's/\.git//g'`
    NAMES="${NAMES} ${NAME}"
done

echo "Commit changes"

cd ${DATA}/sfomuseum-findingaids
git pull origin main
git add data
git commit -m "update finding aids for ${NAMES}" data
git push origin main
