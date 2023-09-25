# Curso intensivo de expressões regulares

Expressões regulares (ou *regex*, de *[re]gular [ex]pressions*) são expressões capazes de representar, com bastante detalhes, praticamente qualquer padrão de texto.

## Metacaracteres

Metacaracteres são caracteres que vão além de seu papel normal de símbolos gráficos em um texto. Na construção de expressões regulares, isso significa que alguns caracteres assumirão algum papel especial, que pode ser de:

- Representar a ocorrência de caracteres (representantes e classes);
- Descrever a quantidade em que esses caracteres ocorrem (quantificadores);
- Especificar com que parte do texto o padrão deve coincidir (âncoras);
- Alterar a precedência, a associação e a relação entre os padrões presentes na expressão (operadores diversos);
- Transformar metacaracteres em caracteres normais e vice-versa (escape).

A tabela abaixo mostra os metacaracteres comuns à maioria das implementações de expressões regulares:

| Metacaractere | Tipo | Descrição |
|---|---|---|
| `.` |	Representante | Qualquer caractere único. |
| `[...]` |	Representante | Um caractere na lista. |
| `[^...]` | Representante | Nenhum caractere da lista. |
| `\w` | Classe | Um caractere válido em palavras: `[A-Za-z0-9_]` |
| `\W` | Classe | Um caractere inválido em palavras: `[^A-Za-z0-9_]` |
| `\s` | Classe | Um caractere em branco. |
| `\S` | Classe | Tudo menos caracteres em branco. |
| `?` | Quantificador | A entidade anterior (caractere literal, padrão ou representante) pode ocorrer zero ou uma vez. |
| `*` | Quantificador | A entidade anterior pode ocorrer zero ou mais vezes. |
| `+` | Quantificador | A entidade anterior pode ocorrer uma ou mais vezes. |
| `{min,max}` | Quantificador | A entidade anterior pode ocorrer em qualquer quantidade entre mín e max (inclusive). |
| `^` | Âncora | Marca o começo de uma linha. |
| `$` | Âncora | Marca o fim de uma linha. |
| `\b` | Âncora | Especifica que o padrão ocorre no início ou no fim de uma palavra. |
| `\B` | Âncora | Especifica que o padrão não ocorre no início ou no fim de uma palavra. |
| `\` | Escape | Remove o significado especial de metacaracteres (ou atribui significado especial a caracteres). |
| `\|` | Operador | Expressa padrões alternativos (um ou outro). |
| `(...)` | Grupo | Agrupa, aninha e define a precedência e a associação de padrões. |
| `\1...\9` | Retrovisor | Reutiliza padrões casados em grupos anteriores conforme a ordem das ocorrências (máximo de 9). |

### Não confunda!

Os metacaracteres `?` e `*` não devem ser confundidos com aqueles que vimos na formação de padrões de nomes de arquivos. A principal diferença é que, nos globs, os metacaracteres acumulam as funções de representar e quantificar caracteres.

Para fazermos um paralelo entre as duas linguagens, observe a tabela abaixo:

|Glob | Regex | Descrição |
|---|---|---|
| `*` | `.*` | Zero ou mais caracteres quaisquer. |
| `?` | `.` | Exatamente um caractere qualquer. |
| `[...]` | `[...]` | Exatamente um caractere qualquer da lista. |
| `[!...]` | `[^...]` | Nenhum caractere da lista. |

## O metacaractere de escape

Embora seja sempre lembrado por "remover poderes especiais" de metacaracteres (uma kriptonita, como diz Aurélio Jargas), a barra invertida também faz com que alguns caracteres normais "ganhem" poderes especiais. Algumas implementações de expressões regulares também podem exigir o escape de caracteres para que eles se comportem como metacaracteres.

Observe:

```
:~$ var='2 5 10'
:~$ grep '[0-9]' <<< $var
[2] [5] [10]
```

> Nota: os trechos entre colchetes na saída são os casamentos encontrados pelo `grep` que, no terminal, apareceriam em destaque.

Se quisermos que o casamento ocorra apenas com dois dígitos numéricos seguidos, nós podemos utilizar o quantificador `{2}` (exatamente duas ocorrências da entidade anterior):

```
:~$ var='2 5 10'
:~$ grep '[0-9]{2}' <<< $var
:~$
```

Aparentemente, nenhum casamento foi encontrado, mas isso é um "falso negativo", como podemos confirmar escapando as chaves:

```
:~$ var='2 5 10'
:~$ grep '[0-9]\{2\}' <<< $var
2 5 [10]
```

Esse comportamento pode ser alterado por opções explícitas do `grep`, como a opção `-E`:

```
:~$ var='2 5 10'
:~$ grep -E '[0-9]{2}' <<< $var
2 5 [10]
```

É justamente isso que caracteriza dois dos modos de expressões regulares do grep: os modos básico (BRE) e estendido (ERE). No modo BRE, os metacaracteres `?`, `+`, `{`, `|`, `(` e `)` perdem seu significado especial, a menos que sejam escapados ou que o modo ERE seja habilitado com a opção `-E`. Aliás, o utilitário `sed` também trabalha com expressões regulares básicas e estendidas sob as mesmas condições.

## Representantes

Os metacaracteres representantes são aqueles que, como o nome diz, representam a ocorrência de um (e apenas um) caractere. Nesta categoria encontram-se:

| Metacaractere | Descrição |
|---|---|
| `.` |Qualquer caractere único. |
| `[...]` | Um caractere na lista. |
| `[^...]` | Um caractere fora da lista. |

> Nota: o `grep` sempre retorna linhas inteiras que contenham o padrão descrito na expressão regular. Para obter apenas as partes das linhas que casarem com o padrão, é preciso informar a opção `-o` (*only*). Deste modo, cada correspondência encontrada será exibida em uma linha na saída.

## O ponto

O ponto casa com exatamente um caractere qualquer:

```
:~$ var='banana bacana barata bandana'
:~$ grep -o 'ba.a.a' <<< $var
banana
bacana
barata
```

Ele também casa com espaços e o próprio ponto:

```
:~$ num='2.75 2,75 2 75'
:~$ grep -o '2.75' <<< $num
2.75
2,75
2 75
```

Quando precisarmos representar um caractere ponto textual, ele tem que ser escapado:

```
:~$ num='2.75 2,75 2 75'
:~$ grep -o '2\.75' <<< $num
2.75
```

Mas o ponto não casa com o caractere de fim de linha:

```
:~$ var=$'1234\n'
:~$ grep '....' <<< "$var"
1234
:~$ grep '.....' <<< "$var"
:~$
```

> No exemplo, nós utilizamos uma expansão de caracteres ANSI-C (`$'string'`) para que a quebra de linha (`\n`) fosse acrescentada como um quinto caractere à string atribuída a `var`.

Quando descrevemos o padrão buscado com os quatro pontos, o `grep` nos retornou uma linha contendo os 4 primeiros caracteres em `var`. Mas, quando tentamos descrever um quinto caractere qualquer no padrão, nada foi retornado: o padrão simplesmente não tem correspondência na linha recebida pelo `grep`.

## Lista

A lista só casa com um dos caracteres descritos entre os colchetes:

```
:~$ grep -o 'b.ta' <<< $'bata beta bota b\tta'
bata
beta
bota
b       ta
```

Aqui, com o ponto, o segundo caractere pode ser qualquer coisa, inclusive caracteres como a tabulação, na quarta palavra. Pode ser que isso seja desejável em algumas situações, mas é sempre bom avaliar se não podemos ser mais específicos, como no exemplo abaixo:

```
:~$ grep -o 'b[ao]ta' <<< $'bata beta bota b\tta'
bata
bota
```

Desta vez, nós deixamos claro que queremos apenas um de dois caracteres na segunda posição (`a` ou `o`), o que forma um padrão que casa com apenas duas palavras: `bata` ou `bota`.

### Sem significados especiais

Dentro dos colchetes de uma lista, todos os caracteres são textuais, menos o circunflexo (`^`), se ele for o primeiro caractere da lista: ou seja, se quisermos casar com um caractere circunflexo, ele não poderá ser o primeiro a aparecer na lista.

Por exemplo:

```
:~$ grep -o '2[.^*$]75' <<< '2.75 2^75 2*75 2$75'
2.75
2^75
2*75
2$75
```

### Casando colchetes

Os colchetes também podem entrar na lista, mas é preciso tomar cuidado com o caractere `]`. Se precisar ser casado, ele terá que ser o primeiro caractere na lista:

```
:~$ grep -o '2[].,[]75' <<< '2.75 2,75 2[75 2]75'
2.75
2,75
2[75
2]75
```

### Faixas de caracteres

Outra coisa que podemos fazer nas listas é descrever faixas de caracteres. Embora seja mais comum o uso de faixas de letras e números, é possível criar faixas com quase todos os tipos de caracteres iniciais e finais. A única limitação (e um bom motivo para não abusar das possibilidades) é que os caracteres válidos dependerão das coleções de caracteres da localidade do sistema:

```
:~$ grep -o '[9-a]' <<< '9 ; : < = > ? @ a'
9
a
:~$ LC_ALL=C grep -o '[9-a]' <<< '9 ; : < = > ? @ a'
9
;
:
<
=
>
?
@
a
```

Na tabela de caracteres da localidade `pt_BR` (padrão do meu sistema), os símbolos gráficos da string testada não estão entre `9` e `a`. Mas, alterando a localidade para `C`, a tabela ASCII é utilizada e todos os símbolos gráficos casam com o intervalo da lista.

Os intervalos mais comuns são:

- `A-Z` - letras maiúsculas
- `a-z` - letras minúsculas
- `0-9` - dígitos

Também não precisamos utilizar sempre os extremos dos intervalos. Faixas como `b-f` ou `3-8`, por exemplo, são perfeitamente válidas.

### Casando o traço

Como o traço (`-`) é utilizado para expressar faixas de caracteres, ele também exigirá um cuidado especial quando for apenas um caractere descrito na lista. Nesta situação, ele deverá ser o primeiro ou o último!

```
:~$ grep -o '[0-9-]' <<< '1 2 3 -'
1
2
3
-
```

> É mais comum vermos o traço sendo utilizado na última posição da lista, mas isso não é uma regra.

## Lista negada

A lista negada segue o mesmo conceito de uma lista normal, a diferença é que, neste caso, a leitura que se faz é *"qualquer caractere, menos o que está listado"*.

Observe:

```
:~$ grep -o '[0-9]' <<< '1 2 3 a b c'
1
2
3
:~$ grep -o '[^0-9]' <<< '1 2 3 a b c'



