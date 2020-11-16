
`timescale 1ns / 1ps


module tb_top;

    integer         error_count = 0;

	reg 			clk_100;
	reg 			rst_n;
	
	wire 			scl;
	wire 			sda;

	wire			uart_rx;
	wire			uart_tx;	
	
	reg	[3:0]		btn;
	reg	[3:0]		switch;
		
		
	fpga_top 
	#(
		.G_IN_SIM		( 1 )
	)
	dut
	(	
		//Clocks
		.clk_pad   		( clk_100 ),
		 
		//Resets
		.rst_n			( rst_n ),
		
		//I2C
		.I2C_SCL		( scl ),
		.I2C_SDA		( sda ),
		
		//UART
		.uart_tx		( uart_tx ),
		.uart_rx		( uart_rx ),
		
		//Buttons // Switches
		.btn			( btn ),
		.switch			( switch ),
		
		//LEDs
		.led			( ),
		.led_r			( ),
		.led_g			( ),
		.led_b			( )		
	);

//BFM I2C
	assign (pull1,pull0) sda 		= '1;
	assign (pull1,pull0) scl 		= '1;
	
	bfm_i2c_slave #(7'b1010000)		//EEPROM
	bfm_i2c_slave_50
	( 
		.SDA		( sda ),
		.SCL		( scl ),
		.IOout 		( )
	);	

//BFMs UARTs
	bfm_uart	
	#(	
        .G_BAUD			( 115200 )
	)
	bfm_uart 
	(  
		.tx_in			( uart_tx ),
		.rx_out			( uart_rx )
    );	

	
	
   initial
      $timeformat (-9, 3, " ns", 13);	

	initial
	begin
		#0  	rst_n   		= 1'b0;
		#0  	clk_100			= 1'b0;		
		
		#0		btn				= 4'b0000;
		#0		switch			= 4'b0000;

		#200	rst_n   		= 1'b1;		
		
		#10000	btn				= 4'b0001;		//Press Button 0
		#100	btn				= 4'b0000;
		
		#10000	btn				= 4'b0010;		//Press Button 1
		#10000	btn				= 4'b0000;		
		
	end

	always
	begin
		#5  	clk_100 	= !clk_100;
	end



	initial
	begin
		$display("TEST STARTED");
				
		#1000;		
		bfm_uart.file_output_set	( "o_file_001.txt" );
		
		bfm_uart.file_input_send	( "i_file_001.txt" );
		
		bfm_uart.tx_wait_empty		( );
			
		
		#500000;	
		bfm_uart.file_output_close	( );
		
		if ( error_count==0 ) $display("TEST PASSED");
		else                  $display("TEST FAILED : %d ERRORS", error_count );
		
		$finish;
	end

endmodule
