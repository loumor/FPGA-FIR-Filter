
library IEEE;
use IEEE.std_logic_1164.all;

entity clk_prescaler is
    generic (PRESCALER : integer);
	port ( 
	   clkin 	: 	in  	std_logic;
       clkout 	: 	out  	std_logic;
	   rst_n 	: 	in  	std_logic
    );
end clk_prescaler;

architecture behavioral of clk_prescaler is

	signal COUNT 	: integer range 0 to PRESCALER-1;

	signal clk_int	: STD_LOGIC;
begin

	clkout	<= clk_int;

DIVIDE : process(clkin, rst_n)

begin
	if rst_n = '0' then
		clk_int		<= '0';
		COUNT 		<= PRESCALER-1;		
	elsif rising_edge(clkin) then
		if COUNT = 0 then
			clk_int	<= not clk_int;

			COUNT 	<= PRESCALER-1;
		else
			COUNT   <= COUNT - 1;
		end if;
	end if;
end process DIVIDE;

end behavioral;

