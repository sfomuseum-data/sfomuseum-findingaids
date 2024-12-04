# sfomuseum-findingaids

## Description

A Who's On First (sfomuseum-data) findinging aid is a lookup table mapping any given Who's On First (sfomuseum-data) ID to the (GitHub) repository where the full record for that ID is stored.

### Reminder

This is not an ideal situation. It is a reflection of the fact that there is a still a limit to how many documents can be stored in a single Git(Hub) repository. While it may be true that SFO Museum doesn't have enough records, in total, to trigger that limit it is definitely true of Who's On First records so we (SFO Museum) simply follow the convention.

## Data

Finding aid data is stored in the [sfomuseum-data/sfomuseum-findingaids](https://github.com/sfomuseum-data/sfomuseum-findingaids) repository.

That data is updated using the [bin/update-findingaids.sh](https://github.com/sfomuseum-data/sfomuseum-findingaids/blob/main/bin/update-findingaids.sh) tool which polls GitHub for `sfomuseum-data-` repositories that have been updated in the last (n) hours and then runs the `wof-findingaid-populate` tool (part of the [whosonfirst/go-whosonfirst-findingaid](https://github.com/whosonfirst/go-whosonfirst-findingaid) repository) to index those repositories in both the [[findingaid]] DynamoDB table and corresponding CSV files in the `sfomuseum-findingaids` repository.

## Model

The [whosonfirst/go-whosonfirst-findingaid](https://github.com/whosonfirst/go-whosonfirst-findingaid) package defines three principal components for  findingaids:

1. Providers. This is where data is read from, for example one or more `sfomuseum-data-` repositories.
2. Producers. This is what produces a findingaid lookup table.
3. Resolvers. This is what resolves an ID to a repository (using a lookup table to do so).

## Readers

One of the principal uses for the findingaid is to use it in conjunction with the [whosonfirst/go-reader-findingaid](https://github.com/whosonfirst/go-reader-findingaid) package. For example:

```
$> ./bin/read \
	-reader-uri 'findingaid://https/static.sfomuseum.org/findingaid/?template=https://raw.githubusercontent.com/sfomuseum-data/{repo}/main/data/' \
	102527513 \

| jq '.["properties"]["wof:name"]'

"San Francisco International Airport"
```

In this example we are using a `findingaid` implementation of the [whosonfirst/go-reader.Reader](https://github.com/whosonfirst/go-reader) interface which takes as its constructor arguments:

1. The location of the findingaid resolver.
2. A URI template which the resultant repository will be applied producing a _new_ `go-reader.Reader`  constructor URI that will be used to produce a final reader implementation to "read" the input value (102527513).

It's all a bit "squirrel-y" but it works.

## See also

* https://github.com/whosonfirst/go-reader-findingaid