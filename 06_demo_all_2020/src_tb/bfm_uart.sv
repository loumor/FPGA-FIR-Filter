//--------------------------------------------------------------------------------
// bfm_uart
//
// Bus functional model to help decipher the UART comms protocol
//
//--------------------------------------------------------------------------------

`timescale 1ns/1ps

module bfm_uart
	#(
	parameter 
        G_BAUD 		= 115200
	)
	(  
		input 		tx_in,
		output reg	rx_out
    );
	
	`define NULL 0  
	
	integer         fh_input;			//File handler - input
	integer         fh_output;			//File handler - output
	
	integer         lh_input;			//Line handler - input	

	
	logic	[7:0]	captured_data;	
	
	real 			baud_period		= (1000000000/G_BAUD);
	const int		C_FIFO_SIZE		= 32;
		
	//RX Side	
	reg				rx_idle			= 1;
	reg 			rx_sample_tgl 	= 0;
	reg [7:0]		rx_data;
		
	//TX Side	
	reg [7:0]		tx_fifo[32];
	int				tx_ptr_wr		= 0;
	int				tx_ptr_rd		= 0;
	reg [9:0]		tx_data;
	int				tx_fill			= 0;

	//####################################################################################
	//
	// RX 
	//
	//####################################################################################
	always
    begin
		rx_idle			= 1;
		@(negedge tx_in);
		rx_idle			= 0;
		#(baud_period/2);
		rx_sample_tgl	= ~rx_sample_tgl;

		
		for (int i=0; i<8; i++)
		begin
			#(baud_period);
			rx_sample_tgl	= ~rx_sample_tgl;
			rx_data[i]		= tx_in;
		end 
		
		$display ( "%m %g UART RX : 0x%h", $time, rx_data );
		
		$fwrite  ( fh_output, "%x\n", rx_data );
	end

	//####################################################################################
	//
	// TX
	//
	//####################################################################################	
	always
    begin
		rx_out			= 1;
		wait ( tx_fill!=0 );
		
		tx_data			= {1'b1, tx_fifo[tx_ptr_rd], 1'b0};
		tx_ptr_rd		= tx_ptr_rd + 1;
		tx_fill 		= tx_fill - 1;
		
		if ( tx_ptr_rd == C_FIFO_SIZE )	tx_ptr_rd = 0;
		
		for (int j=0; j<10; j++)
		begin
			#(baud_period);		
			rx_out		= tx_data[j];
		end 
	end
	
	
	
	
	
	
	
	//####################################################################################
	//
	// TASKS
	//
	//####################################################################################	
	
	// Task TX Data in
	task uart_tx;
		input [7:0]  	data_to_send;
	begin
		$display ( "%m %g UART TX add : 0x%h", $time, data_to_send );
	
		if ( tx_fill==C_FIFO_SIZE )	wait ( tx_fill<C_FIFO_SIZE );

		tx_fifo[tx_ptr_wr]	= data_to_send;
		tx_ptr_wr			= tx_ptr_wr + 1;
		tx_fill 			= tx_fill + 1;
	
		if ( tx_ptr_wr == C_FIFO_SIZE )	tx_ptr_wr = 0;
	
	end
	endtask	
 

 
	task tx_wait_empty;

	begin
		$display ( "%m %g TX wait_empty...", $time );
	
		wait ( tx_fill==0 );
		
		$display ( "%m %g TX wait_empty...done", $time );	
	end
	endtask	
 
 
	// Task TX File 
 	task file_input_send ( input string file_name );
	
		reg	loop_file;
	
	begin
		$display ( "%g Reading... %s", $time, file_name ); 
	
		fh_input = $fopen( file_name, "r");
		
		if (fh_input == `NULL) begin
			$display("fh_input handle was NULL");
			$finish;
		end

		//Loop through file
		loop_file = 1'b1;
		while ( loop_file == 1'b1 )
		begin
						
			if ( $feof(fh_input) ) begin
				loop_file 	= 1'b0;
			end 
			else 
			begin				
				lh_input = $fscanf( fh_input, "%x\n", captured_data ); 

				$display ( "%g %m 0x%h", $time, captured_data );
				
				uart_tx( captured_data );	
			end
		end 	
	end
	endtask	


	
	// Task RX File 
 	task file_output_set ( input string file_name );	
	begin
	
		fh_output	= $fopen( file_name, "w");
		
		if ( fh_output == `NULL ) begin
			$display("%m file handle was NULL");
			$finish;
		end		
	end
	endtask
	
	

	task file_output_close ( );	
	begin	
		$display ( "%g %m File Close", $time );
	
		$fclose(fh_output);
	end
	endtask	

	
endmodule