a

b

c
```

> Neste exemplo, observe que a lista negada também casou com os caracteres espaço.

## Quantificadores

Por padrão, cada entidade (um caractere textual, um representante ou um padrão agrupado) é tratada como uma ocorrência única e obrigatória no padrão. Para alterar isso, nós temos os metacaracteres quantificadores:

| Metacaractere | Descrição | 
|---|---|
| `?` | A entidade anterior pode ocorrer zero ou uma vez. | 
| `*` | A entidade anterior pode ocorrer zero ou mais vezes. | 
| `+` | A entidade anterior pode ocorrer uma ou mais vezes. | 
| `{min,max}` | A entidade anterior pode ocorrer em qualquer quantidade entre o min e max. | 
| `{0,max}` | A entidade anterior pode ocorrer de zero até max vezes. | 
| `{min,}` | A entidade anterior pode ocorrer pelo menos min vezes. | 
| `{qtde}` | Especifica a quantidade exata de ocorrências da entidade anterior. | 

## Âncoras

As âncoras não casam com caracteres, mas nos ajudam a especificar a posição da ocorrência de um padrão:

| Metacaractere | Descrição | 
|---|---|
| `^` | Marca o começo de uma linha. | 
| `$` | Marca o fim de uma linha. | 
| `\b` | Especifica que o padrão ocorre no início ou no fim de uma palavra. | 
| `\B` | Especifica que o padrão não ocorre no início ou no fim de uma palavra. | 

> No contexto das expressões regulares, "palavras" são sequências de caracteres formadas apenas por letras maiúsculas e minúsculas, dígitos e o caractere sublinhado: `[A-Za-z0-9_]`.

## Classes

As classes são conjuntos predefinidos de caracteres válidos ou proibidos em dada posição do padrão. As classes mais comuns são:

| Classe | Lista | Descrição | 
|---|---|---|
| `\w` | `[A-Za-z0-9_]` | Caracteres válidos em palavras | 
| `\W` | `[^A-Za-z0-9_]` | Caracteres inválidos em palavras | 
| `\s` | `[ \t\n\r\f\v]` | Espaço ou tabulação | 
| `\S` | `[^ \t\n\r\f\v]` | Tudo menos espaço ou tabulação | 

> Na literatura estrangeira, as classes de caracteres precedidas pela contrabarra também são chamadas de "operadores".

Dependendo da implementação nos programas, nós ainda podemos encontrar outras classes, como:

- `\d`: dígitos decimais
- `\x`: dígitos hexadecimais
- `\O`: dígitos octais

Contudo, por não estarem universalmente disponíveis, seu uso deve ser evitado em favor das classes conhecidas como classes POSIX.

## Classes POSIX

As classes POSIX também são conjuntos predefinidos de caracteres, mas, embora sejam representadas entre colchetes, elas não funcionam fora de listas.

Por exemplo:

```
:~$ grep '\w ' <<< 'Árvore Banana CASA'
Árvor[e] Banan[a] CASA
```

Aqui, a classe `\w` pôde ser utilizada, mas teríamos problemas em listas, porque a contrabarra perderia seu significado especial:

```
:~$ grep '\sB' <<< 'Árvore Banana CASA'
Árvore[ B]anana CASA
:~$ grep '[\s]B' <<< 'Árvore Banana CASA'
:~$
```

Com as classes POSIX, ocorre o contrário:

```
:~$ grep '[:space:]B' <<< 'Árvore Banana CASA'
grep: a sintaxe de categoria de caracteres é [[:space:]], e não [:space:]
```

Destaque especial para a mensagem de erro que pode levar a conclusões equivocadas! O que a mensagem chama de "sintaxe de categoria de caracteres" é, na verdade, a sintaxe de uma lista contendo uma classe POSIX (uma classe nomeada, no caso):

```
:~$ grep '[[:space:]]B' <<< 'Árvore Banana CASA'
Árvore[ B]anana CASA
```

Ou ainda, para deixar mais claro…

```
:~$ grep '[[:upper:]B]a' <<< 'Tamanduá Banana laranja'
[Ta]manduá [Ba]nana laranja
```

### Classes nomeadas

Quando dizemos "classes POSIX", geralmente estamos nos referindo a apenas uma das definições das normas POSIX para classes de caracteres, as chamadas classes nomeadas:

| Classe | Lista | Descrição | 
|---|---|---|
| `[:upper:]` | `[A-Z]` | Letras maiúsculas. | 
| `[:lower:]` | `[a-z]` | Letras minúsculas. | 
| `[:alpha:]` | `[A-Za-z]` | Maiúsculas/minúsculas. | 
| `[:alnum:]` | `[A-Za-z0-9]` | Letras e números. | 
| `[:word:]` | `[A-Za-z0-9_]` | Letras, números e sublinhado. | 
| `[:digit:]` | `[0-9]` | Dígitos decimais. | 
| `[:xdigit:]` | `[0-9A-Fa-f]` | Dígitos em hexadecimal. | 
| `[:blank:]` | `[ \t]` | Espaço e tabulação. | 
| `[:space:]` | `[ \t\n\r\f\v]` | Caracteres em branco. | 
| `[:graph:]` | `[^ \t\n\r\f\v]` | Caracteres imprimíveis. | 
| `[:print:]` | `[^\t\n\r\f\v]` | Imprimíveis e o espaço. | 
| `[:punct:]` | (uma lista enorme!) | Pontos e símbolos gráficos. | 

Contudo, ainda existem outras definições de classes POSIX.

### Elementos de coleção

Podem ser:

- Um caractere;
- Uma sequência de caracteres que conte como um caractere único;
- Ou um nome predefinido para uma sequência de caracteres.

Quando os elementos de uma coleção aparecem entre `[. e .]`, tudo que estiver entre os pontos será tratado como uma sequência textual do padrão entre as opções da lista. Sendo assim, uma coleção `[.ch.]`, onde `ch` é visto como apenas um caractere no idioma tcheco, por exemplo, casaria com as ocorrências do caractere `c` seguido do caractere `h` na string.

Mas, por ser altamente dependente da localização, este recurso raramente é usado para descrever padrões no nosso idioma ou na localização padrão `C`, especialmente para avaliações feitas com utilitários GNU.

### Classes de equivalência

Uma localização POSIX pode definir que alguns caracteres devem ser considerados idênticos para efeito de ordenação. Por exemplo, caracteres acentuados podem ser ignorados na ordenação de uma lista de palavras:

```
:~$ sort -d <<< $'árvore\nacento\nátomo\npeixe\nseta'
acento
peixe
árvore
seta
átomo
```

Perceba que, com a opção `-d`, o utilitário sort ignorou o caractere `á` de `árvore` e `átomo` e ordenou as linhas levando em conta os caracteres seguintes.

Numa expressão regular, porém, o caractere `a` e suas versões acentuadas podem ser representados numa lista pela *classe de equivalência* (ou *classe equivalente*) `[=a=]`:

```
:~$  grep '[[=a=]]' <<< 'árvore acento átomo peixe seta'
[á]rvore [a]cento [á]tomo peixe set[a]
```

## Operador 'ou'

O operador "ou", representado pela barra vertical (`|`), expressa padrões alternativos, ou seja, os padrões à esquerda e à direita da barra são diferentes, mas ambos são válidos para efeito de casamento:

```
:~$ str=$'bom dia\nboa tarde\nboa noite\ndia e noite'
:~$ grep -E 'bom dia|boa' <<< "$str"
[bom dia]
[boa] tarde
[boa] noite
```

Repare que o casamento foi feito com os padrões alternativos `bom dia` e `boa`, não com `dia` ou `boa`. Isso significa que o operador `|` trabalha com padrões inteiros antes e depois dele, não com partes de padrões. Se quisermos delimitar os padrões alternativos, será preciso recorrer aos agrupamentos, por exemplo:

```
:~$ str=$'bom dia\nboa tarde\nboa noite'
:~$ grep -E 'bom dia|boa (tarde|noite)' <<< "$str"
bom dia
boa tarde
boa noite
```

## Grupos

Os parêntesis `(...)` são utilizados para agrupar subpadrões. Sendo assim, no exemplo anterior, o grupo com os padrões alternativos `tarde` ou `noite` ainda são parte do padrão iniciado com `boa<espaço>`. Consequentemente, o primeiro operador `|` da expressão está lidando com os padrões alternativos `bom dia` e `boa (tarde|noite)`.

## Registros (retrovisores)

O mecanismo das expressões regulares faz um registro de todos os trechos casados em grupos e na ordem em que eles são encontrados. Então, ainda no exemplo anterior, a string casada com o padrão `(tarde|noite)` ficará registrada e poderá ser referenciada na expressão regular pelo operador numerado `\1`:

```
:~$ str=$'bom dia\nboa noite tarde\nboa noite noite'
:~$ grep -E 'boa (tarde|noite) \1' <<< "$str"
boa noite noite
```

