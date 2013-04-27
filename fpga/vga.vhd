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
	constant WIDTH : integer := 640;
	constant HEIGHT : integer := 480;
	
	constant HFP : integer := WIDTH; -- Horizontal front porch start time
	constant HSP : integer := HFP + 16; -- Horizontal sync pulse start time
	constant HBP : integer := HSP + 96; -- Horizontal back porch start time
	constant HEND : integer := HBP + 48; -- Horizontal end
	
	constant VFP : integer := HEIGHT; -- Vertical front porch start time
	constant VSP : integer := VFP + 2; -- Vertical sync pulse start time
	constant VBP : integer := VSP + 10; -- Vertical back porch start time
	constant VEND : integer := VBP + 29; -- Vertical end
	
	signal hcount : std_logic_vector(9 downto 0);
	signal vcount : std_logic_vector(9 downto 0);
	signal hdisp : std_logic;
	signal vdisp : std_logic;
begin
	disp <= hdisp and vdisp;
	sx <= '1' when hcount = HEND-1 else '0';
	sy <= '1' when vcount = VEND-1 else '0';
	process (clk,rst)
	begin
		if (rst = '0') then
			hdisp <= '1';
			vdisp <= '1';
			hs <= '1';
			vs <= '1';
			hcount <= (others => '0');
			vcount <= (others => '0');
		elsif (clk'event and clk = '1') then
			if (ce = '1') then
				hcount <= hcount + '1';
				if (hcount = HFP-1) then
					hdisp <= '0';
				elsif (hcount = HSP-1) then
					hs <= '0';
				elsif (hcount = HBP-1) then
					hs <= '1';
				elsif (hcount = HEND-1) then
					vcount <= vcount + '1';
					hcount <= (others=>'0');
					hdisp <= '1';
					if (vcount = VFP-1) then
						vdisp <= '0';
					elsif (vcount = VSP-1) then
						vs <= '0';
					elsif (vcount = VBP-1) then
						vs <= '1';
					elsif (vcount = VEND-1) then
						vcount <= (others=>'0');
						vdisp <= '1';
					end if;
				end if;
			end if;
		end if;
	end process;

end Behavioral;

