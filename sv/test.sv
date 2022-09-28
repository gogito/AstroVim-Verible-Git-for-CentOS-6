// Test class instantiates the environment and starts it.

class base_test extends uvm_test;
  int value;
  `uvm_component_utils(base_test)
  function new(string name = "base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  env                e0;
  bit [`LENGTH-1:0]  pattern    = 4'b1011;
  gen_item_seq       seq;
  other_gen_item_seq other_seq;
  virtual des_if     vif;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create the environment
    e0 = env::type_id::create("e0", this);

    // Get virtual IF handle from top level and pass it to everything
    // in env level
    if (!uvm_config_db#(virtual des_if)::get(this, "", "des_vif", vif))
      `uvm_fatal("TEST", "Did not get vif")
    uvm_config_db#(virtual des_if)::set(this, "e0.a0.*", "des_vif", vif);

    // Setup pattern queue and place into config db
    uvm_config_db#(bit [`LENGTH-1:0])::set(this, "*", "ref_pattern", pattern);

  endfunction

  virtual task reset_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("RESET PHASE", "START RESET PHASE", UVM_LOW)
    `uvm_info("RESET", "START RESET", UVM_LOW)
    apply_reset();
    `uvm_info("RESET", "FINISH RESET", UVM_LOW)
    `uvm_info("RESET PHASE", "END RESET PHASE", UVM_LOW)
    phase.drop_objection(this);
  endtask

  virtual task post_reset_phase(uvm_phase phase);
    phase.raise_objection(this);
    #1;
    `uvm_info("POST_RESET", "START POST RESET", UVM_LOW)
    `uvm_info("SAVE", "SAVE HERE", UVM_LOW)
    $save("finished_reset");
    `uvm_info("POST_RESET", "END POST RESET", UVM_LOW)
    phase.drop_objection(this);
  endtask

  virtual task main_phase(uvm_phase phase);
    phase.raise_objection(this);
    #1;
    //$restart("finished_reset");
    `uvm_info("RESTART", "RESTART HERE", UVM_LOW)
    `uvm_info("MAIN PHASE", "START MAIN PHASE", UVM_LOW)

    // if (sknobs::get_value("test.seq_en", 0)) begin
    //   `uvm_info("SEQ CHECK", "SEQ ENABLED", UVM_LOW);
    //   // Create sequence and randomize it
    //   seq = gen_item_seq::type_id::create("seq");
    //   // seq.randomize();
    //   assert(seq.randomize() with { num inside {[300:500]}; });
    //   `uvm_info("START SEQUENCE", "SEQUENCE START HERE", UVM_LOW)
    //   seq.start(e0.a0.s0);
    // end 

    // else if (sknobs::get_value("test.other_seq_en", 0)) begin
    //   `uvm_info("OTHER SEQ CHECK", "OTHER SEQ ENABLED", UVM_LOW);
    //   // Create sequence and randomize it
    //   other_seq = other_gen_item_seq::type_id::create("other_seq");
    //   assert(other_seq.randomize() with { num inside {[300:500]}; });
    //   // other_seq.randomize();
    //   `uvm_info("START SEQUENCE", "OTHER SEQUENCE START HERE", UVM_LOW)
    //   other_seq.start(e0.a0.s0);
    // end 

    $value$plusargs("Sequence=%0d", value);
    // value = 1;
    if (value == 1) begin
      `uvm_info("SEQ CHECK", "SEQ ENABLED", UVM_LOW);
      // Create sequence and randomize it
      seq = gen_item_seq::type_id::create("seq");
      // seq.randomize();
      assert (seq.randomize() with {num inside {[300 : 500]};});
      `uvm_info("START SEQUENCE", "SEQUENCE START HERE", UVM_LOW)
      seq.start(e0.a0.s0);
    end else if (value == 2) begin
      `uvm_info("OTHER SEQ CHECK", "OTHER SEQ ENABLED", UVM_LOW);
      // Create sequence and randomize it
      other_seq = other_gen_item_seq::type_id::create("other_seq");
      assert (other_seq.randomize() with {num inside {[300 : 500]};});
      // other_seq.randomize();
      `uvm_info("START SEQUENCE", "OTHER SEQUENCE START HERE", UVM_LOW)
      other_seq.start(e0.a0.s0);
    end

    #200;
    `uvm_info("MAIN PHASE", "END MAIN PHASE", UVM_LOW)
    phase.drop_objection(this);
  endtask

  virtual task apply_reset();
    vif.rstn <= 0;
    vif.in   <= 0;
    repeat (5) @(posedge vif.clk);
    vif.rstn <= 1;
    repeat (10) @(posedge vif.clk);
  endtask
endclass

class test_1011 extends base_test;
  `uvm_component_utils(test_1011)
  function new(string name = "test_1011", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    pattern = 4'b1011;
    super.build_phase(phase);
  endfunction
endclass
