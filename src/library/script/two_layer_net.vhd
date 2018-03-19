library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library unisim;
use unisim.vcomponents.all;

entity two_layer_net is
  port(
    refclk200_p        : in    std_logic;
    refclk200_n        : in    std_logic;
    perst_n            : in    std_logic;
    pcie100_p          : in    std_logic;
    pcie100_n          : in    std_logic;
    pci_exp_txn        : out   std_logic_vector(7 downto 0);
    pci_exp_txp        : out   std_logic_vector(7 downto 0);
    pci_exp_rxn        : in    std_logic_vector(7 downto 0);
    pci_exp_rxp        : in    std_logic_vector(7 downto 0);
    model_inout        : inout std_logic_vector(55 downto 0)
  );
end entity;

architecture admpcie7v3_axi4 of two_layer_net is

  constant m_axi_axaddr_width : natural := 33;
  constant m_axi_xdata_width : natural := 512;
  constant mig_ranks : natural := 2;

  constant adb3_axaddr_width : natural := 39;
  constant adb3_xdata_width : natural := 256;
  constant pre_hls_addr_width : natural := 12;
  constant hls_axilite_addr_width : natural := 5;
  constant hls_axilite_data_width : natural := 32;
  constant hls_axiaddr_width : natural := 32;
  constant hls_xdata_width : natural := 32;
  constant bctl_axaddr_width : natural := 20;
  constant blk_mem_axaddr_width : natural := 32;

  -- Calculate pack_factor
  constant phys_data_width : natural := 64;
  constant pack_factor : natural := m_axi_xdata_width / phys_data_width;

  -- Calculate AXI4 address width; should exactly match that of MIG's AXI4 interface
  constant num_byte_lanes : natural := m_axi_xdata_width / 8;
  constant log2_num_byte_lanes : natural := natural(floor(log2(real(num_byte_lanes) + 0.5)));

  -- AXI4 burst length width to match that of MIG's AXI4 interface
  constant m_axi_axlen_width : natural := 8;

  -- AXI4 TID width to match that of MIG's AXI4 interface
  constant m_axi_xid_width : natural := 4;

  component adb3_admpcie7v3_m
    port(
      perst_n : in std_logic;
      pcie100_p : in std_logic;
      pcie100_n : in std_logic;
      refclk200_p : in std_logic;
      refclk200_n : in std_logic;
      refclk : out std_logic;
      aclk : out std_logic;
      aresetn : out std_logic;
      pci_exp_txn : out std_logic_vector(7 downto 0);
      pci_exp_txp : out std_logic_vector(7 downto 0);
      pci_exp_rxn : in std_logic_vector(7 downto 0);
      pci_exp_rxp : in std_logic_vector(7 downto 0);
      model_inout_i : in std_logic_vector(55 downto 0);
      model_inout_o : out std_logic_vector(55 downto 0);
      model_inout_t : out std_logic_vector(55 downto 0);
      ds_axi_awaddr : out std_logic_vector(63 downto 0);
      ds_axi_awlen : out std_logic_vector(m_axi_axlen_width - 1 downto 0);
      ds_axi_awsize : out std_logic_vector(2 downto 0);
      ds_axi_awburst : out std_logic_vector(1 downto 0);
      ds_axi_awcache : out std_logic_vector(3 downto 0);
      ds_axi_awprot : out std_logic_vector(2 downto 0);
      ds_axi_awvalid : out std_logic;
      ds_axi_wdata : out std_logic_vector(adb3_xdata_width - 1 downto 0);
      ds_axi_wstrb : out std_logic_vector(adb3_xdata_width / 8 - 1 downto 0);
      ds_axi_wlast : out std_logic;
      ds_axi_wvalid : out std_logic;
      ds_axi_bready : out std_logic;
      ds_axi_araddr : out std_logic_vector(63 downto 0);
      ds_axi_arlen : out std_logic_vector(m_axi_axlen_width - 1 downto 0);
      ds_axi_arsize : out std_logic_vector(2 downto 0);
      ds_axi_arburst : out std_logic_vector(1 downto 0);
      ds_axi_arcache : out std_logic_vector(3 downto 0);
      ds_axi_arprot : out std_logic_vector(2 downto 0);
      ds_axi_arvalid : out std_logic;
      ds_axi_rready : out std_logic;
      ds_axi_awready : in std_logic;
      ds_axi_wready : in std_logic;
      ds_axi_bresp : in std_logic_vector(1 downto 0);
      ds_axi_bvalid : in std_logic;
      ds_axi_arready : in std_logic;
      ds_axi_rdata : in std_logic_vector(adb3_xdata_width - 1 downto 0);
      ds_axi_rresp : in std_logic_vector(1 downto 0);
      ds_axi_rlast : in std_logic;
      ds_axi_rvalid : in std_logic;
      ds_axi_awlock : out std_logic_vector(0 downto 0);
      ds_axi_awqos : out std_logic_vector(3 downto 0);
      ds_axi_arlock : out std_logic_vector(0 downto 0);
      ds_axi_arqos : out std_logic_vector(3 downto 0);
      ds_axi_awregion : out std_logic_vector(3 downto 0);
      ds_axi_arregion : out std_logic_vector(3 downto 0);

      dma0_axi_awaddr : out std_logic_vector(adb3_axaddr_width - 1 downto 0);
      dma0_axi_awlen : out std_logic_vector(m_axi_axlen_width - 1 downto 0);
      dma0_axi_awsize : out std_logic_vector(2 downto 0);
      dma0_axi_awburst : out std_logic_vector(1 downto 0);
      dma0_axi_awcache : out std_logic_vector(3 downto 0);
      dma0_axi_awprot : out std_logic_vector(2 downto 0);
      dma0_axi_awvalid : out std_logic;
      dma0_axi_wdata : out std_logic_vector(adb3_xdata_width - 1 downto 0);
      dma0_axi_wstrb : out std_logic_vector(adb3_xdata_width / 8 - 1 downto 0);
      dma0_axi_wlast : out std_logic;
      dma0_axi_wvalid : out std_logic;
      dma0_axi_bready : out std_logic;
      dma0_axi_araddr : out std_logic_vector(adb3_axaddr_width - 1 downto 0);
      dma0_axi_arlen : out std_logic_vector(m_axi_axlen_width - 1 downto 0);
      dma0_axi_arsize : out std_logic_vector(2 downto 0);
      dma0_axi_arburst : out std_logic_vector(1 downto 0);
      dma0_axi_arcache : out std_logic_vector(3 downto 0);
      dma0_axi_arprot : out std_logic_vector(2 downto 0);
      dma0_axi_arvalid : out std_logic;
      dma0_axi_rready : out std_logic;
      dma0_axi_awready : in std_logic;
      dma0_axi_wready : in std_logic;
      dma0_axi_bresp : in std_logic_vector(1 downto 0);
      dma0_axi_bvalid : in std_logic;
      dma0_axi_arready : in std_logic;
      dma0_axi_rdata : in std_logic_vector(adb3_xdata_width - 1 downto 0);
      dma0_axi_rresp : in std_logic_vector(1 downto 0);
      dma0_axi_rlast : in std_logic;
      dma0_axi_rvalid : in std_logic;
      dma0_axi_awlock : out std_logic_vector(0 to 0);
      dma0_axi_awqos : out std_logic_vector(3 downto 0);
      dma0_axi_arlock : out std_logic_vector(0 to 0);
      dma0_axi_arqos : out std_logic_vector(3 downto 0);
      dma0_axi_awregion : out std_logic_vector(3 downto 0);
      dma0_axi_arregion : out std_logic_vector(3 downto 0);

      dma1_axi_awaddr : out std_logic_vector(adb3_axaddr_width - 1 downto 0);
      dma1_axi_awlen : out std_logic_vector(m_axi_axlen_width - 1 downto 0);
      dma1_axi_awsize : out std_logic_vector(2 downto 0);
      dma1_axi_awburst : out std_logic_vector(1 downto 0);
      dma1_axi_awcache : out std_logic_vector(3 downto 0);
      dma1_axi_awprot : out std_logic_vector(2 downto 0);
      dma1_axi_awvalid : out std_logic;
      dma1_axi_wdata : out std_logic_vector(adb3_xdata_width - 1 downto 0);
      dma1_axi_wstrb : out std_logic_vector(adb3_xdata_width / 8 - 1 downto 0);
      dma1_axi_wlast : out std_logic;
      dma1_axi_wvalid : out std_logic;
      dma1_axi_bready : out std_logic;
      dma1_axi_araddr : out std_logic_vector(adb3_axaddr_width - 1 downto 0);
      dma1_axi_arlen : out std_logic_vector(m_axi_axlen_width - 1 downto 0);
      dma1_axi_arsize : out std_logic_vector(2 downto 0);
      dma1_axi_arburst : out std_logic_vector(1 downto 0);
      dma1_axi_arcache : out std_logic_vector(3 downto 0);
      dma1_axi_arprot : out std_logic_vector(2 downto 0);
      dma1_axi_arvalid : out std_logic;
      dma1_axi_rready : out std_logic;
      dma1_axi_awready : in std_logic;
      dma1_axi_wready : in std_logic;
      dma1_axi_bresp : in std_logic_vector(1 downto 0);
      dma1_axi_bvalid : in std_logic;
      dma1_axi_arready : in std_logic;
      dma1_axi_rdata : in std_logic_vector(adb3_xdata_width - 1 downto 0);
      dma1_axi_rresp : in std_logic_vector(1 downto 0);
      dma1_axi_rlast : in std_logic;
      dma1_axi_rvalid : in std_logic;
      dma1_axi_awlock : out std_logic_vector(0 to 0);
      dma1_axi_awqos : out std_logic_vector(3 downto 0);
      dma1_axi_arlock : out std_logic_vector(0 to 0);
      dma1_axi_arqos : out std_logic_vector(3 downto 0);
      dma1_axi_awregion : out std_logic_vector(3 downto 0);
      dma1_axi_arregion : out std_logic_vector(3 downto 0);

      core_status : out std_logic_vector(63 downto 0)
    );
  end component;

  component axi_dwidth_converter_dma_m
    port (
      s_axi_aclk : in std_logic;
      s_axi_aresetn : in std_logic;
      s_axi_awaddr : in std_logic_vector(m_axi_axaddr_width - 1 downto 0);
      s_axi_awlen : in std_logic_vector(m_axi_axlen_width - 1 downto 0);
      s_axi_awsize : in std_logic_vector(2 downto 0);
      s_axi_awburst : in std_logic_vector(1 downto 0);
      s_axi_awlock : in std_logic_vector(0 downto 0);
      s_axi_awcache : in std_logic_vector(3 downto 0);
      s_axi_awprot : in std_logic_vector(2 downto 0);
      s_axi_awregion : in std_logic_vector(3 downto 0);
      s_axi_awqos : in std_logic_vector(3 downto 0);
      s_axi_awvalid : in std_logic;
      s_axi_awready : out std_logic;
      s_axi_wdata : in std_logic_vector(adb3_xdata_width - 1 downto 0);
      s_axi_wstrb : in std_logic_vector(adb3_xdata_width / 8 - 1 downto 0);
      s_axi_wlast : in std_logic;
      s_axi_wvalid : in std_logic;
      s_axi_wready : out std_logic;
      s_axi_bresp : out std_logic_vector(1 downto 0);
      s_axi_bvalid : out std_logic;
      s_axi_bready : in std_logic;
      s_axi_araddr : in std_logic_vector(m_axi_axaddr_width - 1 downto 0);
      s_axi_arlen : in std_logic_vector(m_axi_axlen_width - 1 downto 0);
      s_axi_arsize : in std_logic_vector(2 downto 0);
      s_axi_arburst : in std_logic_vector(1 downto 0);
      s_axi_arlock : in std_logic_vector(0 downto 0);
      s_axi_arcache : in std_logic_vector(3 downto 0);
      s_axi_arprot : in std_logic_vector(2 downto 0);
      s_axi_arregion : in std_logic_vector(3 downto 0);
      s_axi_arqos : in std_logic_vector(3 downto 0);
      s_axi_arvalid : in std_logic;
      s_axi_arready : out std_logic;
      s_axi_rdata : out std_logic_vector(adb3_xdata_width - 1 downto 0);
      s_axi_rresp : out std_logic_vector(1 downto 0);
      s_axi_rlast : out std_logic;
      s_axi_rvalid : out std_logic;
      s_axi_rready : in std_logic;

      m_axi_awaddr : out std_logic_vector(m_axi_axaddr_width - 1 downto 0);
      m_axi_awlen : out std_logic_vector(m_axi_axlen_width - 1 downto 0);
      m_axi_awsize : out std_logic_vector(2 downto 0);
      m_axi_awburst : out std_logic_vector(1 downto 0);
      m_axi_awlock : out std_logic_vector(0 downto 0);
      m_axi_awcache : out std_logic_vector(3 downto 0);
      m_axi_awprot : out std_logic_vector(2 downto 0);
      m_axi_awregion : out std_logic_vector(3 downto 0);
      m_axi_awqos : out std_logic_vector(3 downto 0);
      m_axi_awvalid : out std_logic;
      m_axi_awready : in std_logic;
      m_axi_wdata : out std_logic_vector(m_axi_xdata_width - 1 downto 0);
      m_axi_wstrb : out std_logic_vector(m_axi_xdata_width / 8 - 1 downto 0);
      m_axi_wlast : out std_logic;
      m_axi_wvalid : out std_logic;
      m_axi_wready : in std_logic;
      m_axi_bresp : in std_logic_vector(1 downto 0);
      m_axi_bvalid : in std_logic;
      m_axi_bready : out std_logic;
      m_axi_araddr : out std_logic_vector(m_axi_axaddr_width - 1 downto 0);
      m_axi_arlen : out std_logic_vector(m_axi_axlen_width - 1 downto 0);
      m_axi_arsize : out std_logic_vector(2 downto 0);
      m_axi_arburst : out std_logic_vector(1 downto 0);
      m_axi_arlock : out std_logic_vector(0 downto 0);
      m_axi_arcache : out std_logic_vector(3 downto 0);
      m_axi_arprot : out std_logic_vector(2 downto 0);
      m_axi_arregion : out std_logic_vector(3 downto 0);
      m_axi_arqos : out std_logic_vector(3 downto 0);
      m_axi_arvalid : out std_logic;
      m_axi_arready : in std_logic;
      m_axi_rdata : in std_logic_vector(m_axi_xdata_width - 1 downto 0);
      m_axi_rresp : in std_logic_vector(1 downto 0);
      m_axi_rlast : in std_logic;
      m_axi_rvalid : in std_logic;
      m_axi_rready : out std_logic
    );
  end component;


  component axi_dwidth_converter_pre_hls_m
    port (
      s_axi_aclk : in std_logic;
      s_axi_aresetn : in std_logic;
      s_axi_awaddr : in std_logic_vector(pre_hls_addr_width - 1 downto 0);
      s_axi_awlen : in std_logic_vector(m_axi_axlen_width - 1 downto 0);
      s_axi_awsize : in std_logic_vector(2 downto 0);
      s_axi_awburst : in std_logic_vector(1 downto 0);
      s_axi_awlock : in std_logic_vector(0 downto 0);
      s_axi_awcache : in std_logic_vector(3 downto 0);
      s_axi_awprot : in std_logic_vector(2 downto 0);
      s_axi_awregion : in std_logic_vector(3 downto 0);
      s_axi_awqos : in std_logic_vector(3 downto 0);
      s_axi_awvalid : in std_logic;
      s_axi_awready : out std_logic;
      s_axi_wdata : in std_logic_vector(adb3_xdata_width - 1 downto 0);
      s_axi_wstrb : in std_logic_vector(adb3_xdata_width / 8 - 1 downto 0);
      s_axi_wlast : in std_logic;
      s_axi_wvalid : in std_logic;
      s_axi_wready : out std_logic;
      s_axi_bresp : out std_logic_vector(1 downto 0);
      s_axi_bvalid : out std_logic;
      s_axi_bready : in std_logic;
      s_axi_araddr : in std_logic_vector(pre_hls_addr_width - 1 downto 0);
      s_axi_arlen : in std_logic_vector(m_axi_axlen_width - 1 downto 0);
      s_axi_arsize : in std_logic_vector(2 downto 0);
      s_axi_arburst : in std_logic_vector(1 downto 0);
      s_axi_arlock : in std_logic_vector(0 downto 0);
      s_axi_arcache : in std_logic_vector(3 downto 0);
      s_axi_arprot : in std_logic_vector(2 downto 0);
      s_axi_arregion : in std_logic_vector(3 downto 0);
      s_axi_arqos : in std_logic_vector(3 downto 0);
      s_axi_arvalid : in std_logic;
      s_axi_arready : out std_logic;
      s_axi_rdata : out std_logic_vector(adb3_xdata_width - 1 downto 0);
      s_axi_rresp : out std_logic_vector(1 downto 0);
      s_axi_rlast : out std_logic;
      s_axi_rvalid : out std_logic;
      s_axi_rready : in std_logic;
      m_axi_awaddr : out std_logic_vector(pre_hls_addr_width - 1 downto 0);
      m_axi_awlen : out std_logic_vector(m_axi_axlen_width - 1 downto 0);
      m_axi_awsize : out std_logic_vector(2 downto 0);
      m_axi_awburst : out std_logic_vector(1 downto 0);
      m_axi_awlock : out std_logic_vector(0 downto 0);
      m_axi_awcache : out std_logic_vector(3 downto 0);
      m_axi_awprot : out std_logic_vector(2 downto 0);
      m_axi_awregion : out std_logic_vector(3 downto 0);
      m_axi_awqos : out std_logic_vector(3 downto 0);
      m_axi_awvalid : out std_logic;
      m_axi_awready : in std_logic;
      m_axi_wdata : out std_logic_vector(hls_axilite_data_width - 1 downto 0);
      m_axi_wstrb : out std_logic_vector(3 downto 0);
      m_axi_wlast : out std_logic;
      m_axi_wvalid : out std_logic;
      m_axi_wready : in std_logic;
      m_axi_bresp : in std_logic_vector(1 downto 0);
      m_axi_bvalid : in std_logic;
      m_axi_bready : out std_logic;
      m_axi_araddr : out std_logic_vector(pre_hls_addr_width - 1 downto 0);
      m_axi_arlen : out std_logic_vector(m_axi_axlen_width - 1 downto 0);
      m_axi_arsize : out std_logic_vector(2 downto 0);
      m_axi_arburst : out std_logic_vector(1 downto 0);
      m_axi_arlock : out std_logic_vector(0 downto 0);
      m_axi_arcache : out std_logic_vector(3 downto 0);
      m_axi_arprot : out std_logic_vector(2 downto 0);
      m_axi_arregion : out std_logic_vector(3 downto 0);
      m_axi_arqos : out std_logic_vector(3 downto 0);
      m_axi_arvalid : out std_logic;
      m_axi_arready : in std_logic;
      m_axi_rdata : in std_logic_vector(hls_axilite_data_width - 1 downto 0);
      m_axi_rresp : in std_logic_vector(1 downto 0);
      m_axi_rlast : in std_logic;
      m_axi_rvalid : in std_logic;
      m_axi_rready : out std_logic
    );
  end component;


  component axi_protocol_converter_hls_m
    port (
      aclk : in std_logic;
      aresetn : in std_logic;
      s_axi_awaddr : in std_logic_vector(pre_hls_addr_width - 1 downto 0);
      s_axi_awlen : in std_logic_vector(m_axi_axlen_width - 1 downto 0);
      s_axi_awsize : in std_logic_vector(2 downto 0);
      s_axi_awburst : in std_logic_vector(1 downto 0);
      s_axi_awlock : in std_logic_vector(0 downto 0);
      s_axi_awcache : in std_logic_vector(3 downto 0);
      s_axi_awprot : in std_logic_vector(2 downto 0);
      s_axi_awregion : in std_logic_vector(3 downto 0);
      s_axi_awqos : in std_logic_vector(3 downto 0);
      s_axi_awvalid : in std_logic;
      s_axi_awready : out std_logic;
      s_axi_wdata : in std_logic_vector(hls_axilite_data_width - 1 downto 0);
      s_axi_wstrb : in std_logic_vector(3 downto 0);
      s_axi_wlast : in std_logic;
      s_axi_wvalid : in std_logic;
      s_axi_wready : out std_logic;
      s_axi_bresp : out std_logic_vector(1 downto 0);
      s_axi_bvalid : out std_logic;
      s_axi_bready : in std_logic;
      s_axi_araddr : in std_logic_vector(pre_hls_addr_width - 1 downto 0);
      s_axi_arlen : in std_logic_vector(m_axi_axlen_width - 1 downto 0);
      s_axi_arsize : in std_logic_vector(2 downto 0);
      s_axi_arburst : in std_logic_vector(1 downto 0);
      s_axi_arlock : in std_logic_vector(0 downto 0);
      s_axi_arcache : in std_logic_vector(3 downto 0);
      s_axi_arprot : in std_logic_vector(2 downto 0);
      s_axi_arregion : in std_logic_vector(3 downto 0);
      s_axi_arqos : in std_logic_vector(3 downto 0);
      s_axi_arvalid : in std_logic;
      s_axi_arready : out std_logic;
      s_axi_rdata : out std_logic_vector(hls_axilite_data_width - 1 downto 0);
      s_axi_rresp : out std_logic_vector(1 downto 0);
      s_axi_rlast : out std_logic;
      s_axi_rvalid : out std_logic;
      s_axi_rready : in std_logic;
      m_axi_awaddr : out std_logic_vector(pre_hls_addr_width - 1 downto 0);
      m_axi_awprot : out std_logic_vector(2 downto 0);
      m_axi_awvalid : out std_logic;
      m_axi_awready : in std_logic;
      m_axi_wdata : out std_logic_vector(hls_axilite_data_width - 1 downto 0);
      m_axi_wstrb : out std_logic_vector(3 downto 0);
      m_axi_wvalid : out std_logic;
      m_axi_wready : in std_logic;
      m_axi_bresp : in std_logic_vector(1 downto 0);
      m_axi_bvalid : in std_logic;
      m_axi_bready : out std_logic;
      m_axi_araddr : out std_logic_vector(pre_hls_addr_width - 1 downto 0);
      m_axi_arprot : out std_logic_vector(2 downto 0);
      m_axi_arvalid : out std_logic;
      m_axi_arready : in std_logic;
      m_axi_rdata : in std_logic_vector(hls_axilite_data_width - 1 downto 0);
      m_axi_rresp : in std_logic_vector(1 downto 0);
      m_axi_rvalid : in std_logic;
      m_axi_rready : out std_logic
    );
  end component;


  component two_layer_net_m
    port (
      s_axi_control_awaddr : in std_logic_vector(hls_axilite_addr_width - 1 downto 0);
      s_axi_control_awvalid : in std_logic;
      s_axi_control_awready : out std_logic;
      s_axi_control_wdata : in std_logic_vector(hls_axilite_data_width - 1 downto 0);
      s_axi_control_wstrb : in std_logic_vector(hls_axilite_data_width / 8 - 1 downto 0);
      s_axi_control_wvalid : in std_logic;
      s_axi_control_wready : out std_logic;
      s_axi_control_bresp : out std_logic_vector(1 downto 0);
      s_axi_control_bvalid : out std_logic;
      s_axi_control_bready : in std_logic;
      s_axi_control_araddr : in std_logic_vector(hls_axilite_addr_width - 1 downto 0);
      s_axi_control_arvalid : in std_logic;
      s_axi_control_arready : out std_logic;
      s_axi_control_rdata : out std_logic_vector(hls_axilite_data_width - 1 downto 0);
      s_axi_control_rresp : out std_logic_vector(1 downto 0);
      s_axi_control_rvalid : out std_logic;
      s_axi_control_rready : in std_logic;
      ap_clk : in std_logic;
      ap_rst_n : in std_logic;
      interrupt : out std_logic;
      m_axi_hostmem_awaddr : out std_logic_vector(hls_axiaddr_width - 1 downto 0);
      m_axi_hostmem_awlen : out std_logic_vector(m_axi_axlen_width - 1 downto 0);
      m_axi_hostmem_awsize : out std_logic_vector(2 downto 0);
      m_axi_hostmem_awburst : out std_logic_vector(1 downto 0);
      m_axi_hostmem_awlock : out std_logic_vector(1 downto 0);
      m_axi_hostmem_awregion : out std_logic_vector(3 downto 0);
      m_axi_hostmem_awcache : out std_logic_vector(3 downto 0);
      m_axi_hostmem_awprot : out std_logic_vector(2 downto 0);
      m_axi_hostmem_awqos : out std_logic_vector(3 downto 0);
      m_axi_hostmem_awvalid : out std_logic;
      m_axi_hostmem_awready : in std_logic;
      m_axi_hostmem_wdata : out std_logic_vector(hls_xdata_width - 1 downto 0);
      m_axi_hostmem_wstrb : out std_logic_vector(hls_xdata_width / 8 - 1 downto 0);
      m_axi_hostmem_wlast : out std_logic;
      m_axi_hostmem_wvalid : out std_logic;
      m_axi_hostmem_wready : in std_logic;
      m_axi_hostmem_bresp : in std_logic_vector(1 downto 0);
      m_axi_hostmem_bvalid : in std_logic;
      m_axi_hostmem_bready : out std_logic;
      m_axi_hostmem_araddr : out std_logic_vector(hls_axiaddr_width - 1 downto 0);
      m_axi_hostmem_arlen : out std_logic_vector(m_axi_axlen_width - 1 downto 0);
      m_axi_hostmem_arsize : out std_logic_vector(2 downto 0);
      m_axi_hostmem_arburst : out std_logic_vector(1 downto 0);
      m_axi_hostmem_arlock : out std_logic_vector(1 downto 0);
      m_axi_hostmem_arregion : out std_logic_vector(3 downto 0);
      m_axi_hostmem_arcache : out std_logic_vector(3 downto 0);
      m_axi_hostmem_arprot : out std_logic_vector(2 downto 0);
      m_axi_hostmem_arqos : out std_logic_vector(3 downto 0);
      m_axi_hostmem_arvalid : out std_logic;
      m_axi_hostmem_arready : in std_logic;
      m_axi_hostmem_rdata : in std_logic_vector(hls_xdata_width - 1 downto 0);
      m_axi_hostmem_rresp : in std_logic_vector(1 downto 0);
      m_axi_hostmem_rlast : in std_logic;
      m_axi_hostmem_rvalid : in std_logic;
      m_axi_hostmem_rready : out std_logic
    );
  end component;


  component axi_dwidth_converter_post_hls_m
    port (
      s_axi_aclk : in std_logic;
      s_axi_aresetn : in std_logic;
      s_axi_awaddr : in std_logic_vector(m_axi_axaddr_width - 1 downto 0);
      s_axi_awlen : in std_logic_vector(m_axi_axlen_width - 1 downto 0);
      s_axi_awsize : in std_logic_vector(2 downto 0);
      s_axi_awburst : in std_logic_vector(1 downto 0);
      s_axi_awlock : in std_logic_vector(0 downto 0);
      s_axi_awcache : in std_logic_vector(3 downto 0);
      s_axi_awprot : in std_logic_vector(2 downto 0);
      s_axi_awregion : in std_logic_vector(3 downto 0);
      s_axi_awqos : in std_logic_vector(3 downto 0);
      s_axi_awvalid : in std_logic;
      s_axi_awready : out std_logic;
      s_axi_wdata : in std_logic_vector(hls_xdata_width - 1 downto 0);
      s_axi_wstrb : in std_logic_vector(hls_xdata_width / 8 - 1 downto 0);
      s_axi_wlast : in std_logic;
      s_axi_wvalid : in std_logic;
      s_axi_wready : out std_logic;
      s_axi_bresp : out std_logic_vector(1 downto 0);
      s_axi_bvalid : out std_logic;
      s_axi_bready : in std_logic;
      s_axi_araddr : in std_logic_vector(m_axi_axaddr_width - 1 downto 0);
      s_axi_arlen : in std_logic_vector(m_axi_axlen_width - 1 downto 0);
      s_axi_arsize : in std_logic_vector(2 downto 0);
      s_axi_arburst : in std_logic_vector(1 downto 0);
      s_axi_arlock : in std_logic_vector(0 downto 0);
      s_axi_arcache : in std_logic_vector(3 downto 0);
      s_axi_arprot : in std_logic_vector(2 downto 0);
      s_axi_arregion : in std_logic_vector(3 downto 0);
      s_axi_arqos : in std_logic_vector(3 downto 0);
      s_axi_arvalid : in std_logic;
      s_axi_arready : out std_logic;
      s_axi_rdata : out std_logic_vector(hls_xdata_width - 1 downto 0);
      s_axi_rresp : out std_logic_vector(1 downto 0);
      s_axi_rlast : out std_logic;
      s_axi_rvalid : out std_logic;
      s_axi_rready : in std_logic;
      m_axi_awaddr : out std_logic_vector(m_axi_axaddr_width - 1 downto 0);
      m_axi_awlen : out std_logic_vector(m_axi_axlen_width - 1 downto 0);
      m_axi_awsize : out std_logic_vector(2 downto 0);
      m_axi_awburst : out std_logic_vector(1 downto 0);
      m_axi_awlock : out std_logic_vector(0 downto 0);
      m_axi_awcache : out std_logic_vector(3 downto 0);
      m_axi_awprot : out std_logic_vector(2 downto 0);
      m_axi_awregion : out std_logic_vector(3 downto 0);
      m_axi_awqos : out std_logic_vector(3 downto 0);
      m_axi_awvalid : out std_logic;
      m_axi_awready : in std_logic;
      m_axi_wdata : out std_logic_vector(m_axi_xdata_width - 1 downto 0);
      m_axi_wstrb : out std_logic_vector(m_axi_xdata_width / 8 - 1 downto 0);
      m_axi_wlast : out std_logic;
      m_axi_wvalid : out std_logic;
      m_axi_wready : in std_logic;
      m_axi_bresp : in std_logic_vector(1 downto 0);
      m_axi_bvalid : in std_logic;
      m_axi_bready : out std_logic;
      m_axi_araddr : out std_logic_vector(m_axi_axaddr_width - 1 downto 0);
      m_axi_arlen : out std_logic_vector(m_axi_axlen_width - 1 downto 0);
      m_axi_arsize : out std_logic_vector(2 downto 0);
      m_axi_arburst : out std_logic_vector(1 downto 0);
      m_axi_arlock : out std_logic_vector(0 downto 0);
      m_axi_arcache : out std_logic_vector(3 downto 0);
      m_axi_arprot : out std_logic_vector(2 downto 0);
      m_axi_arregion : out std_logic_vector(3 downto 0);
      m_axi_arqos : out std_logic_vector(3 downto 0);
      m_axi_arvalid : out std_logic;
      m_axi_arready : in std_logic;
      m_axi_rdata : in std_logic_vector(m_axi_xdata_width - 1 downto 0);
      m_axi_rresp : in std_logic_vector(1 downto 0);
      m_axi_rlast : in std_logic;
      m_axi_rvalid : in std_logic;
      m_axi_rready : out std_logic
    );
  end component;


  component axi_crossbar_c0_m
    port (
      aclk : in std_logic;
      aresetn : in std_logic;
      s_axi_awid : in std_logic_vector(1 downto 0);
      s_axi_awaddr : in std_logic_vector(m_axi_axaddr_width * 2 - 1 downto 0);
      s_axi_awlen : in std_logic_vector(m_axi_axlen_width * 2 - 1 downto 0);
      s_axi_awsize : in std_logic_vector(5 downto 0);
      s_axi_awburst : in std_logic_vector(3 downto 0);
      s_axi_awlock : in std_logic_vector(1 downto 0);
      s_axi_awcache : in std_logic_vector(7 downto 0);
      s_axi_awprot : in std_logic_vector(5 downto 0);
      s_axi_awqos : in std_logic_vector(7 downto 0);
      s_axi_awvalid : in std_logic_vector(1 downto 0);
      s_axi_awready : out std_logic_vector(1 downto 0);
      s_axi_wdata : in std_logic_vector(m_axi_xdata_width * 2 - 1 downto 0);
      s_axi_wstrb : in std_logic_vector(m_axi_xdata_width / 8 * 2 - 1 downto 0);
      s_axi_wlast : in std_logic_vector(1 downto 0);
      s_axi_wvalid : in std_logic_vector(1 downto 0);
      s_axi_wready : out std_logic_vector(1 downto 0);
      s_axi_bid : out std_logic_vector(1 downto 0);
      s_axi_bresp : out std_logic_vector(3 downto 0);
      s_axi_bvalid : out std_logic_vector(1 downto 0);
      s_axi_bready : in std_logic_vector(1 downto 0);
      s_axi_arid : in std_logic_vector(1 downto 0);
      s_axi_araddr : in std_logic_vector(m_axi_axaddr_width * 2 - 1 downto 0);
      s_axi_arlen : in std_logic_vector(m_axi_axlen_width * 2 - 1 downto 0);
      s_axi_arsize : in std_logic_vector(5 downto 0);
      s_axi_arburst : in std_logic_vector(3 downto 0);
      s_axi_arlock : in std_logic_vector(1 downto 0);
      s_axi_arcache : in std_logic_vector(7 downto 0);
      s_axi_arprot : in std_logic_vector(5 downto 0);
      s_axi_arqos : in std_logic_vector(7 downto 0);
      s_axi_arvalid : in std_logic_vector(1 downto 0);
      s_axi_arready : out std_logic_vector(1 downto 0);
      s_axi_rid : out std_logic_vector(1 downto 0);
      s_axi_rdata : out std_logic_vector(m_axi_xdata_width * 2 - 1 downto 0);
      s_axi_rresp : out std_logic_vector(3 downto 0);
      s_axi_rlast : out std_logic_vector(1 downto 0);
      s_axi_rvalid : out std_logic_vector(1 downto 0);
      s_axi_rready : in std_logic_vector(1 downto 0);

      m_axi_awid : out std_logic_vector(0 downto 0);
      m_axi_awaddr : out std_logic_vector(m_axi_axaddr_width - 1 downto 0);
      m_axi_awlen : out std_logic_vector(m_axi_axlen_width - 1 downto 0);
      m_axi_awsize : out std_logic_vector(2 downto 0);
      m_axi_awburst : out std_logic_vector(1 downto 0);
      m_axi_awlock : out std_logic_vector(0 downto 0);
      m_axi_awcache : out std_logic_vector(3 downto 0);
      m_axi_awprot : out std_logic_vector(2 downto 0);
      m_axi_awregion : out std_logic_vector(3 downto 0);
      m_axi_awqos : out std_logic_vector(3 downto 0);
      m_axi_awvalid : out std_logic;
      m_axi_awready : in std_logic;
      m_axi_wdata : out std_logic_vector(m_axi_xdata_width - 1 downto 0);
      m_axi_wstrb : out std_logic_vector(m_axi_xdata_width / 8 - 1 downto 0);
      m_axi_wlast : out std_logic;
      m_axi_wvalid : out std_logic;
      m_axi_wready : in std_logic;
      m_axi_bid : in std_logic_vector(0 downto 0);
      m_axi_bresp : in std_logic_vector(1 downto 0);
      m_axi_bvalid : in std_logic;
      m_axi_bready : out std_logic;
      m_axi_arid : out std_logic_vector(0 downto 0);
      m_axi_araddr : out std_logic_vector(m_axi_axaddr_width - 1 downto 0);
      m_axi_arlen : out std_logic_vector(m_axi_axlen_width - 1 downto 0);
      m_axi_arsize : out std_logic_vector(2 downto 0);
      m_axi_arburst : out std_logic_vector(1 downto 0);
      m_axi_arlock : out std_logic_vector(0 downto 0);
      m_axi_arcache : out std_logic_vector(3 downto 0);
      m_axi_arprot : out std_logic_vector(2 downto 0);
      m_axi_arregion : out std_logic_vector(3 downto 0);
      m_axi_arqos : out std_logic_vector(3 downto 0);
      m_axi_arvalid : out std_logic;
      m_axi_arready : in std_logic;
      m_axi_rid : in std_logic_vector(0 downto 0);
      m_axi_rdata : in std_logic_vector(m_axi_xdata_width - 1 downto 0);
      m_axi_rresp : in std_logic_vector(1 downto 0);
      m_axi_rlast : in std_logic;
      m_axi_rvalid : in std_logic;
      m_axi_rready : out std_logic
    );
  end component;


  component axi_bram_ctrl_m
    port (
      s_axi_aclk : in std_logic;
      s_axi_aresetn : in std_logic;
      s_axi_awaddr : in std_logic_vector(bctl_axaddr_width - 1 downto 0);
      s_axi_awlen : in std_logic_vector(m_axi_axlen_width - 1 downto 0);
      s_axi_awsize : in std_logic_vector(2 downto 0);
      s_axi_awburst : in std_logic_vector(1 downto 0);
      s_axi_awlock : in std_logic_vector(0 downto 0);
      s_axi_awcache : in std_logic_vector(3 downto 0);
      s_axi_awprot : in std_logic_vector(2 downto 0);
      s_axi_awvalid : in std_logic;
      s_axi_awready : out std_logic;
      s_axi_wdata : in std_logic_vector(m_axi_xdata_width - 1 downto 0);
      s_axi_wstrb : in std_logic_vector(m_axi_xdata_width / 8 - 1 downto 0);
      s_axi_wlast : in std_logic;
      s_axi_wvalid : in std_logic;
      s_axi_wready : out std_logic;
      s_axi_bresp : out std_logic_vector(1 downto 0);
      s_axi_bvalid : out std_logic;
      s_axi_bready : in std_logic;
      s_axi_araddr : in std_logic_vector(bctl_axaddr_width - 1 downto 0);
      s_axi_arlen : in std_logic_vector(m_axi_axlen_width - 1 downto 0);
      s_axi_arsize : in std_logic_vector(2 downto 0);
      s_axi_arburst : in std_logic_vector(1 downto 0);
      s_axi_arlock : in std_logic_vector(0 downto 0);
      s_axi_arcache : in std_logic_vector(3 downto 0);
      s_axi_arprot : in std_logic_vector(2 downto 0);
      s_axi_arvalid : in std_logic;
      s_axi_arready : out std_logic;
      s_axi_rdata : out std_logic_vector(m_axi_xdata_width - 1 downto 0);
      s_axi_rresp : out std_logic_vector(1 downto 0);
      s_axi_rlast : out std_logic;
      s_axi_rvalid : out std_logic;
      s_axi_rready : in std_logic;
      bram_rst_a : out std_logic;
      bram_clk_a : out std_logic;
      bram_en_a : out std_logic;
      bram_we_a : out std_logic_vector(m_axi_xdata_width / 8 - 1 downto 0);
      bram_addr_a : out std_logic_vector(bctl_axaddr_width - 1 downto 0);
      bram_wrdata_a : out std_logic_vector(m_axi_xdata_width - 1 downto 0);
      bram_rddata_a : in std_logic_vector(m_axi_xdata_width - 1 downto 0)
    );
  end component;

  
  component blk_mem_gen_m
    port (
      clka : in std_logic;
      rsta : in std_logic;
      ena : in std_logic;
      wea : in std_logic_vector(m_axi_xdata_width / 8 - 1 downto 0);
      addra : in std_logic_vector(blk_mem_axaddr_width - 1 downto 0);
      dina : in std_logic_vector(m_axi_xdata_width - 1 downto 0);
      douta : out std_logic_vector(m_axi_xdata_width - 1 downto 0)
    );
  end component;


  signal model_inout_i : std_logic_vector(55 downto 0);
  signal model_inout_o : std_logic_vector(55 downto 0);
  signal model_inout_t : std_logic_vector(55 downto 0);
  signal sig_refclk : std_logic;
  signal sig_aresetn : std_logic;
  signal sig_aclk : std_logic;


  signal sig_ds_axi_awaddr : std_logic_vector(63 downto 0);
  signal sig_ds_axi_awlen : std_logic_vector(m_axi_axlen_width - 1 downto 0);
  signal sig_ds_axi_awsize : std_logic_vector(2 downto 0);
  signal sig_ds_axi_awburst : std_logic_vector(1 downto 0);
  signal sig_ds_axi_awcache : std_logic_vector(3 downto 0);
  signal sig_ds_axi_awprot : std_logic_vector(2 downto 0);
  signal sig_ds_axi_awvalid : std_logic;
  signal sig_ds_axi_wdata : std_logic_vector(adb3_xdata_width - 1 downto 0);
  signal sig_ds_axi_wstrb : std_logic_vector(adb3_xdata_width / 8 - 1 downto 0);
  signal sig_ds_axi_wlast : std_logic;
  signal sig_ds_axi_wvalid : std_logic;
  signal sig_ds_axi_bready : std_logic;
  signal sig_ds_axi_araddr : std_logic_vector(63 downto 0);
  signal sig_ds_axi_arlen : std_logic_vector(m_axi_axlen_width - 1 downto 0);
  signal sig_ds_axi_arsize : std_logic_vector(2 downto 0);
  signal sig_ds_axi_arburst : std_logic_vector(1 downto 0);
  signal sig_ds_axi_arcache : std_logic_vector(3 downto 0);
  signal sig_ds_axi_arprot : std_logic_vector(2 downto 0);
  signal sig_ds_axi_arvalid : std_logic;
  signal sig_ds_axi_rready : std_logic;
  signal sig_ds_axi_awready : std_logic;
  signal sig_ds_axi_wready : std_logic;
  signal sig_ds_axi_bresp : std_logic_vector(1 downto 0);
  signal sig_ds_axi_bvalid : std_logic;
  signal sig_ds_axi_arready : std_logic;
  signal sig_ds_axi_rdata : std_logic_vector(adb3_xdata_width - 1 downto 0);
  signal sig_ds_axi_rresp : std_logic_vector(1 downto 0);
  signal sig_ds_axi_rlast : std_logic;
  signal sig_ds_axi_rvalid : std_logic;
  signal sig_ds_axi_awlock : std_logic_vector(0 downto 0);
  signal sig_ds_axi_awqos : std_logic_vector(3 downto 0);
  signal sig_ds_axi_arlock : std_logic_vector(0 downto 0);
  signal sig_ds_axi_arqos : std_logic_vector(3 downto 0);
  signal sig_ds_axi_awregion : std_logic_vector(3 downto 0);
  signal sig_ds_axi_arregion : std_logic_vector(3 downto 0);

  signal sig_dma0_axi_araddr_adb3 : std_logic_vector(adb3_axaddr_width - 1 downto 0);
  signal sig_dma0_axi_araddr : std_logic_vector(m_axi_axaddr_width - 1 downto 0);
  signal sig_dma0_axi_arburst : std_logic_vector(1 downto 0);
  signal sig_dma0_axi_arcache : std_logic_vector(3 downto 0);
  signal sig_dma0_axi_arlen : std_logic_vector(m_axi_axlen_width - 1 downto 0);
  signal sig_dma0_axi_arlock : std_logic_vector(0 downto 0);
  signal sig_dma0_axi_arprot : std_logic_vector(2 downto 0);
  signal sig_dma0_axi_arqos : std_logic_vector(3 downto 0);
  signal sig_dma0_axi_arready : std_logic;
  signal sig_dma0_axi_arregion : std_logic_vector(3 downto 0);
  signal sig_dma0_axi_arsize : std_logic_vector(2 downto 0);
  signal sig_dma0_axi_arvalid : std_logic;
  signal sig_dma0_axi_awaddr_adb3 : std_logic_vector(adb3_axaddr_width - 1 downto 0);
  signal sig_dma0_axi_awaddr : std_logic_vector(m_axi_axaddr_width - 1 downto 0);
  signal sig_dma0_axi_awburst : std_logic_vector(1 downto 0);
  signal sig_dma0_axi_awcache : std_logic_vector(3 downto 0);
  signal sig_dma0_axi_awlen : std_logic_vector(m_axi_axlen_width - 1 downto 0);
  signal sig_dma0_axi_awlock : std_logic_vector(0 downto 0);
  signal sig_dma0_axi_awprot : std_logic_vector(2 downto 0);
  signal sig_dma0_axi_awqos  : std_logic_vector(3 downto 0);
  signal sig_dma0_axi_awready : std_logic;
  signal sig_dma0_axi_awregion : std_logic_vector(3 downto 0);
  signal sig_dma0_axi_awsize : std_logic_vector(2 downto 0);
  signal sig_dma0_axi_awvalid : std_logic;
  signal sig_dma0_axi_wdata : std_logic_vector(adb3_xdata_width - 1 downto 0);
  signal sig_dma0_axi_wlast : std_logic;
  signal sig_dma0_axi_wstrb : std_logic_vector(adb3_xdata_width / 8 - 1 downto 0);
  signal sig_dma0_axi_wready : std_logic;
  signal sig_dma0_axi_wvalid : std_logic;
  signal sig_dma0_axi_bready : std_logic;
  signal sig_dma0_axi_bresp : std_logic_vector(1 downto 0);
  signal sig_dma0_axi_bvalid : std_logic;
  signal sig_dma0_axi_rdata : std_logic_vector(adb3_xdata_width - 1 downto 0);
  signal sig_dma0_axi_rlast : std_logic;
  signal sig_dma0_axi_rready : std_logic;
  signal sig_dma0_axi_rresp : std_logic_vector(1 downto 0);
  signal sig_dma0_axi_rvalid : std_logic;

  signal sig_dma1_axi_araddr_adb3 : std_logic_vector(adb3_axaddr_width - 1 downto 0);
  signal sig_dma1_axi_araddr : std_logic_vector(pre_hls_addr_width - 1 downto 0);
  signal sig_dma1_axi_arburst : std_logic_vector(1 downto 0);
  signal sig_dma1_axi_arcache : std_logic_vector(3 downto 0);
  signal sig_dma1_axi_arlen : std_logic_vector(m_axi_axlen_width - 1 downto 0);
  signal sig_dma1_axi_arlock : std_logic_vector(0 downto 0);
  signal sig_dma1_axi_arprot : std_logic_vector(2 downto 0);
  signal sig_dma1_axi_arqos : std_logic_vector(3 downto 0);
  signal sig_dma1_axi_arready : std_logic;
  signal sig_dma1_axi_arregion : std_logic_vector(3 downto 0);
  signal sig_dma1_axi_arsize : std_logic_vector(2 downto 0);
  signal sig_dma1_axi_arvalid : std_logic;
  signal sig_dma1_axi_awaddr_adb3 : std_logic_vector(adb3_axaddr_width - 1 downto 0);
  signal sig_dma1_axi_awaddr : std_logic_vector(pre_hls_addr_width - 1 downto 0);
  signal sig_dma1_axi_awburst : std_logic_vector(1 downto 0);
  signal sig_dma1_axi_awcache : std_logic_vector(3 downto 0);
  signal sig_dma1_axi_awlen : std_logic_vector(m_axi_axlen_width - 1 downto 0);
  signal sig_dma1_axi_awlock : std_logic_vector(0 downto 0);
  signal sig_dma1_axi_awprot : std_logic_vector(2 downto 0);
  signal sig_dma1_axi_awqos  : std_logic_vector(3 downto 0);
  signal sig_dma1_axi_awready : std_logic;
  signal sig_dma1_axi_awregion : std_logic_vector(3 downto 0);
  signal sig_dma1_axi_awsize : std_logic_vector(2 downto 0);
  signal sig_dma1_axi_awvalid : std_logic;
  signal sig_dma1_axi_wdata : std_logic_vector(adb3_xdata_width - 1 downto 0);
  signal sig_dma1_axi_wlast : std_logic;
  signal sig_dma1_axi_wstrb : std_logic_vector(adb3_xdata_width / 8 - 1 downto 0);
  signal sig_dma1_axi_wready : std_logic;
  signal sig_dma1_axi_wvalid : std_logic;
  signal sig_dma1_axi_bready : std_logic;
  signal sig_dma1_axi_bresp : std_logic_vector(1 downto 0);
  signal sig_dma1_axi_bvalid : std_logic;
  signal sig_dma1_axi_rdata : std_logic_vector(adb3_xdata_width - 1 downto 0);
  signal sig_dma1_axi_rlast : std_logic;
  signal sig_dma1_axi_rready : std_logic;
  signal sig_dma1_axi_rresp : std_logic_vector(1 downto 0);
  signal sig_dma1_axi_rvalid : std_logic;


  signal sig_dw_dma0_m_axi_awaddr : std_logic_vector(m_axi_axaddr_width - 1 downto 0);
  signal sig_dw_dma0_m_axi_awlen : std_logic_vector(m_axi_axlen_width - 1 downto 0);
  signal sig_dw_dma0_m_axi_awsize : std_logic_vector(2 downto 0);
  signal sig_dw_dma0_m_axi_awburst : std_logic_vector(1 downto 0);
  signal sig_dw_dma0_m_axi_awlock : std_logic_vector(0 downto 0);
  signal sig_dw_dma0_m_axi_awcache : std_logic_vector(3 downto 0);
  signal sig_dw_dma0_m_axi_awprot : std_logic_vector(2 downto 0);
  signal sig_dw_dma0_m_axi_awregion : std_logic_vector(3 downto 0);
  signal sig_dw_dma0_m_axi_awqos : std_logic_vector(3 downto 0);
  signal sig_dw_dma0_m_axi_awvalid : std_logic;
  signal sig_dw_dma0_m_axi_awready : std_logic;
  signal sig_dw_dma0_m_axi_wdata : std_logic_vector(m_axi_xdata_width - 1 downto 0);
  signal sig_dw_dma0_m_axi_wstrb : std_logic_vector(m_axi_xdata_width / 8 - 1 downto 0);
  signal sig_dw_dma0_m_axi_wlast : std_logic;
  signal sig_dw_dma0_m_axi_wvalid : std_logic;
  signal sig_dw_dma0_m_axi_wready : std_logic;
  signal sig_dw_dma0_m_axi_bresp : std_logic_vector(1 downto 0);
  signal sig_dw_dma0_m_axi_bvalid : std_logic;
  signal sig_dw_dma0_m_axi_bready : std_logic;
  signal sig_dw_dma0_m_axi_araddr : std_logic_vector(m_axi_axaddr_width - 1 downto 0);
  signal sig_dw_dma0_m_axi_arlen : std_logic_vector(m_axi_axlen_width - 1 downto 0);
  signal sig_dw_dma0_m_axi_arsize : std_logic_vector(2 downto 0);
  signal sig_dw_dma0_m_axi_arburst : std_logic_vector(1 downto 0);
  signal sig_dw_dma0_m_axi_arlock : std_logic_vector(0 downto 0);
  signal sig_dw_dma0_m_axi_arcache : std_logic_vector(3 downto 0);
  signal sig_dw_dma0_m_axi_arprot : std_logic_vector(2 downto 0);
  signal sig_dw_dma0_m_axi_arregion : std_logic_vector(3 downto 0);
  signal sig_dw_dma0_m_axi_arqos : std_logic_vector(3 downto 0);
  signal sig_dw_dma0_m_axi_arvalid : std_logic;
  signal sig_dw_dma0_m_axi_arready : std_logic;
  signal sig_dw_dma0_m_axi_rdata : std_logic_vector(m_axi_xdata_width - 1 downto 0);
  signal sig_dw_dma0_m_axi_rresp : std_logic_vector(1 downto 0);
  signal sig_dw_dma0_m_axi_rlast : std_logic;
  signal sig_dw_dma0_m_axi_rvalid : std_logic;
  signal sig_dw_dma0_m_axi_rready : std_logic;


  signal sig_dw_pre_hls_m_axi_awaddr : std_logic_vector(pre_hls_addr_width - 1 downto 0);
  signal sig_dw_pre_hls_m_axi_awlen : std_logic_vector(m_axi_axlen_width - 1 downto 0);
  signal sig_dw_pre_hls_m_axi_awsize : std_logic_vector(2 downto 0);
  signal sig_dw_pre_hls_m_axi_awburst : std_logic_vector(1 downto 0);
  signal sig_dw_pre_hls_m_axi_awlock : std_logic_vector(0 downto 0);
  signal sig_dw_pre_hls_m_axi_awcache : std_logic_vector(3 downto 0);
  signal sig_dw_pre_hls_m_axi_awprot : std_logic_vector(2 downto 0);
  signal sig_dw_pre_hls_m_axi_awregion : std_logic_vector(3 downto 0);
  signal sig_dw_pre_hls_m_axi_awqos : std_logic_vector(3 downto 0);
  signal sig_dw_pre_hls_m_axi_awvalid : std_logic;
  signal sig_dw_pre_hls_m_axi_awready : std_logic;
  signal sig_dw_pre_hls_m_axi_wdata : std_logic_vector(hls_axilite_data_width - 1 downto 0);
  signal sig_dw_pre_hls_m_axi_wstrb : std_logic_vector(hls_axilite_data_width / 8 - 1 downto 0);
  signal sig_dw_pre_hls_m_axi_wlast : std_logic;
  signal sig_dw_pre_hls_m_axi_wvalid : std_logic;
  signal sig_dw_pre_hls_m_axi_wready : std_logic;
  signal sig_dw_pre_hls_m_axi_bresp : std_logic_vector(1 downto 0);
  signal sig_dw_pre_hls_m_axi_bvalid : std_logic;
  signal sig_dw_pre_hls_m_axi_bready : std_logic;
  signal sig_dw_pre_hls_m_axi_araddr : std_logic_vector(pre_hls_addr_width - 1 downto 0);
  signal sig_dw_pre_hls_m_axi_arlen : std_logic_vector(m_axi_axlen_width - 1 downto 0);
  signal sig_dw_pre_hls_m_axi_arsize : std_logic_vector(2 downto 0);
  signal sig_dw_pre_hls_m_axi_arburst : std_logic_vector(1 downto 0);
  signal sig_dw_pre_hls_m_axi_arlock : std_logic_vector(0 downto 0);
  signal sig_dw_pre_hls_m_axi_arcache : std_logic_vector(3 downto 0);
  signal sig_dw_pre_hls_m_axi_arprot : std_logic_vector(2 downto 0);
  signal sig_dw_pre_hls_m_axi_arregion : std_logic_vector(3 downto 0);
  signal sig_dw_pre_hls_m_axi_arqos : std_logic_vector(3 downto 0);
  signal sig_dw_pre_hls_m_axi_arvalid : std_logic;
  signal sig_dw_pre_hls_m_axi_arready : std_logic;
  signal sig_dw_pre_hls_m_axi_rdata : std_logic_vector(hls_axilite_data_width - 1 downto 0);
  signal sig_dw_pre_hls_m_axi_rresp : std_logic_vector(1 downto 0);
  signal sig_dw_pre_hls_m_axi_rlast : std_logic;
  signal sig_dw_pre_hls_m_axi_rvalid : std_logic;
  signal sig_dw_pre_hls_m_axi_rready : std_logic;


  signal sig_pr_hls_m_axi_awaddr_pr : std_logic_vector(pre_hls_addr_width - 1 downto 0);
  signal sig_pr_hls_m_axi_awaddr : std_logic_vector(hls_axilite_addr_width - 1 downto 0);
  signal sig_pr_hls_m_axi_awprot : std_logic_vector(2 downto 0);
  signal sig_pr_hls_m_axi_awvalid : std_logic;
  signal sig_pr_hls_m_axi_awready : std_logic;
  signal sig_pr_hls_m_axi_wdata : std_logic_vector(hls_axilite_data_width - 1 downto 0);
  signal sig_pr_hls_m_axi_wstrb : std_logic_vector(hls_axilite_data_width / 8 - 1 downto 0);
  signal sig_pr_hls_m_axi_wvalid : std_logic;
  signal sig_pr_hls_m_axi_wready : std_logic;
  signal sig_pr_hls_m_axi_bresp : std_logic_vector(1 downto 0);
  signal sig_pr_hls_m_axi_bvalid : std_logic;
  signal sig_pr_hls_m_axi_bready : std_logic;
  signal sig_pr_hls_m_axi_araddr_pr : std_logic_vector(pre_hls_addr_width - 1 downto 0);
  signal sig_pr_hls_m_axi_araddr : std_logic_vector(hls_axilite_addr_width - 1 downto 0);
  signal sig_pr_hls_m_axi_arprot : std_logic_vector(2 downto 0);
  signal sig_pr_hls_m_axi_arvalid : std_logic;
  signal sig_pr_hls_m_axi_arready : std_logic;
  signal sig_pr_hls_m_axi_rdata : std_logic_vector(hls_axilite_data_width - 1 downto 0);
  signal sig_pr_hls_m_axi_rresp : std_logic_vector(1 downto 0);
  signal sig_pr_hls_m_axi_rvalid : std_logic;
  signal sig_pr_hls_m_axi_rready : std_logic;


  signal sig_hls_m_axi_gmem_awaddr_hls : std_logic_vector(hls_axiaddr_width - 1 downto 0);
  signal sig_hls_m_axi_gmem_awaddr : std_logic_vector(m_axi_axaddr_width - 1 downto 0);
  signal sig_hls_m_axi_gmem_awlen : std_logic_vector(m_axi_axlen_width - 1 downto 0);
  signal sig_hls_m_axi_gmem_awsize : std_logic_vector(2 downto 0);
  signal sig_hls_m_axi_gmem_awburst : std_logic_vector(1 downto 0);
  signal sig_hls_m_axi_gmem_awlock : std_logic_vector(1 downto 0);
  signal sig_hls_m_axi_gmem_awregion : std_logic_vector(3 downto 0);
  signal sig_hls_m_axi_gmem_awcache : std_logic_vector(3 downto 0);
  signal sig_hls_m_axi_gmem_awprot : std_logic_vector(2 downto 0);
  signal sig_hls_m_axi_gmem_awqos : std_logic_vector(3 downto 0);
  signal sig_hls_m_axi_gmem_awvalid : std_logic;
  signal sig_hls_m_axi_gmem_awready : std_logic;
  signal sig_hls_m_axi_gmem_wdata : std_logic_vector(hls_xdata_width - 1 downto 0);
  signal sig_hls_m_axi_gmem_wstrb : std_logic_vector(hls_xdata_width / 8 - 1 downto 0);
  signal sig_hls_m_axi_gmem_wlast : std_logic;
  signal sig_hls_m_axi_gmem_wvalid : std_logic;
  signal sig_hls_m_axi_gmem_wready : std_logic;
  signal sig_hls_m_axi_gmem_bresp : std_logic_vector(1 downto 0);
  signal sig_hls_m_axi_gmem_bvalid : std_logic;
  signal sig_hls_m_axi_gmem_bready : std_logic;
  signal sig_hls_m_axi_gmem_araddr_hls : std_logic_vector(hls_axiaddr_width - 1 downto 0);
  signal sig_hls_m_axi_gmem_araddr : std_logic_vector(m_axi_axaddr_width - 1 downto 0);
  signal sig_hls_m_axi_gmem_arlen : std_logic_vector(m_axi_axlen_width - 1 downto 0);
  signal sig_hls_m_axi_gmem_arsize : std_logic_vector(2 downto 0);
  signal sig_hls_m_axi_gmem_arburst : std_logic_vector(1 downto 0);
  signal sig_hls_m_axi_gmem_arlock : std_logic_vector(1 downto 0);
  signal sig_hls_m_axi_gmem_arregion : std_logic_vector(3 downto 0);
  signal sig_hls_m_axi_gmem_arcache : std_logic_vector(3 downto 0);
  signal sig_hls_m_axi_gmem_arprot : std_logic_vector(2 downto 0);
  signal sig_hls_m_axi_gmem_arqos : std_logic_vector(3 downto 0);
  signal sig_hls_m_axi_gmem_arvalid : std_logic;
  signal sig_hls_m_axi_gmem_arready : std_logic;
  signal sig_hls_m_axi_gmem_rdata : std_logic_vector(hls_xdata_width - 1 downto 0);
  signal sig_hls_m_axi_gmem_rresp : std_logic_vector(1 downto 0);
  signal sig_hls_m_axi_gmem_rlast : std_logic;
  signal sig_hls_m_axi_gmem_rvalid : std_logic;
  signal sig_hls_m_axi_gmem_rready : std_logic;


  signal sig_dw_post_hls_m_axi_awaddr : std_logic_vector(m_axi_axaddr_width - 1 downto 0);
  signal sig_dw_post_hls_m_axi_awlen : std_logic_vector(m_axi_axlen_width - 1 downto 0);
  signal sig_dw_post_hls_m_axi_awsize : std_logic_vector(2 downto 0);
  signal sig_dw_post_hls_m_axi_awburst : std_logic_vector(1 downto 0);
  signal sig_dw_post_hls_m_axi_awlock : std_logic_vector(0 downto 0);
  signal sig_dw_post_hls_m_axi_awcache : std_logic_vector(3 downto 0);
  signal sig_dw_post_hls_m_axi_awprot : std_logic_vector(2 downto 0);
  signal sig_dw_post_hls_m_axi_awregion : std_logic_vector(3 downto 0);
  signal sig_dw_post_hls_m_axi_awqos : std_logic_vector(3 downto 0);
  signal sig_dw_post_hls_m_axi_awvalid : std_logic;
  signal sig_dw_post_hls_m_axi_awready : std_logic;
  signal sig_dw_post_hls_m_axi_wdata : std_logic_vector(m_axi_xdata_width - 1 downto 0);
  signal sig_dw_post_hls_m_axi_wstrb : std_logic_vector(m_axi_xdata_width / 8 - 1 downto 0);
  signal sig_dw_post_hls_m_axi_wlast : std_logic;
  signal sig_dw_post_hls_m_axi_wvalid : std_logic;
  signal sig_dw_post_hls_m_axi_wready : std_logic;
  signal sig_dw_post_hls_m_axi_bresp : std_logic_vector(1 downto 0);
  signal sig_dw_post_hls_m_axi_bvalid : std_logic;
  signal sig_dw_post_hls_m_axi_bready : std_logic;
  signal sig_dw_post_hls_m_axi_araddr : std_logic_vector(m_axi_axaddr_width - 1 downto 0);
  signal sig_dw_post_hls_m_axi_arlen : std_logic_vector(m_axi_axlen_width - 1 downto 0);
  signal sig_dw_post_hls_m_axi_arsize : std_logic_vector(2 downto 0);
  signal sig_dw_post_hls_m_axi_arburst : std_logic_vector(1 downto 0);
  signal sig_dw_post_hls_m_axi_arlock : std_logic_vector(0 downto 0);
  signal sig_dw_post_hls_m_axi_arcache : std_logic_vector(3 downto 0);
  signal sig_dw_post_hls_m_axi_arprot : std_logic_vector(2 downto 0);
  signal sig_dw_post_hls_m_axi_arregion : std_logic_vector(3 downto 0);
  signal sig_dw_post_hls_m_axi_arqos : std_logic_vector(3 downto 0);
  signal sig_dw_post_hls_m_axi_arvalid : std_logic;
  signal sig_dw_post_hls_m_axi_arready : std_logic;
  signal sig_dw_post_hls_m_axi_rdata : std_logic_vector(m_axi_xdata_width - 1 downto 0);
  signal sig_dw_post_hls_m_axi_rresp : std_logic_vector(1 downto 0);
  signal sig_dw_post_hls_m_axi_rlast : std_logic;
  signal sig_dw_post_hls_m_axi_rvalid : std_logic;
  signal sig_dw_post_hls_m_axi_rready : std_logic;


  signal sig_xbar_c0_m_axi_awid : std_logic_vector(0 downto 0);
  signal sig_xbar_c0_m_axi_awaddr_xbar : std_logic_vector(m_axi_axaddr_width - 1 downto 0);
  signal sig_xbar_c0_m_axi_awaddr : std_logic_vector(bctl_axaddr_width - 1 downto 0);
  signal sig_xbar_c0_m_axi_awlen : std_logic_vector(m_axi_axlen_width - 1 downto 0);
  signal sig_xbar_c0_m_axi_awsize : std_logic_vector(2 downto 0);
  signal sig_xbar_c0_m_axi_awburst : std_logic_vector(1 downto 0);
  signal sig_xbar_c0_m_axi_awlock : std_logic_vector(0 downto 0);
  signal sig_xbar_c0_m_axi_awcache : std_logic_vector(3 downto 0);
  signal sig_xbar_c0_m_axi_awprot : std_logic_vector(2 downto 0);
  signal sig_xbar_c0_m_axi_awregion : std_logic_vector(3 downto 0);
  signal sig_xbar_c0_m_axi_awqos : std_logic_vector(3 downto 0);
  signal sig_xbar_c0_m_axi_awvalid : std_logic;
  signal sig_xbar_c0_m_axi_awready : std_logic;
  signal sig_xbar_c0_m_axi_wdata : std_logic_vector(m_axi_xdata_width - 1 downto 0);
  signal sig_xbar_c0_m_axi_wstrb : std_logic_vector(m_axi_xdata_width / 8 - 1 downto 0);
  signal sig_xbar_c0_m_axi_wlast : std_logic;
  signal sig_xbar_c0_m_axi_wvalid : std_logic;
  signal sig_xbar_c0_m_axi_wready : std_logic;
  signal sig_xbar_c0_m_axi_bid : std_logic_vector(0 downto 0);
  signal sig_xbar_c0_m_axi_bresp : std_logic_vector(1 downto 0);
  signal sig_xbar_c0_m_axi_bvalid : std_logic;
  signal sig_xbar_c0_m_axi_bready : std_logic;
  signal sig_xbar_c0_m_axi_arid : std_logic_vector(0 downto 0);
  signal sig_xbar_c0_m_axi_araddr_xbar : std_logic_vector(m_axi_axaddr_width - 1 downto 0);
  signal sig_xbar_c0_m_axi_araddr : std_logic_vector(bctl_axaddr_width - 1 downto 0);
  signal sig_xbar_c0_m_axi_arlen : std_logic_vector(m_axi_axlen_width - 1 downto 0);
  signal sig_xbar_c0_m_axi_arsize : std_logic_vector(2 downto 0);
  signal sig_xbar_c0_m_axi_arburst : std_logic_vector(1 downto 0);
  signal sig_xbar_c0_m_axi_arlock : std_logic_vector(0 downto 0);
  signal sig_xbar_c0_m_axi_arcache : std_logic_vector(3 downto 0);
  signal sig_xbar_c0_m_axi_arprot : std_logic_vector(2 downto 0);
  signal sig_xbar_c0_m_axi_arregion : std_logic_vector(3 downto 0);
  signal sig_xbar_c0_m_axi_arqos : std_logic_vector(3 downto 0);
  signal sig_xbar_c0_m_axi_arvalid : std_logic;
  signal sig_xbar_c0_m_axi_arready : std_logic;
  signal sig_xbar_c0_m_axi_rid : std_logic_vector(0 downto 0);
  signal sig_xbar_c0_m_axi_rdata : std_logic_vector(m_axi_xdata_width - 1 downto 0);
  signal sig_xbar_c0_m_axi_rresp : std_logic_vector(1 downto 0);
  signal sig_xbar_c0_m_axi_rlast : std_logic;
  signal sig_xbar_c0_m_axi_rvalid : std_logic;
  signal sig_xbar_c0_m_axi_rready : std_logic;


  signal sig_c0_bram_rst_a : std_logic;
  signal sig_c0_bram_clk_a : std_logic;
  signal sig_c0_bram_en_a : std_logic;
  signal sig_c0_bram_we_a : std_logic_vector(m_axi_xdata_width / 8 - 1 downto 0);
  signal sig_c0_bram_addr_a_bctl : std_logic_vector(bctl_axaddr_width - 1 downto 0);
  signal sig_c0_bram_addr_a : std_logic_vector(blk_mem_axaddr_width - 1 downto 0);
  signal sig_c0_bram_wrdata_a : std_logic_vector(m_axi_xdata_width - 1 downto 0);
  signal sig_c0_bram_rddata_a : std_logic_vector(m_axi_xdata_width - 1 downto 0);


  signal logic0, logic1 : std_logic;

