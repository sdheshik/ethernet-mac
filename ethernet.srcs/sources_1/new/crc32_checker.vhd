-------------------------------------------------------------------------------
-- CRC module for data(7:0)
--   lfsr(31:0)=1+x^1+x^2+x^4+x^5+x^7+x^8+x^10+x^11+x^12+x^16+x^22+x^23+x^26+x^32;
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity crc is
  port (
    data_rev : in  std_logic_vector(7 downto 0);  -- input byte, bit-reversed (LSB-first)
    crc_en   : in  std_logic;                     -- advance CRC when '1'
    rst      : in  std_logic;                     -- active-low async reset
    clk      : in  std_logic;                     -- clock
    init     : in  std_logic;                     -- sync init: reload CRC to all '1's
    crc_out  : out std_logic_vector(31 downto 0)  -- current CRC register (no final inversion here)
  );
end crc;

architecture imp_crc of crc is
  signal lfsr_q     : std_logic_vector(31 downto 0) := (others => '1'); -- CRC register (init to all '1's)
  signal lfsr_c     : std_logic_vector(31 downto 0) := (others => '0'); -- next-state CRC value
  signal data_in    : std_logic_vector(7 downto 0)  := (others => '0'); -- reflected mapping of data_rev
  signal crc_enable : std_logic := '0';                                  -- local enable mirror

  ATTRIBUTE MARK_DEBUG : STRING;
  ATTRIBUTE MARK_DEBUG OF lfsr_q     : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF crc_enable : SIGNAL IS "true";
