clean:
	rm -rf luarocks luarocks-2.2.0

luarocks:
	wget http://luarocks.org/releases/luarocks-2.2.0.tar.gz
	tar -xf luarocks-2.2.0.tar.gz
	cd luarocks-2.2.0 && ./configure --lua-version=5.1 --prefix=`pwd`/../luarocks && $(MAKE) bootstrap
	rm -rf luarocks-2.2.0.tar.gz

dependencies: luarocks
	luarocks/bin/luarocks install npath-adventurer-0.0-1.rockspec
	cp -r luarocks/share/lua/5.1/metalua .
	cp luarocks/lib/lua/5.1/checks.so .

build-love:
	mkdir build
	zip -9r build/npath-adventurers.love *
	cp checks.so build
