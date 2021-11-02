#!/bin/sh

SOURCES=/usr/local/bin/sources
POPULATE=/usr/local/bin/populate

SINCE=0

${GIT} clone https://github.com/sfomuseum-data/sfomuseum-findingaids.git /usr/local/data/sfomuseum-findingaid

REPOS=`bin/sources -provider-uri "github://sfomuseum-data?prefix=sfomuseum-data-&updated_since=${SINCE}"`

for REPO in ${REPOS}
do
    NAME=`basename ${REPO} | sed 's/\.git//g'`

    PRODUCER_URI="csv://?archive=/usr/local/data/sfomuseum-findingaid/data/${NAME}.db"

    if [ "${NAME}" = "sfomuseum-data-whosonfirst" ]
    then
	PRODUCER_URI="csv://?archive=/usr/local/data/sfomuseum-findingaid/data/${NAME}.db&path-repo=properties.sfomuseum:repo"
    fi
    
    time ${POPULATE} -iterator-uri git:///tmp -producer-uri ${PRODUCER_URI} ${REPO}
done

cd /usr/local/data/sfomuseum-findingaid
git commit -m "update finding aids for ${REPOS}"
git push origin main


