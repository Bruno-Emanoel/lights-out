.nolist
.include "m328Pdef.inc"
.list

.def aux_timer = R15
.def aux = R16
.def screen_up = R17
.def screen_down = R18
.def count = R19
.def aux_bit = R22
.def bit_copy = R23
.def row_pointer = R24
.def Botao_keep = R25
.equ Botoes_col = PINB
.equ Botoes_lin = PORTC

.ORG 0x00
  RJMP INICIO 
.org PCI0addr
  RJMP BOTAO_APERTADO


; Devemos inicializar o programa com as devidas configurações de porta
; Serão usados todos os pinos da porta D como saída (para o display)
; Será usados PB0~PB3 e PC0~PC3 para os botões, de maneira que:
; PCs serão usados para alimentação
; PBs serão usados para leitura em pull-down, ativando interrupção quando pressionados
INICIO:
  ; Usaremos PD0 ~ PD7 como saída
  ldi   aux, 0xff
  out   DDRD, aux
  ; Usaremos PB0 ~ PB3 como entrada
  ldi   aux, 0b0000
  out   DDRB, aux
  ; Pull-up habilitado Para os pins de B configurados
  ldi   aux, 0b1111
  out   PORTB, aux

  ; Usaremos PC0 ~ PC3 como saída
  
  out   DDRC, aux
  ldi   aux, 0 
  out   PORTC, aux ; coloca as linhas em LOW
  ldi   aux, 0b1111 ; 

  ; Define PB0 ~ PB3 como ativadores de interrupção
  sts   PCMSK0, aux
 
  ; Habilitando PCI para o portB (PCIE0)
  ldi   aux, (1<<PCIE0)
  sts   PCICR, aux
  
  ; Como será utilizada uma matriz de led como se fosse 4X4, precisaremos de 16 bits no total.
  ; Ou seja, 2 registradores que serão chamados de screen_up e screen_down, que portarão a parte superior e inferior da tela, respectivamente.
  ; Os 4 bits menos significativos de cada um representam sua linha superior, enquanto os 4 mais significativos representam a linha inferior. 

  ; Inicializar os Timers
  ldi aux, (1<<CS01) | (1<<CS00)   ; Timer0 com prescaler 64
  out TCCR0B, aux

  ldi aux, (1<<CS11) | (1<<CS10)   ; Timer1 com prescaler 64
  sts TCCR1B, aux

  ; Aguardar botão ser pressionado
  Aguardar_Botao:
    in aux, Botoes_col       
    andi aux, 0b1111  
    cpi aux, 0    
    breq Aguardar_Botao

  rcall Gerar_Padrao_Possivel

  ; Ligando o flag de interrupção
  sei
  rjmp  Main


; Gera um padrão sempre resolvível usando os valores dos timers
; Modifica screen_up e screen_down diretamente
Gerar_Padrao_Possivel:
  clr screen_up
  clr screen_down

  ; Toque aleatório 1
  in aux, TCNT0         ; valor aleatório (0 a 255)
  andi aux, 0x0F        ; limita de 0 a 15
  mov count, aux
  rcall SimularToque

  ; Toque aleatório 2
  lds aux, TCNT1L
  andi aux, 0x0F
  mov count, aux
  rcall SimularToque

  ; Toque aleatório 3
  in aux, TCNT0
  lds aux_timer, TCNT1L
  add aux, aux_timer       ; soma dois valores "randômicos"
  andi aux, 0x0F
  mov count, aux
  rcall SimularToque

  ; Toque aleatório 4
  in aux, TCNT0
  lds aux_timer, TCNT1L
  eor aux, aux_timer       ; mistura os bits com XOR
  andi aux, 0x0F
  mov count, aux
  rcall SimularToque

  ; Toque aleatório 5
  lds aux, TCNT1L
  com aux               ; inverte os bits
  andi aux, 0x0F
  mov count, aux
  rcall SimularToque

  ret

; Sub-rotina que simula apertar um botão com índice em 'count'
SimularToque:
  mov R26, count        ; compatível com Acender_Up/Down
  cpi count, 8
  brge Simular_Down
  rcall Acender_Up
  ret

Simular_Down:
  subi count, 8
  rcall Acender_Down
  ret


