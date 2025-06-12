library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-------------------------------------------------------------------------------
-- Entity: synchronizer
-- 2‐stage flip‐flop synchronizer to safely bring an asynchronous single‐bit
-- signal into the local clock domain, mitigating metastability.
-------------------------------------------------------------------------------
entity synchronizer is
  port (
    i_clk   : in  std_logic;  -- Destination domain clock
    i_rst_n : in  std_logic;  -- Active‐low synchronous reset
    i_data  : in  std_logic;  -- Asynchronous input signal
    o_data  : out std_logic   -- Synchronized output signal
  );
end entity synchronizer;

-------------------------------------------------------------------------------
-- Architecture: rtl
-------------------------------------------------------------------------------
architecture rtl of synchronizer is

  -----------------------------------------------------------------------------
  -- Internal Signals
  -----------------------------------------------------------------------------
  signal meta   : std_logic := '0';  -- First flop captures async input
  signal stable : std_logic := '0';  -- Second flop produces stable output

begin

  -- Drive the synchronized output  
  o_data <= stable;

  -----------------------------------------------------------------------------
  -- Two‐stage Synchronizer Process
  -- On each rising edge of i_clk:
  --   - Reset both flops to '0' if i_rst_n is low.
  --   - Otherwise, shift in i_data through meta into stable.
  -----------------------------------------------------------------------------
  p_sync : process(i_clk)
  begin
    if rising_edge(i_clk) then
      if i_rst_n = '0' then
        meta   <= '0';
        stable <= '0';
      else
        meta   <= i_data;  -- Capture asynchronous input
        stable <= meta;    -- Final synchronized output
      end if;
    end if;
  end process p_sync;

end architecture rtl;
