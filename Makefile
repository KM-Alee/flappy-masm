ASM := uasm
CC := gcc

BUILD_DIR := build/linux
TARGET := build/flappy-term
ASMFLAGS := -q -elf64
LDFLAGS := -no-pie

ifeq ($(MODE),debug)
  CFLAGS := -g -O0
else
  CFLAGS := -O2
endif

# All assembly source modules
SRCS := src/main.asm src/terminal.asm src/input.asm src/gameplay.asm \
	src/physics.asm src/render.asm src/util.asm
OBJS := $(patsubst src/%.asm,$(BUILD_DIR)/%.o,$(SRCS))

# All include files (shared dependency)
INCS := include/config.inc include/linux.inc include/game.inc

.PHONY: all release debug run gdb clean

all: release

release:
	@$(MAKE) MODE=release $(TARGET)

debug:
	@$(MAKE) MODE=debug $(TARGET)

run: release
	@$(TARGET)

gdb: debug
	@gdb -q --args $(TARGET)

$(TARGET): $(OBJS)
	@mkdir -p build
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

$(BUILD_DIR)/%.o: src/%.asm $(INCS)
	@mkdir -p $(BUILD_DIR)
	$(ASM) $(ASMFLAGS) -Fo=$@ $<

clean:
	rm -rf build
