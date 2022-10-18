edu设备继承自COMBO6 cards，这是一种飞机上的设备。而edu设备的id号和pci空间都是继承自这个设备。

接下来是edu设备的内存空间中，某些地址对应的功能：

* 0x00：只读空间，存的是edu设备的id，格式是`0xRRrr00edu`。其中RR是major version，rr是minor version。
* 0x04：可读可写。这部分是edu设备其中的一个功能：value inversion。在原来的飞机上，这部分的功能叫做card liveness check。具体其实就是将传进去的数进行按位取反。在我们测试的程序中已经有如下的代码：
 ```c
i = 0x12345678;
bar0[EDU_CARD_LIVENESS_ADDR] = i;
fprintf(stdout, "Inversion: %08X --> %08X\n", i, bar0[EDU_CARD_LIVENESS_ADDR]);
 ```
将0001按位取反后是E，将0010按位取反之后是D……如此进行下去，将i取反后结果就是`EDCBA987`。
* 0x08：可读可写。这时edu设备的另一个功能：阶乘计算。这里是放需要计算的数，当计算成功后，结果也是放在这里。那么如何触发这个功能呢？就是下面的状态寄存器。
* 0x20：可读可写。状态寄存器，按位或(*这是什么意思？*)。当是0x01的时候，就计算0x08中存的数的阶乘；当是0x80的时候，就在计算结束后产生一个中断。
* 0x24：只读。中断状态寄存器。下面两个都是用来控制它的。
* 0x60：只写。中断产生寄存器。产生一个中断，写进去的值会被放到0x24里(使用按位或)。
* 0x64：只写。清除0x24中的值。然后ISR(Interrupt Service Routines)负责停止产生中断。

接下来是一些和DMA相关的空间，和前面一起直接贴出英文原文：

>MMIO area spec
>Only size == 4 accesses are allowed for addresses < 0x80. size == 4 or size == 8 for the rest.
>0x00 (RO) : identification (0xRRrr00edu)
>RR -- major version
>rr -- minor version	    
>0x04 (RW) : card liveness check It is a simple value inversion (~ C operator).
>0x08 (RW) : factorial computation The stored value is taken and factorial of it is put back here.This happens only after factorial bit in the status register (0x20 below) is cleared.
>0x20 (RW) : status register, bitwise OR 0x01 -- computing factorial (RO) 0x80 -- raise interrupt after finishing factorial computation
>0x24 (RO) : interrupt status register It contains values which raised the interrupt (see interrupt raise register below).
>0x60 (WO) : interrupt raise register Raise an interrupt. The value will be put to the interrupt status register (using bitwise OR).
>0x64 (WO) : interrupt acknowledge register Clear an interrupt. The value will be cleared from the interrupt status register. This needs to be done from the ISR to stop generating interrupts.
>0x80 (RW) : DMA source address Where to perform the DMA from.
>0x88 (RW) : DMA destination address Where to perform the DMA to.
>0x90 (RW) : DMA transfer count The size of the area to perform the DMA on.
>0x98 (RW) : DMA command register, bitwise OR 0x01 -- start transfer 0x02 -- direction (0: from RAM to EDU, 1: from EDU to RAM) 0x04 -- raise interrupt 0x100 after finishing the DMA

对于edu的驱动程序，我在Stack Overflow上找到了一个pci设备通用的驱动程序——`uio_pci_generic`。这是Linux自带的一个模块，它其实就是一个pci的设备驱动程序，代码如下：

