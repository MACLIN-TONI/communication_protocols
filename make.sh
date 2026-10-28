#!/bin/bash

dut=$1

if [ -z "$dut" ]; then
    echo "Usage: ./make.sh <dut_name>"
    exit 1
fi

mkdir -p "$dut"/{rtl,tb,sim,docs,waves}

cd "$dut" || exit 1

touch "rtl/$dut.v"
touch "tb/tb_$dut.v"

cat > Makefile <<EOF
DUT ?= $dut

RTL = rtl/\$(DUT).v
TB = tb/tb_\$(DUT).v
TOP = tb_\$(DUT)
SIM = sim/sim.out
WAVE = waves/dump.vcd
LOG = docs/\$(DUT).log

compile:
	iverilog -g2012 -o \$(SIM) \$(RTL) \$(TB)

run: compile
	vvp \$(SIM) | tee \$(LOG)

wave: run
	gtkwave \$(WAVE) &

check: run
	@echo "---FAILURES---"
	@grep "FAIL" \$(LOG) || echo "NONE"
	@echo "---SUMMARY---"
	@grep "summary\|PASS\|FAIL" \$(LOG) | tail -2

clean:
	rm -f \$(SIM) \$(WAVE) \$(LOG)

.PHONY: compile run wave check clean
EOF