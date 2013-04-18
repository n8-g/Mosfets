----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:33:27 03/29/2013 
-- Design Name: 
-- Module Name:    ram - Behavioral 
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

entity async_ram is
	generic ( cycle : integer := 7 );
	port (
		clk : in std_logic;
		rst : in std_logic;
		en : in std_logic;
		we : in std_logic;
		addr : in std_logic_vector(25 downto 0);
		din : in std_logic_vector(15 downto 0);
		dout : out std_logic_vector(15 downto 0);
		ready : out std_logic;
		-- IO pins to external memory
		memadr : out std_logic_vector(25 downto 0);
		memdb : inout std_logic_vector(15 downto 0);
		memoe : out std_logic;
		memwr : out std_logic;
		memcs : out std_logic
	);
end async_ram;

architecture Behavioral of async_ram is
	signal counter : std_logic_vector(4 downto 0);
	signal wr : std_logic;
	signal busy_reg : std_logic;
begin
	memadr <= addr;
	memoe <= not busy_reg or wr;
	memwr <= not (busy_reg and wr);
	memcs <= not busy_reg;
	memdb <= din when (busy_reg and wr) = '1' else -- Data in
			(others=>'Z'); -- Don't drive the lines, its an input
	dout <= memdb;
	ready <= '1' when counter = (cycle-1) else '0';
	process (clk,rst)
	begin
		if (rst = '0') then
			busy_reg <= '0';
		elsif (clk'event and clk = '1') then
			if (busy_reg = '1') then
				if (counter = cycle-1) then 
					busy_reg <= '0';
				end if;
				counter <= counter + '1';
			elsif (en = '1') then
				wr <= we;
				busy_reg <= '1';
				counter <= (others => '0');
			end if;
		end if;
	end process;
end Behavioral;