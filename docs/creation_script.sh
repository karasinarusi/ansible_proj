#!/bin/bash

# Списки контейнеров
K8S_NODES=("k8s-master" "k8s-worker1" "k8s-worker2")
ALL_NODES=("proxy1" "proxy2" "${K8S_NODES[@]}")

echo "--- Настройка параметров LXC для K8s ---"
for node in "${K8S_NODES[@]}"; do
  lxc config set "$node" \
    security.privileged=true \
    security.nesting=true \
    linux.kernel_modules=ip_tables,ip_vs,br_netfilter \
    raw.lxc="lxc.apparmor.profile=unconfined"$'\n'"lxc.cap.drop="$'\n'"lxc.cgroup.devices.allow=a"$'\n'"lxc.mount.auto=proc:rw sys:rw"
done

echo "--- Настройка SSH и базового ПО ---"
for container in "${ALL_NODES[@]}"; do
  (
    # Проверка наличия SSH‑ключа
    if [ ! -f ~/.ssh/id_ed25519.pub ]; then
      echo "  [✗] $container: SSH‑ключ не найден"
      continue
    fi

    # Копирование SSH‑ключей
    lxc exec "$container" -- mkdir -p /root/.ssh
    lxc file push ~/.ssh/id_ed25519.pub "$container/root/.ssh/authorized_keys" 2>/dev/null || \
    lxc exec "$container" -- bash -c "echo '$(cat ~/.ssh/id_ed25519.pub)' > /root/.ssh/authorized_keys"

    # Установка прав доступа
    lxc exec "$container" -- chmod 600 /root/.ssh/authorized_keys
    lxc exec "$container" -- chown root:root /root/.ssh/authorized_keys

    # Быстрая установка без лишних логов
    if lxc exec "$container" -- bash -c "apt-get update && apt-get install -y python3 openssh-server"; then
      echo "  [✓] $container: ПО установлено"
    else
      echo "  [✗] $container: ошибка установки ПО"
    fi
  )
done

echo "Done!"


