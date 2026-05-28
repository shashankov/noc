# Makefile to run generic NOC testbench with Verilator or ModelSim
# Parameterized for any topology and config

VERILATOR ?= verilator
THREADS ?= 4
VERILATOR_FLAGS = --binary --top-module generic_harness_tb_sim -Wno-fatal -Wno-WIDTH -Wno-PINMISSING -Wno-IMPLICIT -DSIMULATION --threads $(THREADS)

VSIM = vsim -c
PYTHON ?= python3

# Default topology configuration
TOPOLOGY ?= router
SIMULATION ?= 1

# Verilator does not support compiling with Intel closed-source IPs, so it must always use SIMULATION=1.
ifeq ($(SIMULATION),0)
  ifneq ($(filter all run verilator obj_dir/Vgeneric_harness_tb_sim,$(MAKECMDGOALS)),)
    $(error Error: Verilator simulation must always be compiled with SIMULATION=1. Turn off SIMULATION (SIMULATION=0) only for the ModelSim target.)
  endif
  ifeq ($(MAKECMDGOALS),)
    $(error Error: Verilator simulation (default target) must always be compiled with SIMULATION=1. Turn off SIMULATION (SIMULATION=0) only for the ModelSim target.)
  endif
endif
NUM_INPUTS ?= 4
NUM_OUTPUTS ?= 4
NUM_ROWS ?= 2
NUM_COLS ?= 2
K ?= 2
N ?= 2
PACKET_COUNT ?= 1024
LOAD ?= 0.6
TIMEOUT_CYCLES ?= $(shell expr $(PACKET_COUNT) \* 200 + 100000)

SERIALIZATION_FACTOR ?= 1
CLKCROSS_FACTOR ?= 1
ifeq ($(CLKCROSS_FACTOR),1)
  SINGLE_CLOCK ?= 1
else
  SINGLE_CLOCK ?= 0
endif
SERDES_IN_BUFFER_DEPTH ?= 4
SERDES_OUT_BUFFER_DEPTH ?= 32
SERDES_EXTRA_SYNC_STAGES ?= 0
SERDES_FORCE_MLAB ?= 0
RESET_SYNC_EXTEND_CYCLES ?= 2
RESET_NUM_OUTPUT_REGISTERS ?= 1
PIPELINE_LINKS ?= 0
EXTRA_PIPELINE_LONG_LINKS ?= 0

# Default routing table prefix based on topology
ifeq ($(TOPOLOGY),router)
  ROUTING_TABLE_PREFIX ?= ../routing_tables/router_$(NUM_INPUTS)x$(NUM_OUTPUTS)/
else ifeq ($(TOPOLOGY),ring)
  ROUTING_TABLE_PREFIX ?= ../routing_tables/ring_$(NUM_INPUTS)/
else ifeq ($(TOPOLOGY),double_ring)
  ROUTING_TABLE_PREFIX ?= ../routing_tables/double_ring_$(NUM_INPUTS)/
else ifeq ($(TOPOLOGY),mesh)
  ROUTING_TABLE_PREFIX ?= ../routing_tables/mesh_$(NUM_ROWS)x$(NUM_COLS)/
else ifeq ($(TOPOLOGY),torus)
  ROUTING_TABLE_PREFIX ?= ../routing_tables/torus_$(NUM_ROWS)x$(NUM_COLS)/
else ifeq ($(TOPOLOGY),directional_torus)
  ROUTING_TABLE_PREFIX ?= ../routing_tables/dtorus_$(NUM_ROWS)x$(NUM_COLS)/
else ifeq ($(TOPOLOGY),butterfly)
  ROUTING_TABLE_PREFIX ?= ../routing_tables/butterfly_$(K)_$(N)/
endif

