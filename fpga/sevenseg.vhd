----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    01:46:42 04/05/2013 
-- Design Name: 
-- Module Name:    sevenseg - Behavioral 
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

entity sevenseg is
	port (
		digit : in std_logic_vector(3 downto 0);
		seg : out std_logic_vector(6 downto 0)
	);
	constant D0 : std_logic_vector(3 downto 0) := "0000";
	constant D1 : std_logic_vector(3 downto 0) := "0001";
	constant D2 : std_logic_vector(3 downto 0) := "0010";
	constant D3 : std_logic_vector(3 downto 0) := "0011";
	constant D4 : std_logic_vector(3 downto 0) := "0100";
	constant D5 : std_logic_vector(3 downto 0) := "0101";
	constant D6 : std_logic_vector(3 downto 0) := "0110";
	constant D7 : std_logic_vector(3 downto 0) := "0111";
	constant D8 : std_logic_vector(3 downto 0) := "1000";
	constant D9 : std_logic_vector(3 downto 0) := "1001";
	constant DA : std_logic_vector(3 downto 0) := "1010";
	constant DB : std_logic_vector(3 downto 0) := "1011";
	constant DC : std_logic_vector(3 downto 0) := "1100";
	constant DD : std_logic_vector(3 downto 0) := "1101";
	constant DE : std_logic_vector(3 downto 0) := "1110";
	constant DF : std_logic_vector(3 downto 0) := "1111";

end sevenseg;

architecture Behavioral of sevenseg is

begin
	seg(0) <= '1' when digit = D1 or digit = D4 or digit = DB or digit = DD else '0';
	seg(1) <= '1' when digit = D5 or digit = D6 or digit = DB or digit = DC or digit = DE or digit = DF else '0';
	seg(2) <= '1' when digit = D2 or digit = DC or digit = DE or digit = DF else '0';
	seg(3) <= '1' when digit = D1 or digit = D4 or digit = D7 or digit = DA or digit = DF else '0';
	seg(4) <= '1' when digit = D1 or digit = D4 or digit = D5 or digit = D7 or digit = D9 else '0';
	seg(5) <= '1' when digit = D1 or digit = D2 or digit = D3 or digit = D7 or digit = DD else '0';
	seg(6) <= '1' when digit = D1 or digit = D7 or digit = D0 or digit = DC else '0';

end Behavioral;

