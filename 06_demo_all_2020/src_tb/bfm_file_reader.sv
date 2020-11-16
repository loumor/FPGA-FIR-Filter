//--------------------------------------------------------------------------------
//
// bfm_file_reader
//
//--------------------------------------------------------------------------------

module bfm_file_reader
	#(
	parameter 
		G_NUM_BITS			= 32,
		G_NUM_CYCLES_GAP	= 2
	)
	(  
		input 							clk,
		output reg						data_vld,
		output reg	[G_NUM_BITS-1:0]	data,
		input 							data_rdy			//Set high by receiver when data can be accepted
    );

	`define NULL 0  
	
	integer               		data_file; // file handler
	integer               		scan_file; // file handler
	logic	[G_NUM_BITS-1:0]	captured_data;
	

	initial begin
		data_vld			= 1'b0;
		data				= {G_NUM_BITS{1'b0}};
	end

	
	
	
	task read_file ( input string file_name );
	
		reg	loop_file;
	
	begin
		$display ( "%g Reading... %s", $time, file_name ); 
	
		data_file = $fopen( file_name, "r");
		
		if (data_file == `NULL) begin
			$display("data_file handle was NULL");
			$finish;
		end

		//Loop through file
		loop_file = 1'b1;
		while ( loop_file == 1'b1 )
		begin
						
			if ( $feof(data_file) ) begin
				loop_file 	= 1'b0;
			end 
			else 
			begin				
				scan_file = $fscanf( data_file, "%x\n", captured_data ); 
			
				@ (posedge clk);
			
				$display ( "%g %m 0x%h", $time, captured_data ); 			
			
				data_vld	= 1'b1;
				data		= captured_data;	
			
				//wait clock, valid and ready
					do 
					begin
						@ (posedge clk);							
					end 
					while ( ~(data_vld==1'b1 && data_rdy==1'b1) );
					
				//Clear valid
					data_vld	= 1'b0;
						
				//Gap if needed
					repeat (G_NUM_CYCLES_GAP) begin 
						@ (posedge clk);
					end			
	
			end
		end 
		
		@ (posedge clk);
		data_vld			= 1'b0;
		
	end
	endtask	

endmodule
	
	
	
	
	
	
