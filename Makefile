.PHONY: test install-bats clean

test: install-bats
	sudo bats -p --verbose-run diskmute_test.bats

install-bats:
	@which bats > /dev/null || (echo "Installing bats..." && brew install bats-core)

clean:
	rm -rf /tmp/test_volume