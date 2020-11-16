----------------------------------------------------------------------------------
-- Company: Digilent Inc.
-- Engineer: Ryan Kim
-- 
-- Create Date:    14:35:33 10/10/2011 
-- Module Name:    PmodOLEDCtrl - Behavioral 
-- Project Name:   PmodOLED Demo
-- Tool versions:  ISE 13.2
-- Description:    Top level controller that controls the PmodOLED blocks
--
-- Revision: 1.1
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------
library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use ieee.std_logic_unsigned.ALL;
	use ieee.std_logic_arith.all;

entity PmodOLEDCtrl is
	generic (
		G_IN_SIM	: INTEGER := 0
	);
	Port ( 
		CLK 		: in  	STD_LOGIC;
		RST 		: in	STD_LOGIC;
		CS  		: out 	STD_LOGIC;
		SDIN		: out 	STD_LOGIC;
		SCLK		: out 	STD_LOGIC;
		DC			: out 	STD_LOGIC;
		RES			: out 	STD_LOGIC;
		VBAT		: out 	STD_LOGIC;
		VDD			: out 	STD_LOGIC;
		
		--User Interface
		req			: IN	STD_LOGIC;
		req_addr	: IN    STD_LOGIC_VECTOR(07 downto 00);
		req_data	: IN    STD_LOGIC_VECTOR(07 downto 00);
		rsp			: OUT	STD_LOGIC		
	);
end PmodOLEDCtrl;

architecture Behavioral of PmodOLEDCtrl is

type states is (Idle,
					OledInitialize,
					OledUser,
					Done);

signal current_state 	: states := Idle;

signal init_en			: STD_LOGIC := '0';
signal init_done		: STD_LOGIC;
signal init_cs			: STD_LOGIC;
signal init_sdo			: STD_LOGIC;
signal init_sclk		: STD_LOGIC;
signal init_dc			: STD_LOGIC;

signal user_en			: STD_LOGIC := '0';
signal user_cs			: STD_LOGIC;
signal user_sdo			: STD_LOGIC;
signal user_sclk		: STD_LOGIC;
signal user_dc			: STD_LOGIC;
signal user_done		: STD_LOGIC;

begin

PM_Init		: entity work.OledInit 
	port map(CLK, RST, init_en, 	  init_cs,    init_sdo,    init_sclk,    init_dc,    RES, VBAT, VDD, init_done);
	
PM_UserDisp : entity work.OledUser
    port map ( 	
		CLK 		=> CLK,
		RST 		=> RST,
		EN			=> user_en,
		CS  		=> user_cs,
		SDO			=> user_sdo,
		SCLK		=> user_sclk,
		DC			=> user_dc,
		FIN  		=> user_done,
					
		--User Interface
		req			=> req,
		req_addr	=> req_addr,
		req_data	=> req_data,
		rsp			=> rsp
	);
	
	--MUXes to indicate which outputs are routed out depending on which block is enabled
	CS 		<= init_cs 		when (current_state = OledInitialize) else user_cs;
	SDIN 	<= init_sdo 	when (current_state = OledInitialize) else user_sdo;
	SCLK 	<= init_sclk 	when (current_state = OledInitialize) else user_sclk;
	DC 		<= init_dc 		when (current_state = OledInitialize) else user_dc;
	--END output MUXes
	
	--MUXes that enable blocks when in the proper states
	init_en <= '1' 			when (current_state = OledInitialize) else '0';
	user_en <= '1' 			when (current_state = OledUser) 	  else '0';
	--END enable MUXes
	
	process(CLK)
	begin
		if(rising_edge(CLK)) then
			if(RST = '1') then
				current_state <= Idle;
			else
				case(current_state) is
					when Idle =>
					
						if ( G_IN_SIM=1 ) then			--straight to user display -- skip the slow initialize
							current_state <= OledUser;
						else 							
							current_state <= OledInitialize;
						end if;
						
					--Go through the initialization sequence
					when OledInitialize =>
						if(init_done = '1') then
							current_state <= OledUser;
						end if;
					--Do example and Do nothing when finished
					when OledUser =>
						if(user_done = '1') then
							current_state <= Done;
						end if;
					--Do Nothing
					when Done =>
						current_state <= Done;
					when others =>
						current_state <= Idle;
				end case;
			end if;
		end if;
	end process;
	
	
end Behavioral;

