#!/bin/bash
### Script para buscar informações de rastreio de arquivos XML em CTEs da Azul e Jadlog apenas ###


for cte in xml/*
do
export transportadora=$(grep -Po '<xNome>.*</xNome>' $cte | head -n1)
export chave=$(grep -Po '<chave>.*</chave>' $cte)
export nfe=${chave:35:6}
export tempo=$(date "+%Y-%m-%d  %H:%M:%S")
[ -z "$nfe" ]  || if [[ "$transportadora" == *"AZUL"* ]]; then
  export rastreio=$(grep -Po '<nOCA>.*</nOCA>' $cte | tr -dc '0-9')
  echo $nfe - $rastreio >> rastreioLog
 else
  if [[ "$transportadora" == *"JADLOG"* ]]; then
   export stringRastreio=$(grep -Po '<xObs>.*</xObs>' $cte | tr -dc '0-9')
   export rastreio=${stringRastreio:0:14}
   echo $nfe - $rastreio >> rastreioLog
   else
   echo "Transportadora não reconhecida"
  fi
fi
done
