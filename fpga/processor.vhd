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
	constant lsize : integer := 5;
	constant size : integer := 16;
	constant pclen : integer := 12;
	constant vga_width : integer := 32;
	constant vga_height : integer := 32;
	constant vga_depth : integer := 3;
	constant stride : integer := vga_width / size;
	constant pixel_scale : integer := 480 / vga_width;
	
	type vga_row_t is array(vga_width-1 downto 0) of std_logic_vector(2 downto 0);
	
	signal rst : std_logic;
	signal proc_rst : std_logic;
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
	signal vga_val : std_logic_vector(2 downto 0);
	signal img_x : std_logic_vector(lsize downto 0);
	signal img_y : std_logic_vector(lsize-1 downto 0);
	
	signal vram_src_addr : std_logic_vector(7 downto 0);	
	signal vram_src_data : std_logic_vector(size-1 downto 0);
	signal vram_addr : std_logic_vector(7 downto 0);
	signal vram_row : std_logic_vector(vga_width*vga_depth-size-1 downto 0);
	signal vram_data : std_logic_vector(vga_width*vga_depth-1 downto 0);
	signal vram_we : std_logic;
	signal vram_piece : std_logic_vector(0 downto 0);
	signal vram_depth : std_logic_vector(1 downto 0);
	signal vram_ready : std_logic;
	
	signal vga_data : std_logic_vector(vga_width*vga_depth-1 downto 0);
	signal vga_row : vga_row_t;
	
	signal north : std_logic_vector(size-1 downto 0);
	signal south : std_logic_vector(size-1 downto 0);
	signal east : std_logic_vector(size-1 downto 0);
	signal west : std_logic_vector(size-1 downto 0);
	
	signal bordern : std_logic_vector(size-1 downto 0);
	signal bordere : std_logic_vector(size-1 downto 0);
	signal borderw : std_logic_vector(size-1 downto 0);
	signal borders : std_logic_vector(size-1 downto 0);
	signal load_image : std_logic;

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
	signal started : std_logic;
	signal halted : std_logic;
	signal instr_valid : std_logic;
	
	signal data_loaded : std_logic;
	signal instr_loaded : std_logic;
	
	signal img_in : std_logic_vector(size-1 downto 0);

	signal if_pe_ram_addr : std_logic_vector(7 downto 0);
	signal id_pe_ram_addr : std_logic_vector(7 downto 0);
	signal pe_ce : std_logic;
	signal pe_clrcar : std_logic;
	signal pe_aluop : std_logic_vector(2 downto 0);
	signal pe_invacc : std_logic;
	signal pe_invout : std_logic;
	signal pe_gpregsel : std_logic_vector(1 downto 0);
	signal pe_insel : std_logic_vector(2 downto 0);
	signal pe_ram_addr : std_logic_vector(7 downto 0);
	signal pe_set_ram : std_logic;
	signal pe_set_flag : std_logic;
	signal pe_set_news : std_logic;
	signal pe_north : std_logic_vector(size-1 downto 0);
	signal pe_south : std_logic_vector(size-1 downto 0);
	signal pe_east : std_logic_vector(size-1 downto 0);
	signal pe_west : std_logic_vector(size-1 downto 0);
	
	signal fetch_instr : std_logic; -- Fetch enable
	signal if_instr : std_logic_vector(31 downto 0); -- Instruction Fetch stage instruction
	signal if_ctrl : std_logic_vector(3 downto 0); -- Instruction Fecth stage control word
	signal id_instr : std_logic_vector(31 downto 0); -- Instruction Decode stage instruction
	signal id_ctrl : std_logic_vector(3 downto 0);  -- Instruction Decode stage control
	signal id_halted : std_logic; -- Instruction Decode stage halted
	signal id_addr : std_logic_vector(7 downto 0); -- Data cache address to fetch
	signal ex_instr : std_logic_vector(31 downto 0); -- Execution stage instruction
	signal ex_ctrl : std_logic_vector(3 downto 0); -- Execution stage control
	signal ex_halted : std_logic; -- Execution stage halted
	signal ex_addr : std_logic_vector(7 downto 0); -- Data cache address to write
	signal ex_we : std_logic; -- Data cache enable
	signal pc : std_logic_vector(pclen-1 downto 0);
	signal next_pc : std_logic_vector(pclen-1 downto 0);
	signal instr_counter : std_logic_vector(7 downto 0);
	signal instr_cycles : integer;
	
	type reg_file is array(7 downto 0) of std_logic_vector(7 downto 0);
	signal registers : reg_file;
	signal srcreg : std_logic_vector(2 downto 0);
	signal dstreg : std_logic_vector(2 downto 0);
	signal srcreg_val : std_logic_vector(7 downto 0);
	signal offset : std_logic_vector(pclen-1 downto 0);
