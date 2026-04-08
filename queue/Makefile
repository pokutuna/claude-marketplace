.PHONY: test lint check

test:
	bats test/queue.bats

lint:
	checkbashisms bin/queue.sh

check: lint test
