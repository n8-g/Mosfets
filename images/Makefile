all: image.bin erosion_image.bin sobel_image.bin
%.bin: %.txt
	../makehex/makehex -b $< $@
