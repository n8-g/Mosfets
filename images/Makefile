all: tools image.bin erosion_image.bin sobel_image.bin mario.bin sword.bin
%.bin: %.png
	../mosconv/mosconv $< $@
	../makehex/makehex -r -b $@ $@.txt
%.bin: %.mosimg
	../makehex/makehex -b $< $@
	
tools:
	cd ../mosconv/ && make
	cd ../makehex/ && make

clean:
	rm -f *.bin