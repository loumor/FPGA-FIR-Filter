library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.Std_logic_signed.all;

entity my_FIR_filter is
	generic (
        G_DATA_WIDTH    : INTEGER := 32
    );
	port(   
		CLK          : in std_logic;
        rst_n        : in std_logic;
        data_in      : in std_logic_vector(7 downto 0); --input signal
        data_in_vld  : in std_logic;
        data_out     : out std_logic_vector(7  downto 0);  --filter output
        data_out_vld : out std_logic        
    );
end my_FIR_filter;

architecture behav of my_FIR_filter is

    --Data PIPELINE internal signal
    signal pipe_2_vld    : STD_LOGIC;
    signal pipe_2_data     : STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 00); 

    constant c1 : signed(31 downto 0) := "11111111101010101011100111100010"; -- Twos complement first bit is the signed and decimal (eg. -1.01010) 
    constant c2 : signed(31 downto 0) := "11111111100101001000100000111110";
    constant c3 : signed(31 downto 0) := "11111111100101100011000010010000";
    constant c4 : signed(31 downto 0) := "11111111101111111110001000111110";
    constant c5 : signed(31 downto 0) := "00000000001000010010111011100001";
    constant c6 : signed(31 downto 0) := "00000000110001100011011100001101";
    constant c7 : signed(31 downto 0) := "00000001101101001110011000011111";
    constant c8 : signed(31 downto 0) := "00000010111010101100000001010110";
    constant c9 : signed(31 downto 0) := "00000100010110111011101000111001";
    constant c10 : signed(31 downto 0) := "00000101111100100110110010000100";   
    constant c11 : signed(31 downto 0) := "00000111100100011100000010101110";  
    constant c12 : signed(31 downto 0) := "00001001000101111111001000001000";  
    constant c13 : signed(31 downto 0) := "00001010011000101000000101001110";  
    constant c14 : signed(31 downto 0) := "00001011010100101000100100001100";   
    constant c15 : signed(31 downto 0) := "00001011110100001100100110110000";    
    constant c16 : signed(31 downto 0) := "00001011110100001100100110110000"; 
    constant c17 : signed(31 downto 0) := "00001011010100101000100100001100";  
    constant c18 : signed(31 downto 0) := "00001010011000101000000101001110"; 
    constant c19 : signed(31 downto 0) := "00001001000101111111001000001000"; 
    constant c20 : signed(31 downto 0) := "00000111100100011100000010101110"; 
    constant c21 : signed(31 downto 0) := "00000101111100100110110010000100";  
    constant c22 : signed(31 downto 0) := "00000100010110111011101000111001";   
    constant c23 : signed(31 downto 0) := "00000010111010101100000001010110";   
    constant c24 : signed(31 downto 0) := "00000001101101001110011000011111";   
    constant c25 : signed(31 downto 0) := "00000000110001100011011100001101";   
    constant c26 : signed(31 downto 0) := "00000000001000010010111011100001";   
    constant c27 : signed(31 downto 0) := "11111111101111111110001000111110";    
    constant c28 : signed(31 downto 0) := "11111111100101100011000010010000";
    constant c29 : signed(31 downto 0) := "11111111100101001000100000111110";
    constant c30 : signed(31 downto 0) := "11111111101010101011100111100010";

    
    signal x_in : signed (7 downto 0);
    signal y_out : signed (7 downto 0) := (others => '0');
    -- 32 Bits + 8 Bits gives 40 bits for M, Add, Q
    signal M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12, M13, M14, M15, M16, M17, M18, M19, M20, M21, M22, M23, M24, M25, M26, M27, M28, M29 : signed(39 downto 0) := (others => '0'); 
    signal add1, add2, add3, add4, add5, add6, add7, add8, add9, add10, add11, add12, add13, add14, add15, add16, add17, add18, add19, add20, add21, add22, add23, add24, add25, add26, add27, add28, add29 : signed(39 downto 0) := (others=>'0');
    signal  Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8, Q9, Q10, Q11, Q12, Q13, Q14, Q15, Q16, Q17, Q18, Q19, Q20, Q21, Q22, Q23, Q24, Q25, Q26, Q27, Q28, Q29 : signed(39 downto 0) := (others=>'0'); 
    
       
