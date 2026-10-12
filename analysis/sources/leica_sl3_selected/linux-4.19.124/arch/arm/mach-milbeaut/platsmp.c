// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright:	(C) 2018 Socionext Inc.
 * Copyright:	(C) 2015 Linaro Ltd.
 */

#include <linux/cpu_pm.h>
#include <linux/irqchip/arm-gic.h>
#include <linux/of_address.h>
#include <linux/suspend.h>

#include <asm/cacheflush.h>
#include <asm/cp15.h>
#include <asm/idmap.h>
#include <asm/smp_plat.h>
#include <asm/suspend.h>

#define M10V_MAX_CPU	4
#define KERNEL_UNBOOT_FLAG	0x12345678
#define CPU_FINISH_SUSPEND_FLAG 0x56784321

#define CPU_RESUME_ADDRESS_OFFSET   (M10V_MAX_CPU * 4)
#define CPU_FINISH_SUSPEND_OFFSET   (CPU_RESUME_ADDRESS_OFFSET * 2 + 8)

static void __iomem *m10v_smp_base;

static int m10v_boot_secondary(unsigned int l_cpu, struct task_struct *idle)
{
	unsigned int mpidr, cpu, cluster;

	if (!m10v_smp_base)
		return -ENXIO;

	mpidr = cpu_logical_map(l_cpu);
	cpu = MPIDR_AFFINITY_LEVEL(mpidr, 0);
	cluster = MPIDR_AFFINITY_LEVEL(mpidr, 1);

	if (cpu >= M10V_MAX_CPU)
		return -EINVAL;

	pr_info("%s: cpu %u l_cpu %u cluster %u\n",
			__func__, cpu, l_cpu, cluster);

	writel(__pa_symbol(secondary_startup), m10v_smp_base + cpu * 4);
	arch_send_wakeup_ipi_mask(cpumask_of(l_cpu));

	return 0;
}

static void m10v_smp_init(unsigned int max_cpus)
{
	unsigned int mpidr, cpu, cluster;
	struct device_node *np;

	np = of_find_compatible_node(NULL, NULL, "socionext,smp-trampoline");
	if (!np)
		return;

	m10v_smp_base = of_iomap(np, 0);
	if (!m10v_smp_base)
		return;

	mpidr = read_cpuid_mpidr();
	cpu = MPIDR_AFFINITY_LEVEL(mpidr, 0);
	cluster = MPIDR_AFFINITY_LEVEL(mpidr, 1);
	pr_info("MCPM boot on cpu_%u cluster_%u\n", cpu, cluster);

	for (cpu = 0; cpu < M10V_MAX_CPU; cpu++)
		writel(KERNEL_UNBOOT_FLAG, m10v_smp_base + cpu * 4);
}

static void m10v_cpu_die(unsigned int l_cpu)
{
	unsigned int mpidr, cpu;

	mpidr = cpu_logical_map(l_cpu);
	cpu = MPIDR_AFFINITY_LEVEL(mpidr, 0);
	/* Set data $ to invalid */
	asm volatile
		(".arch	armv7-a \n\t"
		 "stmfd	sp!, {fp, ip} \n\t"
		 "mrc	p15, 0, r0, c1, c0, 0	@ get SCTLR \n\t"
		 "bic	r0, r0, #"__stringify(CR_C)" \n\t"
		 "mcr	p15, 0, r0, c1, c0, 0	@ set SCTLR \n\t"
		 "isb	\n\t"
		 "bl	v7_flush_dcache_louis \n\t"
		 "ldmfd	sp!, {fp, ip}"
		 : : : "r0","r1","r2","r3","r4","r5","r6","r7",
		 "r9","r10","lr","memory" );
	writel(KERNEL_UNBOOT_FLAG, m10v_smp_base + cpu * 4);
	/* Now we are prepared for power-down, do it: */
	wfi();
	/* Enable data $ */
	asm volatile
		("mrc	p15, 0, r0, c1, c0, 0	@ get SCTLR \n\t"
		 "orr	r0, r0, #"__stringify(CR_C)" \n\t"
		 "mcr	p15, 0, r0, c1, c0, 0	@ set SCTLR");
}

static int m10v_cpu_kill(unsigned int l_cpu)
{
	unsigned int mpidr, cpu;

	mpidr = cpu_logical_map(l_cpu);
	cpu = MPIDR_AFFINITY_LEVEL(mpidr, 0);

	writel(KERNEL_UNBOOT_FLAG, m10v_smp_base + cpu * 4);

	return 1;
}

static struct smp_operations m10v_smp_ops __initdata = {
	.smp_prepare_cpus	= m10v_smp_init,
	.smp_boot_secondary	= m10v_boot_secondary,
	.cpu_die		= m10v_cpu_die,
	.cpu_kill		= m10v_cpu_kill,
};
CPU_METHOD_OF_DECLARE(m10v_smp, "socionext,milbeaut-m10v-smp", &m10v_smp_ops);

static int m10v_pm_valid(suspend_state_t state)
{
	return (state == PM_SUSPEND_STANDBY) || (state == PM_SUSPEND_MEM);
}


static int m10v_die(unsigned long arg)
{
	unsigned int mpidr, cpu, cluster;
	mpidr = read_cpuid_mpidr();
	cpu = MPIDR_AFFINITY_LEVEL(mpidr, 0);
	cluster = MPIDR_AFFINITY_LEVEL(mpidr, 1);
	writel(virt_to_phys(cpu_resume), m10v_smp_base + CPU_RESUME_ADDRESS_OFFSET + cpu * 4);
	flush_cache_all();

	/* Notify that can enter suspend mode*/
	writel(CPU_FINISH_SUSPEND_FLAG, m10v_smp_base + CPU_FINISH_SUSPEND_OFFSET);

	/* M0 or RTOS should power-off, and then reset upon resume */
	while (1)
		asm("wfi");

	/* never reach here*/
	return -1;

	return 0;
}

static int m10v_pm_enter(suspend_state_t state)
{
	switch (state) {
	case PM_SUSPEND_STANDBY:
		pr_err("STANDBY\n");
		asm("wfi");
		break;
	case PM_SUSPEND_MEM:
		pr_err("SUSPEND\n");
		cpu_pm_enter();
		cpu_suspend(0, m10v_die);
		cpu_pm_exit();
		break;
	}
	return 0;
}

static const struct platform_suspend_ops m10v_pm_ops = {
	.valid		= m10v_pm_valid,
	.enter		= m10v_pm_enter,
};

struct clk *m10v_clclk_register(struct device *cpu_dev);

static int __init m10v_pm_init(void)
{
	suspend_set_ops(&m10v_pm_ops);

	return 0;
}
late_initcall(m10v_pm_init);
