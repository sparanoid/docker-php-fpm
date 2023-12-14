all: build

build:
	docker build --build-arg BASE_TAG=8-fpm -t sparanoid/php-fpm:8-latest .
	docker build --build-arg BASE_TAG=7.4-fpm -t sparanoid/php-fpm:7.4-latest .

# Usage: make build tag=8
buildx:
	docker build --build-arg BASE_TAG=$(tag)-fpm -t sparanoid/php-fpm:$(tag)-latest .

# Usage: make bake tag=8-fpm
bake:
	BASE_TAG=$(tag) docker buildx bake build-all --push

run:
	docker run --rm -it --name php-fpm sparanoid/php-fpm:latest

up:
	docker-compose down --remove-orphans && docker-compose up -d --build

push:
	docker push sparanoid/php-fpm:8-latest
	docker push sparanoid/php-fpm:7.4-latest

stop:
	docker rm -f php-fpm

clean:
	docker rmi sparanoid/php-fpm:latest
