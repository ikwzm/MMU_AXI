-----------------------------------------------------------------------------------
--!     @file    mmu_core.vhd
--!     @brief   MMU Core Module
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
--! @brief   MMU_CORE : MMU Core Module
-----------------------------------------------------------------------------------
entity  MMU_CORE is
    generic (
        DATA_BITS       : integer := 32;
        ADDR_BITS       : integer :=  4;
        PTR_BITS        : integer :=  4;
        MODE_BITS       : integer := 32;
        PREF_BITS       : integer := 32;
        USE_PREFETCH    : integer :=  1;
        SEL_SDPRAM      : integer :=  0
    );
    port (
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
        RESET_L         : in  std_logic;
        RESET_D         : in  std_logic;
        RESET_Q         : out std_logic;
        PREF_L          : in  std_logic_vector(PREF_BITS  -1 downto 0);
        PREF_D          : in  std_logic_vector(PREF_BITS  -1 downto 0);
        PREF_Q          : out std_logic_vector(PREF_BITS  -1 downto 0);
        MODE_L          : in  std_logic_vector(MODE_BITS  -1 downto 0);
        MODE_D          : in  std_logic_vector(MODE_BITS  -1 downto 0);
        MODE_Q          : out std_logic_vector(MODE_BITS  -1 downto 0);
        QUERY_REQ       : in  std_logic;
        QUERY_ADDR      : in  std_logic_vector(ADDR_BITS  -1 downto 0);
        QUERY_ACK       : out std_logic;
        QUERY_ERROR     : out std_logic;
        QUERY_DATA      : out std_logic_vector(DATA_BITS  -1 downto 0);
        F_REQ_VALID     : out std_logic;
        F_REQ_FIRST     : out std_logic;
        F_REQ_LAST      : out std_logic;
        F_REQ_READY     : in  std_logic;
        F_ACK_VALID     : in  std_logic;
        F_ACK_ERROR     : in  std_logic;
        F_ACK_NEXT      : in  std_logic;
        F_ACK_LAST      : in  std_logic;
        F_ACK_STOP      : in  std_logic;
        F_ACK_NONE      : in  std_logic;
        F_XFER_BUSY     : in  std_logic;
        F_XFER_ERROR    : in  std_logic := '0';
        F_XFER_DONE     : in  std_logic;
        F_BUF_DATA      : in  std_logic_vector(DATA_BITS  -1 downto 0);
        F_BUF_BEN       : in  std_logic_vector(DATA_BITS/8-1 downto 0);
        F_BUF_PTR       : in  std_logic_vector(PTR_BITS   -1 downto 0);
        F_BUF_WE        : in  std_logic
    );
