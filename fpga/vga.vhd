----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:56:23 03/28/2013 
-- Design Name: 
-- Module Name:    vga - Behavioral 
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

entity vga is
	port(
		clk : in std_logic;
		rst : in std_logic;
		ce : in std_logic;
		hs : out std_logic;
		vs : out std_logic;
		sx : out std_logic;
		sy : out std_logic;
		disp : out std_logic
	);
end vga;

architecture Behavioral of vga is
	signal hcount : std_logic_vector(9 downto 0);
	signal vcount : std_logic_vector(9 downto 0);
	signal hdisp : std_logic;
	signal vdisp : std_logic;
begin
	disp <= hdisp and vdisp;
	sx <= '1' when hcount = 144 and ce = '1' else '0';
	sy <= '1' when vcount = 31 and hcount = 144 and ce = '1' else '0';
	process (clk,rst)
	begin
		if (rst = '0') then
			hs <= '0';
			vs <= '0';
			hcount <= (others => '0');
			vcount <= (others => '0');
			hdisp <= '0';
			vdisp <= '0';
		elsif (clk'event and clk = '1') then
			if (ce = '1') then
				hcount <= hcount + 1;
				if (hcount = 96) then
					hs <= '1'; -- Clear horizontal sync, begin back porch
				elsif (hcount = 144) then
					hdisp <= '1';
				elsif (hcount = 784) then
					hdisp <= '0';
				elsif (hcount = 800) then
					hcount <= (others => '0');
					hs <= '0';
					vcount <= vcount + 1;
					if (vcount = 2) then
						vs <= '1'; -- Clear vertical sync
					elsif (vcount = 31) then
						vdisp <= '1'; -- Set vertical ready
						vs <= '1';
					elsif (vcount = 509) then
						vdisp <= '0'; 
					elsif (vcount = 521) then
						vcount <= (others => '0');
						vs <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;

end Behavioral;

