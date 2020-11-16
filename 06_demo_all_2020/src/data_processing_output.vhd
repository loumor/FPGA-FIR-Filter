----------------------------------------------------------------------------------
-- data_processing
----------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;


entity data_processing_output is
	generic (
		G_DATA_WIDTH	: INTEGER := 32
	);

	port (
	--Clocks
	clk				: in    	std_logic;
	rst_n			: in    	std_logic;
		
	pipe_3_vld		: in STD_LOGIC;
	pipe_3_data 		: in STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 00);			
				
	--Data Output	
	data_out_vld_i	: OUT STD_LOGIC;
	data_out 		: OUT	STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 00);
	data_out_rdy	: IN 	STD_LOGIC 		--Set high when the receiver can accept data
	);
end data_processing_output;

architecture RTL of data_processing_output is
  
	signal data_out_vld_iI	: STD_LOGIC;  
  
begin
	data_out_vld_i	<= data_out_vld_ii;

P_DATA_OUT : process ( clk, rst_n )
	begin
		if ( rst_n = '0' ) then
			
			data_out_vld_i 		<= '0';
			data_out			<= ( others=>'0' );
						
		elsif rising_edge( clk ) then
	
				if ( pipe_3_vld='1') then 
					data_out_vld_ii	<= '1';
					data_out		<= pipe_3_data;
				end if;
						
				if ( data_out_vld_ii='1' and data_out_rdy='1') then 
					data_out_vld_i	<= '0';
				end if;	
				
		end if;
	
	end process;	
	
end RTL;
