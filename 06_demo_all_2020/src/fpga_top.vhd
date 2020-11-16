----------------------------------------------------------------------------------
-- fpga_top VHDL
----------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

entity fpga_top is
	generic (
		G_IN_SIM			: INTEGER := 0
	);

	port (
		--Clocks
			clk_pad			: IN    	std_logic;						-- 100Mhz clock
		--Reset
			rst_n			: IN    	std_logic;						-- "reset" button input (negative logic)
			
		--Analog Input
			vp_in 			: IN 		STD_LOGIC;
			vn_in 			: IN 		STD_LOGIC;		
		
		--PMOD OLED
			pmod_cs			: OUT		STD_LOGIC;
			pmod_mosi       : OUT		STD_LOGIC;
			pmod_sclk       : OUT		STD_LOGIC;
			pmod_dc         : OUT		STD_LOGIC;
			pmod_res        : OUT		STD_LOGIC;
			pmod_vbat       : OUT		STD_LOGIC;
			pmod_vdd		: OUT		STD_LOGIC;	

		--I2C
			I2C_SCL			: INOUT		STD_LOGIC;
			I2C_SDA			: INOUT		STD_LOGIC;

		--SPI
			spi_clk			: OUT		STD_LOGIC;
			spi_cs			: OUT		STD_LOGIC_VECTOR(01 downto 00);
			spi_miso		: IN 		STD_LOGIC;
			spi_mosi		: OUT		STD_LOGIC;
			
		--UART
			uart_tx			: OUT		std_logic;
			uart_rx			: IN		std_logic;
							
		--Switches
			btn				: IN 		std_logic_vector(03 downto 00);	-- 4 BUTTONs on FPGA board		
			switch			: IN 		std_logic_vector(03 downto 00);	-- 4 SWITCHs on FPGA board
					
		--LEDs							
			led				: OUT 		std_logic_vector(03 downto 00);	-- 4 LEDs on FPGA board		
			led_r			: OUT 		std_logic_vector(03 downto 00);	-- 4 LEDs on FPGA board -- RED
			led_g			: OUT 		std_logic_vector(03 downto 00);	-- 4 LEDs on FPGA board -- GREEN
			led_b			: OUT 		std_logic_vector(03 downto 00)	-- 4 LEDs on FPGA board -- BLUE	
	);
end fpga_top;

