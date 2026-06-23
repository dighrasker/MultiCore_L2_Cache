# Makefile for VCS Simulation

# Tool
VCS = vcs

# Flags
FLAGS = -sverilog -debug_acc+all +incdir+verilog +incdir+include

# Source files - add all your design and testbench files here
SRC = verilog/L2Cache.sv \
      verilog/memDP.sv \
      verilog/mshr.sv \
      verification/tb_initial.sv
# Top-level testbench module name
TOP = tb

# Output executable
OUT = sim.out

# Default target: compile and run
all: compile run

compile:
	$(VCS) $(FLAGS) $(SRC) -top $(TOP) -o $(OUT)

run:
	./$(OUT)

# Run with VCD dump (add $dumpfile/$dumpvars to your TB, or use this flag)
waves:
	./$(OUT) -ucli -do "dump -file dump.vcd -type VCD; run; exit"

clean:
	rm -f $(OUT) dump.vcd
	rm -rf csrc simv.daidir ucli.key

.PHONY: all compile run waves clean