#!/bin/sh

SOURCES=`command -v wof-findingaid-sources`
POPULATE=`command -v wof-findingaid-populate`

GIT=`command -v git`
DATE=`command -v date`
BC=`command -v bc`

NOW=`${DATE} '+%s'`
SINCE=$((${NOW} - 86400))	# 24 hours

${GIT} clone https://github.com/sfomuseum-data/sfomuseum-findingaids.git /usr/local/data/sfomuseum-findingaid

REPOS=`${SOURCES} -provider-uri "github://sfomuseum-data?prefix=sfomuseum-data-&updated_since=${SINCE}"`

if [ "${REPOS}" = "" ]
then
    exit
fi

for REPO in ${REPOS}
do
    NAME=`basename ${REPO} | sed 's/\.git//g'`
    echo "Update finding aid for ${NAME}"
    
    PRODUCER_URI="csv://?archive=/usr/local/data/sfomuseum-findingaid/data/${NAME}.db"

    if [ "${NAME}" = "sfomuseum-data-whosonfirst" ]
    then
	PRODUCER_URI="csv://?archive=/usr/local/data/sfomuseum-findingaid/data/${NAME}.db&path-repo=properties.sfomuseum:repo"
    fi
    
    time ${POPULATE} -iterator-uri git:///tmp -producer-uri ${PRODUCER_URI} ${REPO}
done

cd /usr/local/data/sfomuseum-findingaid
git add data
git commit -m "update finding aids for ${REPOS}"
git push origin main