architecture RTL of fpga_top is

	component clk_wiz_0
	port
	(
		-- Clock in ports
		clk_in1     		: in     STD_LOGIC;
		-- Clock out ports
		clk_100         	: out    STD_LOGIC;
		clk_36          	: out    STD_LOGIC 
	);
	end component;
	
	COMPONENT xadc_wiz_0
	PORT (
		di_in 				: IN	STD_LOGIC_VECTOR(15 DOWNTO 00);
		daddr_in 			: IN 	STD_LOGIC_VECTOR(06 DOWNTO 00);
		den_in 				: IN 	STD_LOGIC;
		dwe_in 				: IN 	STD_LOGIC;
		drdy_out 			: OUT 	STD_LOGIC;
		do_out 				: OUT 	STD_LOGIC_VECTOR(15 DOWNTO 00);
		dclk_in 			: IN 	STD_LOGIC;
		reset_in 			: IN 	STD_LOGIC;
		vp_in 				: IN 	STD_LOGIC;
		vn_in 				: IN 	STD_LOGIC;
		channel_out 		: OUT 	STD_LOGIC_VECTOR(04 DOWNTO 00);
		eoc_out 			: OUT 	STD_LOGIC;
		alarm_out 			: OUT 	STD_LOGIC;
		eos_out 			: OUT 	STD_LOGIC;
		busy_out 			: OUT 	STD_LOGIC
	);
	END COMPONENT;	

	-- IBUF declaration
    component IBUF
    port(I: in STD_LOGIC; O: out STD_LOGIC);
    end component;
	
	--OLED 
		type states_oled is ( Idle, SetupScreen, SendReq, WaitRsp, WRITE_SAMPLE );	
	
		signal state_oled			: states_oled;
		signal state_oled_next		: states_oled;
		
		type r_OLED_SETUP is record
			pos_x  	: INTEGER;
			pos_y 	: INTEGER;
			char  	: std_logic_vector(7 downto 0);
		end record r_OLED_SETUP; 	

		type ArrayOledSetup		is array (0 to 24) of r_OLED_SETUP;
		
		--(0,0) => ADC=0x
		--(0,1) => Offset=0x
		--(0,2) => 
		--(0,3) => Weight=X.XXXkg
		constant OledSetupArray : ArrayOledSetup := ( 	( 0,0,X"41"),( 1,0,X"44"),( 2,0,X"43"),( 3,0,X"3D"),( 4,0,X"30"),( 5,0,X"78"),
		
														( 0,1,X"4F"),( 1,1,X"66"),( 2,1,X"66"),( 3,1,X"73"),( 4,1,X"65"),( 5,1,X"74"),( 6,1,X"3D"),( 7,1,X"30"),( 8,1,X"78"),
														
														
														
														( 0,3,X"57"),( 1,3,X"65"),( 2,3,X"69"),( 3,3,X"67"),( 4,3,X"68"),( 5,3,X"74"),( 6,3,X"3D"),( 8,3,X"2E"),( 12,3,X"6B"),( 13,3,X"67")
													);
		
		signal oled_count			: INTEGER;
		signal oled_req				: STD_LOGIC;
		signal oled_req_addr		: STD_LOGIC_VECTOR(07 downto 00);
		signal oled_req_data		: STD_LOGIC_VECTOR(07 downto 00);
		signal oled_rsp				: STD_LOGIC;

		
	
	signal clk_100M					: STD_LOGIC;
	signal clk_36M 					: STD_LOGIC;
	signal clk_1M  					: STD_LOGIC;
	signal clk_10k  				: STD_LOGIC;
	signal clk_1					: STD_LOGIC;
		
	signal clk_1M_last				: STD_LOGIC;
	signal clk_10k_last				: STD_LOGIC;
	
	signal spi_miso_int		 		: STD_LOGIC;
	
	signal trigger_i2c				: STD_LOGIC;
	signal trigger_spi				: STD_LOGIC;
	
	signal nrst_n                   : std_logic;
	signal uart_rx_data				: STD_LOGIC_VECTOR(07 downto 00);
	signal uart_rx_valid			: STD_LOGIC;
	signal uart_rx_valid_dly1		: STD_LOGIC;
	signal uart_rx_fifo_empty		: STD_LOGIC;
		
	signal uart_tx_data				: STD_LOGIC_VECTOR(07 downto 00);
	signal uart_tx_valid			: STD_LOGIC;
	
	signal dp_data_in_valid			: STD_LOGIC;
	signal dp_data_in    			: STD_LOGIC_VECTOR(07 downto 00);
	
	signal di_in 					: STD_LOGIC_VECTOR(15 DOWNTO 00);
	signal daddr_in 				: STD_LOGIC_VECTOR(06 DOWNTO 00);
	signal den_in 					: STD_LOGIC;
	signal dwe_in 					: STD_LOGIC;
	signal drdy_out 				: STD_LOGIC;
	signal do_out 					: STD_LOGIC_VECTOR(15 DOWNTO 00);	
	signal eoc_out					: STD_LOGIC;
	signal xadc_pwm					: STD_LOGIC;
	
	signal xadc_sample				: STD_LOGIC_VECTOR(11 DOWNTO 00);
	signal xadc_offset				: UNSIGNED(11 DOWNTO 00);
	signal xadc_actual				: UNSIGNED(11 DOWNTO 00);
	signal xadc_calculation			: UNSIGNED(11 DOWNTO 00);
	
	signal calc_2					: STD_LOGIC;
	signal calc_3					: STD_LOGIC;
	signal calc_4					: STD_LOGIC;
	
	signal oled_sample				: STD_LOGIC_VECTOR(11 DOWNTO 00);	
	signal oled_digit_1				: STD_LOGIC_VECTOR(03 downto 00);
	signal oled_digit_2				: STD_LOGIC_VECTOR(03 downto 00);
	signal oled_digit_3				: STD_LOGIC_VECTOR(03 downto 00);
	signal oled_digit_4				: STD_LOGIC_VECTOR(03 downto 00);

		
