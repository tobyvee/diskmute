.PHONY: test install uninstall install-bats clean

test: install-bats
	sudo bats -p --verbose-run diskmute_test.bats

install:
	sudo cp diskmute.sh /usr/local/bin/diskmute
	chmod +x /usr/local/bin/diskmute

uninstall:
	sudo rm /usr/local/bin/diskmute

install-bats:
	@which bats > /dev/null || (echo "Installing bats..." && brew install bats-core)

clean:
	rm -rf /tmp/test_volume