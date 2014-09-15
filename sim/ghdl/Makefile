DUMMY_PLUG_WORK_PATH = ../../Dummy_Plug/sim/ghdl/dummy_plug
PIPEWORK_WORK_PATH   = ../../PipeWork/sim/ghdl
SRC_PATH             = ../../src

GHDL       = ghdl
GHDLFLAGS  = --mb-comments -P$(DUMMY_PLUG_WORK_PATH) -P$(PIPEWORK_WORK_PATH)

COMPONENTS = mmu_core    \
             mmu_tlb     \
             mmu_tlb_lru \
             $(END_LIST)

DUT : $(addsuffix .o,$(COMPONENTS))

mmu_core.o    : $(SRC_PATH)/main/vhdl/mmu_core.vhd 
	 $(GHDL) -a $(GHDLFLAGS) --work=WORK $<

mmu_tlb.o     : $(SRC_PATH)/main/vhdl/mmu_tlb.vhd 
	 $(GHDL) -a $(GHDLFLAGS) --work=WORK $<

mmu_tlb_lru.o : $(SRC_PATH)/main/vhdl/mmu_tlb_lru.vhd 
	 $(GHDL) -a $(GHDLFLAGS) --work=WORK $<
