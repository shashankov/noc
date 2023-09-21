# Simple Intel FPGA Optimized NoC

## NoC
### Generic NoC Parameters
| Parameter | Description |
| --------: | :---------- |
| DEST_WIDTH | Width of the destination input (can be larger than actual destination, only the lowest bits are used for destination decoding)
| FLIT_WIDTH | Data width of the router |
| FLIT_BUFFER_DEPTH | Input flit buffer depth |
| ROUTER_PIPELINE_OUTPUT | Adds an extra pipeline stage at the output of routers |
| ROUTER_DISABLE_SELFLOOP | Disables path from input i to output i in each router |
| ROUTER_FORCE_MLAB | Forces the flit buffers in routers to use MLABs (LUTRAM) instead of M20Ks (BRAM) (Advanced) |

### Routing Table Generation

`routing_tables/` contains scripts to generate routing tables based on X-Y dimension ordered routing for mesh and shortest-path routing for Double-Ring and Ring networks.

Usage:
- Mesh: `./gen_mesh_table.py <num_rows> <num_cols> <file_prefix>`
- Double Ring: `./gen_double_ring_table.py <num_routers> <file_prefix>`
- Ring: `./gen_ring_table.py <num_routers> <file_prefix>`

### NoC Topologies

#### Mesh NoC (mesh.sv)

