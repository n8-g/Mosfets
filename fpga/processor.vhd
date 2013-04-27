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
	
	constant pixel_scale : integer := 480 / size;
	
	type image_row is array(size-1 downto 0) of std_logic_vector(2 downto 0);
	
	signal rst : std_logic;
	signal data_rst : std_logic;
	signal instr_rst : std_logic;
	signal ce : std_logic;
	
	signal pcnt : std_logic_vector(1 downto 0);
	signal pclk : std_logic;
	signal xcnt : std_logic_vector(5 downto 0);
	signal ycnt : std_logic_vector(5 downto 0);
	signal vga_disp : std_logic;
	signal vga_sx : std_logic;
	signal vga_sy : std_logic;
	signal vga_pix : std_logic_vector(2 downto 0);
	signal vga_addr : std_logic_vector(7 downto 0);
	signal vga_data : std_logic_vector(size-1 downto 0);
	signal vga_val : std_logic_vector(2 downto 0);
	signal img_x : std_logic_vector(lsize downto 0);
	signal img_y : std_logic_vector(lsize-1 downto 0);
	signal vga_row : image_row;
	
	signal pe_instr : std_logic_vector(21 downto 0);
	signal north : std_logic_vector(size-1 downto 0);
	signal south : std_logic_vector(size-1 downto 0);
	signal east : std_logic_vector(size-1 downto 0);
	signal west : std_logic_vector(size-1 downto 0);

	signal flash_page : std_logic_vector(7 downto 0);
	signal flash_offset : std_logic_vector(14 downto 0);
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
	signal data_inaddr : std_logic_vector(7 downto 0);
	signal data_outaddr : std_logic_vector(7 downto 0);
	signal data_in : std_logic_vector(size-1 downto 0);
	signal data_out : std_logic_vector(size-1 downto 0);
	
	signal load_data : std_logic;
	signal load_instr : std_logic;
	signal ready : std_logic;
	--signal halted : std_logic;
	
	signal data_loaded : std_logic;
	signal instr_loaded : std_logic;
	
	signal img_we : std_logic;
	signal img_outaddr : std_logic_vector(7 downto 0);
	signal img_inaddr : std_logic_vector(7 downto 0);
	signal img_in : std_logic_vector(size-1 downto 0);
	signal img_out : std_logic_vector(size-1 downto 0);

	signal pc : std_logic_vector(pclen-1 downto 0);
	signal instr : std_logic_vector(31 downto 0);
	signal next_instr : std_logic_vector(31 downto 0);
	signal instr_valid : std_logic;
	signal ctrl : std_logic_vector(1 downto 0);
	
	signal next_pc : std_logic_vector(pclen-1 downto 0);
	
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
	instr_cache : entity work.block_memory
		generic map(depth => pclen, width => 32)
		port map (
			clk => clk,
			a_addr => ld_instr_addr(pclen downto 1),
			a_din => ld_instr_data,
			a_we => ld_instr_we,
			a_dout => open,
			b_addr => pc,
			b_dout => next_instr,
			b_we => '0',
			b_din => (others=>'0')
		);
	data_cache : entity work.block_memory
		generic map (depth => 8,width => 16)
		port map (
			clk => clk,
			a_addr => data_inaddr,
			a_din => data_in,
			a_we => data_we,
			a_dout => open,
			b_addr => data_outaddr,
			b_din => (others=>'0'),
			b_we => '0',
			b_dout => data_out
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
			sx => vga_sx,
			sy => vga_sy,
			disp => vga_disp
		);
	led <= (
		0 => instr_loaded,
		1 => data_loaded,
		2 => ce,
		others => '0');
	seg <= (others=>'1');
	an <= (others=>'1');
	rst <= not btn(3);
	data_rst <= rst and not btn(4);
	instr_rst <= rst and not btn(2);
	flashrp <= rst;
	flash_addr <= "000"&flash_page&flash_offset;
	
	-- VGA stuff
	vga_addr(7 downto lsize+2) <= (others=>'0'); -- 0
	vga_addr(lsize+1 downto lsize) <= pcnt; -- Depth
	vga_addr(lsize-1 downto 0) <= img_y(lsize-1 downto 0); -- Row
	vga_data <= data_out when ce = '0' else (others=>'0');
	vga_pix <= vga_row(conv_integer(unsigned(img_x(lsize-1 downto 0)))) when img_x(lsize) = '0' else (others=>'1');
	vga_val <= (others=>'0') when vga_disp = '0' else
					vga_pix when sw(7)='1' else 
					(others=>vga_pix(2));
	vgaRed <= vga_val;
	vgaGreen <= vga_val;
	vgaBlue <= vga_val(2 downto 1);
	pclk <= '1' when pcnt = "00" else '0';
	vgaDriver : process(rst,clk)
	begin
		if (rst = '0') then
			pcnt <= "00";
			img_x <= (others => '0');
			img_y <= (others => '0');
			xcnt <= (others =>'0');
			ycnt <= (others =>'0');
		elsif (rising_edge(clk)) then
			pcnt <= pcnt + '1';
			if (pclk = '1') then -- When the VGA driver is enabled
				xcnt <= xcnt + '1';
				if (xcnt = pixel_scale-1) then
					xcnt <= (others=>'0');
					img_x <= img_x + '1';
				end if;
				if (vga_sx = '1') then
					img_x <= (others=>'0'); -- Reset x
					xcnt <= (others=>'0');
					
					ycnt <= ycnt + '1';
					if (ycnt = pixel_scale-1) then
						ycnt <= (others=>'0');
						img_y <= img_y + '1';
					end if;
					if (vga_sy = '1') then
						img_y <= (others=>'0');
						ycnt <= (others=>'0');
					end if;
				end if;
			end if;
			-- Fill the proper bit for each pixel in our row with the data from the image RAM
			for i in 0 to size-1 loop -- Iterate over each pixel
				case pcnt is -- Note that the value of vga_data was fetched on the previous clock cycle
					when "01" => vga_row(i)(2) <= vga_data(i);
					when "10" => vga_row(i)(1) <= vga_data(i);
					when "11" => vga_row(i)(0) <= vga_data(i);
					when others =>
				end case;
			end loop;
		end if;
	end process;
	
	-- Priority encoder
	process(instr_loaded,data_loaded,flash_ready,ld_instr_addr,ld_data_addr,flash_data,img_out,img_inaddr,img_outaddr,img_we,sw,ce,vga_addr)
	begin
		load_instr <= '0';
		load_data <= '0';
		ready <= '0';
		flash_page <= (others=>'0');
		flash_offset <= (others=>'0');
		flash_en <= '0';
		ld_instr_we <= '0';
		data_in <= (others=>'0');
		data_inaddr <= (others=>'0');
		data_outaddr <= (others=>'0');
		data_we <= '0';
		if (instr_loaded = '0') then
			load_instr <= '1';
			flash_en <= '1';
			ld_instr_we <= flash_ready and ld_instr_addr(0);
			flash_page <= x"1"&sw(2 downto 0)&'0';
			flash_offset(ld_instr_addr'RANGE) <= ld_instr_addr;
		elsif (data_loaded = '0') then
			load_data <= '1';
			flash_en <= '1';
			data_in <= flash_data;
			data_inaddr <= ld_data_addr;
			data_we <= flash_ready;
			flash_page <= x"2"&sw(5 downto 3)&'0';
			flash_offset(ld_data_addr'RANGE) <= ld_data_addr;
		else
			ready <= '1';
			if (ce = '1') then
				data_in <= img_out;
				data_inaddr <= img_outaddr;
				data_outaddr <= img_inaddr;
				data_we <= img_we;
			else
				data_outaddr <= vga_addr;
			end if;
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
	next_pc <= pc + '1';
	pe_instr <= instr(21 downto 0);
	ctrl <= instr(31 downto 30);
	
	north <= (others => '1');
	south <= img_in when ctrl = LOAD else (others => '1');
	east <= (others => '1');
	west <= (others=>'1');
	img_in <= data_out;
	img_outaddr <= instr(29 downto 22);
	img_inaddr <= next_instr(29 downto 22); -- Since we're using block ram, start the fetch for the NEXT instruction
	img_we <= '1' when ce = '1' and ctrl = SAVE else '0';
	process(rst,clk)
	begin
		if (rst = '0') then
			pc <= (others=>'0');
			instr <= (others=>'0');
			instr_valid <= '0';
			ce <= '0';
		elsif (clk'event and clk = '1') then
			instr <= next_instr;
			instr_valid <= '1';
			if (ce = '1') then
				if (ctrl = HALT) then
					ce <= '0';
				end if;
				pc <= next_pc;
			elsif (ready = '1' and btn(0) = '1') then
				ce <= '1';
				pc <= (others=>'0');
			end if;
		end if;
	end process;
end Behavioral;

