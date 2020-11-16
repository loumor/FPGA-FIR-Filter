
LIBRARY ieee;
	USE ieee.std_logic_1164.all;
	USE ieee.std_logic_unsigned.all;

ENTITY i2c_wrapper IS
  GENERIC(
    input_clk 	: INTEGER 	:= 50_000_000; 					--input clock speed from user logic in Hz
    bus_clk   	: INTEGER 	:= 400_000);   					--speed the i2c bus (scl) will run at in Hz
  PORT(
    clk_sys   	: IN    	STD_LOGIC;                    	--system clock
    rst_n   	: IN     	STD_LOGIC;                    	--active low reset
	
	trigger		: IN     	STD_LOGIC;
	
    sda       	: INOUT  	STD_LOGIC;                    	--serial data output of i2c bus
    scl       	: INOUT  	STD_LOGIC);                   	--serial clock output of i2c bus
END i2c_wrapper;

ARCHITECTURE logic OF i2c_wrapper IS

	type T_SM_I2C	is 		( WAIT_TRIGGER, I2C_WRITE_0, I2C_WRITE_1, I2C_WRITE_DATA, I2C_WRITE_END, 
											I2C_READ_0,  I2C_READ_1,  I2C_READ_2,	  I2C_WAIT_BUSY );
	
	signal sm_i2c			: T_SM_I2C;
	signal sm_i2c_next		: T_SM_I2C;
	signal cmd_is_write		: STD_LOGIC;

 
	signal i2c_ena			: STD_LOGIC;
	signal i2c_addr			: STD_LOGIC_VECTOR(06 DOWNTO 00);	
	signal i2c_rw			: STD_LOGIC;
	signal i2c_data_wr		: STD_LOGIC_VECTOR(07 DOWNTO 00);	
	signal i2c_busy			: STD_LOGIC;
	signal i2c_busy_last	: STD_LOGIC;
	signal i2c_data_rd		: STD_LOGIC_VECTOR(07 DOWNTO 00);	
	signal i2c_ack_error	: STD_LOGIC;
 
 
	signal eeprom_addr		: STD_LOGIC_VECTOR(14 DOWNTO 00);	
	
	signal data_rd			: STD_LOGIC_VECTOR(15 DOWNTO 00);	
 
BEGIN

PM_I2C_MASTER : ENTITY work.i2c_master
	GENERIC MAP (
		input_clk 			=> input_clk,
		bus_clk   			=> bus_clk
	)					
	PORT MAP (					
		clk       			=> clk_sys,
		reset_n   			=> rst_n,
		ena       			=> i2c_ena,				-- latch in command
		addr      			=> i2c_addr,			-- address of target slave
		rw        			=> i2c_rw,				-- '0' is write, '1' is read
		data_wr   			=> i2c_data_wr,			-- data to write to slave
		busy      			=> i2c_busy,			-- indicates transaction in progress
		data_rd   			=> i2c_data_rd,			-- data read from slave
		ack_error 			=> i2c_ack_error,		-- flag if improper acknowledge from slave
						
		sda       			=> sda,
		scl       			=> scl
	);

P_I2C_CONTROL : process ( clk_sys, rst_n )
	begin
		if ( rst_n = '0' ) then
		
			cmd_is_write	<= '1';
			sm_i2c			<= WAIT_TRIGGER;
			sm_i2c_next		<= WAIT_TRIGGER;
		
			i2c_ena			<= '0';
			i2c_addr      	<= (others=> '0');
			i2c_rw 			<= '0';
			i2c_data_wr   	<= (others=> '0');
			i2c_busy_last	<= '0';
			
			eeprom_addr   	<= (others=> '0');
		
		elsif rising_edge( clk_sys ) then	
			i2c_busy_last	<= i2c_busy;
		
					
			case ( sm_i2c ) is
			when WAIT_TRIGGER =>
			
				if ( trigger='1' ) then 
					if ( cmd_is_write='1' ) then 
						sm_i2c		<= I2C_WRITE_0;
					else 
						sm_i2c		<= I2C_READ_0;
					end if;
				end if;		

				
				
			when I2C_WRITE_0 => 
				i2c_ena			<= '1';
				i2c_rw 			<= '0';      			-- I2C WRITE
				i2c_addr      	<= "1010000";			-- I2C EEPROM address
				i2c_data_wr		<= "01010101";			--'0' & eeprom_addr(14 downto 08);
				
				sm_i2c			<= I2C_WAIT_BUSY;
				sm_i2c_next		<= I2C_WRITE_1;

			when I2C_WRITE_1 => 
				i2c_data_wr		<= "00000001";			--eeprom_addr(07 downto 00);		
				
				sm_i2c			<= I2C_WAIT_BUSY;
				sm_i2c_next		<= I2C_WRITE_DATA;		

			when I2C_WRITE_DATA =>
				i2c_data_wr		<= "11000011";
				
				sm_i2c			<= I2C_WAIT_BUSY;
				sm_i2c_next		<= I2C_WRITE_END;

			when I2C_WRITE_END =>
				i2c_ena 		<= '0'; 
				cmd_is_write	<= '0';
				
				if ( i2c_busy = '0' ) then
					sm_i2c		<= WAIT_TRIGGER;
				end if;
				
				
				
			when I2C_READ_0 => 	
				i2c_ena			<= '1';
				i2c_rw 			<= '1';      			-- I2C READ
				i2c_addr      	<= "1010000";			-- I2C EEPROM address
				
				sm_i2c			<= I2C_WAIT_BUSY;
				sm_i2c_next		<= I2C_READ_1;				
				
			when I2C_READ_1 => 
				sm_i2c_next		<= I2C_READ_2;				
			
				if ( i2c_busy = '0' ) then 
					sm_i2c					<= I2C_WAIT_BUSY;
					data_rd(15 DOWNTO 08) 	<= i2c_data_rd;
				end if;

			when I2C_READ_2 => 
				cmd_is_write	<= '1';					--Next is WRITE
				sm_i2c_next		<= WAIT_TRIGGER;				
			
				if ( i2c_busy = '0' ) then 
					sm_i2c					<= I2C_WAIT_BUSY;
					data_rd(07 DOWNTO 00) 	<= i2c_data_rd;
				end if;				

				
				
			when I2C_WAIT_BUSY => 
				if ( i2c_busy_last='0' and i2c_busy='1' ) then
					sm_i2c		<= sm_i2c_next;
				end if;
			
			end case;
		
		end if;	
	end process;
  
END logic;
