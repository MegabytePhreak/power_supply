# ARM7 common makefile scripts and rules.

# Output
OUTFILES = $(BUILDDIR)/$(PROJECT).elf $(BUILDDIR)/$(PROJECT).hex $(BUILDDIR)/$(PROJECT).bin $(BUILDDIR)/$(PROJECT).dmp
ifeq ($(BUILDDIR),)
  BUILDDIR = .
  CLEANDIR =
  OBJDIR = .objs
else
  CLEANDIR = $(BUILDDIR)
  OBJDIR = $(BUILDDIR)/.objs
endif
ENSUREBUILDDIR = $(shell test -d $(BUILDDIR) || mkdir $(BUILDDIR))
ENSUREOBJDIR = $(shell test -d $(OBJDIR) || mkdir $(OBJDIR))

# Automatic compiler options
OPT = $(USE_OPT)
CPPOPT = $(USE_CPPOPT)
ifeq ($(USE_CURRP_CACHING),yes)
  OPT += -ffixed-r7 -DCH_CURRP_REGISTER_CACHE='"r7"'
endif
ifeq ($(USE_LINK_GC),yes)
  OPT += -ffunction-sections -fdata-sections
endif

# Source files groups
ifeq ($(USE_THUMB),yes)
  TCSRC += $(CSRC)
  TCPPSRC += $(CPPSRC)
else
  ACSRC += $(CSRC)
  ACPPSRC += $(CPPSRC)
endif
ASRC	 = $(ACSRC)$(ACPPSRC)
TSRC	 = $(TCSRC)$(TCPPSRC)
SRC	     = $(ASRC)$(TSRC)

vpath %.c $(dir $(ACSRC)) $(dir $(TCSRC))
vpath %.h $(dir $(ACPPSRC)) $(dir $(TSRC))
vpath %.s $(dir $(ASMSRC))

# Object files groups
ACOBJS   = $(addprefix $(OBJDIR)/,$(notdir $(ACSRC:.c=.o)))
ACPPOBJS =  $(addprefix $(OBJDIR)/,$(notdir $(ACPPSRC:.cpp=.o)))
TCOBJS   = $(addprefix $(OBJDIR)/,$(notdir $(TCSRC:.c=.o)))
TCPPOBJS =  $(addprefix $(OBJDIR)/,$(notdir $(TCPPSRC:.cpp=.o)))
ASMOBJS  = $(addprefix $(OBJDIR)/,$(notdir $(ASMSRC:.s=.o)))
OBJS	 = $(ASMOBJS) $(ACOBJS) $(TCOBJS) $(ACPPOBJS) $(TCPPOBJS) 

# Paths
IINCDIR = $(patsubst %,-I%,$(INCDIR) $(DINCDIR) $(UINCDIR))
LLIBDIR = $(patsubst %,-L%,$(DLIBDIR) $(ULIBDIR))

# Macros
DEFS    = $(DDEFS) $(UDEFS)
ADEFS   = $(DADEFS) $(UADEFS)

# Libs
LIBS    = $(DLIBS) $(ULIBS)

# Various settings
MCFLAGS = -mcpu=$(MCU)
ODFLAGS	= -x --syms
ASFLAGS = $(MCFLAGS) -Wa,-amhls=$(<:.s=.lst) $(ADEFS)
CFLAGS   = $(MCFLAGS) $(OPT) $(CWARN) -Wa,-alms=$(@:.o=.lst) $(DEFS)
CPPFLAGS = $(MCFLAGS) $(OPT) $(CPPOPT) $(CPPWARN) -Wa,-alms=$(<:.cpp=.lst) $(DEFS)
ifeq ($(USE_LINK_GC),yes)
  LDFLAGS = $(MCFLAGS) -nostartfiles -T$(LDSCRIPT) -Wl,-Map=$(BUILDDIR)/$(PROJECT).map,--cref,--no-warn-mismatch,--gc-sections $(LLIBDIR)
else
  LDFLAGS = $(MCFLAGS) -nostartfiles -T$(LDSCRIPT) -Wl,-Map=$(BUILDDIR)/$(PROJECT).map,--cref,--no-warn-mismatch $(LLIBDIR)
endif

# Thumb interwork enabled only if needed because it kills performance.
ifneq ($(TSRC),)
  CFLAGS += -DTHUMB_PRESENT
  CPPFLAGS += -DTHUMB_PRESENT
  ASFLAGS += -DTHUMB_PRESENT
  ifneq ($(ASRC),)
    # Mixed ARM and THUMB mode
    CFLAGS += -mthumb-interwork
    CPPFLAGS += -mthumb-interwork
    ASFLAGS += -mthumb-interwork
    LDFLAGS += -mthumb-interwork
  else
    # Pure THUMB mode, THUMB C code cannot be called by ARM asm code directly.
    CFLAGS += -mno-thumb-interwork -DTHUMB_NO_INTERWORKING
    CPPFLAGS += -mno-thumb-interwork -DTHUMB_NO_INTERWORKING
    ASFLAGS += -mno-thumb-interwork -DTHUMB_NO_INTERWORKING -mthumb
    LDFLAGS += -mno-thumb-interwork -mthumb
  endif
else
  # Pure ARM mode
  CFLAGS += -mno-thumb-interwork
  CPPFLAGS += -mno-thumb-interwork
  ASFLAGS += -mno-thumb-interwork
  LDFLAGS += -mno-thumb-interwork
endif

# Generate dependency information
CFLAGS += -MD -MP -MF .dep/$(@F).d
CPPFLAGS += -MD -MP -MF .dep/$(@F).d

#
# Makefile rules
#
$(TCOBJS): CFLAGS += $(TOPT) 
$(ACOBJS): CFLAGS += $(AOPT)
$(TCPPOBJS): CPPFLAGS += $(TOPT)
$(ACPPOBJS): CFPPLAGS += $(AOPT)

all: $(ENSUREBUILDDIR) $(ENSUREOBJDIR) $(OBJS) $(OUTFILES)

$(OBJDIR)/%.o : %.cpp
	@echo
	$(CPPC) -c $(CPPFLAGS) $(AOPT) -I . $(IINCDIR) $< -o $@



$(OBJDIR)/%.o : %.c
	@echo
	$(CC) -c $(CFLAGS) -I . $(IINCDIR) $< -o $@


$(OBJDIR)/%.o : %.s
	@echo
	$(AS) -c $(ASFLAGS) -I . $(IINCDIR) $< -o $@

%elf: $(OBJS)
	@echo
	$(LD) $(OBJS) $(LDFLAGS) $(LIBS) -o $@

%hex: %elf
	$(HEX) $< $@

%bin: %elf
	$(BIN) $< $@

%dmp: %elf
	$(OD) $(ODFLAGS) $< > $@

clean:
	-rm -f $(OBJS)
	-rm -f $(ACSRC:.c=.lst) $(TCSRC:.c=.lst) $(ACPPSRC:.cpp=.lst) $(TCPPSRC:.cpp=.lst) $(ASMSRC:.s=.lst)
	-rm -f $(OUTFILES) $(BUILDDIR)/$(PROJECT).map
	-rm -fR .dep $(CLEANDIR)

#
# Include the dependency files, should be the last of the makefile
#
-include $(shell mkdir .dep 2>/dev/null) $(wildcard .dep/*)

# *** EOF ***
