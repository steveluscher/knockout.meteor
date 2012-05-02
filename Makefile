compile:
	./node_modules/coffee-script/bin/coffee -o ./build/ -c ./src/*.coffee
	cp ./build/*.js ./example/client/

watch:
	./node_modules/coffee-script/bin/coffee -o ./build/ -w ./src/*.coffee &
	./node_modules/coffee-script/bin/coffee -o ./example/client/ -w ./src/*.coffee;