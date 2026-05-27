# Makefile to run generic NOC testbench with Verilator or ModelSim
# Parameterized for any topology and config

VERILATOR = verilator
VERILATOR_FLAGS = --binary --top-module generic_harness_tb_sim -Wno-fatal -Wno-WIDTH -Wno-PINMISSING -Wno-IMPLICIT -DSIMULATION --threads 4

VSIM = vsim -c
PYTHON ?= python3

# Default topology configuration
TOPOLOGY ?= router
NUM_INPUTS ?= 4
NUM_OUTPUTS ?= 4
NUM_ROWS ?= 2
NUM_COLS ?= 2
K ?= 2
N ?= 2
PACKET_COUNT ?= 1024
LOAD ?= 0.1
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
  ROUTING_TABLE_PREFIX ?= routing_tables/router_$(NUM_INPUTS)x$(NUM_OUTPUTS)/
else ifeq ($(TOPOLOGY),ring)
  ROUTING_TABLE_PREFIX ?= routing_tables/ring_$(NUM_INPUTS)/
else ifeq ($(TOPOLOGY),double_ring)
  ROUTING_TABLE_PREFIX ?= routing_tables/double_ring_$(NUM_INPUTS)/
else ifeq ($(TOPOLOGY),mesh)
  ROUTING_TABLE_PREFIX ?= routing_tables/mesh_$(NUM_ROWS)x$(NUM_COLS)/
else ifeq ($(TOPOLOGY),torus)
  ROUTING_TABLE_PREFIX ?= routing_tables/torus_$(NUM_ROWS)x$(NUM_COLS)/
else ifeq ($(TOPOLOGY),directional_torus)
  ROUTING_TABLE_PREFIX ?= routing_tables/dtorus_$(NUM_ROWS)x$(NUM_COLS)/
else ifeq ($(TOPOLOGY),butterfly)
  ROUTING_TABLE_PREFIX ?= routing_tables/butterfly_$(K)_$(N)/
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

.PHONY: all run verilator modelsim clean help gen_routing_table

all: run

run: verilator

gen_routing_table:
	@echo "--- Generating Routing Tables for $(TOPOLOGY) at $(ROUTING_TABLE_PREFIX) ---"
ifeq ($(TOPOLOGY),router)
	$(PYTHON) routing_tables/gen_router_table.py $(NUM_INPUTS) $(NUM_OUTPUTS) $(ROUTING_TABLE_PREFIX)
else ifeq ($(TOPOLOGY),ring)
	$(PYTHON) routing_tables/gen_ring_table.py $(NUM_INPUTS) $(ROUTING_TABLE_PREFIX)
else ifeq ($(TOPOLOGY),double_ring)
	$(PYTHON) routing_tables/gen_double_ring_table.py $(NUM_INPUTS) $(ROUTING_TABLE_PREFIX)
else ifeq ($(TOPOLOGY),mesh)
	$(PYTHON) routing_tables/gen_mesh_table.py $(NUM_ROWS) $(NUM_COLS) $(ROUTING_TABLE_PREFIX)
else ifeq ($(TOPOLOGY),torus)
	$(PYTHON) routing_tables/gen_torus_table.py $(NUM_ROWS) $(NUM_COLS) $(ROUTING_TABLE_PREFIX)
else ifeq ($(TOPOLOGY),directional_torus)
	$(PYTHON) routing_tables/gen_dtorus_table.py $(NUM_ROWS) $(NUM_COLS) $(ROUTING_TABLE_PREFIX)
else ifeq ($(TOPOLOGY),butterfly)
	$(PYTHON) routing_tables/gen_butterfly_table.py $(K) $(N) $(ROUTING_TABLE_PREFIX)
endif

verilator: obj_dir/Vgeneric_harness_tb_sim gen_routing_table
	@echo "--- Running Generic Testbench ($(TOPOLOGY)) in Verilator ---"
	./obj_dir/Vgeneric_harness_tb_sim

obj_dir/Vgeneric_harness_tb_sim: test/generic_harness_tb_sim.sv test/axis_topology_wrapper.sv src/*.sv src/topologies/*.sv src/fifos/*.sv test/harness/*.sv gen_routing_table FORCE
	$(VERILATOR) $(VERILATOR_FLAGS) --prefix Vgeneric_harness_tb_sim $(VERILATOR_GFLAGS) $(filter-out FORCE gen_routing_table,$^)

FORCE:

modelsim: gen_routing_table
	@echo "--- Running Generic Testbench ($(TOPOLOGY)) in ModelSim ---"
	$(VSIM) -do "set USER_DEFINED_ELAB_OPTIONS \"$(VSIM_GFLAGS)\"; do sim/generic_harness_sim.tcl; quit -f"

clean:
	rm -rf obj_dir
	rm -rf work vsim.wlf transcript

help:
	@echo "NOC Generic Testbench Runner"
	@echo ""
	@echo "Targets:"
	@echo "  make run [TOPOLOGY=...] [NUM_INPUTS=...]    - Compile and run with Verilator"
	@echo "  make verilator                              - Compile and run with Verilator"
	@echo "  make modelsim                               - Run with ModelSim"
	@echo "  make clean                                  - Clean build directories"
	@echo ""
	@echo "Parameters (and default values):"
	@echo "  TOPOLOGY             = router   (router|ring|double_ring|mesh|torus|directional_torus|butterfly)"
	@echo "  NUM_INPUTS           = 4"
	@echo "  NUM_OUTPUTS          = 4"
	@echo "  NUM_ROWS             = 2        (for mesh/torus/dtorus)"
	@echo "  NUM_COLS             = 2        (for mesh/torus/dtorus)"
	@echo "  K                    = 2        (for butterfly)"
	@echo "  N                    = 2        (for butterfly)"
	@echo "  PACKET_COUNT         = 1024"
	@echo "  LOAD                 = 0.5"
	@echo "  TIMEOUT_CYCLES       = <auto-calculated: PACKET_COUNT * 200 + 100000>"
	@echo "  ROUTING_TABLE_PREFIX = <auto-set based on topology>"
	@echo "  SERIALIZATION_FACTOR = 1"
	@echo "  CLKCROSS_FACTOR      = 1"
	@echo "  SINGLE_CLOCK         = <auto-calculated: 1 if CLKCROSS_FACTOR == 1 else 0>"
	@echo "  SERDES_IN_BUFFER_DEPTH = 4"
	@echo "  SERDES_OUT_BUFFER_DEPTH = 32"
	@echo "  SERDES_EXTRA_SYNC_STAGES = 0"
	@echo "  SERDES_FORCE_MLAB    = 0"
	@echo "  RESET_SYNC_EXTEND_CYCLES = 2"
	@echo "  RESET_NUM_OUTPUT_REGISTERS = 1"
	@echo "  PIPELINE_LINKS       = 0"
	@echo "  EXTRA_PIPELINE_LONG_LINKS = 0"
