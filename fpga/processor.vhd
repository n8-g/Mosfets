----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:41:56 04/02/2013 
-- Design Name: 
-- Module Name:    processor - Behavioral 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use work.ALU_OP.ALL;
use work.PE_CONST.ALL;
use work.INSTR_WORD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity processor is
	port (
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
end processor;

architecture Behavioral of processor is
	constant lsize : integer := 4;
	constant size : integer := 2**lsize;
	constant pclen : integer := 9;
	constant ldepth : integer := 2;
	constant depth : integer := 4;
	
	type image_row is array(size-1 downto 0) of std_logic_vector(depth-1 downto 0);
	
	signal rst : std_logic;
	signal data_rst : std_logic;
	signal instr_rst : std_logic;
	signal ce : std_logic;
	
	signal pcnt : std_logic_vector(1 downto 0);
	signal pclk : std_logic;
	signal disp : std_logic;
	signal vga_x : std_logic_vector(9 downto 0);
	signal vga_y : std_logic_vector(9 downto 0);
	signal img_x : std_logic_vector(lsize-1 downto 0);
	signal img_y : std_logic_vector(lsize-1 downto 0);
	signal vga_bit : std_logic_vector(ldepth-1 downto 0);
	signal vga_pix : std_logic_vector(3 downto 0);
	signal vga_addr : std_logic_vector(7 downto 0);
	signal vga_data : std_logic_vector(size-1 downto 0);
	signal vga_row : image_row;
	
	signal pe_instr : std_logic_vector(21 downto 0);
	signal north : std_logic_vector(size-1 downto 0);
	signal south : std_logic_vector(size-1 downto 0);
	signal east : std_logic_vector(size-1 downto 0);
	signal west : std_logic_vector(size-1 downto 0);

	signal flash_addr : std_logic_vector(25 downto 0);
	signal flash_en : std_logic;
	signal flash_data : std_logic_vector(15 downto 0);
	signal flash_ready : std_logic;
	
	signal ld_data_addr : std_logic_vector(7 downto 0);
	
	signal ld_instr_we : std_logic;
	signal ld_instr_addr : std_logic_vector(pclen downto 0);
	signal ld_instr_data : std_logic_vector(31 downto 0);
	signal ld_instr_loword : std_logic_vector(15 downto 0);
	
	signal data_we : std_logic;
	signal data_addr : std_logic_vector(7 downto 0);
	signal data_data : std_logic_vector(size-1 downto 0);
	
	signal load_data : std_logic;
	signal load_instr : std_logic;
	signal ready : std_logic;
	signal halted : std_logic;
	
	signal data_loaded : std_logic;
	signal instr_loaded : std_logic;
	
	signal img_we : std_logic;
	signal img_addr : std_logic_vector(7 downto 0);
	signal img_in : std_logic_vector(size-1 downto 0);
	signal img_out : std_logic_vector(size-1 downto 0);

	signal pc : std_logic_vector(pclen-1 downto 0);
	signal instr : std_logic_vector(31 downto 0);
	signal next_instr : std_logic_vector(31 downto 0);
	signal ctrl : std_logic_vector(1 downto 0);
	
	signal next_pc : std_logic_vector(pclen-1 downto 0);
	
	signal start : std_logic;
	
begin
	-- Instantiate the Unit Under Test (UUT)
   pe_arr: entity work.pe_array generic map (size=>size)
		port map (
			clk => clk,
			rst => rst,
			ce => ce,
			north => north,
			east => east,
			west => west,
			south => south,
			clrcar=>pe_instr(CLRCAR_OFF),
			aluop=>pe_instr(ALU_OFF+2 downto ALU_OFF),
			invacc=>pe_instr(INVACC_OFF),
			invout=>pe_instr(INVOUT_OFF),
			gpregsel=>pe_instr(GPREG_OFF+1 downto GPREG_OFF),
			insel=>pe_instr(INSEL_OFF+2 downto INSEL_OFF),
			ram_addr=>pe_instr(RAMADDR_OFF+7 downto RAMADDR_OFF),
			set_ram=>pe_instr(SETRAM_OFF),
			set_flag=>pe_instr(SETFLAG_OFF),
			set_news=>pe_instr(SETNEWS_OFF),
			outdata => img_out
	  );
	instr_cache : entity work.instr_ram 
		port map (
			clk => clk,
			a => ld_instr_addr(pclen downto 1),
			d => ld_instr_data,
			we => ld_instr_we,
			spo => open,
			dpra => pc,
			dpo => next_instr
		);
	data_cache : entity work.data_ram
		port map (
			clk => clk,
			a => data_addr,
			d => data_data,
			we => data_we,
			spo => img_in,
			dpra => vga_addr,
			dpo => vga_data
		);
	flash_mem : entity work.async_ram generic map (cycle => 12)
		port map (
			clk => clk,
			rst => rst,
			en => flash_en,
			we => '0',
			addr => flash_addr,
			din => (others => '0'),
			dout => flash_data,
			ready=> flash_ready,
			memadr => memadr,
			memdb => memdb,
			memoe => memoe,
			memwr => memwr,
			memcs => flashcs
		);
	vga1 : entity work.vga
		port map (
			clk => clk,
			rst => rst,
			ce => pclk,
			hs => Hsync,
			vs => Vsync,
			x => vga_x,
			y => vga_y,
			disp => disp
		);
	led <= (
		0 => instr_loaded,
		1 => data_loaded,
		2 => ce,
		3 => halted,
		others => '0');
	seg <= (others=>'1');
	an <= (others=>'1');
	rst <= not btn(0);
	data_rst <= rst and not btn(4);
	instr_rst <= rst and not btn(2);
	flashrp <= rst;
	
	pixelClock : process(rst,clk)
	begin
		if (rst = '0') then
			pcnt <= "00";
		elsif (rising_edge(clk)) then
			pcnt <= pcnt + '1';
		end if;
	end process;
	
	img_x <= vga_x(7 downto 8-lsize);
	img_y <= vga_y(7 downto 8-lsize);
	pclk <= '1' when pcnt = "00" else '0';
	vga_addr(7 downto lsize+ldepth) <= (others=>'0'); -- 0
	vga_addr(lsize+ldepth-1 downto lsize) <= vga_bit; -- Depth
	vga_addr(lsize-1 downto 0) <= img_x when vga_x(9 downto 8) = "00" else (others=>'0'); -- Row
	vga_pix(3 downto 4-depth) <= vga_row(conv_integer(unsigned(img_y))) when vga_y(9 downto 8) = "00" and vga_x(9 downto 8) = "00" else (others=>'0');
	vga_pix(3-depth downto 0) <= (others=>vga_pix(4-depth));
	--vga_pix <= (others=>img_x(0) xor img_y(0));
	vgaRed <= vga_pix(3 downto 1);
	vgaGreen <= vga_pix(3 downto 1);
	vgaBlue <= vga_pix(3 downto 2);
	
	-- Fills in the bits for vga_row based on the current row
	vgaDriver : process(rst,clk)
	begin
		if (rst = '0') then
			vga_row <= (others =>(others=>'0'));
			vga_bit <= (others=>'0');
		elsif (rising_edge(clk)) then
			-- Fill the proper bit for each pixel in our row with the data from the image RAM
			for i in 0 to size-1 loop -- Iterate over each pixel
				vga_row(i)(depth-1-conv_integer(unsigned(vga_bit))) <= vga_data(i);
			end loop;
			if (vga_bit = depth-1) then
				vga_bit <= (others=>'0');
			else
				vga_bit <= vga_bit + '1';
			end if;
		end if;
	end process;
	
	-- Priority encoder
	process(instr_loaded,data_loaded,flash_ready,ld_instr_addr,ld_data_addr,flash_data,start,img_out,img_addr,img_we)
	begin
		load_instr <= '0';
		load_data <= '0';
		ready <= '0';
		flash_addr <= (others=>'0');
		flash_en <= '0';
		ld_instr_we <= '0';
		data_data <= (others=>'0');
		data_addr <= (others=>'0');
		data_we <= '0';
		if (instr_loaded = '0') then
			load_instr <= '1';
			flash_addr <= "0000001000000000" & ld_instr_addr;
			flash_en <= '1';
			ld_instr_we <= flash_ready and ld_instr_addr(0);
		elsif (data_loaded = '0') then
			load_data <= '1';
			flash_en <= '1';
			data_data <= flash_data;
			data_addr <= ld_data_addr;
			data_we <= flash_ready;
			flash_addr <= "000001000000000000" & ld_data_addr;
		elsif (start = '1') then
			ready <= '1';
			data_data <= img_out;
			data_addr <= img_addr;
			data_we <= img_we;
		end if;
	end process;
	
	-- Loaders
	ld_instr_data <= flash_data & ld_instr_loword;
	instrLoader : process(instr_rst,clk)
	begin
		if (instr_rst = '0') then
			instr_loaded <= '0';
			ld_instr_addr <= (others=>'0');
		elsif(rising_edge(clk)) then
			if (load_instr = '1' and flash_ready = '1') then
				if (ld_instr_addr(0) = '0') then
					ld_instr_loword <= flash_data;
				elsif (ld_instr_addr = "111111111" or ld_instr_data(31 downto 30) = HALT) then
					instr_loaded <= '1';
				end if;
				ld_instr_addr <= ld_instr_addr + '1';
			end if;
		end if;
	end process;
	dataLoader : process(data_rst,clk)
	begin
		if (data_rst = '0') then
			data_loaded <= '0';
			ld_data_addr <= (others=>'0');
		elsif(rising_edge(clk)) then
			if (load_data = '1' and flash_ready = '1') then
				if (ld_data_addr = "11111111") then
					data_loaded <= '1';
				end if;
				ld_data_addr <= ld_data_addr + '1';
			end if;
		end if;
	end process;
	
	-- Control unit
	north <= (others => '1');
	south <= img_in when ctrl = LOAD else (others => '1');
	east <= (others => '1');
	west <= (others=>'1');
	
	next_pc <= pc + '1';
	pe_instr <= instr(21 downto 0);
	ctrl <= instr(31 downto 30);
	halted <= '1' when (ready = '1' and ctrl = HALT) else '0';
	ce <= '1' when ready = '1' and halted = '0' else '0';
	
	img_addr <= instr(29 downto 22);
	img_we <= '1' when ce = '1' and ctrl = SAVE else '0';
	process(rst,clk)
	begin
		if (rst = '0') then
			pc <= (others=>'0');
			instr <= (others=>'0');
			start <= '0';
		elsif (clk'event and clk = '1') then
			instr <= next_instr;
			if (btn(3) = '1') then
				start <= '1';
			end if;
			if (ce = '1') then
				pc <= next_pc;
			end if;
		end if;
	end process;
end Behavioral;

