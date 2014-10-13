DUMMY_PLUG_WORK_PATH = ../../Dummy_Plug/sim/ghdl/dummy_plug
PIPEWORK_WORK_PATH   = ../../PipeWork/sim/ghdl
SRC_PATH             = ../../src

GHDL       = ghdl
GHDLFLAGS  = --mb-comments -P$(DUMMY_PLUG_WORK_PATH) -P$(PIPEWORK_WORK_PATH)

COMPONENTS = mmu_axi     \
             mmu_core    \
             mmu_tlb     \
             mmu_tlb_lru \
             $(END_LIST)


TEST_BENCH = mmu_axi_test_bench \
             $(END_LIST)


all: DUT $(TEST_BENCH)

clean:
	rm -f *.o *.cf $(TEST_BENCH)


$(TEST_BENCH) : $(addsuffix .o,$(TEST_BENCH)) $(addsuffix .snr,$(TEST_BENCH))
	 $(GHDL) -e $(GHDLFLAGS) --work=WORK $@
	-$(GHDL) -r $(GHDLFLAGS) --work=WORK $@

mmu_axi_test_bench.o : $(SRC_PATH)/test/vhdl/mmu_axi_test_bench.vhd 
	 $(GHDL) -a $(GHDLFLAGS) --work=WORK $<

DUT : $(addsuffix .o,$(COMPONENTS))

mmu_axi.o    : $(SRC_PATH)/main/vhdl/mmu_axi.vhd 
	 $(GHDL) -a $(GHDLFLAGS) --work=WORK $<

mmu_core.o    : $(SRC_PATH)/main/vhdl/mmu_core.vhd 
	 $(GHDL) -a $(GHDLFLAGS) --work=WORK $<

mmu_tlb.o     : $(SRC_PATH)/main/vhdl/mmu_tlb.vhd 
	 $(GHDL) -a $(GHDLFLAGS) --work=WORK $<

mmu_tlb_lru.o : $(SRC_PATH)/main/vhdl/mmu_tlb_lru.vhd 
	 $(GHDL) -a $(GHDLFLAGS) --work=WORK $<