begin
	-- Instantiate the Unit Under Test (UUT)
   pe_arr: entity work.pe_array generic map (size=>size)
		port map (
			clk => clk,
			rst => rst,
			ce => pe_ce,
			north => north,
			east => east,
			west => west,
			south => south,
			clrcar=>pe_clrcar,
			aluop=>pe_aluop,
			invacc=>pe_invacc,
			invout=>pe_invout,
			gpregsel=>pe_gpregsel,
			insel=>pe_insel,
			ram_addr=>pe_ram_addr,
			set_ram=>pe_set_ram,
			set_flag=>pe_set_flag,
			set_news=>pe_set_news,
			pe_north => pe_north,
			pe_south => pe_south,
			pe_east => pe_east,
			pe_west => pe_west
	  );
	instr_cache : entity work.block_memory
		generic map(depth => pclen, width => 32)
		port map (
			clk => clk,
			a_addr => ld_instr_addr(pclen downto 1),
			a_din => ld_instr_data,
			a_en => '1',
			a_we => ld_instr_we,
			a_dout => open,
			b_addr => next_pc,
			b_dout => if_instr,
			b_en => fetch_instr,
			b_we => '0',
			b_din => (others=>'0')
		);
	data_cache : entity work.block_memory
		generic map (depth => 8,width => size)
		port map (
			clk => clk,
			a_addr => data_inaddr,
			a_din => data_in,
			a_en => '1',
			a_we => data_we,
			a_dout => open,
			b_addr => data_outaddr,
			b_din => (others=>'0'),
			b_en => '1',
			b_we => '0',
			b_dout => data_out
		);
	video_ram : entity work.block_memory
		generic map (depth => 8, width => vga_width*vga_depth)
		port map (
			clk => clk,
			a_en => '1',
			a_addr => vga_addr,
			a_din => (others=>'0'),
			a_dout => vga_data,
			a_we => '0',
			b_en => '1',
			b_addr => vram_addr,
			b_din => vram_data,
			b_dout => open,
			b_we => vram_we
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
		2 => started,
		3 => halted,
		others => '0');
	seg <= (others=>'1');
	an <= "1111";
	rst <= not btn(3);
	proc_rst <= rst and not btn(1);
	data_rst <= rst and not btn(4);
	instr_rst <= rst and not btn(2);
	flashrp <= rst;
	flash_addr <= "000"&flash_page&flash_offset;
	
	-- Video ram loader
	vram_src_data <= data_out;
	vram_src_addr <= vram_depth&vram_addr(4 downto 0)&(not vram_piece); -- Source address to fetch
	vram_data <= vram_row&vram_src_data; -- Current row value'
	vram_we <= '1' when vram_ready = '1' and vram_depth = vga_depth-1 and vram_piece = "1" else '0';
	vgaLoader : process(rst,clk)
	begin
		if (rst = '0') then
			vram_addr <= (others=>'0');
			vram_row <= (others=>'0');
			vram_piece <= (others=>'0');
			vram_depth <= "00";
			vram_ready <= '0'; -- Whether vga_src_row is valid
		elsif (rising_edge(clk)) then
			if (vram_ready = '1') then
				vram_row <= vram_data(vga_width*vga_depth-size-1 downto 0); -- Update row
				if (vram_piece = stride-1) then -- Last piece in row
					vram_piece <= (others=>'0');
					if (vram_depth = vga_depth-1) then -- Last depth
						vram_depth <= "00";
						if (vram_addr = vga_height-1) then -- Last row
							vram_addr <= (others=>'0');
						else
							vram_addr <= vram_addr + '1';
						end if;
					else
						vram_depth <= vram_depth + '1';
					end if;
				else
					vram_piece <= vram_piece + '1';
				end if;
				vram_ready <= '0';
			else
				vram_ready <= '1';
			end if;
		end if;
	end process;
	
	-- VGA stuff
	vga_addr(7 downto lsize) <= (others=>'0'); -- 0
	vga_addr(lsize-1 downto 0) <= img_y(lsize-1 downto 0); -- Row
	-- Make vga_data a little more pixel friendly
	vga_row_gen : for i in 0 to vga_width-1 generate
		vga_depth_gen : for j in 0 to vga_depth-1 generate
			vga_row(i)(j) <= vga_data(i + j*vga_width);
		end generate;
	end generate;
	vga_pix <= vga_row(conv_integer(img_x(lsize-1 downto 0))) when img_x(lsize) = '0' else (others=>'1');
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
		end if;
	end process;
	
	-- Priority encoder
	process(instr_loaded,data_loaded,flash_ready,ld_instr_addr,ld_data_addr,flash_data,pe_north,ex_addr,ex_we,sw,started)
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
			ready <= started;
			data_in <= pe_north;
			data_inaddr <= ex_addr;
			data_we <= ex_we;
		end if;
	end process;
	data_outaddr <= id_addr when id_ctrl = LOAD else vram_src_addr;
	
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
				elsif (ld_instr_addr = "1111111111111" or ld_instr_data(31 downto 28) = HALT) then
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
	ex_ctrl <= ex_instr(31 downto CTRL_OFF);
	id_ctrl <= id_instr(31 downto CTRL_OFF);
	if_ctrl <= if_instr(31 downto CTRL_OFF);
	img_in <= data_out;
	ce <= ready and not halted;
	north <= bordern;
	east <= bordere;
	west <= borderw;
	south <= img_in when load_image = '1' else borders;
	
	
	-- Processing Element Configuration
	
	-- Values based on ctrl
	process(ex_instr,ex_ctrl,registers)
	begin
		-- Defaults
		pe_ce <= '0';
		pe_clrcar <= '0';
		pe_aluop <= OP_CPY;
		pe_invacc <= '0';
		pe_invout <= '0';
		pe_gpregsel <= (others=>'0');
		pe_insel <= IN_S;
		pe_set_ram <= '0';
		pe_set_flag <= '0';
		pe_set_news <= '0';
		ex_we <= '0';
		load_image <= '0';
		case ex_ctrl is
			when HALT => 
			when NORMAL =>
				pe_ce <= '1';
				pe_clrcar <= ex_instr(CLRCAR_OFF);
				pe_aluop <= ex_instr(ALU_OFF+2 downto ALU_OFF);
				pe_invacc <= ex_instr(INVACC_OFF);
				pe_invout <= ex_instr(INVOUT_OFF);
				pe_gpregsel <= ex_instr(GPREG_OFF+1 downto GPREG_OFF);
				pe_insel <= ex_instr(INSEL_OFF+2 downto INSEL_OFF);
				pe_set_ram <= ex_instr(SETRAM_OFF);
				pe_set_flag <= ex_instr(SETFLAG_OFF);
				pe_set_news <= ex_instr(SETNEWS_OFF);
			when LOAD =>
				pe_ce <= '1';
				pe_set_ram <= '1';
				pe_set_news <= '1';
				load_image <= '1';
			when SAVE =>
				pe_ce <= '1';
				pe_set_news <= '1';
				ex_we <= '1';
			when OTHERS =>
		end case;
	end process;
	-- Instruction cycle count
	process(if_ctrl)
	begin
		case if_ctrl is
			when LOAD => instr_cycles <= size-1;
			when SAVE => instr_cycles <= size-1;
			when OTHERS => instr_cycles <= 0;
		end case;
	end process;
	
	offset <= if_instr(OFFSET_OFF+pclen-1 downto OFFSET_OFF);
	next_pc <= (others=>'0') when instr_valid = '0' else
					pc + offset when if_ctrl = BNE and srcreg_val /= if_instr(IMMEDIATE_OFF + 7 downto IMMEDIATE_OFF) else
					pc + 1;
	
	-- Controller process
	srcreg <= if_instr(SRCREG_OFF+2 downto SRCREG_OFF);
	dstreg <= if_instr(DSTREG_OFF+2 downto DSTREG_OFF);
	srcreg_val <= registers(conv_integer(srcreg));
	fetch_instr <= '1' when instr_valid = '0' or (instr_counter = instr_cycles and if_ctrl /= HALT) else '0';
	id_halted <= '1' when id_ctrl = HALT else '0';
	ex_halted <= '1' when ex_ctrl = HALT else '0';
	if_pe_ram_addr <= if_instr(RAMADDR_OFF+7 downto RAMADDR_OFF) + srcreg_val;
	process(proc_rst,clk)
		variable instr_fetched : std_logic;
	begin
		if (proc_rst = '0') then
			pc <= (others=>'0');
			started <= '0';
			halted <= '0';
			bordern <= (others => '1');
			borders <= (others => '1');
			bordere <= (others => '1');
			borderw <= (others => '1');
			instr_counter <= (others=>'0');
			id_instr <= (others=>'1');
			ex_instr <= (others=>'1');
			ex_addr <= (others=>'0');
			id_addr <= (others => '0');
			instr_valid <= '0';
			registers <= (others=>(others=>'0'));
		elsif (clk'event and clk = '1') then
			if (ex_halted = '0') then -- Execution stage actions
				case ex_ctrl is
					when BDR =>
						case ex_instr(BDR_OFF+1 downto BDR_OFF) is
							when BDRN => bordern <= pe_south;
							when BDRE => bordere <= pe_west;
							when BDRS => borders <= pe_north;
							when BDRW => borderw <= pe_east;
							when others =>
						end case;
					when OTHERS =>
				end case;
			end if;
			pe_ram_addr <= id_pe_ram_addr;
			id_pe_ram_addr <= if_pe_ram_addr; -- RAM address is calculated in the IF stage and passed along the pipeline
			ex_instr <= id_instr;
			ex_addr <= id_addr;
			if (ce = '1') then -- Processor running
				id_instr <= if_instr;
				case if_ctrl is -- IF stage operations: handling registers
					when LDREG => registers(conv_integer(dstreg)) <= if_instr(IMMEDIATE_OFF+7 downto IMMEDIATE_OFF);
					when CPYREG => registers(conv_integer(dstreg)) <= srcreg_val;
					when ADDREG => registers(conv_integer(dstreg)) <= registers(conv_integer(dstreg)) + if_instr(IMMEDIATE_OFF+7 downto IMMEDIATE_OFF);
					when OTHERS =>
				end case;
				if (instr_counter = 0) then
					-- Load information from the new instruction
					case if_ctrl is
						when LOAD => id_addr <= if_instr(LOAD_IMGADDR_OFF+7 downto LOAD_IMGADDR_OFF) + registers(conv_integer(dstreg)); -- Setup decode stage address
						when SAVE => id_addr <= if_instr(SAVE_IMGADDR_OFF+7 downto SAVE_IMGADDR_OFF) + registers(conv_integer(dstreg)); -- Setup decode stage address
						when HALT => halted <= '1';
						when OTHERS =>
					end case;
				else
					-- Update addresses
					case id_ctrl is
						when SAVE => id_addr <= id_addr + id_instr(SAVE_STRIDE_OFF+3 downto SAVE_STRIDE_OFF);
						when LOAD => id_addr <= id_addr + id_instr(LOAD_STRIDE_OFF+3 downto LOAD_STRIDE_OFF);
						when OTHERS =>
					end case;
				end if;
				if (fetch_instr = '1') then -- We're going to fetch a new instruction
					instr_valid <= '1';
					instr_counter <= (others =>'0'); -- Reset counter
					pc <= next_pc;
				else
					instr_counter <= instr_counter + '1';
				end if;
			elsif (btn(0) = '1') then -- Start processor
				started <= '1';
			end if;
		end if;
	end process;
end Behavioral;