begin

	led(0)		<= clk_1;   
	led(1)		<= uart_tx_valid;
	led(2)		<= btn(1) OR btn(0);	
	led(3)		<= clk_1;	
	
	led_r       <= ( xadc_pwm & xadc_pwm & xadc_pwm & xadc_pwm );
	led_g       <= ( btn(2) & btn(2) & btn(2) & btn(2) );
	led_b       <= ( btn(3) & btn(3) & btn(3) & btn(3) );	
	
PM_PLL : clk_wiz_0
	port map ( 
	-- Clock in ports
		clk_in1 			=> clk_pad,
	-- Clock out ports  
		clk_100  			=> clk_100M,
		clk_36				=> clk_36M
	);	

PM_CLKDIV_1M: entity work.clk_prescaler
    generic map (
        PRESCALER 			=> 100
    )	
    port map ( 	
        clkin           	=> clk_100M, 
        clkout          	=> clk_1M,
        rst_n           	=> rst_n
       ); 

PM_CLKDIV_1K: entity work.clk_prescaler
    generic map (
        PRESCALER 			=> 100  
    )	
    port map ( 	
        clkin           	=> clk_1M,
        clkout          	=> clk_10k,
        rst_n           	=> rst_n
    ); 	
	   
PM_CLKDIV_1: entity work.clk_prescaler
    generic map (
        PRESCALER 			=> 1000 
    )	
    port map ( 	
        clkin           	=> clk_10k,
        clkout          	=> clk_1,
        rst_n           	=> rst_n
    ); 	
	   
	   
	   
--#################################################################################################	   
--
-- I2C
--
--#################################################################################################	   	   
P_TRIGGER_I2C : process ( clk_100M, rst_n )
	begin
		if ( rst_n = '0' ) then
		
			trigger_i2c			<= '0';
			clk_10k_last		<= '0';
								
		elsif rising_edge( clk_100M ) then			
		
			trigger_i2c			<= '0';
			clk_10k_last		<= clk_10k;
				
			if ( clk_10k='1' and (clk_10k /= clk_10k_last) ) then		--rising edge
				trigger_i2c		<= '1';
			end if;
		end if;	
	end process;


PM_I2C_WRAPPER : ENTITY work.i2c_wrapper
	GENERIC MAP (
		input_clk 						=> 100_000_000, 		--input clock speed from user logic in Hz		--100MHz
		bus_clk   						=>     100_000  		--speed the i2c bus (scl) will run at in Hz		--100kHz
	)				
	PORT MAP (				
		clk_sys    						=> clk_100M,
		rst_n   						=> rst_n,
		
		trigger							=> trigger_i2c,
		
		sda       						=> I2C_SDA,
		scl       						=> I2C_SCL
	);	   
	 
	 
	 
--#################################################################################################	   
--
-- SPI
--
--#################################################################################################
P_TRIGGER_SPI : process ( clk_100M, rst_n )
	begin
		if ( rst_n = '0' ) then
		
			trigger_spi			<= '0';
			clk_1M_last			<= '0';
								
		elsif rising_edge( clk_100M ) then			
		
			trigger_spi			<= '0';
			clk_1M_last			<= clk_1M;
				
			if ( clk_1M='1' and (clk_1M /= clk_1M_last) ) then		--rising edge
				trigger_spi		<= '1';
			end if;
		end if;	
	end process;

--    process(clk_36M,rst_n)
--	begin
--	    if ( rst_n = '0' ) then		
--			spi_miso_int 	<= '0';

--		elsif rising_edge(clk_36M) then
--		    spi_miso_int   <= spi_miso;
--		end if;
--	end process;

-- IBUF instantiation
U1: IBUF port map (I => spi_miso, O => spi_miso_int);
		  
PM_SPI_CONTROLLER : entity work.spi_controller
	PORT MAP (	
		clk_sys		         			=> clk_100M,		
		clk_spi_x2						=> clk_36M,				--36MHz clock generates 18M on SPI interface,
			
		rst_n  		         			=> rst_n,

		trigger							=> trigger_spi,
		
		--IO connections on SPI_CLK                    
			spi_clk						=> spi_clk,
			spi_cs						=> spi_cs,
			spi_miso					=> spi_miso_int,
			spi_mosi					=> spi_mosi,
			spi_rst 					=> open,
			spi_ch 						=> open
	);
	
	 
