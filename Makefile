# 工具链定义
NASM := nasm
GCC := gcc
LD := ld
OBJCOPY := objcopy
QEMU := qemu-system-i386

# 编译选项
# 使用 -f elf32 来生成 ld 可以处理的对象文件
AFLAGS := -f elf32 -g -F dwarf
LDFLAGS := -m elf_i386 -nostdlib

# 目录和源文件
BUILD_DIR := build
SRC_DIR_BOOT := boot

# 源文件
STAGE1_SRC := $(SRC_DIR_BOOT)/stage1.asm

# 目标文件
# 1. 对象文件 (.o)
STAGE1_OBJ := $(BUILD_DIR)/boot/stage1.o
# 2. ELF 可执行文件 (用于调试)
KERNEL_ELF := $(BUILD_DIR)/kernel.elf
# 3. 纯二进制文件 (用于镜像)
STAGE1_BIN := $(BUILD_DIR)/boot/stage1.bin
# 4. 最终磁盘镜像
IMG := ecpos.img

# 伪目标
.PHONY: all clean run rebuild debug

# 默认目标
all: $(IMG)

# --- 编译和链接规则 ---

# 汇编 stage1.asm 为对象文件 (.o)
$(STAGE1_OBJ): $(STAGE1_SRC)
	@echo "Assembling $< to $@..."
	@mkdir -p $(dir $@)
	$(NASM) $(AFLAGS) $< -o $@

# 链接最终的 ELF 文件
# 这是 GDB 进行调试时需要加载的文件
$(KERNEL_ELF): $(STAGE1_OBJ)
	@echo "Linking $@..."
	@mkdir -p $(dir $@)
	$(LD) $(LDFLAGS) -Ttext 0x7c00 $^ -o $@

# 从 ELF 文件中提取纯二进制代码
$(STAGE1_BIN): $(KERNEL_ELF)
	@echo "Extracting binary from $< to $@..."
	@mkdir -p $(dir $@)
	$(OBJCOPY) -O binary $< $@


# --- 镜像和运行规则 ---

# 创建最终的磁盘镜像
$(IMG): $(STAGE1_BIN)
	@echo "Creating disk image $(IMG)..."
    # 确保文件大小正好是 512 字节，并带有 MBR 签名
	cat $^ > $@
	@echo "Image created successfully: $(IMG) (`stat -c '%s' $@` bytes)"

# 运行 QEMU
run: $(IMG)
	@echo "Booting with QEMU..."
	$(QEMU) -drive format=raw,file=$(IMG),if=floppy -boot order=a

# 以调试模式运行 QEMU
# 注意：debug 依赖于 all，确保在调试前所有文件都已正确生成
debug: all
	@echo "Booting with QEMU in debug mode (waiting for GDB on localhost:1234)..."
	$(QEMU) -cpu 486 -s -S -drive format=raw,file=$(IMG),if=floppy -boot order=a

# --- 清理规则 ---

# 强制重新编译
rebuild: clean all

# 清理所有生成的文件
clean:
	@echo "Cleaning up..."
	-rm -rf $(BUILD_DIR) $(IMG)