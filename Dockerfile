FROM golang:1.20-alpine as gotools

RUN mkdir /build

RUN apk update && apk upgrade \
    && apk add git make gcc libc-dev \
    #
    && cd /build \
    && git clone https://github.com/whosonfirst/go-whosonfirst-findingaid.git \
    && cd go-whosonfirst-findingaid \
    && go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/wof-findingaid-sources cmd/wof-findingaid-sources/main.go \
    && go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/wof-findingaid-populate cmd/wof-findingaid-populate/main.go \
    && go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/wof-findingaid-csv2docstore cmd/wof-findingaid-csv2docstore/main.go \
    #
    && git clone https://github.com/sfomuseum/runtimevar.git \
    && cd runtimevar \
    && go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/runtimevar cmd/runtimevar/main.go \
    && cd && rm -rf /build \
    #
    && git clone https://github.com/aaronland/go-tools.git \
    && cd go-tools \
    && go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/urlencode cmd/urlencode/main.go \
    && cd && rm -rf /build 
    
FROM alpine

RUN mkdir /usr/local/data

RUN apk update && apk upgrade \
    && apk add git git-lfs

COPY --from=gotools /usr/local/bin/wof-findingaid-sources /usr/local/sfomuseum/bin
COPY --from=gotools /usr/local/bin/wof-findingaid-populate /usr/local/sfomuseum/bin
COPY --from=gotools /usr/local/bin/wof-findingaid-csv2docstore /usr/local/sfomuseum/bin
COPY --from=gotools /usr/local/bin/runtimevar /usr/local/sfomuseum/bin
COPY --from=gotools /usr/local/bin/urlencode /usr/local/sfomuseum/bin

COPY bin/update-findingaids.sh /usr/local/bin/update-findingaids.sh
COPY bin/populate-findingaids.sh /usr/local/bin/populate-findingaids.sh
COPY bin/.gitconfig /root/.gitconfig