begin

  logic0 <= '0';
  logic1 <= '1';


  -- Instantiate Board Control & Host Interface
  adb3_admpcie7v3_inst : adb3_admpcie7v3_m
    port map(
      perst_n => perst_n,
      pcie100_p => pcie100_p,
      pcie100_n => pcie100_n,
      refclk200_p => refclk200_p,
      refclk200_n => refclk200_n,
      refclk => open,
      aclk => sig_aclk,
      aresetn => sig_aresetn,
      pci_exp_txn => pci_exp_txn,
      pci_exp_txp => pci_exp_txp,
      pci_exp_rxn => pci_exp_rxn,
      pci_exp_rxp => pci_exp_rxp,
      model_inout_i => model_inout_i,
      model_inout_o => model_inout_o,
      model_inout_t => model_inout_t,
      ds_axi_araddr => open,
      ds_axi_arburst => open,
      ds_axi_arcache => open,
      ds_axi_arlen => open,
      ds_axi_arlock => open,
      ds_axi_arprot => open,
      ds_axi_arqos => open,
      ds_axi_arready => logic0,
      ds_axi_arregion => open,
      ds_axi_arsize => open,
      ds_axi_arvalid => open,
      ds_axi_awaddr => open,
      ds_axi_awburst => open,
      ds_axi_awcache => open,
      ds_axi_awlen => open,
      ds_axi_awlock => open,
      ds_axi_awprot => open,
      ds_axi_awqos => open,
      ds_axi_awready => logic0,
      ds_axi_awregion => open,
      ds_axi_awsize => open,
      ds_axi_awvalid => open,
      ds_axi_bready => open,
      ds_axi_bresp => B"00",
      ds_axi_bvalid => logic0,
      ds_axi_rdata => B"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      ds_axi_rlast => logic0,
      ds_axi_rready => open,
      ds_axi_rresp => B"00",
      ds_axi_rvalid => logic0,
      ds_axi_wdata => open,
      ds_axi_wlast => open,
      ds_axi_wready => logic0,
      ds_axi_wstrb => open,
      ds_axi_wvalid => open,

      dma0_axi_araddr => sig_dma0_axi_araddr_adb3,
      dma0_axi_arburst => sig_dma0_axi_arburst,
      dma0_axi_arcache => sig_dma0_axi_arcache,
      dma0_axi_arlen => sig_dma0_axi_arlen,
      dma0_axi_arlock => sig_dma0_axi_arlock,
      dma0_axi_arprot => sig_dma0_axi_arprot,
      dma0_axi_arqos => sig_dma0_axi_arqos,
      dma0_axi_arready => sig_dma0_axi_arready,
      dma0_axi_arregion => sig_dma0_axi_arregion,
      dma0_axi_arsize => sig_dma0_axi_arsize,
      dma0_axi_arvalid => sig_dma0_axi_arvalid,
      dma0_axi_awaddr => sig_dma0_axi_awaddr_adb3,
      dma0_axi_awburst => sig_dma0_axi_awburst,
      dma0_axi_awcache => sig_dma0_axi_awcache,
      dma0_axi_awlen => sig_dma0_axi_awlen,
      dma0_axi_awlock => sig_dma0_axi_awlock,
      dma0_axi_awprot => sig_dma0_axi_awprot,
      dma0_axi_awqos => sig_dma0_axi_awqos,
      dma0_axi_awready => sig_dma0_axi_awready,
      dma0_axi_awregion => sig_dma0_axi_awregion,
      dma0_axi_awsize => sig_dma0_axi_awsize,
      dma0_axi_awvalid => sig_dma0_axi_awvalid,
      dma0_axi_bready => sig_dma0_axi_bready,
      dma0_axi_bresp => sig_dma0_axi_bresp,
      dma0_axi_bvalid => sig_dma0_axi_bvalid,
      dma0_axi_rdata => sig_dma0_axi_rdata,
      dma0_axi_rlast => sig_dma0_axi_rlast,
      dma0_axi_rready => sig_dma0_axi_rready,
      dma0_axi_rresp => sig_dma0_axi_rresp,
      dma0_axi_rvalid => sig_dma0_axi_rvalid,
      dma0_axi_wdata => sig_dma0_axi_wdata,
      dma0_axi_wlast => sig_dma0_axi_wlast,
      dma0_axi_wready => sig_dma0_axi_wready,
      dma0_axi_wstrb => sig_dma0_axi_wstrb,
      dma0_axi_wvalid => sig_dma0_axi_wvalid,

      dma1_axi_araddr => sig_dma1_axi_araddr_adb3,
      dma1_axi_arburst => sig_dma1_axi_arburst,
      dma1_axi_arcache => sig_dma1_axi_arcache,
      dma1_axi_arlen => sig_dma1_axi_arlen,
      dma1_axi_arlock => sig_dma1_axi_arlock,
      dma1_axi_arprot => sig_dma1_axi_arprot,
      dma1_axi_arqos => sig_dma1_axi_arqos,
      dma1_axi_arready => sig_dma1_axi_arready,
      dma1_axi_arregion => sig_dma1_axi_arregion,
      dma1_axi_arsize => sig_dma1_axi_arsize,
      dma1_axi_arvalid => sig_dma1_axi_arvalid,
      dma1_axi_awaddr => sig_dma1_axi_awaddr_adb3,
      dma1_axi_awburst => sig_dma1_axi_awburst,
      dma1_axi_awcache => sig_dma1_axi_awcache,
      dma1_axi_awlen => sig_dma1_axi_awlen,
      dma1_axi_awlock => sig_dma1_axi_awlock,
      dma1_axi_awprot => sig_dma1_axi_awprot,
      dma1_axi_awqos => sig_dma1_axi_awqos,
      dma1_axi_awready => sig_dma1_axi_awready,
      dma1_axi_awregion => sig_dma1_axi_awregion,
      dma1_axi_awsize => sig_dma1_axi_awsize,
      dma1_axi_awvalid => sig_dma1_axi_awvalid,
      dma1_axi_bready => sig_dma1_axi_bready,
      dma1_axi_bresp => sig_dma1_axi_bresp,
      dma1_axi_bvalid => sig_dma1_axi_bvalid,
      dma1_axi_rdata => sig_dma1_axi_rdata,
      dma1_axi_rlast => sig_dma1_axi_rlast,
      dma1_axi_rready => sig_dma1_axi_rready,
      dma1_axi_rresp => sig_dma1_axi_rresp,
      dma1_axi_rvalid => sig_dma1_axi_rvalid,
      dma1_axi_wdata => sig_dma1_axi_wdata,
      dma1_axi_wlast => sig_dma1_axi_wlast,
      dma1_axi_wready => sig_dma1_axi_wready,
      dma1_axi_wstrb => sig_dma1_axi_wstrb,
      dma1_axi_wvalid => sig_dma1_axi_wvalid,

      core_status => open
    );

  gen_model_inout : for i in model_inout'range generate
    model_inout(i) <= model_inout_o(i) when model_inout_t(i) = '0' else 'Z';
    model_inout_i(i) <= model_inout(i);
  end generate;

  sig_dma0_axi_awaddr <= std_logic_vector(resize(unsigned(sig_dma0_axi_awaddr_adb3), m_axi_axaddr_width));
  sig_dma0_axi_araddr <= std_logic_vector(resize(unsigned(sig_dma0_axi_araddr_adb3), m_axi_axaddr_width));
  sig_dma1_axi_awaddr <= std_logic_vector(resize(unsigned(sig_dma1_axi_awaddr_adb3), pre_hls_addr_width));
  sig_dma1_axi_araddr <= std_logic_vector(resize(unsigned(sig_dma1_axi_araddr_adb3), pre_hls_addr_width));


  axi_dwidth_converter_dma0_inst : axi_dwidth_converter_dma_m
    port map (
      s_axi_aclk => sig_aclk,
      s_axi_aresetn => sig_aresetn,

      s_axi_awaddr => sig_dma0_axi_awaddr,
      s_axi_awlen => sig_dma0_axi_awlen,
      s_axi_awsize => sig_dma0_axi_awsize,
      s_axi_awburst => sig_dma0_axi_awburst,
      s_axi_awlock => sig_dma0_axi_awlock,
      s_axi_awcache => sig_dma0_axi_awcache,
      s_axi_awprot => sig_dma0_axi_awprot,
      s_axi_awregion => sig_dma0_axi_awregion,
      s_axi_awqos => sig_dma0_axi_awqos,
      s_axi_awvalid => sig_dma0_axi_awvalid,
      s_axi_awready => sig_dma0_axi_awready,
      s_axi_wdata => sig_dma0_axi_wdata,
      s_axi_wstrb => sig_dma0_axi_wstrb,
      s_axi_wlast => sig_dma0_axi_wlast,
      s_axi_wvalid => sig_dma0_axi_wvalid,
      s_axi_wready => sig_dma0_axi_wready,
      s_axi_bresp => sig_dma0_axi_bresp,
      s_axi_bvalid => sig_dma0_axi_bvalid,
      s_axi_bready => sig_dma0_axi_bready,
      s_axi_araddr => sig_dma0_axi_araddr,
      s_axi_arlen => sig_dma0_axi_arlen,
      s_axi_arsize => sig_dma0_axi_arsize,
      s_axi_arburst => sig_dma0_axi_arburst,
      s_axi_arlock => sig_dma0_axi_arlock,
      s_axi_arcache => sig_dma0_axi_arcache,
      s_axi_arprot => sig_dma0_axi_arprot,
      s_axi_arregion => sig_dma0_axi_arregion,
      s_axi_arqos => sig_dma0_axi_arqos,
      s_axi_arvalid => sig_dma0_axi_arvalid,
      s_axi_arready => sig_dma0_axi_arready,
      s_axi_rdata => sig_dma0_axi_rdata,
      s_axi_rresp => sig_dma0_axi_rresp,
      s_axi_rlast => sig_dma0_axi_rlast,
      s_axi_rvalid => sig_dma0_axi_rvalid,
      s_axi_rready => sig_dma0_axi_rready,

      m_axi_awaddr => sig_dw_dma0_m_axi_awaddr,
      m_axi_awlen => sig_dw_dma0_m_axi_awlen,
      m_axi_awsize => sig_dw_dma0_m_axi_awsize,
      m_axi_awburst => sig_dw_dma0_m_axi_awburst,
      m_axi_awlock => sig_dw_dma0_m_axi_awlock,
      m_axi_awcache => sig_dw_dma0_m_axi_awcache,
      m_axi_awprot => sig_dw_dma0_m_axi_awprot,
      m_axi_awregion => sig_dw_dma0_m_axi_awregion,
      m_axi_awqos => sig_dw_dma0_m_axi_awqos,
      m_axi_awvalid => sig_dw_dma0_m_axi_awvalid,
      m_axi_awready => sig_dw_dma0_m_axi_awready,
      m_axi_wdata => sig_dw_dma0_m_axi_wdata,
      m_axi_wstrb => sig_dw_dma0_m_axi_wstrb,
      m_axi_wlast => sig_dw_dma0_m_axi_wlast,
      m_axi_wvalid => sig_dw_dma0_m_axi_wvalid,
      m_axi_wready => sig_dw_dma0_m_axi_wready,
      m_axi_bresp => sig_dw_dma0_m_axi_bresp,
      m_axi_bvalid => sig_dw_dma0_m_axi_bvalid,
      m_axi_bready => sig_dw_dma0_m_axi_bready,
      m_axi_araddr => sig_dw_dma0_m_axi_araddr,
      m_axi_arlen => sig_dw_dma0_m_axi_arlen,
      m_axi_arsize => sig_dw_dma0_m_axi_arsize,
      m_axi_arburst => sig_dw_dma0_m_axi_arburst,
      m_axi_arlock => sig_dw_dma0_m_axi_arlock,
      m_axi_arcache => sig_dw_dma0_m_axi_arcache,
      m_axi_arprot => sig_dw_dma0_m_axi_arprot,
      m_axi_arregion => sig_dw_dma0_m_axi_arregion,
      m_axi_arqos => sig_dw_dma0_m_axi_arqos,
      m_axi_arvalid => sig_dw_dma0_m_axi_arvalid,
      m_axi_arready => sig_dw_dma0_m_axi_arready,
      m_axi_rdata => sig_dw_dma0_m_axi_rdata,
      m_axi_rresp => sig_dw_dma0_m_axi_rresp,
      m_axi_rlast => sig_dw_dma0_m_axi_rlast,
      m_axi_rvalid => sig_dw_dma0_m_axi_rvalid,
      m_axi_rready => sig_dw_dma0_m_axi_rready
    );


  axi_dwidth_converter_pre_hls_inst : axi_dwidth_converter_pre_hls_m
    port map (
      s_axi_aclk => sig_aclk,
      s_axi_aresetn => sig_aresetn,
  
      s_axi_awaddr => sig_dma1_axi_awaddr,
      s_axi_awlen => sig_dma1_axi_awlen,
      s_axi_awsize => sig_dma1_axi_awsize,
      s_axi_awburst => sig_dma1_axi_awburst,
      s_axi_awlock => sig_dma1_axi_awlock,
      s_axi_awcache => sig_dma1_axi_awcache,
      s_axi_awprot => sig_dma1_axi_awprot,
      s_axi_awregion => sig_dma1_axi_awregion,
      s_axi_awqos => sig_dma1_axi_awqos,
      s_axi_awvalid => sig_dma1_axi_awvalid,
      s_axi_awready => sig_dma1_axi_awready,
      s_axi_wdata => sig_dma1_axi_wdata,
      s_axi_wstrb => sig_dma1_axi_wstrb,
      s_axi_wlast => sig_dma1_axi_wlast,
      s_axi_wvalid => sig_dma1_axi_wvalid,
      s_axi_wready => sig_dma1_axi_wready,
      s_axi_bresp => sig_dma1_axi_bresp,
      s_axi_bvalid => sig_dma1_axi_bvalid,
      s_axi_bready => sig_dma1_axi_bready,
      s_axi_araddr => sig_dma1_axi_araddr,
      s_axi_arlen => sig_dma1_axi_arlen,
      s_axi_arsize => sig_dma1_axi_arsize,
      s_axi_arburst => sig_dma1_axi_arburst,
      s_axi_arlock => sig_dma1_axi_arlock,
      s_axi_arcache => sig_dma1_axi_arcache,
      s_axi_arprot => sig_dma1_axi_arprot,
      s_axi_arregion => sig_dma1_axi_arregion,
      s_axi_arqos => sig_dma1_axi_arqos,
      s_axi_arvalid => sig_dma1_axi_arvalid,
      s_axi_arready => sig_dma1_axi_arready,
      s_axi_rdata => sig_dma1_axi_rdata,
      s_axi_rresp => sig_dma1_axi_rresp,
      s_axi_rlast => sig_dma1_axi_rlast,
      s_axi_rvalid => sig_dma1_axi_rvalid,
      s_axi_rready => sig_dma1_axi_rready,
  
      m_axi_awaddr => sig_dw_pre_hls_m_axi_awaddr,
      m_axi_awlen => sig_dw_pre_hls_m_axi_awlen,
      m_axi_awsize => sig_dw_pre_hls_m_axi_awsize,
      m_axi_awburst => sig_dw_pre_hls_m_axi_awburst,
      m_axi_awlock => sig_dw_pre_hls_m_axi_awlock,
      m_axi_awcache => sig_dw_pre_hls_m_axi_awcache,
      m_axi_awprot => sig_dw_pre_hls_m_axi_awprot,
      m_axi_awregion => sig_dw_pre_hls_m_axi_awregion,
      m_axi_awqos => sig_dw_pre_hls_m_axi_awqos,
      m_axi_awvalid => sig_dw_pre_hls_m_axi_awvalid,
      m_axi_awready => sig_dw_pre_hls_m_axi_awready,
      m_axi_wdata => sig_dw_pre_hls_m_axi_wdata,
      m_axi_wstrb => sig_dw_pre_hls_m_axi_wstrb,
      m_axi_wlast => sig_dw_pre_hls_m_axi_wlast,
      m_axi_wvalid => sig_dw_pre_hls_m_axi_wvalid,
      m_axi_wready => sig_dw_pre_hls_m_axi_wready,
      m_axi_bresp => sig_dw_pre_hls_m_axi_bresp,
      m_axi_bvalid => sig_dw_pre_hls_m_axi_bvalid,
      m_axi_bready => sig_dw_pre_hls_m_axi_bready,
      m_axi_araddr => sig_dw_pre_hls_m_axi_araddr,
      m_axi_arlen => sig_dw_pre_hls_m_axi_arlen,
      m_axi_arsize => sig_dw_pre_hls_m_axi_arsize,
      m_axi_arburst => sig_dw_pre_hls_m_axi_arburst,
      m_axi_arlock => sig_dw_pre_hls_m_axi_arlock,
      m_axi_arcache => sig_dw_pre_hls_m_axi_arcache,
      m_axi_arprot => sig_dw_pre_hls_m_axi_arprot,
      m_axi_arregion => sig_dw_pre_hls_m_axi_arregion,
      m_axi_arqos => sig_dw_pre_hls_m_axi_arqos,
      m_axi_arvalid => sig_dw_pre_hls_m_axi_arvalid,
      m_axi_arready => sig_dw_pre_hls_m_axi_arready,
      m_axi_rdata => sig_dw_pre_hls_m_axi_rdata,
      m_axi_rresp => sig_dw_pre_hls_m_axi_rresp,
      m_axi_rlast => sig_dw_pre_hls_m_axi_rlast,
      m_axi_rvalid => sig_dw_pre_hls_m_axi_rvalid,
      m_axi_rready => sig_dw_pre_hls_m_axi_rready
    );
  
  
  axi_protocol_converter_hls_inst : axi_protocol_converter_hls_m
    port map (
      aclk => sig_aclk,
      aresetn => sig_aresetn,
  
      s_axi_awaddr => sig_dw_pre_hls_m_axi_awaddr,
      s_axi_awlen => sig_dw_pre_hls_m_axi_awlen,
      s_axi_awsize => sig_dw_pre_hls_m_axi_awsize,
      s_axi_awburst => sig_dw_pre_hls_m_axi_awburst,
      s_axi_awlock => sig_dw_pre_hls_m_axi_awlock,
      s_axi_awcache => sig_dw_pre_hls_m_axi_awcache,
      s_axi_awprot => sig_dw_pre_hls_m_axi_awprot,
      s_axi_awregion => sig_dw_pre_hls_m_axi_awregion,
      s_axi_awqos => sig_dw_pre_hls_m_axi_awqos,
      s_axi_awvalid => sig_dw_pre_hls_m_axi_awvalid,
      s_axi_awready => sig_dw_pre_hls_m_axi_awready,
      s_axi_wdata => sig_dw_pre_hls_m_axi_wdata,
      s_axi_wstrb => sig_dw_pre_hls_m_axi_wstrb,
      s_axi_wlast => sig_dw_pre_hls_m_axi_wlast,
      s_axi_wvalid => sig_dw_pre_hls_m_axi_wvalid,
      s_axi_wready => sig_dw_pre_hls_m_axi_wready,
      s_axi_bresp => sig_dw_pre_hls_m_axi_bresp,
      s_axi_bvalid => sig_dw_pre_hls_m_axi_bvalid,
      s_axi_bready => sig_dw_pre_hls_m_axi_bready,
      s_axi_araddr => sig_dw_pre_hls_m_axi_araddr,
      s_axi_arlen => sig_dw_pre_hls_m_axi_arlen,
      s_axi_arsize => sig_dw_pre_hls_m_axi_arsize,
      s_axi_arburst => sig_dw_pre_hls_m_axi_arburst,
      s_axi_arlock => sig_dw_pre_hls_m_axi_arlock,
      s_axi_arcache => sig_dw_pre_hls_m_axi_arcache,
      s_axi_arprot => sig_dw_pre_hls_m_axi_arprot,
      s_axi_arregion => sig_dw_pre_hls_m_axi_arregion,
      s_axi_arqos => sig_dw_pre_hls_m_axi_arqos,
      s_axi_arvalid => sig_dw_pre_hls_m_axi_arvalid,
      s_axi_arready => sig_dw_pre_hls_m_axi_arready,
      s_axi_rdata => sig_dw_pre_hls_m_axi_rdata,
      s_axi_rresp => sig_dw_pre_hls_m_axi_rresp,
      s_axi_rlast => sig_dw_pre_hls_m_axi_rlast,
      s_axi_rvalid => sig_dw_pre_hls_m_axi_rvalid,
      s_axi_rready => sig_dw_pre_hls_m_axi_rready,
  
      m_axi_awaddr => sig_pr_hls_m_axi_awaddr_pr,
      m_axi_awprot => sig_pr_hls_m_axi_awprot,
      m_axi_awvalid => sig_pr_hls_m_axi_awvalid,
      m_axi_awready => sig_pr_hls_m_axi_awready,
      m_axi_wdata => sig_pr_hls_m_axi_wdata,
      m_axi_wstrb => sig_pr_hls_m_axi_wstrb,
      m_axi_wvalid => sig_pr_hls_m_axi_wvalid,
      m_axi_wready => sig_pr_hls_m_axi_wready,
      m_axi_bresp => sig_pr_hls_m_axi_bresp,
      m_axi_bvalid => sig_pr_hls_m_axi_bvalid,
      m_axi_bready => sig_pr_hls_m_axi_bready,
      m_axi_araddr => sig_pr_hls_m_axi_araddr_pr,
      m_axi_arprot => sig_pr_hls_m_axi_arprot,
      m_axi_arvalid => sig_pr_hls_m_axi_arvalid,
      m_axi_arready => sig_pr_hls_m_axi_arready,
      m_axi_rdata => sig_pr_hls_m_axi_rdata,
      m_axi_rresp => sig_pr_hls_m_axi_rresp,
      m_axi_rvalid => sig_pr_hls_m_axi_rvalid,
      m_axi_rready => sig_pr_hls_m_axi_rready
    );
  
  sig_pr_hls_m_axi_awaddr <= std_logic_vector(resize(unsigned(sig_pr_hls_m_axi_awaddr_pr), hls_axilite_addr_width));
  sig_pr_hls_m_axi_araddr <= std_logic_vector(resize(unsigned(sig_pr_hls_m_axi_araddr_pr), hls_axilite_addr_width));
  
  
  two_layer_net_inst : two_layer_net_m
    port map (
      s_axi_control_awaddr => sig_pr_hls_m_axi_awaddr,
      s_axi_control_awvalid => sig_pr_hls_m_axi_awvalid,
      s_axi_control_awready => sig_pr_hls_m_axi_awready,
      s_axi_control_wdata => sig_pr_hls_m_axi_wdata,
      s_axi_control_wstrb => sig_pr_hls_m_axi_wstrb,
      s_axi_control_wvalid => sig_pr_hls_m_axi_wvalid,
      s_axi_control_wready => sig_pr_hls_m_axi_wready,
      s_axi_control_bresp => sig_pr_hls_m_axi_bresp,
      s_axi_control_bvalid => sig_pr_hls_m_axi_bvalid,
      s_axi_control_bready => sig_pr_hls_m_axi_bready,
      s_axi_control_araddr => sig_pr_hls_m_axi_araddr,
      s_axi_control_arvalid => sig_pr_hls_m_axi_arvalid,
      s_axi_control_arready => sig_pr_hls_m_axi_arready,
      s_axi_control_rdata => sig_pr_hls_m_axi_rdata,
      s_axi_control_rresp => sig_pr_hls_m_axi_rresp,
      s_axi_control_rvalid => sig_pr_hls_m_axi_rvalid,
      s_axi_control_rready => sig_pr_hls_m_axi_rready,
  
      ap_clk => sig_aclk,
      ap_rst_n => sig_aresetn,
      interrupt => open,
  
      m_axi_hostmem_awaddr => sig_hls_m_axi_gmem_awaddr_hls,
      m_axi_hostmem_awlen => sig_hls_m_axi_gmem_awlen,
      m_axi_hostmem_awsize => sig_hls_m_axi_gmem_awsize,
      m_axi_hostmem_awburst => sig_hls_m_axi_gmem_awburst,
      m_axi_hostmem_awlock => sig_hls_m_axi_gmem_awlock,
      m_axi_hostmem_awregion => sig_hls_m_axi_gmem_awregion,
      m_axi_hostmem_awcache => sig_hls_m_axi_gmem_awcache,
      m_axi_hostmem_awprot => sig_hls_m_axi_gmem_awprot,
      m_axi_hostmem_awqos => sig_hls_m_axi_gmem_awqos,
      m_axi_hostmem_awvalid => sig_hls_m_axi_gmem_awvalid,
      m_axi_hostmem_awready => sig_hls_m_axi_gmem_awready,
      m_axi_hostmem_wdata => sig_hls_m_axi_gmem_wdata,
      m_axi_hostmem_wstrb => sig_hls_m_axi_gmem_wstrb,
      m_axi_hostmem_wlast => sig_hls_m_axi_gmem_wlast,
      m_axi_hostmem_wvalid => sig_hls_m_axi_gmem_wvalid,
      m_axi_hostmem_wready => sig_hls_m_axi_gmem_wready,
      m_axi_hostmem_bresp => sig_hls_m_axi_gmem_bresp,
      m_axi_hostmem_bvalid => sig_hls_m_axi_gmem_bvalid,
      m_axi_hostmem_bready => sig_hls_m_axi_gmem_bready,
      m_axi_hostmem_araddr => sig_hls_m_axi_gmem_araddr_hls,
      m_axi_hostmem_arlen => sig_hls_m_axi_gmem_arlen,
      m_axi_hostmem_arsize => sig_hls_m_axi_gmem_arsize,
      m_axi_hostmem_arburst => sig_hls_m_axi_gmem_arburst,
      m_axi_hostmem_arlock => sig_hls_m_axi_gmem_arlock,
      m_axi_hostmem_arregion => sig_hls_m_axi_gmem_arregion,
      m_axi_hostmem_arcache => sig_hls_m_axi_gmem_arcache,
      m_axi_hostmem_arprot => sig_hls_m_axi_gmem_arprot,
      m_axi_hostmem_arqos => sig_hls_m_axi_gmem_arqos,
      m_axi_hostmem_arvalid => sig_hls_m_axi_gmem_arvalid,
      m_axi_hostmem_arready => sig_hls_m_axi_gmem_arready,
      m_axi_hostmem_rdata => sig_hls_m_axi_gmem_rdata,
      m_axi_hostmem_rresp => sig_hls_m_axi_gmem_rresp,
      m_axi_hostmem_rlast => sig_hls_m_axi_gmem_rlast,
      m_axi_hostmem_rvalid => sig_hls_m_axi_gmem_rvalid,
      m_axi_hostmem_rready => sig_hls_m_axi_gmem_rready
    );

  sig_hls_m_axi_gmem_awaddr <= std_logic_vector(resize(unsigned(sig_hls_m_axi_gmem_awaddr_hls), m_axi_axaddr_width));
  sig_hls_m_axi_gmem_araddr <= std_logic_vector(resize(unsigned(sig_hls_m_axi_gmem_araddr_hls), m_axi_axaddr_width));

  axi_dwidth_converter_post_hls_inst : axi_dwidth_converter_post_hls_m
    port map (
      s_axi_aclk => sig_aclk,
      s_axi_aresetn => sig_aresetn,
  
      s_axi_awaddr => sig_hls_m_axi_gmem_awaddr,
      s_axi_awlen => sig_hls_m_axi_gmem_awlen,
      s_axi_awsize => sig_hls_m_axi_gmem_awsize,
      s_axi_awburst => sig_hls_m_axi_gmem_awburst,
      s_axi_awlock => sig_hls_m_axi_gmem_awlock(0 downto 0),
      s_axi_awcache => sig_hls_m_axi_gmem_awcache,
      s_axi_awprot => sig_hls_m_axi_gmem_awprot,
      s_axi_awregion => sig_hls_m_axi_gmem_awregion,
      s_axi_awqos => sig_hls_m_axi_gmem_awqos,
      s_axi_awvalid => sig_hls_m_axi_gmem_awvalid,
      s_axi_awready => sig_hls_m_axi_gmem_awready,
      s_axi_wdata => sig_hls_m_axi_gmem_wdata,
      s_axi_wstrb => sig_hls_m_axi_gmem_wstrb,
      s_axi_wlast => sig_hls_m_axi_gmem_wlast,
      s_axi_wvalid => sig_hls_m_axi_gmem_wvalid,
      s_axi_wready => sig_hls_m_axi_gmem_wready,
      s_axi_bresp => sig_hls_m_axi_gmem_bresp,
      s_axi_bvalid => sig_hls_m_axi_gmem_bvalid,
      s_axi_bready => sig_hls_m_axi_gmem_bready,
      s_axi_araddr => sig_hls_m_axi_gmem_araddr,
      s_axi_arlen => sig_hls_m_axi_gmem_arlen,
      s_axi_arsize => sig_hls_m_axi_gmem_arsize,
      s_axi_arburst => sig_hls_m_axi_gmem_arburst,
      s_axi_arlock => sig_hls_m_axi_gmem_arlock(0 downto 0),
      s_axi_arcache => sig_hls_m_axi_gmem_arcache,
      s_axi_arprot => sig_hls_m_axi_gmem_arprot,
      s_axi_arregion => sig_hls_m_axi_gmem_arregion,
      s_axi_arqos => sig_hls_m_axi_gmem_arqos,
      s_axi_arvalid => sig_hls_m_axi_gmem_arvalid,
      s_axi_arready => sig_hls_m_axi_gmem_arready,
      s_axi_rdata => sig_hls_m_axi_gmem_rdata,
      s_axi_rresp => sig_hls_m_axi_gmem_rresp,
      s_axi_rlast => sig_hls_m_axi_gmem_rlast,
      s_axi_rvalid => sig_hls_m_axi_gmem_rvalid,
      s_axi_rready => sig_hls_m_axi_gmem_rready,
  
      m_axi_awaddr => sig_dw_post_hls_m_axi_awaddr,
      m_axi_awlen => sig_dw_post_hls_m_axi_awlen,
      m_axi_awsize => sig_dw_post_hls_m_axi_awsize,
      m_axi_awburst => sig_dw_post_hls_m_axi_awburst,
      m_axi_awlock => sig_dw_post_hls_m_axi_awlock,
      m_axi_awcache => sig_dw_post_hls_m_axi_awcache,
      m_axi_awprot => sig_dw_post_hls_m_axi_awprot,
      m_axi_awregion => sig_dw_post_hls_m_axi_awregion,
      m_axi_awqos => sig_dw_post_hls_m_axi_awqos,
      m_axi_awvalid => sig_dw_post_hls_m_axi_awvalid,
      m_axi_awready => sig_dw_post_hls_m_axi_awready,
      m_axi_wdata => sig_dw_post_hls_m_axi_wdata,
      m_axi_wstrb => sig_dw_post_hls_m_axi_wstrb,
      m_axi_wlast => sig_dw_post_hls_m_axi_wlast,
      m_axi_wvalid => sig_dw_post_hls_m_axi_wvalid,
      m_axi_wready => sig_dw_post_hls_m_axi_wready,
      m_axi_bresp => sig_dw_post_hls_m_axi_bresp,
      m_axi_bvalid => sig_dw_post_hls_m_axi_bvalid,
      m_axi_bready => sig_dw_post_hls_m_axi_bready,
      m_axi_araddr => sig_dw_post_hls_m_axi_araddr,
      m_axi_arlen => sig_dw_post_hls_m_axi_arlen,
      m_axi_arsize => sig_dw_post_hls_m_axi_arsize,
      m_axi_arburst => sig_dw_post_hls_m_axi_arburst,
      m_axi_arlock => sig_dw_post_hls_m_axi_arlock,
      m_axi_arcache => sig_dw_post_hls_m_axi_arcache,
      m_axi_arprot => sig_dw_post_hls_m_axi_arprot,
      m_axi_arregion => sig_dw_post_hls_m_axi_arregion,
      m_axi_arqos => sig_dw_post_hls_m_axi_arqos,
      m_axi_arvalid => sig_dw_post_hls_m_axi_arvalid,
      m_axi_arready => sig_dw_post_hls_m_axi_arready,
      m_axi_rdata => sig_dw_post_hls_m_axi_rdata,
      m_axi_rresp => sig_dw_post_hls_m_axi_rresp,
      m_axi_rlast => sig_dw_post_hls_m_axi_rlast,
      m_axi_rvalid => sig_dw_post_hls_m_axi_rvalid,
      m_axi_rready => sig_dw_post_hls_m_axi_rready
    );
 

  axi_crossbar_c0_inst : axi_crossbar_c0_m
    port map (
      aclk => sig_aclk,
      aresetn => sig_aresetn,

      s_axi_awid => B"00",
      s_axi_awaddr(m_axi_axaddr_width * 2 - 1 downto m_axi_axaddr_width) => sig_dw_post_hls_m_axi_awaddr,
      s_axi_awaddr(m_axi_axaddr_width - 1 downto 0) => sig_dw_dma0_m_axi_awaddr,
      s_axi_awlen(m_axi_axlen_width * 2 - 1 downto m_axi_axlen_width) => sig_dw_post_hls_m_axi_awlen,
      s_axi_awlen(m_axi_axlen_width - 1 downto 0) => sig_dw_dma0_m_axi_awlen,
      s_axi_awsize(5 downto 3) => sig_dw_post_hls_m_axi_awsize,
      s_axi_awsize(2 downto 0) => sig_dw_dma0_m_axi_awsize,
      s_axi_awburst(3 downto 2) => sig_dw_post_hls_m_axi_awburst,
      s_axi_awburst(1 downto 0) => sig_dw_dma0_m_axi_awburst,
      s_axi_awlock(1 downto 1) => sig_dw_post_hls_m_axi_awlock,
      s_axi_awlock(0 downto 0) => sig_dw_dma0_m_axi_awlock,
      s_axi_awcache(7 downto 4) => sig_dw_post_hls_m_axi_awcache,
      s_axi_awcache(3 downto 0) => sig_dw_dma0_m_axi_awcache,
      s_axi_awprot(5 downto 3) => sig_dw_post_hls_m_axi_awprot,
      s_axi_awprot(2 downto 0) => sig_dw_dma0_m_axi_awprot,
      s_axi_awqos(7 downto 4) => sig_dw_post_hls_m_axi_awqos,
      s_axi_awqos(3 downto 0) => sig_dw_dma0_m_axi_awqos,
      s_axi_awvalid(1) => sig_dw_post_hls_m_axi_awvalid,
      s_axi_awvalid(0) => sig_dw_dma0_m_axi_awvalid,
      s_axi_awready(1) => sig_dw_post_hls_m_axi_awready,
      s_axi_awready(0) => sig_dw_dma0_m_axi_awready,
      s_axi_wdata(m_axi_xdata_width * 2 - 1 downto m_axi_xdata_width) => sig_dw_post_hls_m_axi_wdata,
      s_axi_wdata(m_axi_xdata_width - 1 downto 0) => sig_dw_dma0_m_axi_wdata,
      s_axi_wstrb(m_axi_xdata_width / 8 * 2 - 1 downto m_axi_xdata_width / 8) => sig_dw_post_hls_m_axi_wstrb,
      s_axi_wstrb(m_axi_xdata_width / 8 - 1 downto 0) => sig_dw_dma0_m_axi_wstrb,
      s_axi_wlast(1) => sig_dw_post_hls_m_axi_wlast,
      s_axi_wlast(0) => sig_dw_dma0_m_axi_wlast,
      s_axi_wvalid(1) => sig_dw_post_hls_m_axi_wvalid,
      s_axi_wvalid(0) => sig_dw_dma0_m_axi_wvalid,
      s_axi_wready(1) => sig_dw_post_hls_m_axi_wready,
      s_axi_wready(0) => sig_dw_dma0_m_axi_wready,
      s_axi_bid => open,
      s_axi_bresp(3 downto 2) => sig_dw_post_hls_m_axi_bresp,
      s_axi_bresp(1 downto 0) => sig_dw_dma0_m_axi_bresp,
      s_axi_bvalid(1) => sig_dw_post_hls_m_axi_bvalid,
      s_axi_bvalid(0) => sig_dw_dma0_m_axi_bvalid,
      s_axi_bready(1) => sig_dw_post_hls_m_axi_bready,
      s_axi_bready(0) => sig_dw_dma0_m_axi_bready,
      s_axi_arid => B"00",
      s_axi_araddr(m_axi_axaddr_width * 2 - 1 downto m_axi_axaddr_width) => sig_dw_post_hls_m_axi_araddr,
      s_axi_araddr(m_axi_axaddr_width - 1 downto 0) => sig_dw_dma0_m_axi_araddr,
      s_axi_arlen(m_axi_axlen_width * 2 - 1 downto m_axi_axlen_width) => sig_dw_post_hls_m_axi_arlen,
      s_axi_arlen(m_axi_axlen_width - 1 downto 0) => sig_dw_dma0_m_axi_arlen,
      s_axi_arsize(5 downto 3) => sig_dw_post_hls_m_axi_arsize,
      s_axi_arsize(2 downto 0) => sig_dw_dma0_m_axi_arsize,
      s_axi_arburst(3 downto 2) => sig_dw_post_hls_m_axi_arburst,
      s_axi_arburst(1 downto 0) => sig_dw_dma0_m_axi_arburst,
      s_axi_arlock(1 downto 1) => sig_dw_post_hls_m_axi_arlock,
      s_axi_arlock(0 downto 0) => sig_dw_dma0_m_axi_arlock,
      s_axi_arcache(7 downto 4) => sig_dw_post_hls_m_axi_arcache,
      s_axi_arcache(3 downto 0) => sig_dw_dma0_m_axi_arcache,
      s_axi_arprot(5 downto 3) => sig_dw_post_hls_m_axi_arprot,
      s_axi_arprot(2 downto 0) => sig_dw_dma0_m_axi_arprot,
      s_axi_arqos(7 downto 4) => sig_dw_post_hls_m_axi_arqos,
      s_axi_arqos(3 downto 0) => sig_dw_dma0_m_axi_arqos,
      s_axi_arvalid(1) => sig_dw_post_hls_m_axi_arvalid,
      s_axi_arvalid(0) => sig_dw_dma0_m_axi_arvalid,
      s_axi_arready(1) => sig_dw_post_hls_m_axi_arready,
      s_axi_arready(0) => sig_dw_dma0_m_axi_arready,
      s_axi_rid => open,
      s_axi_rdata(m_axi_xdata_width * 2 - 1 downto m_axi_xdata_width) => sig_dw_post_hls_m_axi_rdata,
      s_axi_rdata(m_axi_xdata_width - 1 downto 0) => sig_dw_dma0_m_axi_rdata,
      s_axi_rresp(3 downto 2) => sig_dw_post_hls_m_axi_rresp,
      s_axi_rresp(1 downto 0) => sig_dw_dma0_m_axi_rresp,
      s_axi_rlast(1) => sig_dw_post_hls_m_axi_rlast,
      s_axi_rlast(0) => sig_dw_dma0_m_axi_rlast,
      s_axi_rvalid(1) => sig_dw_post_hls_m_axi_rvalid,
      s_axi_rvalid(0) => sig_dw_dma0_m_axi_rvalid,
      s_axi_rready(1) => sig_dw_post_hls_m_axi_rready,
      s_axi_rready(0) => sig_dw_dma0_m_axi_rready,

      m_axi_awid => sig_xbar_c0_m_axi_awid,
      m_axi_awaddr => sig_xbar_c0_m_axi_awaddr_xbar,
      m_axi_awlen => sig_xbar_c0_m_axi_awlen,
      m_axi_awsize => sig_xbar_c0_m_axi_awsize,
      m_axi_awburst => sig_xbar_c0_m_axi_awburst,
      m_axi_awlock => sig_xbar_c0_m_axi_awlock,
      m_axi_awcache => sig_xbar_c0_m_axi_awcache,
      m_axi_awprot => sig_xbar_c0_m_axi_awprot,
      m_axi_awregion => sig_xbar_c0_m_axi_awregion,
      m_axi_awqos => sig_xbar_c0_m_axi_awqos,
      m_axi_awvalid => sig_xbar_c0_m_axi_awvalid,
      m_axi_awready => sig_xbar_c0_m_axi_awready,
      m_axi_wdata => sig_xbar_c0_m_axi_wdata,
      m_axi_wstrb => sig_xbar_c0_m_axi_wstrb,
      m_axi_wlast => sig_xbar_c0_m_axi_wlast,
      m_axi_wvalid => sig_xbar_c0_m_axi_wvalid,
      m_axi_wready => sig_xbar_c0_m_axi_wready,
      m_axi_bid => B"0",
      m_axi_bresp => sig_xbar_c0_m_axi_bresp,
      m_axi_bvalid => sig_xbar_c0_m_axi_bvalid,
      m_axi_bready => sig_xbar_c0_m_axi_bready,
      m_axi_arid => sig_xbar_c0_m_axi_arid,
      m_axi_araddr => sig_xbar_c0_m_axi_araddr_xbar,
      m_axi_arlen => sig_xbar_c0_m_axi_arlen,
      m_axi_arsize => sig_xbar_c0_m_axi_arsize,
      m_axi_arburst => sig_xbar_c0_m_axi_arburst,
      m_axi_arlock => sig_xbar_c0_m_axi_arlock,
      m_axi_arcache => sig_xbar_c0_m_axi_arcache,
      m_axi_arprot => sig_xbar_c0_m_axi_arprot,
      m_axi_arregion => sig_xbar_c0_m_axi_arregion,
      m_axi_arqos => sig_xbar_c0_m_axi_arqos,
      m_axi_arvalid => sig_xbar_c0_m_axi_arvalid,
      m_axi_arready => sig_xbar_c0_m_axi_arready,
      m_axi_rid => B"0",
      m_axi_rdata => sig_xbar_c0_m_axi_rdata,
      m_axi_rresp => sig_xbar_c0_m_axi_rresp,
      m_axi_rlast => sig_xbar_c0_m_axi_rlast,
      m_axi_rvalid => sig_xbar_c0_m_axi_rvalid,
      m_axi_rready => sig_xbar_c0_m_axi_rready
    );

  sig_xbar_c0_m_axi_awaddr <= std_logic_vector(resize(unsigned(sig_xbar_c0_m_axi_awaddr_xbar), bctl_axaddr_width));
  sig_xbar_c0_m_axi_araddr <= std_logic_vector(resize(unsigned(sig_xbar_c0_m_axi_araddr_xbar), bctl_axaddr_width));


  axi_bram_ctrl_c0_inst : axi_bram_ctrl_m
    port map (
      s_axi_aclk => sig_aclk,
      s_axi_aresetn => sig_aresetn,
      s_axi_awaddr => sig_xbar_c0_m_axi_awaddr,
      s_axi_awlen => sig_xbar_c0_m_axi_awlen,
      s_axi_awsize => sig_xbar_c0_m_axi_awsize,
      s_axi_awburst => sig_xbar_c0_m_axi_awburst,
      s_axi_awlock => sig_xbar_c0_m_axi_awlock,
      s_axi_awcache => sig_xbar_c0_m_axi_awcache,
      s_axi_awprot => sig_xbar_c0_m_axi_awprot,
      s_axi_awvalid => sig_xbar_c0_m_axi_awvalid,
      s_axi_awready => sig_xbar_c0_m_axi_awready,
      s_axi_wdata => sig_xbar_c0_m_axi_wdata,
      s_axi_wstrb => sig_xbar_c0_m_axi_wstrb,
      s_axi_wlast => sig_xbar_c0_m_axi_wlast,
      s_axi_wvalid => sig_xbar_c0_m_axi_wvalid,
      s_axi_wready => sig_xbar_c0_m_axi_wready,
      s_axi_bresp => sig_xbar_c0_m_axi_bresp,
      s_axi_bvalid => sig_xbar_c0_m_axi_bvalid,
      s_axi_bready => sig_xbar_c0_m_axi_bready,
      s_axi_araddr => sig_xbar_c0_m_axi_araddr,
      s_axi_arlen => sig_xbar_c0_m_axi_arlen,
      s_axi_arsize => sig_xbar_c0_m_axi_arsize,
      s_axi_arburst => sig_xbar_c0_m_axi_arburst,
      s_axi_arlock => sig_xbar_c0_m_axi_arlock,
      s_axi_arcache => sig_xbar_c0_m_axi_arcache,
      s_axi_arprot => sig_xbar_c0_m_axi_arprot,
      s_axi_arvalid => sig_xbar_c0_m_axi_arvalid,
      s_axi_arready => sig_xbar_c0_m_axi_arready,
      s_axi_rdata => sig_xbar_c0_m_axi_rdata,
      s_axi_rresp => sig_xbar_c0_m_axi_rresp,
      s_axi_rlast => sig_xbar_c0_m_axi_rlast,
      s_axi_rvalid => sig_xbar_c0_m_axi_rvalid,
      s_axi_rready => sig_xbar_c0_m_axi_rready,

      bram_rst_a => sig_c0_bram_rst_a,
      bram_clk_a => sig_c0_bram_clk_a,
      bram_en_a => sig_c0_bram_en_a,
      bram_we_a => sig_c0_bram_we_a,
      bram_addr_a => sig_c0_bram_addr_a_bctl,
      bram_wrdata_a => sig_c0_bram_wrdata_a,
      bram_rddata_a => sig_c0_bram_rddata_a
    );

  sig_c0_bram_addr_a <= std_logic_vector(resize(unsigned(sig_c0_bram_addr_a_bctl), blk_mem_axaddr_width));


  blk_mem_gen_c0_inst : blk_mem_gen_m
    port map (
      clka => sig_c0_bram_clk_a,
      rsta => sig_c0_bram_rst_a,
      ena => sig_c0_bram_en_a,
      wea => sig_c0_bram_we_a,
      addra => sig_c0_bram_addr_a,
      dina => sig_c0_bram_wrdata_a,
      douta => sig_c0_bram_rddata_a
    );


end architecture;
