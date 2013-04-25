----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:25:59 04/17/2013 
-- Design Name: 
-- Module Name:    onepe - Behavioral 
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
use WORK.ALU_OP.ALL;
use WORK.PE_CONST.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity onepe is
	port(
		clk : in std_logic;
		btn : in std_logic_vector(4 downto 0);
		sw : in std_logic_vector(7 downto 0);
		led : out std_logic_vector(7 downto 0);
		memadr : out std_logic_vector(25 downto 0);
		memdb : inout std_logic_vector(15 downto 0);
		memoe : out std_logic;
		memwr : out std_logic;
		flashcs : out std_logic;
		flashrp : out std_logic;
		vgaRed : out std_logic_vector(2 downto 0);
		vgaGreen : out std_logic_vector(2 downto 0);
		vgaBlue : out std_logic_vector(2 downto 1);
		Hsync : out std_logic;
		Vsync : out std_logic;
		seg : out std_logic_vector(7 downto 0);
		an : out std_logic_vector(3 downto 0)
	);
end onepe;

architecture Behavioral of onepe is
	signal rst : std_logic;
	signal addr : std_logic_vector(3 downto 0);
	signal ce : std_logic;
	signal start : std_logic;
	signal halt : std_logic;
	signal output : std_logic;
	signal west : std_logic;
	signal load : std_logic;
	
	signal clrcar : std_logic;
	signal aluop : std_logic_vector(2 downto 0);
	signal invacc : std_logic;
	signal invout : std_logic;
	signal gpregsel : std_logic_vector(1 downto 0);
	signal insel : std_logic_vector(2 downto 0);
	signal ram_addr : std_logic_vector(7 downto 0);
	signal set_ram : std_logic;
	signal set_flag : std_logic;
	signal set_news : std_logic;
begin
	pe1 : entity work.pe port map (
		clk=>clk,
		rst=>rst,
		ce=>ce,
		north=>sw(3),
		east=>sw(2),
		west=>west,
		south=>sw(1),
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
		output=>output
	);
	led <= (
		7 => halt,
		6 => ce,
		5 => '0',
		4 => output,
		3 => sw(3),
		2 => sw(2),
		1 => sw(1),
		0 => sw(0)
	);
	seg <= (others=>'1');
	an <= (others=>'1');
	ce <= start and (not halt);
	rst <= not btn(1);
	clrcar <= '0';
	invacc <= '0';
	gpregsel <= "00";
	ram_addr <= x"FF";
	west <= sw(4) when load = '1' else sw(0);
	
	memadr <= (others=>'0');
	memdb <= (others=>'Z');
	memoe <= '1';
	memwr <= '1';
	flashcs <= '1';
	flashrp <= '1';
	vgaRed <= (others=>'0');
	vgaGreen <= (others=>'0');
	vgaBlue <= (others=>'0');
	Hsync <= '0';
	Vsync <= '0';
	
	instr_rom : process (addr)
	begin
		case addr is
			when "0000" => load<='1';aluop<=OP_CPY;invout<='0';insel<=IN_W;set_ram<='1';set_flag<='0';set_news<='1';halt<='0'; -- Load RAM from West - sw(4)
			when "0001" => load<='0';aluop<=OP_CPY;invout<='1';insel<=IN_R;set_ram<='0';set_flag<='1';set_news<='0';halt<='0'; -- Disable white pixels
			when "0010" => load<='0';aluop<=OP_CPY;invout<='0';insel<=IN_N;set_ram<='0';set_flag<='0';set_news<='0';halt<='0'; -- Load accumulator from N
			when "0011" => load<='0';aluop<=OP_OR; invout<='0';insel<=IN_E;set_ram<='0';set_flag<='0';set_news<='0';halt<='0'; -- OR in E
			when "0100" => load<='0';aluop<=OP_OR; invout<='0';insel<=IN_W;set_ram<='0';set_flag<='0';set_news<='0';halt<='0'; -- OR in W
			when "0101" => load<='0';aluop<=OP_OR; invout<='1';insel<=IN_S;set_ram<='1';set_flag<='0';set_news<='1';halt<='0'; -- OR in S, set news,ram to inverse
			when others => load<='0';aluop<=OP_CPY;invout<='0';insel<=IN_W;set_ram<='0';set_flag<='0';set_news<='0';halt<='1'; -- HALT
		end case;
	end process;
	
	process(clk,rst) 
	begin
		if (rst = '0') then
			addr <= (others=>'0');
			start <= '0';
		elsif (rising_edge(clk)) then
			if (ce = '1') then
				addr <= addr + '1';
			elsif (btn(0) = '1') then
				start <= '1';
			end if;
		end if;
	end process;
end Behavioral;

