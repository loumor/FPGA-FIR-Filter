----------------------------------------------------------------------------------
-- data_processing
----------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;


entity data_processing_input is
	generic (
		G_DATA_WIDTH	: INTEGER := 32
	);

	port (
	   --Clocks
		clk				: in    	std_logic;
		rst_n			: in    	std_logic;
		
		
		--Data Input
		data_in_vld		: IN 		STD_LOGIC;							--High when data on the input is valid
		data_in 		: IN 		STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 00);		
		data_in_rdy	  : OUT 		STD_LOGIC;							--Set high when this block can accept data
				
	 filter_in_vld	    : out STD_LOGIC;
	 filter_in_data		: out STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 00);
	 filter_out_vld	    : in STD_LOGIC;
     filter_out_data    : in STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 00);

		--Data Output
		data_out_vld	: OUT 		STD_LOGIC;
		data_out 		: OUT		STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 00);
		data_out_rdy	: IN 		STD_LOGIC 	
	);
end data_processing_input;

architecture RTL of data_processing_input is

	signal data_in_rdy_i	: STD_LOGIC;
	signal data_out_vld_i	: STD_LOGIC;

	signal fifo_empty 		: STD_LOGIC;
	signal fifo_full 		: STD_LOGIC;
	signal fifo_rd_en		: STD_LOGIC;
	signal fifo_rd_en_dly1	: STD_LOGIC;
	signal fifo_wr_en		: STD_LOGIC;
	signal fifo_rd_data		: STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 00);	
  
begin

	data_in_rdy		<= data_in_rdy_i;
	data_out_vld	<= data_out_vld_i;

	
PM_FIFO : entity work.fifo_ram
    generic map (
		G_DATA_WIDTH 	=> G_DATA_WIDTH,
		G_DEPTH      	=> 16
    )
    port map(
		clk    			=> clk,
		rst_n  			=> rst_n,
		din    			=> data_in,
		wr_en  			=> fifo_wr_en,
		full   			=> fifo_full,
		dout   			=> fifo_rd_data,
		rd_en  			=> fifo_rd_en,
		empty  			=> fifo_empty
    );

	
P_DATA_IN : process ( clk, rst_n )
	begin
		if ( rst_n = '0' ) then
					
			data_in_rdy_i 		<= '0';
			fifo_wr_en			<= '0';
							
		elsif rising_edge( clk ) then
			fifo_wr_en			<= '0';
			
			data_in_rdy_i		<= not fifo_full;

			if ( data_in_vld='1' and data_in_rdy_i='1' and fifo_wr_en='0' and fifo_full='0' ) then		--Check wr_en low to as full flag takes a clock to become valid
				fifo_wr_en 		<= '1';
			end if;
			
		end if;
	
	end process;
	
	
	
P_DATA_OUT : process ( clk, rst_n )
	begin
		if ( rst_n = '0' ) then
			
			fifo_rd_en			<= '0';
			fifo_rd_en_dly1		<= '0';
			
			data_out_vld_i 		<= '0';
			data_out			<= ( others=>'0' );
						
			filter_in_vld		<= '0';
			filter_in_data		<= ( others=>'0' );		
			
		elsif rising_edge( clk ) then
			fifo_rd_en			<= '0';
			fifo_rd_en_dly1		<= fifo_rd_en;
			filter_in_vld		<= '0';
			
			--Get Data from FIFO if not empty
			if ( data_out_vld_i='0' and fifo_rd_en='0' and fifo_empty = '0' ) then		--Check rd_en low to as empty flag takes a clock to become valid
				fifo_rd_en 		<= '1';
			end if;
			
			
			--Data not valid until one clock after fifo_rd_en
			if ( fifo_rd_en_dly1='1') then 		
				filter_in_vld	<= '1';
				filter_in_data	<= fifo_rd_data;				
			end if;		          		
			
			--OUTPUT STAGE			
				if ( filter_out_vld='1') then 
					data_out_vld_i	<= '1';
					data_out		<= filter_out_data;
				end if;
						
				if ( data_out_vld_i='1' and data_out_rdy='1') then 
					data_out_vld_i	<= '0';
				end if;	
				
		end if;
	
	end process;	
	
end RTL;