--#################################################################################################	   
--
-- UART
--
--#################################################################################################	   
PM_UART : entity work.uart
    generic map (
		G_BAUD_RATE  		=> 115200,
		G_CLOCK_FREQ 		=> 100.0e6
    )
    port map (
		clk               	=> clk_100M,
		rst_n               => rst_n,
		
		tx_data_in        	=> uart_tx_data,
		tx_data_wr_in     	=> uart_tx_valid,
		tx_fifo_full_out  	=> open,
		tx_out            	=> uart_tx,
		
		rx_in             	=> uart_rx,		
		rx_data_rd_in     	=> uart_rx_valid,
		rx_data_out       	=> uart_rx_data,
		rx_fifo_empty_out 	=> uart_rx_fifo_empty
    );	

	
	
--#################################################################################################	   
--
-- DATA PIPE LINE
--
--#################################################################################################	
	   
PM_DATA_PROCESS : entity work.data_processing
	generic map (
		G_DATA_WIDTH		=> 8
	)
	port map (
	   --Clocks
		clk					=> clk_100M,
		rst_n				=> rst_n,
		
		--Modes
		mode				=> switch,
		
		--Data Input
		data_in_vld			=> dp_data_in_valid,
		data_in 			=> dp_data_in,
		data_in_rdy			=> open,
				
		--Data Output
		data_out_vld		=> uart_tx_valid,
		data_out 			=> uart_tx_data,
		data_out_rdy		=> '1'
	);
	
P_PIPE_DATA_IN : process ( clk_100M, rst_n )
	begin
		if ( rst_n = '0' ) then
					
			uart_rx_valid			<= '0';
			uart_rx_valid_dly1		<= '0';
			
			dp_data_in_valid		<= '0';
			dp_data_in				<= ( others => '0' );
			
		elsif rising_edge( clk_100M ) then
			uart_rx_valid			<= '0';
			uart_rx_valid_dly1		<= uart_rx_valid;
			dp_data_in_valid		<= '0';
			
			if ( uart_rx_valid='0' and uart_rx_fifo_empty='0' ) then
				uart_rx_valid		<= '1';
			end if;
			
			if ( uart_rx_valid_dly1='1' ) then
				dp_data_in_valid	<= '1';
				dp_data_in			<= uart_rx_data;
			end if;
			
		end if;
	
	end process;	
	
	
	
--#################################################################################################	   
--
-- XADC
--
--#################################################################################################		
nrst_n <= not rst_n;	
	
PM_XADC : xadc_wiz_0
	PORT MAP (
		di_in	 			=> di_in,
		daddr_in 			=> daddr_in,
		den_in 				=> den_in,
		dwe_in 				=> dwe_in,
		drdy_out 			=> drdy_out,
		do_out 				=> do_out,
		
		dclk_in 			=> clk_100M,
		reset_in 			=> nrst_n,
		
		vp_in 				=> vp_in,
		vn_in 				=> vn_in,
		
		channel_out 		=> open,
		eoc_out 			=> eoc_out,
		alarm_out 			=> open,
		eos_out 			=> open,
		busy_out 			=> open
	);
	
	xadc_sample	<= do_out(15 downto 04); 
	
PM_XADC_PWM : entity work.dbg_pwm_out
    generic map ( 
		G_INPUT_BITS 		=> 12
	)
	port map ( 
	   clk  				=> clk_100M,
	   rst_n 				=> rst_n,
	   
	   input_to_sample		=> xadc_sample,
	   	   
       pwm_out 				=> xadc_pwm
    );
	
P_READ_XADC : process ( clk_100M, rst_n )
	begin
		if ( rst_n = '0' ) then
		
			di_in 				<= (others=>'0');
			daddr_in 			<= (others=>'0');
			den_in 				<= '0';
			dwe_in 				<= '0';
								
		elsif rising_edge( clk_100M ) then			
		
			den_in				<= '0';
			daddr_in			<= "0000011";		--0x03 VP/VN value
	
			if ( eoc_out = '1' ) then 				--Do a read after every conversion
				den_in			<= '1';
			end if;
		end if;	
	end process;	
	