; Função de tratamento de interrupção
; Assim que um botão for apertado, receberemos uma interrupção em PORTB
; A lógica consiste em conseguir o índice do botão apertado, da direita para esquerda de cima para baixo; (0-indexado)
; Para isso, faremos scanning nos botões, mudando os valores em PORTC
BOTAO_APERTADO:
  ; Devemos guarda o valor anteriormente em SREG para não afetar a execução do programa
  push  aux
  in    aux, SREG
  push  aux

  ; Guardaremos o valor lido por PORTB, ou seja, a coluna que foi pressionada
  in    Botao_keep, Botoes_col
  com   Botao_keep              ; Inverte pois estamos usando pull-up (0 = pressionado)
  andi  Botao_keep, 0b1111      ; Remove bits não importantes para a leitura (4 mais significativos)
  cpi   Botao_keep, 0           ; Se não foi identificado nenhum botão apertado, retornamos
  breq  BOTAO_APERTADO_Retorno
  clr   aux
  out   Botoes_lin, aux         ; Temos que cessar a alimentação dos botões para checar a linha pressionada
  clr   count                   ; Usaremos count para indexar o botão apertado, contando da direita para esquerda, de cima pra baixo
  ldi   row_pointer, 1          ; Máscara de bits para checar a linha
  com   row_pointer
  BOTAO_APERTADO_Linha:
  out   Botoes_lin, row_pointer ; Colocamos a máscara na Saída C, para testar para uma linha específica
  ; Tempo de debounce
  rcall Atraso_Pequeno          ; Debounce
  in    aux, Botoes_col         ; Pegamos novamente o valor de entrada.
  com   aux                     ; Inverte pois estamos usando pull-up
  andi  aux, 0b1111
  cp    aux, Botao_keep         ; Se ele permanece igual, achamos a linha
  breq  BOTAO_APERTADO_Coluna
  BOTAO_APERTADO_Linha_Prox:    ; Se não, checamos a próxima
  subi  count, -4               ; count += 4 (pula linha)
  cpi   count, 16
  brge  BOTAO_APERTADO_Retorno  ; Checa se não passou do índice limite
  com row_pointer
  lsl   row_pointer             ; row_pointer<<1 (muda a máscara para o próximo bit)
  com   row_pointer
  rjmp  BOTAO_APERTADO_Linha

  BOTAO_APERTADO_Coluna:
  lsr   Botao_keep              ; Enquanto não chegarmos no bit de coluna que foi acendido
  cpi   Botao_keep, 0           ; Se Botao_keep===0, chegamos no índice desejado
  breq  BOTAO_APERTADO_Coluna_End
  inc   count                   ; count++
  cpi   count, 16
  brge  BOTAO_APERTADO_Retorno
  rjmp  BOTAO_APERTADO_Coluna

  BOTAO_APERTADO_Coluna_End:
  cpi   count, 16
  brge  BOTAO_APERTADO_Retorno

  BOTAO_APERTADO_Acender:
  mov   R26, count
  cpi   count, 8              ; Devemos checar se a mudança será feita em screen_up ou screen_down primariamente
  brge  BOTAO_APERTADO_Down
  rcall Acender_Up            ; Mudança será feita em screen_up
  rjmp  BOTAO_APERTADO_Retorno; Fim
  BOTAO_APERTADO_Down:
  subi  count, 8              ; Mudamos o índice relativo
  rcall Acender_Down          ; Mudança será feita em screen_down
  BOTAO_APERTADO_Retorno:
  pop   aux
  out   SREG, aux
  ldi   aux, 0
  out   Botoes_lin, aux
  pop   aux
  RETI


; Essa função considera que o valor de count contém o índice do botão apertado
; Considere a grid indexada da direita para esquerda, de cima para baixo
Acender_Up:
  clr   aux
  clr   aux_bit
  inc   aux_bit

  Acender_Up_Centro:
  ; Quando um botão é apertado, nós vamos sempre ascender/apagar ele
  ; Pra isso, fazemos aux_bit=1<<count para usarmos o aux_bit como máscara
  cp    aux, count
  breq  Acender_Up_Cima
  inc   aux
  lsl   aux_bit
  rjmp  Acender_Up_Centro
  Acender_Up_Cima:
  eor   screen_up, aux_bit  ; Aplicamos a máscara com o xor, mudando o estado do bit referente ao botão apertado

  ; Comparamos agora o valor de count com 4, 
  ; Se for maior ou igual, faremos aux_bit>>=4 para mudar a máscara para a linha acima
  ; se for menor, não existe luz acima e partimos para a direita
  cpi   aux, 4
  brlt  Acender_Up_Direita
  mov   bit_copy, aux_bit
  lsr   bit_copy  
  lsr   bit_copy  
  lsr   bit_copy  
  lsr   bit_copy
  eor   screen_up, bit_copy  ; Aplicação da máscara

  Acender_Up_Direita:
  ; Aqui precisamos checar se count é múltiplo de 4 
  ; usamos o fato de que se isso for verdade, então os 2 bits menos significativos serão 0
  andi  aux, 0b11
  cpi   aux, 0
  breq  Acender_Up_Baixo
  mov   bit_copy, aux_bit
  lsr   bit_copy
  eor   screen_up, bit_copy

  Acender_Up_Baixo:
  ; Precisamos checar se o valor modificado será em scree_up ou screen_down
  ; Para isso comparamos se o valor é maior ou igual a 4
  ; A única diferença está na direção dos bit shiftings e em qual registrador será aplciado a máscara
  mov   aux, count
  cpi   aux, 0b100
  brge  Acender_Up_Baixo_Down
  mov   bit_copy, aux_bit
  lsl   bit_copy
  lsl   bit_copy
  lsl   bit_copy
  lsl   bit_copy
  eor   screen_up, bit_copy
  rjmp  Acender_Up_Esquerda
  Acender_Up_Baixo_Down:
  mov   bit_copy, aux_bit
  lsr   bit_copy  
  lsr   bit_copy  
  lsr   bit_copy  
  lsr   bit_copy
  eor   screen_down, bit_copy 

  Acender_Up_Esquerda:
  ; Aqui precisamos checar se count é múltiplo de 4  -1
  ; usamos o fato de que se isso for verdade, então os 2 bits menos significativos serão 1
  andi  aux, 0b11
  cpi   aux, 0b11
  breq  Acender_Up_Fim
  lsl   aux_bit
  eor   screen_up, aux_bit

  Acender_Up_Fim:
  ret

