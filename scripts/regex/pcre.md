# Casamentos gulosos e PCRE

As implementações de expressões regulares POSIX e GNU nos modos básico (BRE) e estendido (ERE) sempre tentarão casar o padrão com a maior sequência de caracteres possível. Esse comportamento é chamado de casamento ganancioso (greedy, em inglês) ou, como Aurélio Jargas e Julio Neves costumam dizer: "guloso".

Normalmente, isso não afeta a maior parte dos usos das expressões regulares: localizar linhas de texto inteiras que casem com o padrão, por exemplo. Contudo, quando se trata de extrair e processar apenas a parte casada, isso pode ser um pouco mais complicado, mas sempre haverá uma solução!

## Resolvendo casamentos gulosos

Nos modos ERE e BRE, se quisermos a parte da string que casa com o padrão, nós temos algumas opções...

### Solução 1: regex mais verbosa

Um opção é tentamos ser mais verbosos e específicos nas nossas expressões regulares:

```
:~$ sed -nE 's/^(blau:)((.*:){2})(.*:){3}.*/\1\2/p' /etc/passwd
blau:x:1000:
```

### Solução 2: trocar a regex por recursos de ferramentas

Também podemos abandonar a abordagem por expressões regulares para lançar mão de outros recursos capazes de processar os casamentos encontrados:

```
:~$ grep '^blau:' /etc/passwd | cut -d':' -f1-3
blau:x:1000
```

### Solução 3: usar a cabeça

Outra solução, mais engenhosa, é negar caracteres delimitadores:

```
:~$ sed -nE 's/^(blau:([^:]+:){2}).*/\1/p' /etc/passwd
blau:x:1000:
```

Ou, com o grep:

:~$ grep -Eo '^blau:([^:]+:){2}' /etc/passwd
blau:x:1000:

### Solução 4: utilizar outra especificação de regex

O sed e o grep não são os únicos utilitários que trabalham com regex na linha de comandos. Nós temos, por exemplo, o interpretador da linguagem Perl:

```
:~$ perl -ne 'print if s/^(blau:(.*?:){2}).*/\1/p' /etc/passwd
blau:x:1000:
```

Repare nesta construção:

```
.*?
```

Pelo que vimos sobre os metacaracteres, tanto `*` quanto `?` são quantificadores. Então, por que estamos utilizando dois quantificadores para a mesma entidade?

Isso é o que se chama de *quantificadores dobrados*, como veremos melhor a seguir, e é uma das especificações de expressões regulares compatíveis com o Perl (PCRE). O tipo de quantificador dobrado que utilizamos informa ao mecanismo de processamento da regex que o casamento deve ser feito com a menor quantidade de caracteres possível, anulando o casamento guloso.

## Quantificadores dobrados

Em meados dos anos 1990, a versão 5 da linguagem Perl introduziu uma série de novos operadores de expressões regulares, entre eles, os quantificadores dobrados, que visam justamente implementar a possibilidade de realizar um casamento com a mínima sequência de caracteres que corresponda ao padrão. Assim, nas especificações do Perl 5, todo quantificador seguido de `?` indicará um casamento "não-guloso":

| Modificador | Descrição | 
|---|---|
| `??` | Zero ou um "não-guloso". | 
| `*?` | Zero ou mais "não-guloso". | 
| `+?` | Um ou mais "não-guloso". | 
| `{min,max}?` | De mínimo a máximo "não-guloso". | 

Os quantificadores dobrados não estão implementados nos modos BRE e ERE, adotado por ferramentas GNU como o `awk` e o `sed`, mas o `grep` oferece um modo parcialmente implementado das especificações Perl (PCRE) com a opção `-P`. Portanto, isso é possível:

```
:~$ grep -Po '^blau:(.*?:){2}' /etc/passwd
blau:x:1000:
```

## Operadores estendidos do Perl

Ainda entre as novidades do Perl 5, nós temos uma série de operadores capazes de dotar as expressões regulares de recursos que, originalmente, ficariam para os comandos e utilitários do shell encarregados pelo pós-processamento dos resultados obtidos.

De modo geral, esses operadores estendidos se parecem muito com agrupamentos (e, de fato, eles agrupam). O principal diferencial, porém, é que o primeiro caractere do grupo será ?.

Sintaxe geral:

```
(?<IDENTIFICADOR><CONTEÚDO>)
```