P_PROCESS_SAMPLE : process ( clk_100M, rst_n )
	begin
		if ( rst_n = '0' ) then

			xadc_offset			<= ( others => '0' );
			xadc_actual			<= ( others => '0' );
			xadc_calculation	<= ( others => '0' );
			
			--Going to show 0.000 Kgs ( maximum will be 2.048 when sample = 0xFFF			
			oled_digit_1		<= ( others => '0' );
			oled_digit_2		<= ( others => '0' );
			oled_digit_3		<= ( others => '0' );
			oled_digit_4		<= ( others => '0' );
			
			calc_2				<= '0';
			calc_3				<= '0';
			calc_4				<= '0';
		
		elsif rising_edge( clk_100M ) then			
			calc_2				<= '0';
			calc_3				<= '0';
			calc_4				<= '0';

		
			--Offset gets updated if Button 0 pressed
			if ( btn(0) = '1' ) then
				xadc_offset		<= UNSIGNED( xadc_sample );
			end if;
		
			--Actual value is current minus offset
			xadc_actual 		<= UNSIGNED( xadc_sample ) - xadc_offset;
			
			--Convert to user readable text digits
			--Start when drdy_out is set
			
			--First digit												--Only if button 1 is not pressed. Press button 1 to stop conversions leaving screen static
			if ( btn(1)='0' and drdy_out='1' ) then
				calc_2					<= '1';
			
				if ( xadc_actual > 16#FA0# ) then						--d4000 or 2kg
					oled_digit_1		<= "0010";
					xadc_calculation	<= xadc_actual - 16#FA0#;
					
				elsif ( xadc_actual > 16#7D0# ) then					--d2000 or 1kg
					oled_digit_1		<= "0001";
					xadc_calculation	<= xadc_actual - 16#7D0#;
				else
					oled_digit_1		<= "0000";
					xadc_calculation	<= xadc_actual;
				end if;			
			end if;
			
			--Second digit
			if ( calc_2='1' ) then	
				calc_3					<= '1';
				
				if ( xadc_calculation > 16#708# ) then
					oled_digit_2		<= "1001";
					xadc_calculation	<= xadc_calculation - 16#708#;
					
				elsif ( xadc_calculation > 16#640# ) then
					oled_digit_2		<= "1000";
					xadc_calculation	<= xadc_calculation - 16#640#;				
					
				elsif ( xadc_calculation > 16#578# ) then
					oled_digit_2		<= "0111";
					xadc_calculation	<= xadc_calculation - 16#578#;								
				
				elsif ( xadc_calculation > 16#4B0# ) then
					oled_digit_2		<= "0110";
					xadc_calculation	<= xadc_calculation - 16#4B0#;								

				elsif ( xadc_calculation > 16#3E8# ) then
					oled_digit_2		<= "0101";
					xadc_calculation	<= xadc_calculation - 16#3E8#;				
					
				elsif ( xadc_calculation > 16#320# ) then
					oled_digit_2		<= "0100";
					xadc_calculation	<= xadc_calculation - 16#320#;								
				
				elsif ( xadc_calculation > 16#258# ) then
					oled_digit_2		<= "0011";
					xadc_calculation	<= xadc_calculation - 16#258#;								
					
				elsif ( xadc_calculation > 16#190# ) then
					oled_digit_2		<= "0010";
					xadc_calculation	<= xadc_calculation - 16#190#;				
					
				elsif ( xadc_calculation > 16#0C8# ) then
					oled_digit_2		<= "0001";
					xadc_calculation	<= xadc_calculation - 16#0C8#;								
					
				else 
					oled_digit_2		<= "0000";
				end if;
					
				
			end if;

			--Third digit
			if ( calc_3='1' ) then	
				calc_4					<= '1';
				
				if ( xadc_calculation > 16#0B4# ) then
					oled_digit_3		<= "1001";
					xadc_calculation	<= xadc_calculation - 16#0B4#;
					
				elsif ( xadc_calculation > 16#0A0# ) then
					oled_digit_3		<= "1000";
					xadc_calculation	<= xadc_calculation - 16#0A0#;				
					
				elsif ( xadc_calculation > 16#08C# ) then
					oled_digit_3		<= "0111";
					xadc_calculation	<= xadc_calculation - 16#08C#;
				
				elsif ( xadc_calculation > 16#078# ) then
					oled_digit_3		<= "0110";
					xadc_calculation	<= xadc_calculation - 16#078#;								

				elsif ( xadc_calculation > 16#064# ) then
					oled_digit_3		<= "0101";
					xadc_calculation	<= xadc_calculation - 16#064#;				
					
				elsif ( xadc_calculation > 16#050# ) then
					oled_digit_3		<= "0100";
					xadc_calculation	<= xadc_calculation - 16#050#;								
				
				elsif ( xadc_calculation > 16#03C# ) then
					oled_digit_3		<= "0011";
					xadc_calculation	<= xadc_calculation - 16#03C#;								
					
				elsif ( xadc_calculation > 16#028# ) then
					oled_digit_3		<= "0010";
					xadc_calculation	<= xadc_calculation - 16#028#;				
					
				elsif ( xadc_calculation > 16#014# ) then
					oled_digit_3		<= "0001";
					xadc_calculation	<= xadc_calculation - 16#014#;								
					
				else 
					oled_digit_3		<= "0000";
				end if;
				
			end if;
			
			--Fourth digit
			if ( calc_4='1' ) then				
				if ( xadc_calculation > 16#012# ) then
					oled_digit_4		<= "1001";
					
				elsif ( xadc_calculation > 16#010# ) then
					oled_digit_4		<= "1000";			
					
				elsif ( xadc_calculation > 16#00E# ) then
					oled_digit_4		<= "0111";
				
				elsif ( xadc_calculation > 16#00C# ) then
					oled_digit_4		<= "0110";						

				elsif ( xadc_calculation > 16#00A# ) then
					oled_digit_4		<= "0101";				
					
				elsif ( xadc_calculation > 16#008# ) then
					oled_digit_4		<= "0100";							
				
				elsif ( xadc_calculation > 16#006# ) then
					oled_digit_4		<= "0011";						
					
				elsif ( xadc_calculation > 16#004# ) then
					oled_digit_4		<= "0010";		
					
				elsif ( xadc_calculation > 16#002# ) then
					oled_digit_4		<= "0001";
					
				else 
					oled_digit_4		<= "0000";
				end if;
				
			end if;			
						
		end if;	
	end process;
	
	
--#################################################################################################	   
--
-- OLED
--
--#################################################################################################		
	
PM_OLED : entity work.PmodOLEDCtrl
	generic map (
		G_IN_SIM			=> G_IN_SIM
	)
	port map( 
		CLK 				=> clk_100M,
		RST 				=> nrst_n,
		
		CS  				=> pmod_cs,
		SDIN				=> pmod_mosi,
		SCLK				=> pmod_sclk,
		DC					=> pmod_dc,
		RES					=> pmod_res,
		VBAT				=> pmod_vbat,
		VDD					=> pmod_vdd,
		
		req					=> oled_req,
		req_addr			=> oled_req_addr,
		req_data			=> oled_req_data,
		rsp					=> oled_rsp
	);	
			
P_SETUP_OLED : process ( clk_100M, rst_n )

		variable hex_digit	: STD_LOGIC_VECTOR(03 downto 00);

	begin
		if ( rst_n = '0' ) then
			state_oled			<= SetupScreen;
			state_oled_next		<= SetupScreen;
			oled_count			<= 0;
			oled_sample			<= (others=>'0');			
		
			oled_req			<= '0';
			oled_req_addr		<= (others=>'0');
			oled_req_data		<= (others=>'0');			
					
		elsif rising_edge( clk_100M ) then			
				
			case state_oled is
				WHEN SetupScreen =>
				
					oled_req_addr(07 downto 04)	<= STD_LOGIC_VECTOR( to_UNSIGNED( OledSetupArray(oled_count).pos_x ,4 ) );
					oled_req_addr(03 downto 00)	<= STD_LOGIC_VECTOR( to_UNSIGNED( OledSetupArray(oled_count).pos_y ,4 ) );
					
					oled_req_data				<= OledSetupArray(oled_count).char;
					
					state_oled					<= SendReq;
									
					if ( oled_count = OledSetupArray'HIGH ) then 
						state_oled_next			<= IDLE;
					else 
						state_oled_next			<= SetupScreen;
						oled_count				<= oled_count + 1;
					end if;
					
				
				WHEN IDLE => 
					if ( calc_4 = '1' ) then 				--Do a screen update after every conversion
						state_oled				<= WRITE_SAMPLE;
						state_oled_next			<= IDLE;
						oled_count				<= 0;
					end if;	
					

				WHEN WRITE_SAMPLE => 
					case oled_count is
					WHEN 0 => 					oled_req_addr(07 downto 04)	<= "0110";		--(6,0)	
												oled_req_addr(03 downto 00)	<= "0000";													
												hex_digit					:= STD_LOGIC_VECTOR( xadc_actual(11 downto 08) );
				
					WHEN 1 => 					oled_req_addr(07 downto 04)	<= "0111";		--(7,0)
												oled_req_addr(03 downto 00)	<= "0000";				
												hex_digit					:= STD_LOGIC_VECTOR( xadc_actual(07 downto 04) );

					WHEN 2 => 					oled_req_addr(07 downto 04)	<= "1000";		--(8,0)
												oled_req_addr(03 downto 00)	<= "0000";					
												hex_digit					:= STD_LOGIC_VECTOR( xadc_actual(03 downto 00) );												

					WHEN 3 => 					oled_req_addr(07 downto 04)	<= "1001";		--(9,1)	
												oled_req_addr(03 downto 00)	<= "0001";	
												hex_digit					:= STD_LOGIC_VECTOR( xadc_offset(11 downto 08) );
				
					WHEN 4 => 					oled_req_addr(07 downto 04)	<= "1010";		--(10,1)
												oled_req_addr(03 downto 00)	<= "0001";				
												hex_digit					:= STD_LOGIC_VECTOR( xadc_offset(07 downto 04) );

					WHEN 5 => 					oled_req_addr(07 downto 04)	<= "1011";		--(11,1)
												oled_req_addr(03 downto 00)	<= "0001";						
												hex_digit					:= STD_LOGIC_VECTOR( xadc_offset(03 downto 00) );												
				
					WHEN 6 => 					oled_req_addr(07 downto 04)	<= "0111";		--(7,3)
												oled_req_addr(03 downto 00)	<= "0011";
												hex_digit					:= oled_digit_1;

					WHEN 7 => 					oled_req_addr(07 downto 04)	<= "1001";		--(9,3)	
												oled_req_addr(03 downto 00)	<= "0011";	
												hex_digit					:= oled_digit_2;
				
					WHEN 8 => 					oled_req_addr(07 downto 04)	<= "1010";		--(10,3)
												oled_req_addr(03 downto 00)	<= "0011";		
												hex_digit					:= oled_digit_3;												
												
					WHEN 9 => 					oled_req_addr(07 downto 04)	<= "1011";		--(11,3)
												oled_req_addr(03 downto 00)	<= "0011";		
												hex_digit					:= oled_digit_4;

					when others => 				oled_req_addr				<= "11111111";	--Not on screen	
					
					end case;
				
				
				
--					oled_req_addr(07 downto 04)	<= STD_LOGIC_VECTOR( "0110" + to_UNSIGNED(oled_count,4) );
--					oled_req_addr(03 downto 00)	<= "0011";		
--
--					hex_digit					:= oled_sample( (11-(4*oled_count)) downto (08-(4*oled_count)) );
--
					if ( hex_digit <= "1001" ) then
						oled_req_data			<= "0011" & hex_digit;		--hex_digit + 0x30 which is an 0
					else						
						hex_digit				:= STD_LOGIC_VECTOR( UNSIGNED(hex_digit) - to_UNSIGNED(9,4) );
						oled_req_data			<= "0100" & hex_digit;		--hex_digit-10 + 0x41 which is an A
					end if;
					
					state_oled					<= SendReq;
					
					if ( oled_count = 9 ) then 
						state_oled_next			<= IDLE;
					else 
						state_oled_next			<= WRITE_SAMPLE;
						oled_count				<= oled_count + 1;
					end if;					
						
						
				WHEN SendReq => 	
					oled_req					<= '1';
					state_oled					<= WaitRsp;
				
				WHEN WaitRsp => 
					if ( oled_rsp = '1' ) then
						oled_req				<= '0';			
						state_oled				<= state_oled_next;
					end if;						
			end case;
		end if;
	
	end process;	
	
end RTL;
