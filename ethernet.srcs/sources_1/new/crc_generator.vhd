library ieee;
use ieee.std_logic_1164.all;

entity crc_gen is
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;                       -- active-low async reset for this process
    init    : in  std_logic;                       -- synchronous init: reload CRC to all '1's
    crc_en  : in  std_logic;                       -- enable to advance CRC with current datain
    datain  : in  std_logic_vector(7 downto 0);    -- input byte (LSB-first reflected mapping)
    crc_out : out std_logic_vector(31 downto 0)    -- current CRC value (reflected+inverted)
  );
end entity;

architecture rtl of crc_gen is
  signal lfsr_q  : std_logic_vector(31 downto 0) := (others => '1'); -- CRC register (initialized to all '1's)
  signal lfsr_c  : std_logic_vector(31 downto 0);                    -- next-state CRC register
  signal data_in : std_logic_vector(7 downto 0) := (others => '0');  -- reflected bit order of datain

  ATTRIBUTE MARK_DEBUG : STRING;
  ATTRIBUTE MARK_DEBUG OF data_in : SIGNAL IS "true";
begin

  -- Map input byte to reflected bit order expected by the parallel CRC logic
  data_in(7) <= datain(0);
  data_in(6) <= datain(1);
  data_in(5) <= datain(2);
  data_in(4) <= datain(3);
  data_in(3) <= datain(4);
  data_in(2) <= datain(5);
  data_in(1) <= datain(6);
  data_in(0) <= datain(7);

  -- Parallel CRC32 next-state equations (reflected polynomial), 8-bit at a time
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

  -- CRC register update:
  -- - async active-low reset sets CRC to all 1's
  -- - init synchronously reloads CRC to all 1's
  -- - when crc_en='1', advance to next state lfsr_c
  process(clk, rst)
  begin
    if rst = '0' then
      lfsr_q <= (others => '1');
    elsif rising_edge(clk) then
      if init = '1' then
        lfsr_q <= (others => '1');
      elsif crc_en = '1' then
        lfsr_q <= lfsr_c;
      end if;
    end if;
  end process;

  -- Output reflected+finalized CRC (bitwise inversion and bit reverse)
  gen_final : for i in 0 to 31 generate
    crc_out(i) <= not lfsr_q(31 - i);
  end generate;

end architecture rtl;
