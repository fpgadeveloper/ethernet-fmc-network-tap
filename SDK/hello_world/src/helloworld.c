/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xemacps.h"

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

XEmacPs emacps;
XEmacPs_Config *mac_config;
extern XEmacPs_Config XEmacPs_ConfigTable[];

int init_emacps(XEmacPs *emacpsp, unsigned int baseaddr);
int set_gmii_to_rgmii_speed(XEmacPs *emacpsp, unsigned int speed, unsigned int convphyaddr);
XEmacPs_Config *xemacps_lookup_config(unsigned mac_base);
static void SetUpSLCRDivisors(unsigned int mac_baseaddr, signed int speed);

int main()
{
	signed int status;

    init_platform();

    xil_printf("Hello World\n\r");

    // Setup EMAC
    status = init_emacps(&emacps,XPAR_PS7_ETHERNET_1_BASEADDR);
	if (status != XST_SUCCESS) {
		xil_printf("EmacPs1 Configuration Failed\r\n");
	}

	// Set GMII-to-RGMII block link speed
	set_gmii_to_rgmii_speed(&emacps,1000,7);
	set_gmii_to_rgmii_speed(&emacps,1000,8);

    xil_printf("Finished\n\r");

    cleanup_platform();
    return 0;
}


int init_emacps(XEmacPs *emacpsp, unsigned int baseaddr)
{
	signed int status;

	// obtain config of this emac
	mac_config = (XEmacPs_Config *)xemacps_lookup_config(baseaddr);

	status = XEmacPs_CfgInitialize(emacpsp, mac_config, mac_config->BaseAddress);
	if (status != XST_SUCCESS) {
		return(status);
	}

	XEmacPs_SetMdioDivisor(emacpsp, MDC_DIV_224);

	return(XST_SUCCESS);
}

int set_gmii_to_rgmii_speed(XEmacPs *emacpsp, unsigned int speed, unsigned int convphyaddr)
{
	unsigned int convspeeddupsetting = 0;

	SetUpSLCRDivisors(emacpsp->Config.BaseAddress,speed);
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


XEmacPs_Config *xemacps_lookup_config(unsigned mac_base)
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


static void SetUpSLCRDivisors(unsigned int mac_baseaddr, signed int speed)
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
