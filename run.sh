vcs -full64 -sverilog +vpi -ntb_opts uvm -debug_all \
  +define+UVM_NO_DEPRECATED \
  -timescale=1ns/1ps \
  -f filelist.f \
  -l compile.log