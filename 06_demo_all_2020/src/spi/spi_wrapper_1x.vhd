----------------------------------------------------------------------------------
-- spi_wrapper VHDL
--
-- A block to instantiate all SPI Masters with glue logic back up to the SYS CLK domain
--
-- SPI system controller along with a controller per DAC is also implemented
----------------------------------------------------------------------------------

library IEEE;
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.NUMERIC_STD.all;

entity spi_wrapper_1x is
	GENERIC (
		G_NUM_SPI_CLKS_READ 			: INTEGER := 16
	);
	
	port (	
		clk_sys		         			: IN        STD_LOGIC;		
		clk_spi_x2						: IN		STD_LOGIC;
			
		rst_n  		         			: IN  	    STD_LOGIC;									-- reset signal
		
		--System Signals on clk_sys
			--Reads
			sys_rd_trigger				: IN		STD_LOGIC;
			sys_rd_sample_valid			: OUT		STD_LOGIC;
			sys_rd_sample_ch			: OUT		STD_LOGIC;
			sys_rd_sample_data			: OUT 		STD_LOGIC_VECTOR	( G_NUM_SPI_CLKS_READ-1 downto 00 );
			
			--Writes
			sys_wr_valid				: IN		STD_LOGIC;
			sys_wr_eot					: IN		STD_LOGIC;
			sys_wr_data    				: IN		STD_LOGIC_VECTOR	( 07 downto 00 );
			sys_wr_taken   				: OUT		STD_LOGIC;			
			
										
		--IO connections on clk_spi		
			spi_clk						: OUT		STD_LOGIC;
			spi_cs						: OUT		STD_LOGIC;
			spi_miso					: IN		STD_LOGIC;
			spi_mosi					: OUT		STD_LOGIC;
			spi_rst						: OUT		STD_LOGIC;
			spi_ch						: OUT		STD_LOGIC
	);
end spi_wrapper_1x;

architecture RTL of spi_wrapper_1x is

	signal  sys_rd_trigger_tgl			: STD_LOGIC;
	signal  sys_wr_valid_tgl			: STD_LOGIC;

	--SPI Read data
	signal 	spi_rd_trigger				: STD_LOGIC;	
	signal  spi_rd_valid				: STD_LOGIC;
	signal  spi_rd_data 				: STD_LOGIC_VECTOR	( G_NUM_SPI_CLKS_READ-1 downto 00 );

	--SPI Write data
	signal 	spi_wr_valid				: STD_LOGIC;
	signal 	spi_wr_eot					: STD_LOGIC;
	signal 	spi_wr_data					: STD_LOGIC_VECTOR	( 07 downto 00 );
	signal 	spi_wr_taken				: STD_LOGIC;
	
	signal 	spi_ch_i					: STD_LOGIC;
begin

	spi_ch	<= spi_ch_i;

	PM_SPI_M : entity work.spi_master
	GENERIC MAP (
		G_SPI_CLKS_READ		=> G_NUM_SPI_CLKS_READ
	)
	PORT MAP (
		clk			   		=> clk_spi_x2,					--2x clock to generate a 1x SPI_CLK
		rst_n  		    	=> rst_n,
		
		wr_valid			=> spi_wr_valid,
		wr_taken			=> spi_wr_taken,
		wr_eot				=> spi_wr_eot,
		wr_data  			=> spi_wr_data,
			
		trigger_read    	=> spi_rd_trigger,
		spi_rd_valid		=> spi_rd_valid,
		spi_rd_data			=> spi_rd_data,
					
		spi_clk		    	=> spi_clk,
		spi_cs		    	=> spi_cs,
		spi_miso 	    	=> spi_miso, 
		spi_mosi 	    	=> spi_mosi,
		spi_ch				=> spi_ch_i
	);

--##################################################################################################
-- TRIGGERs
--##################################################################################################
P_TRIGGER : process( clk_sys, rst_n )
begin
	if ( rst_n = '0' ) then												-- on reset signal
		
		sys_rd_trigger_tgl				<= '0';
		sys_wr_valid_tgl				<= '0';
				
	elsif rising_edge( clk_sys ) then									-- on clock rising edge

		if ( sys_rd_trigger = '1' ) then 		
			sys_rd_trigger_tgl			<= not sys_rd_trigger_tgl;		--Toggle to cross over domain
		end if;	
		
		if ( sys_wr_valid = '1' ) then 		
			sys_wr_valid_tgl			<= not sys_wr_valid_tgl;
		end if;
	
	end if;
end process P_TRIGGER;


--##################################################################################################
-- CLOCK DOMAIN - SYSTEM TO SPI domain - Reads
--##################################################################################################
P_SYS_TO_SPI_RD : process ( clk_spi_x2, rst_n )
	
	variable	trigger_adc_samples_xfer_1, trigger_adc_samples_xfer_2, trigger_adc_samples_xfer_3	: STD_LOGIC;

