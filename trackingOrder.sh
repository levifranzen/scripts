#!/bin/bash
find /mnt/rastreio/recebidos/ -cmin -1440 -name '*09296295001646*.xml' -exec cp {} /mnt/rastreio/xml/ \;
find /mnt/rastreio/recebidos/ -cmin -1440 -name '*04884082000305*.xml' -exec cp {} /mnt/rastreio/xml/ \;
cd /mnt/rastreio/xml
for cte in *.xml
do
export token="slithz0c24b5g53bg"
export transportadora=($(grep -oP '(?<=CNPJ>)[^<]+' "$cte"))
export chave=($(grep -oP '(?<=chave>)[^<]+' "$cte"))
export nfe=${chave:28:6}
export tempo=$(date "+%Y-%m-%d  %H:%M:%S")
export stringPedido=($(grep -oP '(?<=xPed>)[^<]+' "/mnt/rastreio/nf/$chave-nfe.xml"))
export pedido=${stringPedido:0:10}
if [ -z "$pedido" ]; then
   echo "ERR $tempo cte:$cte nota:$nfe pedido:$pedido rastreio:$rastreio status:PEDIDO VAZIO" >> trackingOrder.log
  else
   sleep 3 && export dados=$(curl -k -X GET -H "Content-type: application/json" "https://grupofw.api.flexy.com.br/platform/api/orders/?numbers=${pedido}&token=${token}&limit=100&offset=0")
   export status=$(echo $dados | jq -r '.[0].status.name')
    if [[ "$status" != "status.billed" ]]; then
      echo "ERR $tempo cte:$cte nota:$nfe pedido:$pedido rastreio:$rastreio status:$status" >> trackingOrder.log
    elif [[ "$transportadora" == *"09296295001646"* ]]; then ### Rotina da Azul
      export rastreio=$(grep -Po '<nOCA>.*</nOCA>' $cte | tr -dc '0-9')
      sleep 3 && curl -k -X PUT -H "Content-type: application/json" -d '[{ "number": '"$pedido"',  "trackingCode": '"$rastreio"' }]' "https://grupofw.api.flexy.com.br/platform/api/orders/tracking-code/?token=${token}"
      echo "ENV $tempo cte:$cte nota:$nfe pedido:$pedido rastreio:$rastreio status:$status" >> trackingOrder.log
    elif [[ "$transportadora" == *"04884082000305"* ]]; then ### Rotina da Jadlog
      export stringRastreio=$(grep -Po 'NUMERO OPERACIONAL:.*]' $cte | tr -dc '0-9')
      export rastreio=${stringRastreio:0:14}
      sleep 3 && curl -k -X PUT -H "Content-type: application/json" -d '[{ "number": '"$pedido"',  "trackingCode": '"$rastreio"' }]' "https://grupofw.api.flexy.com.br/platform/api/orders/tracking-code/?token=${token}"
      echo "ENV $tempo cte:$cte nota:$nfe pedido:$pedido rastreio:$rastreio status:$status" >> trackingOrder.log
    else
      echo "ERR $tempo cte:$cte nota:$nfe pedido:$pedido rastreio:$rastreio status:$status"  >> trackingOrder.log
   fi
fi
mv $cte importados/
done
echo " "
echo "Finalizando script..." && sleep 10 && echo "..."
