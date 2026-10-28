DUT ?= UART

RTL = rtl/$(DUT).v rtl/UART_TX.v rtl/synchronizer.v rtl/UART_RX.v
TB = tb/tb_$(DUT).v tb/tb_UART_TX.v tb/tb_synchronizer.v tb/tb_UART_RX.v

TOP = tb_$(DUT)
SIM = sim/sim.out
WAVE = waves/dump.vcd
LOG = docs/$(DUT).log

compile:
	iverilog -g2012 -o $(SIM) $(RTL) $(TB)

run: compile
	vvp $(SIM) | tee $(LOG)

wave: run
	gtkwave $(WAVE) &

check: run
	@echo "---FAILURES---"
	@grep "FAIL" $(LOG) || echo "NONE"
	@echo "---SUMMARY---"
	@grep "summary\|PASS\|FAIL" $(LOG) | tail -2

clean:
	rm -f $(SIM) $(WAVE) $(LOG)

.PHONY: compile run wave check clean
