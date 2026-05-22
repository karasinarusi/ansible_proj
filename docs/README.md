# Инструкция для локального запуска с использованием контейнеров LXC

Технические требования:
8гб оперативной памяти
не arm процессор
установленный lxc lxd


## Шаг 1: Создание контейнеров

Запустите следующие контейнеры на базе Ubuntu 22.04:

```bash
lxc launch ubuntu:22.04 proxy1
lxc launch ubuntu:22.04 proxy2
lxc launch ubuntu:22.04 k8s-master
lxc launch ubuntu:22.04 k8s-worker1
lxc launch ubuntu:22.04 k8s-worker2
```


## Шаг 2: Ограничение ресурсов(что бы уместились в 6 гб оперативной памяти)

```bash
lxc config set k8s-master limits.memory 2GB
lxc config set k8s-worker1 limits.memory 1536MB
lxc config set k8s-worker2 limits.memory 1536MB
lxc config set proxy1 limits.memory 512MB
lxc config set proxy2 limits.memory 512MB
```


## Шаг 3: Получение ip контейнеров и запись их в inventory.ini
Вывести споисок запущенных контейнеров командой
```bash
lxc list
```
Воспользоваться калонокой IPV4 и скопировать адреса в соотвествующие ansible_host переменные.

## Шаг 4: Выполнить подготовку контейнеров
Выполнить скрипт, устанавливающий необходимые настройки и подключени по ssh к контейнерам.
```bash
docs/creation_script.sh
```
## Шаг 5: Запустить плейбук
```bash
ansible-playbook -i inventory.ini site.yml -e "ansible_ssh_common_args='-o StrictHostKeyChecking=no'"   
```