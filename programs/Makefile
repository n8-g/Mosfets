all: edge.bin sobel.bin erosion.bin
%.bin: %.n8
	../compiler/n8c -o $@ $<

clean:
	rm -f *.bin
