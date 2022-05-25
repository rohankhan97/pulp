class cpi_base_seq extends uvm_sequence;
	`uvm_object_utils(cpi_base_seq)

	uvm_event_pool my_event_pool;

	uvm_event FRAME_EVT  = uvm_event_pool::get_global("FRAME_EVT");
	cpi_frame_item current_item = cpi_frame_item::type_id::create("current_item");

	function new(string name="cpi_base_seq");
		super.new(name);
	endfunction

	function cpi_frame_item get_current_item_copy();
		cpi_frame_item current_item_copy = cpi_frame_item::type_id::create("current_item_copy");
		current_item_copy.pdata      = current_item.pdata; 
        current_item_copy.lat_cycles = current_item.lat_cycles;
        current_item_copy.frame_id   = current_item.frame_id;
		return current_item_copy;
	endfunction : get_current_item_copy

	virtual task body();
		for (int i = 0; i < TRANSACTIONS; i++) begin
			cpi_frame_item m_item = cpi_frame_item::type_id::create("m_item");
			`uvm_info(`gfn, "Waiting for the trigger event", UVM_MEDIUM);
			FRAME_EVT.wait_ptrigger();
			`uvm_info(`gfn, "Received trigger event", UVM_MEDIUM);
			start_item(m_item);
			m_item.randomize();
			current_item = m_item;
			FRAME_EVT.reset();
			finish_item(m_item);
		end
	endtask : body
endclass