begin                		                     	                     

        -- multipliers   
    M0 <= c1* x_in; 
    M1 <= c2* x_in;
    M2 <= c3* x_in;
    M3 <= c4* x_in;
    M4 <= c5* x_in;
    M5 <= c6* x_in;
    M6 <= c7* x_in;
    M7 <= c8* x_in;
    M8 <= c9* x_in;
    M9 <= c10* x_in;
    M10 <= c11* x_in;
    M11 <= c12* x_in;
    M12 <= c13* x_in;
    M13 <= c14* x_in;
    M14 <= c15* x_in;
    M15 <= c16* x_in;
    M16 <= c17* x_in;
    M17 <= c18* x_in;
    M18 <= c19* x_in;
    M19 <= c20* x_in;
    M20 <= c21* x_in;
    M21 <= c22* x_in;
    M22 <= c23* x_in;
    M23 <= c24* x_in;
    M24 <= c25* x_in;
    M25 <= c26* x_in;
    M26 <= c27* x_in;
    M27 <= c28* x_in;
    M28 <= c29* x_in;
    M29 <= c30* x_in;    
    
    
    -- adders   
    add29 <= M0 + Q29; 
    add28 <= M1 + Q28;  
    add27 <= M2 + Q27;  
    add26 <= M3 + Q26;  
    add25 <= M4 + Q25;  
    add24 <= M5 + Q24;  
    add23 <= M6 + Q23;  
    add22 <= M7 + Q22;  
    add21 <= M8 + Q21;  
    add20 <= M9 + Q20;  
    add19 <= M10 + Q19;  
    add18 <= M11 + Q18;  
    add17 <= M12 + Q17;
    add16 <= M13 + Q16;
    add15 <= M14 + Q15;
    add14 <= M15 + Q14;
    add13 <= M16 + Q13;
    add12 <= M17 + Q12;
    add11 <= M18 + Q11;
    add10 <= M19 + Q10;
    add9 <= M20 + Q9;
    add8 <= M21 + Q8;
    add7 <= M22 + Q7;
    add6 <= M23 + Q6;
    add5 <= M24 + Q5;
    add4 <= M25 + Q4;
    add3 <= M26 + Q3;
    add2 <= M27 + Q2;
    add1 <= M28 + Q1;
  
    x_in <= signed(data_in); 
    -- Take 8 MSB for the UART 
    y_out <= add29(38 downto 31);
       
    P_DATA_OUT : process ( clk, rst_n )
        begin
            if ( rst_n = '0' ) then                    
    
                pipe_2_vld        <= '0';
                pipe_2_data       <= ( others=>'0' );        
                data_out_vld      <= '0';
                data_out          <= ( others=>'0' );
                                
            elsif rising_edge( clk ) then
                
                    if ( data_in_vld    = '1' ) then 
                         pipe_2_vld    <= '1';  
                         
                         Q1 <= M29;
                         Q2 <= add1;
                         Q3 <= add2;
                         Q4 <= add3;
                         Q5 <= add4;
                         Q6 <= add5;
                         Q7 <= add6;
                         Q8 <= add7;
                         Q9 <= add8;
                         Q10 <= add9;
                         Q11 <= add10;
                         Q12 <= add11;
                         Q13 <= add12;
                         Q14 <= add13;
                         Q15 <= add14;
                         Q16 <= add15;
                         Q17 <= add16;
                         Q18 <= add17;
                         Q19 <= add18;
                         Q20 <= add19;
                         Q21 <= add20;
                         Q22 <= add21;
                         Q23 <= add22;
                         Q24 <= add23;
                         Q25 <= add24;
                         Q26 <= add25;
                         Q27 <= add26;
                         Q28 <= add27;
                         Q29 <= add28;                  
                             
                         pipe_2_data <= std_logic_vector(y_out);     
                                                  
                    else
                        pipe_2_vld        <= '0';                
                    end if;
                
                    if ( pipe_2_vld='1' ) then 
                        data_out_vld    <= '1';  
                        
                        data_out <= pipe_2_data;

                    else
                        data_out_vld    <= '0';                    
                    end if;
                              
            end if;    
        end process;        
end behav; 

