上一篇文章写了[字符设备](https://so.csdn.net/so/search?q=%E5%AD%97%E7%AC%A6%E8%AE%BE%E5%A4%87&spm=1001.2101.3001.7020)驱动的基本结构及访问方式，在实际应用时首先需要绑定自己的硬件设备。本篇主要描述字符设备驱动与PCI接口类型的设备访问方式(内核为2.6.24及以上的方法，测试内核为2.6.32)。

**首先介绍下PCI驱动结构：**

```c
//PCI设备id描述结构：这里有两个参数 第一个是VendorID，第二个是DeviceID(在linux Terminal中输入 lspci -vmm可以看到设备信息) 
static struct pci_device_id pci_ids[] = {
    { PCI_DEVICE(Vendor,Device) },
    { 0 }
};

//PCI设备描述结构：指定PCI设备函数
static struct pci_driver driver_ops = {
    .name = DevName,//驱动名称
    .id_table = pci_ids,//PCI设备id描述结构
    .probe = pci_probe,//PCI入口函数
    .remove = pci_remove,//PCI退出函数
};

//PCI驱动注册函数
//注意项：如果没有探测到 PCI设备id描述结构(指定的VendorID或DeviceID在Terminal中查找不到)或者指定的设备已经绑定了驱动，那么PCI入口函数以及PCI退出函数不会执行(PCI设备描述结构内指定的别的函数也是如此)
pci_register_driver(&driver_ops);

```

```c
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/version.h>
#include <linux/vmalloc.h>
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/device.h>

#define DevName 	"test"
#define ClassName 	"class_test"
#define VendorID 	0xFA01
#define DeviceID   	0x1234

struct class    *mem_class;
struct Pci_Test
{
	struct cdev 	_cdev;
	dev_t    	dev;
	char 		msi_enabled;
}*pci_test;


static int Test_open(struct inode *inode,struct file *filp)
{
	return 0;
}

static int Test_release(struct inode *inode,struct file *filp)
{
	return 0;
}


static struct file_operations test_fops = {
.owner = THIS_MODULE,
//.ioctl = Test_ioctl,
.open = Test_open,
.release = Test_release,
};

//字符驱动
static init_chrdev(struct Pci_Test *test_ptr)
{
	int result = alloc_chrdev_region(&test_ptr->dev, 0, 2, DevName);
	if (result < 0)
	{
		printk("Err:failed in alloc_chrdev_region!\n");
		return result;
	}
	
	mem_class = class_create(THIS_MODULE,ClassName);// /dev/ create devfile 
    	if (IS_ERR(mem_class))
    	{
		printk("Err:failed in creating class!\n");
  	}
	device_create(mem_class,NULL,test_ptr->dev,NULL,DevName);

	cdev_init(&test_ptr->_cdev,&test_fops);
	test_ptr->_cdev.owner = THIS_MODULE;
	test_ptr->_cdev.ops = &test_fops;//Create Dev and file_operations Connected
	result = cdev_add(&test_ptr->_cdev,test_ptr->dev,1);
	return result;
}

//PCI驱动入口函数
static int __init pci_probe(struct pci_dev *dev, const struct pci_device_id *id)
{
	int rc = 0;
	pci_test = dev;
    	pci_set_drvdata(dev, pci_test);
    //在这里创建字符设备驱动
	rc = init_chrdev(pci_test); 
    	if (rc) {
        	dev_err(&dev->dev, "init_chrdev() failed\n");
        	return -1;
    	}

	rc = pci_enable_device(dev);
    	if (rc) {
        	dev_err(&dev->dev, "pci_enable_device() failed\n");
       		return -1;
    	} 

	rc = pci_request_regions(dev, DevName);
    	if (rc) {
        	dev_err(&dev->dev, "pci_request_regions() failed\n");
        	return -1;
    	}

    	pci_set_master(dev);
    	rc = pci_enable_msi(dev);
   	if (rc) {
        	dev_info(&dev->dev, "pci_enable_msi() failed\n");
        	pci_test->msi_enabled = 0;
    	} else {
        	dev_info(&dev->dev, "pci_enable_msi() successful\n");
       	 	pci_test->msi_enabled = 1;
   	}

	return rc;
}

static void __exit pci_remove(struct pci_dev *dev)
{
    	if (0 != mem_class)
    	{
		device_destroy(mem_class,pci_test->dev);
		class_destroy(mem_class);
		mem_class = 0;
    	}

	pci_test = pci_get_drvdata(dev);
    	cdev_del(&pci_test->_cdev);
    	unregister_chrdev_region(pci_test->dev, 1);
   	pci_disable_device(dev);

    	if(pci_test) {
        	if(pci_test->msi_enabled) {
            		pci_disable_msi(dev);
            		pci_test->msi_enabled = 0;
        		}
    	}
 
    	pci_release_regions(dev);
}

static struct pci_device_id pci_ids[] = {
    { PCI_DEVICE( VendorID, DeviceID) },
    { 0 }
};

static struct pci_driver driver_ops = {
    .name = DevName,
    .id_table = pci_ids,
    .probe = pci_probe,
    .remove = pci_remove,
};
//驱动模块入口函数
static int Test_init_module(void)
{
	int rc = 0;
	pci_test = kzalloc(sizeof(struct Pci_Test), GFP_KERNEL);
	//配对设备以及注册PCI驱动，如果找到对应设备调用PCI入口函数
	rc = pci_register_driver(&driver_ops);
    	if (rc) {
       		printk(KERN_ALERT  ": PCI driver registration failed\n");
    	}
	
	return rc;
}

static void Test_exit_module(void)
{
	pci_unregister_driver(&driver_ops);
	kfree(pci_test);
}
module_init(Test_init_module);
module_exit(Test_exit_module);
MODULE_AUTHOR(DevName);
MODULE_LICENSE("GPL");
```