begin
  -- Expose internal CRC register directly
  crc_out <= lfsr_q;

  -- Direct mirror of input enable (kept as separate net for debug/ILA observability)
  crc_enable <= crc_en;

  -- Map incoming byte to reflected bit order expected by the parallel equations
  data_in(7) <= data_rev(0);
  data_in(6) <= data_rev(1);
  data_in(5) <= data_rev(2);
  data_in(4) <= data_rev(3);
  data_in(3) <= data_rev(4);
  data_in(2) <= data_rev(5);
  data_in(1) <= data_rev(6);
  data_in(0) <= data_rev(7);

  -- Parallel CRC32 next-state logic for 8-bit input (reflected polynomial form)
  lfsr_c(0)  <= lfsr_q(24) xor lfsr_q(30) xor data_in(0) xor data_in(6);
  lfsr_c(1)  <= lfsr_q(24) xor lfsr_q(25) xor lfsr_q(30) xor lfsr_q(31) xor data_in(0) xor data_in(1) xor data_in(6) xor data_in(7);
  lfsr_c(2)  <= lfsr_q(24) xor lfsr_q(25) xor lfsr_q(26) xor lfsr_q(30) xor lfsr_q(31) xor data_in(0) xor data_in(1) xor data_in(2) xor data_in(6) xor data_in(7);
  lfsr_c(3)  <= lfsr_q(25) xor lfsr_q(26) xor lfsr_q(27) xor lfsr_q(31) xor data_in(1) xor data_in(2) xor data_in(3) xor data_in(7);
  lfsr_c(4)  <= lfsr_q(24) xor lfsr_q(26) xor lfsr_q(27) xor lfsr_q(28) xor lfsr_q(30) xor data_in(0) xor data_in(2) xor data_in(3) xor data_in(4) xor data_in(6);
  lfsr_c(5)  <= lfsr_q(24) xor lfsr_q(25) xor lfsr_q(27) xor lfsr_q(28) xor lfsr_q(29) xor lfsr_q(30) xor lfsr_q(31) xor data_in(0) xor data_in(1) xor data_in(3) xor data_in(4) xor data_in(5) xor data_in(6) xor data_in(7);
  lfsr_c(6)  <= lfsr_q(25) xor lfsr_q(26) xor lfsr_q(28) xor lfsr_q(29) xor lfsr_q(30) xor lfsr_q(31) xor data_in(1) xor data_in(2) xor data_in(4) xor data_in(5) xor data_in(6) xor data_in(7);
  lfsr_c(7)  <= lfsr_q(24) xor lfsr_q(26) xor lfsr_q(27) xor lfsr_q(29) xor lfsr_q(31) xor data_in(0) xor data_in(2) xor data_in(3) xor data_in(5) xor data_in(7);
  lfsr_c(8)  <= lfsr_q(0)  xor lfsr_q(24) xor lfsr_q(25) xor lfsr_q(27) xor lfsr_q(28) xor data_in(0) xor data_in(1) xor data_in(3) xor data_in(4);
  lfsr_c(9)  <= lfsr_q(1)  xor lfsr_q(25) xor lfsr_q(26) xor lfsr_q(28) xor lfsr_q(29) xor data_in(1) xor data_in(2) xor data_in(4) xor data_in(5);
  lfsr_c(10) <= lfsr_q(2)  xor lfsr_q(24) xor lfsr_q(26) xor lfsr_q(27) xor lfsr_q(29) xor data_in(0) xor data_in(2) xor data_in(3) xor data_in(5);
  lfsr_c(11) <= lfsr_q(3)  xor lfsr_q(24) xor lfsr_q(25) xor lfsr_q(27) xor lfsr_q(28) xor data_in(0) xor data_in(1) xor data_in(3) xor data_in(4);
  lfsr_c(12) <= lfsr_q(4)  xor lfsr_q(24) xor lfsr_q(25) xor lfsr_q(26) xor lfsr_q(28) xor lfsr_q(29) xor lfsr_q(30) xor data_in(0) xor data_in(1) xor data_in(2) xor data_in(4) xor data_in(5) xor data_in(6);
  lfsr_c(13) <= lfsr_q(5)  xor lfsr_q(25) xor lfsr_q(26) xor lfsr_q(27) xor lfsr_q(29) xor lfsr_q(30) xor lfsr_q(31) xor data_in(1) xor data_in(2) xor data_in(3) xor data_in(5) xor data_in(6) xor data_in(7);
  lfsr_c(14) <= lfsr_q(6)  xor lfsr_q(26) xor lfsr_q(27) xor lfsr_q(28) xor lfsr_q(30) xor lfsr_q(31) xor data_in(2) xor data_in(3) xor data_in(4) xor data_in(6) xor data_in(7);
  lfsr_c(15) <= lfsr_q(7)  xor lfsr_q(27) xor lfsr_q(28) xor lfsr_q(29) xor lfsr_q(31) xor data_in(3) xor data_in(4) xor data_in(5) xor data_in(7);
  lfsr_c(16) <= lfsr_q(8)  xor lfsr_q(24) xor lfsr_q(28) xor lfsr_q(29) xor data_in(0) xor data_in(4) xor data_in(5);
  lfsr_c(17) <= lfsr_q(9)  xor lfsr_q(25) xor lfsr_q(29) xor lfsr_q(30) xor data_in(1) xor data_in(5) xor data_in(6);
  lfsr_c(18) <= lfsr_q(10) xor lfsr_q(26) xor lfsr_q(30) xor lfsr_q(31) xor data_in(2) xor data_in(6) xor data_in(7);
  lfsr_c(19) <= lfsr_q(11) xor lfsr_q(27) xor lfsr_q(31) xor data_in(3) xor data_in(7);
  lfsr_c(20) <= lfsr_q(12) xor lfsr_q(28) xor data_in(4);
  lfsr_c(21) <= lfsr_q(13) xor lfsr_q(29) xor data_in(5);
  lfsr_c(22) <= lfsr_q(14) xor lfsr_q(24) xor data_in(0);
  lfsr_c(23) <= lfsr_q(15) xor lfsr_q(24) xor lfsr_q(25) xor lfsr_q(30) xor data_in(0) xor data_in(1) xor data_in(6);
  lfsr_c(24) <= lfsr_q(16) xor lfsr_q(25) xor lfsr_q(26) xor lfsr_q(31) xor data_in(1) xor data_in(2) xor data_in(7);
  lfsr_c(25) <= lfsr_q(17) xor lfsr_q(26) xor lfsr_q(27) xor data_in(2) xor data_in(3);
  lfsr_c(26) <= lfsr_q(18) xor lfsr_q(24) xor lfsr_q(27) xor lfsr_q(28) xor lfsr_q(30) xor data_in(0) xor data_in(3) xor data_in(4) xor data_in(6);
  lfsr_c(27) <= lfsr_q(19) xor lfsr_q(25) xor lfsr_q(28) xor lfsr_q(29) xor lfsr_q(31) xor data_in(1) xor data_in(4) xor data_in(5) xor data_in(7);
  lfsr_c(28) <= lfsr_q(20) xor lfsr_q(26) xor lfsr_q(29) xor lfsr_q(30) xor data_in(2) xor data_in(5) xor data_in(6);
  lfsr_c(29) <= lfsr_q(21) xor lfsr_q(27) xor lfsr_q(30) xor lfsr_q(31) xor data_in(3) xor data_in(6) xor data_in(7);
  lfsr_c(30) <= lfsr_q(22) xor lfsr_q(28) xor lfsr_q(31) xor data_in(4) xor data_in(7);
  lfsr_c(31) <= lfsr_q(23) xor lfsr_q(29) xor data_in(5);

  -- CRC register update: async active-low reset, sync init, gated by crc_en
  process (clk, rst)
  begin
    if (rst = '0') or (init = '1') then
      lfsr_q <= (others => '1');         -- reload preset
    elsif rising_edge(clk) then
      if (crc_en = '1') then
        lfsr_q <= lfsr_c;                -- advance with current byte
      end if;
    end if;
  end process;
end architecture imp_crc;