end MMU_CORE;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PipeWork;
use     PipeWork.PRIORITY_ENCODER_PROCEDURES.all;
use     PipeWork.PUMP_COMPONENTS.PUMP_CONTROL_REGISTER;
architecture RTL of MMU_CORE is

    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    component MMU_TLB 
        generic (
            TAG_HI          : integer := 32;
            TAG_LO          : integer := 12;
            TAG_SETS        : integer :=  4;
            TAG_WAYS        : integer :=  0;
            DATA_BITS       : integer := 32;
            ADDR_BITS       : integer :=  4;
            NO_KEEP_DATA    : integer :=  0;
            SEL_SDPRAM      : integer :=  0
        );
        port (
            CLK             : in  std_logic; 
            RST             : in  std_logic;
            CLR             : in  std_logic;
            Q_TAG           : in  std_logic_vector(TAG_HI downto TAG_LO);
            Q_SET_LRU       : in  std_logic;
            Q_KEEP_DATA     : in  std_logic;
            Q_HIT           : out std_logic;
            Q_ERR           : out std_logic;
            Q_DATA          : out std_logic_vector(DATA_BITS-1 downto 0);
            S_CLR           : in  std_logic;
            S_START         : in  std_logic;
            S_TAG           : in  std_logic_vector(TAG_HI downto TAG_LO);
            S_DONE          : in  std_logic;
            S_ERR           : in  std_logic;
            S_ADDR          : in  std_logic_vector(ADDR_BITS  -1 downto 0);
            S_DATA          : in  std_logic_vector(DATA_BITS  -1 downto 0);
            S_BEN           : in  std_logic_vector(DATA_BITS/8-1 downto 0);
            S_WE            : in  std_logic
        );
    end component;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    constant  LEVEL             :  integer := 2;
    constant  QUERY_TAG_HI      :  integer := QUERY_ADDR'high;
    constant  QUERY_TAG_LO      :  integer := 12;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    type      LEVEL_INFO_TYPE   is record
              TAG_HI            :  integer;
              TAG_LO            :  integer;
              TAG_SETS          :  integer;
              TAG_WAYS          :  integer;
    end record;
    type      LEVEL_INFO_VECTOR is array(integer range <>) of LEVEL_INFO_TYPE;
    constant  LV                :  LEVEL_INFO_VECTOR(0 to LEVEL-1) := (
                                       0 => (TAG_HI   => QUERY_TAG_HI,
                                             TAG_LO   => QUERY_TAG_LO,
                                             TAG_SETS =>  2,  -- 2sets
                                             TAG_WAYS =>  3   -- 8ways = 2**3
                                       ),
                                       1 => (TAG_HI   => QUERY_TAG_HI,
                                             TAG_LO   => QUERY_TAG_LO+10,
                                             TAG_SETS =>  1,  -- 1sets
                                             TAG_WAYS =>  0   -- 1ways = 2**0
                                       )
                                   );
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    subtype   TLB_DATA_TYPE     is std_logic_vector(DATA_BITS-1 downto 0);
    type      TLB_DATA_VECTOR   is array (integer range <>) of TLB_DATA_TYPE;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal    tlb_query_tag     :  std_logic_vector(QUERY_TAG_HI downto 0);
    signal    tlb_query_set     :  std_logic;
    signal    tlb_clear         :  std_logic;
    signal    tlb_query_hit     :  std_logic_vector(LEVEL   downto 0);
    signal    tlb_query_error   :  std_logic_vector(LEVEL   downto 0);
    signal    tlb_query_data    :  TLB_DATA_VECTOR (LEVEL   downto 0);
    signal    tlb_fetch_tag     :  std_logic_vector(QUERY_TAG_HI downto 0);
    signal    tlb_fetch_hit     :  std_logic_vector(LEVEL   downto 0);
    signal    tlb_fetch_sel_d   :  std_logic_vector(LEVEL-1 downto 0);
    signal    tlb_fetch_sel_q   :  std_logic_vector(LEVEL-1 downto 0);
    signal    tlb_fetch_start   :  std_logic_vector(LEVEL-1 downto 0);
    signal    tlb_fetch_done    :  std_logic_vector(LEVEL-1 downto 0);
    signal    tlb_fetch_error   :  std_logic_vector(LEVEL-1 downto 0);
    signal    tlb_fetch_wen     :  std_logic_vector(LEVEL-1 downto 0);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    type      QUERY_STATE_TYPE  is (QUERY_IDLE, QUERY_RUN, QUERY_DONE, QUERY_PREF);
    signal    query_state       :  QUERY_STATE_TYPE;
    signal    start_bit         :  std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    type      FETCH_STATE_TYPE  is (FETCH_IDLE, FETCH_START, FETCH_XFER);
    signal    fetch_state       :  FETCH_STATE_TYPE;
    signal    fetch_xfer_start  :  std_logic;
    signal    fetch_xfer_done   :  std_logic;
    signal    fetch_xfer_error  :  std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal    reset_regs        :  std_logic;
