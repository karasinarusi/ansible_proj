#!/bin/bash

K8S_NODES=("k8s-master" "k8s-worker1" "k8s-worker2")
ALL_NODES=("proxy1" "proxy2" "${K8S_NODES[@]}")

echo "--- Настройка параметров LXC для K8s ---"
for node in "${K8S_NODES[@]}"; do
  # Проверяем существование контейнера перед настройкой
  if lxc info "$node" >/dev/null 2>&1; then
    lxc config set "$node" \
      security.privileged=true \
      security.nesting=true \
      limits.memory.swap=false \
      linux.kernel_modules=ip_tables,ip_vs,br_netfilter,overlay 
#         lxc config set "$node" raw.lxc "lxc.apparmor.profile=unconfined
# lxc.cap.drop=
# lxc.mount.auto=proc:rw sys:rw cgroup:rw:force
# lxc.cgroup2.devices.allow=a"
    # 2. Безопасная передача raw.lxc через printf без использования EOF
    printf "lxc.apparmor.profile = unconfined\nlxc.cap.drop =\nlxc.mount.auto = proc:rw sys:rw cgroup:rw:force\nlxc.cgroup2.devices.allow = a\n" | lxc config set "$node" raw.lxc -

    # 3. Добавление устройства /dev/kmsg
    lxc config device add "$node" kmsg unix-char path=/dev/kmsg >/dev/null 2>&1

    echo "  [✓] $node: параметры LXC и лимиты swap установлены"
    
    # 4. Перезапуск контейнера для применения всех изменений
    echo "  [ ] $node: перезапуск для применения настроек..."
    lxc restart "$node"
    echo "  [✓] $node: параметры LXC установлены"
  fi
done

echo "--- Настройка SSH и ПО ---"
SSH_PUB_KEY="$HOME/.ssh/id_ed25519.pub"

if [ ! -f "$SSH_PUB_KEY" ]; then
  echo "[✗] Критическая ошибка: SSH-ключ $SSH_PUB_KEY не найден!"
  exit 1
fi

for container in "${ALL_NODES[@]}"; do
  if ! lxc info "$container" >/dev/null 2>&1; then
    echo "  [✗] $container: не существует, пропуск"
    continue
  fi

  echo "  [ ] $container: настройка..."
  
  # Создание папки и проброс ключа
  lxc exec "$container" -- mkdir -p /root/.ssh
  lxc file push "$SSH_PUB_KEY" "$container/root/.ssh/authorized_keys"
  lxc exec "$container" -- chown root:root /root/.ssh/authorized_keys
  lxc exec "$container" -- chmod 600 /root/.ssh/authorized_keys

  # Установка ПО (удалил установку ядра, добавил kmod)
  # -qq и DEBIAN_FRONTEND делают установку тихой и неинтерактивной
  lxc exec "$container" -- bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -o Acquire::ForceIPv4=true -qq
    apt-get install -o Acquire::ForceIPv4=true -y -qq python3 openssh-server kmod curl >/dev/null
  " && echo "  [✓] $container: ПО и SSH настроены" || echo "  [✗] $container: ошибка установки"

done

echo "Все операции завершены!"
