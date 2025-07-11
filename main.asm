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
.def col_pointer = R25
.equ Botoes = PINB

.ORG 0x00
  RJMP INICIO 
.org PCI0addr
  RJMP BOTAO_APERTADO


INICIO:
  ; Usaremos PD0 ~ PD7 como saída
  ldi   aux, 0xff
  out   DDRD, aux
  ; Usaremos PB0 ~ PB7 como entrada
  ldi   aux, 0
  out   DDRB, aux
  ; Pull-up habilitado 
  ldi   aux, 0xff
  out   PORTB, aux
  ; Define todos os Pins B como ativadores de interrupção
  sts   PCMSK0, aux
  ; Habilitando PCI para o portB (PCIE0)
  ldi   aux, (1<<PCIE0)
  sts   PCICR, aux


  ;ldi   aux, 0xff
  ;out   DDRC, aux

  
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
    in aux, PINB         
    cpi aux, 0x00       
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


BOTAO_APERTADO:
  ; Quando o botão é apertado, ele muda arbitrariamente os valores em screen_up e screen_down
  clr   count
  ldi   col_pointer, 1
  ldi   row_pointer, 0b10000

  BOTAO_APERTADO_Checar:
  in    aux, Botoes
  and   aux, row_pointer
  cpi   aux, 0
  breq  BOTAO_APERTADO_Checar_ProximaLinha
  rjmp  BOTAO_APERTADO_Coluna
  BOTAO_APERTADO_Checar_ProximaLinha:
  ldi   aux, 4
  add   count, aux
  lsl   row_pointer
  cpi   count, 16
  brge  BOTAO_APERTADO_Retorno
  rjmp  BOTAO_APERTADO_Checar

  BOTAO_APERTADO_Coluna:
  in    aux, Botoes
  and   aux, col_pointer
  cpi   aux, 0
  breq  BOTAO_APERTADO_Checar_ProximaColuna
  rjmp  BOTAO_APERTADO_Acender
  BOTAO_APERTADO_Checar_ProximaColuna:
  inc   count
  lsl   col_pointer
  cpi   count, 16
  brge  BOTAO_APERTADO_Retorno
  rjmp  BOTAO_APERTADO_Coluna


  cpi   count, 16
  brge  BOTAO_APERTADO_Retorno
  BOTAO_APERTADO_Acender:
  mov   R26, count
  cpi   count, 8
  brge  BOTAO_APERTADO_Down
  rcall Acender_Up
  rjmp  BOTAO_APERTADO_Retorno
  BOTAO_APERTADO_Down:
  subi  count, 8
  rcall Acender_Down
  BOTAO_APERTADO_Retorno:
  RETI

Acender_Up:
  clr   aux
  clr   aux_bit
  inc   aux_bit

  Acender_Up_Centro:
  cp    aux, count
  breq  Acender_Up_Cima
  inc   aux
  lsl   aux_bit
  rjmp  Acender_Up_Centro
  Acender_Up_Cima:
  eor   screen_up, aux_bit

  cpi   aux, 4
  brlt  Acender_Up_Direita
  mov   bit_copy, aux_bit
  lsr   bit_copy  
  lsr   bit_copy  
  lsr   bit_copy  
  lsr   bit_copy
  eor   screen_up, bit_copy  

  Acender_Up_Direita:
  andi  aux, 0b11
  cpi   aux, 0
  breq  Acender_Up_Baixo
  mov   bit_copy, aux_bit
  lsr   bit_copy
  eor   screen_up, bit_copy

  Acender_Up_Baixo:
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
  andi  aux, 0b11
  cpi   aux, 0b11
  breq  Acender_Up_Fim
  lsl   aux_bit
  eor   screen_up, aux_bit

  Acender_Up_Fim:
  ret

Acender_Down:
  clr   aux
  clr   aux_bit
  inc   aux_bit
  
  Acender_Down_Centro:
  cp    aux, count
  breq  Acender_Down_Cima
  inc   aux
  lsl   aux_bit
  rjmp  Acender_Down_Centro
  Acender_Down_Cima:
  eor   screen_down, aux_bit

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
  andi  aux, 0b11
  cpi   aux, 0
  breq  Acender_Down_Baixo
  mov   bit_copy, aux_bit
  lsr   bit_copy
  eor   screen_down, bit_copy

  Acender_Down_Baixo:
  mov   aux, count
  cpi   aux, 0b100
  brge  Acender_Down_Esquerda
  mov   bit_copy, aux_bit
  lsl   bit_copy
  lsl   bit_copy
  lsl   bit_copy
  lsl   bit_copy
  eor   screen_down, bit_copy

  Acender_Down_Esquerda:
  andi  aux, 0b11
  cpi   aux, 0b11
  breq  Acender_Down_Fim
  lsl   aux_bit
  eor   screen_down, aux_bit

  Acender_Down_Fim:
  ret


Main:
  ; Desenha na matriz LED
  ;rcall Atraso
  ; Verifica se o jogo está finalizado
  ; TODO: Fazer funcionar ????
  ;cpi screen_up, 0
  ;brne Main          ; se forem diferentes, continua
  ;cpi screen_down, 0
  ;brne Main          ; se não for zero, continua
  ;rjmp Finalizar
  
  rcall Desenhar
  rcall Atraso_Pequeno
  cp screen_up, screen_down
  brne Main
  cpi screen_up, 0x00
  brne Main
  rjmp Finalizar


;Método que olhará os valores em screne_up e screen_down e os desenhará na matriz de led
Desenhar:

  ;out PORTC, screen_down


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
  rcall Desenhar
  rcall Atraso_Pequeno

  dec count
  brne Espiral_Loop

; Piscar todos os LEDs 3 vezes
  ldi count, 3
Finalizar_Piscar:
  ldi screen_up, 0xFF
  ldi screen_down, 0xFF
  rcall Desenhar
  rcall Atraso

  clr screen_up
  clr screen_down
  rcall Desenhar
  rcall Atraso

  dec count
  brne Finalizar_Piscar

  sei
  rjmp Aguardar_Botao


Atraso:
  ldi   r20, 0xff
  Volta1:
  ldi   r21, 0x10
  Volta2:
  ;rcall Desenhar
  dec   r21
  brne  Volta2
  dec   r20
  brne  Volta1
  ret

Atraso_Pequeno:
  ldi   r22, 0xff
  Volta_Pequena:
  dec   r21
  brne  Volta_Pequena
  ret


EspiralTable:
  .db 0, 1, 2, 3
  .db 7, 11, 15, 14
  .db 13, 12, 8, 4
  .db 5, 6, 10, 9