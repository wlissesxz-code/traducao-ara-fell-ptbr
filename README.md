# Ara Fell: Enhanced Edition — Tradução PT-BR

**[BAIXAR O INSTALADOR ADAPTÁVEL CORRIGIDO](https://github.com/wlissesxz-code/traducao-ara-fell-ptbr/releases/tag/v6.2.0-preview.1)**

Baixe **Ara-Fell-PTBR-6.2-adaptavel-corrigido.zip** em Assets, extraia tudo e abra **Instalar.cmd**. Selecione a pasta do jogo e clique em **Instalar tradução**. Depois, escolha **Português (Brasil)** nas opções do jogo.

Esta é uma **versão de teste**. O pacote é completo: não exige Python instalado nem acesso à internet. Requer Windows de 64 bits e cerca de 5 GB livres para preparo e backups. Os ZIPs “Source code” contêm o projeto, não o instalador completo.

## O que mudou

- Corrigido o erro **System.String não contém SetBounds** ao abrir a janela.
- Reconhece **RPG_RT.exe / RPG_RT_Data** e **Ara Fell.exe / Ara Fell_Data**.
- Adapta textos e fontes dentro dos arquivos locais, sem exigir uma correspondência exata com o arquivo inteiro da GOG.
- Preserva inglês e japonês e acrescenta português como terceira opção.
- Mantém os componentes específicos da instalação, incluindo bibliotecas da loja.
- Faz backup, confere os resultados e recupera a instalação anterior se uma substituição falhar.

A antiga distribuição **6.1.1** foi substituída por esta prévia corrigida. Antes de usar o instalador adaptável sobre uma tradução antiga, restaure os originais com o instalador daquela tradução. Se você já tem o pacote antigo, conserve-o para essa restauração.

## Compatibilidade e limites

Foi testada uma cópia da instalação **v4887393**, com **RPG_RT_Data**, fornecida pelo usuário. Foram reconhecidas **17.952 linhas**, preservados integralmente **133.475 objetos** e mantidos **8.720 corpos de métodos**. Inglês, japonês e pixels dos caracteres originais foram conferidos. A inicialização do português e das fontes passou no jogo em teste automatizado sem interface gráfica.

Instalação real, reaplicação, restauração exata, recuperação após falha e montagem da janela no Windows PowerShell foram testadas.

Essa cópia contém componentes modificados; o teste **não comprova todas as builds oficiais da Steam ou da GOG**. Ainda falta revisão visual dos diálogos nesta adaptação. Textos novos sem correspondência segura podem permanecer em inglês. Estruturas incompatíveis continuam sendo recusadas. A demo clássica em RPG Maker não é suportada.

## Restaurar

Selecione English no jogo, feche-o e clique em **Restaurar original**. Não apague os backups `.antes-ptbr-adaptavel.bak` nem o registro `.ptbr-adaptavel.json`. Saves não são modificados pelo instalador.

## Código e montagem

O código da nova distribuição está em [adaptavel/](adaptavel/). A publicação é montada pelo GitHub Actions usando dependências com versões fixadas e downloads de Python e Mono.Cecil conferidos por SHA-256. A janela e a integridade do ZIP são verificadas antes da publicação. O código e os documentos antigos permanecem como histórico do projeto e não são a distribuição atual.

Tradução comunitária não oficial. Ara Fell pertence à Stegosoft Games e aos respectivos titulares. O pacote não contém o jogo completo. As licenças das ferramentas acompanham a distribuição.
