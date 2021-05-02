# :desktop_computer: Algortimo de Multiplicação 


O código em assembly **mult.asm** apresenta um algortimo de multiplicação sequencial utilizando shift e somas sucessivas e é baseado na seção *3.3 Multiplication* do livro *Computer Organization and Design* de David A. Patterson e John L. Hennessy. Todo o trabalho foi produzido por Beatriz Maia, Luana Costa e Sophie Dilhon. 


O código consiste em multiplicar dois números (multiplicando e o multiplicador) dentro do intervalo de  <img src="https://latex.codecogs.com/gif.latex?-2^{31}" /> a <img src="https://latex.codecogs.com/gif.latex?2^{31}-1" /> e armazenar o resultado em 2 registradores de 32 bits, utilizando no total 64 bits para a sua representação. O resultado final é apresentado nos registradores **$s2** e **$s3**, no qual **$s2** representa o HI (ou os 32 bits mais significativo do produto) e **$s3** representa o LO (ou os 32 bits menos significativo do produto).

Para a explicação em vídeo, [clique aqui](https://www.youtube.com/watch?v=a2nHcnN4wKo&feature=youtu.be&ab_channel=LuanaCosta) para acessar o vídeo no Youtube.

## Execução do arquivo

Para a execução do arquivo, é necessário utilizar o [MARS (MIPS Assembler and Runtime Simulator)](http://courses.missouristate.edu/kenvollmar/mars/). 

### :book: Leitura de multiplicando e multiplicador


Há duas funções (labels) para a leitura do multiplicando e do multiplicador, representadas pelos labels: *EntradaDados* e *EntradaTerminal*. No código, utilizamos a função *EntradaDados*, mas caso queira utilizar *EntradaTerminal*, basta comentar a linha 22 ("jal EntradaDados") e descomentar a linha 23 ("jal EntradaTerminal").


```assembly
jal EntradaDados
#jal EntradaTerminal
```

#### EntradaDados

O label *EntradaDados* permite a leitura de dois números em complemento à dois utilizando valores do .data. A primeira palavra lida (palavra indicada pelo label multiplicador) é armazenada no registrador **$s0** e a segunda (palavra indicada pelo label multiplicando) no registrador **$s1**. 

.data:
```assembly
.data
input: .asciiz "Digite a entrada:\n"
texto1: .asciiz "Multiplicando "
texto2: .asciiz " por "
texto3: .asciiz "\n"
multiplicador: .word 10
multiplicando: .word 10
```

Label *EntradaDados*:
```assembly
EntradaDados:
	lw $s0, multiplicador
	lw $s1, multiplicando 
```

#### EntradaTerminal

O label *EntradaTerminal* permite a leitura de dois números em complemento à dois do terminal do MARS. O primeiro valor de entrada é armazenado no registrador **$s0** e a segundo no registrador **$s1**.

### :memo: Tratamento da entrada


Antes de executar o algortimo é necessário verificar o sinal do multiplicando e do multiplicador. O algoritmo depende dos valores estarem *unsigned*. Para diminuir o tempo do programa, é também verificado qual dos números é maior, armazenando o menor em **$s0** (o multiplicador) e o maior em **$s1** (o multiplicando). Se um dos números é igual a 0, o código é finalizado (o resultado será 0). 

No código, verifica-se os sinais dos números utilizando **slt** para verificar se um número é menor que 0. Caso for, o registrador recebe 1 (representação de um número negativo), caso não for, o registrador recebe 0 (representação de um número positivo). O **$t0** é utilizado para guardar o sinal de $s0 (multiplicador) e **$t1** é utilizado para guardar o sinal de $s1 (multiplicando). 

#### SeZero 

Para verficiar se um número é 0, é utilizado o label *SeZero*. Seu parâmetro é $a0 (no label main utiliza-se com os valores de $s0 e $s1), e é comparado ao número 0. Caso seja igual a 0, o programa é finalizado com $s2 e $s3 com 0, representando o número 0. 

Exemplo de chamada do label *SeZero* no label main:
```assembly
add $a0, $s0, $0
jal SeZero
```

Label *SeZero*:
```assembly
SeZero:
	beq $a0, $0, FIM # Se o numero for igual a 0, vai para o label Zero
	jr $ra
```

#### Negativo

O label *Negativo* faz o complemento à dois de um valor informado. Na chamada da função, é necessário anteriormente armazenar o valor que deseja fazer o complemento em $a0.

```assembly
Negativo:
	xori $a0, $a0, 0xffffffff # Or entre o numero e 0xffffffff
	addiu  $a0, $a0, 1        # Soma 1
	jr $ra
```

#### Verifica

O label *Verifica* permite verificar se um número é positivo ou negativo. Seus parâmetros são $a0 e $a1, com $a0 o valor de $s0 (multiplicador) e $a1 com o sinal. 
A comparação é feita entre o valor do sinal e 0. Se os valores forem diferentes entre si, o código desvia para o label *Negativo*.
No retorno, $a0 possui o valor absoluto do valor de $a0. 

Exemplo de chamada do label *Verifica* no label main:
```assembly
add $a0, $s0, $zero  # Parametro 1: s0 (multiplicador)
add $a1, $t0, $zero  # Parametro 2: t0 (sinal de s0)
jal Verifica         # Verifica se o numero eh negativo. Se sim, deixa ele positivo (em c2)
add $s0, $a0, $zero  # Modulo de s0 eh armazenado em s0
```

Label *Verifica*:
```assembly
Verifica:
	bne $0, $a1, Negativo # Se o sinal for negativo
	jr $ra
```

### :heavy_multiplication_x: Algoritmo de Multiplicação


O algoritmo de multiplicação é acessível pelo label *Algoritmo* e é necessário informar os parâmetros $a0 (o valor do multiplicador) e $a1 (o valor do multiplicando). Para executar o algoritmo, é necessário utilizar números positivos e unsigned. Em relação ao algoritmo informado no livro de *Computer Organization and Design*, foi modificado a condição de parada. Em vez de fazer 32 iterações e depois terminar de executar o algoritmo, ele para quando o valor do multiplicador (após shifts sucessivos) for igual a 0.

- O multiplicador (representado por um registrador de 32 bits): $a0
- O multiplicando (representado por 2 registradores de 32 bits): 
  - Bits mais significativos (HI): $a2
  - Bits menos significativos (LO): $a1 

#### VerSignificativo

 O label *VerSignificativo* verifica se o bit menos significativo de $a0 é igual a 0 ou 1. Se o bit for igual a 1, é necessário somar o multiplicado ao produto (identificado pelo label *Soma*). Caso o valor seja 0, o programa sofre um desvio para o label *Shift*.

```assembly
VerSignificativo:
        andi $t2, $a0, 1
        beq $t2, $0, Shift  # Verifica se o bit menos 
```

#### Soma

O label *Soma* é responsável pela soma dos registradores HI e LO de produto e do multiplicando, e utiliza apenas números unsigned. Para tratar o bit do carry, é preciso primeiro verificar se o resultado dos bits menos significativo do produto e do multiplicando seja maior ou igual que ambos valores somados. Se o valor for menor, indica que houve overflow e é preciso adicionar um bit aos bits mais significativos do produto(HI).  

```assembly
Soma:
    addu $t4, $a1, $s3  # Soma o LO do multiplicando + LO do produto e coloca o resultado em $t4
    sltu $t5, $t4, $s3  # Verifica se a soma total eh menor que o LO do produto ($s3). Guarda 1 se sim em $t5
    sltu $t6, $t4, $a1  # Verifica se a soma total eh menor que o Lo do multiplicando ($a1). Guarda 1 se sim em $t6
	
	addu $s3, $t4, $0   # Coloca a soma anterior no LO do produto ($s3) 
	addu $s2, $s2, $a2  # Soma o HI do produto ($s2) e o HI do multiplcando ($a2)
	or $t7, $t6, $t5    # Faz um or entra $t5 e $t6. Quando a soma eh maior que os dois numeros, $t7 = 0
    beq $t7, $0, Shift  # Se $t7 = 0, vai para Shift
    addiu $s2, $s2, 1   # Se nao for = 0: Bit do carry no HI do produto (soma o HI do produto ($s2) com 1)

```

#### Shift

O label *Shift* é responsável por dar shift right no multiplicador ($a0) e shift left nos registradores do multiplicando ($a1 e $a2). Se o bit mais significativo for 0, o programa sofre um desvio para o label *VerContador*. Se o bit mais significativo de $a1 for 1, é preciso somar 1 a $a2 (identificado pelo label *HI*).

```assembly
Shift:
        srl $a0, $a0, 1     # Shift right no multiplicador
        andi $t3, $a1, 0x80000000 # and com 1000... e LO do multiplicando ($a1) 
        
        sll $a2, $a2, 1     # Shift left no multiplicando HI ($a2)
        sll $a1, $a1, 1     # Shift left no multiplicando LO ($a1)
        beq $t3, $0, VerContador # se o resultado do and eh 0, so da shift no lo
HI:
        addiu $a2, $a2, 1   # Soma 1 no Hi
```

#### VerContador

O label *VerContador* é reponsavél por decidir se o loop irá continuar, ou se o código retornará para o label *main*. É feito uma comparação entre o valor de $a0 e $0 para verificar se os valores são diferentes. Se os valores forem diferentes, é necessário continuar o loop, fazendo um desvio para o label *VerSignificativo*. 

```assembly
 VerContador:
        bne $a0, $0, VerSignificativo # Verifica se o multiplier eh igual a 0
        jr $ra
```

### :memo: Tratamento do resultado


O produto é feito utilizando valores unsigned, com os valores em $s2 (HI do produto) e $s3 (LO do produto). Para apresentar o resultado real, respeitando o sinal da multiplicação, é necessário verificar se ambos os sinais dos valores de entrada são iguais (negativo * negativo ou positivo * positivo) ou se são diferentes. Se os sinais forem iguais, o programa é finalizado. Se não forem iguais, é necessário tratar os valores de $s2 e $s3. 

```assembly
# Verifica se o resultado eh negativo
xor $t2, $t0, $t1
beq $t2, $0, FIM
```
#### Resultado

Para transformar o produto num número negativo, é necessário primeiro verificar se os bits menos significativo são todos 0 (tratamento de overflow). Se for tudo 0, o tratamento é feito pelo label *LOZero*. Se for diferente de 0, o valor de $s3 (LO) é mandado para o label *Negativo*, no qual é feito o seu complemento. O valor de $s2 (HI) é a operação xor entre o valor anterior de $s2 e o imediato 0xffffffff. O código é depois finalizado. 

```assembly
Resultado:
	beq $s3, $0, LOZero
	# LO
	add $a0, $s3, $zero  # Parametro 1: $s3 (LO do resultado)
	jal Negativo         # Transforma de positivo para negativo (c2)
	add $s3, $a0, $zero  # Numero em c2 (LO)

	# HI	
	xori $s2, $s2, 0xffffffff # Or entre o numero e 0xffffffff
	
	j FIM
```

#### LOZero

Para tratar o overflow no complemento à dois do produto, no caso em que $s3 (LO) apresenta todos os seus bits iguais a 0, precisamo inverter os bits de $s2 (HI) e depois adicionar 1 (o bit do carry). Não é necessário inverter os bits de $s2.

```assembly
LOZero:
	# HI
	add $a0, $s2, $zero  # Parametro 1: $s2 (HI do resultado)
	jal Negativo         # Transforma de positivo para negativo (c2)
	add $s2, $a0, $zero  # Numero em c2
	
	j FIM
```

### Produto


O valor do produto se encontra em dois registradores, *$s2* e *$s3*, e representado por um número de 64 bits com o bit mais significativo representando o sinal. O valor dos 32 bits menos significativos se encontram em $s3 e o valor dos 32 bits mais significativos se encontram em $s2. 
O resultado é um número inteiro entre <img src="https://latex.codecogs.com/gif.latex?-2^{63}" /> e <img src="https://latex.codecogs.com/gif.latex?2^{63}-1" />.
