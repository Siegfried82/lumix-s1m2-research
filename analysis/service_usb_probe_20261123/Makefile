CC ?= clang
CFLAGS ?= -O2 -Wall -Wextra
USB_CFLAGS := $(shell pkg-config --cflags libusb-1.0)
USB_LIBS := $(shell pkg-config --libs libusb-1.0)

svc_probe: svc_probe.c
	$(CC) $(CFLAGS) $(USB_CFLAGS) $< $(USB_LIBS) -o $@

clean:
	rm -f svc_probe

.PHONY: clean
