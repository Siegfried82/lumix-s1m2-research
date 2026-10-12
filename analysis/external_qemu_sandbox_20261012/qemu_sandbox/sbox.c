/*
 * sbox.c - static init for the S1RM2 kernel QEMU sandbox
 *
 * 1. mounts sysfs/proc/configfs
 * 2. creates the configfs gadget (g1) with one ffs function
 * 3. forks ffs_min (binds the ffs descriptors, must stay alive)
 * 4. binds the fake UDC ("qoob") to the gadget
 * 5. runs a REPL on the serial console (stdin/stdout):
 *      cfg <n> | get <wIndex> | set <wIndex> <wValue> |
 *      scan <start> <n> <stride> | status | help | exit
 *    Each command is passed to /proc/qoob; the response from
 *    /proc/qoob_out is printed.
 *
 * Build: aarch64-linux-gnu-gcc -static -O2 -o sbox sbox.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <sys/wait.h>
#include <sys/reboot.h>

#define BASE "/sys/kernel/config/usb_gadget/g1"

static int wfile(const char *path, const char *data)
{
	int fd = open(path, O_WRONLY);
	if (fd < 0)
		return -1;
	if (write(fd, data, strlen(data)) < 0) {
		close(fd);
		return -1;
	}
	close(fd);
	return 0;
}

static void setup(void)
{
	int r;
	fprintf(stderr, "sbox: step=setup start\n");
	mkdir("/tmp", 0777);
	mkdir("/sys", 0755);
	r = mount("sysfs", "/sys", "sysfs", 0, NULL);
	fprintf(stderr, "sbox: mount sysfs rc=%d\n", r);
	mkdir("/proc", 0755);
	r = mount("proc", "/proc", "proc", 0, NULL);
	fprintf(stderr, "sbox: mount proc rc=%d\n", r);
	mkdir("/sys/kernel/config", 0755);
	r = mount("configfs", "/sys/kernel/config", "configfs", 0, NULL);
	fprintf(stderr, "sbox: mount configfs rc=%d\n", r);

	r = mkdir(BASE, 0755);
	fprintf(stderr, "sbox: mkdir g1 rc=%d\n", r);
	wfile(BASE "/idVendor", "0x04da");
	wfile(BASE "/idProduct", "0x2372");
	mkdir(BASE "/strings/0x409", 0755);
	r = wfile(BASE "/strings/0x409/serialnumber", "0123456789");
	fprintf(stderr, "sbox: serialnumber rc=%d\n", r);
	mkdir(BASE "/configs/c.1", 0755);
	mkdir(BASE "/configs/c.1/strings/0x409", 0755);
	r = mkdir(BASE "/functions/ffs.ffs0", 0755);
	fprintf(stderr, "sbox: mkdir ffs.ffs0 rc=%d\n", r);
	r = symlink(BASE "/functions/ffs.ffs0", BASE "/configs/c.1/ffs.ffs0");
	fprintf(stderr, "sbox: symlink ffs.ffs0 rc=%d\n", r);
	mkdir("/dev", 0755);
	mount("devtmpfs", "/dev", "devtmpfs", 0, NULL);
	mkdir("/dev/ffs0", 0755);
	r = mount("ffs0", "/dev/ffs0", "functionfs", 0, NULL);
	fprintf(stderr, "sbox: mount functionfs rc=%d\n", r);
}

static int run_cmd(char *line)
{
	int fd, n, off = 0;
	char out[4096];
	size_t len = strlen(line);

	if (len == 0)
		return 1;
	line[strcspn(line, "\r\n")] = 0;

	fd = open("/proc/qoob", O_WRONLY);
	if (fd < 0) {
		perror("open /proc/qoob");
		return 1;
	}
	if (write(fd, line, len) < 0)
		perror("write /proc/qoob");
	close(fd);

	fd = open("/proc/qoob_out", O_RDONLY);
	if (fd < 0)
		return 1;
	for (;;) {
		n = read(fd, out + off, sizeof(out) - 1 - off);
		if (n <= 0)
			break;
		off += n;
		if (off == (int)(sizeof(out) - 1))
			break;
	}
	close(fd);
	out[off] = 0;
	fputs(out, stdout);
	fflush(stdout);
	return 1;
}

int main(void)
{
	char line[256];
	pid_t pid;
	int rc;

	fprintf(stderr, "sbox: main enter\n");
	fflush(stderr);
	setup();

	pid = fork();
	if (pid == 0) {
		execl("/ffs_min", "ffs_min",
		      "/dev/ffs0/ep0", (char *)NULL);
		_exit(127);
	}
	usleep(200000);

	fprintf(stderr, "sbox: udc bind start\n");
	fflush(stderr);
	rc = wfile(BASE "/UDC", "qoob");
	fprintf(stderr, "sbox: udc bind rc=%d\n", rc);
	if (rc)
		fprintf(stderr, "sbox: UDC bind failed (check dmesg)\n");

	fprintf(stderr, "sbox: ready (ffs_min pid=%d)\n", pid);
	fprintf(stderr, "sbox: cmds: cfg <n> | get <wIdx> | set <wIdx> <wVal> "
		"| scan <start> <n> <stride> | status | sh | exit\n");
	fflush(stderr);

	{
		char cmdline[512] = {0};
		int cfd = open("/proc/cmdline", O_RDONLY);
		if (cfd >= 0) {
			read(cfd, cmdline, sizeof(cmdline) - 1);
			close(cfd);
		}
		if (strstr(cmdline, "sbox.shell=1")) {
			pid_t sp = fork();
			if (sp == 0) {
				setenv("PATH", "/bin:/sbin:/usr/bin:/usr/sbin", 1);
				setenv("PS1", "lumix-s1rm2:\\w# ", 1);
				execl("/bin/sh", "sh", (char *)NULL);
				_exit(127);
			}
			waitpid(sp, NULL, 0);
			reboot(RB_POWER_OFF);
			return 0;
		}
	}

	for (;;) {
		if (!fgets(line, sizeof(line), stdin))
			break;
		if (!strncmp(line, "exit", 4))
			break;
		if (!strncmp(line, "sh", 2) && (line[2] == '\n' || line[2] == '\r' || line[2] == 0 || !strncmp(line, "shell", 5))) {
			pid_t sp = fork();
			if (sp == 0) {
				setenv("PATH", "/bin:/sbin:/usr/bin:/usr/sbin", 1);
				setenv("PS1", "lumix-s1rm2:\\w# ", 1);
				execl("/bin/sh", "sh", (char *)NULL);
				_exit(127);
			}
			waitpid(sp, NULL, 0);
			continue;
		}
		if (!strncmp(line, "help", 4)) {
			fputs("cfg <n>            SET_CONFIGURATION\n"
			      "get <wIndex>       GET_INTERFACE\n"
			      "set <wIndex> <wVal> SET_INTERFACE\n"
			      "scan <s> <n> <st>   batch GET_INTERFACE\n"
			      "status               gadget state\n"
			      "sh                   drop into BusyBox /bin/sh shell\n"
			      "exit                 power off VM\n", stdout);
			fflush(stdout);
			continue;
		}
		run_cmd(line);
	}
	reboot(RB_POWER_OFF);
	return 0;
}
