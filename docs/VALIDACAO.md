# Validação da versão 6.1.1

## Correção de texto cortado

O verificador anterior media a fonte Pinch, usada em menus, enquanto os diálogos usavam Softsquare Mono. Esse erro deixou passar linhas largas demais. A versão 6.1.1 usa Softsquare proporcional somente nos diálogos em português, preserva o tamanho configurado e valida as linhas com os avanços dessa fonte. Duas linhas adicionais foram encurtadas.

A frase relatada foi reproduzida numa cópia de teste e apareceu inteira dentro da caixa com a correção. O diálogo seguinte continuou normalmente, com acentos. Não foram alterados os mecanismos de paginação, animação ou escolha do jogo. Inglês e japonês mantêm suas fontes.

A tentativa experimental de quebra automática apresentou uma regressão e foi descartada; esse código não integra a versão distribuída.

## Validação anterior da versão 6.1.0

A versão 6.1.0 distribui o mesmo conteúdo traduzido da versão 6, com novo instalador portátil e patches diferenciais.

## Conteúdo

- Cobertura dos 7.902 blocos de tradução/revisão; zero blocos pendentes.
- 17.953 linhas da tabela, com português adicionado em coluna própria.
- Inglês, japonês e identificadores preservados, inclusive nas entradas duplicadas.
- 16.552 linhas de português diferentes da coluna inglesa; nomes, siglas, marcas e interjeições podem permanecer iguais.
- Revisão contextual por cenas e interlocutores; conferência de gênero, ironia, termos do mundo e missões.
- Códigos, números e variáveis verificados; ordinais adaptados foram conferidos manualmente.
- Nenhum caractere português sem glifo e nenhum alerta restante no cálculo de espaço.
- Verificação visual de menus e diálogos iniciais em uma cópia GOG. Não houve playtest da campanha inteira.

## Instalador

Testes executados com os arquivos originais em uma pasta isolada:

1. Verificação da instalação limpa.
2. Aplicação real dos dois patches; SHA-256 final idêntico ao pacote testado no jogo.
3. Reinstalação sem mudanças adicionais.
4. Restauração exata dos dois originais.
5. Bloqueio do segundo arquivo durante a substituição: o primeiro foi recuperado para a versão anterior.
6. Alteração proposital de um byte: versão desconhecida recusada sem alterar os outros arquivos.
7. Descoberta de instalação Steam em biblioteca secundária simulada, com espaços no caminho.

A build Steam não foi obtida nem testada em jogo. A descoberta de pastas Steam foi testada separadamente da compatibilidade dos arquivos. O instalador só aceita os hashes declarados em `patches/manifest.json` e não possui modo de forçar uma versão desconhecida.