begin
	if ( rst_n = '0' ) then	
	
		spi_rd_trigger				<= '0';
		trigger_adc_samples_xfer_1	:= '0';
		trigger_adc_samples_xfer_2	:= '0';
		trigger_adc_samples_xfer_3	:= '0';
	
	elsif rising_edge( clk_spi_x2 ) then
	
		spi_rd_trigger				<= '0';	
		
		--Trigger Sampling
		trigger_adc_samples_xfer_3	:= trigger_adc_samples_xfer_2;
		trigger_adc_samples_xfer_2	:= trigger_adc_samples_xfer_1;
		trigger_adc_samples_xfer_1	:= sys_rd_trigger_tgl;

		if ( trigger_adc_samples_xfer_3 /= trigger_adc_samples_xfer_2 ) then
			spi_rd_trigger		<= '1';
		end if;
		
	end if;
end process P_SYS_TO_SPI_RD;

--##################################################################################################
-- CLOCK DOMAIN - SYSTEM TO SPI Domain - Writes
--##################################################################################################
P_SYS_TO_SPI_WR : process ( clk_spi_x2, rst_n )
	
	variable	spi_wr_valid_xfer_1, spi_wr_valid_xfer_2, spi_wr_valid_xfer_3	: STD_LOGIC;

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of spi_wr_valid_xfer_1: variable is "true";	
	
begin
	if ( rst_n = '0' ) then	
	
		spi_wr_valid				<= '0';
		spi_wr_eot					<= '0';
		spi_wr_data					<= (others => '0');

		spi_wr_valid_xfer_1			:= '0';
		spi_wr_valid_xfer_2			:= '0';
		spi_wr_valid_xfer_3			:= '0';
	
	elsif rising_edge( clk_spi_x2 ) then

		--FROM SPI WRITE data channel
			
			--SPI Write Interface
			if ( spi_wr_taken='1' ) then 
				--VALID set with a toggle but cleared when we receive a TAKEN FROM SPI MASTER
				spi_wr_valid		<= '0';					
			end if;
				
			spi_wr_valid_xfer_3		:= spi_wr_valid_xfer_2;
			spi_wr_valid_xfer_2		:= spi_wr_valid_xfer_1;
			spi_wr_valid_xfer_1		:= sys_wr_valid_tgl;				--Transfer valid toggle across domain
		
			if ( spi_wr_valid_xfer_3 /= spi_wr_valid_xfer_2 ) then		--Sample all into DAC domain
				spi_wr_valid		<= '1';					
				spi_wr_data			<= sys_wr_data;
				spi_wr_eot			<= sys_wr_eot;
			end if;		
		
	end if;
end process P_SYS_TO_SPI_WR;

--##################################################################################################
-- CLOCK DOMAIN - SPI to SYSTEM
--##################################################################################################
P_SPI_TO_SYS : process ( clk_sys, rst_n )
	
	variable 	spi_wr_taken_xfer_1,	spi_wr_taken_xfer_2,	spi_wr_taken_xfer_3		: STD_LOGIC;
	variable	spi_rd_valid_xfer_1,	spi_rd_valid_xfer_2,	spi_rd_valid_xfer_3		: STD_LOGIC;
	
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of spi_wr_taken_xfer_1: variable is "true";	
	attribute ASYNC_REG of spi_rd_valid_xfer_1: variable is "true";	
	
begin
	if ( rst_n = '0' ) then	
	
		sys_wr_taken				<= '0';
		
		sys_rd_sample_valid			<= '0';
		sys_rd_sample_ch			<= '0';
		sys_rd_sample_data			<= ( others => '0' );
				
		spi_wr_taken_xfer_1			:= '0';
		spi_wr_taken_xfer_2			:= '0';
		spi_wr_taken_xfer_3			:= '0';
				
		spi_rd_valid_xfer_1			:= '0';
		spi_rd_valid_xfer_2			:= '0';
		spi_rd_valid_xfer_3			:= '0';
		
		
	elsif rising_edge( clk_sys ) then
	
		sys_wr_taken				<= '0';
		sys_rd_sample_valid			<= '0';
		
	--FROM DAC domain
		--CONFIG TAKEN
		spi_wr_taken_xfer_3			:= spi_wr_taken_xfer_2;
		spi_wr_taken_xfer_2			:= spi_wr_taken_xfer_1;
		spi_wr_taken_xfer_1			:= spi_wr_taken;
		
		if ( spi_wr_taken_xfer_3 /= spi_wr_taken_xfer_2 and spi_wr_taken_xfer_2='1' ) then			--Rising edge only
			sys_wr_taken			<= '1';
		end if;

		

	--FROM ADC domain
		--FROM SPI Read data channel
			spi_rd_valid_xfer_3			:= spi_rd_valid_xfer_2;
			spi_rd_valid_xfer_2			:= spi_rd_valid_xfer_1;
			spi_rd_valid_xfer_1			:= spi_rd_valid;
		
			if ( (spi_rd_valid_xfer_3 /= spi_rd_valid_xfer_2) and spi_rd_valid_xfer_2='1' ) then	--Rising edge only
				sys_rd_sample_valid		<= '1';
				sys_rd_sample_ch		<= spi_ch_i;
				sys_rd_sample_data		<= spi_rd_data;
			end if;		
					
	end if;
end process P_SPI_TO_SYS;	
	
end RTL;
