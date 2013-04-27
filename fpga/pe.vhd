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
use work.PE_CONST.ALL;
use work.ALU_OP.ALL;

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
	signal alu_out : std_logic;
	signal alu_carry : std_logic;
	signal ram_we : std_logic;
	signal ram_data : std_logic;
	signal input : std_logic;
	signal reg_acc : std_logic;
	signal reg_carry : std_logic;
	signal reg_flag : std_logic;
	signal reg_x : std_logic;
	signal reg_y : std_logic;
	signal reg_z : std_logic;
	signal reg_news : std_logic;
begin
	ram1 : entity work.memory port map (
		a => ram_addr, 
		d(0) => alu_out,
		clk => clk,
		we => ram_we,
		spo(0) => ram_data
	);
	alu1 : entity work.ALU port map (
		input => input,
		acc => reg_acc,
		carry_in => reg_carry,
		aluop => aluop,
		invacc => invacc,
		invout => invout,
		output => alu_out,
		carry_out => alu_carry
	);
	output <= reg_news;
	with insel select
		input <= north when IN_N,
					east when IN_E,
					west when IN_W,
					south when IN_S,
					ram_data when IN_R,
					reg_x when IN_X,
					reg_y when IN_Y,
					reg_z when IN_Z,
					'0' when others;
	ram_we <= reg_flag and set_ram;
	process (rst,clk)
	begin
		if (rst = '0') then
			reg_flag <= '1';
			reg_acc <= '0';
			reg_carry <= '0';
			reg_x <= '0';
			reg_y <= '0';
			reg_z <= '0';
			reg_news <= '0';
		elsif (rising_edge(clk)) then
			if (ce = '1') then
				reg_acc <= alu_out;
				if (set_flag = '1') then reg_flag <= alu_out; end if;
				if (reg_flag = '1') then
					if (set_news = '1') then reg_news <= alu_out; end if;
					if (gpregsel = GP_X) then reg_x <= alu_out; end if;
					if (gpregsel = GP_Y) then reg_y <= alu_out; end if;
					if (gpregsel = GP_Z) then reg_z <= alu_out; end if;
					if (clrcar = '1') then reg_carry <= '0';
					elsif (aluop = OP_SUM) then reg_carry <= alu_carry; end if;
				end if;
			end if;
		end if;
	end process;
end Behavioral;

