
library IEEE;
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.NUMERIC_STD.all;

entity spi_controller is

	port (	
		clk_sys		         			: IN        STD_LOGIC;		
		clk_spi_x2						: IN		STD_LOGIC;
			
		rst_n  		         			: IN  	    STD_LOGIC;									-- reset signal
		
		trigger							: IN		STD_LOGIC;
										
		--IO connections on clk_spi		
			spi_clk						: OUT		STD_LOGIC;
			spi_cs						: OUT		STD_LOGIC_VECTOR(01 downto 00);
			spi_miso					: IN		STD_LOGIC;
			spi_mosi					: OUT		STD_LOGIC;
			spi_rst						: OUT		STD_LOGIC;
			spi_ch						: OUT		STD_LOGIC
	);
end spi_controller;

architecture RTL of spi_controller is

	type T_SM_SPI	is 		( WAIT_TRIGGER, SPI_WRITE_0, SPI_WRITE_1, WAIT_TAKEN );
	
	signal sm_spi			: T_SM_SPI;
	signal sm_spi_next		: T_SM_SPI;

	signal sys_wr_valid		: STD_LOGIC;
	signal sys_wr_eot		: STD_LOGIC;
	signal sys_wr_data		: STD_LOGIC_VECTOR(07 downto 00);
	signal sys_wr_taken		: STD_LOGIC;
	
	signal set_cs_0			: STD_LOGIC;
	
	signal spi_cs_i			: STD_LOGIC;
	
begin

	spi_cs(0)	<= spi_cs_i when set_cs_0='1' else '1';
	spi_cs(1)	<= spi_cs_i when set_cs_0='0' else '1';


PM_SPI_MASTER : entity work.spi_wrapper_1x
	GENERIC MAP (
		G_NUM_SPI_CLKS_READ				=>  16
	)
	PORT MAP (	
		clk_sys		         			=> clk_sys,		
		clk_spi_x2						=> clk_spi_x2,
			
		rst_n  		         			=> rst_n,
		
		--SYS Reads
			sys_rd_trigger 				=> '0',
			sys_rd_sample_valid			=> open,
			sys_rd_sample_ch			=> open,
			sys_rd_sample_data			=> open,
			
		--SYS Writes
			sys_wr_valid				=> sys_wr_valid,
			sys_wr_eot					=> sys_wr_eot,
			sys_wr_data    				=> sys_wr_data,
			sys_wr_taken   				=> sys_wr_taken,
			
		--IO connections on SPI_CLK                    
			spi_clk						=> spi_clk,
			spi_cs						=> spi_cs_i,
			spi_miso					=> spi_miso,
			spi_mosi					=> spi_mosi,
			spi_rst 					=> open,
			spi_ch 						=> open
	);	
	
	
P_SPI_CONTROL : process ( clk_sys, rst_n )
	begin
		if ( rst_n = '0' ) then
		
			sm_spi			<= WAIT_TRIGGER;
			sm_spi_next		<= WAIT_TRIGGER;
		
			set_cs_0		<= '0';
		
			sys_wr_valid	<= '0';
			sys_wr_eot		<= '0';
			sys_wr_data		<= (others => '0');
					
		elsif rising_edge( clk_sys ) then	
			sys_wr_valid	<= '0';	
		
			case ( sm_spi ) is
			when WAIT_TRIGGER =>
									
				if ( trigger='1' ) then
					set_cs_0	<= not set_cs_0;		--change device each cycle
					sm_spi		<= SPI_WRITE_0;
				end if;		

			when SPI_WRITE_0 =>
				sys_wr_valid	<= '1';	
				sys_wr_data		<= "01010111";			
				
				sm_spi			<= WAIT_TAKEN;
				sm_spi_next		<= SPI_WRITE_1;

			when SPI_WRITE_1 =>
				sys_wr_valid	<= '1';	
				sys_wr_eot		<= '1';	
				sys_wr_data		<= "11110000";			
				
				sm_spi			<= WAIT_TAKEN;
				sm_spi_next		<= WAIT_TRIGGER;	

		
			when WAIT_TAKEN => 
				if ( sys_wr_taken='1' ) then
					sys_wr_eot	<= '0';
				
					sm_spi		<= sm_spi_next;
				end if;
			
			end case;
		
		end if;	
	end process;	
	
end RTL;