begin
    -------------------------------------------------------------------------------
    -- QUERY STATE MACHINE
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                query_state <= QUERY_IDLE;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                query_state <= QUERY_IDLE;
            else
                case query_state is
                    when QUERY_IDLE =>
                        if     (QUERY_REQ = '1') then
                                query_state <= QUERY_DONE;
                        elsif (start_bit = '1') then
                            if (USE_PREFETCH /= 0) then
                                query_state <= QUERY_PREF;
                            else
                                query_state <= QUERY_RUN;
                            end if;
                        else
                                query_state <= QUERY_IDLE;
                        end if;
                    when QUERY_RUN =>
                        if (QUERY_REQ = '1' and tlb_query_hit(0) = '1') then
                            if (USE_PREFETCH /= 0) then
                                query_state <= QUERY_PREF;
                            else
                                query_state <= QUERY_DONE;
                            end if;
                        elsif (start_bit = '1') then
                                query_state <= QUERY_IDLE;
                        else
                                query_state <= QUERY_RUN;
                        end if;
                    when QUERY_DONE =>
                        if    (start_bit = '0') then
                            query_state <= QUERY_IDLE;
                        else
                            query_state <= QUERY_RUN;
                        end if;
                    when QUERY_PREF =>
                        if    (USE_PREFETCH = 0) then
                            query_state <= QUERY_IDLE;
                        elsif (start_bit = '0') then
                            query_state <= QUERY_IDLE;
                        elsif (QUERY_REQ = '1' or tlb_query_hit(0) = '1') then
                            query_state <= QUERY_RUN;
                        else
                            query_state <= QUERY_PREF;
                        end if;
                    when others => 
                            query_state <= QUERY_IDLE;
                end case;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- QUERY_ACK/QUERY_ERR/QUERY_DATA
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                QUERY_ACK   <= '0';
                QUERY_ERROR <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                QUERY_ACK   <= '0';
                QUERY_ERROR <= '0';
            elsif (query_state = QUERY_RUN and QUERY_REQ = '1' and tlb_query_hit(0) = '1') then
                QUERY_ACK   <= '1';
                QUERY_ERROR <= tlb_query_error(0);
            elsif (query_state = QUERY_IDLE    and QUERY_REQ = '1') then
                QUERY_ACK   <= '1';
                QUERY_ERROR <= '1';
            else
                QUERY_ACK   <= '0';
                QUERY_ERROR <= '0';
            end if;
        end if;
    end process;
    QUERY_DATA <= tlb_query_data(0);
    -------------------------------------------------------------------------------
    -- プリフェッチを使う場合...
    -------------------------------------------------------------------------------
    PREFETCH_ON  : if (USE_PREFETCH /= 0) generate
        signal  prefetch_regs :  std_logic_vector(PREF_BITS-1 downto 0);
        signal  prefetch_addr :  std_logic_vector(QUERY_ADDR'range);
    begin
        process (CLK, RST)
            constant REGS_ADDR  : unsigned(LV(0).TAG_HI downto LV(0).TAG_LO+LV(0).TAG_WAYS) := (others => '0');
            variable curr_addr  : unsigned(REGS_ADDR'length-1 downto 0);
            variable next_addr  : unsigned(REGS_ADDR'length-1 downto 0);
        begin
            if (RST = '1') then
                    prefetch_regs <= (others => '0');
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    prefetch_regs <= (others => '0');
                elsif (query_state = QUERY_RUN and QUERY_REQ = '1' and tlb_query_hit(0) = '1') then
                    curr_addr := unsigned(prefetch_regs(REGS_ADDR'range));
                    next_addr := curr_addr + 1;
                    for i in prefetch_regs'range loop
                        if (REGS_ADDR'low <= i and i <= REGS_ADDR'high) then
                            if (next_addr(i-REGS_ADDR'low) = '1') then
                                prefetch_regs(i) <= '1';
                            else
                                prefetch_regs(i) <= '0';
                            end if;
                        else
                                prefetch_regs(i) <= '0';
                        end if;
                    end loop;
                else
                    for i in prefetch_regs'range loop
                        if (REGS_ADDR'low <= i and i <= REGS_ADDR'high) then
                            if (PREF_L(i) = '1') then
                                prefetch_regs(i) <= PREF_D(i);
                            end if;
                        else
                                prefetch_regs(i) <= '0';
                        end if;
                    end loop;
                end if;
            end if;
        end process;
        process(prefetch_regs) begin
            for i in prefetch_addr'range loop
                if (prefetch_regs'low <= i and i <= prefetch_regs'high) then
                    prefetch_addr(i) <= prefetch_regs(i);
                else
                    prefetch_addr(i) <= '0';
                end if;
            end loop;
        end process;
        tlb_query_tag <= QUERY_ADDR when (query_state = QUERY_RUN) else prefetch_addr;
        tlb_query_set <= '1'        when (query_state = QUERY_RUN) else '0';
        PREF_Q  <= prefetch_addr;
    end generate;
    -------------------------------------------------------------------------------
    -- プリフェッチを使わない場合...
    -------------------------------------------------------------------------------
    PREFETCH_OFF : if (USE_PREFETCH  = 0) generate
        tlb_query_tag <= QUERY_ADDR;
        tlb_query_set <= '1';
        PREF_Q  <= (others => '0');
    end generate;
    -------------------------------------------------------------------------------
    -- TLB
    -------------------------------------------------------------------------------
    TLB: for i in 0 to LEVEL-1 generate
        signal    q_tag     :  std_logic_vector(LV(i).TAG_HI downto LV(i).TAG_LO);
        signal    s_tag     :  std_logic_vector(LV(i).TAG_HI downto LV(i).TAG_LO);
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        q_tag <= tlb_query_tag(q_tag'range);
        s_tag <= tlb_fetch_tag(s_tag'range);
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        U: MMU_TLB                                       -- 
            generic map (                                -- 
                TAG_HI          => LV(i).TAG_HI        , -- 
                TAG_LO          => LV(i).TAG_LO        , -- 
                TAG_SETS        => LV(i).TAG_SETS      , -- 
                TAG_WAYS        => LV(i).TAG_WAYS      , -- 
                DATA_BITS       => DATA_BITS           , -- 
                ADDR_BITS       => PTR_BITS            , --
                NO_KEEP_DATA    => i                   , --
                SEL_SDPRAM      => SEL_SDPRAM            -- 
            )                                            -- 
            port map (                                   -- 
                CLK             => CLK                 , -- In  :
                RST             => RST                 , -- In  :
                CLR             => CLR                 , -- In  :
                Q_TAG           => q_tag               , -- In  :
                Q_SET_LRU       => tlb_query_set       , -- In  :
                Q_KEEP_DATA     => QUERY_REQ           , -- In  :
                Q_HIT           => tlb_query_hit  (i)  , -- Out :
                Q_ERR           => tlb_query_error(i)  , -- Out :
                Q_DATA          => tlb_query_data (i)  , -- Out :
                S_CLR           => reset_regs          , -- In  :
                S_START         => tlb_fetch_start(i)  , -- In  :
                S_TAG           => s_tag               , -- In  :
                S_DONE          => tlb_fetch_done (i)  , -- In  :
                S_ERR           => tlb_fetch_error(i)  , -- In  :
                S_ADDR          => F_BUF_PTR           , -- In  :
                S_DATA          => F_BUF_DATA          , -- In  :
                S_BEN           => F_BUF_BEN           , -- In  :
                S_WE            => tlb_fetch_wen  (i)    -- In  :
            );                                           -- 
    end generate;                                        -- 
    -------------------------------------------------------------------------------
    -- FETCH STATE MACHINE
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                fetch_state     <= FETCH_IDLE;
                tlb_fetch_tag   <= (others => '0');
                tlb_fetch_hit   <= (others => '0');
                tlb_fetch_sel_q <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                fetch_state     <= FETCH_IDLE;
                tlb_fetch_tag   <= (others => '0');
                tlb_fetch_hit   <= (others => '0');
                tlb_fetch_sel_q <= (others => '0');
            else
                case fetch_state is
                    when FETCH_IDLE =>
                        if (query_state = QUERY_RUN  and QUERY_REQ    = '1' and tlb_query_hit(0) = '0') or
                           (query_state = QUERY_PREF and USE_PREFETCH /= 0  and tlb_query_hit(0) = '0') then
                            fetch_state <= FETCH_START;
                        else
                            fetch_state <= FETCH_IDLE;
                        end if;
                        tlb_fetch_tag   <= tlb_query_tag;
                        tlb_fetch_hit   <= tlb_query_hit;
                        tlb_fetch_sel_q <= (others => '0');
                    when FETCH_START => 
                        fetch_state     <= FETCH_XFER;
                        tlb_fetch_sel_q <= tlb_fetch_sel_d;
                    when FETCH_XFER  =>
                        if (fetch_xfer_done = '1') then
                            fetch_state     <= FETCH_IDLE;
                            tlb_fetch_sel_q <= (others => '0');
                        else
                            fetch_state <= FETCH_XFER;
                        end if;
                    when others =>
                            fetch_state     <= FETCH_IDLE;
                            tlb_fetch_sel_q <= (others => '0');
                end case;
            end if;
        end if;
    end process;
    fetch_xfer_start <= '1'             when (fetch_state = FETCH_START) else '0';
    tlb_fetch_start  <= tlb_fetch_sel_d when (fetch_state = FETCH_START) else (others => '0');
    tlb_fetch_done   <= tlb_fetch_sel_q when (fetch_xfer_done     = '1') else (others => '0');
    tlb_fetch_error  <= tlb_fetch_sel_q when (fetch_xfer_error    = '1') else (others => '0');
    tlb_fetch_wen    <= tlb_fetch_sel_q when (F_BUF_WE            = '1') else (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (tlb_fetch_hit)
        variable valid   : std_logic;
        variable tlb_hit : std_logic_vector(LEVEL-1 downto 0);
        variable one_hot : std_logic_vector(LEVEL-1 downto 0);
    begin
        tlb_hit := tlb_fetch_hit(LEVEL downto 1);
        Priority_Encode_To_OneHot_Simply(
            High_to_Low => FALSE      , -- In : tag_val_hit(0)の方が優先順位が高い.
            Data        => tlb_hit    , -- In : 入力データ.
            Output      => one_hot    , -- Out: 出力変数.
            Valid       => valid        -- Out: tag_val_hit のどれかが'1'の時に真.
        );
        tlb_fetch_sel_d <= one_hot;
    end process;
    -------------------------------------------------------------------------------
    -- FETCH CONTROL REGISTER
    -------------------------------------------------------------------------------
    FETCH_CTRL: PUMP_CONTROL_REGISTER                -- 
        generic map (                                -- 
            MODE_BITS       => MODE_BITS           , --
            STAT_BITS       => 1                     -- 
        )                                            -- 
        port map (                                   -- 
            CLK             => CLK                 , -- In  :
            RST             => RST                 , -- In  :
            CLR             => CLR                 , -- In  :
            RESET_L         => RESET_L             , -- In  :
            RESET_D         => RESET_D             , -- In  :
            RESET_Q         => reset_regs          , -- Out :
            START_L         => fetch_xfer_start    , -- In  :
            START_D         => '1'                 , -- In  :
            START_Q         => open                , -- Out :
            STOP_L          => '0'                 , -- In  :
            STOP_D          => '0'                 , -- In  :
            STOP_Q          => open                , -- Out :
            PAUSE_L         => '0'                 , -- In  :
            PAUSE_D         => '0'                 , -- In  :
            PAUSE_Q         => open                , -- Out :
            FIRST_L         => fetch_xfer_start    , -- In  :
            FIRST_D         => '1'                 , -- In  :
            FIRST_Q         => open                , -- Out :
            LAST_L          => fetch_xfer_start    , -- In  :
            LAST_D          => '1'                 , -- In  :
            LAST_Q          => open                , -- Out :
            DONE_EN_L       => '0'                 , -- In  :
            DONE_EN_D       => '0'                 , -- In  :
            DONE_EN_Q       => open                , -- Out :
            DONE_ST_L       => '0'                 , -- In  :
            DONE_ST_D       => '0'                 , -- In  :
            DONE_ST_Q       => open                , -- Out :
            ERR_ST_L        => '0'                 , -- In  :
            ERR_ST_D        => '0'                 , -- In  :
            ERR_ST_Q        => open                , -- Out :
            MODE_L          => MODE_L              , -- In  :
            MODE_D          => MODE_D              , -- In  :
            MODE_Q          => MODE_Q              , -- Out :
            STAT_L          => "0"                 , -- In  :
            STAT_D          => "0"                 , -- In  :
            STAT_Q          => open                , -- Out :
            STAT_I          => open                , -- In  :
            REQ_VALID       => F_REQ_VALID         , -- Out :
            REQ_FIRST       => F_REQ_FIRST         , -- Out :
            REQ_LAST        => F_REQ_LAST          , -- Out :
            REQ_READY       => F_REQ_READY         , -- In  :
            ACK_VALID       => F_ACK_VALID         , -- In  :
            ACK_ERROR       => F_ACK_ERROR         , -- In  :
            ACK_NEXT        => F_ACK_NEXT          , -- In  :
            ACK_LAST        => F_ACK_LAST          , -- In  :
            ACK_STOP        => F_ACK_STOP          , -- In  :
            ACK_NONE        => F_ACK_NONE          , -- In  :
            XFER_BUSY       => F_XFER_BUSY         , -- In  :
            XFER_ERROR      => F_XFER_ERROR        , -- In  :
            XFER_DONE       => F_XFER_DONE         , -- In  :
            VALVE_OPEN      => open                , -- Out :
            TRAN_START      => open                , -- Out :
            TRAN_BUSY       => open                , -- Out :
            TRAN_DONE       => fetch_xfer_done     , -- Out :
            TRAN_ERROR      => fetch_xfer_error      -- Out :
        );
    RESET_Q <= reset_regs;
    
end RTL;
