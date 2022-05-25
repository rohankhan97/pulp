typedef class io_mux_simple_drive_seq; ///< Sequence to drive a signal  withou pull-up/down

class io_mux_base_seq extends uvm_sequence;
  `uvm_object_utils(io_mux_base_seq)
  `uvm_object_new
  task body();
    `uvm_fatal(`gtn, "Need to override body when you extend from this class.");
  endtask
endclass

class io_mux_simple_drive_seq #(parameter int unsigned NUM_SIGNALS) extends io_mux_base_seq;
  rand bit value;
  rand int unsigned signal_idx;

  constraint sig_idx_limit {
    signal_idx < NUM_SIGNALS;
  }

  `uvm_object_param_utils(io_mux_simple_drive_seq#(NUM_SIGNALS))
  `uvm_object_new
  io_mux_seq_item item;
  task body();
    `uvm_do_with(item,
      {value == local::value; signal_idx == local::signal_idx; tx_en == 1; pu_en == 0; pd_en == 0;} )
  endtask
endclass

class io_mux_no_drive_seq #(parameter int unsigned NUM_SIGNALS) extends io_mux_base_seq;
  rand int unsigned signal_idx;

  constraint sig_idx_limit {
    signal_idx < NUM_SIGNALS;
  }

  `uvm_object_param_utils(io_mux_no_drive_seq#(NUM_SIGNALS))
  `uvm_object_new
    io_mux_seq_item item;
  task body();
    `uvm_do_with(item,
      {signal_idx == local::signal_idx; value == 0; tx_en == 0; pu_en == 0; pd_en == 0;} )
  endtask
endclass
