--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package alu_op is
	constant OP_CPY : std_logic_vector(2 downto 0) := "000";
	constant OP_AND : std_logic_vector(2 downto 0) := "001";
	constant OP_XOR : std_logic_vector(2 downto 0) := "010";
	constant OP_OR : std_logic_vector(2 downto 0) := "011";
	constant OP_SUM : std_logic_vector(2 downto 0) := "100";
	constant OP_CLR : std_logic_vector(2 downto 0) := "101";
	constant OP_SET : std_logic_vector(2 downto 0) := "110";
	constant OP_CAR : std_logic_vector(2 downto 0) := "111";
end alu_op;

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package pe_const is
	constant IN_N : std_logic_vector(2 downto 0) := "000";
	constant IN_E : std_logic_vector(2 downto 0) := "001";
	constant IN_W : std_logic_vector(2 downto 0) := "010";
	constant IN_S : std_logic_vector(2 downto 0) := "011";
	constant IN_R : std_logic_vector(2 downto 0) := "100";
	constant IN_X : std_logic_vector(2 downto 0) := "101";
	constant IN_Y : std_logic_vector(2 downto 0) := "110";
	constant IN_Z : std_logic_vector(2 downto 0) := "111";
	constant GP_NONE : std_logic_vector(1 downto 0) := "00";
	constant GP_X : std_logic_vector(1 downto 0) := "01";
	constant GP_Y : std_logic_vector(1 downto 0) := "10";
	constant GP_Z : std_logic_vector(1 downto 0) := "11";
	
end pe_const;

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package instr_word is
	constant CLRCAR_OFF : integer := 0;
	constant ALU_OFF : integer := 1;
	constant INVACC_OFF : integer := 4;
	constant INVOUT_OFF : integer := 5;
	constant GPREG_OFF : integer := 6;
	constant INSEL_OFF : integer := 8;
	constant RAMADDR_OFF : integer := 11;
	constant SETFLAG_OFF : integer := 19;
	constant SETRAM_OFF : integer := 20;
	constant SETNEWS_OFF : integer := 21;
	
	constant LOAD_RAMADDR_OFF : integer := 0;
	constant LOAD_IMGADDR_OFF : integer := 8;
	constant SAVE_IMGADDR_OFF : integer := 8;
	constant CTRL_OFF : integer := 28;
	constant BDR_OFF : integer := 0;
	
	constant NORMAL : std_logic_vector(3 downto 0) := "0000";
	constant LOAD : std_logic_vector(3 downto 0) := "0001";
	constant SAVE : std_logic_vector(3 downto 0) := "0010";
	constant BDR : std_logic_vector(3 downto 0) := "0011";
	constant HALT : std_logic_vector(3 downto 0) := "1111";
	
	constant BDRN : std_logic_vector(1 downto 0) := "00";
	constant BDRE : std_logic_vector(1 downto 0) := "01";
	constant BDRS : std_logic_vector(1 downto 0) := "10";
	constant BDRW : std_logic_vector(1 downto 0) := "11";
end instr_word;