; Essa função considera que o valor de count contém o índice do botão apertado
; Considere a grid indexada da direita para esquerda, de cima para baixo
Acender_Down:
  clr   aux
  clr   aux_bit
  inc   aux_bit
  
  Acender_Down_Centro:
  ; Quando um botão é apertado, nós vamos sempre ascender/apagar ele
  ; Pra isso, fazemos aux_bit=1<<count para usarmos o aux_bit como máscara
  cp    aux, count
  breq  Acender_Down_Cima
  inc   aux
  lsl   aux_bit
  rjmp  Acender_Down_Centro
  Acender_Down_Cima:
  eor   screen_down, aux_bit ; Aplicamos a máscara com o xor, mudando o estado do bit referente ao botão apertado

  ; Comparamos agora o valor de count com 4, 
  ; Se for menor, faremos aux_bit>>=4 para mudar a máscara para a linha acima
  ; se for maior ou igual, a mudança será feita em screen_up
  cpi   aux, 4
  brlt  Acender_Down_Cima_Up
  mov   bit_copy, aux_bit
  lsr   bit_copy  
  lsr   bit_copy  
  lsr   bit_copy  
  lsr   bit_copy
  eor   screen_down, bit_copy  
  rjmp  Acender_Down_Direita
  Acender_Down_Cima_Up:
  mov   bit_copy, aux_bit
  lsl   bit_copy  
  lsl   bit_copy  
  lsl   bit_copy  
  lsl   bit_copy
  eor   screen_up, bit_copy

  Acender_Down_Direita:
  ; Aqui precisamos checar se count é múltiplo de 4 
  ; usamos o fato de que se isso for verdade, então os 2 bits menos significativos serão 0
  andi  aux, 0b11
  cpi   aux, 0
  breq  Acender_Down_Baixo
  mov   bit_copy, aux_bit
  lsr   bit_copy
  eor   screen_down, bit_copy

  Acender_Down_Baixo:
  ; Precisamos checar se o valor modificado será em scree_up ou screen_down
  ; Para isso comparamos se o valor é maior ou igual a 4
  ; Se for verdade, então não haverá luz embaixo
  ; Caso contrário, faremos bit_copy<<=4 e aplicamos a máscara
  mov   aux, count
  cpi   aux, 4
  brge  Acender_Down_Esquerda
  mov   bit_copy, aux_bit
  lsl   bit_copy
  lsl   bit_copy
  lsl   bit_copy
  lsl   bit_copy
  eor   screen_down, bit_copy

  Acender_Down_Esquerda:
  ; Aqui precisamos checar se count é múltiplo de 4  -1
  ; usamos o fato de que se isso for verdade, então os 2 bits menos significativos serão 1
  andi  aux, 0b11
  cpi   aux, 0b11
  breq  Acender_Down_Fim
  lsl   aux_bit
  eor   screen_down, aux_bit

  Acender_Down_Fim:
  ret


Main:
  ; Desenha na matriz LED
  ; Verifica se o jogo está finalizado
  rcall Desenhar
  cp screen_up, screen_down
  brne Main
  cpi screen_up, 0x00
  brne Main
  sei
  rjmp Finalizar


