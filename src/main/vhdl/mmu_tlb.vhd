-----------------------------------------------------------------------------------
--!     @file    mmu_tlb.vhd
--!     @brief   MMU Translation-Lookaside-Buffer 
--!     @version 1.0.0
--!     @date    2014/9/14
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
--! @brief   MMU_TLB : MMU Translation-Lookaside-Buffer
-----------------------------------------------------------------------------------
entity  MMU_TLB is
    generic (
        TAG_HI      : integer := 32;
        TAG_LO      : integer := 12;
        TAG_SETS    : integer :=  4;
        TAG_WAYS    : integer :=  0;
        DATA_BITS   : integer := 32;
        ADDR_BITS   : integer :=  4;
        SEL_SDPRAM  : integer :=  0
    );
    port (
        CLK         : in  std_logic; 
        RST         : in  std_logic;
        CLR         : in  std_logic;
        Q_TAG       : in  std_logic_vector(TAG_HI downto TAG_LO);
        Q_SET       : in  std_logic;
        Q_HIT       : out std_logic;
        Q_ERR       : out std_logic;
        Q_DATA      : out std_logic_vector(DATA_BITS-1 downto 0);
        S_CLR       : in  std_logic;
        S_START     : in  std_logic;
        S_TAG       : in  std_logic_vector(TAG_HI downto TAG_LO);
        S_DONE      : in  std_logic;
        S_ERR       : in  std_logic;
        S_ADDR      : in  std_logic_vector(ADDR_BITS  -1 downto 0);
        S_DATA      : in  std_logic_vector(DATA_BITS  -1 downto 0);
        S_BEN       : in  std_logic_vector(DATA_BITS/8-1 downto 0);
        S_WE        : in  std_logic
    );
