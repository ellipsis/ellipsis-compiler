#
# ellipsis-compiler - shell script package manager
#
##############################################################################

all: test

##############################################################################

tag:
	@sed -e 's/^ELLIPSIS_XVERSION=.*$$/ELLIPSIS_XVERSION="$(version)"/'\
		src/version.bash > src/version.bash.tmp &&\
		mv src/version.bash.tmp src/version.bash
	@git add src/version.bash
	@git commit -m v$(version)
	@git tag v$(version)

##############################################################################

test: deps/bats/bin/bats deps/ellipsis
	@deps/bats/bin/bats test $(TEST_OPTS)

##############################################################################

deps/ellipsis:
	@mkdir -p deps
	@export ELLIPSIS_PATH="$$(pwd)/deps/ellipsis";\
		curl -Ls ellipsis.sh | sh

##############################################################################

deps/bats/bin/bats:
	@mkdir -p deps
	git clone --depth 1 git://github.com/sstephenson/bats.git deps/bats

##############################################################################

.PHONY: all tag test

##############################################################################
