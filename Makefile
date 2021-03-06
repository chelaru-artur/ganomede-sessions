BUNYAN_LEVEL?=1000
SHELL = /bin/bash -o pipefail

all: install test

check: install
	./node_modules/.bin/eslint src/
	./node_modules/.bin/coffeelint -q src tests

test: check
	./node_modules/.bin/mocha -b --recursive --compilers coffee:coffee-script/register tests | ./node_modules/.bin/bunyan -l ${BUNYAN_LEVEL}

coverage: test
	@mkdir -p doc

	@# coverage using istanbul
	./node_modules/.bin/istanbul cover --dir doc ./node_modules/.bin/_mocha -- --recursive --compilers coffee:coffee-script/register tests
	@echo "coverage exported to doc/lcov-report/index.html"

run: check
	node index.js | ./node_modules/.bin/bunyan -l ${BUNYAN_LEVEL}

start-daemon:
	node_modules/.bin/forever start index.js

stop-daemon:
	node_modules/.bin/forever stop index.js

install: node_modules

node_modules: package.json
	npm install
	@touch node_modules

clean:
	rm -fr node_modules

docker-prepare:
	@mkdir -p doc
	docker-compose up -d --no-recreate redisSessions redisAuth

docker-run: docker-prepare
	docker-compose run --rm app make run BUNYAN_LEVEL=${BUNYAN_LEVEL}

docker-test: docker-prepare
	docker-compose run --rm app make test BUNYAN_LEVEL=${BUNYAN_LEVEL}

docker-coverage: docker-prepare
	docker-compose run --rm app make coverage