end MMU_TLB;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PipeWork;
use     PipeWork.PRIORITY_ENCODER_PROCEDURES.all;
use     PipeWork.Components.SDPRAM;
architecture RTL of MMU_TLB is
    -------------------------------------------------------------------------------
    -- 指定されたベクタのリダクション論理和を求める関数.
    -------------------------------------------------------------------------------
    function  or_reduce(Arg : std_logic_vector) return std_logic is
        variable result : std_logic;
    begin
        result := '0';
        for i in Arg'range loop
            result := result or Arg(i);
        end loop;
        return result;
    end function;
    -------------------------------------------------------------------------------
    -- 指定されたサイズを表現するのに必要なビット数を計算する関数.
    -------------------------------------------------------------------------------
    function calc_width(NUM:integer) return integer is
        variable value : integer;
    begin
        value := 0;
        while (2**value < NUM) loop
            value := value + 1;
        end loop;
        return value;
    end function;
    -------------------------------------------------------------------------------
    -- データを保持するのに SDPRAM を使うか レジスタを使うかを選択する.
    -------------------------------------------------------------------------------
    constant  USE_SDPRAM        :  boolean := ((SEL_SDPRAM >  0) and
                                               (SEL_SDPRAM <= (2**TAG_WAYS)*TAG_SETS));
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  ADDR_WAYS_LO      :  integer := calc_width(DATA_BITS/8);
    -------------------------------------------------------------------------------
    -- TAG の状態を示すタイプ
    -------------------------------------------------------------------------------
    subtype   TAG_STATE_TYPE    is std_logic_vector(2 downto 0);
    constant  TAG_INVALID       :  std_logic_vector(2 downto 0) := "000";
    constant  TAG_LOADING       :  std_logic_vector(2 downto 0) := "100";
    constant  TAG_VALID_OK      :  std_logic_vector(2 downto 0) := "001";
    constant  TAG_VALID_ERR     :  std_logic_vector(2 downto 0) := "011";
    -------------------------------------------------------------------------------
    -- TAG のデータタイプ
    -------------------------------------------------------------------------------
    subtype   TAG_DATA_TYPE     is std_logic_vector(TAG_HI downto TAG_LO+TAG_WAYS);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal    tag_val_hit       :  std_logic_vector(TAG_SETS-1 downto 0);
    signal    tag_val_err       :  std_logic_vector(TAG_SETS-1 downto 0);
    signal    tag_hit           :  std_logic_vector(TAG_SETS-1 downto 0);
    signal    tag_load          :  std_logic_vector(TAG_SETS-1 downto 0);
    signal    lru_load          :  std_logic_vector(TAG_SETS-1 downto 0);
    signal    lru_select        :  std_logic_vector(TAG_SETS-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    component MMU_TLB_LRU
        generic (
            NUM_SETS    : integer := 4
        );
        port (
            CLK         : in  std_logic; 
            RST         : in  std_logic;
            CLR         : in  std_logic;
            I_HIT       : in  std_logic_vector(NUM_SETS-1 downto 0);
            Q_SEL       : out std_logic_vector(NUM_SETS-1 downto 0);
            O_SEL       : out std_logic_vector(NUM_SETS-1 downto 0)
        );
    end component;
    
begin
    -------------------------------------------------------------------------------
    -- Tag Data and Status
    -------------------------------------------------------------------------------
    TAG: for i in 0 to TAG_SETS-1 generate
        signal    data          :  TAG_DATA_TYPE;
        signal    state         :  TAG_STATE_TYPE;
        signal    data_hit      :  boolean;
    begin
        process (CLK, RST) begin
            if (RST = '1') then
                    data  <= (others => '0');
                    state <= TAG_INVALID;
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1' or S_CLR = '1') then
                    data  <= (others => '0');
                    state <= TAG_INVALID;
                elsif (state = TAG_LOADING) then
                    if (S_DONE = '1') then
                        if (S_ERR = '1') then
                            state <= TAG_VALID_ERR;
                        else
                            state <= TAG_VALID_OK;
                        end if;
                    end if;
                elsif (S_START = '1' and lru_select(i) = '1') then
                    data  <= S_TAG(TAG_DATA_TYPE'range);
                    state <= TAG_LOADING;
                end if;
            end if;
        end process;
        data_hit   <= (Q_TAG(TAG_DATA_TYPE'range) = data);
        tag_val_hit(i) <= '1' when (data_hit and state(0) = '1') else '0';
        tag_val_err(i) <= '1' when (data_hit and state(1) = '1') else '0';
        tag_load(i)    <= '1' when (state(2) = '1') else '0';
    end generate;
    -------------------------------------------------------------------------------
    -- Tag Hit Priority Encoding
    -------------------------------------------------------------------------------
    process (tag_val_hit, tag_val_err)
        variable valid   : std_logic;
        variable one_hot : std_logic_vector(TAG_SETS-1 downto 0);
    begin
        Priority_Encode_To_OneHot_Simply(
            High_to_Low => FALSE      , -- In : tag_val_hit(0)の方が優先順位が高い.
            Data        => tag_val_hit, -- In : 入力データ.
            Output      => one_hot    , -- Out: 出力変数.
            Valid       => valid        -- Out: tag_val_hit のどれかが'1'の時に真.
        );
        tag_hit <= one_hot;
        Q_HIT   <= valid;
        if (or_reduce(one_hot and tag_val_err) = '1') then
            Q_ERR <= '1';
        else
            Q_ERR <= '0';
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- TLBのセットから最も過去に選択したエントリを選択する.
    -------------------------------------------------------------------------------
    LRU: MMU_TLB_LRU generic map (NUM_SETS => TAG_SETS) port map(
            CLK         => CLK         , -- In  :
            RST         => RST         , -- In  :
            CLR         => CLR         , -- In  :
            I_HIT       => lru_load    , -- In  :
            Q_SEL       => open        , -- Out :
            O_SEL       => lru_select    -- Out :
        );
    lru_load <= tag_hit when (Q_SET = '1') else (others => '0');
    -------------------------------------------------------------------------------
    -- TLB DATA を RAMに保持する場合...
    -------------------------------------------------------------------------------
    DATA_RAMS: if (USE_SDPRAM = TRUE) generate
        constant  DATA_WIDTH :  integer := calc_width(DATA_BITS);
        constant  WAYS_WIDTH :  integer := TAG_WAYS;
        constant  SETS_WIDTH :  integer := calc_width(TAG_SETS);
        constant  RAM_DEPTH  :  integer := DATA_WIDTH + WAYS_WIDTH + SETS_WIDTH;
        signal    ram_raddr  :  std_logic_vector(RAM_DEPTH downto DATA_WIDTH);
        signal    ram_waddr  :  std_logic_vector(RAM_DEPTH downto DATA_WIDTH);
        signal    ram_rdata  :  std_logic_vector(2**(DATA_WIDTH  )-1 downto 0);
        signal    ram_wdata  :  std_logic_vector(2**(DATA_WIDTH  )-1 downto 0);
        signal    ram_we     :  std_logic_vector(2**(DATA_WIDTH-3)-1 downto 0);
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (tag_load, S_ADDR, S_BEN, S_WE)
            variable valid : std_logic;
            variable addr  : std_logic_vector(SETS_WIDTH+WAYS_WIDTH-1 downto 0);
        begin
            if (TAG_WAYS > 0) then
                for i in 0 to WAYS_WIDTH-1 loop
                    addr(i) := S_ADDR(ADDR_WAYS_LO+i);
                end loop;
            end if;
            if (TAG_SETS > 1) then
                Priority_Encode_To_Binary_Simply(
                    High_to_Low => FALSE     ,
                    Binary_Len  => SETS_WIDTH,
                    Data        => tag_load  ,
                    Output      => addr(addr'high downto addr'high-(SETS_WIDTH-1)),
                    Valid       => valid
                );
            else
                valid := '1';
            end if;
            ram_waddr <= addr;
            for i in ram_we'range loop
                if (valid = '1' and S_WE = '1' and S_BEN'low <= i and i <= S_BEN'high) then
                    ram_we(i) <= S_BEN(i);
                else
                    ram_we(i) <= '0';
                end if;
            end loop;
        end process;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (tag_val_hit, Q_TAG)
            variable valid : std_logic;
            variable addr  : std_logic_vector(SETS_WIDTH+WAYS_WIDTH-1 downto 0);
        begin
            if (TAG_WAYS > 0) then
                for i in 0 to WAYS_WIDTH-1 loop
                    addr(i) := Q_TAG(TAG_LO+i);
                end loop;
            end if;
            if (TAG_SETS > 1) then
                Priority_Encode_To_Binary_Simply(
                    High_to_Low => FALSE      ,
                    Binary_Len  => SETS_WIDTH ,
                    Data        => tag_val_hit,
                    Output      => addr(addr'high downto addr'high-(SETS_WIDTH-1)),
                    Valid       => valid
                );
            else
                valid := '1';
            end if;
            ram_raddr <= addr;
        end process;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (S_DATA) begin
            for i in ram_wdata'range loop
                if (ram_wdata'low <= i and i <= ram_wdata'high) then
                    ram_wdata(i) <= S_DATA(i);
                else
                    ram_wdata(i) <= '0';
                end if;
            end loop;
        end process;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        RAMS:  SDPRAM 
            generic map (
                DEPTH   => RAM_DEPTH   ,
                RWIDTH  => DATA_WIDTH  ,
                WWIDTH  => DATA_WIDTH  ,
                WEBIT   => DATA_WIDTH-3,
                ID      => 0
            )
            port map (
                WCLK    => CLK         , -- In  :
                WE      => ram_we      , -- In  :
                WADDR   => ram_waddr   , -- In  :
                WDATA   => ram_wdata   , -- In  :
                RCLK    => CLK         , -- In  :
                RADDR   => ram_raddr   , -- In  :
                RDATA   => ram_rdata     -- Out :
            );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        Q_DATA <= ram_rdata(Q_DATA'range);
    end generate;
    -------------------------------------------------------------------------------
    -- TLB DATA を REGS(F/F)に保持する場合...
    -------------------------------------------------------------------------------
    DATA_REGS: if (USE_SDPRAM = FALSE) generate
        subtype   DATA_TYPE          is std_logic_vector(DATA_BITS-1 downto 0);
        type      DATA_VECTOR        is array(integer range <>) of DATA_TYPE;
        type      DATA_REGS_TYPE     is array(0 to TAG_SETS-1) of DATA_VECTOR(0 to TAG_WAYS-1);
        signal    data_regs          :  DATA_REGS_TYPE;
        function  select_data(VEC: DATA_VECTOR;SEL: std_logic_vector) return DATA_TYPE is
            variable tmp     : std_logic_vector(SEL'high downto SEL'low);
            variable result  : DATA_TYPE;
        begin
            for i in result'range loop
                for n in tmp'range loop
                    if (SEL(n) = '1') then
                        tmp(n) := VEC(n)(i);
                    else
                        tmp(n) := '0';
                    end if;
                end loop;
                result(i) := or_reduce(tmp);
            end loop;
            return result;
        end function;
    begin
        ---------------------------------------------------------------------------
        -- data_regs
        ---------------------------------------------------------------------------
        process (CLK, RST)
            variable  way_load   :  std_logic_vector(0 to 2**TAG_WAYS-1);
        begin
            if (RST = '1') then
                    data_regs <= (others => (others => (others => '0')));
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    data_regs <= (others => (others => (others => '0')));
                elsif (S_WE = '1') then
                    if (TAG_WAYS = 0) then
                        way_load(0) := '1';
                    else
                        for way_pos in way_load'range loop
                            if (way_pos = unsigned(S_ADDR(ADDR_WAYS_LO+TAG_WAYS-1 downto ADDR_WAYS_LO))) then
                                way_load(way_pos) := '1';
                            else
                                way_load(way_pos) := '0';
                            end if;
                        end loop;
                    end if;
                    for tag_pos in 0 to TAG_SETS-1 loop
                        for way_pos in 0 to 2**TAG_WAYS-1 loop
                            for i in 0 to DATA_BITS-1 loop
                                if (tag_load(tag_pos) = '1' and
                                    way_load(way_pos) = '1' and
                                    S_BEN(i/8)        = '1') then
                                    data_regs(tag_pos)(way_pos)(i) <= S_DATA(i);
                                end if;
                            end loop;
                        end loop;
                    end loop;
                end if;
            end if;
        end process;
        ---------------------------------------------------------------------------
        -- Q_DATA : 
        ---------------------------------------------------------------------------
        process (CLK, RST)
            variable  set_data   :  DATA_VECTOR     (0 to TAG_SETS   -1);
            variable  way_data   :  DATA_VECTOR     (0 to 2**TAG_WAYS-1);
            variable  way_select :  std_logic_vector(0 to 2**TAG_WAYS-1);
        begin
            if (RST = '1') then
                    Q_DATA <= (others => '0');
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    Q_DATA <= (others => '0');
                else
                    if (TAG_WAYS = 0) then
                        way_select(0) := '1';
                    else
                        for way_pos in way_select'range loop
                            if (way_pos = unsigned(Q_TAG(TAG_LO+TAG_WAYS-1 downto TAG_LO))) then
                                way_select(way_pos) := '1';
                            else
                                way_select(way_pos) := '0';
                            end if;
                        end loop;
                    end if;
                    for tag_pos in set_data'range loop
                        for way_pos in way_data'range loop
                            way_data(way_pos) := data_regs(tag_pos)(way_pos);
                        end loop;
                        set_data(tag_pos) := select_data(way_data, way_select);
                    end loop;
                    if (TAG_SETS > 1) then
                        Q_DATA <= select_data(set_data, tag_hit);
                    else
                        Q_DATA <= set_data(0);
                    end if;
                end if;
            end if;
        end process;
    end generate;
end RTL;
