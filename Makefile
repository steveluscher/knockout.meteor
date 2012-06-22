compile:
	./node_modules/coffee-script/bin/coffee -o ./build/ -c ./src/*.coffee
	cp ./build/*.js ./examples/lib/

watch:
	./node_modules/coffee-script/bin/coffee -o ./build/ -w ./src/*.coffee &
	./node_modules/coffee-script/bin/coffee -o ./examples/lib/ -w ./src/*.coffee;
