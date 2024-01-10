#TODO

- [ ] 找到jitter逻辑中，一帧超过一个vsync interval之后，第二个vsync信号来的时候，发现第一帧的handler还在干活儿，延时发送第二帧的msg的逻辑在哪里。