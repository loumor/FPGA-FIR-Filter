----------------------------------------------------------------------------------
-- spi_adc_x VHDL
--
-- A block to read x number of adc channels at once using a common spi chip select and clock
-- with x spi read channels.
-- Used to interface to the Analog devices AD7276/AD7277/AD7278 which has a max 
-- SPI clock of 48MHz
----------------------------------------------------------------------------------

library IEEE;
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.NUMERIC_STD.all;


entity spi_master is
	GENERIC (
		G_SPI_CLKS_READ	: INTEGER := 16			--Returns all the data read in the SPI transaction - Up to higher blocks to extract the right bits.
	);

	port (
		clk			         		: IN        STD_LOGIC;									-- Two times the desired SPI_CLK rate
		rst_n  		         		: IN  	    STD_LOGIC;									-- reset signal
		
		--Write out of SPI interface
		wr_valid					: IN		STD_LOGIC;
		wr_taken					: OUT		STD_LOGIC;
		wr_eot						: IN		STD_LOGIC;
		wr_data 					: IN		STD_LOGIC_VECTOR(07 downto 00);
		
		trigger_read         		: IN 	    STD_LOGIC;									-- Trigger from an external state machine to start the ADC captures		
		spi_rd_valid				: OUT		STD_LOGIC;
		spi_rd_data					: OUT		STD_LOGIC_VECTOR( G_SPI_CLKS_READ-1 downto 0 );
				
		spi_clk		         		: OUT    	STD_LOGIC;
		spi_cs		         		: OUT	    STD_LOGIC;
		spi_miso 	         		: IN	    STD_LOGIC;
		spi_mosi					: OUT		STD_LOGIC;
		
		spi_ch						: out       STD_LOGIC			--Used in an ADC AD7265 to select channels
		
	);
end spi_master;

architecture RTL of spi_master is

	TYPE	T_state IS( IDLE, WAITING, WRITING, WRITE_END, READING, READ_END ); 	--state machine data type  
	SIGNAL	state            	: T_state;                     					--current state

	SIGNAL 	spi_clk_i			: STD_LOGIC;
	signal  spi_ch_i            : STD_LOGIC;
	SIGNAL	spi_bit_counter	   	: INTEGER;	
	
	signal 	spi_wr_local_byte	: STD_LOGIC_VECTOR(07 downto 00);
	signal  spi_wr_local_eot	: STD_LOGIC;
	
	signal 	spi_data_array		: STD_LOGIC_VECTOR( G_SPI_CLKS_READ-1 downto 0 );
			
begin

	spi_clk	<= spi_clk_i;
	spi_ch  <= spi_ch_i;

spi_adc_x_sm : process( clk, rst_n )
begin
	if ( rst_n = '0' ) then					-- on reset signal
		spi_clk_i		  		<= '1';				
		spi_cs			  		<= '1';
		spi_mosi				<= '0';
		spi_ch_i				<= '0';
		
		wr_taken				<= '0';
		spi_wr_local_byte		<= ( others => '0' );
		spi_wr_local_eot		<= '0';
		
		spi_rd_valid			<= '0';
		spi_rd_data				<= ( others => '0' );
		
		spi_bit_counter   		<= G_SPI_CLKS_READ-1;	
		spi_data_array			<= ( others => '0' );
					
		state			  		<= IDLE;
		
	elsif rising_edge(clk) then				-- on clock rising edge
	
		spi_rd_valid			<= '0';
		wr_taken				<= '0';
	
		CASE state IS

			WHEN IDLE =>	
				--Reset all flags while waiting for a trigger
				spi_clk_i				<= '1';				
				spi_cs					<= '1';
				spi_mosi				<= '0';
				state					<= WAITING;		--ensures at least one clk of CS high between transactions
				
			WHEN WAITING => 
								
				--READ
				if ( trigger_read = '1' ) then
					spi_cs				<= '0';
					spi_bit_counter 	<= G_SPI_CLKS_READ-1;
					
					state				<= READING;
				end if;

				--WRITE
				if ( wr_valid = '1' ) then 					
					spi_bit_counter 	<= 7;
					wr_taken			<= '1';
					spi_wr_local_byte	<= wr_data;
					spi_wr_local_eot	<= wr_eot;
				
					state				<= WRITING;
				end if;				
			
			WHEN WRITING =>	
			
				if ( spi_clk_i = '0' ) then					--clk currently 0 so this will be the rising edge of SPI_CLK

					spi_cs						<= '0';		--Chip Select with first bit of data
					spi_mosi					<= spi_wr_local_byte(spi_bit_counter);
										
					--Check for end of READ
					if ( spi_bit_counter = 0 ) then
                        --End the write if EOT is set else new data ?
						
						if ( spi_wr_local_eot='1' ) then 						
							state          		<= WRITE_END;                                               
						else
							--More Data
							spi_bit_counter 	<= 7;
							wr_taken			<= '1';
							spi_wr_local_byte	<= wr_data;		
							spi_wr_local_eot	<= wr_eot;						
						end if;
                    else 					
					    spi_bit_counter   		<= spi_bit_counter - 1;
					end if;
					   
				end if;
									
				--Toggle clock
				spi_clk_i						<= not spi_clk_i;		

			WHEN WRITE_END =>
			
				if ( spi_clk_i = '0' ) then
					spi_cs						<= '1';	
					state          				<= IDLE;
				end if;
			
				--Toggle clock
				spi_clk_i						<= not spi_clk_i;			
			
			WHEN READING =>	
				
				if ( spi_clk_i = '0' ) then

					spi_data_array(spi_bit_counter)	<= spi_miso;
										
					if ( spi_bit_counter = 29 ) then					
						spi_ch_i					<= not spi_ch_i;
					end if;						
										
					--Check for end of READ
					if ( spi_bit_counter = 0 ) then
                        --End the read
                        state             			<= READ_END;                                               
                    else 					
					    spi_bit_counter   			<= spi_bit_counter - 1;
					end if;
					   
				end if;
									
				--Toggle clock
				spi_clk_i						<= not spi_clk_i;		
				
	       WHEN READ_END =>
				spi_rd_valid					<= '1';
				spi_rd_data						<= spi_data_array;		--Takes the data out of the SPI traffic and passes it back to the SYSTEM
			   	           
	            state           				<= IDLE;
			
		end case;
	
	end if;

end process spi_adc_x_sm;

end RTL;