```c
// SPDX-License-Identifier: GPL-2.0
/* uio_pci_generic - generic UIO driver for PCI 2.3 devices
 *
 * Copyright (C) 2009 Red Hat, Inc.
 * Author: Michael S. Tsirkin <mst@redhat.com>
 *
 * Since the driver does not declare any device ids, you must allocate
 * id and bind the device to the driver yourself.  For example:
 *
 * # echo "8086 10f5" > /sys/bus/pci/drivers/uio_pci_generic/new_id
 * # echo -n 0000:00:19.0 > /sys/bus/pci/drivers/e1000e/unbind
 * # echo -n 0000:00:19.0 > /sys/bus/pci/drivers/uio_pci_generic/bind
 * # ls -l /sys/bus/pci/devices/0000:00:19.0/driver
 * .../0000:00:19.0/driver -> ../../../bus/pci/drivers/uio_pci_generic
 *
 * Driver won't bind to devices which do not support the Interrupt Disable Bit
 * in the command register. All devices compliant to PCI 2.3 (circa 2002) and
 * all compliant PCI Express devices should support this bit.
 */

#include <linux/device.h>
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/slab.h>
#include <linux/uio_driver.h>

#define DRIVER_VERSION	"0.01.0"
#define DRIVER_AUTHOR	"Michael S. Tsirkin <mst@redhat.com>"
#define DRIVER_DESC	"Generic UIO driver for PCI 2.3 devices"

struct uio_pci_generic_dev {
	struct uio_info info;
	struct pci_dev *pdev;
};

static inline struct uio_pci_generic_dev *
to_uio_pci_generic_dev(struct uio_info *info)
{
	return container_of(info, struct uio_pci_generic_dev, info);
}

static int release(struct uio_info *info, struct inode *inode)
{
	struct uio_pci_generic_dev *gdev = to_uio_pci_generic_dev(info);

	/*
	 * This driver is insecure when used with devices doing DMA, but some
	 * people (mis)use it with such devices.
	 * Let's at least make sure DMA isn't left enabled after the userspace
	 * driver closes the fd.
	 * Note that there's a non-zero chance doing this will wedge the device
	 * at least until reset.
	 */
	pci_clear_master(gdev->pdev);
	return 0;
}

/* Interrupt handler. Read/modify/write the command register to disable
 * the interrupt. */
static irqreturn_t irqhandler(int irq, struct uio_info *info)
{
	struct uio_pci_generic_dev *gdev = to_uio_pci_generic_dev(info);

	if (!pci_check_and_mask_intx(gdev->pdev))
		return IRQ_NONE;

	/* UIO core will signal the user process. */
	return IRQ_HANDLED;
}

static int probe(struct pci_dev *pdev,
			   const struct pci_device_id *id)
{
	struct uio_pci_generic_dev *gdev;
	struct uio_mem *uiomem;
	int err;
	int i;

	err = pcim_enable_device(pdev);
	if (err) {
		dev_err(&pdev->dev, "%s: pci_enable_device failed: %d\n",
			__func__, err);
		return err;
	}

	if (pdev->irq && !pci_intx_mask_supported(pdev))
		return -ENODEV;

	gdev = devm_kzalloc(&pdev->dev, sizeof(struct uio_pci_generic_dev), GFP_KERNEL);
	if (!gdev)
		return -ENOMEM;

	gdev->info.name = "uio_pci_generic";
	gdev->info.version = DRIVER_VERSION;
	gdev->info.release = release;
	gdev->pdev = pdev;
	if (pdev->irq && (pdev->irq != IRQ_NOTCONNECTED)) {
		gdev->info.irq = pdev->irq;
		gdev->info.irq_flags = IRQF_SHARED;
		gdev->info.handler = irqhandler;
	} else {
		dev_warn(&pdev->dev, "No IRQ assigned to device: "
			 "no support for interrupts?\n");
	}

	uiomem = &gdev->info.mem[0];
	for (i = 0; i < MAX_UIO_MAPS; ++i) {
		struct resource *r = &pdev->resource[i];

		if (r->flags != (IORESOURCE_SIZEALIGN | IORESOURCE_MEM))
			continue;

		if (uiomem >= &gdev->info.mem[MAX_UIO_MAPS]) {
			dev_warn(
				&pdev->dev,
				"device has more than " __stringify(
					MAX_UIO_MAPS) " I/O memory resources.\n");
			break;
		}

		uiomem->memtype = UIO_MEM_PHYS;
		uiomem->addr = r->start & PAGE_MASK;
		uiomem->offs = r->start & ~PAGE_MASK;
		uiomem->size =
			(uiomem->offs + resource_size(r) + PAGE_SIZE - 1) &
			PAGE_MASK;
		uiomem->name = r->name;
		++uiomem;
	}

	while (uiomem < &gdev->info.mem[MAX_UIO_MAPS]) {
		uiomem->size = 0;
		++uiomem;
	}

	return devm_uio_register_device(&pdev->dev, &gdev->info);
}

static struct pci_driver uio_pci_driver = {
	.name = "uio_pci_generic",
	.id_table = NULL, /* only dynamic id's */
	.probe = probe,
};

module_pci_driver(uio_pci_driver);
MODULE_VERSION(DRIVER_VERSION);
MODULE_LICENSE("GPL v2");
MODULE_AUTHOR(DRIVER_AUTHOR);
MODULE_DESCRIPTION(DRIVER_DESC);
```

我们能看到，它并不支持静态的设备id，所以我们要把`pci_device_id`动态地导入。首先插入模块，然后将edu设备的id写进去：

```shell
modprobe uio_pci_generic
echo "1234 11e8" > /sys/bus/pci/drivers/uio_pci_generic/new_id
```

这样我们就能在pci设备列表中查找到它的信息了：

