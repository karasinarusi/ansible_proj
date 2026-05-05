# запуск
lxc launch ubuntu:22.04 proxy1
lxc launch ubuntu:22.04 proxy2
lxc launch ubuntu:22.04 k8s-master
lxc launch ubuntu:22.04 k8s-worker1
lxc launch ubuntu:22.04 k8s-worker2

# ограничения ресурсов
lxc config set k8s-master limits.memory 2GB
lxc config set k8s-worker1 limits.memory 1536MB
lxc config set k8s-worker2 limits.memory 1536MB
lxc config set proxy1 limits.memory 256MB
lxc config set proxy2 limits.memory 256MB
