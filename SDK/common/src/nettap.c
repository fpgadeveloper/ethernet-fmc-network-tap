
#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xemacps.h"
#include "nettap.h"


int nettap_init_emacps(XEmacPs *emacpsp, unsigned int baseaddr)
{
  XEmacPs_Config *mac_config;
	signed int status;

	// obtain config of this emac
	mac_config = (XEmacPs_Config *)nettap_xemacps_lookup_config(baseaddr);

	status = XEmacPs_CfgInitialize(emacpsp, mac_config, mac_config->BaseAddress);
	if (status != XST_SUCCESS) {
		return(status);
	}

	XEmacPs_SetMdioDivisor(emacpsp, MDC_DIV_224);

	return(XST_SUCCESS);
}

int nettap_set_gmii_to_rgmii_speed(XEmacPs *emacpsp, unsigned int speed, unsigned int convphyaddr)
{
	unsigned int convspeeddupsetting = 0;

	nettap_SetUpSLCRDivisors(emacpsp->Config.BaseAddress,speed);
	sleep(1);

	if(speed == 1000){
		convspeeddupsetting = XEMACPS_GMII2RGMII_SPEED1000_FD;
	} else if(speed == 100){
		convspeeddupsetting = XEMACPS_GMII2RGMII_SPEED100_FD;
	} else {
		convspeeddupsetting = XEMACPS_GMII2RGMII_SPEED10_FD;
	}
	XEmacPs_PhyWrite(emacpsp, convphyaddr,
	XEMACPS_GMII2RGMII_REG_NUM, convspeeddupsetting);

	return(XST_SUCCESS);
}


XEmacPs_Config *nettap_xemacps_lookup_config(unsigned mac_base)
{
	XEmacPs_Config *cfgptr = NULL;
	signed int i;

	for (i = 0; i < XPAR_XEMACPS_NUM_INSTANCES; i++) {
		if (XEmacPs_ConfigTable[i].BaseAddress == mac_base) {
			cfgptr = &XEmacPs_ConfigTable[i];
			break;
		}
	}

	return (cfgptr);
}


static void nettap_SetUpSLCRDivisors(unsigned int mac_baseaddr, signed int speed)
{
	volatile unsigned int slcrBaseAddress;
	unsigned int SlcrDiv0;
	unsigned int SlcrDiv1;
	unsigned int SlcrTxClkCntrl;
	unsigned int gigeversion;

	gigeversion = ((Xil_In32(mac_baseaddr + 0xFC)) >> 16) & 0xFFF;
	if (gigeversion == 2) {

		*(volatile unsigned int *)(SLCR_UNLOCK_ADDR) = SLCR_UNLOCK_KEY_VALUE;

		if (mac_baseaddr == XPAR_XEMACPS_0_BASEADDR) {
			slcrBaseAddress = SLCR_GEM0_CLK_CTRL_ADDR;
		} else {
			slcrBaseAddress = SLCR_GEM1_CLK_CTRL_ADDR;
		}
		if (speed == 1000) {
			if (mac_baseaddr == XPAR_XEMACPS_0_BASEADDR) {
#ifdef XPAR_PS7_ETHERNET_0_ENET_SLCR_1000MBPS_DIV0
				SlcrDiv0 = XPAR_PS7_ETHERNET_0_ENET_SLCR_1000MBPS_DIV0;
				SlcrDiv1 = XPAR_PS7_ETHERNET_0_ENET_SLCR_1000MBPS_DIV1;
#endif
			} else {
#ifdef XPAR_PS7_ETHERNET_1_ENET_SLCR_1000MBPS_DIV0
				SlcrDiv0 = XPAR_PS7_ETHERNET_1_ENET_SLCR_1000MBPS_DIV0;
				SlcrDiv1 = XPAR_PS7_ETHERNET_1_ENET_SLCR_1000MBPS_DIV1;
#endif
			}
		} else if (speed == 100) {
			if (mac_baseaddr == XPAR_XEMACPS_0_BASEADDR) {
#ifdef XPAR_PS7_ETHERNET_0_ENET_SLCR_100MBPS_DIV0
				SlcrDiv0 = XPAR_PS7_ETHERNET_0_ENET_SLCR_100MBPS_DIV0;
				SlcrDiv1 = XPAR_PS7_ETHERNET_0_ENET_SLCR_100MBPS_DIV1;
#endif
			} else {
#ifdef XPAR_PS7_ETHERNET_1_ENET_SLCR_100MBPS_DIV0
				SlcrDiv0 = XPAR_PS7_ETHERNET_1_ENET_SLCR_100MBPS_DIV0;
				SlcrDiv1 = XPAR_PS7_ETHERNET_1_ENET_SLCR_100MBPS_DIV1;
#endif
			}
		} else {
			if (mac_baseaddr == XPAR_XEMACPS_0_BASEADDR) {
#ifdef XPAR_PS7_ETHERNET_0_ENET_SLCR_10MBPS_DIV0
				SlcrDiv0 = XPAR_PS7_ETHERNET_0_ENET_SLCR_10MBPS_DIV0;
				SlcrDiv1 = XPAR_PS7_ETHERNET_0_ENET_SLCR_10MBPS_DIV1;
#endif
			} else {
#ifdef XPAR_PS7_ETHERNET_1_ENET_SLCR_10MBPS_DIV0
				SlcrDiv0 = XPAR_PS7_ETHERNET_1_ENET_SLCR_10MBPS_DIV0;
				SlcrDiv1 = XPAR_PS7_ETHERNET_1_ENET_SLCR_10MBPS_DIV1;
#endif
			}
		}
		SlcrTxClkCntrl = *(volatile unsigned int *)(slcrBaseAddress);
		SlcrTxClkCntrl &= EMACPS_SLCR_DIV_MASK;
		SlcrTxClkCntrl |= (SlcrDiv1 << 20);
		SlcrTxClkCntrl |= (SlcrDiv0 << 8);
		*(volatile unsigned int *)(slcrBaseAddress) = SlcrTxClkCntrl;
		*(volatile unsigned int *)(SLCR_LOCK_ADDR) = SLCR_LOCK_KEY_VALUE;
	}
	return;
}


int nettap_init()
{
  XEmacPs emacps;
	signed int status;

    xil_printf("Configuring GEM for Network Tap\n\r");

    // Setup EMAC
    status = nettap_init_emacps(&emacps,GEM_FOR_MDIO);
	if (status != XST_SUCCESS) {
		xil_printf("EmacPs Configuration Failed\r\n");
	}

	// Set GMII-to-RGMII block link speed
	nettap_set_gmii_to_rgmii_speed(&emacps,1000,7);
	nettap_set_gmii_to_rgmii_speed(&emacps,1000,8);

    xil_printf("Finished\n\r");

    return XST_SUCCESS;
}
