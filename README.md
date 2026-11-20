# Ara Fell: Enhanced Edition — Tradução PT-BR

Tradução comunitária completa para português do Brasil, com português como **terceira opção de idioma**, preservando inglês e japonês. Inclui história até o final, missões, menus, itens, equipamentos, habilidades e tutoriais. Fonte pixelada com acentos e correções de legibilidade.

**[BAIXAR O INSTALADOR REVISADO — Steam e GOG](https://github.com/wlissesxz-code/traducao-ara-fell-ptbr/archive/refs/heads/main.zip)**

Extraia o ZIP acima e abra **Instalar.cmd**. Na primeira execução, ele baixa automaticamente os componentes da tradução 6.1.1 (aproximadamente 145 MB) e verifica sua integridade. É necessário acesso à internet nessa etapa. O pacote antigo da release 6.1.1 não contém esta correção de identificação da Steam.

## Instalação

1. Feche o Ara Fell e extraia o ZIP inteiro em uma pasta.
2. Abra **Instalar.cmd**.
3. Selecione a pasta do jogo: **Ara Fell.exe / Ara Fell_Data** na GOG ou **RPG_RT.exe / RPG_RT_Data** na Steam. O instalador procura instalações da Steam e da GOG; use **Procurar...** se a sua não aparecer.
4. Clique em **Verificar** e depois em **Instalar tradução**.
5. Abra o jogo e selecione **Português (Brasil)** nas opções de idioma.

Não é necessário instalar Python nem baixar ferramentas à parte. O instalador usa o Windows PowerShell que acompanha o Windows. O patch é aplicado localmente, sem enviar arquivos ou informações da sua instalação.

## Correção do instalador para Steam — 20/11/2026

Reconhece os nomes da Enhanced Edition na Steam sem renomear arquivos, bloqueia a instalação enquanto RPG_RT.exe estiver aberto e baixa os componentes ausentes automaticamente. A presença de Legacy.exe não impede a identificação. Mantém as verificações e os backups da versão anterior. Testes de estrutura simulada passaram; a build Steam continua sem teste independente em jogo.

## Compatibilidade

| Edição | Situação |
| --- | --- |
| Enhanced Edition, Windows, GOG | Build de referência testada em jogo e no instalador |
| Enhanced Edition, Windows, Steam | Instalador encontra bibliotecas Steam, inclusive secundárias. Aplica somente se os arquivos passarem na verificação de compatibilidade. Ainda sem teste independente da build Steam |
| Traduções anteriores deste projeto, versões 4 e 5 | Atualização aceita quando a cópia de segurança original está íntegra |
| Versão clássica em RPG Maker, Linux/macOS e consoles | Fora do escopo deste pacote |

**A loja e o nome da pasta não bastam para provar compatibilidade.** O instalador compara os arquivos com as versões reconhecidas antes de escrever. A verificação é automática: não é necessário calcular ou enviar códigos ou arquivos. Se a sua build Steam ou GOG for diferente das suportadas, ele recusa a instalação sem modificar o jogo. A correção de identificação não acrescenta suporte a binários de builds desconhecidas.

## Restaurar o original

Primeiro selecione **English** no jogo e feche-o. Abra o instalador, escolha a mesma pasta e clique em **Restaurar original**. A versão original não reconhece o idioma adicional de português.

As cópias originais ficam ao lado dos arquivos alterados, com o sufixo `.original-antes-ptbr.bak`. Elas são verificadas e preservadas. Seus jogos salvos não são modificados. Atualizações do jogo ou a verificação de integridade da loja podem remover o patch; confira novamente a compatibilidade antes de reaplicá-lo.

## Revisão e testes

Foram traduzidos ou revisados contextualmente **7.902 blocos**, com conferência das cenas, interlocutores, gênero, termos recorrentes e objetivos de missões. Códigos de cor, pausas, variáveis e números foram conferidos, assim como o espaço estimado das linhas e os caracteres disponíveis nas fontes.

A verificação visual incluiu menus e diálogos iniciais. A campanha inteira não foi jogada de ponta a ponta. Consulte [o relatório de validação](docs/VALIDACAO.md).

O instalador prepara e verifica os dois arquivos antes de substituir qualquer um deles. Guarda os originais e recupera a instalação anterior se uma substituição falhar. O download contém patches diferenciais; exige os arquivos locais de uma cópia do jogo.

## Problemas e contribuições

Para erros de texto, informe o personagem, local e frase, de preferência com uma captura. Para instalação, informe Windows, loja e a mensagem exibida. Evite publicar caminhos com seu nome de usuário ou dados pessoais.

O catálogo em [`traducao/partes/`](traducao/partes/) permite consultar e propor correções. Os patches binários e a ferramenta de aplicação ficam nas releases, não no histórico Git. Veja [os detalhes técnicos](docs/DESENVOLVIMENTO.md).

Tradução não oficial. Ara Fell pertence à Stegosoft Games e aos respectivos titulares. O código do instalador tem licença MIT; a ferramenta Xdelta usa Apache 2.0, com os avisos em `docs/`. A licença do instalador não concede direitos sobre o jogo ou seus textos.
