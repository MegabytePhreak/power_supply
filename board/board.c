
#include "ch.h"
#include "hal.h"

/*
 * GPIO Setup
 */ 
#if HAL_USE_PAL
const PALConfig pal_default_config =
{
  .PAData = {VAL_GPIOAODR, VAL_GPIOACRL, VAL_GPIOACRH},
  .PBData = {VAL_GPIOBODR, VAL_GPIOBCRL, VAL_GPIOBCRH},
  .PCData = {VAL_GPIOCODR, VAL_GPIOCCRL, VAL_GPIOCCRH},
  .PDData = {VAL_GPIODODR, VAL_GPIODCRL, VAL_GPIODCRH},
  .PEData = {VAL_GPIOEODR, VAL_GPIOECRL, VAL_GPIOECRH},
};
#endif

/*
 * Early initialization code.
 * This initialization must be performed just after stack setup and before
 * any other initialization.
 */
void __early_init(void) {

  stm32_clock_init();
}

/*
 * Board-specific initialization code.
 */
void boardInit(void) {
}
