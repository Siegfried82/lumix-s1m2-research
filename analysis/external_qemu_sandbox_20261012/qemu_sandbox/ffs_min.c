/*
 * ffs_min.c - minimal userspace FunctionFS app (QEMU sandbox)
 *
 * Binds the descriptors for the configfs ffs function:
 *   1 interface, 2 bulk endpoints (IN 0x81 512, OUT 0x02 512).
 * The app must stay open for the lifetime of the sandbox: closing the
 * fd puts the function into FFS_DEACTIVATED, which blocks ffs_func_set_alt.
 *
 * Build: aarch64-linux-gnu-gcc -static -O2 -o ffs_min ffs_min.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <poll.h>
/*
 * FunctionFS two-phase protocol (4.19):
 *   write 1: u32 magic(=3, DESCRIPTORS_MAGIC_V2), u32 len, u32 flags,
 *            u32 reserved, <device+config+intf+ep descriptors>
 *   write 2: u32 magic(=2, STRINGS_MAGIC), u32 len, u32 str_count,
 *            u32 lang_count, <u16 lang[] + string data>
 */
static const unsigned char desc_block[] = {
	/* v2 header: magic=3, len=66 (0x42), flags=FS|HS (0x03) */
	0x03, 0x00, 0x00, 0x00,
	0x42, 0x00, 0x00, 0x00,
	0x03, 0x00, 0x00, 0x00,
	/* fs_count=3, hs_count=3 */
	0x03, 0x00, 0x00, 0x00,
	0x03, 0x00, 0x00, 0x00,

	/* FS descriptors (23 bytes): 1 intf + 2 bulk eps (maxpacket=64) */
	9, 0x04, 0, 0, 2, 0xff, 0, 0, 0,
	7, 0x05, 0x81, 0x02, 0x40, 0x00, 0,
	7, 0x05, 0x02, 0x02, 0x40, 0x00, 0,

	/* HS descriptors (23 bytes): 1 intf + 2 bulk eps (maxpacket=512) */
	9, 0x04, 0, 0, 2, 0xff, 0, 0, 0,
	7, 0x05, 0x81, 0x02, 0x00, 0x02, 0,
	7, 0x05, 0x02, 0x02, 0x00, 0x02, 0,
};

static const unsigned char strings_block[] = {
	/* magic=2, len=16, str_count=0, lang_count=0 */
	0x02, 0x00, 0x00, 0x00,
	0x10, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00,
};
int main(int argc, char **argv)
{
	const char *path = argc > 1 ? argv[1] : "/dev/ffs0/ep0";
	int fd, n;
	struct pollfd pfd;

	fd = open(path, O_RDWR);
	fprintf(stderr, "ffs_min: open rc=%d\n", fd);
	fflush(stderr);
	if (fd < 0) {
		perror("open ffs");
		return 1;
	}

	n = (int)write(fd, desc_block, sizeof(desc_block));
	fprintf(stderr, "ffs_min: desc write n=%d\n", n);
	if (n != (int)sizeof(desc_block)) {
		fprintf(stderr, "ffs_min: descriptor write %d\n", n);
		return 1;
	}
	n = (int)write(fd, strings_block, sizeof(strings_block));
	if (n != (int)sizeof(strings_block)) {
		fprintf(stderr, "ffs_min: strings write %d\n", n);
		return 1;
	}
	fprintf(stderr, "ffs_min: bound %s, staying alive\n", path);

	/* drain functionfs events forever; never close the fd */
	pfd.fd = fd;
	pfd.events = POLLIN | POLLOUT;
	for (;;) {
		if (poll(&pfd, 1, -1) < 0)
			continue;
		/* events are advisory for our purposes; ignore */
	}
	return 0;
}
