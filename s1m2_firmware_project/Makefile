# Offline tests only. No camera firmware build or installation target.
PYTHON ?= python3
.PHONY: test test-parser test-ptp-wire test-tools help
test:
	$(PYTHON) tests/run_all_tests.py
test-parser:
	$(PYTHON) tests/test_dump_parser.py
test-ptp-wire:
	$(PYTHON) tests/test_ptp_wire_parser.py
test-tools:
	$(PYTHON) tests/test_toolchain.py
help:
	@echo "Offline input/sample tests. No camera functionality is implemented."
