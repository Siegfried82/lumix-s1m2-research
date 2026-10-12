// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright (C) 2018 Socionext Inc.
 */

#include <linux/clk.h>
#include <linux/interrupt.h>
#include <linux/irq.h>
#include <linux/irqreturn.h>
#include <linux/sched_clock.h>
#include "timer-of.h"
#include <linux/device.h>

#define MLB_TMR_TMCSR_OFS	0x0
#define MLB_TMR_TMR_OFS		0x4
#define MLB_TMR_TMRLR1_OFS	0x8
#define MLB_TMR_TMRLR2_OFS	0xc
#define MLB_TMR_REGSZPCH	0x10
#define MLB_TMR_TMCSR_MODE	GENMASK(8, 7)
#define MLB_TMR_TMCSR_RELS	BIT(12)
#define MLB_TMR_TMCSR_CSL	GENMASK(11, 10)

#define MLB_TMR_TMCSR_OUTL	BIT(5)
#define MLB_TMR_TMCSR_RELD	BIT(4)
#define MLB_TMR_TMCSR_INTE	BIT(3)
#define MLB_TMR_TMCSR_UF	BIT(2)
#define MLB_TMR_TMCSR_CNTE	BIT(1)
#define MLB_TMR_TMCSR_TRG	BIT(0)

#define MLB_TMR_TMCSR_CSL_DIV2	0
#define MLB_TMR_DIV_CNT		2

#define MLB_TMR_SRC_CH		1
#define MLB_TMR_EVT_CH		0

#define MLB_TMR_SRC_CH_OFS	(MLB_TMR_REGSZPCH * MLB_TMR_SRC_CH)
#define MLB_TMR_EVT_CH_OFS	(MLB_TMR_REGSZPCH * MLB_TMR_EVT_CH)

#define MLB_TMR_SRC_TMCSR_OFS	(MLB_TMR_SRC_CH_OFS + MLB_TMR_TMCSR_OFS)
#define MLB_TMR_SRC_TMR_OFS	(MLB_TMR_SRC_CH_OFS + MLB_TMR_TMR_OFS)
#define MLB_TMR_SRC_TMRLR1_OFS	(MLB_TMR_SRC_CH_OFS + MLB_TMR_TMRLR1_OFS)
#define MLB_TMR_SRC_TMRLR2_OFS	(MLB_TMR_SRC_CH_OFS + MLB_TMR_TMRLR2_OFS)

#define MLB_TMR_EVT_TMCSR_OFS	(MLB_TMR_EVT_CH_OFS + MLB_TMR_TMCSR_OFS)
#define MLB_TMR_EVT_TMR_OFS	(MLB_TMR_EVT_CH_OFS + MLB_TMR_TMR_OFS)
#define MLB_TMR_EVT_TMRLR1_OFS	(MLB_TMR_EVT_CH_OFS + MLB_TMR_TMRLR1_OFS)
#define MLB_TMR_EVT_TMRLR2_OFS	(MLB_TMR_EVT_CH_OFS + MLB_TMR_TMRLR2_OFS)

#define MLB_TIMER_RATING_DEFAULT	500
#define MLB_TIMER_ONESHOT	0
#define MLB_TIMER_PERIODIC	1

struct pm_regs {
	u32 evt_csr, src_csr;
	bool evt_timer_active;
	unsigned long save_evt_timer[2];
};

static void __iomem *sched_timer_count __read_mostly;
static int timer_rating = 0;

static irqreturn_t mlb_timer_interrupt(int irq, void *dev_id)
{
	struct clock_event_device *clk = dev_id;
	struct timer_of *to = to_timer_of(clk);
	u32 val;
	struct pm_regs *save_pm = (struct pm_regs *)to->private_data;

	val = readl_relaxed(timer_of_base(to) + MLB_TMR_EVT_TMCSR_OFS);
	if ((val & MLB_TMR_TMCSR_RELD) == 0)
		/* One shot */
		save_pm->evt_timer_active = false;
	val &= ~MLB_TMR_TMCSR_UF;
	writel_relaxed(val, timer_of_base(to) + MLB_TMR_EVT_TMCSR_OFS);

	clk->event_handler(clk);

	return IRQ_HANDLED;
}