# Verilator parameter override flags
VERILATOR_GFLAGS = \
  -GTOPOLOGY='"$(TOPOLOGY)"' \
  -GNUM_INPUTS=$(NUM_INPUTS) \
  -GNUM_OUTPUTS=$(NUM_OUTPUTS) \
  -GNUM_ROWS=$(NUM_ROWS) \
  -GNUM_COLS=$(NUM_COLS) \
  -GK=$(K) \
  -GN=$(N) \
  -GPACKET_COUNT=$(PACKET_COUNT) \
  -GLOAD=$(LOAD) \
  -GTIMEOUT_CYCLES=$(TIMEOUT_CYCLES) \
  -GROUTING_TABLE_PREFIX='"$(ROUTING_TABLE_PREFIX)"' \
  -GSERIALIZATION_FACTOR=$(SERIALIZATION_FACTOR) \
  -GCLKCROSS_FACTOR=$(CLKCROSS_FACTOR) \
  -GSINGLE_CLOCK=$(SINGLE_CLOCK) \
  -GSERDES_IN_BUFFER_DEPTH=$(SERDES_IN_BUFFER_DEPTH) \
  -GSERDES_OUT_BUFFER_DEPTH=$(SERDES_OUT_BUFFER_DEPTH) \
  -GSERDES_EXTRA_SYNC_STAGES=$(SERDES_EXTRA_SYNC_STAGES) \
  -GSERDES_FORCE_MLAB=$(SERDES_FORCE_MLAB) \
  -GRESET_SYNC_EXTEND_CYCLES=$(RESET_SYNC_EXTEND_CYCLES) \
  -GRESET_NUM_OUTPUT_REGISTERS=$(RESET_NUM_OUTPUT_REGISTERS) \
  -GPIPELINE_LINKS=$(PIPELINE_LINKS) \
  -GEXTRA_PIPELINE_LONG_LINKS=$(EXTRA_PIPELINE_LONG_LINKS)

# ModelSim parameter override flags
VSIM_GFLAGS = \
  -gTOPOLOGY=$(TOPOLOGY) \
  -gNUM_INPUTS=$(NUM_INPUTS) \
  -gNUM_OUTPUTS=$(NUM_OUTPUTS) \
  -gNUM_ROWS=$(NUM_ROWS) \
  -gNUM_COLS=$(NUM_COLS) \
  -gK=$(K) \
  -gN=$(N) \
  -gPACKET_COUNT=$(PACKET_COUNT) \
  -gLOAD=$(LOAD) \
  -gTIMEOUT_CYCLES=$(TIMEOUT_CYCLES) \
  -gROUTING_TABLE_PREFIX=$(ROUTING_TABLE_PREFIX) \
  -gSERIALIZATION_FACTOR=$(SERIALIZATION_FACTOR) \
  -gCLKCROSS_FACTOR=$(CLKCROSS_FACTOR) \
  -gSINGLE_CLOCK=$(SINGLE_CLOCK) \
  -gSERDES_IN_BUFFER_DEPTH=$(SERDES_IN_BUFFER_DEPTH) \
  -gSERDES_OUT_BUFFER_DEPTH=$(SERDES_OUT_BUFFER_DEPTH) \
  -gSERDES_EXTRA_SYNC_STAGES=$(SERDES_EXTRA_SYNC_STAGES) \
  -gSERDES_FORCE_MLAB=$(SERDES_FORCE_MLAB) \
  -gRESET_SYNC_EXTEND_CYCLES=$(RESET_SYNC_EXTEND_CYCLES) \
  -gRESET_NUM_OUTPUT_REGISTERS=$(RESET_NUM_OUTPUT_REGISTERS) \
  -gPIPELINE_LINKS=$(PIPELINE_LINKS) \
  -gEXTRA_PIPELINE_LONG_LINKS=$(EXTRA_PIPELINE_LONG_LINKS)

.PHONY: all run verilator modelsim clean help gen_routing_table regress regress_clean

all: help

run: verilator

gen_routing_table:
	@echo "--- Generating Routing Tables for $(TOPOLOGY) at $(ROUTING_TABLE_PREFIX) ---"
ifeq ($(TOPOLOGY),router)
	$(PYTHON) ../routing_tables/gen_router_table.py $(NUM_INPUTS) $(NUM_OUTPUTS) $(ROUTING_TABLE_PREFIX)
else ifeq ($(TOPOLOGY),ring)
	$(PYTHON) ../routing_tables/gen_ring_table.py $(NUM_INPUTS) $(ROUTING_TABLE_PREFIX)
else ifeq ($(TOPOLOGY),double_ring)
	$(PYTHON) ../routing_tables/gen_double_ring_table.py $(NUM_INPUTS) $(ROUTING_TABLE_PREFIX)
else ifeq ($(TOPOLOGY),mesh)
	$(PYTHON) ../routing_tables/gen_mesh_table.py $(NUM_ROWS) $(NUM_COLS) $(ROUTING_TABLE_PREFIX)
else ifeq ($(TOPOLOGY),torus)
	$(PYTHON) ../routing_tables/gen_torus_table.py $(NUM_ROWS) $(NUM_COLS) $(ROUTING_TABLE_PREFIX)
