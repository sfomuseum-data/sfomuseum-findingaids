docker:
	docker buildx build --platform=linux/amd64 --no-cache=true -t sfomuseum-data-findingaid .	
