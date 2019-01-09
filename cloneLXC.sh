#!/bin/sh
####### Criado por OpenSea #######
### openseatecnologia.github.io ##

# Informe as variaveis conforme cenario
# Nome do Container
container=zabbix
oldcontainer=$( lxc-ls $container- )

# Variavel para diferenciar o backup
data=$(date +'%Y-%m-%d')

# A rotina abaixo mantem apenas uma copia
lxc-stop -n $container
lxc-destroy -n $oldcontainer
lxc-copy -n $container -N $container-$data
lxc-start -n $container

# Caminho de Backup do Container
containerpath=/var/lib/lxc/$container-$data
cd $containerpath

# Desabilitar o autostart do backup, necessario descomentar caso voltar o backup
sed -i -e 's/lxc.start.auto/#lxc.start.auto/g' config
