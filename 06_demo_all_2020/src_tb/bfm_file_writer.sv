//--------------------------------------------------------------------------------
// bfm_file_writer
//--------------------------------------------------------------------------------

module bfm_file_writer
	#(
	parameter 
		G_NUM_BITS			= 32,
		G_NUM_CYCLES_GAP	= 4
	)
	(  
		input 							clk,
		input    						data_vld,
		input    	[G_NUM_BITS-1:0]	data,
		output reg						data_rdy
    );

	`define NULL 0  
	
	integer	file_handler;
	
	integer gap_count = 0;
	
	initial begin
		data_rdy		= 1'b1;
		
		file_handler	= $fopen( "sim_output.log", "w");
		
		if (file_handler == `NULL) begin
			$display("%m file handle was NULL");
			$finish;
		end		
	end	

	
	
	always @( posedge clk )
	begin
	
		if ( gap_count > 0 ) 
		begin
			data_rdy		= 1'b0;
		
			gap_count 		= gap_count - 1;
		end
		else
		begin		
			data_rdy		= 1'b1;
		end
		
	
		if ( data_rdy==1'b1 && data_vld == 1'b1 ) 
		begin		
			$display ( "%g %m 0x%h", $time, data );
		
			$fwrite  ( file_handler, "%x\n", data );	

			gap_count = G_NUM_CYCLES_GAP;
		end		
		
	end

	
	
	task file_set ( input string file_name );
	
	begin	
	
	end
	endtask
	
	task file_close ( );
	
	begin	
		$display ( "%g %m File Close", $time );
	
		$fclose(file_handler);
	end
	endtask	
	
endmodule
	
	
	
	
	
	
