--------------------------------------------------------------------------------
-- shift2to8.vhd  (only start collecting when we see in_valid=’1’ & in_2b="01")
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity shift2to8 is
  Port (
    clk       : in  std_logic;                    -- 50 MHz RMII clock
    rst_n     : in  std_logic;                    -- active-low reset
    in_valid  : in  std_logic;                    -- tied to phy_crs_dv
    init      : in  std_logic;
    in_2b     : in  std_logic_vector(1 downto 0); -- tied to phy_rxd[1:0]
    out_valid : out std_logic;                    -- pulses when a full 8-bit is ready
    out_8b    : out std_logic_vector(7 downto 0)  -- assembled 8-bit MSB-first
  );
end shift2to8;

architecture Behavioral of shift2to8 is
  signal shift_reg     : std_logic_vector(7 downto 0) := (others => '0');
  signal nibble_count  : integer range 0 to 3 := 0;
  signal byte_count    : integer:= 0;
  signal out_valid_reg : std_logic := '0';
begin


  process(clk, rst_n)
  begin
    if (rst_n = '0') or (init = '1') then
      shift_reg     <= (others => '0');
      nibble_count  <= 0;
      byte_count  <= 0;
      out_valid_reg <= '0';

    elsif rising_edge(clk) then

      ----------------------------------------------------------------------------
      -- Case A: first nibble of a real byte arrives when nibble_count=0, in_valid='1', in_2b="01"
      ----------------------------------------------------------------------------
      if (in_valid = '1') and (in_2b = "01") and (byte_count = 0) then
        shift_reg(5 downto 0) <= (others => '0'); -- clear upper bits
        shift_reg(7 downto 6) <= in_2b;           -- nibble0 = b7..b6
        nibble_count  <= 1;                       -- next, we’ll collect nibble1
        out_valid_reg <= '0';
        byte_count <= 1;

      ----------------------------------------------------------------------------
      -- Case B: we’re already collecting this same byte (nibble_count=1..3) and in_valid='1'
      ----------------------------------------------------------------------------
      elsif (in_valid = '1') and (byte_count > 0) then
        shift_reg(5 downto 0) <= shift_reg(7 downto 2); -- shift left 2 bits
        shift_reg(7 downto 6) <= in_2b;                 -- load next nibble

        if nibble_count = 3 then
          -- That was nibble3 (the 4th nibble), so now shift_reg is a full 8-bit byte
          out_valid_reg <= '1';  -- pulse out_valid
          nibble_count  <= 0;    -- reset for next byte (or next preamble)
          byte_count <= byte_count + 1;
        else
          out_valid_reg <= '0';
          nibble_count  <= nibble_count + 1;
        end if;
      ----------------------------------------------------------------------------
      -- Case D: in_valid='0'
      --   ⇒ No new nibble. We do NOT clear nibble_count here,
      --      so if we are mid-byte (nibble_count>0), we finish collecting 4 nibbles.
      ----------------------------------------------------------------------------
      elsif (in_valid = '0') then
        out_valid_reg <= '0';
        byte_count <= 0;
        nibble_count <= 0;
        -- nibble_count unchanged (so we continue collecting until count=4)

      else
        out_valid_reg <= '0';
      end if;

    end if;
  end process;

  ----------------------------------------------------------------------------
  -- Drive outputs
  ----------------------------------------------------------------------------
  out_8b    <= shift_reg;
  out_valid <= out_valid_reg;

end Behavioral;
