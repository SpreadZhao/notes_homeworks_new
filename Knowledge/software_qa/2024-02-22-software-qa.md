---
title: Docker踩坑
date: 2024-02-22
tags: 
mtrace:
  - 2024-02-22
---

#date 2024-02-22

# Docker踩坑

docker安装失败没有docker-ce-cli：[ubuntu - Docker Desktop doesn't install saying docker-ce-cli not installable - Stack Overflow](https://stackoverflow.com/questions/72299444/docker-desktop-doesnt-install-saying-docker-ce-cli-not-installable)

docker-desktop启动失败：[sudo rm /etc/xdg/systemd/user/docker-desktop.service](https://stackoverflow.com/questions/75907472/docker-desktop-does-not-launch-on-ubuntu-failed-to-start-docker-desktop-service)

彻底卸载docker：[sudo apt-get autoremove -y --purge docker-engine docker docker.io docker-ce docker-compose-plugin](https://askubuntu.com/questions/935569/how-to-completely-uninstall-docker)