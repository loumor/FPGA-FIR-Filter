library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;


entity pipeline is
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
	    pipe_in_vld		: in STD_LOGIC;
	    pipe_in_data 	: in STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 00);	
	
		--Data Output
	    pipe_out_vld		: out STD_LOGIC;
	    pipe_out_data		: out STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 00)
	);
end pipeline;

architecture RTL of pipeline is
	
	--Data PIPELINE internal signal
    signal pipe_2_vld	: STD_LOGIC;
	signal pipe_2_data 	: STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 00);	
	
begin                		                     	                     
	
	
    P_DATA_OUT : process ( clk, rst_n )
    begin
        if ( rst_n = '0' ) then                    

            pipe_2_vld            <= '0';
            pipe_2_data           <= ( others=>'0' );        
            pipe_out_vld          <= '0';
            pipe_out_data         <= ( others=>'0' );
                        
        elsif rising_edge( clk ) then
        
            --
            -- PIPELINE ----------------------------
            --
            if ( pipe_in_vld='1' ) then 
                pipe_2_vld        <= '1';
                                    
                if ( mode(0)='1' ) then
                    pipe_2_data    <= not pipe_in_data;        --Invert all bits
                else 
                    pipe_2_data    <= pipe_in_data;
                end if;
            else
                pipe_2_vld         <= '0';                
            end if;
        
            if ( pipe_2_vld='1' ) then 
                pipe_out_vld       <= '1';
                
                if ( mode(1)='1' ) then                    --7:0 becomes 0:7

                    for I in 0 to G_DATA_WIDTH-1 loop
                        
                        pipe_out_data(I) <= pipe_2_data( G_DATA_WIDTH-1-I );
                    
                    end loop;                    
                else 
                    pipe_out_data  <= pipe_2_data;            
                end if;
            else
                pipe_out_vld       <= '0';                    
            end if;
            --
            -- END PIPELINE ----------------------------
            --                             
        end if;    
    end process;        
end RTL;