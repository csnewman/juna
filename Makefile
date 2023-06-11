build-chip:
	yosys -p "plugin -i systemverilog" -p "read_systemverilog blackice.sv" -p "flatten" -p "proc" -p "tribuf" -p "opt -full" -p "memory" -p "opt -full" -p "fsm" -p "opt -full" -p "synth_ice40 -top blackice -json chip.json"
	# yosys -p "plugin -i systemverilog" -p "read_systemverilog blackice.sv" -p "flatten" -p "opt -full" -p "memory"  -p "opt -full" -p "fsm" -p "opt -full" -p "techmap" -p "opt -full" -p "synth_ice40 -top blackice -json chip.json"

build: build-chip
	nextpnr-ice40 --hx8k  --package tq144:4k --json chip.json --pcf blackice-ii.pcf --asc chip.asc --freq 50
	icepack chip.asc chip.bin

gui: build-chip
	nextpnr-ice40 --hx8k  --package tq144:4k --json chip.json --pcf blackice-ii.pcf --freq 50 --gui

upload:
	./swtool upload /dev/ttyUSB0 chip.bin

run:
	./swtool shell /dev/ttyUSB0

clean:
	$(RM) -f chip.json chip.asc chip.bin