Describes a Mesh NoC using the [router interface](#router-interface) for IO pairs.

##### Mesh Specific Parameters

| Parameter | Description |
| --------: | :---------- |
| NUM_ROWS | Number of rows in the mesh |
| NUM_COLS | Number of columns in the mesh |
| ROUTING_TABLE_PREFIX | Prefix of the location of hex files containing the routing tables. Tables follow the format `prefix/i_j.hex` for router at row i and column j |

#### (Double-)Ring NoC ((double_)ring.sv)

Describes a (double-)ring NoC using the [router interface](#router-interface) for IO pairs.

##### (Double-)Ring Specific Parameters
Note: The ROUTER_DISABLE_SELFLOOP option is removed from the ring topology since it does not make sense without IO pairs as in a ring.

| Parameter | Description |
| --------: | :---------- |
| NUM_ROUTERS | Number of routers in the ring |
| ROUTING_TABLE_PREFIX | Prefix of the location of hex files containing the routing tables. Tables follow the format `prefix/i.hex` for router i |

### Router (router.sv)

Describes a parametrizable router featuring input-independent output-based routing table for deterministic routing, virtual links enabled (ensures packets do not get interrupted), and full crossbar support. Uses wormhole routing and credit-based flow control.

#### Router Interface

| Signal | I/O | Description |
| --------: | :-: | :---------- |
|clk | I | Clock |
|rst_n | I | Synchronous active-low reset|
|||
|data_in     |I|Flit Data|
|dest_in     |I|Destination|
|is_tail_in  |I|If the flit is the tail flit|
|send_in     |I|Push (Router must accept - credit-based flow control)|
|credit_out  |I|Send credits|
|||
|data_out    |O|Flit Data|
|dest_out    |O|Destination|
|is_tail_out |O|If the flit is the tail flit|
|send_out    |O|Push (Output must accept - credit-based flow control)|
|credit_in   |I|Receive credits|

#### Parameters

| Parameter | Description |
| --------: | :---------- |
| NOC_NUM_ENDPOINTS | Number of endpoints in the NoC the router is a part of |
| ROUTING_TABLE_HEX | Location hex file containing the routing table loaded in using readmemh |
| NUM_INPUTS | Number of inputs of the router |
| NUM_OUTPUTS | Number of outputs of the router |
| DEST_WIDTH | Width of the destination input (can be larger than actual destination, only the lowest bits are used for destination decoding)
| FLIT_WIDTH | Data width of the router |
| FLIT_BUFFER_DEPTH | Input flit buffer depth |
| PIPELINE_OUTPUT | Adds an extra pipeline stage at the output of the router |
| DISABLE_SELFLOOP | Disables path from input i to output i, useful in a mesh NoC |
| FORCE_MLAB | Forces the flit buffers to use MLABs (LUTRAM) instead of M20Ks (BRAM) (Advanced) |

## AXI-Stream NoC Wrapper

This repo also provides an AXI-Stream wrapper that implements data width conversion with clock crossing along with providing a simple AXI-Stream interface to the NoC. It contains shims to convert the credit-based NoC ports into AXI-Stream through a Dual-Clock Asynchronous FIFO.

### Generic Parameters and Interface Description

NoC Topology specific parameters are same as in the [NoC section](#noc) and not repeated here.

#### AXI-S NoC Interface
| Signal | I/O | Description |
| -----: | :-: | :---------- |
|clk_noc         | I | NoC clock domain |
|clk_usr         | I | User clock domain |
|rst_n           | I | Asynchronous active-low reset |
| | |
|axis_in_tvalid  | I | Signals that the input is driving a valid transfer. A transfer takes place with both tvalid and tready are asserted |
|axis_in_tready  | O | Signals that the NoC is ready to accept data |
|axis_in_tdata   | I | Primary payload containing a flit |
|axis_in_tlast   | I | Indicated the boundary of a packet |
|axis_in_tid     | I | Data stream identifier |
|axis_in_tdest   | I | Routing information for the data stream |
| | |
|axis_out_tvalid | O | Signals that the NoC is driving a valid transfer. A transfer takes place with both tvalid and tready are asserted |
|axis_out_tready | I | Signals that the user is ready to accept data |
|axis_out_tdata  | O | Primary payload containing a flit |
|axis_out_tlast  | O | Indicated the boundary of a packet |
|axis_out_tid    | O | Data stream identifier |
|axis_out_tdest  | O | Routing information for the data stream |

#### Generic Parameters
| Parameter | Description |
| --------: | :---------- |
| RESET_SYNC_EXTEND_CYCLES  | Specifies the number of cycles to extend the synchronized reset for (may be beneficial to debounce or depending on how the reset is generated) |
| TID_WIDTH                 | Width of AXI-Stream tid signal |
| TDEST_WIDTH               | Width of AXI-Stream tdest signal |
| TDATA_WIDTH               | Width of AXI-Stream tdata signal |
| SERIALIZATION_FACTOR      | Factor to serialize in the user clock domain (doesn't use memory bits) |
| CLKCROSS_FACTOR           | Factor to serialize while crossing from the user to the NoC clock domain (uses mixed-width DC FIFO)  |
| SINGLE_CLOCK              | (0 / 1) Specfies whether the NoC and user clock are the same (uses single-clock FIFO instead of dual-clock FIFO) |
| SERDES_IN_BUFFER_DEPTH    | Serializer buffer depth (in units of TDATA_WIDTH words) |
| SERDES_OUT_BUFFER_DEPTH   | Deserializer buffer depth (in units of TDATA_WIDTH words) |
| SERDES_EXTRA_SYNC_STAGES  | Asynchronous FIFO extra metastability synchronization stages (-2 disables synchronization and may be used for synchronized clocks) |
| SERDES_FORCE_MLAB         | Forces the buffers in the serdes modules to use MLABs (LUTRAM) instead of M20Ks (BRAM) if possible (mixed-width dual-clock FIFO does not support this) |
| | |
| FLIT_BUFFER_DEPTH         | See [NoC parameters](#generic-noc-parameters)
| ROUTING_TABLE_PREFIX      | See [NoC parameters](#generic-noc-parameters)
| ROUTER_PIPELINE_OUTPUT    | See [NoC parameters](#generic-noc-parameters)
| ROUTER_FORCE_MLAB         | See [NoC parameters](#generic-noc-parameters)

### AXI-S Shims (axis_serdes_shims.sv)

Contain modules `axis_serializer_shim_in` and `axis_deserializer_shim_out` which form the input and output shims respectively. Parameters are forwarded and can be seen in the top-level [AXI-S NoC parameters](#generic-parameters)

## Miscellaneous

- `test_harness`: Contains traffic generator and checker for the NoC with AXI-Stream wrapper.
- `testbench`: Contains testbench files for various components in the repository.
- `sim`: Containes files and tcl scripts required to perform a Modelsim simulation of the testbenches.