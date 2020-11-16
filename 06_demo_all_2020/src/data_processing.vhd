----------------------------------------------------------------------------------
-- data_processing
----------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;


entity data_processing is
	generic (
		G_DATA_WIDTH	: INTEGER := 32
	);

	port (
	   --Clocks
		clk				: in    	std_logic;
		rst_n			: in    	std_logic;
		
		--Modes
		mode			: in 		std_logic_vector(03 downto 00);		-- 4 enables to switch functionality
		
		--Data Input
		data_in_vld		: IN 		STD_LOGIC;							--High when data on the input is valid
		data_in 		: IN 		STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 00);		
		data_in_rdy  	: OUT 		STD_LOGIC;							--Set high when this block can accept data
				
		--Data Output
		data_out_vld	: OUT 		STD_LOGIC;
		data_out 		: OUT		STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 00);
		data_out_rdy	: IN 		STD_LOGIC 							--Set high when the receiver can accept data
	);
end data_processing;

architecture RTL of data_processing is
	
	--Data PIPELINE
	signal filter_in_vld	: STD_LOGIC;
	signal filter_in_data	: STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 00);	
	
	signal filter_out_vld	: STD_LOGIC;
	signal filter_out_data	: STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 00);		
  
begin

PM_DATAINPUT: entity work.data_processing_input 	
    generic map (
		G_DATA_WIDTH 	=> G_DATA_WIDTH
    )
    port map(
		clk    			=> clk,
		rst_n  			=> rst_n,		
		data_in_vld		=> data_in_vld,
		data_in 		=> data_in,
		data_in_rdy  	=> data_in_rdy, 
		data_out_vld	=> data_out_vld,
		data_out 		=> data_out,		
		data_out_rdy	=> data_out_rdy,
		filter_in_vld	=> filter_in_vld,
	    filter_in_data	=> filter_in_data,	
	    filter_out_vld	=> filter_out_vld,
	    filter_out_data => filter_out_data
    );		
	
PM_MYFILTER: entity work.my_filter 
	generic map (
		G_DATA_WIDTH	=> G_DATA_WIDTH
	)
	port map (
		clk    			=> clk,
		rst_n  			=> rst_n,	
		mode            => mode,
        filter_in_vld	=> filter_in_vld,	
		filter_in_data 	=> filter_in_data, 
		filter_out_vld	=> filter_out_vld,
	    filter_out_data	=> filter_out_data
	);

end RTL;
