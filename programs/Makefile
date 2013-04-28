all: edge.bin sobel.bin erosion.bin sobel1.bin
%.bin: %.n8 n8c
	../compiler/n8c -o $@ $<
n8c:
	cd ../compiler && make
clean:
	rm -f *.bin
