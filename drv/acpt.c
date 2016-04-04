#define DEBUG
#include <linux/kernel.h>
#include <linux/dma-mapping.h>
#include <linux/interrupt.h>
#include <linux/of.h>
#include <linux/of_device.h>
#include <linux/of_address.h>
#include <linux/of_irq.h>
#include <linux/mfd/syscon.h>
#include <linux/module.h>
#include <linux/clk.h>
#include <linux/regmap.h>
#include <linux/ioport.h>
#include <asm/io.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/uaccess.h>
#include <linux/mm.h>
#include <linux/slab.h>

typedef struct {
	uint32_t dw[16];
} desc_t;

typedef struct {
	struct device *dev;
	void __iomem *mmio;

	desc_t *req;
	desc_t *rsp;
	uint16_t *req_ci;
	uint16_t *rsp_pi;
	dma_addr_t req_a;
	dma_addr_t req_ci_a;
	dma_addr_t rsp_a;
	dma_addr_t rsp_pi_a;
} acpt_t;

static struct of_device_id acpt_of_match[] = {
	{ .compatible = "BiTMICRO,acpt-1.0", },

	{},
};

enum {
	HPS2IP_BASE   = 0x00,
	HPS2IP_MINDEX = 0x08,
	HPS2IP_PI     = 0x0C,
	HPS2IP_CI     = 0x10,

	IP2HPS_BASE   = 0x20,
	IP2HPS_PI_BASE= 0x24,
	IP2HPS_MINDEX = 0x28,
	IP2HPS_PI     = 0x2C,
	IP2HPS_CI     = 0x30,

	DMA_EN        = 0x3C,
};

static int acpt_probe(struct platform_device *pdev)
{
	int res, sz = 65536, mxi;
	struct device *dev = &pdev->dev;
	struct device_node *np = dev->of_node;
	const struct of_device_id *of_id;
	uint32_t seq = jiffies << 16;
	void __iomem *mmio;
	acpt_t *acpt;
	desc_t *req, *rsp;
	uint32_t awreg = 0, arreg = 0;

	pr_debug("++ %s\n", __func__);
	of_id = of_match_device(acpt_of_match, dev);

	acpt = devm_kzalloc(dev, sizeof(*acpt), GFP_KERNEL);
	if (acpt == NULL) {
		res = -ENOMEM;
		goto out;
	}

	mmio = acpt->mmio = of_iomap(np, 0);
	if (acpt->mmio == NULL) {
		res = -ENODEV;
		goto out;
	}
	req = acpt->req = dmam_alloc_coherent(dev, sz, &acpt->req_a, GFP_KERNEL);
	rsp = acpt->rsp = dmam_alloc_coherent(dev, sz, &acpt->rsp_a, GFP_KERNEL);
	acpt->rsp_pi = dmam_alloc_coherent(dev, 4096, &acpt->rsp_pi_a, GFP_KERNEL);
	if (acpt->req == NULL ||
	    acpt->rsp == NULL ||
	    acpt->rsp_pi == NULL) {
		res = -ENOMEM;
		goto out;
	}
	acpt->req_ci   = acpt->rsp_pi + 2;
	acpt->req_ci_a = acpt->rsp_pi_a + 2;
	pr_debug("req %p/%08x, rsp %p/%08x, %p/%08x, seq %08x\n",
			acpt->req, (uint32_t)acpt->req_a,
			acpt->rsp, (uint32_t)acpt->rsp_a,
			acpt->rsp_pi, (uint32_t)acpt->rsp_pi_a, seq);

	/* [2:0] prot :   0b001
	 * [6:3] cache:  0b1111
	 * [11:7] user:0b1_1111
	 */
	arreg = (0x1 << 0) |
		(0xf << 3) |
		(0x1f<< 7);
	awreg = (0x1 << 0) |
		(0xf << 3) |
		(0x1f<< 7);

	writel((arreg<<16)|awreg, mmio + 0x38);
	pr_debug("awreg %x, arreg %x\n", awreg, arreg);

	/* disable DMA */
	writel(0, mmio + DMA_EN);
	for (res = 0; res < 128; res ++) {
		req->dw[res] = seq + res;
	}
	*acpt->rsp_pi = 0;
	*acpt->req_ci = 0;

	mxi = sz / sizeof(desc_t);
	writel(acpt->req_a,   mmio + HPS2IP_BASE);
	writel(mxi,           mmio + HPS2IP_MINDEX);
	writel(0,             mmio + HPS2IP_PI);

	writel(acpt->rsp_a,   mmio + IP2HPS_BASE);
	writel(mxi,           mmio + IP2HPS_MINDEX);
	writel(acpt->rsp_pi_a,mmio + IP2HPS_PI_BASE);
	writel(0,             mmio + IP2HPS_CI);

	writel(1, mmio + DMA_EN);
	pr_debug("en %x\n", readl(mmio + DMA_EN));
	writel(2, mmio + HPS2IP_PI);

	pr_debug("req %08x/%08x: mxi %x, pi %x/%x\n",
			readl(mmio + HPS2IP_BASE), acpt->req_a,
			readl(mmio + HPS2IP_MINDEX),
			readl(mmio + HPS2IP_PI),
			readl(mmio + HPS2IP_CI));
	pr_debug("rsp %08x/%08x: mxi %x, pi %x/%x, rsp_pi %08x/%08x\n",
			readl(mmio + IP2HPS_BASE), acpt->rsp_a,
			readl(mmio + IP2HPS_MINDEX),
			readl(mmio + IP2HPS_PI),
			readl(mmio + IP2HPS_CI),
			readl(mmio + IP2HPS_PI_BASE), acpt->rsp_pi_a);
	pr_debug("req ci %04x: %08x %08x %08x %08x - %08x %08x %08x %08x\n",
			*acpt->req_ci,
			req->dw[0], req->dw[1], req->dw[2], req->dw[3],
			req->dw[4], req->dw[5], req->dw[6], req->dw[7]);
	pr_debug("rsp pi %04x: %08x %08x %08x %08x - %08x %08x %08x %08x\n",
			*acpt->rsp_pi,
			rsp->dw[0], rsp->dw[1], rsp->dw[2], rsp->dw[3],
			rsp->dw[4], rsp->dw[5], rsp->dw[6], rsp->dw[7]);
	res = 0;
out:
	pr_debug("-- %s, %d\n", __func__, res);
	return res;
}

static int acpt_remove(struct platform_device *pdev)
{
	return 0;
}

static struct platform_driver acpt_plat_driver = {
	.probe  = acpt_probe,
	.remove = acpt_remove,
	.driver = {
		.name = "acpt-drv",
		.owner = THIS_MODULE,
		.of_match_table = of_match_ptr(acpt_of_match),
	},
};

static int __init acpt_init(void)
{
	return platform_driver_register(&acpt_plat_driver);
}

static void __exit acpt_exit(void)
{
	platform_driver_unregister(&acpt_plat_driver);
}

module_init(acpt_init);
module_exit(acpt_exit);

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Steve Hu<steve.hu@bitmicro.com>");
MODULE_DESCRIPTION("acpt driver for linux with HPS");
MODULE_VERSION("0.1");
