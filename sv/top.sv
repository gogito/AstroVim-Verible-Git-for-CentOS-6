`define LENGTH 4
import uvm_pkg::*;
// `include "/tools/FOSS/sknobs/1.0.1_ampere_2/lib/verilog/sknobs.sv"
`include "uvm_macros.svh"
`include "dut.sv"
`include "interface.sv"
`include "package.svh"
import pkg::*;
module top;
  reg clk;
  
  always #10 clk =~ clk;
  des_if _if (clk);
  
  det_1011 u0 	( .clk(clk),
  .rstn(_if.rstn),
  .in(_if.in),
  .out(_if.out));
  
  
  initial begin
    // if (sknobs::sknobs_init(0)) begin                                                                                                                                                                                                                                                   
    //   `uvm_fatal("fc_tb", "sknobs init failed")                                                                                                                                                                                                                                         
    // end
    
    clk <= 0;
    uvm_config_db#(virtual des_if)::set(null, "uvm_test_top", "des_vif", _if);
    run_test("test_1011");
  end
endmodule