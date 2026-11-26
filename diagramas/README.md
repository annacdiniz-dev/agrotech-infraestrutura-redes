# Diagramas

| Arquivo | Conteúdo |
|---|---|
| [`fisico.drawio`](fisico.drawio) | 3 páginas: planta e cabeamento da **matriz**, planta e cabeamento da **filial**, elevação dos **racks 24U e 4U** |
| [`logico.drawio`](logico.drawio) | VLANs, sub-redes, gateways, trunks, WAN, VPN e servidores |
| `fisico.png`, `logico.png` | Exportações em imagem (geradas pela equipe, passo abaixo) |

As versões em **Mermaid** dos mesmos diagramas aparecem direto no GitHub em [`docs/02-planejamento-da-infraestrutura.md`](../docs/02-planejamento-da-infraestrutura.md).

## Abrir no draw.io

1. Acesse <https://app.diagrams.net>.
2. Se perguntar onde salvar, escolha **Dispositivo** (*Device*).
3. Menu **Arquivo → Abrir do dispositivo** (*File → Open from → Device*) e selecione `diagramas/fisico.drawio`.
4. As páginas ficam em abas na parte de baixo da tela (*Matriz*, *Filial*, *Racks*).

Os arquivos foram gerados automaticamente: confira se nenhum texto ficou sobreposto e, se precisar, arraste os elementos. As linhas de cabo são "inteligentes": ao mover uma sala ou o rack, elas se redesenham sozinhas.

## Exportar PNG

1. Com o arquivo aberto, menu **Arquivo → Exportar como → PNG** (*File → Export as → PNG*).
2. Marque **Todas as páginas** se quiser tudo numa imagem só, ou exporte uma página por vez. Zoom 100% e **Borda** 10 estão bons; deixe **Fundo transparente** desmarcado.
3. Clique em **Exportar** e salve como `diagramas/fisico.png` (e, para o outro arquivo, `diagramas/logico.png`).
4. Se salvar as páginas do físico separadas, use `fisico-matriz.png`, `fisico-filial.png` e `fisico-racks.png`.

Se fizer alterações, salve também o `.drawio` (**Arquivo → Salvar como → Dispositivo**, mesmo nome) para manter o arquivo-fonte atualizado.
