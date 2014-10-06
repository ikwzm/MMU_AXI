-----------------------------------------------------------------------------------
--!     @file    mmu_axi.vhd
--!     @brief   MMU AXI Module
--!     @version 1.0.0
--!     @date    2014/10/6
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
library ieee;
use     ieee.std_logic_1164.all;
-----------------------------------------------------------------------------------
--! @brief   MMU_AXI : MMU AXI Module
-----------------------------------------------------------------------------------
entity  MMU_AXI is
    generic (
        READ_ENABLE     : integer :=  1;
        WRITE_ENABLE    : integer :=  1;
        PAGE_SIZE       : integer := 12;
        DESC_SIZE       : integer :=  2;
        TLB_TAG_SETS    : integer :=  2;
        TLB_TAG_WAYS    : integer :=  3;
        M_QUEUE_SIZE    : integer :=  4;
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
    -------------------------------------------------------------------------------
    -- Reset Signals.
    -------------------------------------------------------------------------------
        ARESETn         : in    std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F Clock.
    -------------------------------------------------------------------------------
        C_CLK           : in    std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
        C_ARID          : in    std_logic_vector(C_ID_WIDTH    -1 downto 0);
        C_ARADDR        : in    std_logic_vector(C_ADDR_WIDTH  -1 downto 0);
        C_ARLEN         : in    std_logic_vector(C_ALEN_WIDTH  -1 downto 0);
        C_ARSIZE        : in    std_logic_vector(2 downto 0);
        C_ARBURST       : in    std_logic_vector(1 downto 0);
        C_ARVALID       : in    std_logic;
        C_ARREADY       : out   std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Read Data Channel Signals.
    -------------------------------------------------------------------------------
        C_RID           : out   std_logic_vector(C_ID_WIDTH    -1 downto 0);
        C_RDATA         : out   std_logic_vector(C_DATA_WIDTH  -1 downto 0);
        C_RRESP         : out   std_logic_vector(1 downto 0);
        C_RLAST         : out   std_logic;
        C_RVALID        : out   std_logic;
        C_RREADY        : in    std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Write Address Channel Signals.
    -------------------------------------------------------------------------------
        C_AWID          : in    std_logic_vector(C_ID_WIDTH    -1 downto 0);
        C_AWADDR        : in    std_logic_vector(C_ADDR_WIDTH  -1 downto 0);
        C_AWLEN         : in    std_logic_vector(C_ALEN_WIDTH  -1 downto 0);
        C_AWSIZE        : in    std_logic_vector(2 downto 0);
        C_AWBURST       : in    std_logic_vector(1 downto 0);
        C_AWVALID       : in    std_logic;
        C_AWREADY       : out   std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Write Data Channel Signals.
    -------------------------------------------------------------------------------
        C_WDATA         : in    std_logic_vector(C_DATA_WIDTH  -1 downto 0);
        C_WSTRB         : in    std_logic_vector(C_DATA_WIDTH/8-1 downto 0);
        C_WLAST         : in    std_logic;
        C_WVALID        : in    std_logic;
        C_WREADY        : out   std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Write Response Channel Signals.
    -------------------------------------------------------------------------------
        C_BID           : out   std_logic_vector(C_ID_WIDTH    -1 downto 0);
        C_BRESP         : out   std_logic_vector(1 downto 0);
        C_BVALID        : out   std_logic;
        C_BREADY        : in    std_logic;
    -------------------------------------------------------------------------------
    -- Descripter Fetch I/F Clock.
    -------------------------------------------------------------------------------
        F_CLK           : in    std_logic;
    -------------------------------------------------------------------------------
    -- Descripter Fetch I/F AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
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
    -------------------------------------------------------------------------------
    -- Descripter Fetch I/F AXI4 Read Data Channel Signals.
    -------------------------------------------------------------------------------
        F_RID           : in    std_logic_vector(F_ID_WIDTH    -1 downto 0);
        F_RDATA         : in    std_logic_vector(F_DATA_WIDTH  -1 downto 0);
        F_RRESP         : in    std_logic_vector(1 downto 0);
        F_RLAST         : in    std_logic;
        F_RVALID        : in    std_logic;
        F_RREADY        : out   std_logic;
    -------------------------------------------------------------------------------
    -- Descripter Fetch I/F AXI4 Write Address Channel Signals.
    -------------------------------------------------------------------------------
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
    -------------------------------------------------------------------------------
    -- Descripter Fetch I/F AXI4 Write Data Channel Signals.
    -------------------------------------------------------------------------------
        F_WDATA         : out   std_logic_vector(F_DATA_WIDTH  -1 downto 0);
        F_WSTRB         : out   std_logic_vector(F_DATA_WIDTH/8-1 downto 0);
        F_WLAST         : out   std_logic;
        F_WVALID        : out   std_logic;
        F_WREADY        : in    std_logic;
    -------------------------------------------------------------------------------
    -- Descripter Fetch I/F AXI4 Write Response Channel Signals.
    -------------------------------------------------------------------------------
        F_BID           : in    std_logic_vector(F_ID_WIDTH    -1 downto 0);
        F_BRESP         : in    std_logic_vector(1 downto 0);
        F_BVALID        : in    std_logic;
        F_BREADY        : out   std_logic;
    -------------------------------------------------------------------------------
    -- MMU Slave I/F Clock.
    -------------------------------------------------------------------------------
        S_CLK           : in    std_logic;
    -------------------------------------------------------------------------------
    -- MMU Slave I/F AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
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
    -------------------------------------------------------------------------------
    -- MMU Slave I/F AXI4 Read Data Channel Signals.
    -------------------------------------------------------------------------------
        S_RID           : out   std_logic_vector(S_ID_WIDTH    -1 downto 0);
        S_RDATA         : out   std_logic_vector(S_DATA_WIDTH  -1 downto 0);
        S_RRESP         : out   std_logic_vector(1 downto 0);
        S_RLAST         : out   std_logic;
        S_RVALID        : out   std_logic;
        S_RREADY        : in    std_logic;
    -------------------------------------------------------------------------------
    -- MMU Slave I/F AXI4 Write Address Channel Signals.
    -------------------------------------------------------------------------------
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
    -------------------------------------------------------------------------------
    -- MMU Slave I/F AXI4 Write Data Channel Signals.
    -------------------------------------------------------------------------------
        S_WDATA         : in    std_logic_vector(S_DATA_WIDTH  -1 downto 0);
        S_WSTRB         : in    std_logic_vector(S_DATA_WIDTH/8-1 downto 0);
        S_WLAST         : in    std_logic;
        S_WVALID        : in    std_logic;
        S_WREADY        : out   std_logic;
    -------------------------------------------------------------------------------
    -- MMU Slave I/F AXI4 Write Response Channel Signals.
    -------------------------------------------------------------------------------
        S_BID           : out   std_logic_vector(S_ID_WIDTH    -1 downto 0);
        S_BRESP         : out   std_logic_vector(1 downto 0);
        S_BVALID        : out   std_logic;
        S_BREADY        : in    std_logic;
    -------------------------------------------------------------------------------
    -- MMU Master I/F Clock.
    -------------------------------------------------------------------------------
        M_CLK           : in    std_logic;
    -------------------------------------------------------------------------------
    -- MMU Master I/F AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
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
    -------------------------------------------------------------------------------
    -- MMU Master I/F AXI4 Read Data Channel Signals.
    -------------------------------------------------------------------------------
        M_RID           : in    std_logic_vector(M_ID_WIDTH    -1 downto 0);
        M_RDATA         : in    std_logic_vector(M_DATA_WIDTH  -1 downto 0);
        M_RRESP         : in    std_logic_vector(1 downto 0);
        M_RLAST         : in    std_logic;
        M_RVALID        : in    std_logic;
        M_RREADY        : out   std_logic;
    -------------------------------------------------------------------------------
    -- MMU Master I/F AXI4 Write Address Channel Signals.
    -------------------------------------------------------------------------------
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
    -------------------------------------------------------------------------------
    -- MMU Master I/F AXI4 Write Data Channel Signals.
    -------------------------------------------------------------------------------
        M_WDATA         : out   std_logic_vector(M_DATA_WIDTH  -1 downto 0);
        M_WSTRB         : out   std_logic_vector(M_DATA_WIDTH/8-1 downto 0);
        M_WLAST         : out   std_logic;
        M_WVALID        : out   std_logic;
        M_WREADY        : in    std_logic;
    -------------------------------------------------------------------------------
    -- MMU Master I/F AXI4 Write Response Channel Signals.
    -------------------------------------------------------------------------------
        M_BID           : in    std_logic_vector(M_ID_WIDTH    -1 downto 0);
        M_BRESP         : in    std_logic_vector(1 downto 0);
        M_BVALID        : in    std_logic;
        M_BREADY        : out   std_logic
    );
