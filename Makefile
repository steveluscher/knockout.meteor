compile:
	./node_modules/coffee-script/bin/coffee -o ./build/ -c ./src/*.coffee
	cp ./build/*.js ./examples/dynamic_finders/client/
	cp ./build/*.js ./examples/todo_list/client/

watch:
	./node_modules/coffee-script/bin/coffee -o ./build/ -w ./src/*.coffee &
	./node_modules/coffee-script/bin/coffee -o ./examples/dynamic_finders/client/ -w ./src/*.coffee &
	./node_modules/coffee-script/bin/coffee -o ./examples/todo_list/client/ -w ./src/*.coffee;