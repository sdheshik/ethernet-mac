library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-------------------------------------------------------------------------------
-- Entity: rst_sync
-- Synchronizes a global asynchronous reset into the local clock domain.
-- Uses a two-stage shift-register to ensure a clean, glitch-free reset release.
-------------------------------------------------------------------------------
entity rst_sync is
  port (
    i_clk   : in  std_logic;  -- Target domain clock
    i_rst_n : in  std_logic;  -- Global async reset (active-low)
    o_rst_n : out std_logic   -- Local synchronized reset (active-low)
  );
end entity rst_sync;

-------------------------------------------------------------------------------
-- Architecture: rtl
-------------------------------------------------------------------------------
architecture rtl of rst_sync is

  ---------------------------------------------------------------------------
  -- Internal Synchronizer Flip-Flops
  -- A two-bit shift register that captures the de-assertion of i_rst_n.
  ---------------------------------------------------------------------------
  signal sync_ff : std_logic_vector(1 downto 0) := (others => '0');

begin

  ---------------------------------------------------------------------------
  -- Reset Synchronization Process
  -- Async assertion when i_rst_n='0', then shift in '1's each clock edge
  -- once reset is released.
  ---------------------------------------------------------------------------
  process(i_clk, i_rst_n)
  begin
    if i_rst_n = '0' then
      -- Immediately assert local reset
      sync_ff <= (others => '0');
    elsif rising_edge(i_clk) then
      -- Shift in '1' to release reset gradually
      sync_ff(0) <= '1';
      sync_ff(1) <= sync_ff(0);
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Synchronized Reset Output
  -- Only de-assert after two consecutive clocks of i_rst_n='1'.
  ---------------------------------------------------------------------------
  o_rst_n <= sync_ff(1);

end architecture rtl;
