# Estrutura e manutenção

`Instalar.ps1` apresenta a janela; `lib/Installer.Core.ps1` detecta pastas, verifica o pacote e aplica/restaura. `patches/manifest.json` fixa os hashes de entrada, saída e ferramentas. `traducao/partes/` contém somente a coluna portuguesa, indexada pelas chaves do jogo.

O pacote altera `Ara Fell_Data/data.unity3d` e `Ara Fell_Data/Managed/Assembly-CSharp.dll`. O segundo arquivo adiciona português ao seletor e ao mapeamento de fontes. O pacote de dados contém a tradução e as fontes com acentos. Os arquivos finais do jogo não são incluídos neste repositório.

## Recriar os diferenciais

É necessário ter os dois arquivos originais homologados, os dois arquivos traduzidos correspondentes e o Xdelta 3.2.2 oficial. Execute `tools/Build-Patches.ps1` com as pastas de dados de entrada e saída. O script recusa arquivos cujo hash não corresponda ao manifesto. Ele não extrai nem baixa arquivos do jogo.

O catálogo português serve para revisão editorial. Alterá-lo sozinho não modifica os patches de uma release; é preciso integrar a correção ao pacote Unity, reconstruir a DLL se necessário, revisar os hashes e gerar uma nova versão.

## Testar

`tests/Integration.ps1` recebe caminhos explícitos para arquivos originais, o pacote completo e uma pasta de teste nova. Os testes usam cópias locais e não incluem dados do jogo no Git. Eles cobrem aplicação, restauração, idempotência, rollback, recusa de hashes desconhecidos e descoberta Steam.

A descoberta Steam lê as bibliotecas e o manifesto do app 440540. A descoberta GOG usa os registros de instalação; pastas personalizadas podem ser selecionadas na interface. Nenhuma rotina modifica o registro, jogos salvos ou configurações de segurança do Windows.

## Releases

Distribua um ZIP com `Instalar.cmd`, `Instalar.ps1`, `lib/`, `bin/xdelta3.exe`, `patches/`, `README.md`, `LEIA-ME.txt` e os avisos de licença em `docs/`. Mantenha os `.vcdiff` e executáveis fora do histórico Git. Publique também `SHA256SUMS.txt` para o ZIP.