Onde `IDENTIFICADOR` determina o tipo de operador e `CONTEÚDO` é o trecho da expressão regular que será afetado.

### Alguns operadores estendidos

Tendo em vista que estamos falando de expressões regulares no shell GNU, e que nem todos os recursos PCRE estão implementados, nós vamos nos limitar aos operadores estendidos mais comuns:

| Operador | Descrição | 
|---|---|
| `(?#TEXTO)` | Comentário | 
| `(?:PADRÃO)` | Grupo não capturado | 
| `(?=PADRÃO)` | Asserção positiva à frente de comprimento zero | 
| `(?!PADRÃO)` | Asserção negativa à frente de comprimento zero | 
| `(?<=PADRÃO)` | Asserção positiva anterior de comprimento zero | 
| `(?<!PADRÃO)` | Asserção negativa anterior de comprimento zero | 
| `\K` | Exclui os padrões casados anteriormente | 

### Comentários '(?#TEXTO)'

O agrupamento é ignorado e não participa do casamento:

```
:~$ str='muito quente leite quente'
:~$ grep -Po '(?# Eu sou um comentário)(leite|muito) quente' <<< $str
muito quente
leite quente
```

### Grupo não capturado '(?:PADRÃO)'

O subpadrão participa do casamento, mas não recebe um registro numerado (`\1`, `\2`, etc…).

Isso funciona:

```
:~$ grep -P '(quero)-\1' <<< 'quero-quero'
quero-quero
```

Mas isso provoca um erro:

```
:~$ grep -P '(?:quero)-\1' <<< 'quero-quero'
grep: reference to non-existent subpattern
```

### Asserção positiva à frente '(?=PADRÃO)'

Uma asserção positiva é um padrão agrupado que deve encontrar, obrigatoriamente, um casamento na string, mas não é tratada como parte do resultado: daí ser definida como de comprimento zero. No caso do operador de asserção positiva à frente (*lookahead*, "olhe adiante"), o mecanismo de avaliação da expressão regular verifica se o padrão agrupado adiante possui correspondência para considerar se haverá ou não um casamento com a string:

```
:~$ str=$'salada mista\nsalada de frutas'
:~$ grep -P 'salada(?= mista)' <<< $str
[salada] mista
:~$ grep -Po 'salada(?= mista)' <<< "$str"
salada
```

Isso é útil em situações onde queremos obter apenas a parte casada no começo da linha.

> Importante: os operadores de comprimento zero não registram grupos!

### Asserção negativa à frente '(?!PADRÃO)'

Ao contrário da asserção positiva, uma asserção negativa determina um padrão que não pode ser casado:

```
:~$ str=$'salada mista\nsalada de frutas'
:~$ grep -P 'salada(?! mista)' <<< "$str"
[salada] de frutas
```

### Asserção positiva anterior '(?<=PADRÃO)'

Funciona como a asserção positiva à frente, mas condicionando os padrões seguintes ao casamento do padrão agrupado anteriormente (*lookbehind*, "olhe para trás"):

```
:~$ str=$'muito quente\nleite quente'
:~$ grep -P '(?<=leite )quente' <<< "$str"
leite [quente]
```

### Asserção negativa anterior '(?<!PADRÃO)'

Condiciona os padrões seguintes ao não casamento do padrão agrupado anteriormente:

```
:~$ str=$'muito quente\nleite quente'
:~$ grep -P '(?<!leite )quente' <<< "$str"
muito [quente]
```

### O operador '\K'

Introduzido na PCRE7.2, o operador `\K` também estabelece uma asserção positiva anterior (*lookbehind*), mas não está limitada a um padrão agrupado: ou seja, todos os padrões que vierem antes dele participarão do mecanismo de casamento, mas serão descartados no resultado da avaliação da expressão regular.

Por exemplo, se quiséssemos apenas o último campo da linha de /etc/passwd iniciada por `blau`, seria um problema descartar toda a parte anterior do casamento usando apenas o `grep`:

```
:~$ grep -Po '^blau.*:/bin/bash' /etc/passwd
blau:x:1000:1000:Blau Araujo,,,:/home/blau:/bin/bash
```

Com o operador `\K`, porém, nós temos uma solução bem mais simples:

```
:~$ grep -Po '^blau.*:\K/bin/bash' /etc/passwd
/bin/bash
```