static void mlb_evt_timer_start(struct timer_of *to, bool periodic)
{
	u32 val = MLB_TMR_TMCSR_CSL_DIV2;
	struct pm_regs *save_pm = (struct pm_regs *)to->private_data;

	val |= MLB_TMR_TMCSR_CNTE | MLB_TMR_TMCSR_TRG | MLB_TMR_TMCSR_INTE;
	if (periodic)
		val |= MLB_TMR_TMCSR_RELD;

	writel_relaxed(val, timer_of_base(to) + MLB_TMR_EVT_TMCSR_OFS);
	save_pm->evt_timer_active = true;

	save_pm->evt_csr =
		readl_relaxed(timer_of_base(to) + MLB_TMR_EVT_TMCSR_OFS);
}

static void mlb_evt_timer_stop(struct timer_of *to)
{
	u32 val = readl_relaxed(timer_of_base(to) + MLB_TMR_EVT_TMCSR_OFS);
	struct pm_regs *save_pm = (struct pm_regs *)to->private_data;

	val &= ~MLB_TMR_TMCSR_CNTE;
	writel_relaxed(val, timer_of_base(to) + MLB_TMR_EVT_TMCSR_OFS);
	save_pm->evt_timer_active = false;
	save_pm->evt_csr =
		readl_relaxed(timer_of_base(to) + MLB_TMR_EVT_TMCSR_OFS);
}

static void mlb_evt_timer_register_count(struct timer_of *to, unsigned long cnt)
{
	struct pm_regs *save_pm = (struct pm_regs *)to->private_data;

	save_pm->save_evt_timer[0] = cnt;
	writel_relaxed(cnt, timer_of_base(to) + MLB_TMR_EVT_TMRLR1_OFS);
}

static int mlb_set_state_periodic(struct clock_event_device *clk)
{
	struct timer_of *to = to_timer_of(clk);

	mlb_evt_timer_stop(to);
	mlb_evt_timer_register_count(to, to->of_clk.period);
	mlb_evt_timer_start(to, MLB_TIMER_PERIODIC);
	return 0;
}

static int mlb_set_state_oneshot(struct clock_event_device *clk)
{
	struct timer_of *to = to_timer_of(clk);

	mlb_evt_timer_stop(to);
	mlb_evt_timer_start(to, MLB_TIMER_ONESHOT);
	return 0;
}

static int mlb_set_state_shutdown(struct clock_event_device *clk)
{
	struct timer_of *to = to_timer_of(clk);

	mlb_evt_timer_stop(to);
	return 0;
}

static int mlb_clkevt_next_event(unsigned long event,
				   struct clock_event_device *clk)
{
	struct timer_of *to = to_timer_of(clk);

	mlb_evt_timer_stop(to);
	mlb_evt_timer_register_count(to, event);
	mlb_evt_timer_start(to, MLB_TIMER_ONESHOT);
	return 0;
}

static void mlb_timer_suspend(struct clock_event_device *clk)
{
	struct timer_of *evt = to_timer_of(clk);
	struct pm_regs *save_pm = (struct pm_regs *)evt->private_data;

	save_pm->src_csr =
		readl_relaxed(timer_of_base(evt) + MLB_TMR_SRC_TMCSR_OFS);
}

static void mlb_timer_resume(struct clock_event_device *clk)
{
	struct timer_of *to = to_timer_of(clk);
	struct pm_regs *save_pm = (struct pm_regs *)to->private_data;
	u32 val;

	writel_relaxed(0, timer_of_base(to) + MLB_TMR_SRC_TMCSR_OFS);
	writel_relaxed(~0,
			timer_of_base(to) + MLB_TMR_SRC_TMRLR1_OFS);
	writel_relaxed(~0,
			timer_of_base(to) + MLB_TMR_SRC_TMRLR2_OFS);
	/*
	* TRG shoudld be set because MLB_TMR_TMCSR_TRG
	* was set at timer_init.
	*/
	writel_relaxed(save_pm->src_csr | MLB_TMR_TMCSR_TRG,
		       timer_of_base(to) + MLB_TMR_SRC_TMCSR_OFS);

	writel_relaxed(0x0, timer_of_base(to) + MLB_TMR_EVT_TMCSR_OFS);
	writel_relaxed(save_pm->save_evt_timer[0],
		timer_of_base(to) + MLB_TMR_EVT_TMRLR1_OFS);
	writel_relaxed(save_pm->save_evt_timer[0],
		timer_of_base(to) + MLB_TMR_EVT_TMRLR2_OFS);

	val = save_pm->evt_csr;
	if (save_pm->evt_timer_active)
	/* TRG should be resume if evt_timer was active before suspend */
		val |= MLB_TMR_TMCSR_TRG;
	writel_relaxed(val, timer_of_base(to) + MLB_TMR_EVT_TMCSR_OFS);
	pr_debug("%s %x\n", __func__,  save_pm->evt_csr);
}

