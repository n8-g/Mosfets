all: edge.bin sobel.bin erosion.bin sobel1.bin
%.bin: %.mos mc
	../compiler/mc -o $@ $<
mc:
	cd ../compiler && make
clean:
	rm -f *.bin
