# UVM Environment for Multi-Core L2 Cache

This repository delivers a complete UVM-based verification environment for a write-back, multi-core L2 cache tailored to a 32-bit RISC-V system with an AXI4-Lite DRAM interface. Beyond the core cache features, the testbench layers in randomized stimulus, self-checking scoreboards, assertion-driven coverage and flexible configuration options to rigorously exercise coherence and corner-case behavior. Through this project, I mastered advanced SystemVerilog design patterns, deepened my understanding of the AXI4-Lite protocol and gained hands-on experience building end-to-end UVM test environments.


## 🔧 Cache Features

- **Shared Multi-Core Architecture**  
  A single L2 cache instance services a parameterizable number of processor cores, with proper logic to manage requests without contention

- **MESI Coherence Protocol**  
  Implements the full Modified-Exclusive-Shared-Invalid state machine to coordinate data sharing and invalidations across all L1 caches.

- **Non-Blocking Miss Handling**  
  Miss Status Holding Registers (MSHRs) allow multiple outstanding cache misses, preventing pipeline stalls on subsequent hits.

- **Configurable Parameters**  
  Easily tailor core count, associativity (ways), cache size, line width, and number of MSHRs via `define` macros to match varied system requirements.

- **AXI4-Lite DRAM Interface**  
  Exposes a simplified AXI4-Lite slave port for memory-mapped cache line fills and write-backs, ensuring low-latency, easy integration with common DRAM controllers. Dirty cache lines are retained locally and only written back to DRAM on eviction, drastically reducing external write traffic and improving overall throughput.

- **True-LRU Eviction Logic**  
  Employs an accurate replacement scheme that utilizes true LRU behavior, optimized for hit-rate performance.

- **Snooping Mechanism**  
  Listens to peer cache transactions on the coherence bus to detect remote reads/writes and trigger invalidations or data shares as needed.



## Current Update
Next Steps: Refine Testbench in UVM environment for more thorough testing