static int mlb_config_clock_source(struct timer_of *to)
{
	u32 val = MLB_TMR_TMCSR_CSL_DIV2;

	writel_relaxed(val, timer_of_base(to) + MLB_TMR_SRC_TMCSR_OFS);
	writel_relaxed(~0, timer_of_base(to) + MLB_TMR_SRC_TMRLR1_OFS);
	writel_relaxed(~0, timer_of_base(to) + MLB_TMR_SRC_TMRLR2_OFS);
	val |= MLB_TMR_TMCSR_RELD | MLB_TMR_TMCSR_CNTE | MLB_TMR_TMCSR_TRG;
	writel_relaxed(val, timer_of_base(to) + MLB_TMR_SRC_TMCSR_OFS);
	return 0;
}

static int mlb_config_clock_event(struct timer_of *to)
{
	writel_relaxed(0, timer_of_base(to) + MLB_TMR_EVT_TMCSR_OFS);
	return 0;
}

static void mlb_clockevent_init(struct timer_of *to, struct pm_regs *save_pm)
{
	to->flags = TIMER_OF_IRQ | TIMER_OF_BASE | TIMER_OF_CLOCK;

	to->clkevt.name = "mlb-clkevt";
	to->clkevt.rating = timer_rating;
	to->clkevt.cpumask = cpu_possible_mask;
	to->clkevt.features = CLOCK_EVT_FEAT_DYNIRQ | CLOCK_EVT_FEAT_ONESHOT;
	to->clkevt.set_state_oneshot = mlb_set_state_oneshot;
	to->clkevt.set_state_periodic = mlb_set_state_periodic;
	to->clkevt.set_state_shutdown = mlb_set_state_shutdown;
	to->clkevt.set_next_event = mlb_clkevt_next_event;
	to->clkevt.suspend = mlb_timer_suspend;
	to->clkevt.resume = mlb_timer_resume;

	to->of_irq.flags = IRQF_TIMER | IRQF_IRQPOLL;
	to->of_irq.handler = mlb_timer_interrupt;

	to->private_data = (void *)save_pm;
}

static u64 notrace mlb_timer_sched_read(void)
{
	return ~readl_relaxed(sched_timer_count);
}

static int __init mlb_timer_init(struct device_node *node)
{
	int ret;
	unsigned long rate;
	struct timer_of *to;
	struct pm_regs *save_pm;

	to = kzalloc(sizeof(*to), GFP_KERNEL);
	if (!to)
		return -ENOMEM;

	save_pm = kzalloc(sizeof(*save_pm), GFP_KERNEL);
	if (!save_pm) {
		kfree(to);
		return -ENOMEM;
	}

	mlb_clockevent_init(to, save_pm);
	ret = timer_of_init(node, to);
	if (ret) {
		kfree(to);
		kfree(save_pm);
		return ret;
	}

	if (of_find_property(node, "rating", NULL)) {
		ret = of_property_read_u32(node, "rating", &timer_rating);
		if (ret) {
			kfree(to);
			kfree(save_pm);
			return ret;
		}
	}
	else {
		timer_rating = MLB_TIMER_RATING_DEFAULT;
	}

	save_pm->evt_timer_active = false;

	rate = timer_of_rate(to) / MLB_TMR_DIV_CNT;
	mlb_config_clock_source(to);
	clocksource_mmio_init(timer_of_base(to) + MLB_TMR_SRC_TMR_OFS,
		"mlb-clksrc", rate, timer_rating, 32,
		clocksource_mmio_readl_down);
	if(!sched_timer_count) {
		sched_timer_count = timer_of_base(to) + MLB_TMR_SRC_TMR_OFS;
		sched_clock_register(mlb_timer_sched_read, 32, rate);
	}
	mlb_config_clock_event(to);
	clockevents_config_and_register(&to->clkevt, timer_of_rate(to), 15,
		0xffffffff);
	return 0;
}
TIMER_OF_DECLARE(mlb_peritimer, "socionext,milbeaut-timer",
		mlb_timer_init);
