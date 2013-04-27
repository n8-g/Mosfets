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
use WORK.ALU_OP.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity alu is
	port(		
		input:			in		std_logic;
		acc:				in		std_logic;
		carry_in:		in		std_logic;
		aluop:			in		std_logic_vector(2 downto 0);
		invacc:			in		std_logic;
		invout:			in		std_logic;
		output:			out	std_logic;
		carry_out:		out	std_logic
	);
end alu;

architecture Behavioral of alu is
signal	acc_s:	std_logic;
signal 	output_s:	std_logic;
signal	carry_s: std_logic;
signal 	in_and_acc_s: std_logic;
signal 	in_xor_acc_s: std_logic;
begin
	acc_s <= acc xor invacc;
	in_and_acc_s <= input and acc_s;
	in_xor_acc_s <= input xor acc_s;
	carry_s <= in_and_acc_s or (in_xor_acc_s and carry_in);
	with aluop select
		output_s <= input when OP_CPY,
						in_and_acc_s when OP_AND,
						in_xor_acc_s when OP_XOR,
						input or acc_s when OP_OR,
						in_xor_acc_s xor carry_in when OP_SUM,
						'0' when OP_CLR,
						'1' when OP_SET,
						carry_s when OP_CAR,
						'0' when others;
	output <= output_s xor invout;
	carry_out <= carry_s;
end Behavioral;

