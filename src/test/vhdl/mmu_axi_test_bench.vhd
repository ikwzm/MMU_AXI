-----------------------------------------------------------------------------------
--!     @file    mmu_axi_test_bench.vhd
--!     @brief   Test Bench for MMU AXI
--!     @version 1.0.0
--!     @date    2014/10/13
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2014 Ichiro Kawazome
--      All rights reserved.
--
--      Redistribution and use in source and binary forms, with or without
--      modification, are permitted provided that the following conditions
--      are met:
--
--        1. Redistributions of source code must retain the above copyright
--           notice, this list of conditions and the following disclaimer.
--
--        2. Redistributions in binary form must reproduce the above copyright
--           notice, this list of conditions and the following disclaimer in
--           the documentation and/or other materials provided with the
--           distribution.
--
--      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
--      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
--      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
--      A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
--      OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
--      SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
--      LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
--      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
--      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
--      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
--      OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
library DUMMY_PLUG;
use     DUMMY_PLUG.AXI4_TYPES.all;
entity  MMU_AXI_TEST_BENCH is
    generic (
        NAME            : STRING  := "MMU_AXI_TEST_BENCH";
        SCENARIO_FILE   : STRING  := "mmu_axi_test_bench.snr";
        READ_ENABLE     : integer :=  1;
        WRITE_ENABLE    : integer :=  1;
        PAGE_SIZE       : integer := 12;
        DESC_SIZE       : integer :=  2;
        TLB_TAG_SETS    : integer :=  2;
        TLB_TAG_WAYS    : integer :=  3;
        M_QUEUE_SIZE    : integer :=  0;
        M_AR_QUEUE_SIZE : integer :=  1;
        M_AW_QUEUE_SIZE : integer :=  1;
        M_RD_QUEUE_SIZE : integer :=  4;
        M_WD_QUEUE_SIZE : integer :=  4;
        M_WB_QUEUE_SIZE : integer :=  4
    );
