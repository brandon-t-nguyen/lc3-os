as=lc3as

all:
	find ./src -iname "*.asm" -type f -exec echo "//////////" \; -exec echo "assembling '{}'" \; -exec $(as) {} \;
	#find ./src -iname "*.asm" -type f -exec echo "assembling '{}'" \;

pretty:
	rm -r *.bin *.hex *.lst

clean:
	rm -r *.bin *.hex *.lst *.obj *.sym