.nolist
.include "m328Pdef.inc"
.list

.def aux = R16
.def screen_up = R17
.def screen_down = R18

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
  ; Ligando o flag de interrupção
  sei

  ; Valor inicial da tela
  ; Como será utilizada uma matriz de led como se fosse 4X4, precisaremos de 16 bits no total.
  ; Ou seja, 2 registradores que serão chamados de screen_up e screen_down, que portarão a parte superior e inferior da tela, respectivamente.
  ; Os 4 bits menos significativos de cada um representam sua linha superior, enquanto os 4 mais significativos representam a linha inferior. 
  ; TODO: Mudar essa inicialização
  ldi   screen_up, 0b11110000
  ldi   screen_down, 0b10010110
  rjmp  Main


BOTAO_APERTADO:
  ; Quando o botão é apertado, ele muda arbitrariamente os valores em screen_up e screen_down
  ldi   screen_up, 0b1111
  ldi   screen_down, 0b01101001
  RETI

Main:
  rcall Atraso
  rjmp  MAIN

;Método que olhará os valores em screne_up e screen_down e os desenhará na matriz de led
Desenhar:
  ; Pegar a primeira linha, 4 bits menos significativos de screen_up
  ; Para isso, colocamos esses 4 bits nas suas devidas posições em aux, as 4 mais significativas. Para isso, utilizamos 4 leftwise bit shift
  mov   aux, screen_up
  lsl   aux
  lsl   aux
  lsl   aux
  lsl   aux
  ; Precisamos negar o valor, pois os valores colocados em cada coluna ascendem apenas se forem zero.
  com   aux
  ; Precisamos deixar acesos apenas os bits acesos anteriormente da parte mais significativa, e o bit de linha adequado (primeiro)
  andi  aux, 0b11110001
  out   PORTD, aux
  rcall Atraso_Pequeno

  ; Pegar a segunda linha, 4 bits mais significativos de screen_up
  ; Para isso, apenas pegamos o valor de screen_up, não é necessário fazer bit shifting pois os quatro bits já estão na posição adequada
  mov   aux, screen_up
  ; Precisamos negar o valor, pois os valores colocados em cada coluna ascendem apenas se forem zero.
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
  ; Precisamos negar o valor, pois os valores colocados em cada coluna ascendem apenas se forem zero.
  com   aux
  ; Precisamos deixar acesos apenas os bits acesos anteriormente da parte mais significativa, e o bit de linha adequado (terceiro)
  andi  aux, 0b11110100
  out   PORTD, aux
  rcall Atraso_Pequeno

  ; Pegar a quarta linha, 4 bits mais significativos de screen_down
  ; Para isso, apenas pegamos o valor de screen_down, não é necessário fazer bit shifting pois os quatro bits já estão na posição adequada
  mov   aux, screen_down
  ; Precisamos negar o valor, pois os valores colocados em cada coluna ascendem apenas se forem zero.
  com   aux
  ; Precisamos deixar acesos apenas os bits acesos anteriormente da parte mais significativa, e o bit de linha adequado (quarto)
  andi  aux, 0b11111000
  out   PORTD, aux
  rcall Atraso_Pequeno

  ret


Atraso:
  ldi   r20, 0xff
  Volta1:
  ldi   r21, 0x10
  Volta2:
  rcall Desenhar
  dec   r21
  brne  Volta2
  dec   r20
  brne  Volta1
  ret

Atraso_Pequeno:
  ldi   r22, 0x5
  Volta_Pequena:
  dec   r21
  brne  Volta_Pequena
  ret