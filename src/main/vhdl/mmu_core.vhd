-----------------------------------------------------------------------------------
--!     @file    mmu_core.vhd
--!     @brief   MMU Core Module
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
library ieee;
use     ieee.std_logic_1164.all;
-----------------------------------------------------------------------------------
--! @brief   MMU_CORE : MMU Core Module
-----------------------------------------------------------------------------------
entity  MMU_CORE is
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
end MMU_CORE;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PIPEWORK;
use     PIPEWORK.COMPONENTS.COUNT_UP_REGISTER;
use     PIPEWORK.COMPONENTS.COUNT_DOWN_REGISTER;
use     PIPEWORK.PUMP_COMPONENTS.PUMP_CONTROL_REGISTER;
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
    -- 
    -------------------------------------------------------------------------------
    procedure priority_encode_to_onehot_simply(
                 Data        : in  std_logic_vector;
                 Output      : out std_logic_vector;
                 Valid       : out std_logic
    ) is
        variable result      :     std_logic_vector(Data'range);
    begin
        for i in Data'range loop
            if (i = Data'low) then
                result(i) := Data(i);
            else
                result(i) := Data(i) and (not or_reduce(Data(i-1 downto Data'low)));
            end if;
        end loop;
        Output := result;
        Valid  := or_reduce(Data);
    end procedure;
     -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    type      BIT_FIELD_TYPE    is record
              BITS              :  integer;
              HI                :  integer;
              LO                :  integer;
    end record;
    function  BIT_FIELD(HI,LO:integer) return BIT_FIELD_TYPE is
        variable result :  BIT_FIELD_TYPE;
        constant vector :  std_logic_vector(HI downto LO) := (others => '0');
    begin
        result.HI   := vector'high;
        result.LO   := vector'low;
        result.BITS := vector'length;
        return result;
    end function;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    constant  LEVEL             :  integer := 2;
    constant  PAGE_INDEX_BITS   :  integer := PAGE_SIZE-DESC_SIZE;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    type      DESC_FORMAT_TYPE  is record
              TOTAL             :  BIT_FIELD_TYPE;
              ADDR              :  BIT_FIELD_TYPE;
              ENABLE            :  BIT_FIELD_TYPE;
    end record;
    constant  DESC_FORMAT       :  DESC_FORMAT_TYPE := (
                                       TOTAL   => BIT_FIELD(2**(DESC_SIZE+3)-1, 0),
                                       ADDR    => BIT_FIELD(2**(DESC_SIZE+3)-1, PAGE_SIZE),
                                       ENABLE  => BIT_FIELD(0,0)
                                   );
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    type      TAG_FORMAT_TYPE   is record
              TOTAL             :  BIT_FIELD_TYPE;
              PAGE_SEL          :  BIT_FIELD_TYPE;
              PAGE_INDEX        :  BIT_FIELD_TYPE;
    end record;
    function  TAG_FORMAT(HI,LO:integer) return TAG_FORMAT_TYPE is
        variable result : TAG_FORMAT_TYPE;
    begin
        result.TOTAL      := BIT_FIELD(HI,LO);
        result.PAGE_SEL   := BIT_FIELD(HI,LO+PAGE_INDEX_BITS);
        result.PAGE_INDEX := BIT_FIELD(LO+PAGE_INDEX_BITS-1, LO);
        return result;
    end function;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    type      LEVEL_INFO_TYPE   is record
              TAG_SETS          :  integer;
              TAG_WAYS          :  integer;
              TAG_FORM          :  TAG_FORMAT_TYPE;
              DESC_FORM         :  DESC_FORMAT_TYPE;
    end record;
    type      LEVEL_INFO_VECTOR is array(integer range <>) of LEVEL_INFO_TYPE;
    constant  LV                :  LEVEL_INFO_VECTOR(0 to LEVEL) := (
                                       0 => (TAG_SETS  => TLB_TAG_SETS,
                                             TAG_WAYS  => TLB_TAG_WAYS,
                                             TAG_FORM  => TAG_FORMAT(QUERY_ADDR'high, PAGE_SIZE+0*PAGE_INDEX_BITS),
                                             DESC_FORM => DESC_FORMAT
                                       ),
                                       1 => (TAG_SETS  => 1,  -- 1sets
                                             TAG_WAYS  => 0,  -- 1ways = 2**0
                                             TAG_FORM  => TAG_FORMAT(QUERY_ADDR'high, PAGE_SIZE+1*PAGE_INDEX_BITS),
                                             DESC_FORM => DESC_FORMAT
                                       ),
                                       2 => (TAG_SETS  => 0,  --  未使用
                                             TAG_WAYS  => 0,  --  未使用
                                             TAG_FORM  => TAG_FORMAT(QUERY_ADDR'high, QUERY_ADDR'high),
                                             DESC_FORM => DESC_FORMAT
                                       )
                                   );
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    constant  TLB_DATA_BITS     :  integer := 2**(DESC_SIZE+3);
    subtype   TLB_DATA_TYPE     is std_logic_vector(TLB_DATA_BITS-1 downto 0);
    type      TLB_DATA_VECTOR   is array (integer range <>) of TLB_DATA_TYPE;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal    tlb_query_tag     :  std_logic_vector(QUERY_ADDR'high downto 0);
    signal    tlb_query_set     :  std_logic;
    signal    tlb_clear         :  std_logic;
    signal    tlb_query_hit     :  std_logic_vector(LEVEL   downto 0);
    signal    tlb_query_error   :  std_logic_vector(LEVEL   downto 0);
    signal    tlb_query_data    :  TLB_DATA_VECTOR (LEVEL   downto 0);
    signal    tlb_fetch_tag     :  std_logic_vector(QUERY_ADDR'high downto 0);
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
    signal    reset_regs        :  std_logic;
    signal    desc_regs         :  std_logic_vector(2**(DESC_SIZE+3)-1 downto 0);
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
                        if (start_bit = '1') then
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
                        elsif (start_bit = '0') then
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
    process (query_state, QUERY_REQ, tlb_query_hit, tlb_query_error) begin
        if    (query_state = QUERY_RUN  and QUERY_REQ = '1' and tlb_query_hit(0) = '1') then
            QUERY_ACK   <= '1';
            QUERY_ERROR <= tlb_query_error(0);
        elsif (query_state = QUERY_IDLE and QUERY_REQ = '1') then
            QUERY_ACK   <= '1';
            QUERY_ERROR <= '1';
        else
            QUERY_ACK   <= '0';
            QUERY_ERROR <= '0';
        end if;
    end process;
    QUERY_DESC <= tlb_query_data(0);
    -------------------------------------------------------------------------------
    -- プリフェッチを使う場合...
    -------------------------------------------------------------------------------
    PREFETCH_ON  : if (USE_PREFETCH /= 0) generate
        signal  prefetch_regs :  std_logic_vector(PREF_BITS-1 downto 0);
        signal  prefetch_addr :  std_logic_vector(QUERY_ADDR'range);
    begin
        process (CLK, RST)
            constant TAG_HI     : integer := LV(0).TAG_FORM.TOTAL.HI;
            constant TAG_LO     : integer := LV(0).TAG_FORM.TOTAL.LO;
            constant TAG_WAYS   : integer := LV(0).TAG_WAYS;
            constant REGS_ADDR  : unsigned(TAG_HI downto TAG_LO+TAG_WAYS) := (others => '0');
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
        PREF_Q  <= prefetch_regs;
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
        signal    q_tag :  std_logic_vector(LV(i).TAG_FORM.TOTAL.HI downto LV(i).TAG_FORM.TOTAL.LO);
        signal    s_tag :  std_logic_vector(LV(i).TAG_FORM.TOTAL.HI downto LV(i).TAG_FORM.TOtAL.LO);
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        q_tag <= tlb_query_tag(q_tag'range);
        s_tag <= tlb_fetch_tag(s_tag'range);
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        U: MMU_TLB                                           -- 
            generic map (                                    -- 
                TAG_HI          => LV(i).TAG_FORM.TOTAL.HI , -- 
                TAG_LO          => LV(i).TAG_FORM.TOTAL.LO , -- 
                TAG_SETS        => LV(i).TAG_SETS          , -- 
                TAG_WAYS        => LV(i).TAG_WAYS          , -- 
                DATA_BITS       => TLB_DATA_BITS           , -- 
                ADDR_BITS       => FETCH_PTR_BITS          , --
                NO_KEEP_DATA    => i                       , --
                SEL_SDPRAM      => SEL_SDPRAM                -- 
            )                                                -- 
            port map (                                       -- 
                CLK             => CLK                     , -- In  :
                RST             => RST                     , -- In  :
                CLR             => CLR                     , -- In  :
                Q_TAG           => q_tag                   , -- In  :
                Q_SET_LRU       => tlb_query_set           , -- In  :
                Q_KEEP_DATA     => QUERY_REQ               , -- In  :
                Q_HIT           => tlb_query_hit  (i)      , -- Out :
                Q_ERR           => tlb_query_error(i)      , -- Out :
                Q_DATA          => tlb_query_data (i)      , -- Out :
                S_CLR           => reset_regs              , -- In  :
                S_START         => tlb_fetch_start(i)      , -- In  :
                S_TAG           => s_tag                   , -- In  :
                S_DONE          => tlb_fetch_done (i)      , -- In  :
                S_ERR           => tlb_fetch_error(i)      , -- In  :
                S_ADDR          => FETCH_BUF_PTR           , -- In  :
                S_DATA          => FETCH_BUF_DATA          , -- In  :
                S_BEN           => FETCH_BUF_BEN           , -- In  :
                S_WE            => tlb_fetch_wen  (i)        -- In  :
            );                                               -- 
    end generate;                                            -- 
    -------------------------------------------------------------------------------
    -- start_bit
    -------------------------------------------------------------------------------
    START: process (CLK, RST) begin
        if (RST = '1') then
                start_bit <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                start_bit <= '0';
            elsif (START_L = '1') then
                start_bit <= START_D;
            end if;
        end if;
    end process;
    START_Q <= start_bit;                    
    -------------------------------------------------------------------------------
    -- desc_regs
    -------------------------------------------------------------------------------
    DESC: process (CLK, RST) begin
        if (RST = '1') then
                desc_regs <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                desc_regs <= (others => '0');
            else
                for i in desc_regs'range loop
                    if (DESC_L(i) = '1') then
                        desc_regs(i) <= DESC_D(i);
                    end if;
                end loop;
            end if;
        end if;
    end process;
    DESC_Q <= desc_regs;
    tlb_query_data (LEVEL) <= desc_regs;
    tlb_query_hit  (LEVEL) <= '1';
    tlb_query_error(LEVEL) <= '0';
    -------------------------------------------------------------------------------
    -- FETCH STATE MACHINE
    -------------------------------------------------------------------------------
    FETCH: block
        type      STATE_TYPE    is (FETCH_IDLE, FETCH_START, FETCH_TRAN, FETCH_ABORT);
        signal    state         :  STATE_TYPE;
        signal    tran_start    :  std_logic;
        signal    tran_enable   :  std_logic;
        signal    tran_busy     :  std_logic;
        signal    tran_done     :  std_logic;
        signal    tran_error    :  std_logic;
        signal    tlb_hit_q     :  std_logic_vector(LEVEL   downto 0);
        signal    tlb_err_q     :  std_logic_vector(LEVEL   downto 0);
        signal    tlb_sel_d     :  std_logic_vector(LEVEL-1 downto 0);
        signal    tlb_sel_q     :  std_logic_vector(LEVEL-1 downto 0);
        constant  TLB_SEL_ALL0  :  std_logic_vector(LEVEL-1 downto 0) := (others => '0');
    begin
        ---------------------------------------------------------------------------
        -- FETCH STATE MACHINE
        ---------------------------------------------------------------------------
        process (CLK, RST) begin
            if (RST = '1') then
                    state         <= FETCH_IDLE;
                    tlb_fetch_tag <= (others => '0');
                    tlb_hit_q     <= (LEVEL => '1', others => '0');
                    tlb_err_q     <= (others => '0');
                    tlb_sel_q     <= (others => '0');
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    state         <= FETCH_IDLE;
                    tlb_fetch_tag <= (others => '0');
                    tlb_hit_q     <= (LEVEL => '1', others => '0');
                    tlb_err_q     <= (others => '0');
                    tlb_sel_q     <= (others => '0');
                else
                    case state is
                        when FETCH_IDLE =>
                            if (query_state = QUERY_RUN  and QUERY_REQ    = '1' and tlb_query_hit(0) = '0') or
                               (query_state = QUERY_PREF and USE_PREFETCH /= 0  and tlb_query_hit(0) = '0') then
                                state <= FETCH_START;
                            else
                                state <= FETCH_IDLE;
                            end if;
                            tlb_fetch_tag <= tlb_query_tag;
                            tlb_hit_q     <= tlb_query_hit;
                            tlb_err_q     <= tlb_query_error;
                            tlb_sel_q     <= (others => '0');
                        when FETCH_START =>
                            if (tran_enable = '1') then
                                state <= FETCH_TRAN;
                            else
                                state <= FETCH_ABORT;
                            end if;
                            tlb_sel_q <= tlb_sel_d;
                        when FETCH_TRAN  =>
                            if (tran_done = '1') then
                                state <= FETCH_IDLE;
                            else
                                state <= FETCH_TRAN;
                            end if;
                        when others =>
                                state     <= FETCH_IDLE;
                                tlb_sel_q <= (others => '0');
                    end case;
                end if;
            end if;
        end process;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        tlb_fetch_start  <= tlb_sel_d when (state = FETCH_START) else (others => '0');
        tlb_fetch_done   <= tlb_sel_q when (state = FETCH_TRAN and tran_done    = '1') or
                                           (state = FETCH_ABORT) else (others => '0');
        tlb_fetch_error  <= tlb_sel_q when (state = FETCH_TRAN and tran_error   = '1') or
                                           (state = FETCH_ABORT) else (others => '0');
        tlb_fetch_wen    <= tlb_sel_q when (state = FETCH_TRAN and FETCH_BUF_WE = '1') else (others => '0');
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (tlb_hit_q)
            variable valid   : std_logic;
            variable tlb_hit : std_logic_vector(LEVEL-1 downto 0);
            variable one_hot : std_logic_vector(LEVEL-1 downto 0);
        begin
            tlb_hit := tlb_hit_q(LEVEL downto 1);
            priority_encode_to_onehot_simply(
                Data        => tlb_hit    , -- In : 入力データ.
                Output      => one_hot    , -- Out: 出力変数.
                Valid       => valid        -- Out: tag_val_hit のどれかが'1'の時に真.
            );
            tlb_sel_d <= one_hot;
        end process;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        tran_start  <= '1' when (state = FETCH_START and tran_enable = '1') else '0';
        tran_enable <= '1' when ((tlb_sel_d and tlb_err_q(LEVEL-1 downto 0)) = TLB_SEL_ALL0) else '0';
        ---------------------------------------------------------------------------
        -- FETCH CONTROL REGISTER
        ---------------------------------------------------------------------------
        CTRL: PUMP_CONTROL_REGISTER                      -- 
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
                START_L         => tran_start          , -- In  :
                START_D         => '1'                 , -- In  :
                START_Q         => open                , -- Out :
                STOP_L          => '0'                 , -- In  :
                STOP_D          => '0'                 , -- In  :
                STOP_Q          => open                , -- Out :
                PAUSE_L         => '0'                 , -- In  :
                PAUSE_D         => '0'                 , -- In  :
                PAUSE_Q         => open                , -- Out :
                FIRST_L         => tran_start          , -- In  :
                FIRST_D         => '1'                 , -- In  :
                FIRST_Q         => open                , -- Out :
                LAST_L          => tran_start          , -- In  :
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
                STAT_I          => "0"                 , -- In  :
                REQ_VALID       => FETCH_REQ_VALID     , -- Out :
                REQ_FIRST       => FETCH_REQ_FIRST     , -- Out :
                REQ_LAST        => FETCH_REQ_LAST      , -- Out :
                REQ_READY       => FETCH_REQ_READY     , -- In  :
                ACK_VALID       => FETCH_ACK_VALID     , -- In  :
                ACK_ERROR       => FETCH_ACK_ERROR     , -- In  :
                ACK_NEXT        => FETCH_ACK_NEXT      , -- In  :
                ACK_LAST        => FETCH_ACK_LAST      , -- In  :
                ACK_STOP        => FETCH_ACK_STOP      , -- In  :
                ACK_NONE        => FETCH_ACK_NONE      , -- In  :
                XFER_BUSY       => FETCH_XFER_BUSY     , -- In  :
                XFER_ERROR      => FETCH_XFER_ERROR    , -- In  :
                XFER_DONE       => FETCH_XFER_DONE     , -- In  :
                VALVE_OPEN      => open                , -- Out :
                TRAN_START      => open                , -- Out :
                TRAN_BUSY       => tran_busy           , -- Out :
                TRAN_DONE       => tran_done           , -- Out :
                TRAN_ERROR      => tran_error            -- Out :
            );
        RESET_Q <= reset_regs;
        ---------------------------------------------------------------------------
        -- FETCH ADDR REGISTER
        ---------------------------------------------------------------------------
        ADDR: block
            subtype   ADDR_TYPE     is std_logic_vector(FETCH_ADDR_BITS-1 downto 0);
            type      ADDR_VECTOR   is array(integer range<>) of ADDR_TYPE;
            signal    addr_data     :  ADDR_TYPE;
            signal    addr_wen      :  ADDR_TYPE;
            constant  addr_up_ben   :  ADDR_TYPE := (11 downto 0 => '1', others => '0');
        begin
            -----------------------------------------------------------------------
            -- 
            -----------------------------------------------------------------------
            REGS: COUNT_UP_REGISTER                      -- 
                generic map (                            -- 
                    VALID       => 1                   , -- 
                    BITS        => FETCH_ADDR_BITS     , -- 
                    REGS_BITS   => FETCH_ADDR_BITS       -- 
                )                                        -- 
                port map (                               -- 
                    CLK         => CLK                 , -- In  :
                    RST         => RST                 , -- In  :
                    CLR         => CLR                 , -- In  :
                    REGS_WEN    => addr_wen            , -- In  :
                    REGS_WDATA  => addr_data           , -- In  :
                    REGS_RDATA  => open                , -- Out :
                    UP_ENA      => '1'                 , -- In  :
                    UP_VAL      => FETCH_ACK_VALID     , -- In  :
                    UP_BEN      => addr_up_ben         , -- In  :
                    UP_SIZE     => FETCH_ACK_SIZE      , -- In  :
                    COUNTER     => FETCH_REQ_ADDR        -- Out :
                );                                       --
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            process (tlb_sel_d, tlb_query_data, tlb_fetch_tag)
                variable addr_vec      :  ADDR_VECTOR(tlb_sel_d'range);
                function make_addr(
                             DESC_DATA :  TLB_DATA_TYPE;
                    constant DESC_FORM :  DESC_FORMAT_TYPE;
                             TAG_DATA  :  std_logic_vector;
                    constant TAG_FORM  :  TAG_FORMAT_TYPE ;
                    constant TAG_WAYS  :  integer
                )            return       ADDR_TYPE
                is
                    variable base      :  ADDR_TYPE;
                    variable index     :  ADDR_TYPE;
                    variable addr      :  ADDR_TYPE;
                begin
                    for i in ADDR_TYPE'range loop
                        if (i <= DESC_FORM.ADDR.HI) and
                           (i >= DESC_FORM.ADDR.LO) then
                            base(i) := DESC_DATA(i);
                        else
                            base(i) := '0';
                        end if;
                    end loop;
                    for i in ADDR_TYPE'range loop
                        if (i+TAG_FORM.PAGE_INDEX.LO-DESC_SIZE <= TAG_FORM.PAGE_INDEX.HI) and
                           (i+TAG_FORM.PAGE_INDEX.LO-DESC_SIZE >= TAG_FORM.PAGE_INDEX.LO+TAG_WAYS) then
                            index(i) := TAG_DATA(i+TAG_FORM.PAGE_INDEX.LO-DESC_SIZE);
                        else
                            index(i) := '0';
                        end if;
                    end loop;
                    if (TAG_FORM.PAGE_INDEX.HI-(TAG_FORM.PAGE_INDEX.LO-DESC_SIZE) >= DESC_FORM.ADDR.LO) then
                        addr := std_logic_vector(unsigned(base)+unsigned(index));
                    else
                        addr := base or index;
                    end if;
                    return addr;
                end function;
                function select_addr(VEC: ADDR_VECTOR;SEL: std_logic_vector) return ADDR_TYPE is
                    variable tmp      : std_logic_vector(SEL'high downto SEL'low);
                    variable result   : ADDR_TYPE;
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
                for tlb in tlb_sel_d'low to tlb_sel_d'high loop
                    addr_vec(tlb) := make_addr(
                                         DESC_DATA => tlb_query_data(tlb+1),
                                         DESC_FORM => LV(tlb+1).DESC_FORM  ,
                                         TAG_DATA  => tlb_fetch_tag        ,
                                         TAG_FORM  => LV(tlb).TAG_FORM     ,
                                         TAG_WAYS  => LV(tlb).TAG_WAYS
                                     );
                end loop;
                addr_data <= select_addr(addr_vec, tlb_sel_d);
            end process;
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            addr_wen <= (others => '1') when (tran_start = '1') else (others => '0');
        end block;
        ---------------------------------------------------------------------------
        -- FETCH SIZE REGISTER
        ---------------------------------------------------------------------------
        SIZE: block
            subtype   SIZE_TYPE     is std_logic_vector(FETCH_SIZE_BITS-1 downto 0);
            type      SIZE_VECTOR   is array(integer range<>) of SIZE_TYPE;
            signal    size_data     :  SIZE_TYPE;
            signal    size_wen      :  SIZE_TYPE;
        begin
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            REGS: COUNT_DOWN_REGISTER                    -- 
                generic map (                            -- 
                    VALID       => 1                   , -- 
                    BITS        => FETCH_SIZE_BITS     , -- 
                    REGS_BITS   => FETCH_SIZE_BITS       -- 
                )                                        -- 
                port map (                               -- 
                    CLK         => CLK                 , -- In  :
                    RST         => RST                 , -- In  :
                    CLR         => CLR                 , -- In  :
                    REGS_WEN    => size_wen            , -- In  :
                    REGS_WDATA  => size_data           , -- In  :
                    REGS_RDATA  => open                , -- Out :
                    DN_ENA      => '1'                 , -- In  :
                    DN_VAL      => FETCH_ACK_VALID     , -- In  :
                    DN_SIZE     => FETCH_ACK_SIZE      , -- In  :
                    COUNTER     => FETCH_REQ_SIZE      , -- Out :
                    ZERO        => open                , -- Out :
                    NEG         => open                  -- Out :
               );                                        -- 
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            process (tlb_sel_d)
                variable size_vec      :  SIZE_VECTOR(tlb_sel_d'range);
                function select_size(VEC: SIZE_VECTOR;SEL: std_logic_vector) return SIZE_TYPE is
                    variable tmp      : std_logic_vector(SEL'high downto SEL'low);
                    variable result   : SIZE_TYPE;
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
                for tlb in tlb_sel_d'low to tlb_sel_d'high loop
                    size_vec(tlb) := std_logic_vector(to_unsigned(2**(LV(tlb).TAG_WAYS+DESC_SIZE), FETCH_SIZE_BITS));
                end loop;
                size_data <= select_size(size_vec, tlb_sel_d);
            end process;
        end block;
        ---------------------------------------------------------------------------
        -- FETCH BUF PTR REGISTER
        ---------------------------------------------------------------------------
        BUF_PTR: block
            constant  ALL_ZERO : std_logic_vector(FETCH_PTR_BITS-1 downto 0) := (others => '0');
            constant  ALL_ONE  : std_logic_vector(FETCH_PTR_BITS-1 downto 0) := (others => '1');
            signal    wen      : std_logic_vector(FETCH_PTR_BITS-1 downto 0);
        begin 
            -----------------------------------------------------------------------
            -- 
            -----------------------------------------------------------------------
            REGS: COUNT_UP_REGISTER                      -- 
                generic map (                            -- 
                    VALID       => 1                   , -- 
                    BITS        => FETCH_PTR_BITS      , -- 
                    REGS_BITS   => FETCH_PTR_BITS        -- 
                )                                        -- 
                port map (                               -- 
                    CLK         => CLK                 , -- In  :
                    RST         => RST                 , -- In  :
                    CLR         => CLR                 , -- In  :
                    REGS_WEN    => wen                 , -- In  :
                    REGS_WDATA  => ALL_ZERO            , -- In  :
                    REGS_RDATA  => open                , -- Out :
                    UP_ENA      => '1'                 , -- In  :
                    UP_VAL      => FETCH_ACK_VALID     , -- In  :
                    UP_BEN      => ALL_ONE             , -- In  :
                    UP_SIZE     => FETCH_ACK_SIZE      , -- In  :
                    COUNTER     => FETCH_REQ_PTR         -- Out :
                );                                       --
            wen <= ALL_ONE when (tran_start = '1') else ALL_ZERO;
        end block;
    end block;
end RTL;
