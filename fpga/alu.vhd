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

entity alu is
	port(		input:			in		std_logic;
				acc:				in		std_logic;
				carry_in:		in		std_logic;
				alu_op:			in		std_logic_vector(2 downto 0);
				invacc:			in		std_logic;
				invout:			in		std_logic;
				output:			out	std_logic;
				carry_out:		out	std_logic
				);
end alu;

architecture Behavioral of alu is
signal	ops:	std_logic_vector(7 downto 0);
signal	acc_s:	std_logic;
signal 	output_s:	std_logic;

begin

	with invacc select
	acc_s <= acc when '0',
				not acc when '1',
				'0' when others;
						 
	with invout select
	output <= output_s when '0',
				 not output_s when '1',
				 '0' when others;
				 

	ops(0) <= input;
	ops(1) <= input and acc_s;
	ops(2) <= input xor acc_s; 	 
	ops(3) <= input or acc_s;
	ops(4) <= ops(5) xor carry_in; -- Doesn't look rightt
	ops(5) <= '0';
	ops(6) <= '1';
	ops(7) <= ops(3) or ops(6); -- Doesn't look right

	with alu_op select
	output_s <= ops(7) when "111", 
					 ops(6) when "110",
					 ops(5) when "101",
					 ops(4) when "100",
					 ops(3) when "011",
					 ops(2) when "010",
					 ops(1) when "001",
					 ops(0) when "000",
					 '0' when others;
	
carry_out <= ops(7);

end Behavioral;