end     MMU_AXI_TEST_BENCH;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     std.textio.all;
library DUMMY_PLUG;
use     DUMMY_PLUG.AXI4_TYPES.all;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_MASTER_PLAYER;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_SLAVE_PLAYER;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_SIGNAL_PRINTER;
use     DUMMY_PLUG.SYNC.all;
use     DUMMY_PLUG.CORE.MARCHAL;
use     DUMMY_PLUG.CORE.REPORT_STATUS_TYPE;
use     DUMMY_PLUG.CORE.REPORT_STATUS_VECTOR;
use     DUMMY_PLUG.CORE.MARGE_REPORT_STATUS;
architecture MODEL of MMU_AXI_TEST_BENCH is
    -------------------------------------------------------------------------------
    -- 各種定数
    -------------------------------------------------------------------------------
    constant PERIOD          : time    := 10 ns;
    constant DELAY           : time    :=  1 ns;
    constant AXI4_ADDR_WIDTH : integer := 32;
    constant C_WIDTH         : AXI4_SIGNAL_WIDTH_TYPE := (
                                 ID          => 4,
                                 AWADDR      => AXI4_ADDR_WIDTH,
                                 ARADDR      => AXI4_ADDR_WIDTH,
                                 ALEN        => AXI4_ALEN_WIDTH,
                                 ALOCK       => AXI4_ALOCK_WIDTH,
                                 WDATA       => 32,
                                 RDATA       => 32,
                                 ARUSER      => 1,
                                 AWUSER      => 1,
                                 WUSER       => 1,
                                 RUSER       => 1,
                                 BUSER       => 1);
    constant S_WIDTH         : AXI4_SIGNAL_WIDTH_TYPE := (
                                 ID          => 4,
                                 AWADDR      => AXI4_ADDR_WIDTH,
                                 ARADDR      => AXI4_ADDR_WIDTH,
                                 ALEN        => AXI4_ALEN_WIDTH,
                                 ALOCK       => AXI4_ALOCK_WIDTH,
                                 WDATA       => 32,
                                 RDATA       => 32,
                                 ARUSER      => 1,
                                 AWUSER      => 1,
                                 WUSER       => 1,
                                 RUSER       => 1,
                                 BUSER       => 1);
    constant M_WIDTH         : AXI4_SIGNAL_WIDTH_TYPE := (
                                 ID          => 4,
                                 AWADDR      => AXI4_ADDR_WIDTH,
                                 ARADDR      => AXI4_ADDR_WIDTH,
                                 ALEN        => AXI4_ALEN_WIDTH,
                                 ALOCK       => AXI4_ALOCK_WIDTH,
                                 WDATA       => 32,
                                 RDATA       => 32,
                                 ARUSER      => 1,
                                 AWUSER      => 1,
                                 WUSER       => 1,
                                 RUSER       => 1,
                                 BUSER       => 1);
    constant F_WIDTH         : AXI4_SIGNAL_WIDTH_TYPE := (
                                 ID          => 4,
                                 AWADDR      => AXI4_ADDR_WIDTH,
                                 ARADDR      => AXI4_ADDR_WIDTH,
                                 ALEN        => AXI4_ALEN_WIDTH,
                                 ALOCK       => AXI4_ALOCK_WIDTH,
                                 WDATA       => 32,
                                 RDATA       => 32,
                                 ARUSER      => 1,
                                 AWUSER      => 1,
                                 WUSER       => 1,
                                 RUSER       => 1,
                                 BUSER       => 1);
    constant SYNC_WIDTH      : integer :=  2;
    constant GPO_WIDTH       : integer :=  8;
    constant GPI_WIDTH       : integer :=  GPO_WIDTH;
    -------------------------------------------------------------------------------
    -- グローバルシグナル.
    -------------------------------------------------------------------------------
    signal   ACLK            : std_logic;
    signal   ARESETn         : std_logic;
    signal   RESET           : std_logic;
    constant CLEAR           : std_logic := '0';
    ------------------------------------------------------------------------------
    -- CSR I/F 
    ------------------------------------------------------------------------------
    signal   C_ARADDR        : std_logic_vector(C_WIDTH.ARADDR -1 downto 0);
    signal   C_ARWRITE       : std_logic;
    signal   C_ARLEN         : std_logic_vector(C_WIDTH.ALEN   -1 downto 0);
    signal   C_ARSIZE        : AXI4_ASIZE_TYPE;
    signal   C_ARBURST       : AXI4_ABURST_TYPE;
    signal   C_ARLOCK        : std_logic_vector(C_WIDTH.ALOCK  -1 downto 0);
    signal   C_ARCACHE       : AXI4_ACACHE_TYPE;
    signal   C_ARPROT        : AXI4_APROT_TYPE;
    signal   C_ARQOS         : AXI4_AQOS_TYPE;
    signal   C_ARREGION      : AXI4_AREGION_TYPE;
    signal   C_ARUSER        : std_logic_vector(C_WIDTH.ARUSER -1 downto 0);
    signal   C_ARID          : std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal   C_ARVALID       : std_logic;
    signal   C_ARREADY       : std_logic;
    signal   C_RVALID        : std_logic;
    signal   C_RLAST         : std_logic;
    signal   C_RDATA         : std_logic_vector(C_WIDTH.RDATA  -1 downto 0);
    signal   C_RRESP         : AXI4_RESP_TYPE;
    signal   C_RUSER         : std_logic_vector(C_WIDTH.RUSER  -1 downto 0);
    signal   C_RID           : std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal   C_RREADY        : std_logic;
    signal   C_AWADDR        : std_logic_vector(C_WIDTH.AWADDR -1 downto 0);
    signal   C_AWLEN         : std_logic_vector(C_WIDTH.ALEN   -1 downto 0);
    signal   C_AWSIZE        : AXI4_ASIZE_TYPE;
    signal   C_AWBURST       : AXI4_ABURST_TYPE;
    signal   C_AWLOCK        : std_logic_vector(C_WIDTH.ALOCK  -1 downto 0);
    signal   C_AWCACHE       : AXI4_ACACHE_TYPE;
    signal   C_AWPROT        : AXI4_APROT_TYPE;
    signal   C_AWQOS         : AXI4_AQOS_TYPE;
    signal   C_AWREGION      : AXI4_AREGION_TYPE;
    signal   C_AWUSER        : std_logic_vector(C_WIDTH.AWUSER -1 downto 0);
    signal   C_AWID          : std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal   C_AWVALID       : std_logic;
    signal   C_AWREADY       : std_logic;
    signal   C_WLAST         : std_logic;
    signal   C_WDATA         : std_logic_vector(C_WIDTH.WDATA  -1 downto 0);
    signal   C_WSTRB         : std_logic_vector(C_WIDTH.WDATA/8-1 downto 0);
    signal   C_WUSER         : std_logic_vector(C_WIDTH.WUSER  -1 downto 0);
    signal   C_WID           : std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal   C_WVALID        : std_logic;
    signal   C_WREADY        : std_logic;
    signal   C_BRESP         : AXI4_RESP_TYPE;
    signal   C_BUSER         : std_logic_vector(C_WIDTH.BUSER  -1 downto 0);
    signal   C_BID           : std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal   C_BVALID        : std_logic;
    signal   C_BREADY        : std_logic;
    ------------------------------------------------------------------------------
    -- Transaction Request Block I/F.
    ------------------------------------------------------------------------------
    signal   M_ARADDR        : std_logic_vector(M_WIDTH.ARADDR -1 downto 0);
    signal   M_ARLEN         : std_logic_vector(M_WIDTH.ALEN   -1 downto 0);
    signal   M_ARSIZE        : AXI4_ASIZE_TYPE;
    signal   M_ARBURST       : AXI4_ABURST_TYPE;
    signal   M_ARLOCK        : std_logic_vector(M_WIDTH.ALOCK  -1 downto 0);
    signal   M_ARCACHE       : AXI4_ACACHE_TYPE;
    signal   M_ARPROT        : AXI4_APROT_TYPE;
    signal   M_ARQOS         : AXI4_AQOS_TYPE;
    signal   M_ARREGION      : AXI4_AREGION_TYPE;
    signal   M_ARUSER        : std_logic_vector(M_WIDTH.ARUSER -1 downto 0);
    signal   M_ARID          : std_logic_vector(M_WIDTH.ID     -1 downto 0);
    signal   M_ARVALID       : std_logic;
    signal   M_ARREADY       : std_logic;
    signal   M_RVALID        : std_logic;
    signal   M_RLAST         : std_logic;
    signal   M_RDATA         : std_logic_vector(M_WIDTH.RDATA  -1 downto 0);
    signal   M_RRESP         : AXI4_RESP_TYPE;
    signal   M_RUSER         : std_logic_vector(M_WIDTH.RUSER  -1 downto 0);
    signal   M_RID           : std_logic_vector(M_WIDTH.ID     -1 downto 0);
    signal   M_RREADY        : std_logic;
    signal   M_AWADDR        : std_logic_vector(M_WIDTH.AWADDR -1 downto 0);
    signal   M_AWLEN         : std_logic_vector(M_WIDTH.ALEN   -1 downto 0);
    signal   M_AWSIZE        : AXI4_ASIZE_TYPE;
    signal   M_AWBURST       : AXI4_ABURST_TYPE;
    signal   M_AWLOCK        : std_logic_vector(M_WIDTH.ALOCK  -1 downto 0);
    signal   M_AWCACHE       : AXI4_ACACHE_TYPE;
    signal   M_AWPROT        : AXI4_APROT_TYPE;
    signal   M_AWQOS         : AXI4_AQOS_TYPE;
    signal   M_AWREGION      : AXI4_AREGION_TYPE;
    signal   M_AWUSER        : std_logic_vector(M_WIDTH.AWUSER -1 downto 0);
    signal   M_AWID          : std_logic_vector(M_WIDTH.ID     -1 downto 0);
    signal   M_AWVALID       : std_logic;
    signal   M_AWREADY       : std_logic;
    signal   M_WLAST         : std_logic;
    signal   M_WDATA         : std_logic_vector(M_WIDTH.WDATA  -1 downto 0);
    signal   M_WSTRB         : std_logic_vector(M_WIDTH.WDATA/8-1 downto 0);
    signal   M_WUSER         : std_logic_vector(M_WIDTH.WUSER  -1 downto 0);
    signal   M_WID           : std_logic_vector(M_WIDTH.ID     -1 downto 0);
    signal   M_WVALID        : std_logic;
    signal   M_WREADY        : std_logic;
    signal   M_BRESP         : AXI4_RESP_TYPE;
    signal   M_BUSER         : std_logic_vector(M_WIDTH.BUSER  -1 downto 0);
    signal   M_BID           : std_logic_vector(M_WIDTH.ID     -1 downto 0);
    signal   M_BVALID        : std_logic;
    signal   M_BREADY        : std_logic;
    ------------------------------------------------------------------------------
    -- Transaction Request Block I/F.
    ------------------------------------------------------------------------------
    signal   S_ARADDR        : std_logic_vector(S_WIDTH.ARADDR -1 downto 0);
    signal   S_ARLEN         : std_logic_vector(S_WIDTH.ALEN   -1 downto 0);
    signal   S_ARSIZE        : AXI4_ASIZE_TYPE;
    signal   S_ARBURST       : AXI4_ABURST_TYPE;
    signal   S_ARLOCK        : std_logic_vector(S_WIDTH.ALOCK  -1 downto 0);
    signal   S_ARCACHE       : AXI4_ACACHE_TYPE;
    signal   S_ARPROT        : AXI4_APROT_TYPE;
    signal   S_ARQOS         : AXI4_AQOS_TYPE;
    signal   S_ARREGION      : AXI4_AREGION_TYPE;
    signal   S_ARUSER        : std_logic_vector(S_WIDTH.ARUSER -1 downto 0);
    signal   S_ARID          : std_logic_vector(S_WIDTH.ID     -1 downto 0);
    signal   S_ARVALID       : std_logic;
    signal   S_ARREADY       : std_logic;
    signal   S_RVALID        : std_logic;
    signal   S_RLAST         : std_logic;
    signal   S_RDATA         : std_logic_vector(S_WIDTH.RDATA  -1 downto 0);
    signal   S_RRESP         : AXI4_RESP_TYPE;
    signal   S_RUSER         : std_logic_vector(S_WIDTH.RUSER  -1 downto 0);
    signal   S_RID           : std_logic_vector(S_WIDTH.ID     -1 downto 0);
    signal   S_RREADY        : std_logic;
    signal   S_AWADDR        : std_logic_vector(S_WIDTH.AWADDR -1 downto 0);
    signal   S_AWLEN         : std_logic_vector(S_WIDTH.ALEN   -1 downto 0);
    signal   S_AWSIZE        : AXI4_ASIZE_TYPE;
    signal   S_AWBURST       : AXI4_ABURST_TYPE;
    signal   S_AWLOCK        : std_logic_vector(S_WIDTH.ALOCK  -1 downto 0);
    signal   S_AWCACHE       : AXI4_ACACHE_TYPE;
    signal   S_AWPROT        : AXI4_APROT_TYPE;
    signal   S_AWQOS         : AXI4_AQOS_TYPE;
    signal   S_AWREGION      : AXI4_AREGION_TYPE;
    signal   S_AWUSER        : std_logic_vector(S_WIDTH.AWUSER -1 downto 0);
    signal   S_AWID          : std_logic_vector(S_WIDTH.ID     -1 downto 0);
    signal   S_AWVALID       : std_logic;
    signal   S_AWREADY       : std_logic;
    signal   S_WLAST         : std_logic;
    signal   S_WDATA         : std_logic_vector(S_WIDTH.WDATA  -1 downto 0);
    signal   S_WSTRB         : std_logic_vector(S_WIDTH.WDATA/8-1 downto 0);
    signal   S_WUSER         : std_logic_vector(S_WIDTH.WUSER  -1 downto 0);
    signal   S_WID           : std_logic_vector(S_WIDTH.ID     -1 downto 0);
    signal   S_WVALID        : std_logic;
    signal   S_WREADY        : std_logic;
    signal   S_BRESP         : AXI4_RESP_TYPE;
    signal   S_BUSER         : std_logic_vector(S_WIDTH.BUSER  -1 downto 0);
    signal   S_BID           : std_logic_vector(S_WIDTH.ID     -1 downto 0);
    signal   S_BVALID        : std_logic;
    signal   S_BREADY        : std_logic;
    ------------------------------------------------------------------------------
    -- Transaction Request Block I/F.
    ------------------------------------------------------------------------------
    signal   F_ARADDR        : std_logic_vector(F_WIDTH.ARADDR -1 downto 0);
    signal   F_ARLEN         : std_logic_vector(F_WIDTH.ALEN   -1 downto 0);
    signal   F_ARSIZE        : AXI4_ASIZE_TYPE;
    signal   F_ARBURST       : AXI4_ABURST_TYPE;
    signal   F_ARLOCK        : std_logic_vector(F_WIDTH.ALOCK  -1 downto 0);
    signal   F_ARCACHE       : AXI4_ACACHE_TYPE;
    signal   F_ARPROT        : AXI4_APROT_TYPE;
    signal   F_ARQOS         : AXI4_AQOS_TYPE;
    signal   F_ARREGION      : AXI4_AREGION_TYPE;
    signal   F_ARUSER        : std_logic_vector(F_WIDTH.ARUSER -1 downto 0);
    signal   F_ARID          : std_logic_vector(F_WIDTH.ID     -1 downto 0);
    signal   F_ARVALID       : std_logic;
    signal   F_ARREADY       : std_logic;
    signal   F_RVALID        : std_logic;
    signal   F_RLAST         : std_logic;
    signal   F_RDATA         : std_logic_vector(F_WIDTH.RDATA  -1 downto 0);
    signal   F_RRESP         : AXI4_RESP_TYPE;
    signal   F_RUSER         : std_logic_vector(F_WIDTH.RUSER  -1 downto 0);
    signal   F_RID           : std_logic_vector(F_WIDTH.ID     -1 downto 0);
    signal   F_RREADY        : std_logic;
    signal   F_AWADDR        : std_logic_vector(F_WIDTH.AWADDR -1 downto 0);
    signal   F_AWLEN         : std_logic_vector(F_WIDTH.ALEN   -1 downto 0);
    signal   F_AWSIZE        : AXI4_ASIZE_TYPE;
    signal   F_AWBURST       : AXI4_ABURST_TYPE;
    signal   F_AWLOCK        : std_logic_vector(F_WIDTH.ALOCK  -1 downto 0);
    signal   F_AWCACHE       : AXI4_ACACHE_TYPE;
    signal   F_AWPROT        : AXI4_APROT_TYPE;
    signal   F_AWQOS         : AXI4_AQOS_TYPE;
    signal   F_AWREGION      : AXI4_AREGION_TYPE;
    signal   F_AWUSER        : std_logic_vector(F_WIDTH.AWUSER -1 downto 0);
    signal   F_AWID          : std_logic_vector(F_WIDTH.ID     -1 downto 0);
    signal   F_AWVALID       : std_logic;
    signal   F_AWREADY       : std_logic;
    signal   F_WLAST         : std_logic;
    signal   F_WDATA         : std_logic_vector(F_WIDTH.WDATA  -1 downto 0);
    signal   F_WSTRB         : std_logic_vector(F_WIDTH.WDATA/8-1 downto 0);
    signal   F_WUSER         : std_logic_vector(F_WIDTH.WUSER  -1 downto 0);
    signal   F_WID           : std_logic_vector(F_WIDTH.ID     -1 downto 0);
    signal   F_WVALID        : std_logic;
    signal   F_WREADY        : std_logic;
    signal   F_BRESP         : AXI4_RESP_TYPE;
    signal   F_BUSER         : std_logic_vector(F_WIDTH.BUSER  -1 downto 0);
    signal   F_BID           : std_logic_vector(F_WIDTH.ID     -1 downto 0);
    signal   F_BVALID        : std_logic;
    signal   F_BREADY        : std_logic;
    -------------------------------------------------------------------------------
    -- シンクロ用信号
    -------------------------------------------------------------------------------
    signal   SYNC            : SYNC_SIG_VECTOR (SYNC_WIDTH   -1 downto 0);
    -------------------------------------------------------------------------------
    -- GPIO(General Purpose Input/Output)
    -------------------------------------------------------------------------------
    signal   C_GPI           : std_logic_vector(GPI_WIDTH    -1 downto 0);
    signal   C_GPO           : std_logic_vector(GPO_WIDTH    -1 downto 0);
    signal   M_GPI           : std_logic_vector(GPI_WIDTH    -1 downto 0);
    signal   M_GPO           : std_logic_vector(GPO_WIDTH    -1 downto 0);
    signal   S_GPI           : std_logic_vector(GPI_WIDTH    -1 downto 0);
    signal   S_GPO           : std_logic_vector(GPO_WIDTH    -1 downto 0);
    signal   F_GPI           : std_logic_vector(GPI_WIDTH    -1 downto 0);
    signal   F_GPO           : std_logic_vector(GPO_WIDTH    -1 downto 0);
    -------------------------------------------------------------------------------
    -- 各種状態出力.
    -------------------------------------------------------------------------------
    signal   N_REPORT        : REPORT_STATUS_TYPE;
    signal   C_REPORT        : REPORT_STATUS_TYPE;
    signal   M_REPORT        : REPORT_STATUS_TYPE;
    signal   S_REPORT        : REPORT_STATUS_TYPE;
    signal   F_REPORT        : REPORT_STATUS_TYPE;
    signal   N_FINISH        : std_logic;
    signal   C_FINISH        : std_logic;
    signal   M_FINISH        : std_logic;
    signal   S_FINISH        : std_logic;
    signal   F_FINISH        : std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    component MMU_AXI 
        generic (
            READ_ENABLE     : integer :=  1;
            WRITE_ENABLE    : integer :=  1;
            PAGE_SIZE       : integer := 12;
            DESC_SIZE       : integer :=  2;
            TLB_TAG_SETS    : integer :=  2;
            TLB_TAG_WAYS    : integer :=  3;
            M_QUEUE_SIZE    : integer :=  0;
            M_AR_QUEUE_SIZE : integer :=  1;
            M_AW_QUEUE_SIZE : integer :=  1;
            M_RD_QUEUE_SIZE : integer :=  4;
            M_WD_QUEUE_SIZE : integer :=  4;
            M_WB_QUEUE_SIZE : integer :=  4;
            S_ADDR_WIDTH    : integer := 32;
            S_ALEN_WIDTH    : integer :=  8;
            S_ALOCK_WIDTH   : integer :=  1;
            S_AUSER_WIDTH   : integer :=  1;
            S_ID_WIDTH      : integer :=  4;
            S_DATA_WIDTH    : integer := 32;
            M_ADDR_WIDTH    : integer := 32;
            M_ALEN_WIDTH    : integer :=  8;
            M_ALOCK_WIDTH   : integer :=  1;
            M_AUSER_WIDTH   : integer :=  1;
            M_ID_WIDTH      : integer :=  4;
            M_DATA_WIDTH    : integer := 32;
            F_ADDR_WIDTH    : integer := 32;
            F_ALEN_WIDTH    : integer :=  8;
            F_ALOCK_WIDTH   : integer :=  1;
            F_AUSER_WIDTH   : integer :=  1;
            F_ID_WIDTH      : integer :=  4;
            F_DATA_WIDTH    : integer := 32;
            C_ADDR_WIDTH    : integer := 32;
            C_ALEN_WIDTH    : integer :=  8;
            C_ID_WIDTH      : integer :=  4;
            C_DATA_WIDTH    : integer := 32
        );
        port (
        ---------------------------------------------------------------------------
        -- Reset Signals.
        ---------------------------------------------------------------------------
            ARESETn         : in    std_logic;
        ---------------------------------------------------------------------------
        -- Control Status Register I/F Clock.
        ---------------------------------------------------------------------------
            C_CLK           : in    std_logic;
        ---------------------------------------------------------------------------
        -- Control Status Register I/F AXI4 Read Address Channel Signals.
        ---------------------------------------------------------------------------
            C_ARID          : in    std_logic_vector(C_ID_WIDTH    -1 downto 0);
            C_ARADDR        : in    std_logic_vector(C_ADDR_WIDTH  -1 downto 0);
            C_ARLEN         : in    std_logic_vector(C_ALEN_WIDTH  -1 downto 0);
            C_ARSIZE        : in    std_logic_vector(2 downto 0);
            C_ARBURST       : in    std_logic_vector(1 downto 0);
            C_ARVALID       : in    std_logic;
            C_ARREADY       : out   std_logic;
        ---------------------------------------------------------------------------
        -- Control Status Register I/F AXI4 Read Data Channel Signals.
        ---------------------------------------------------------------------------
            C_RID           : out   std_logic_vector(C_ID_WIDTH    -1 downto 0);
            C_RDATA         : out   std_logic_vector(C_DATA_WIDTH  -1 downto 0);
            C_RRESP         : out   std_logic_vector(1 downto 0);
            C_RLAST         : out   std_logic;
            C_RVALID        : out   std_logic;
            C_RREADY        : in    std_logic;
        ---------------------------------------------------------------------------
        -- Control Status Register I/F AXI4 Write Address Channel Signals.
        ---------------------------------------------------------------------------
            C_AWID          : in    std_logic_vector(C_ID_WIDTH    -1 downto 0);
            C_AWADDR        : in    std_logic_vector(C_ADDR_WIDTH  -1 downto 0);
            C_AWLEN         : in    std_logic_vector(C_ALEN_WIDTH  -1 downto 0);
            C_AWSIZE        : in    std_logic_vector(2 downto 0);
            C_AWBURST       : in    std_logic_vector(1 downto 0);
            C_AWVALID       : in    std_logic;
            C_AWREADY       : out   std_logic;
        ---------------------------------------------------------------------------
        -- Control Status Register I/F AXI4 Write Data Channel Signals.
        ---------------------------------------------------------------------------
            C_WDATA         : in    std_logic_vector(C_DATA_WIDTH  -1 downto 0);
            C_WSTRB         : in    std_logic_vector(C_DATA_WIDTH/8-1 downto 0);
            C_WLAST         : in    std_logic;
            C_WVALID        : in    std_logic;
            C_WREADY        : out   std_logic;
        ---------------------------------------------------------------------------
        -- Control Status Register I/F AXI4 Write Response Channel Signals.
        ---------------------------------------------------------------------------
            C_BID           : out   std_logic_vector(C_ID_WIDTH    -1 downto 0);
            C_BRESP         : out   std_logic_vector(1 downto 0);
            C_BVALID        : out   std_logic;
            C_BREADY        : in    std_logic;
        ---------------------------------------------------------------------------
        -- Descripter Fetch I/F Clock.
        ---------------------------------------------------------------------------
            F_CLK           : in    std_logic;
        ---------------------------------------------------------------------------
        -- Descripter Fetch I/F AXI4 Read Address Channel Signals.
        ---------------------------------------------------------------------------
            F_ARID          : out   std_logic_vector(F_ID_WIDTH    -1 downto 0);
            F_ARADDR        : out   std_logic_vector(F_ADDR_WIDTH  -1 downto 0);
            F_ARLEN         : out   std_logic_vector(F_ALEN_WIDTH  -1 downto 0);
            F_ARSIZE        : out   std_logic_vector(2 downto 0);
            F_ARBURST       : out   std_logic_vector(1 downto 0);
            F_ARLOCK        : out   std_logic_vector(F_ALOCK_WIDTH -1 downto 0);
            F_ARCACHE       : out   std_logic_vector(3 downto 0);
            F_ARPROT        : out   std_logic_vector(2 downto 0);
            F_ARQOS         : out   std_logic_vector(3 downto 0);
            F_ARREGION      : out   std_logic_vector(3 downto 0);
            F_ARUSER        : out   std_logic_vector(F_AUSER_WIDTH -1 downto 0);
            F_ARVALID       : out   std_logic;
            F_ARREADY       : in    std_logic;
        ---------------------------------------------------------------------------
        -- Descripter Fetch I/F AXI4 Read Data Channel Signals.
        ---------------------------------------------------------------------------
            F_RID           : in    std_logic_vector(F_ID_WIDTH    -1 downto 0);
            F_RDATA         : in    std_logic_vector(F_DATA_WIDTH  -1 downto 0);
            F_RRESP         : in    std_logic_vector(1 downto 0);
            F_RLAST         : in    std_logic;
            F_RVALID        : in    std_logic;
            F_RREADY        : out   std_logic;
        ---------------------------------------------------------------------------
        -- Descripter Fetch I/F AXI4 Write Address Channel Signals.
        ---------------------------------------------------------------------------
            F_AWID          : out   std_logic_vector(F_ID_WIDTH    -1 downto 0);
            F_AWADDR        : out   std_logic_vector(F_ADDR_WIDTH  -1 downto 0);
            F_AWLEN         : out   std_logic_vector(F_ALEN_WIDTH  -1 downto 0);
            F_AWSIZE        : out   std_logic_vector(2 downto 0);
            F_AWBURST       : out   std_logic_vector(1 downto 0);
            F_AWLOCK        : out   std_logic_vector(F_ALOCK_WIDTH -1 downto 0);
            F_AWCACHE       : out   std_logic_vector(3 downto 0);
            F_AWPROT        : out   std_logic_vector(2 downto 0);
            F_AWQOS         : out   std_logic_vector(3 downto 0);
            F_AWREGION      : out   std_logic_vector(3 downto 0);
            F_AWUSER        : out   std_logic_vector(F_AUSER_WIDTH -1 downto 0);
            F_AWVALID       : out   std_logic;
            F_AWREADY       : in    std_logic;
        ---------------------------------------------------------------------------
        -- Descripter Fetch I/F AXI4 Write Data Channel Signals.
        ---------------------------------------------------------------------------
            F_WDATA         : out   std_logic_vector(F_DATA_WIDTH  -1 downto 0);
            F_WSTRB         : out   std_logic_vector(F_DATA_WIDTH/8-1 downto 0);
            F_WLAST         : out   std_logic;
            F_WVALID        : out   std_logic;
            F_WREADY        : in    std_logic;
        ---------------------------------------------------------------------------
        -- Descripter Fetch I/F AXI4 Write Response Channel Signals.
        ---------------------------------------------------------------------------
            F_BID           : in    std_logic_vector(F_ID_WIDTH    -1 downto 0);
            F_BRESP         : in    std_logic_vector(1 downto 0);
            F_BVALID        : in    std_logic;
            F_BREADY        : out   std_logic;
        ---------------------------------------------------------------------------
        -- MMU Slave I/F Clock.
        ---------------------------------------------------------------------------
            S_CLK           : in    std_logic;
        ---------------------------------------------------------------------------
        -- MMU Slave I/F AXI4 Read Address Channel Signals.
        ---------------------------------------------------------------------------
            S_ARID          : in    std_logic_vector(S_ID_WIDTH    -1 downto 0);
            S_ARUSER        : in    std_logic_vector(S_AUSER_WIDTH -1 downto 0);
            S_ARADDR        : in    std_logic_vector(S_ADDR_WIDTH  -1 downto 0);
            S_ARLEN         : in    std_logic_vector(S_ALEN_WIDTH  -1 downto 0);
            S_ARSIZE        : in    std_logic_vector(2 downto 0);
            S_ARBURST       : in    std_logic_vector(1 downto 0);
            S_ARLOCK        : in    std_logic_vector(S_ALOCK_WIDTH -1 downto 0);
            S_ARCACHE       : in    std_logic_vector(3 downto 0);
            S_ARPROT        : in    std_logic_vector(2 downto 0);
            S_ARQOS         : in    std_logic_vector(3 downto 0);
            S_ARREGION      : in    std_logic_vector(3 downto 0);
            S_ARVALID       : in    std_logic;
            S_ARREADY       : out   std_logic;
        ---------------------------------------------------------------------------
        -- MMU Slave I/F AXI4 Read Data Channel Signals.
        ---------------------------------------------------------------------------
            S_RID           : out   std_logic_vector(S_ID_WIDTH    -1 downto 0);
            S_RDATA         : out   std_logic_vector(S_DATA_WIDTH  -1 downto 0);
            S_RRESP         : out   std_logic_vector(1 downto 0);
            S_RLAST         : out   std_logic;
            S_RVALID        : out   std_logic;
            S_RREADY        : in    std_logic;
        ---------------------------------------------------------------------------
        -- MMU Slave I/F AXI4 Write Address Channel Signals.
        ---------------------------------------------------------------------------
            S_AWID          : in    std_logic_vector(S_ID_WIDTH    -1 downto 0);
            S_AWUSER        : in    std_logic_vector(S_AUSER_WIDTH -1 downto 0);
            S_AWADDR        : in    std_logic_vector(S_ADDR_WIDTH  -1 downto 0);
            S_AWLEN         : in    std_logic_vector(S_ALEN_WIDTH  -1 downto 0);
            S_AWSIZE        : in    std_logic_vector(2 downto 0);
            S_AWBURST       : in    std_logic_vector(1 downto 0);
            S_AWLOCK        : in    std_logic_vector(S_ALOCK_WIDTH -1 downto 0);
            S_AWCACHE       : in    std_logic_vector(3 downto 0);
            S_AWPROT        : in    std_logic_vector(2 downto 0);
            S_AWQOS         : in    std_logic_vector(3 downto 0);
            S_AWREGION      : in    std_logic_vector(3 downto 0);
            S_AWVALID       : in    std_logic;
            S_AWREADY       : out   std_logic;
        ---------------------------------------------------------------------------
        -- MMU Slave I/F AXI4 Write Data Channel Signals.
        ---------------------------------------------------------------------------
            S_WDATA         : in    std_logic_vector(S_DATA_WIDTH  -1 downto 0);
            S_WSTRB         : in    std_logic_vector(S_DATA_WIDTH/8-1 downto 0);
            S_WLAST         : in    std_logic;
            S_WVALID        : in    std_logic;
            S_WREADY        : out   std_logic;
        ---------------------------------------------------------------------------
        -- MMU Slave I/F AXI4 Write Response Channel Signals.
        ---------------------------------------------------------------------------
            S_BID           : out   std_logic_vector(S_ID_WIDTH    -1 downto 0);
            S_BRESP         : out   std_logic_vector(1 downto 0);
            S_BVALID        : out   std_logic;
            S_BREADY        : in    std_logic;
        ---------------------------------------------------------------------------
        -- MMU Master I/F Clock.
        ---------------------------------------------------------------------------
            M_CLK           : in    std_logic;
        ---------------------------------------------------------------------------
        -- MMU Master I/F AXI4 Read Address Channel Signals.
        ---------------------------------------------------------------------------
            M_ARID          : out   std_logic_vector(M_ID_WIDTH    -1 downto 0);
            M_ARUSER        : out   std_logic_vector(M_AUSER_WIDTH -1 downto 0);
            M_ARADDR        : out   std_logic_vector(M_ADDR_WIDTH  -1 downto 0);
            M_ARLEN         : out   std_logic_vector(M_ALEN_WIDTH  -1 downto 0);
            M_ARSIZE        : out   std_logic_vector(2 downto 0);
            M_ARBURST       : out   std_logic_vector(1 downto 0);
            M_ARLOCK        : out   std_logic_vector(M_ALOCK_WIDTH -1 downto 0);
            M_ARCACHE       : out   std_logic_vector(3 downto 0);
            M_ARPROT        : out   std_logic_vector(2 downto 0);
            M_ARQOS         : out   std_logic_vector(3 downto 0);
            M_ARREGION      : out   std_logic_vector(3 downto 0);
            M_ARVALID       : out   std_logic;
            M_ARREADY       : in    std_logic;
        ---------------------------------------------------------------------------
        -- MMU Master I/F AXI4 Read Data Channel Signals.
        ---------------------------------------------------------------------------
            M_RID           : in    std_logic_vector(M_ID_WIDTH    -1 downto 0);
            M_RDATA         : in    std_logic_vector(M_DATA_WIDTH  -1 downto 0);
            M_RRESP         : in    std_logic_vector(1 downto 0);
            M_RLAST         : in    std_logic;
            M_RVALID        : in    std_logic;
            M_RREADY        : out   std_logic;
        ---------------------------------------------------------------------------
        -- MMU Master I/F AXI4 Write Address Channel Signals.
        ---------------------------------------------------------------------------
            M_AWID          : out   std_logic_vector(M_ID_WIDTH    -1 downto 0);
            M_AWUSER        : out   std_logic_vector(M_AUSER_WIDTH -1 downto 0);
            M_AWADDR        : out   std_logic_vector(M_ADDR_WIDTH  -1 downto 0);
            M_AWLEN         : out   std_logic_vector(M_ALEN_WIDTH  -1 downto 0);
            M_AWSIZE        : out   std_logic_vector(2 downto 0);
            M_AWBURST       : out   std_logic_vector(1 downto 0);
            M_AWLOCK        : out   std_logic_vector(M_ALOCK_WIDTH -1 downto 0);
            M_AWCACHE       : out   std_logic_vector(3 downto 0);
            M_AWPROT        : out   std_logic_vector(2 downto 0);
            M_AWQOS         : out   std_logic_vector(3 downto 0);
            M_AWREGION      : out   std_logic_vector(3 downto 0);
            M_AWVALID       : out   std_logic;
            M_AWREADY       : in    std_logic;
        ---------------------------------------------------------------------------
        -- MMU Master I/F AXI4 Write Data Channel Signals.
        ---------------------------------------------------------------------------
            M_WDATA         : out   std_logic_vector(M_DATA_WIDTH  -1 downto 0);
            M_WSTRB         : out   std_logic_vector(M_DATA_WIDTH/8-1 downto 0);
            M_WLAST         : out   std_logic;
            M_WVALID        : out   std_logic;
            M_WREADY        : in    std_logic;
        ---------------------------------------------------------------------------
        -- MMU Master I/F AXI4 Write Response Channel Signals.
        ---------------------------------------------------------------------------
            M_BID           : in    std_logic_vector(M_ID_WIDTH    -1 downto 0);
            M_BRESP         : in    std_logic_vector(1 downto 0);
            M_BVALID        : in    std_logic;
            M_BREADY        : out   std_logic
        );
    end component;
