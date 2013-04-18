----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:43:44 03/29/2013 
-- Design Name: 
-- Module Name:    control - Behavioral 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pe_array is
	generic (size : integer := 16);
	port (
		clk : in std_logic;
		rst : in std_logic;
		ce : in std_logic;
		north : in std_logic_vector(size-1 downto 0);
		east : in std_logic_vector(size-1 downto 0);
		west : in std_logic_vector(size-1 downto 0);
		south : in std_logic_vector(size-1 downto 0);
		
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
		
		outdata : out std_logic_vector(size-1 downto 0)
	);
end pe_array;

architecture Behavioral of pe_array is
	type news_t is array(size+1 downto 0) of std_logic_vector(size+1 downto 0);
	signal news : news_t;
begin
	col: for i in 1 to size generate -- Column
		row: for j in 1 to size generate -- Row
			el : entity work.pe port map (
				clk=>clk, 
				rst=>rst, 
				ce=>ce,
				north=>news(i)(j-1),
				east=>news(i+1)(j),
				west=>news(i-1)(j),
				south=>news(i)(j+1),
				clrcar=>clrcar,
				aluop=>aluop,
				invacc=>invacc,
				invout=>invout,
				gpregsel=>gpregsel,
				insel=>insel,
				ram_addr=>ram_addr,
				set_ram=>set_ram,
				set_flag=>set_flag,
				set_news=>set_news,
				output=>news(i)(j));
		end generate;
		news(i)(0) <= north(i-1);
		news(i)(size+1) <= south(i-1);
		news(0)(i) <= west(i-1);
		news(size+1)(i) <= east(i-1);
	end generate;
	news(0)(0) <= '0';
	news(0)(size+1) <= '0';
	news(size+1)(0) <= '0';
	news(size+1)(size+1) <= '0';
	outdata <= news(size)(size downto 1);
			
end Behavioral;

