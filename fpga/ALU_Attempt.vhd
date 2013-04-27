----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:21:36 03/25/2013 
-- Design Name: 
-- Module Name:    ALU_Attempt - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU_Attempt is
	port(		input:			in		std_logic;
				acc:				in		std_logic;
				carry_in:		in		std_logic;
				big_mux:			in		std_logic_vector(2 downto 0);
				small_mux_a:	in		std_logic;
				small_mux_b:	in		std_logic;
				output:			out	std_logic;
				carry_out:		out	std_logic
				);
end ALU_Attempt;

architecture Behavioral of ALU_Attempt is
signal	eight_to_one:	std_logic_vector(7 downto 0);
signal	two_to_one_a:	std_logic;
signal 	two_to_one_b:	std_logic;

begin

	with small_mux_a select
	two_to_one_a <= acc when '0',
						 not acc when '1',
						 '0' when others;
						 
	with small_mux_b select
	output <= two_to_one_b when '0',
				 not two_to_one_b when '1',
				 '0' when others;
				 

eight_to_one(0) <= input;
eight_to_one(1) <= input and two_to_one_a;
eight_to_one(2) <= input xor two_to_one_a; 	 
eight_to_one(3) <= input or two_to_one_a;
eight_to_one(4) <= eight_to_one(2) xor carry_in;
eight_to_one(5) <= '0';
eight_to_one(6) <= '1';
eight_to_one(7) <= eight_to_one(1) or eight_to_one(4);

	with big_mux select
	two_to_one_b <= eight_to_one(7) when "111", 
					 	 eight_to_one(6) when "110",
						 eight_to_one(5) when "101",
						 eight_to_one(4) when "100",
						 eight_to_one(3) when "011",
						 eight_to_one(2) when "010",
						 eight_to_one(1) when "001",
						 eight_to_one(0) when "000",
						 '0' when others;
	
carry_out <= eight_to_one(7);

end Behavioral;

