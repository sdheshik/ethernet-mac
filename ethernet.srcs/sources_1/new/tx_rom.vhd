library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
library STD;
use STD.TEXTIO.ALL;

entity tx_rom is
  generic (
    data_width : integer := 8;                  -- ROM word width (bits)
    depth      : integer := 46;                 -- number of words in ROM
    data_file  : string  := "tx_data.mif"       -- text file containing byte values
  );
  Port (
    clk        : in  std_logic;                 -- clock
    rst        : in  std_logic;                 -- active-low async reset
    start      : in  std_logic;                 -- start transmission
    init_tx    : in  std_logic;                 -- alternate start trigger
    wr_en      : out std_logic;                 -- write strobe for downstream
    w_out      : out std_logic_vector(data_width-1 downto 0)  -- data word output
  );
end tx_rom;

architecture Behavioral of tx_rom is

  -- Memory array for ROM contents
  type mem_array is array (0 to depth-1) of std_logic_vector(data_width-1 downto 0);

  -- Impure function to initialize ROM from a text file at elaboration time
  impure function load_rom(constant filename : in string) return mem_array is
    file rom_file : text;
    variable rom          : mem_array;
    variable open_status  : file_open_status := NAME_ERROR;
    variable L            : line;
    variable data         : std_logic_vector(7 downto 0);
    variable read_ok      : boolean := true;
    variable next_address : integer := 0;
  begin
    -- default initialize ROM to zeros
    for i in 0 to depth-1 loop
      rom(i) := (others => '0');
    end loop;

    -- When filename is non-empty, try to open and read sequential bytes
    if filename'length > 0 then
      file_open(f => rom_file, external_name => filename, open_kind => READ_MODE, status => open_status);
      assert open_status = open_ok report "Cannot open ROM file: " & filename severity failure;

      -- Read one byte per line until EOF or depth reached
      while not endfile(rom_file) and read_ok and next_address < depth loop
        readline(rom_file, L);
        read(L, data, read_ok);  -- expects std_logic_vector literal per line
        assert read_ok report "Failed to parse data at line " & integer'image(next_address) severity error;

        if read_ok then
          rom(next_address) := data;
          next_address := next_address + 1;
        end if;
      end loop;
      file_close(rom_file);
    end if;

    return rom;
  end function load_rom;

  -- Constant ROM initialized at elaboration
  constant ROM : mem_array := load_rom(data_file);

  -- Output staging
  signal w_out_sig : std_logic_vector(data_width-1 downto 0) := (others => '0');
  signal wr_en_sig : std_logic := '0';

  -- Read pointer; ranges 0..depth, 'depth' used as terminal sentinel
  signal rd_addr   : integer range 0 to depth := 0;

  -- Simple FSM: IDLE -> WRITE -> IDLE
  type state_type is (IDLE, WRITE);
  signal p_state : state_type := IDLE;

begin

  process(clk, rst)
  begin
    if rst = '0' then                      -- async active-low reset
      p_state   <= IDLE;
      wr_en_sig <= '0';
      w_out_sig <= (others => '0');
      rd_addr   <= 0;

    elsif rising_edge(clk) then
      case p_state is

        when IDLE =>
          -- Hold outputs inactive; reset read pointer
          p_state   <= IDLE;
          wr_en_sig <= '0';
          w_out_sig <= (others => '0');
          rd_addr   <= 0;

          -- Start on either 'start' or 'init_tx'
          if start = '1' or init_tx = '1' then
            p_state <= WRITE;
          end if;

        when WRITE =>
          -- Stream ROM contents sequentially
          if (rd_addr < depth) then
            wr_en_sig <= '1';              -- strobe valid for each word
            w_out_sig <= ROM(rd_addr);
            rd_addr   <= rd_addr + 1;
          else
            -- Completed: deassert strobe; hold last data (optional)
            wr_en_sig <= '0';
            w_out_sig <= w_out_sig;
          end if;

          -- Return to IDLE once all words transmitted
          if rd_addr = depth then
            p_state <= IDLE;
          end if;

      end case;
    end if;
  end process;

  -- Drive outputs
  w_out <= w_out_sig;
  wr_en <= wr_en_sig;

end Behavioral;
