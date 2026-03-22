
OUT_DIR := ./run
# Use explicit Synopsys VCS binary path (from your compile log)
VCS_BIN := /usr/Synopsys/vcs/T-2022.06/linux64/bin/vcs
VCS_OPTS := -full64 -sverilog -timescale=1ns/10ps -lca -debug_access+r -kdb +define+FSDB

all: run

compile:
	mkdir -p $(OUT_DIR)
	$(VCS_BIN) $(VCS_OPTS) -f filelist.f -o $(OUT_DIR)/simv

run: compile
	cd $(OUT_DIR) ; ./simv -l sim.log

run_wave: compile
	cd $(OUT_DIR) ; ./simv +vcs+vcdpluson +fsdb_dump -l sim_wave.log -gui &

clean:
	rm -rf $(OUT_DIR) simv* *.log *.fsdb csrc DVEfiles

.PHONY: all compile run run_wave clean
