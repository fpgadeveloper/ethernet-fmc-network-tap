
#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xemacps.h"
#include "platform_config.h"

#define XEMACPS_GMII2RGMII_SPEED1000_FD		0x140
#define XEMACPS_GMII2RGMII_SPEED100_FD		0x2100
#define XEMACPS_GMII2RGMII_SPEED10_FD		0x100
#define XEMACPS_GMII2RGMII_REG_NUM			0x10
/* Frequency setting */
#define SLCR_LOCK_ADDR			(XPS_SYS_CTRL_BASEADDR + 0x4)
#define SLCR_UNLOCK_ADDR		(XPS_SYS_CTRL_BASEADDR + 0x8)
#define SLCR_GEM0_CLK_CTRL_ADDR	(XPS_SYS_CTRL_BASEADDR + 0x140)
#define SLCR_GEM1_CLK_CTRL_ADDR	(XPS_SYS_CTRL_BASEADDR + 0x144)
#define SLCR_LOCK_KEY_VALUE 	0x767B
#define SLCR_UNLOCK_KEY_VALUE	0xDF0D
#define SLCR_ADDR_GEM_RST_CTRL	(XPS_SYS_CTRL_BASEADDR + 0x214)
#define EMACPS_SLCR_DIV_MASK	0xFC0FC0FF

// GEM_FOR_MDIO defines the GEM that is used for MDIO to configure 
// the GMII-to-RGMII IPs and depends on the carrier board
#if defined(PLATFORM_ZYNQ)
#define GEM_FOR_MDIO XPAR_XEMACPS_1_BASEADDR
#define GEM_FOR_LWIP XPAR_XEMACPS_0_BASEADDR
#endif

#if defined(PLATFORM_ZYNQMP)
#define GEM_FOR_MDIO XPAR_XEMACPS_0_BASEADDR
#define GEM_FOR_LWIP XPAR_XEMACPS_1_BASEADDR
#endif

extern XEmacPs_Config XEmacPs_ConfigTable[];

int nettap_init_emacps(XEmacPs *emacpsp, unsigned int baseaddr);
int nettap_set_gmii_to_rgmii_speed(XEmacPs *emacpsp, unsigned int speed, unsigned int convphyaddr);
XEmacPs_Config *nettap_xemacps_lookup_config(unsigned mac_base);
static void nettap_SetUpSLCRDivisors(unsigned int mac_baseaddr, signed int speed);

int nettap_init();
