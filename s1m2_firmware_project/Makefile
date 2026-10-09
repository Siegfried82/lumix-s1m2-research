# SPDX-License-Identifier: MIT
# Makefile for Panasonic LUMIX S1M2 (DC-S1M2) Firmware Engineering Project

CC ?= clang
CFLAGS ?= -Wall -Wextra -std=c11 -O2 -Iinclude
PYTHON ?= python3

BUILD_DIR = build
BIN_DIR = bin

SRCS = src/main_verify.c src/ipcu_protocol.c
HEADERS = include/s1m2_types.h include/s1m2_mmap.h include/s1m2_ipcu.h \
          include/s1m2_dsp_xm6.h include/s1m2_npu_cnn.h include/s1m2_eeprom.h \
          include/s1m2_ptp_proto.h

.PHONY: all clean test test-headers test-tools test-parser test-ptp-wire help

all: $(BIN_DIR)/s1m2_verify $(BIN_DIR)/test_headers

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(BIN_DIR)/s1m2_verify: $(SRCS) $(HEADERS) | $(BIN_DIR)
	$(CC) $(CFLAGS) $(SRCS) -o $@

$(BIN_DIR)/test_headers: tests/test_headers.c $(HEADERS) | $(BIN_DIR)
	$(CC) $(CFLAGS) tests/test_headers.c -o $@

test: all
	@echo "==> Running master verification test suite..."
	$(PYTHON) tests/run_all_tests.py

test-headers: $(BIN_DIR)/test_headers
	@echo "==> Running C header verification..."
	./$(BIN_DIR)/test_headers

test-parser:
	@echo "==> Running memory dump parser verification..."
	$(PYTHON) tests/test_dump_parser.py

test-ptp-wire:
	@echo "==> Running PTP property wire parser tests against real captures..."
	$(PYTHON) tests/test_ptp_wire_parser.py


test-tools:
	@echo "==> Running toolchain & repack round-trip verification..."
	$(PYTHON) tests/test_toolchain.py

clean:
	rm -rf $(BIN_DIR) $(BUILD_DIR) *.bin carved_assets unpacked_output

help:
	@echo "Panasonic LUMIX S1M2 Firmware Reverse Engineering Project"
	@echo "Targets:"
	@echo "  all          Build C verification binaries (s1m2_verify, test_headers)"
	@echo "  test         Execute complete test suite (C unit tests + Python toolchain)"
	@echo "  test-headers Execute C header offset/size unit tests"
	@echo "  test-parser  Execute memory dump parser tests"
	@echo "  test-ptp-wire Execute PTP wire property parser tests"
	@echo "   Execute PTP interval & bracketing sequencer tests"
	@echo "  test-tools   Execute unpack/repack bit-identical tests"
	@echo "  clean        Remove build artifacts and temporary files"
