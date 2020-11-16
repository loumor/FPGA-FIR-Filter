----------------------------------------------------------------------------------
-- data_processing
----------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;


entity my_filter is
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
	   filter_in_vld	    : in STD_LOGIC;
	   filter_in_data		: in STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 00);	
	
		--Data Output
	   filter_out_vld		: out STD_LOGIC;
	   filter_out_data		: out STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 00)
	);
end my_filter;

architecture RTL of my_filter is
	
	-- signals for fir_filter 
    signal fir_out_vld : std_logic;
    signal fir_out_data : std_logic_vector (G_DATA_WIDTH-1 downto 00);

    -- signals for pipeline
    signal pipe_out_vld : std_logic;
    signal pipe_out_data : std_logic_vector (G_DATA_WIDTH-1 downto 00);    
        
    signal mode_select : std_logic_vector (2 downto 0);  
  
begin
	
mode_select <= mode(2 downto 0);
		
-- Choose filter or pipeline depending on switches
-- Could potentially add more filter options here		
process(clk)
begin
    if rising_edge(clk) then 
        case mode_select is
            when "000" => filter_out_vld <= pipe_out_vld;
            when "001" => filter_out_vld <= pipe_out_vld;
            when "010" => filter_out_vld <= pipe_out_vld;
            when "011" => filter_out_vld <= pipe_out_vld;
            when "100" => filter_out_vld <= fir_out_vld;
            when "101" => filter_out_vld <= fir_out_vld;
            when "110" => filter_out_vld <= fir_out_vld;
            when "111" => filter_out_vld <= fir_out_vld;         
            when others => filter_out_vld <= pipe_out_vld;
        end case;
    
        case mode_select is
            when "000" => filter_out_data <= pipe_out_data;
            when "001" => filter_out_data <= pipe_out_data;
            when "010" => filter_out_data <= pipe_out_data;
            when "011" => filter_out_data <= pipe_out_data;
            when "100" => filter_out_data <= fir_out_data;
            when "101" => filter_out_data <= fir_out_data;
            when "110" => filter_out_data <= fir_out_data;
            when "111" => filter_out_data <= fir_out_data;     
            when others => filter_out_data <= pipe_out_data;                   
        end case;
    end if;
end process;


PM_PIPELINE: entity work.pipeline 	
   generic map (
        G_DATA_WIDTH     => G_DATA_WIDTH
    )
    port map(
        clk           => clk,
        rst_n         => rst_n,      
        mode          => mode,  
		pipe_in_vld   => filter_in_vld,
        pipe_in_data  => filter_in_data, 
        pipe_out_vld  => pipe_out_vld,
        pipe_out_data => pipe_out_data  
    );        	
	
PM_FILTER_TEST: entity work.my_FIR_filter
       generic map (
            G_DATA_WIDTH     => G_DATA_WIDTH
        )
        port map(
            clk          => clk,
            rst_n        => rst_n,        
            data_in      => filter_in_data,
            data_in_vld  =>  filter_in_vld, 
            data_out     => fir_out_data,
            data_out_vld => fir_out_vld 
        );   
        
end RTL;
