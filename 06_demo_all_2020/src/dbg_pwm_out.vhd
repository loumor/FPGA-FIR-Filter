----------------------------------------------------------------------------------
--
-- PWM output for debugging
-- Samples a signal at the start of the PWM cycle whilst raising an output
-- Counts until the value sampled is reached then drops PWM
-- Wraps when the full count is reached
--
----------------------------------------------------------------------------------

library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.NUMERIC_STD.all;

entity dbg_pwm_out is
    generic ( G_INPUT_BITS : integer);
	port ( 
	   clk  			: 	IN  	STD_LOGIC;
	   rst_n 			: 	IN  	STD_LOGIC;
	   
	   input_to_sample	: 	IN		STD_LOGIC_VECTOR( G_INPUT_BITS-1 downto 00 );
	   	   
       pwm_out 			: 	OUT  	STD_LOGIC	   
    );
end dbg_pwm_out;



architecture behavioral of dbg_pwm_out is

	signal counter	: UNSIGNED	( G_INPUT_BITS-1 downto 00 );
	signal sample	: UNSIGNED	( G_INPUT_BITS-1 downto 00 );

begin

	P_COUNTER : process( clk, rst_n )

	begin
		if ( rst_n = '0' ) then
		
			pwm_out 		<= '0';
			counter			<= ( others => '0' );
			sample			<= ( others => '0' );
			
		elsif rising_edge( clk ) then
				
			if ( counter = 0 ) then
				pwm_out		<= '1';
				sample		<= UNSIGNED( input_to_sample );
			end if;

			if ( counter = sample ) then
				pwm_out		<= '0';
			end if;					
					
			counter			<= counter + 1;
		end if;
	end process P_COUNTER;

end behavioral;