begin
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    DUT: MMU_AXI                                 -- 
        generic map (                            -- 
            READ_ENABLE     => READ_ENABLE     , -- : integer :=  1;
            WRITE_ENABLE    => WRITE_ENABLE    , -- : integer :=  1;
            PAGE_SIZE       => PAGE_SIZE       , -- : integer := 12;
            DESC_SIZE       => DESC_SIZE       , -- : integer :=  2;
            TLB_TAG_SETS    => TLB_TAG_SETS    , -- : integer :=  2;
            TLB_TAG_WAYS    => TLB_TAG_WAYS    , -- : integer :=  3;
            M_QUEUE_SIZE    => M_QUEUE_SIZE    , -- : integer :=  0;
            M_AR_QUEUE_SIZE => M_AR_QUEUE_SIZE , -- : integer :=  1;
            M_AW_QUEUE_SIZE => M_AW_QUEUE_SIZE , -- : integer :=  1;
            M_RD_QUEUE_SIZE => M_RD_QUEUE_SIZE , -- : integer :=  4;
            M_WD_QUEUE_SIZE => M_WD_QUEUE_SIZE , -- : integer :=  4;
            M_WB_QUEUE_SIZE => M_WB_QUEUE_SIZE , -- : integer :=  4;
            S_ADDR_WIDTH    => S_WIDTH.ARADDR  , -- : integer := 32;
            S_ALEN_WIDTH    => S_WIDTH.ALEN    , -- : integer :=  8;
            S_ALOCK_WIDTH   => S_WIDTH.ALOCK   , -- : integer :=  1;
            S_AUSER_WIDTH   => S_WIDTH.ARUSER  , -- : integer :=  1;
            S_ID_WIDTH      => S_WIDTH.ID      , -- : integer :=  4;
            S_DATA_WIDTH    => S_WIDTH.RDATA   , -- : integer := 32;
            M_ADDR_WIDTH    => M_WIDTH.ARADDR  , -- : integer := 32;
            M_ALEN_WIDTH    => M_WIDTH.ALEN    , -- : integer :=  8;
            M_ALOCK_WIDTH   => M_WIDTH.ALOCK   , -- : integer :=  1;
            M_AUSER_WIDTH   => M_WIDTH.ARUSER  , -- : integer :=  1;
            M_ID_WIDTH      => M_WIDTH.ID      , -- : integer :=  4;
            M_DATA_WIDTH    => M_WIDTH.RDATA   , -- : integer := 32;
            F_ADDR_WIDTH    => F_WIDTH.ARADDR  , -- : integer := 32;
            F_ALEN_WIDTH    => F_WIDTH.ALEN    , -- : integer :=  8;
            F_ALOCK_WIDTH   => F_WIDTH.ALOCK   , -- : integer :=  1;
            F_AUSER_WIDTH   => F_WIDTH.ARUSER  , -- : integer :=  1;
            F_ID_WIDTH      => F_WIDTH.ID      , -- : integer :=  4;
            F_DATA_WIDTH    => F_WIDTH.RDATA   , -- : integer := 32;
            C_ADDR_WIDTH    => C_WIDTH.ARADDR  , -- : integer := 32;
            C_ALEN_WIDTH    => C_WIDTH.ALEN    , -- : integer :=  8;
            C_ID_WIDTH      => C_WIDTH.ID      , -- : integer :=  4;
            C_DATA_WIDTH    => C_WIDTH.RDATA     -- : integer := 32
        )                                        -- 
        port map (                               -- 
        ---------------------------------------------------------------------------
        -- Reset Signals.
        ---------------------------------------------------------------------------
            ARESETn         => ARESETn         , -- In  :
        ---------------------------------------------------------------------------
        -- Control Status Register I/F Clock.
        ---------------------------------------------------------------------------
            C_CLK           => ACLK            , -- In  :
        ---------------------------------------------------------------------------
        -- Control Status Register I/F AXI4 Read Address Channel Signals.
        ---------------------------------------------------------------------------
            C_ARID          => C_ARID          , -- In  :
            C_ARADDR        => C_ARADDR        , -- In  :
            C_ARLEN         => C_ARLEN         , -- In  :
            C_ARSIZE        => C_ARSIZE        , -- In  :
            C_ARBURST       => C_ARBURST       , -- In  :
            C_ARVALID       => C_ARVALID       , -- In  :
            C_ARREADY       => C_ARREADY       , -- Out :
        ---------------------------------------------------------------------------
        -- Control Status Register I/F AXI4 Read Data Channel Signals.
        ---------------------------------------------------------------------------
            C_RID           => C_RID           , -- Out :
            C_RDATA         => C_RDATA         , -- Out :
            C_RRESP         => C_RRESP         , -- Out :
            C_RLAST         => C_RLAST         , -- Out :
            C_RVALID        => C_RVALID        , -- Out :
            C_RREADY        => C_RREADY        , -- In  :
        ---------------------------------------------------------------------------
        -- Control Status Register I/F AXI4 Write Address Channel Signals.
        ---------------------------------------------------------------------------
            C_AWID          => C_AWID          , -- In  :
            C_AWADDR        => C_AWADDR        , -- In  :
            C_AWLEN         => C_AWLEN         , -- In  :
            C_AWSIZE        => C_AWSIZE        , -- In  :
            C_AWBURST       => C_AWBURST       , -- In  :
            C_AWVALID       => C_AWVALID       , -- In  :
            C_AWREADY       => C_AWREADY       , -- Out :
        ---------------------------------------------------------------------------
        -- Control Status Register I/F AXI4 Write Data Channel Signals.
        ---------------------------------------------------------------------------
            C_WDATA         => C_WDATA         , -- In  :
            C_WSTRB         => C_WSTRB         , -- In  :
            C_WLAST         => C_WLAST         , -- In  :
            C_WVALID        => C_WVALID        , -- In  :
            C_WREADY        => C_WREADY        , -- Out :
        ---------------------------------------------------------------------------
        -- Control Status Register I/F AXI4 Write Response Channel Signals.
        ---------------------------------------------------------------------------
            C_BID           => C_BID           , -- Out :
            C_BRESP         => C_BRESP         , -- Out :
            C_BVALID        => C_BVALID        , -- Out :
            C_BREADY        => C_BREADY        , -- In  :
        ---------------------------------------------------------------------------
        -- Descripter Fetch I/F Clock.
        ---------------------------------------------------------------------------
            F_CLK           => ACLK            , -- In  :
        ---------------------------------------------------------------------------
        -- Descripter Fetch I/F AXI4 Read Address Channel Signals.
        ---------------------------------------------------------------------------
            F_ARID          => F_ARID          , -- Out :
            F_ARADDR        => F_ARADDR        , -- Out :
            F_ARLEN         => F_ARLEN         , -- Out :
            F_ARSIZE        => F_ARSIZE        , -- Out :
            F_ARBURST       => F_ARBURST       , -- Out :
            F_ARLOCK        => F_ARLOCK        , -- Out :
            F_ARCACHE       => F_ARCACHE       , -- Out :
            F_ARPROT        => F_ARPROT        , -- Out :
            F_ARQOS         => F_ARQOS         , -- Out :
            F_ARREGION      => F_ARREGION      , -- Out :
            F_ARUSER        => F_ARUSER        , -- Out :
            F_ARVALID       => F_ARVALID       , -- Out :
            F_ARREADY       => F_ARREADY       , -- In  :
        ---------------------------------------------------------------------------
        -- Descripter Fetch I/F AXI4 Read Data Channel Signals.
        ---------------------------------------------------------------------------
            F_RID           => F_RID           , -- In  :
            F_RDATA         => F_RDATA         , -- In  :
            F_RRESP         => F_RRESP         , -- In  :
            F_RLAST         => F_RLAST         , -- In  :
            F_RVALID        => F_RVALID        , -- In  :
            F_RREADY        => F_RREADY        , -- Out :
        ---------------------------------------------------------------------------
        -- Descripter Fetch I/F AXI4 Write Address Channel Signals.
        ---------------------------------------------------------------------------
            F_AWID          => F_AWID          , -- Out :
            F_AWADDR        => F_AWADDR        , -- Out :
            F_AWLEN         => F_AWLEN         , -- Out :
            F_AWSIZE        => F_AWSIZE        , -- Out :
            F_AWBURST       => F_AWBURST       , -- Out :
            F_AWLOCK        => F_AWLOCK        , -- Out :
            F_AWCACHE       => F_AWCACHE       , -- Out :
            F_AWPROT        => F_AWPROT        , -- Out :
            F_AWQOS         => F_AWQOS         , -- Out :
            F_AWREGION      => F_AWREGION      , -- Out :
            F_AWUSER        => F_AWUSER        , -- Out :
            F_AWVALID       => F_AWVALID       , -- Out :
            F_AWREADY       => F_AWREADY       , -- In  :
        ---------------------------------------------------------------------------
        -- Descripter Fetch I/F AXI4 Write Data Channel Signals.
        ---------------------------------------------------------------------------
            F_WDATA         => F_WDATA         , -- Out :
            F_WSTRB         => F_WSTRB         , -- Out :
            F_WLAST         => F_WLAST         , -- Out :
            F_WVALID        => F_WVALID        , -- Out :
            F_WREADY        => F_WREADY        , -- In  :
        ---------------------------------------------------------------------------
        -- Descripter Fetch I/F AXI4 Write Response Channel Signals.
        ---------------------------------------------------------------------------
            F_BID           => F_BID           , -- In  :
            F_BRESP         => F_BRESP         , -- In  :
            F_BVALID        => F_BVALID        , -- In  :
            F_BREADY        => F_BREADY        , -- Out :
        ---------------------------------------------------------------------------
        -- MMU Slave I/F Clock.
        ---------------------------------------------------------------------------
            S_CLK           => ACLK            , -- In  :
        ---------------------------------------------------------------------------
        -- MMU Slave I/F AXI4 Read Address Channel Signals.
        ---------------------------------------------------------------------------
            S_ARID          => S_ARID          , -- In  :
            S_ARUSER        => S_ARUSER        , -- In  :
            S_ARADDR        => S_ARADDR        , -- In  :
            S_ARLEN         => S_ARLEN         , -- In  :
            S_ARSIZE        => S_ARSIZE        , -- In  :
            S_ARBURST       => S_ARBURST       , -- In  :
            S_ARLOCK        => S_ARLOCK        , -- In  :
            S_ARCACHE       => S_ARCACHE       , -- In  :
            S_ARPROT        => S_ARPROT        , -- In  :
            S_ARQOS         => S_ARQOS         , -- In  :
            S_ARREGION      => S_ARREGION      , -- In  :
            S_ARVALID       => S_ARVALID       , -- In  :
            S_ARREADY       => S_ARREADY       , -- Out :
        ---------------------------------------------------------------------------
        -- MMU Slave I/F AXI4 Read Data Channel Signals.
        ---------------------------------------------------------------------------
            S_RID           => S_RID           , -- Out :
            S_RDATA         => S_RDATA         , -- Out :
            S_RRESP         => S_RRESP         , -- Out :
            S_RLAST         => S_RLAST         , -- Out :
            S_RVALID        => S_RVALID        , -- Out :
            S_RREADY        => S_RREADY        , -- In  :
        ---------------------------------------------------------------------------
        -- MMU Slave I/F AXI4 Write Address Channel Signals.
        ---------------------------------------------------------------------------
            S_AWID          => S_AWID          , -- In  :
            S_AWUSER        => S_AWUSER        , -- In  :
            S_AWADDR        => S_AWADDR        , -- In  :
            S_AWLEN         => S_AWLEN         , -- In  :
            S_AWSIZE        => S_AWSIZE        , -- In  :
            S_AWBURST       => S_AWBURST       , -- In  :
            S_AWLOCK        => S_AWLOCK        , -- In  :
            S_AWCACHE       => S_AWCACHE       , -- In  :
            S_AWPROT        => S_AWPROT        , -- In  :
            S_AWQOS         => S_AWQOS         , -- In  :
            S_AWREGION      => S_AWREGION      , -- In  :
            S_AWVALID       => S_AWVALID       , -- In  :
            S_AWREADY       => S_AWREADY       , -- Out :
        ---------------------------------------------------------------------------
        -- MMU Slave I/F AXI4 Write Data Channel Signals.
        ---------------------------------------------------------------------------
            S_WDATA         => S_WDATA         , -- In  :
            S_WSTRB         => S_WSTRB         , -- In  :
            S_WLAST         => S_WLAST         , -- In  :
            S_WVALID        => S_WVALID        , -- In  :
            S_WREADY        => S_WREADY        , -- Out :
        ---------------------------------------------------------------------------
        -- MMU Slave I/F AXI4 Write Response Channel Signals.
        ---------------------------------------------------------------------------
            S_BID           => S_BID           , -- Out :
            S_BRESP         => S_BRESP         , -- Out :
            S_BVALID        => S_BVALID        , -- Out :
            S_BREADY        => S_BREADY        , -- In  :
        ---------------------------------------------------------------------------
        -- MMU Master I/F Clock.
        ---------------------------------------------------------------------------
            M_CLK           => ACLK            , -- In  :
        ---------------------------------------------------------------------------
        -- MMU Master I/F AXI4 Read Address Channel Signals.
        ---------------------------------------------------------------------------
            M_ARID          => M_ARID          , -- Out :
            M_ARUSER        => M_ARUSER        , -- Out :
            M_ARADDR        => M_ARADDR        , -- Out :
            M_ARLEN         => M_ARLEN         , -- Out :
            M_ARSIZE        => M_ARSIZE        , -- Out :
            M_ARBURST       => M_ARBURST       , -- Out :
            M_ARLOCK        => M_ARLOCK        , -- Out :
            M_ARCACHE       => M_ARCACHE       , -- Out :
            M_ARPROT        => M_ARPROT        , -- Out :
            M_ARQOS         => M_ARQOS         , -- Out :
            M_ARREGION      => M_ARREGION      , -- Out :
            M_ARVALID       => M_ARVALID       , -- Out :
            M_ARREADY       => M_ARREADY       , -- In  :
        ---------------------------------------------------------------------------
        -- MMU Master I/F AXI4 Read Data Channel Signals.
        ---------------------------------------------------------------------------
            M_RID           => M_RID           , -- In  :
            M_RDATA         => M_RDATA         , -- In  :
            M_RRESP         => M_RRESP         , -- In  :
            M_RLAST         => M_RLAST         , -- In  :
            M_RVALID        => M_RVALID        , -- In  :
            M_RREADY        => M_RREADY        , -- Out :
        ---------------------------------------------------------------------------
        -- MMU Master I/F AXI4 Write Address Channel Signals.
        ---------------------------------------------------------------------------
            M_AWID          => M_AWID          , -- Out :
            M_AWUSER        => M_AWUSER        , -- Out :
            M_AWADDR        => M_AWADDR        , -- Out :
            M_AWLEN         => M_AWLEN         , -- Out :
            M_AWSIZE        => M_AWSIZE        , -- Out :
            M_AWBURST       => M_AWBURST       , -- Out :
            M_AWLOCK        => M_AWLOCK        , -- Out :
            M_AWCACHE       => M_AWCACHE       , -- Out :
            M_AWPROT        => M_AWPROT        , -- Out :
            M_AWQOS         => M_AWQOS         , -- Out :
            M_AWREGION      => M_AWREGION      , -- Out :
            M_AWVALID       => M_AWVALID       , -- Out :
            M_AWREADY       => M_AWREADY       , -- In  :
        ---------------------------------------------------------------------------
        -- MMU Master I/F AXI4 Write Data Channel Signals.
        ---------------------------------------------------------------------------
            M_WDATA         => M_WDATA         , -- Out :
            M_WSTRB         => M_WSTRB         , -- Out :
            M_WLAST         => M_WLAST         , -- Out :
            M_WVALID        => M_WVALID        , -- Out :
            M_WREADY        => M_WREADY        , -- In  :
        ---------------------------------------------------------------------------
        -- MMU Master I/F AXI4 Write Response Channel Signals.
        ---------------------------------------------------------------------------
            M_BID           => M_BID           , -- In  :
            M_BRESP         => M_BRESP         , -- In  :
            M_BVALID        => M_BVALID        , -- In  :
            M_BREADY        => M_BREADY         -- Out :
        );
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    N: MARCHAL
        generic map(
            SCENARIO_FILE   => SCENARIO_FILE,
            NAME            => "MARCHAL",
            SYNC_PLUG_NUM   => 1,
            SYNC_WIDTH      => SYNC_WIDTH,
            FINISH_ABORT    => FALSE
        )
        port map(
            CLK             => ACLK            , -- In  :
            RESET           => RESET           , -- In  :
            SYNC(0)         => SYNC(0)         , -- I/O :
            SYNC(1)         => SYNC(1)         , -- I/O :
            REPORT_STATUS   => N_REPORT        , -- Out :
            FINISH          => N_FINISH          -- Out :
        );
    ------------------------------------------------------------------------------
    -- AXI4_MASTER_PLAYER
    ------------------------------------------------------------------------------
    C: AXI4_MASTER_PLAYER
        generic map (
            SCENARIO_FILE   => SCENARIO_FILE   ,
            NAME            => "CSR"           ,
            READ_ENABLE     => TRUE            ,
            WRITE_ENABLE    => TRUE            ,
            OUTPUT_DELAY    => DELAY           ,
            WIDTH           => C_WIDTH         ,
            SYNC_PLUG_NUM   => 2               ,
            SYNC_WIDTH      => SYNC_WIDTH      ,
            GPI_WIDTH       => GPI_WIDTH       ,
            GPO_WIDTH       => GPO_WIDTH       ,
            FINISH_ABORT    => FALSE
        )
        port map(
        ---------------------------------------------------------------------------
        -- グローバルシグナル.
        ---------------------------------------------------------------------------
            ACLK            => ACLK            , -- In  :
            ARESETn         => ARESETn         , -- In  :
        ---------------------------------------------------------------------------
        -- リードアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            ARADDR          => C_ARADDR        , -- I/O : 
            ARLEN           => C_ARLEN         , -- I/O : 
            ARSIZE          => C_ARSIZE        , -- I/O : 
            ARBURST         => C_ARBURST       , -- I/O : 
            ARLOCK          => C_ARLOCK        , -- I/O : 
            ARCACHE         => C_ARCACHE       , -- I/O : 
            ARPROT          => C_ARPROT        , -- I/O : 
            ARQOS           => C_ARQOS         , -- I/O : 
            ARREGION        => C_ARREGION      , -- I/O : 
            ARUSER          => C_ARUSER        , -- I/O : 
            ARID            => C_ARID          , -- I/O : 
            ARVALID         => C_ARVALID       , -- I/O : 
            ARREADY         => C_ARREADY       , -- In  :    
        ---------------------------------------------------------------------------
        -- リードデータチャネルシグナル.
        ---------------------------------------------------------------------------
            RLAST           => C_RLAST         , -- In  :    
            RDATA           => C_RDATA         , -- In  :    
            RRESP           => C_RRESP         , -- In  :    
            RUSER           => C_RUSER         , -- In  :    
            RID             => C_RID           , -- In  :    
            RVALID          => C_RVALID        , -- In  :    
            RREADY          => C_RREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- ライトアドレスチャネルシグナル.
        --------------------------------------------------------------------------
            AWADDR          => C_AWADDR        , -- I/O : 
            AWLEN           => C_AWLEN         , -- I/O : 
            AWSIZE          => C_AWSIZE        , -- I/O : 
            AWBURST         => C_AWBURST       , -- I/O : 
            AWLOCK          => C_AWLOCK        , -- I/O : 
            AWCACHE         => C_AWCACHE       , -- I/O : 
            AWPROT          => C_AWPROT        , -- I/O : 
            AWQOS           => C_AWQOS         , -- I/O : 
            AWREGION        => C_AWREGION      , -- I/O : 
            AWUSER          => C_AWUSER        , -- I/O : 
            AWID            => C_AWID          , -- I/O : 
            AWVALID         => C_AWVALID       , -- I/O : 
            AWREADY         => C_AWREADY       , -- In  :    
        --------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        --------------------------------------------------------------------------
            WLAST           => C_WLAST         , -- I/O : 
            WDATA           => C_WDATA         , -- I/O : 
            WSTRB           => C_WSTRB         , -- I/O : 
            WUSER           => C_WUSER         , -- I/O : 
            WID             => C_WID           , -- I/O : 
            WVALID          => C_WVALID        , -- I/O : 
            WREADY          => C_WREADY        , -- In  :    
        --------------------------------------------------------------------------
        -- ライト応答チャネルシグナル.
        --------------------------------------------------------------------------
            BRESP           => C_BRESP         , -- In  :    
            BUSER           => C_BUSER         , -- In  :    
            BID             => C_BID           , -- In  :    
            BVALID          => C_BVALID        , -- In  :    
            BREADY          => C_BREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- シンクロ用信号
        --------------------------------------------------------------------------
            SYNC(0)         => SYNC(0)         , -- I/O :
            SYNC(1)         => SYNC(1)         , -- I/O :
        --------------------------------------------------------------------------
        -- GPIO
        --------------------------------------------------------------------------
            GPI             => C_GPI           , -- In  :
            GPO             => C_GPO           , -- Out :
        --------------------------------------------------------------------------
        -- 各種状態出力.
        --------------------------------------------------------------------------
            REPORT_STATUS   => C_REPORT        , -- Out :
            FINISH          => C_FINISH          -- Out :
        );
    ------------------------------------------------------------------------------
    -- AXI4_SLAVE_PLAYER
    ------------------------------------------------------------------------------
    F: AXI4_SLAVE_PLAYER
        generic map (
            SCENARIO_FILE   => SCENARIO_FILE   ,
            NAME            => "F"             ,
            READ_ENABLE     => TRUE            ,
            WRITE_ENABLE    => TRUE            ,
            OUTPUT_DELAY    => DELAY           ,
            WIDTH           => F_WIDTH         ,
            SYNC_PLUG_NUM   => 3               ,
            SYNC_WIDTH      => SYNC_WIDTH      ,
            GPI_WIDTH       => GPI_WIDTH       ,
            GPO_WIDTH       => GPO_WIDTH       ,
            FINISH_ABORT    => FALSE
        )
        port map(
        ---------------------------------------------------------------------------
        -- グローバルシグナル.
        ---------------------------------------------------------------------------
            ACLK            => ACLK            , -- In  :
            ARESETn         => ARESETn         , -- In  :
        ---------------------------------------------------------------------------
        -- リードアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            ARADDR          => F_ARADDR        , -- In  :    
            ARLEN           => F_ARLEN         , -- In  :    
            ARSIZE          => F_ARSIZE        , -- In  :    
            ARBURST         => F_ARBURST       , -- In  :    
            ARLOCK          => F_ARLOCK        , -- In  :    
            ARCACHE         => F_ARCACHE       , -- In  :    
            ARPROT          => F_ARPROT        , -- In  :    
            ARQOS           => F_ARQOS         , -- In  :    
            ARREGION        => F_ARREGION      , -- In  :    
            ARUSER          => F_ARUSER        , -- In  :    
            ARID            => F_ARID          , -- In  :    
            ARVALID         => F_ARVALID       , -- In  :    
            ARREADY         => F_ARREADY       , -- I/O : 
        ---------------------------------------------------------------------------
        -- リードデータチャネルシグナル.
        ---------------------------------------------------------------------------
            RLAST           => F_RLAST         , -- I/O : 
            RDATA           => F_RDATA         , -- I/O : 
            RRESP           => F_RRESP         , -- I/O : 
            RUSER           => F_RUSER         , -- I/O : 
            RID             => F_RID           , -- I/O : 
            RVALID          => F_RVALID        , -- I/O : 
            RREADY          => F_RREADY        , -- In  :    
        ---------------------------------------------------------------------------
        -- ライトアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            AWADDR          => F_AWADDR        , -- In  :    
            AWLEN           => F_AWLEN         , -- In  :    
            AWSIZE          => F_AWSIZE        , -- In  :    
            AWBURST         => F_AWBURST       , -- In  :    
            AWLOCK          => F_AWLOCK        , -- In  :    
            AWCACHE         => F_AWCACHE       , -- In  :    
            AWPROT          => F_AWPROT        , -- In  :    
            AWQOS           => F_AWQOS         , -- In  :    
            AWREGION        => F_AWREGION      , -- In  :    
            AWUSER          => F_AWUSER        , -- In  :    
            AWID            => F_AWID          , -- In  :    
            AWVALID         => F_AWVALID       , -- In  :    
            AWREADY         => F_AWREADY       , -- I/O : 
        ---------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        ---------------------------------------------------------------------------
            WLAST           => F_WLAST         , -- In  :    
            WDATA           => F_WDATA         , -- In  :    
            WSTRB           => F_WSTRB         , -- In  :    
            WUSER           => F_WUSER         , -- In  :    
            WID             => F_WID           , -- In  :    
            WVALID          => F_WVALID        , -- In  :    
            WREADY          => F_WREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- ライト応答チャネルシグナル.
        --------------------------------------------------------------------------
            BRESP           => F_BRESP         , -- I/O : 
            BUSER           => F_BUSER         , -- I/O : 
            BID             => F_BID           , -- I/O : 
            BVALID          => F_BVALID        , -- I/O : 
            BREADY          => F_BREADY        , -- In  :    
        ---------------------------------------------------------------------------
        -- シンクロ用信号
        ---------------------------------------------------------------------------
            SYNC(0)         => SYNC(0)         , -- I/O :
            SYNC(1)         => SYNC(1)         , -- I/O :
        --------------------------------------------------------------------------
        -- GPIO
        --------------------------------------------------------------------------
            GPI             => F_GPI           , -- In  :
            GPO             => F_GPO           , -- Out :
        --------------------------------------------------------------------------
        -- 各種状態出力.
        --------------------------------------------------------------------------
            REPORT_STATUS   => F_REPORT        , -- Out :
            FINISH          => F_FINISH          -- Out :
    );
    ------------------------------------------------------------------------------
    -- AXI4_MASTER_PLAYER
    ------------------------------------------------------------------------------
    S: AXI4_MASTER_PLAYER
        generic map (
            SCENARIO_FILE   => SCENARIO_FILE   ,
            NAME            => "CSR"           ,
            READ_ENABLE     => TRUE            ,
            WRITE_ENABLE    => TRUE            ,
            OUTPUT_DELAY    => DELAY           ,
            WIDTH           => S_WIDTH         ,
            SYNC_PLUG_NUM   => 4               ,
            SYNC_WIDTH      => SYNC_WIDTH      ,
            GPI_WIDTH       => GPI_WIDTH       ,
            GPO_WIDTH       => GPO_WIDTH       ,
            FINISH_ABORT    => FALSE
        )
        port map(
        ---------------------------------------------------------------------------
        -- グローバルシグナル.
        ---------------------------------------------------------------------------
            ACLK            => ACLK            , -- In  :
            ARESETn         => ARESETn         , -- In  :
        ---------------------------------------------------------------------------
        -- リードアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            ARADDR          => S_ARADDR        , -- I/O : 
            ARLEN           => S_ARLEN         , -- I/O : 
            ARSIZE          => S_ARSIZE        , -- I/O : 
            ARBURST         => S_ARBURST       , -- I/O : 
            ARLOCK          => S_ARLOCK        , -- I/O : 
            ARCACHE         => S_ARCACHE       , -- I/O : 
            ARPROT          => S_ARPROT        , -- I/O : 
            ARQOS           => S_ARQOS         , -- I/O : 
            ARREGION        => S_ARREGION      , -- I/O : 
            ARUSER          => S_ARUSER        , -- I/O : 
            ARID            => S_ARID          , -- I/O : 
            ARVALID         => S_ARVALID       , -- I/O : 
            ARREADY         => S_ARREADY       , -- In  :    
        ---------------------------------------------------------------------------
        -- リードデータチャネルシグナル.
        ---------------------------------------------------------------------------
            RLAST           => S_RLAST         , -- In  :    
            RDATA           => S_RDATA         , -- In  :    
            RRESP           => S_RRESP         , -- In  :    
            RUSER           => S_RUSER         , -- In  :    
            RID             => S_RID           , -- In  :    
            RVALID          => S_RVALID        , -- In  :    
            RREADY          => S_RREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- ライトアドレスチャネルシグナル.
        --------------------------------------------------------------------------
            AWADDR          => S_AWADDR        , -- I/O : 
            AWLEN           => S_AWLEN         , -- I/O : 
            AWSIZE          => S_AWSIZE        , -- I/O : 
            AWBURST         => S_AWBURST       , -- I/O : 
            AWLOCK          => S_AWLOCK        , -- I/O : 
            AWCACHE         => S_AWCACHE       , -- I/O : 
            AWPROT          => S_AWPROT        , -- I/O : 
            AWQOS           => S_AWQOS         , -- I/O : 
            AWREGION        => S_AWREGION      , -- I/O : 
            AWUSER          => S_AWUSER        , -- I/O : 
            AWID            => S_AWID          , -- I/O : 
            AWVALID         => S_AWVALID       , -- I/O : 
            AWREADY         => S_AWREADY       , -- In  :    
        --------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        --------------------------------------------------------------------------
            WLAST           => S_WLAST         , -- I/O : 
            WDATA           => S_WDATA         , -- I/O : 
            WSTRB           => S_WSTRB         , -- I/O : 
            WUSER           => S_WUSER         , -- I/O : 
            WID             => S_WID           , -- I/O : 
            WVALID          => S_WVALID        , -- I/O : 
            WREADY          => S_WREADY        , -- In  :    
        --------------------------------------------------------------------------
        -- ライト応答チャネルシグナル.
        --------------------------------------------------------------------------
            BRESP           => S_BRESP         , -- In  :    
            BUSER           => S_BUSER         , -- In  :    
            BID             => S_BID           , -- In  :    
            BVALID          => S_BVALID        , -- In  :    
            BREADY          => S_BREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- シンクロ用信号
        --------------------------------------------------------------------------
            SYNC(0)         => SYNC(0)         , -- I/O :
            SYNC(1)         => SYNC(1)         , -- I/O :
        --------------------------------------------------------------------------
        -- GPIO
        --------------------------------------------------------------------------
            GPI             => S_GPI           , -- In  :
            GPO             => S_GPO           , -- Out :
        --------------------------------------------------------------------------
        -- 各種状態出力.
        --------------------------------------------------------------------------
            REPORT_STATUS   => S_REPORT        , -- Out :
            FINISH          => S_FINISH          -- Out :
        );
    ------------------------------------------------------------------------------
    -- AXI4_SLAVE_PLAYER
    ------------------------------------------------------------------------------
    M: AXI4_SLAVE_PLAYER
        generic map (
            SCENARIO_FILE   => SCENARIO_FILE   ,
            NAME            => "MASTER"        ,
            READ_ENABLE     => TRUE            ,
            WRITE_ENABLE    => TRUE            ,
            OUTPUT_DELAY    => DELAY           ,
            WIDTH           => F_WIDTH         ,
            SYNC_PLUG_NUM   => 5               ,
            SYNC_WIDTH      => SYNC_WIDTH      ,
            GPI_WIDTH       => GPI_WIDTH       ,
            GPO_WIDTH       => GPO_WIDTH       ,
            FINISH_ABORT    => FALSE
        )
        port map(
        ---------------------------------------------------------------------------
        -- グローバルシグナル.
        ---------------------------------------------------------------------------
            ACLK            => ACLK            , -- In  :
            ARESETn         => ARESETn         , -- In  :
        ---------------------------------------------------------------------------
        -- リードアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            ARADDR          => M_ARADDR        , -- In  :    
            ARLEN           => M_ARLEN         , -- In  :    
            ARSIZE          => M_ARSIZE        , -- In  :    
            ARBURST         => M_ARBURST       , -- In  :    
            ARLOCK          => M_ARLOCK        , -- In  :    
            ARCACHE         => M_ARCACHE       , -- In  :    
            ARPROT          => M_ARPROT        , -- In  :    
            ARQOS           => M_ARQOS         , -- In  :    
            ARREGION        => M_ARREGION      , -- In  :    
            ARUSER          => M_ARUSER        , -- In  :    
            ARID            => M_ARID          , -- In  :    
            ARVALID         => M_ARVALID       , -- In  :    
            ARREADY         => M_ARREADY       , -- I/O : 
        ---------------------------------------------------------------------------
        -- リードデータチャネルシグナル.
        ---------------------------------------------------------------------------
            RLAST           => M_RLAST         , -- I/O : 
            RDATA           => M_RDATA         , -- I/O : 
            RRESP           => M_RRESP         , -- I/O : 
            RUSER           => M_RUSER         , -- I/O : 
            RID             => M_RID           , -- I/O : 
            RVALID          => M_RVALID        , -- I/O : 
            RREADY          => M_RREADY        , -- In  :    
        ---------------------------------------------------------------------------
        -- ライトアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            AWADDR          => M_AWADDR        , -- In  :    
            AWLEN           => M_AWLEN         , -- In  :    
            AWSIZE          => M_AWSIZE        , -- In  :    
            AWBURST         => M_AWBURST       , -- In  :    
            AWLOCK          => M_AWLOCK        , -- In  :    
            AWCACHE         => M_AWCACHE       , -- In  :    
            AWPROT          => M_AWPROT        , -- In  :    
            AWQOS           => M_AWQOS         , -- In  :    
            AWREGION        => M_AWREGION      , -- In  :    
            AWUSER          => M_AWUSER        , -- In  :    
            AWID            => M_AWID          , -- In  :    
            AWVALID         => M_AWVALID       , -- In  :    
            AWREADY         => M_AWREADY       , -- I/O : 
        ---------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        ---------------------------------------------------------------------------
            WLAST           => M_WLAST         , -- In  :    
            WDATA           => M_WDATA         , -- In  :    
            WSTRB           => M_WSTRB         , -- In  :    
            WUSER           => M_WUSER         , -- In  :    
            WID             => M_WID           , -- In  :    
            WVALID          => M_WVALID        , -- In  :    
            WREADY          => M_WREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- ライト応答チャネルシグナル.
        --------------------------------------------------------------------------
            BRESP           => M_BRESP         , -- I/O : 
            BUSER           => M_BUSER         , -- I/O : 
            BID             => M_BID           , -- I/O : 
            BVALID          => M_BVALID        , -- I/O : 
            BREADY          => M_BREADY        , -- In  :    
        ---------------------------------------------------------------------------
        -- シンクロ用信号
        ---------------------------------------------------------------------------
            SYNC(0)         => SYNC(0)         , -- I/O :
            SYNC(1)         => SYNC(1)         , -- I/O :
        --------------------------------------------------------------------------
        -- GPIO
        --------------------------------------------------------------------------
            GPI             => M_GPI           , -- In  :
            GPO             => M_GPO           , -- Out :
        --------------------------------------------------------------------------
        -- 各種状態出力.
        --------------------------------------------------------------------------
            REPORT_STATUS   => M_REPORT        , -- Out :
            FINISH          => M_FINISH          -- Out :
    );
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process begin
        ACLK <= '0';
        wait for PERIOD / 2;
        ACLK <= '1';
        wait for PERIOD / 2;
    end process;

    ARESETn  <= '1' when (RESET = '0') else '0';
    C_GPI    <= (others => '0');
    F_GPI    <= (others => '0');
    S_GPI    <= (others => '0');
    M_GPI    <= (others => '0');
    process
        variable L   : LINE;
        constant T   : STRING(1 to 7) := "  ***  ";
    begin
        wait until (C_FINISH'event and C_FINISH = '1');
        wait for DELAY;
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        WRITE(L,T & "ERROR REPORT " & NAME);                          WRITELINE(OUTPUT,L);
        WRITE(L,T & "[  CSR  ]");                                     WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,C_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,C_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,C_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ FETCH ]");                                     WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,F_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,F_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,F_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ SLAVE ]");                                     WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,S_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,S_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,S_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ MASTER]");                                     WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,M_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,M_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,M_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        assert FALSE report "Simulation complete." severity FAILURE;
        wait;
    end process;
    
 -- SYNC_PRINT_0: SYNC_PRINT generic map(string'("AXI4_TEST_1:SYNC(0)")) port map (SYNC(0));
 -- SYNC_PRINT_1: SYNC_PRINT generic map(string'("AXI4_TEST_1:SYNC(1)")) port map (SYNC(1));
end MODEL;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