```shell
ls -l /sys/bus/pci/devices/0000\:00\:04.0/driver

lrwxrwxrwx 1 root root 0 Mar 15 01:50 /sys/bus/pci/devices/0000:00:04.0/driver -> ../../../bus/pci/drivers/uio_pci_generic
```

接下来是使用这个设备，因为`uio_pci_generic`不会把edu设备的base addresss映射到map中。结论是，在此驱动下，edu设备的mmio被映射到了`/sys/class/uio/uio0/device/resource0`，而处理中断的信息被映射到了`/dev/uio0`。由此才有了如下的测试代码：

```c
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <stdint.h>
#include <sys/mman.h>


#define EDU_IO_SIZE 0x100
#define EDU_CARD_VERSION_ADDR  0x0
#define EDU_CARD_LIVENESS_ADDR 0x1
#define EDU_RAISE_INT_ADDR 0x18
#define EDU_CLEAR_INT_ADDR 0x19

int main()
{
    int uiofd;
    int configfd;
    int bar0fd;
    int resetfd;
    int err;
    int i;
    unsigned icount;
    unsigned char command_high;
    volatile uint32_t *bar0;

    uiofd = open("/dev/uio0", O_RDWR);
    if (uiofd < 0) {
        perror("uio open:");
        return errno;
    }

    configfd = open("/sys/class/uio/uio0/device/config", O_RDWR);
    if (configfd < 0) {
        perror("config open:");
        return errno;
    }

    /* Read and cache command value */
    err = pread(configfd, &command_high, 1, 5);
    if (err != 1) {
        perror("command config read:");
        return errno;
    }
    command_high &= ~0x4;

    /* Map edu's MMIO */
    bar0fd = open("/sys/class/uio/uio0/device/resource0", O_RDWR);
    if (bar0fd < 0) {
        perror("bar0fd open:");
        return errno;
    }

    /* mmap the device's BAR */
    bar0 = (volatile uint32_t *)mmap(NULL, EDU_IO_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, bar0fd, 0);
    if (bar0 == MAP_FAILED) {
        perror("Error mapping bar0!");
        return errno;
    }
    fprintf(stdout, "Version = %08X\n", bar0[EDU_CARD_VERSION_ADDR]);

    /* Test the invertor function */
    i = 0x12345678;
    bar0[EDU_CARD_LIVENESS_ADDR] = i;
    fprintf(stdout, "Inversion: %08X --> %08X\n", i, bar0[EDU_CARD_LIVENESS_ADDR]);

    /* Clear previous interrupt */
    bar0[EDU_CLEAR_INT_ADDR] = 0xABCDABCD;

    /* Raise an interrupt */
    bar0[EDU_RAISE_INT_ADDR] = 0xABCDABCD;

    for(i = 0;; ++i) {
        /* Print out a message, for debugging. */
        if (i == 0)
            fprintf(stderr, "Started uio test driver.\n");
        else
            fprintf(stderr, "Interrupts: %d\n", icount);

        /****************************************/
        /* Here we got an interrupt from the
           device. Do something to it. */
        /****************************************/

        /* Re-enable interrupts. */
        err = pwrite(configfd, &command_high, 1, 5);
        if (err != 1) {
            perror("config write:");
            break;
        }

        /* Clear previous interrupt */
        bar0[EDU_CLEAR_INT_ADDR] = 0xABCDABCD;

        /* Raise an interrupt */
        bar0[EDU_RAISE_INT_ADDR] = 0xABCDABCD;

        /* Wait for next interrupt. */
        err = read(uiofd, &icount, 4);
        if (err != 4) {
            perror("uio read:");
            break;
        }

    }
    return errno;
}
```

最终我们也确实得到了正确的输出：

```shell
Version = 010000ED
Inversion: 12345678 --> EDCBA987
Started uio test driver.
Interrupts: 3793548
Interrupts: 3793549
Interrupts: 3793550
Interrupts: 3793551
Interrupts: 3793552
Interrupts: 3793553
Interrupts: 3793554
Interrupts: 3793555
Interrupts: 3793556
...
```

这其中遇到的问题是：在其中我们定义的edu设备的各种功能的地址空间：

```c
#define EDU_IO_SIZE 0x100
#define EDU_CARD_VERSION_ADDR  0x0
#define EDU_CARD_LIVENESS_ADDR 0x1
#define EDU_RAISE_INT_ADDR 0x18
#define EDU_CLEAR_INT_ADDR 0x19
```

这和在`edu.txt`中，也就是文章开头介绍的edu的地址完全不一样。比如0x04是我们之前介绍的被按位取反的数的位置，而在这个测试代码中却是0x1。但是却也实现了这个功能，这是为什么？