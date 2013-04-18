----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:45:29 04/17/2013 
-- Design Name: 
-- Module Name:    pe - Behavioral 
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

entity pe is
	port (
		clk : in std_logic;
		rst : in std_logic;
		ce : in std_logic;
		north : in std_logic;
		east : in std_logic;
		west : in std_logic;
		south : in std_logic;
		
		clrcar : in std_logic;
		aluop : in std_logic_vector(2 downto 0);
		invacc : in std_logic;
		invout : in std_logic;
		gpregsel : in std_logic_vector(1 downto 0);
		insel : in std_logic_vector(2 downto 0);
		ram_addr : in std_logic_vector(7 downto 0);
		set_ram : in std_logic;
		set_flag : in std_logic;
		set_news : in std_logic;
		
		output : out std_logic
	);
end pe;

architecture Behavioral of pe is

begin


end Behavioral;

