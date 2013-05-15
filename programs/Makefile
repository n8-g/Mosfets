all: edge_loop.bin edge.bin sobel.bin erosion.bin sobel1.bin sobelh.bin sobelv.bin sobel_loop.bin erosion_loop.bin
%.bin: %.mos mosc
	../compiler/mosc -o $@ $<
mosc:
	cd ../compiler && make
clean:
	rm -f *.bin