end MMU_AXI;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
library PIPEWORK;
use     PIPEWORK.AXI4_TYPES.all;
use     PIPEWORK.AXI4_COMPONENTS.AXI4_MASTER_READ_INTERFACE;
use     PIPEWORK.AXI4_COMPONENTS.AXI4_REGISTER_INTERFACE;
use     PIPEWORK.COMPONENTS.REGISTER_ACCESS_ADAPTER;
use     PIPEWORK.COMPONENTS.QUEUE_ARBITER;
use     PIPEWORK.COMPONENTS.QUEUE_REGISTER;
architecture RTL of MMU_AXI is
    -------------------------------------------------------------------------------
    -- リセット信号.
    -------------------------------------------------------------------------------
    signal   RST                :  std_logic;
    constant CLR                :  std_logic := '0';
    -------------------------------------------------------------------------------
    -- Descripter のビット数.
    -------------------------------------------------------------------------------
    constant DESC_BITS          :  integer := 2**(DESC_SIZE+3);
    constant PREF_BITS          :  integer := S_ADDR_WIDTH;
    -------------------------------------------------------------------------------
    -- レジスタアクセスインターフェースのアドレスのビット数.
    -------------------------------------------------------------------------------
    constant REGS_ADDR_WIDTH    :  integer := 5;
    -------------------------------------------------------------------------------
    -- 全レジスタのビット数.
    -------------------------------------------------------------------------------
    constant REGS_DATA_BITS     :  integer := (2**REGS_ADDR_WIDTH)*8;
    -------------------------------------------------------------------------------
    -- レジスタアクセスインターフェースのデータのビット数.
    -------------------------------------------------------------------------------
    constant REGS_DATA_WIDTH    :  integer := 32;
    -------------------------------------------------------------------------------
    -- レジスタアクセス用の信号群.
    -------------------------------------------------------------------------------
    signal   regs_load          :  std_logic_vector(REGS_DATA_BITS-1 downto 0);
    signal   regs_wbit          :  std_logic_vector(REGS_DATA_BITS-1 downto 0);
    signal   regs_rbit          :  std_logic_vector(REGS_DATA_BITS-1 downto 0);
    -------------------------------------------------------------------------------
    -- レジスタのアドレスマップ.
    -------------------------------------------------------------------------------
    --           31            24              16               8               0
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x00 |                       Reserve[31:00]                          |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x04 |                       Reserve[63:32]                          |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x08 |                      Prefetch[31:00]                          |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x0C |                      Prefetch[63:32]                          |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x10 |                    Descripter[31:00]                          |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x14 |                    Descripter[63:32]                          |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x18 |                          Mode[31:00]                          |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x1C | Control[7:0]  |  Status[7:0]  |          Mode[47:32]          |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -------------------------------------------------------------------------------
    constant RESV_REGS_ADDR     :  integer := 16#00#;
    constant RESV_REGS_BITS     :  integer := 64;
    constant RESV_REGS_LO       :  integer := 8*RESV_REGS_ADDR;
    constant RESV_REGS_HI       :  integer := RESV_REGS_LO + RESV_REGS_BITS -1;
    constant PREF_REGS_ADDR     :  integer := 16#08#;
    constant PREF_REGS_BITS     :  integer := 64;
    constant PREF_REGS_LO       :  integer := 8*PREF_REGS_ADDR;
    constant PREF_REGS_HI       :  integer := PREF_REGS_LO + PREF_REGS_BITS -1;
    constant DESC_REGS_ADDR     :  integer := 16#10#;
    constant DESC_REGS_BITS     :  integer := 64;
    constant DESC_REGS_LO       :  integer := 8*DESC_REGS_ADDR;
    constant DESC_REGS_HI       :  integer := DESC_REGS_LO + DESC_REGS_BITS -1;
    constant MODE_REGS_ADDR     :  integer := 16#18#;
    constant MODE_REGS_BITS     :  integer := 48;
    constant MODE_REGS_LO       :  integer := 8*MODE_REGS_ADDR;
    constant MODE_REGS_HI       :  integer := MODE_REGS_LO + MODE_REGS_BITS -1;
    constant MODE_REGS_AUSER_HI :  integer := MODE_REGS_LO + 44;
    constant MODE_REGS_AUSER_LO :  integer := MODE_REGS_LO + 40;
    constant MODE_REGS_CACHE_HI :  integer := MODE_REGS_LO + 39;
    constant MODE_REGS_CACHE_LO :  integer := MODE_REGS_LO + 36;
    constant STAT_REGS_ADDR     :  integer := 16#1E#;
    constant STAT_REGS_BITS     :  integer := 8;
    constant STAT_REGS_LO       :  integer := 8*STAT_REGS_ADDR;
    constant STAT_REGS_HI       :  integer := STAT_REGS_LO + STAT_REGS_BITS -1;
    constant CTRL_REGS_ADDR     :  integer := 16#1F#;
    constant CTRL_REGS_BITS     :  integer := 8;
    constant CTRL_REGS_LO       :  integer := 8*CTRL_REGS_ADDR;
    constant CTRL_REGS_HI       :  integer := CTRL_REGS_LO + CTRL_REGS_BITS -1;
    constant CTRL_REGS_START    :  integer := CTRL_REGS_LO + 0;
    constant CTRL_REGS_RESV1    :  integer := CTRL_REGS_LO + 1;
    constant CTRL_REGS_RESV2    :  integer := CTRL_REGS_LO + 2;
    constant CTRL_REGS_RESV3    :  integer := CTRL_REGS_LO + 3;
    constant CTRL_REGS_RESV4    :  integer := CTRL_REGS_LO + 4;
    constant CTRL_REGS_RESV5    :  integer := CTRL_REGS_LO + 5;
    constant CTRL_REGS_RESV6    :  integer := CTRL_REGS_LO + 6;
    constant CTRL_REGS_RESET    :  integer := CTRL_REGS_LO + 7;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function resize(ARG:std_logic_vector;LEN:integer) return std_logic_vector is
        variable val : std_logic_vector(LEN-1        downto 0);
        alias    av  : std_logic_vector(ARG'length-1 downto 0) is ARG;
    begin
        for i in val'range loop
            if (i > av'high) then
                val(i) := '0';
            else
                val(i) := av(i);
            end if;
        end loop;
        return val;
    end function;
    -------------------------------------------------------------------------------
    -- Descripter Fetch I/F Signals.
    -------------------------------------------------------------------------------
    function CALC_FETCH_SIZE_BITS return integer is
        variable max_xfer_size : integer;
        variable bit_width     : integer;
    begin
        max_xfer_size := TLB_TAG_SETS*(2**TLB_TAG_WAYS)*(DESC_BITS/8);
        bit_width     := 0;
        while (2**bit_width <= max_xfer_size) loop
            bit_width := bit_width + 1;
        end loop;
        return bit_width;
    end function;
    constant FETCH_SIZE_BITS    :  integer := CALC_FETCH_SIZE_BITS;
    signal   fetch_req_addr     :  std_logic_vector(F_ADDR_WIDTH   -1 downto 0);
    signal   fetch_req_size     :  std_logic_vector(FETCH_SIZE_BITS-1 downto 0);
    signal   fetch_req_ptr      :  std_logic_vector(FETCH_SIZE_BITS-2 downto 0);
    signal   fetch_req_first    :  std_logic;
    signal   fetch_req_last     :  std_logic;
    signal   fetch_req_valid    :  std_logic;
    signal   fetch_req_ready    :  std_logic;
    signal   fetch_ack_valid    :  std_logic;
    signal   fetch_ack_error    :  std_logic;
    signal   fetch_ack_next     :  std_logic;
    signal   fetch_ack_last     :  std_logic;
    signal   fetch_ack_stop     :  std_logic;
    signal   fetch_ack_none     :  std_logic;
    signal   fetch_ack_size     :  std_logic_vector(FETCH_SIZE_BITS-1 downto 0);
    signal   fetch_xfer_busy    :  std_logic;
    signal   fetch_xfer_done    :  std_logic;
    signal   fetch_xfer_error   :  std_logic;
    signal   fetch_buf_wen      :  std_logic;
    signal   fetch_buf_ben      :  std_logic_vector(DESC_BITS/8    -1 downto 0);
    signal   fetch_buf_wdata    :  std_logic_vector(DESC_BITS      -1 downto 0);
    signal   fetch_buf_wptr     :  std_logic_vector(FETCH_SIZE_BITS-2 downto 0);
    -------------------------------------------------------------------------------
    -- MMU_CORE Component.
    -------------------------------------------------------------------------------
    component MMU_CORE 
        generic (
            PAGE_SIZE           : integer := 12;
            DESC_SIZE           : integer :=  2;
            TLB_TAG_SETS        : integer :=  2;
            TLB_TAG_WAYS        : integer :=  3;
            QUERY_ADDR_BITS     : integer := 32;
            FETCH_ADDR_BITS     : integer := 32;
            FETCH_SIZE_BITS     : integer := 12;
            FETCH_PTR_BITS      : integer :=  8;
            MODE_BITS           : integer := 32;
            PREF_BITS           : integer := 32;
            USE_PREFETCH        : integer :=  1;
            SEL_SDPRAM          : integer :=  0
        );
        port (
            CLK                 : in  std_logic; 
            RST                 : in  std_logic;
            CLR                 : in  std_logic;
            RESET_L             : in  std_logic;
            RESET_D             : in  std_logic;
            RESET_Q             : out std_logic;
            START_L             : in  std_logic;
            START_D             : in  std_logic;
            START_Q             : out std_logic;
            DESC_L              : in  std_logic_vector(2**(DESC_SIZE+3)-1 downto 0);
            DESC_D              : in  std_logic_vector(2**(DESC_SIZE+3)-1 downto 0);
            DESC_Q              : out std_logic_vector(2**(DESC_SIZE+3)-1 downto 0);
            PREF_L              : in  std_logic_vector(PREF_BITS       -1 downto 0);
            PREF_D              : in  std_logic_vector(PREF_BITS       -1 downto 0);
            PREF_Q              : out std_logic_vector(PREF_BITS       -1 downto 0);
            MODE_L              : in  std_logic_vector(MODE_BITS       -1 downto 0);
            MODE_D              : in  std_logic_vector(MODE_BITS       -1 downto 0);
            MODE_Q              : out std_logic_vector(MODE_BITS       -1 downto 0);
            QUERY_REQ           : in  std_logic;
            QUERY_ADDR          : in  std_logic_vector(QUERY_ADDR_BITS -1 downto 0);
            QUERY_ACK           : out std_logic;
            QUERY_ERROR         : out std_logic;
            QUERY_DESC          : out std_logic_vector(2**(DESC_SIZE+3)-1 downto 0);
            FETCH_REQ_VALID     : out std_logic;
            FETCH_REQ_FIRST     : out std_logic;
            FETCH_REQ_LAST      : out std_logic;
            FETCH_REQ_ADDR      : out std_logic_vector(FETCH_ADDR_BITS -1 downto 0);
            FETCH_REQ_SIZE      : out std_logic_vector(FETCH_SIZE_BITS -1 downto 0);
            FETCH_REQ_PTR       : out std_logic_vector(FETCH_PTR_BITS  -1 downto 0);
            FETCH_REQ_READY     : in  std_logic;
            FETCH_ACK_VALID     : in  std_logic;
            FETCH_ACK_ERROR     : in  std_logic;
            FETCH_ACK_NEXT      : in  std_logic;
            FETCH_ACK_LAST      : in  std_logic;
            FETCH_ACK_STOP      : in  std_logic;
            FETCH_ACK_NONE      : in  std_logic;
            FETCH_ACK_SIZE      : in  std_logic_vector(FETCH_SIZE_BITS -1 downto 0);
            FETCH_XFER_BUSY     : in  std_logic;
            FETCH_XFER_ERROR    : in  std_logic := '0';
            FETCH_XFER_DONE     : in  std_logic;
            FETCH_BUF_DATA      : in  std_logic_vector(2**(DESC_SIZE+3)-1 downto 0);
            FETCH_BUF_BEN       : in  std_logic_vector(2**(DESC_SIZE  )-1 downto 0);
            FETCH_BUF_PTR       : in  std_logic_vector(FETCH_PTR_BITS  -1 downto 0);
            FETCH_BUF_WE        : in  std_logic
        );
    end component;
begin
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    RST <= '1' when (ARESETn = '0') else '0';
    -------------------------------------------------------------------------------
    -- Control Status Register AXI I/F
    -------------------------------------------------------------------------------
    CSR_IF: block
        constant sig_1          :  std_logic := '1';
        signal   regs_req       :  std_logic;
        signal   regs_write     :  std_logic;
        signal   regs_ack       :  std_logic;
        signal   regs_err       :  std_logic;
        signal   regs_addr      :  std_logic_vector(REGS_ADDR_WIDTH  -1 downto 0);
        signal   regs_ben       :  std_logic_vector(REGS_DATA_WIDTH/8-1 downto 0);
        signal   regs_wdata     :  std_logic_vector(REGS_DATA_WIDTH  -1 downto 0);
        signal   regs_rdata     :  std_logic_vector(REGS_DATA_WIDTH  -1 downto 0);
    begin 
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        AXI4: AXI4_REGISTER_INTERFACE                  --
            generic map (                              -- 
                AXI4_ADDR_WIDTH => C_ADDR_WIDTH      , --
                AXI4_DATA_WIDTH => C_DATA_WIDTH      , --
                AXI4_ID_WIDTH   => C_ID_WIDTH        , --
                REGS_ADDR_WIDTH => REGS_ADDR_WIDTH   , --
                REGS_DATA_WIDTH => REGS_DATA_WIDTH     --
            )                                          -- 
            port map (                                 -- 
            -----------------------------------------------------------------------
            -- Clock and Reset Signals.
            -----------------------------------------------------------------------
                CLK             => C_CLK             , -- In  :
                RST             => RST               , -- In  :
                CLR             => CLR               , -- In  :
            -----------------------------------------------------------------------
            -- AXI4 Read Address Channel Signals.
            -----------------------------------------------------------------------
                ARID            => C_ARID            , -- In  :
                ARADDR          => C_ARADDR          , -- In  :
                ARLEN           => C_ARLEN           , -- In  :
                ARSIZE          => C_ARSIZE          , -- In  :
                ARBURST         => C_ARBURST         , -- In  :
                ARVALID         => C_ARVALID         , -- In  :
                ARREADY         => C_ARREADY         , -- Out :
            -----------------------------------------------------------------------
            -- AXI4 Read Data Channel Signals.
            -----------------------------------------------------------------------
                RID             => C_RID             , -- Out :
                RDATA           => C_RDATA           , -- Out :
                RRESP           => C_RRESP           , -- Out :
                RLAST           => C_RLAST           , -- Out :
                RVALID          => C_RVALID          , -- Out :
                RREADY          => C_RREADY          , -- In  :
            -----------------------------------------------------------------------
            -- AXI4 Write Address Channel Signals.
            -----------------------------------------------------------------------
                AWID            => C_AWID            , -- In  :
                AWADDR          => C_AWADDR          , -- In  :
                AWLEN           => C_AWLEN           , -- In  :
                AWSIZE          => C_AWSIZE          , -- In  :
                AWBURST         => C_AWBURST         , -- In  :
                AWVALID         => C_AWVALID         , -- In  :
                AWREADY         => C_AWREADY         , -- Out :
            -----------------------------------------------------------------------
            -- AXI4 Write Data Channel Signals.
            -----------------------------------------------------------------------
                WDATA           => C_WDATA           , -- In  :
                WSTRB           => C_WSTRB           , -- In  :
                WLAST           => C_WLAST           , -- In  :
                WVALID          => C_WVALID          , -- In  :
                WREADY          => C_WREADY          , -- Out :
            -----------------------------------------------------------------------
            -- AXI4 Write Response Channel Signals.
            -----------------------------------------------------------------------
                BID             => C_BID             , -- Out :
                BRESP           => C_BRESP           , -- Out :
                BVALID          => C_BVALID          , -- Out :
                BREADY          => C_BREADY          , -- In  :
            -----------------------------------------------------------------------
            -- Register Interface.
            -----------------------------------------------------------------------
                REGS_REQ        => regs_req          , -- Out :
                REGS_WRITE      => regs_write        , -- Out :
                REGS_ACK        => regs_ack          , -- In  :
                REGS_ERR        => regs_err          , -- In  :
                REGS_ADDR       => regs_addr         , -- Out :
                REGS_BEN        => regs_ben          , -- Out :
                REGS_WDATA      => regs_wdata        , -- Out :
                REGS_RDATA      => regs_rdata          -- In  :
            );
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
        DEC: REGISTER_ACCESS_ADAPTER                   -- 
            generic map (                              -- 
                ADDR_WIDTH      => REGS_ADDR_WIDTH   , -- 
                DATA_WIDTH      => REGS_DATA_WIDTH   , -- 
                WBIT_MIN        => regs_wbit'low     , -- 
                WBIT_MAX        => regs_wbit'high    , -- 
                RBIT_MIN        => regs_rbit'low     , -- 
                RBIT_MAX        => regs_rbit'high    , -- 
                I_CLK_RATE      => 1                 , -- 
                O_CLK_RATE      => 1                 , -- 
                O_CLK_REGS      => 0                   -- 
            )                                          -- 
            port map (                                 -- 
                RST             => RST               , -- In  :
                I_CLK           => C_CLK             , -- In  :
                I_CLR           => CLR               , -- In  :
                I_CKE           => sig_1             , -- In  :
                I_REQ           => regs_req          , -- In  :
                I_SEL           => sig_1             , -- In  :
                I_WRITE         => regs_write        , -- In  :
                I_ADDR          => regs_addr         , -- In  :
                I_BEN           => regs_ben          , -- In  :
                I_WDATA         => regs_wdata        , -- In  :
                I_RDATA         => regs_rdata        , -- Out :
                I_ACK           => regs_ack          , -- Out :
                I_ERR           => regs_err          , -- Out :
                O_CLK           => C_CLK             , -- In  :
                O_CLR           => CLR               , -- In  :
                O_CKE           => sig_1             , -- In  :
                O_WDATA         => regs_wbit         , -- Out :
                O_WLOAD         => regs_load         , -- Out :
                O_RDATA         => regs_rbit           -- In  :
            );                                         -- 
    end block;
    -------------------------------------------------------------------------------
    -- Reserve Register
    -------------------------------------------------------------------------------
    regs_rbit(RESV_REGS_HI downto RESV_REGS_LO) <= (RESV_REGS_HI downto RESV_REGS_LO => '0');
    -------------------------------------------------------------------------------
    -- Status Register
    -------------------------------------------------------------------------------
    regs_rbit(STAT_REGS_HI downto STAT_REGS_LO) <= (STAT_REGS_HI downto STAT_REGS_LO => '0');
    -------------------------------------------------------------------------------
    -- Control Register(Reserve)
    -------------------------------------------------------------------------------
    regs_rbit(CTRL_REGS_RESV1) <= '0';
    regs_rbit(CTRL_REGS_RESV2) <= '0';
    regs_rbit(CTRL_REGS_RESV3) <= '0';
    regs_rbit(CTRL_REGS_RESV4) <= '0';
    regs_rbit(CTRL_REGS_RESV5) <= '0';
    regs_rbit(CTRL_REGS_RESV6) <= '0';
    -------------------------------------------------------------------------------
    -- Descripter Register(Reserve)
    -------------------------------------------------------------------------------
    DESC_REGS_RESV: for i in DESC_REGS_LO to DESC_REGS_HI generate
        T: if (i >= DESC_REGS_LO + DESC_BITS) generate
            regs_rbit(i) <= '0';
        end generate;
    end generate;
    -------------------------------------------------------------------------------
    -- Prefetch Register(Reserve)
    -------------------------------------------------------------------------------
    PREF_REGS_RESV: for i in PREF_REGS_LO to PREF_REGS_HI generate
        T: if (i >= PREF_REGS_LO + PREF_BITS) generate
            regs_rbit(i) <= '0';
        end generate;
    end generate;
    -------------------------------------------------------------------------------
    -- Descripter Fetch AXI I/F
    -------------------------------------------------------------------------------
    FETCH_IF: block
        constant  req_id     :  std_logic_vector(F_ID_WIDTH   -1 downto 0) := (others => '0');
        signal    req_auser  :  std_logic_vector(MODE_REGS_AUSER_HI downto MODE_REGS_AUSER_LO);
        signal    req_cache  :  AXI4_ACACHE_TYPE;
        constant  req_lock   :  AXI4_ALOCK_TYPE   := (others => '0');
        constant  req_prot   :  AXI4_APROT_TYPE   := (others => '0');
        constant  req_qos    :  AXI4_AQOS_TYPE    := (others => '0');
        constant  req_region :  AXI4_AREGION_TYPE := (others => '0');
        constant  flow_size  :  std_logic_vector(FETCH_SIZE_BITS-1 downto 0) := (others => '0');
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        MR_IF: AXI4_MASTER_READ_INTERFACE              -- 
            generic map (                              -- 
                AXI4_ADDR_WIDTH => F_ADDR_WIDTH      , -- 
                AXI4_DATA_WIDTH => F_DATA_WIDTH      , -- 
                AXI4_ID_WIDTH   => F_ID_WIDTH        , -- 
                VAL_BITS        => 1                 , -- 
                REQ_SIZE_BITS   => FETCH_SIZE_BITS   , -- 
                REQ_SIZE_VALID  => 1                 , -- 
                FLOW_VALID      => 0                 , -- 
                BUF_DATA_WIDTH  => DESC_BITS         , --
                BUF_PTR_BITS    => FETCH_SIZE_BITS-1 , --
                ALIGNMENT_BITS  => 32                , --
                XFER_SIZE_BITS  => FETCH_SIZE_BITS   , -- 
                XFER_MIN_SIZE   => FETCH_SIZE_BITS   , -- 
                XFER_MAX_SIZE   => FETCH_SIZE_BITS   , -- 
                QUEUE_SIZE      => 1                   --
             -- RDATA_REGS      => 0                   -- 
            )                                          -- 
            port map (                                 -- 
            -----------------------------------------------------------------------
            -- Clock and Reset Signals.
            -----------------------------------------------------------------------
                CLK             => F_CLK             , -- In  :
                RST             => RST               , -- In  :
                CLR             => CLR               , -- In  :
            -----------------------------------------------------------------------
            -- AXI4 Read Address Channel Signals.
            -----------------------------------------------------------------------
                ARID            => F_ARID            , -- Out :
                ARADDR          => F_ARADDR          , -- Out :
                ARLEN           => F_ARLEN           , -- Out :
                ARSIZE          => F_ARSIZE          , -- Out :
                ARBURST         => F_ARBURST         , -- Out :
                ARLOCK          => open              , -- Out :
                ARCACHE         => F_ARCACHE         , -- Out :
                ARPROT          => F_ARPROT          , -- Out :
                ARQOS           => F_ARQOS           , -- Out :
                ARREGION        => F_ARREGION        , -- Out :
                ARVALID         => F_ARVALID         , -- Out :
                ARREADY         => F_ARREADY         , -- In  :
            -----------------------------------------------------------------------
            -- AXI4 Read Data Channel Signals.
            -----------------------------------------------------------------------
                RID             => F_RID             , -- In  :
                RDATA           => F_RDATA           , -- In  :
                RRESP           => F_RRESP           , -- In  :
                RLAST           => F_RLAST           , -- In  :
                RVALID          => F_RVALID          , -- In  :
                RREADY          => F_RREADY          , -- Out :
            -----------------------------------------------------------------------
            -- Command Request Signals.
            -----------------------------------------------------------------------
                REQ_ADDR        => fetch_req_addr    , -- In  :
                REQ_SIZE        => fetch_req_size    , -- In  :
                REQ_ID          => req_id            , -- In  :
                REQ_BURST       => AXI4_ABURST_INCR  , -- In  :
                REQ_LOCK        => req_lock          , -- In  :
                REQ_CACHE       => req_cache         , -- In  :
                REQ_PROT        => req_prot          , -- In  :
                REQ_QOS         => req_qos           , -- In  :
                REQ_REGION      => req_region        , -- In  :
                REQ_BUF_PTR     => fetch_req_ptr     , -- In  :
                REQ_FIRST       => fetch_req_first   , -- In  :
                REQ_LAST        => fetch_req_last    , -- In  :
                REQ_SPECULATIVE => '0'               , -- In  :
                REQ_SAFETY      => '1'               , -- In  :
                REQ_VAL(0)      => fetch_req_valid   , -- In  :
                REQ_RDY         => fetch_req_ready   , -- Out :
                XFER_SIZE_SEL   => "1"               , -- In  :
                XFER_BUSY(0)    => fetch_xfer_busy   , -- Out :
                XFER_DONE(0)    => fetch_xfer_done   , -- Out :
                XFER_ERROR(0)   => fetch_xfer_error  , -- Out :
            -----------------------------------------------------------------------
            -- Response Signals.
            -----------------------------------------------------------------------
                ACK_VAL(0)      => fetch_ack_valid   , -- Out :
                ACK_ERROR       => fetch_ack_error   , -- Out :
                ACK_NEXT        => fetch_ack_next    , -- Out :
                ACK_LAST        => fetch_ack_last    , -- Out :
                ACK_STOP        => fetch_ack_stop    , -- Out :
                ACK_NONE        => fetch_ack_none    , -- Out :
                ACK_SIZE        => fetch_ack_size    , -- Out :
            -----------------------------------------------------------------------
            -- Flow Control Signals.
            -----------------------------------------------------------------------
                FLOW_PAUSE      => '0'               , -- In  :
                FLOW_STOP       => '0'               , -- In  :
                FLOW_LAST       => '0'               , -- In  :
                FLOW_SIZE       => flow_size         , -- In  :
            -----------------------------------------------------------------------
            -- Push Reserve Size Signals.
            -----------------------------------------------------------------------
                PUSH_RSV_VAL    => open              , -- Out :
                PUSH_RSV_SIZE   => open              , -- Out :
                PUSH_RSV_LAST   => open              , -- Out :
                PUSH_RSV_ERROR  => open              , -- Out :
            -----------------------------------------------------------------------
            -- Push Final Size Signals.
            -----------------------------------------------------------------------
                PUSH_FIN_VAL    => open              , -- Out :
                PUSH_FIN_SIZE   => open              , -- Out :
                PUSH_FIN_LAST   => open              , -- Out :
                PUSH_FIN_ERROR  => open              , -- Out :
            -----------------------------------------------------------------------
            -- Push Buffer Signals.
            -----------------------------------------------------------------------
                PUSH_BUF_RESET  => open              , -- Out :
                PUSH_BUF_VAL    => open              , -- Out :
                PUSH_BUF_SIZE   => open              , -- Out :
                PUSH_BUF_LAST   => open              , -- Out :
                PUSH_BUF_ERROR  => open              , -- Out :
                PUSH_BUF_RDY(0) => '1'               , -- In  :
            -----------------------------------------------------------------------
            -- Read Buffer Interface Signals.
            -----------------------------------------------------------------------
                BUF_WEN(0)      => fetch_buf_wen     , -- Out :
                BUF_BEN         => fetch_buf_ben     , -- Out :
                BUF_DATA        => fetch_buf_wdata   , -- Out :
                BUF_PTR         => fetch_buf_wptr      -- Out :
            );
        F_ARUSER   <= resize(req_auser, F_ARUSER'length);
        F_AWID     <= (others => '0');
        F_AWADDR   <= (others => '0');
        F_AWLEN    <= (others => '0');
        F_AWSIZE   <= (others => '0');
        F_AWBURST  <= (others => '0');
        F_AWLOCK   <= (others => '0');
        F_AWCACHE  <= (others => '0');
        F_AWPROT   <= (others => '0');
        F_AWQOS    <= (others => '0');
        F_AWREGION <= (others => '0');
        F_AWUSER   <= (others => '0');
        F_AWVALID  <= '0';
        F_WDATA    <= (others => '0');
        F_WSTRB    <= (others => '0');
        F_WLAST    <= '0';
        F_WVALID   <= '0';
        F_BREADY   <= '1';
        req_auser <= regs_rbit(MODE_REGS_AUSER_HI downto MODE_REGS_AUSER_LO);
        req_cache <= regs_rbit(MODE_REGS_CACHE_HI downto MODE_REGS_CACHE_LO);
    end block;
    -------------------------------------------------------------------------------
    -- AXI Address Channel
    -------------------------------------------------------------------------------
    ADDR_CHANNEL: block
        signal    query_addr   :  std_logic_vector(S_ADDR_WIDTH     -1 downto 0);
        signal    query_cache  :  std_logic_vector(AXI4_ACACHE_WIDTH-1 downto 0);
        signal    query_desc   :  std_logic_vector(DESC_BITS        -1 downto 0);
        signal    query_rd_sel :  boolean;
        signal    query_wr_sel :  boolean;
        signal    query_req    :  std_logic;
        signal    query_ack    :  std_logic;
        signal    query_error  :  std_logic;
        signal    query_wait   :  std_logic;
        signal    query_ok     :  std_logic;
        constant  Q_AROK_POS   :  integer := 0;
        constant  Q_ARNG_POS   :  integer := 1;
        constant  Q_AWOK_POS   :  integer := 2;
        constant  Q_AWNG_POS   :  integer := 3;
        constant  Q_ACACHE_LO  :  integer := 4;
        constant  Q_ACACHE_HI  :  integer := Q_ACACHE_LO  + AXI4_ACACHE_WIDTH -1;
        constant  Q_ALEN_LO    :  integer := Q_ACACHE_HI  + 1;
        constant  Q_ALEN_HI    :  integer := Q_ALEN_LO    + S_ALEN_WIDTH      -1;
        constant  Q_ASIZE_LO   :  integer := Q_ALEN_HI    + 1;
        constant  Q_ASIZE_HI   :  integer := Q_ASIZE_LO   + AXI4_ASIZE_WIDTH  -1;
        constant  Q_ABURST_LO  :  integer := Q_ASIZE_HI   + 1;
        constant  Q_ABURST_HI  :  integer := Q_ABURST_LO  + AXI4_ABURST_WIDTH -1;
        constant  Q_ALOCK_LO   :  integer := Q_ABURST_HI  + 1;
        constant  Q_ALOCK_HI   :  integer := Q_ALOCK_LO   + S_ALOCK_WIDTH     -1;
        constant  Q_APROT_LO   :  integer := Q_ALOCK_HI   + 1;
        constant  Q_APROT_HI   :  integer := Q_APROT_LO   + AXI4_APROT_WIDTH  -1;
        constant  Q_AQOS_LO    :  integer := Q_APROT_HI   + 1;
        constant  Q_AQOS_HI    :  integer := Q_AQOS_LO    + AXI4_AQOS_WIDTH   -1;
        constant  Q_AREGION_LO :  integer := Q_AQOS_HI    + 1;
        constant  Q_AREGION_HI :  integer := Q_AREGION_LO + AXI4_AREGION_WIDTH-1;
        constant  Q_AUSER_LO   :  integer := Q_AREGION_HI + 1;
        constant  Q_AUSER_HI   :  integer := Q_AUSER_LO   + S_AUSER_WIDTH     -1;
        constant  Q_AID_LO     :  integer := Q_AUSER_HI   + 1;
        constant  Q_AID_HI     :  integer := Q_AID_LO     + S_ID_WIDTH        -1;
        constant  Q_AADDR_LO   :  integer := Q_AID_HI     + 1;
        constant  Q_AADDR_HI   :  integer := Q_AADDR_LO   + S_ADDR_WIDTH      -1;
        constant  Q_LO         :  integer := 0;
        constant  Q_HI         :  integer := Q_AADDR_HI;
        constant  Q_BITS       :  integer := Q_HI - Q_LO + 1;
        signal    t_data       :  std_logic_vector(Q_HI downto Q_LO);
        signal    t_valid      :  std_logic;
        signal    t_ready      :  std_logic;
        signal    m_data       :  std_logic_vector(Q_HI downto Q_LO);
        signal    m_valid      :  std_logic;
        signal    m_ready      :  std_logic;
    begin
        ---------------------------------------------------------------------------
        -- MMU CORE
        ---------------------------------------------------------------------------
        MMU: MMU_CORE                                        -- 
            generic map (                                    -- 
                PAGE_SIZE           => PAGE_SIZE           , --
                DESC_SIZE           => DESC_SIZE           , --
                TLB_TAG_SETS        => TLB_TAG_SETS        , --
                TLB_TAG_WAYS        => TLB_TAG_WAYS        , --
                QUERY_ADDR_BITS     => S_ADDR_WIDTH        , -- 
                FETCH_ADDR_BITS     => F_ADDR_WIDTH        , -- 
                FETCH_SIZE_BITS     => FETCH_SIZE_BITS     , -- 
                FETCH_PTR_BITS      => FETCH_SIZE_BITS-1   , -- 
                MODE_BITS           => MODE_REGS_BITS      , --
                PREF_BITS           => PREF_BITS           , -- 
                USE_PREFETCH        => 1                   , -- 
                SEL_SDPRAM          => 8                     -- 
            )                                                -- 
            port map (                                       -- 
                CLK                 => C_CLK               , -- In  :
                RST                 => RST                 , -- In  :
                CLR                 => CLR                 , -- In  :
                RESET_L             => regs_load(CTRL_REGS_RESET),  -- In  :
                RESET_D             => regs_wbit(CTRL_REGS_RESET),  -- In  :
                RESET_Q             => regs_rbit(CTRL_REGS_RESET),  -- Out :
                START_L             => regs_load(CTRL_REGS_START),  -- In  :
                START_D             => regs_wbit(CTRL_REGS_START),  -- In  :
                START_Q             => regs_rbit(CTRL_REGS_START),  -- Out :
                DESC_L              => regs_load(DESC_REGS_LO+DESC_BITS downto DESC_REGS_LO) , -- In  :
                DESC_D              => regs_wbit(DESC_REGS_LO+DESC_BITS downto DESC_REGS_LO) , -- In  :
                DESC_Q              => regs_rbit(DESC_REGS_LO+DESC_BITS downto DESC_REGS_LO) , -- Out :
                PREF_L              => regs_load(PREF_REGS_LO+PREF_BITS downto PREF_REGS_LO) , -- In  :
                PREF_D              => regs_wbit(PREF_REGS_LO+PREF_BITS downto PREF_REGS_LO) , -- In  :
                PREF_Q              => regs_rbit(PREF_REGS_LO+PREF_BITS downto PREF_REGS_LO) , -- Out :
                MODE_L              => regs_load(MODE_REGS_HI           downto MODE_REGS_LO) , -- In  :
                MODE_D              => regs_wbit(MODE_REGS_HI           downto MODE_REGS_LO) , -- In  :
                MODE_Q              => regs_rbit(MODE_REGS_HI           downto MODE_REGS_LO) , -- Out :
                QUERY_REQ           => query_req           , -- In  :
                QUERY_ADDR          => query_addr          , -- In  :
                QUERY_ACK           => query_ack           , -- Out :
                QUERY_ERROR         => query_error         , -- Out :
                QUERY_DESC          => query_desc          , -- Out :
                FETCH_REQ_VALID     => fetch_req_valid     , -- Out :
                FETCH_REQ_FIRST     => fetch_req_first     , -- Out :
                FETCH_REQ_LAST      => fetch_req_last      , -- Out :
                FETCH_REQ_ADDR      => fetch_req_addr      , -- Out :
                FETCH_REQ_SIZE      => fetch_req_size      , -- Out :
                FETCH_REQ_PTR       => fetch_req_ptr       , -- Out :
                FETCH_REQ_READY     => fetch_req_ready     , -- In  :
                FETCH_ACK_VALID     => fetch_ack_valid     , -- In  :
                FETCH_ACK_ERROR     => fetch_ack_error     , -- In  :
                FETCH_ACK_NEXT      => fetch_ack_next      , -- In  :
                FETCH_ACK_LAST      => fetch_ack_last      , -- In  :
                FETCH_ACK_STOP      => fetch_ack_stop      , -- In  :
                FETCH_ACK_NONE      => fetch_ack_none      , -- In  :
                FETCH_ACK_SIZE      => fetch_ack_size      , -- In  :
                FETCH_XFER_BUSY     => fetch_xfer_busy     , -- In  :
                FETCH_XFER_ERROR    => fetch_xfer_error    , -- In  :
                FETCH_XFER_DONE     => fetch_xfer_done     , -- In  :
                FETCH_BUF_DATA      => fetch_buf_wdata     , -- In  :
                FETCH_BUF_BEN       => fetch_buf_ben       , -- In  :
                FETCH_BUF_PTR       => fetch_buf_wptr      , -- In  :
                FETCH_BUF_WE        => fetch_buf_wen         -- In  :
            );                                               -- 
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        RW: if (READ_ENABLE /= 0 and WRITE_ENABLE /= 0) generate
            signal  arb_valid   :  std_logic;
            signal  arb_shift   :  std_logic;
            signal  rd_sel      :  std_logic;
            signal  wr_sel      :  std_logic;
        begin
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            ARB: QUEUE_ARBITER                   -- 
                generic map (                    -- 
                    MIN_NUM         => 0,        -- 
                    MAX_NUM         => 1         -- 
                )                                -- 
                port map (                       -- 
                    CLK         => C_CLK       , -- In  :
                    RST         => RST         , -- In  :
                    CLR         => CLR         , -- In  :
                    ENABLE      => '1'         , -- In  :
                    REQUEST(0)  => S_ARVALID   , -- In  :
                    REQUEST(1)  => S_AWVALID   , -- In  :
                    GRANT(0)    => rd_sel      , -- Out :
                    GRANT(1)    => wr_sel      , -- Out :
                    GRANT_NUM   => open        , -- Out :
                    REQUEST_O   => open        , -- Out :
                    VALID       => arb_valid   , -- Out :
                    SHIFT       => arb_shift     -- In  :
                );                               -- 
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            process(C_CLK, RST) begin
                if (RST = '1') then
                        query_rd_sel <= FALSE;
                        query_wr_sel <= FALSE;
                elsif (C_CLK'event and C_CLK = '1') then
                    if (CLR = '1') then
                        query_rd_sel <= FALSE;
                        query_wr_sel <= FALSE;
                    else
                        query_rd_sel <= (rd_sel = '1');
                        query_wr_sel <= (wr_sel = '1');
                    end if;
                end if;
            end process;
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            query_addr                               <= S_ARADDR   when (rd_sel = '1') else S_AWADDR;
            query_cache                              <= S_ARCACHE  when (query_rd_sel) else S_AWCACHE;
            t_data(Q_AID_HI     downto Q_AID_LO    ) <= S_ARID     when (query_rd_sel) else S_AWID;
            t_data(Q_AUSER_HI   downto Q_AUSER_LO  ) <= S_ARUSER   when (query_rd_sel) else S_AWUSER;
            t_data(Q_ALEN_HI    downto Q_ALEN_LO   ) <= S_ARLEN    when (query_rd_sel) else S_AWLEN;
            t_data(Q_ASIZE_HI   downto Q_ASIZE_LO  ) <= S_ARSIZE   when (query_rd_sel) else S_AWSIZE;
            t_data(Q_ABURST_HI  downto Q_ABURST_LO ) <= S_ARBURST  when (query_rd_sel) else S_AWBURST;
            t_data(Q_ALOCK_HI   downto Q_ALOCK_LO  ) <= S_ARLOCK   when (query_rd_sel) else S_AWLOCK;
            t_data(Q_APROT_HI   downto Q_APROT_LO  ) <= S_ARPROT   when (query_rd_sel) else S_AWPROT;
            t_data(Q_AQOS_HI    downto Q_AQOS_LO   ) <= S_ARQOS    when (query_rd_sel) else S_AWQOS;
            t_data(Q_AREGION_HI downto Q_AREGION_LO) <= S_ARREGION when (query_rd_sel) else S_AWREGION;
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            query_req <= '1' when (arb_valid = '1' and query_wait = '0') else '0';
            arb_shift <= '1' when (t_valid = '1' and t_ready = '1') else '0';
            S_ARREADY <= '1' when (t_valid = '1' and t_ready = '1' and query_rd_sel) else '0';
            S_AWREADY <= '1' when (t_valid = '1' and t_ready = '1' and query_wr_sel) else '0';
        end generate;
        ---------------------------------------------------------------------------
        -- READ ONLY
        ---------------------------------------------------------------------------
        RO: if (READ_ENABLE /= 0 and WRITE_ENABLE = 0) generate
            query_rd_sel <= TRUE;
            query_wr_sel <= FALSE;
            query_req    <= '1' when (S_ARVALID = '1' and query_wait = '0') else '0';
            query_addr   <= S_ARADDR;
            query_cache  <= S_ARCACHE;
            t_data(Q_AID_HI     downto Q_AID_LO    ) <= S_ARID    ;
            t_data(Q_AUSER_HI   downto Q_AUSER_LO  ) <= S_ARUSER  ;
            t_data(Q_ALEN_HI    downto Q_ALEN_LO   ) <= S_ARLEN   ;
            t_data(Q_ASIZE_HI   downto Q_ASIZE_LO  ) <= S_ARSIZE  ;
            t_data(Q_ABURST_HI  downto Q_ABURST_LO ) <= S_ARBURST ;
            t_data(Q_ALOCK_HI   downto Q_ALOCK_LO  ) <= S_ARLOCK  ;
            t_data(Q_APROT_HI   downto Q_APROT_LO  ) <= S_ARPROT  ;
            t_data(Q_AQOS_HI    downto Q_AQOS_LO   ) <= S_ARQOS   ;
            t_data(Q_AREGION_HI downto Q_AREGION_LO) <= S_ARREGION;
            S_ARREADY <= '1' when (t_valid = '1' and t_ready = '1') else '0';
            S_AWREADY <= '0';
        end generate;
        ---------------------------------------------------------------------------
        -- WRITE ONLY
        ---------------------------------------------------------------------------
        WO: if (READ_ENABLE = 0 and WRITE_ENABLE /= 0) generate
            query_rd_sel <= FALSE;
            query_wr_sel <= TRUE;
            query_req    <= '1' when (S_AWVALID = '1' and query_wait = '0') else '0';
            query_addr   <= S_AWADDR;
            query_cache  <= S_AWCACHE;
            t_data(Q_AID_HI     downto Q_AID_LO    ) <= S_AWID    ;
            t_data(Q_AUSER_HI   downto Q_AUSER_LO  ) <= S_AWUSER  ;
            t_data(Q_ALEN_HI    downto Q_ALEN_LO   ) <= S_AWLEN   ;
            t_data(Q_ASIZE_HI   downto Q_ASIZE_LO  ) <= S_AWSIZE  ;
            t_data(Q_ABURST_HI  downto Q_ABURST_LO ) <= S_AWBURST ;
            t_data(Q_ALOCK_HI   downto Q_ALOCK_LO  ) <= S_AWLOCK  ;
            t_data(Q_APROT_HI   downto Q_APROT_LO  ) <= S_AWPROT  ;
            t_data(Q_AQOS_HI    downto Q_AQOS_LO   ) <= S_AWQOS   ;
            t_data(Q_AREGION_HI downto Q_AREGION_LO) <= S_AWREGION;
            S_ARREADY <= '0';
            S_AWREADY <= '1' when (t_valid = '1' and t_ready = '1') else '0';
        end generate;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process(C_CLK, RST) begin
            if (RST = '1') then
                    t_valid    <= '0';
                    query_wait <= '0';
                    query_ok   <= '0';
            elsif (C_CLK'event and C_CLK = '1') then
                if (CLR = '1') then
                    t_valid    <= '0';
                    query_wait <= '0';
                    query_ok   <= '0';
                else
                    if    (query_ack = '1') then
                        t_valid <= '1';
                    elsif (t_valid = '1' and t_ready = '1') then
                        t_valid <= '0';
                    end if;
                    if    (t_valid = '1' and t_ready = '0') then
                        query_wait <= '1';
                    else
                        query_wait <= '0';
                    end if;
                    query_ok <= not query_error;
                end if;
            end if;
        end process;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (query_addr, query_cache, query_ok, query_desc, query_rd_sel, query_wr_sel)
            variable addr  :  std_logic_vector(M_ADDR_WIDTH     -1 downto 0);
            variable cache :  std_logic_vector(AXI4_ACACHE_WIDTH-1 downto 0);
            variable rd_ok :  boolean;
            variable rd_ng :  boolean;
            variable wr_ok :  boolean;
            variable wr_ng :  boolean;
            function to_std_logic(A:boolean) return std_logic is begin
                if (A) then return '1';
                else        return '0';
                end if;
            end function;
        begin
            for i in addr'range loop
                if    (i < PAGE_SIZE) then
                    addr(i) := query_addr(i);
                elsif (i < DESC_BITS) then
                    addr(i) := query_desc(i);
                else
                    addr(i) := '0';
                end if;
            end loop;
            if (query_desc(2) = '1') then
                cache := query_desc(7 downto 4);
            else
                cache := query_cache;
            end if;
            rd_ok := (query_rd_sel and (query_ok = '1' and query_desc(0) = '1'));
            rd_ng := (query_rd_sel and (query_ok = '0' or  query_desc(0) = '0'));
            wr_ok := (query_wr_sel and (query_ok = '1' and query_desc(1) = '1'));
            wr_ng := (query_wr_sel and (query_ok = '0' or  query_desc(1) = '0'));
            t_data(Q_AADDR_HI  downto Q_AADDR_LO ) <= addr;
            t_data(Q_ACACHE_HI downto Q_ACACHE_LO) <= cache;
            t_data(Q_AROK_POS) <= to_std_logic(rd_ok);
            t_data(Q_ARNG_POS) <= to_std_logic(rd_ng);
            t_data(Q_AWOK_POS) <= to_std_logic(wr_ok);
            t_data(Q_AWNG_POS) <= to_std_logic(wr_ng);
        end process;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        QUEUE: QUEUE_REGISTER                -- 
            generic map (                    -- 
                QUEUE_SIZE  => M_QUEUE_SIZE, --
                DATA_BITS   => Q_BITS      , --
                LOWPOWER    => 0             -- 
            )                                -- 
            port map (                       -- 
                CLK         => C_CLK       , -- In  :
                RST         => RST         , -- In  :
                CLR         => CLR         , -- In  :
                I_DATA      => t_data      , -- In  :
                I_VAL       => t_valid     , -- In  :
                I_RDY       => t_ready     , -- Out :
                O_DATA      => open        , -- Out :
                O_VAL       => open        , -- Out :
                Q_DATA      => m_data      , -- Out :
                Q_VAL(0)    => m_valid     , -- Out :
                Q_RDY       => m_ready       -- In  :
            );
        m_ready    <= '1' when (m_data(Q_AROK_POS) = '1' and M_ARREADY = '1') or
                               (m_data(Q_AWOK_POS) = '1' and M_AWREADY = '1') else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        M_ARID     <= m_data(Q_AID_HI     downto Q_AID_LO    );
        M_ARADDR   <= m_data(Q_AADDR_HI   downto Q_AADDR_LO  );
        M_ARUSER   <= m_data(Q_AUSER_HI   downto Q_AUSER_LO  );
        M_ARLEN    <= m_data(Q_ALEN_HI    downto Q_ALEN_LO   );
        M_ARSIZE   <= m_data(Q_ASIZE_HI   downto Q_ASIZE_LO  );
        M_ARBURST  <= m_data(Q_ABURST_HI  downto Q_ABURST_LO );
        M_ARCACHE  <= m_data(Q_ACACHE_HI  downto Q_ACACHE_LO );
        M_ARLOCK   <= m_data(Q_ALOCK_HI   downto Q_ALOCK_LO  );
        M_ARPROT   <= m_data(Q_APROT_HI   downto Q_APROT_LO  );
        M_ARQOS    <= m_data(Q_AQOS_HI    downto Q_AQOS_LO   );
        M_ARREGION <= m_data(Q_AREGION_HI downto Q_AREGION_LO);
        M_ARVALID  <= '1' when (READ_ENABLE  /= 0 and m_valid = '1' and m_data(Q_AROK_POS) = '1') else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        M_AWID     <= m_data(Q_AID_HI     downto Q_AID_LO    );
        M_AWADDR   <= m_data(Q_AADDR_HI   downto Q_AADDR_LO  );
        M_AWUSER   <= m_data(Q_AUSER_HI   downto Q_AUSER_LO  );
        M_AWLEN    <= m_data(Q_ALEN_HI    downto Q_ALEN_LO   );
        M_AWSIZE   <= m_data(Q_ASIZE_HI   downto Q_ASIZE_LO  );
        M_AWBURST  <= m_data(Q_ABURST_HI  downto Q_ABURST_LO );
        M_AWCACHE  <= m_data(Q_ACACHE_HI  downto Q_ACACHE_LO );
        M_AWLOCK   <= m_data(Q_ALOCK_HI   downto Q_ALOCK_LO  );
        M_AWPROT   <= m_data(Q_APROT_HI   downto Q_APROT_LO  );
        M_AWQOS    <= m_data(Q_AQOS_HI    downto Q_AQOS_LO   );
        M_AWREGION <= m_data(Q_AREGION_HI downto Q_AREGION_LO);
        M_AWVALID  <= '1' when (WRITE_ENABLE /= 0 and m_valid = '1' and m_data(Q_AWOK_POS) = '1') else '0';
    end block;
end RTL;
