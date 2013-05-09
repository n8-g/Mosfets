all: edge.bin sobel.bin erosion.bin sobel1.bin sobelh.bin sobelv.bin
%.bin: %.mos mosc
	../compiler/mosc -o $@ $<
mosc:
	cd ../compiler && make
clean:
	rm -f *.bin
