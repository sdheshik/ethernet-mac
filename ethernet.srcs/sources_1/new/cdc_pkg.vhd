----------------------------------------------------------------------------------
--
-- Project: ASPECT - Analyseur de SPECTre
-- Module Name: cdc_pkg.vhd
-- Target Devices: Nexys A7 100T
-- Tool Versions: Vivado 2023.1
-- Description: CDC package
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package cdc_pkg is

  component synchronizer is
    port (
      i_clk   : in  std_logic;
      i_rst_n : in  std_logic;
      i_data  : in  std_logic;
      o_data  : out std_logic);
  end component synchronizer;

  component pulse_synchronizer is
    port (
      i_clk_a   : in  std_logic;
      i_rst_n_a : in  std_logic;
      i_clk_b   : in  std_logic;
      i_rst_n_b : in  std_logic;
      i_pulse_a : in  std_logic;
      o_pulse_b : out std_logic);
  end component pulse_synchronizer;

  component fifo is
    generic (
      G_ADDR_WIDTH : positive;
      G_DATA_WIDTH : positive);
    port (
      i_write_clk  : in  std_logic;
      i_write_rstn : in  std_logic;
      i_write_en   : in  std_logic;
      i_write_data : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
      o_full       : out std_logic;
      i_read_clk   : in  std_logic;
      i_read_rstn  : in  std_logic;
      i_read_en    : in  std_logic;
      o_read_data  : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
      o_empty      : out std_logic);
  end component fifo;

  component dpram is
    generic (
      G_ADDR_WIDTH : positive;
      G_DATA_WIDTH : positive);
    port (
      i_clk_a   : in  std_logic;
      i_en_a    : in  std_logic;
      i_we_a    : in  std_logic;
      i_addr_a  : in  std_logic_vector(G_ADDR_WIDTH-1 downto 0);
      i_write_a : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
      o_read_a  : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
      i_clk_b   : in  std_logic;
      i_en_b    : in  std_logic;
      i_we_b    : in  std_logic;
      i_addr_b  : in  std_logic_vector(G_ADDR_WIDTH-1 downto 0);
      i_write_b : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
      o_read_b  : out std_logic_vector(G_DATA_WIDTH-1 downto 0));
  end component dpram;

  function gray2bin (gray : std_logic_vector) return std_logic_vector;
  function bin2gray (bin : std_logic_vector) return std_logic_vector;

end package cdc_pkg;

package body cdc_pkg is

  function gray2bin(gray : std_logic_vector) return std_logic_vector is
    variable bin : std_logic_vector(gray'length downto 0);
  begin
    bin := '0' & gray;
    for i in bin'left-1 downto 0
    loop
      bin(i) := bin(i+1) xor bin(i);
    end loop;
    return bin(bin'left-1 downto 0);
  end function;

  function bin2gray (bin : std_logic_vector) return std_logic_vector is
    variable gray : std_logic_vector(bin'length downto 0);
  begin
    gray := ('0' & bin) xor (bin & '0');
    return gray(bin'length downto 1);
  end function;

end package body cdc_pkg;
