# Wayland note

## Wayland compositor

> the role of the Wayland compositor is to <u>dispatch input events to the appropriate Wayland client and to display their windows in their appropriate place on your outputs.</u>
>
> The process of bringing together all of your application windows for display on an output is called **compositing** — and thus we call the software which does this the **compositor**.

## DRM

> Linux's job is to provide an abstraction over your hardware, so that they can be safely accessed by user space — **where our Wayland compositors run**. For graphics, this is called **DRM**, or **direct rendering manager**, for efficiently <u>tasking the GPU with work from user space</u>.

## KMS

> <u>An important subsystem of DRM is **KMS**</u>, or **kernel mode setting**, for <u>enumerating your displays and setting properties</u> such as their selected resolution (also known as their "mode").

## evdev

>  **Input devices** are abstracted through an interface called **evdev**.

## Mesa, GBM

> It provides, among other things, vendor-optimized implementations of OpenGL (and Vulkan) for Linux and the **GBM** (Generic Buffer Management) library — <u>an abstraction on top of libdrm for allocating buffers on the GPU</u>. Most Wayland compositors will use both GBM and OpenGL via Mesa, and most Wayland clients will use at least its OpenGL or Vulkan implementations.

## 其他需要注意的点

* 安装`libwayland-dev`，包含了`wayland-client.h`等头文件