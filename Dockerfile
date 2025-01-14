FROM golang:1.23-alpine AS gotools

RUN mkdir /build

RUN apk update && apk upgrade \
    && apk add git git-lfs make gcc libc-dev 

# GOOS=linux GOARCH=amd64 
# GODEBUG=asyncpreemptoff=1

RUN cd /build \
    && git clone https://github.com/whosonfirst/go-whosonfirst-findingaid.git \
    && cd go-whosonfirst-findingaid \
    && go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/wof-findingaid-sources cmd/wof-findingaid-sources/main.go \
    && go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/wof-findingaid-populate cmd/wof-findingaid-populate/main.go \
    && go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/wof-findingaid-csv2docstore cmd/wof-findingaid-csv2docstore/main.go

RUN cd /build \
    && git clone https://github.com/sfomuseum/runtimevar.git \
    && cd runtimevar \
    && go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/runtimevar cmd/runtimevar/main.go 

RUN cd /build \
    && git clone https://github.com/aaronland/go-tools.git \
    && cd go-tools \
    && go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/urlescape cmd/urlescape/main.go

RUN cd / && rm -rf /build 
    
FROM alpine

RUN mkdir /usr/local/data
RUN mkdir -p /usr/local/sfomuseum/bin

RUN apk update && apk upgrade \
    && apk add git git-lfs

COPY --from=gotools /usr/local/bin/wof-findingaid-sources /usr/local/sfomuseum/bin
COPY --from=gotools /usr/local/bin/wof-findingaid-populate /usr/local/sfomuseum/bin
COPY --from=gotools /usr/local/bin/wof-findingaid-csv2docstore /usr/local/sfomuseum/bin
COPY --from=gotools /usr/local/bin/runtimevar /usr/local/sfomuseum/bin
COPY --from=gotools /usr/local/bin/urlescape /usr/local/sfomuseum/bin

# The new new
COPY bin/update-findingaids.sh /usr/local/bin/sfomuseum/update-findingaids.sh
COPY bin/populate-findingaids.sh /usr/local/bin/sfomuseum/populate-findingaids.sh

# The old old (deprecated (but still being referenced...))
COPY bin/update-findingaids.sh /usr/local/bin/update-findingaids.sh
COPY bin/populate-findingaids.sh /usr/local/bin/populate-findingaids.sh

COPY bin/.gitconfig /root/.gitconfig