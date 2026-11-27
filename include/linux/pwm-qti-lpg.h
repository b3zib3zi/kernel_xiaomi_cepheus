/* SPDX-License-Identifier: GPL-2.0 */
/*
 * Helpers of the QTI LPG PWM driver that the QTI tri-colour LED driver
 * uses for its breathing and pattern controls.
 */
#ifndef _LINUX_PWM_QTI_LPG_H
#define _LINUX_PWM_QTI_LPG_H

#include <linux/types.h>

struct pwm_device;

void qpnp_lpg_ramp_step_ms_set(struct pwm_device *pwm, u16 step_ms);
int qpnp_lpg_ramp_step_ms_get(struct pwm_device *pwm);
void qpnp_lpg_pause_lo_count_set(struct pwm_device *pwm, u8 pause_lo_count);
int qpnp_lpg_pause_lo_count_get(struct pwm_device *pwm);
int qpnp_lpg_switch_lut_pattern(struct pwm_device *pwm, int index);
int qpnp_lpg_lo_idx_get(struct pwm_device *pwm);
int qpnp_lpg_lo_idx_set(struct pwm_device *pwm, int lo_idx);

#endif /* _LINUX_PWM_QTI_LPG_H */