else ifeq ($(TOPOLOGY),directional_torus)
	$(PYTHON) ../routing_tables/gen_dtorus_table.py $(NUM_ROWS) $(NUM_COLS) $(ROUTING_TABLE_PREFIX)
else ifeq ($(TOPOLOGY),butterfly)
	$(PYTHON) ../routing_tables/gen_butterfly_table.py $(K) $(N) $(ROUTING_TABLE_PREFIX)
endif

verilator: obj_dir/Vgeneric_harness_tb_sim gen_routing_table
	@echo "--- Running Generic Testbench ($(TOPOLOGY)) in Verilator ---"
	./obj_dir/Vgeneric_harness_tb_sim

obj_dir/Vgeneric_harness_tb_sim: generic_harness_tb_sim.sv axis_topology_wrapper.sv ../src/*.sv ../src/topologies/*.sv ../src/fifos/*.sv harness/*.sv gen_routing_table FORCE
	$(VERILATOR) $(VERILATOR_FLAGS) --prefix Vgeneric_harness_tb_sim $(VERILATOR_GFLAGS) $(filter-out FORCE gen_routing_table,$^)

FORCE:

modelsim: gen_routing_table
	@echo "--- Running Generic Testbench ($(TOPOLOGY)) in ModelSim ---"
	$(VSIM) -do "set USER_DEFINED_ELAB_OPTIONS \"$(VSIM_GFLAGS)\"; set SIMULATION $(SIMULATION); do sim/generic_harness_sim.tcl; quit -f"

clean:
	rm -rf obj_dir
	rm -rf libraries vsim.wlf transcript modelsim.ini

# ---------------------------------------------------------------------------
# Regression test suite
# ---------------------------------------------------------------------------
# REGRESS_PACKET_COUNT sets the packet count used during regression runs.
# It defaults to 4096 for thorough coverage but can be overridden at the
# command line (e.g. make regress REGRESS_PACKET_COUNT=256 for a quick smoke
# test) without affecting the global PACKET_COUNT default used by make run.
REGRESS_PACKET_COUNT ?= 65536
# Each entry in REGRESSION_CONFIGS is a unique tag used to name per-config
# log files.  The corresponding _ARGS_<tag> variable supplies the make
# overrides that define that configuration.
#
# Topologies covered
#   router            - default 4x4, then larger 8x8
#   ring              - 4-node, then 8-node
#   double_ring       - 4-node
#   mesh              - 2x2, then 4x4
#   torus             - 2x2, then 4x4
#   directional_torus - 2x2
#   butterfly         - k=2 n=2, then k=4 n=2
#
# Key parameter sweeps
#   SERIALIZATION_FACTOR=2  (mesh 2x2)
#   CLKCROSS_FACTOR=2       (router 4x4, enables async clock crossing)
# ---------------------------------------------------------------------------

REGRESSION_CONFIGS := \
  router_4x4 \
  router_8x8 \
  ring_4 \
  ring_8 \
  double_ring_4 \
  mesh_2x2 \
  mesh_4x4 \
  torus_2x2 \
  torus_4x4 \
  dtorus_2x2 \
  butterfly_k2_n2 \
  butterfly_k4_n2 \
  router_4x4_ser2 \
  router_4x4_clkcross2

# Per-configuration make arguments
_ARGS_router_4x4           := TOPOLOGY=router NUM_INPUTS=4 NUM_OUTPUTS=4
_ARGS_router_8x8           := TOPOLOGY=router NUM_INPUTS=8 NUM_OUTPUTS=8
_ARGS_ring_4               := TOPOLOGY=ring   NUM_INPUTS=4 NUM_OUTPUTS=4 LOAD=0.4
_ARGS_ring_8               := TOPOLOGY=ring   NUM_INPUTS=8 NUM_OUTPUTS=8 LOAD=0.1
_ARGS_double_ring_4        := TOPOLOGY=double_ring NUM_INPUTS=4 NUM_OUTPUTS=4
_ARGS_mesh_2x2             := TOPOLOGY=mesh   NUM_ROWS=2 NUM_COLS=2 NUM_INPUTS=4 NUM_OUTPUTS=4
_ARGS_mesh_4x4             := TOPOLOGY=mesh   NUM_ROWS=4 NUM_COLS=4 NUM_INPUTS=16 NUM_OUTPUTS=16
_ARGS_torus_2x2            := TOPOLOGY=torus  NUM_ROWS=2 NUM_COLS=2 NUM_INPUTS=4 NUM_OUTPUTS=4
_ARGS_torus_4x4            := TOPOLOGY=torus  NUM_ROWS=4 NUM_COLS=4 NUM_INPUTS=16 NUM_OUTPUTS=16
_ARGS_dtorus_2x2           := TOPOLOGY=directional_torus NUM_ROWS=2 NUM_COLS=2 NUM_INPUTS=4 NUM_OUTPUTS=4
_ARGS_butterfly_k2_n2      := TOPOLOGY=butterfly K=2 N=2 NUM_INPUTS=4 NUM_OUTPUTS=4
_ARGS_butterfly_k4_n2      := TOPOLOGY=butterfly K=4 N=2 NUM_INPUTS=16 NUM_OUTPUTS=16
_ARGS_router_4x4_ser2      := TOPOLOGY=router NUM_INPUTS=4 NUM_OUTPUTS=4 SERIALIZATION_FACTOR=2
_ARGS_router_4x4_clkcross2 := TOPOLOGY=router NUM_INPUTS=4 NUM_OUTPUTS=4 CLKCROSS_FACTOR=2

REGRESS_LOG_DIR := regress_logs

# Run the full regression suite sequentially.
# Each configuration is compiled and executed in isolation (obj_dir is
# removed between runs so stale artifacts cannot mask failures).
# A summary table is printed at the end; the rule exits non-zero if any
# configuration failed.
# regress:
# 	@mkdir -p $(REGRESS_LOG_DIR)
# 	@echo ""
# 	@echo "================================================================"
# 	@echo "  NOC Regression Suite  ($(words $(REGRESSION_CONFIGS)) configurations)"
# 	@echo "================================================================"
# 	@echo ""
# 	@PASS=0; FAIL=0; RESULTS=""; \
# 	for cfg in $(REGRESSION_CONFIGS); do \
# 	  args=$$($(MAKE) --no-print-directory _regress_print_args_$$cfg 2>/dev/null); \
# 	  logfile=$(REGRESS_LOG_DIR)/$$cfg.log; \
# 	  printf "  [%-28s] " "$$cfg"; \
# 	  $(MAKE) --no-print-directory clean > /dev/null 2>&1; \
#     start_time=$$(date +%s); \
# 	  if $(MAKE) --no-print-directory verilator $$args \
# 	       PACKET_COUNT=$(REGRESS_PACKET_COUNT) \
# 	       > $$logfile 2>&1; then \
# 	    end_time=$$(date +%s); \
#       elapsed=$$(($$end_time - $$start_time)); \
# 	    echo "PASS ($$elapsed s)"; \
# 	    PASS=$$((PASS+1)); \
# 	    RESULTS="$$RESULTS PASS:$$cfg"; \
# 	  else \
# 	    echo "FAIL  (see $$logfile)"; \
# 	    FAIL=$$((FAIL+1)); \
# 	    RESULTS="$$RESULTS FAIL:$$cfg"; \
# 	  fi; \
# 	done; \
# 	echo ""; \
# 	echo "----------------------------------------------------------------"; \
# 	echo "  Results: $$PASS passed, $$FAIL failed"; \
# 	echo "----------------------------------------------------------------"; \
# 	echo ""; \
# 	if [ $$FAIL -ne 0 ]; then exit 1; fi

regress:
	@mkdir -p $(REGRESS_LOG_DIR)
	@GREEN="\033[0;32m"; \
	 RED="\033[0;31m"; \
	 YELLOW="\033[0;33m"; \
	 CYAN="\033[0;36m"; \
	 NC="\033[0m"; \
	 echo ""; \
	 printf "$${CYAN}================================================================$${NC}\n"; \
	 printf "$${CYAN}  NoC Regression Suite  ($(words $(REGRESSION_CONFIGS)) configurations)$${NC}\n"; \
	 printf "$${CYAN}================================================================$${NC}\n"; \
	 echo ""; \
	 PASS=0; FAIL=0; RESULTS=""; \
	 for cfg in $(REGRESSION_CONFIGS); do \
	 	args=$$($(MAKE) --no-print-directory _regress_print_args_$$cfg 2>/dev/null); \
	 	logfile=$(REGRESS_LOG_DIR)/$$cfg.log; \
	 	printf "  [%-28s] " "$$cfg"; \
	 	$(MAKE) --no-print-directory clean > /dev/null 2>&1; \
	 	start_time=$$(date +%s); \
	 	$(MAKE) --no-print-directory verilator $$args \
	 	       PACKET_COUNT=$(REGRESS_PACKET_COUNT) \
	 	       > $$logfile 2>&1; \
	 	status=$$?; \
	 	duration=$$(( $$(date +%s) - start_time )); \
	 	if [ $$status -eq 0 ]; then \
	 		printf "$${GREEN}PASS$${NC}  ($${YELLOW}$${duration}s$${NC})\n"; \
	 		PASS=$$((PASS+1)); \
	 		RESULTS="$$RESULTS PASS:$$cfg"; \
	 	else \
	 		printf "$${RED}FAIL$${NC}  (see $$logfile) ($${YELLOW}$${duration}s$${NC})\n"; \
	 		FAIL=$$((FAIL+1)); \
	 		RESULTS="$$RESULTS FAIL:$$cfg"; \
	 	fi; \
	 done; \
	 echo ""; \
	 printf "$${CYAN}----------------------------------------------------------------$${NC}\n"; \
	 if [ $$FAIL -eq 0 ]; then \
	 	printf "  Results: $${GREEN}$$PASS passed$${NC}, $$FAIL failed\n"; \
	 else \
	 	printf "  Results: $$PASS passed, $${RED}$$FAIL failed$${NC}\n"; \
	 fi; \
	 printf "$${CYAN}----------------------------------------------------------------$${NC}\n"; \
	 echo ""; \
	 if [ $$FAIL -ne 0 ]; then exit 1; fi

# Helper targets so the shell loop above can retrieve per-config args
# without resorting to eval tricks.
$(foreach cfg,$(REGRESSION_CONFIGS),\
  $(eval .PHONY: _regress_print_args_$(cfg)) \
  $(eval _regress_print_args_$(cfg):; @echo "$(_ARGS_$(cfg))"))

# Remove all regression log files.
regress_clean:
	rm -rf $(REGRESS_LOG_DIR)

help:
	@echo "NOC Generic Testbench Runner"
	@echo ""
	@echo "Targets:"
	@echo "  make run [TOPOLOGY=...] [NUM_INPUTS=...]    - Compile and run with Verilator"
	@echo "  make verilator                              - Compile and run with Verilator"
	@echo "  make modelsim                               - Run with ModelSim"
	@echo "  make clean                                  - Clean build directories"
	@echo "  make regress                                - Run full regression suite"
	@echo "  make regress_clean                          - Remove regression log files"
	@echo ""
	@echo "Parameters (and default values):"
	@echo "  TOPOLOGY                    = router   (router|ring|double_ring|mesh|torus|directional_torus|butterfly)"
	@echo "  NUM_INPUTS                  = 4"
	@echo "  NUM_OUTPUTS                 = 4"
	@echo "  NUM_ROWS                    = 2        (for mesh/torus/dtorus)"
	@echo "  NUM_COLS                    = 2        (for mesh/torus/dtorus)"
	@echo "  K                           = 2        (for butterfly)"
	@echo "  N                           = 2        (for butterfly)"
	@echo "  PACKET_COUNT                = 1024"
	@echo "  LOAD                        = 0.5"
	@echo "  TIMEOUT_CYCLES              = <auto-calculated: PACKET_COUNT * 200 + 100000>"
	@echo "  ROUTING_TABLE_PREFIX        = <auto-set based on topology>"
	@echo "  SERIALIZATION_FACTOR        = 1"
	@echo "  CLKCROSS_FACTOR             = 1"
	@echo "  SINGLE_CLOCK                = <auto-calculated: 1 if CLKCROSS_FACTOR == 1 else 0>"
	@echo "  SERDES_IN_BUFFER_DEPTH      = 4"
	@echo "  SERDES_OUT_BUFFER_DEPTH     = 32"
	@echo "  SERDES_EXTRA_SYNC_STAGES    = 0"
	@echo "  SERDES_FORCE_MLAB           = 0"
	@echo "  RESET_SYNC_EXTEND_CYCLES    = 2"
	@echo "  RESET_NUM_OUTPUT_REGISTERS  = 1"
	@echo "  PIPELINE_LINKS              = 0"
	@echo "  EXTRA_PIPELINE_LONG_LINKS   = 0"
	@echo "  SIMULATION                  = 1        (for ModelSim only: set to 0 to compile with Intel FPGA IPs and libraries)"