;Método que olhará os valores em screne_up e screen_down e os desenhará na matriz de led
Desenhar:
  ; Pegar a primeira linha, 4 bits menos significativos de screen_up
  ; Para isso, colocamos esses 4 bits nas suas devidas posições em aux, as 4 mais significativas. Para isso, utilizamos swap para trocar estes bits
  mov   aux, screen_up
  lsl   aux
  lsl   aux
  lsl   aux
  lsl   aux
  ; Precisamos negar o valor, pois os valores colocados em cada coluna acendem apenas se forem zero.
  com   aux
  ; Precisamos deixar acesos apenas os bits acesos anteriormente da parte mais significativa, e o bit de linha adequado (primeiro)
  andi  aux, 0b11110001
  out   PORTD, aux
  rcall Atraso_Pequeno

  ; Pegar a segunda linha, 4 bits mais significativos de screen_up
  ; Para isso, apenas pegamos o valor de screen_up, não é necessário fazer bit shifting pois os quatro bits já estão na posição adequada
  mov   aux, screen_up
  ; Precisamos negar o valor, pois os valores colocados em cada coluna acendem apenas se forem zero.
  andi  aux, 0b11110000
  com   aux
  ; Precisamos deixar acesos apenas os bits acesos anteriormente da parte mais significativa, e o bit de linha adequado (segundo)
  andi  aux, 0b11110010
  out   PORTD, aux
  rcall Atraso_Pequeno

  ; Pegar a terceira linha, 4 bits menos significativos de screen_down
  ; Para isso, colocamos esses 4 bits nas suas devidas posições em aux, as 4 mais significativas. Para isso, utilizamos 4 leftwise bit shift
  mov   aux, screen_down
  lsl   aux
  lsl   aux
  lsl   aux
  lsl   aux
  ; Precisamos negar o valor, pois os valores colocados em cada coluna acendem apenas se forem zero.
  com   aux
  ; Precisamos deixar acesos apenas os bits acesos anteriormente da parte mais significativa, e o bit de linha adequado (terceiro)
  andi  aux, 0b11110100
  out   PORTD, aux
  rcall Atraso_Pequeno

  ; Pegar a quarta linha, 4 bits mais significativos de screen_down
  ; Para isso, apenas pegamos o valor de screen_down, não é necessário fazer bit shifting pois os quatro bits já estão na posição adequada
  mov   aux, screen_down
  ; Precisamos negar o valor, pois os valores colocados em cada coluna acendem apenas se forem zero.
  andi  aux, 0b11110000
  com   aux
  ; Precisamos deixar acesos apenas os bits acesos anteriormente da parte mais significativa, e o bit de linha adequado (quarto)
  andi  aux, 0b11111000
  out   PORTD, aux
  rcall Atraso_Pequeno

  ret


; Animacao para finalizar e voltar para o comeco de um novo nivel
Finalizar:
  cli
  ; Z aponta para tabela espiral
  ldi ZH, high(EspiralTable*2)
  ldi ZL, low(EspiralTable*2)
  ldi count, 16

Espiral_Loop:
  lpm aux, Z+         ; aux = posição 0 a 15

  ; Ativa o bit correspondente
  cpi aux, 8
  brlt Finalizar_Set_Up

  ; screen_down
  subi aux, 8
  ldi aux_bit, 1
  Finalizar_Loop1:
    cpi aux, 0
    breq Finalizar_Grava_Down
    dec aux
    lsl aux_bit
    rjmp Finalizar_Loop1

  Finalizar_Grava_Down:
    or screen_down, aux_bit
    rjmp Finalizar_Desenha

Finalizar_Set_Up:
  ldi aux_bit, 1
  Finalizar_Loop2:
    cpi aux, 0
    breq Finalizar_Grava_Up
    dec aux
    lsl aux_bit
    rjmp Finalizar_Loop2

  Finalizar_Grava_Up:
    or screen_up, aux_bit

Finalizar_Desenha:
  ldi aux, 0xFF
  mov aux_timer, aux
  Desenha_Loop:
  rcall Desenhar
  dec aux_timer
  brne Desenha_Loop
  
  dec count
  brne Espiral_Loop

; Piscar todos os LEDs 3 vezes
  ldi count, 3
Finalizar_Piscar:
  ldi screen_up, 0xFF
  ldi screen_down, 0xFF
  rcall Piscar_Loop

  clr screen_up
  clr screen_down
  rcall Piscar_Loop

  dec count
  brne Finalizar_Piscar

  rjmp Aguardar_Botao

; Permanece os LED's ligados por um tempo
Piscar_Loop:
  ldi r20, 8
  Loop1:
  ldi r21, 0xFF
  mov aux_timer, r21
  Loop2:
  rcall Desenhar
  dec aux_timer
  brne Loop2
  dec r20
  brne Loop1
  
  ret


Atraso:
  ldi   r20, 0xff
  Volta1:
  ldi   r21, 0x10
  Volta2:
  dec   r21
  brne  Volta2
  dec   r20
  brne  Volta1
  ret

Atraso_Pequeno:
  ldi   r21, 0xff
  Volta_Pequena:
  dec   r21
  brne  Volta_Pequena
  ret

EspiralTable:
  .db 0, 1, 2, 3
  .db 7, 11, 15, 14
  .db 13, 12, 8, 4
  .db 5, 6, 10, 9