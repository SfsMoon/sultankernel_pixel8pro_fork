/* SPDX-License-Identifier: GPL-2.0 */
/*
 * Standalone sys_enter tracepoint for KernelSU-Next.
 *
 * With CONFIG_ANDROID_ONLY_VH_TRACING, every regular tracepoint is compiled
 * into a no-op stub. KernelSU-Next needs the sys_enter tracepoint to redirect
 * the syscalls it hooks, so provide just that one tracepoint without pulling
 * in the event tracing infrastructure. It is defined in kernel/tracepoint.c.
 */
#ifndef _TRACE_KSU_SYS_ENTER_H
#define _TRACE_KSU_SYS_ENTER_H

#include <linux/tracepoint.h>
#include <linux/preempt.h>
#include <linux/jump_label.h>

struct pt_regs;

extern struct tracepoint __tracepoint_sys_enter;
int __traceiter_sys_enter(void *__data, struct pt_regs *regs, long id);

static inline void trace_sys_enter(struct pt_regs *regs, long id)
{
	if (static_key_false(&__tracepoint_sys_enter.key)) {
		preempt_disable_notrace();
		__traceiter_sys_enter(NULL, regs, id);
		preempt_enable_notrace();
	}
}

static inline bool trace_sys_enter_enabled(void)
{
	return static_key_false(&__tracepoint_sys_enter.key);
}

static inline int
register_trace_sys_enter(void (*probe)(void *, struct pt_regs *, long),
			 void *data)
{
	return tracepoint_probe_register(&__tracepoint_sys_enter,
					 (void *)probe, data);
}

static inline int
register_trace_prio_sys_enter(void (*probe)(void *, struct pt_regs *, long),
			      void *data, int prio)
{
	return tracepoint_probe_register_prio(&__tracepoint_sys_enter,
					      (void *)probe, data, prio);
}

static inline int
unregister_trace_sys_enter(void (*probe)(void *, struct pt_regs *, long),
			   void *data)
{
	return tracepoint_probe_unregister(&__tracepoint_sys_enter,
					   (void *)probe, data);
}

#endif /* _TRACE_KSU_SYS_ENTER_H */
