all:
	cd images && make clean && make
	cd programs && make clean && make

prog:
	cd fpga && make
