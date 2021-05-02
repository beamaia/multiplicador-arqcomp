# Algoritmo de Multiplicação utilizando shift e soma
# Grupo: Beatriz Maia, Luana Costa e Sophie Dilhon
# Nov/2020
#-------------------------------------------------------------------------------
.data
input: .asciiz "Digite a entrada:\n"
texto1: .asciiz "Multiplicando "
texto2: .asciiz " por "
texto3: .asciiz "\n"
multiplicador: .word 10
multiplicando: .word 10
.text

# Vamos utilizar os seguintes registradores:
# $s0 = multiplicador
# $s1 = multiplicando
# $s2 = HI
# $s3 = LO

#-------------------------------------------------------------------------------
Main:
	jal EntradaDados
	#jal EntradaTerminal

	# Mult para verificar se o valor de HI e LO eh igual a $s2 e $s3, respectivamente	
	mult $s1, $s0
	
	# Verifica se um dos numeros eh igual a 0
	add $a0, $s0, $0
	jal SeZero
	add $a0, $s1, $0
	jal SeZero

	# Coloca em $s0 o menor numero e em $s1 o maior numero
	slt $t0, $s1, $s0
	beq $t0, $0, continua
	add $t1, $s0, $0
	add $s0, $s1, $0
	add $s1, $t1, $0
	
	continua: 
	
	# Verifica sinal de s0 e s1
	slt $t0, $s0, $0  # sinal de s0
	slt $t1, $s1, $0  # sinal de s1

	# Verifica se s0 eh negativo
	add $a0, $s0, $zero  # Parametro 1: s0 (multiplicador)
	add $a1, $t0, $zero  # Parametro 2: t0 (sinal de s0)
	jal Verifica         # Verifica se o numero eh negativo. Se sim, deixa ele positivo (em c2)
	add $s0, $a0, $zero  # Modulo de s0 eh armazenado em s0

	# Verifica se s1 eh negativo
	add $a0, $s1, $zero  # Parametro 1: s1 (multiplicando)
	add $a1, $t1, $zero  # Parametro 2: t1 (sinal de s1)
	jal Verifica         # Verifica se o numero eh negativo. Se sim, deixa ele positivo (em c2)
	add $s1, $a0, $zero  # Modulo de s1 eh armazenado em s1
	
	add $a0, $s0, $zero  # Parametro 1: s0 (multiplicador)
	add $a1, $s1, $zero  # Parametro 2: s1 (multiplicando)
	jal Algoritmo

	# Verifica se o resultado eh negativo
	xor $t2, $t0, $t1
	beq $t2, $0, FIM
	
	# Se negativo, fazer o complemento a 2
	jal Resultado


# --------------------------------------------------------------------------
# Verificando se algum dos inputs eh zero
SeZero:
	beq $a0, $0, FIM # Se o numero for igual a 0, vai para o label Zero
	jr $ra


# Verificando se algum dos inputs eh < 0
Verifica:
	bne $0, $a1, Negativo # Se o sinal for negativo
	jr $ra

# Para fazer complemento a 2
Negativo:
	xori $a0, $a0, 0xffffffff # Or entre o numero e 0xffffffff
	addiu  $a0, $a0, 1          # Soma 1
	jr $ra

# Algoritmo de multiplicacao utilizando shift e soma
Algoritmo:
    VerSignificativo:
        andi $t2, $a0, 1
        beq $t2, $0, Shift  # Verifica se o bit menos significativo eh 0
    Soma:
    	addu $t4, $a1, $s3  # Soma o LO do multiplicando + LO do produto e coloca o resultado em $t4
    	sltu $t5, $t4, $s3  # Verifica se a soma total eh menor que o LO do produto ($s3). Guarda 1 se sim em $t5
    	sltu $t6, $t4, $a1  # Verifica se a soma total eh menor que o Lo do multiplicando ($a1). Guarda 1 se sim em $t6
	
	addu $s3, $t4, $0   # Coloca a soma anterior no LO do produto ($s3) 
	addu $s2, $s2, $a2  # Soma o HI do produto ($s2) e o HI do multiplcando ($a2)
	or $t7, $t6, $t5    # Faz um or entra $t5 e $t6. Quando a soma eh maior que os dois numeros, $t7 = 0
    	beq $t7, $0, Shift  # Se $t7 = 0, vai para Shift
    	addiu $s2, $s2, 1   # Se nao for = 0: Bit do carry no HI do produto (soma o HI do produto ($s2) com 1)
    Shift:
        srl $a0, $a0, 1     # Shift right no multiplicador
        andi $t3, $a1, 0x80000000 # and com 1000... e LO do multiplicando ($a1) 
        
        sll $a2, $a2, 1     # Shift left no multiplicando HI ($a2)
        sll $a1, $a1, 1     # Shift left no multiplicando LO ($a1)
        beq $t3, $0, VerContador # se o resultado do and eh 0, so da shift no lo
    HI:
        addiu $a2, $a2, 1   # Soma 1 no Hi
        
    VerContador:
        bne $a0, $0, VerSignificativo # Verifica se o multiplier eh igual a 0
        jr $ra

# Transformacao do resultado para negativo
Resultado:
	beq $s3, $0, LOZero
	# LO
	add $a0, $s3, $zero  # Parametro 1: $s3 (LO do resultado)
	jal Negativo         # Transforma de positivo para negativo (c2)
	add $s3, $a0, $zero  # Numero em c2 (LO)

	# HI	
	xori $s2, $s2, 0xffffffff # Or entre o numero e 0xffffffff
	
	j FIM

# Caso o registrador dos bits menos significativos forem todos o	
LOZero:
	# HI
	add $a0, $s2, $zero  # Parametro 1: $s2 (HI do resultado)
	jal Negativo         # Transforma de positivo para negativo (c2)
	add $s2, $a0, $zero  # Numero em c2
	
	j FIM

# Fim do programa	
FIM:
    addi $v0, $0, 10
    syscall

# Leitura de dados pelo .data
EntradaDados:
	lw $s0, multiplicador
	lw $s1, multiplicando 

# Leitura de dados pelo terminal	
EntradaTerminal:
	# Carregando strings
	la $t0, input
	la $t1, texto1
	la $t2, texto2
	la $t3, texto3

	# Criando a entrada 
	addi $v0, $0, 4
	add $a0, $t0, $0
	syscall 
	addi $v0, $0, 5
	syscall 
	add $s1, $v0, $0
	addi $v0, $0, 5
	syscall 
	add $s0, $v0, $0

	# Mostrando a entrada
	addi $v0, $0, 4
	add $a0, $t1, $0
	syscall 
	addi $v0, $0, 1
	add $a0, $s1, $0
	syscall 
	addi $v0, $0, 4
	add $a0, $t2, $0
	syscall 
	addi $v0, $0, 1
	add $a0, $s0, $0
	syscall 
	addi $v0, $0, 4
	add $a0, $t3, $0
	syscall 
	jr $ra
 
