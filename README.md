# Lights Out
  
  Lights Out é um jogo de lógica e raciocínio criado pela Tiger Electronics em 1995. 
  Ele se tornou um clássico dos jogos de quebra-cabeça eletrônicos, 
  sendo simples de entender, mas desafiador de resolver.

## Como Funciona
O objetivo é apagar todas as luzes de um tabuleiro. As luzes estão dispostas em forma de grade (4x4 nesse projeto),
e cada uma pode estar acesa ou apagada.

Cada vez que você pressiona uma luz (célula), ela inverte seu estado: se estava acesa, apaga; se estava apagada, acende.

Além disso, as quatro luzes vizinhas (cima, baixo, esquerda, direita) também têm seu estado invertido.

As diagonais não são afetadas.




## Em relação ao Código

### Rotina de Interrupção para os botões
O código utiliza interrupção por mudança de pino (Pin Change Interrupt) nos pinos PB0 a PB3, configurados como entradas com pull-down. Esses pinos fazem parte do grupo PCINT0, e são ativados pelo registrador PCMSK0, que define quais pinos devem gerar interrupção ao mudar de estado. A interrupção do grupo é habilitada pelo registrador PCICR, e o vetor de interrupção é definido com .org PCI0addr. Assim, quando um botão é pressionado e o nível lógico muda, a rotina BOTAO_APERTADO é chamada automaticamente.

### Timers

No código, os timers 0 e 1 do microcontrolador são utilizados como fontes de valores pseudoaleatórios para simular toques no teclado matricial. Seus registradores (TCNT0 e TCNT1L) são lidos e manipulados (com soma, inversão e XOR), gerando números entre 0 e 15, que representam as 16 posições possíveis do teclado. Esses valores alimentam a sub-rotina que acende os “botões” correspondentes, criando padrões simulados de toques aleatórios.


### Tratamento dos botões

O teclado de membrana 4x4 é tratado no código por meio de uma função que permite identificar qual tecla foi pressionada utilizando um número reduzido de pinos do microcontrolador. 
Esse teclado possui 4 linhas e 4 colunas permitindo 16 botões.

No funcionamento, linhas são declaradas como saída recebendo sinal "1" ( nível lógico alto) e as colunas estão em pulldown recebem sinal "0" (colocadas em nível lógico baixo). 
Quando uma tecla é pressionada, ela conecta uma linha a uma coluna, fazendo assim com que a coluna vá para o nível lógico alto, assim é salvo qual coluna foi pressionada com isso chama-se uma outra rotina de escaneamento para detectar qual linha foi pressionada assim verificando
qual botão foi pressionado através de qual coluna e linha.

Essa varredura ocorre de forma sequencial e rápida, 
simulando a leitura simultânea de todas as teclas com apenas 8 pinos de I/O.

### Funcionamento dos Leds

O código contém duas rotinas principais, Acender_Up e Acender_Down, responsáveis por alternar o LED correspondente ao botão pressionado, assim como seus vizinhos (acima, abaixo, à esquerda e à direita), 
respeitando os limites da matriz. 

A identificação da posição é feita com base no valor do registrador count, que representa o índice do botão. 
O uso de máscaras binárias permite alterar os bits individualmente com eficiência por meio da operação XOR. 

Com as celúlas que vão ser alteradas identificadas a função main chama o método desenha para passar os valores para as saídas acendendo e apagando as células necessárias e também verifica se todos os LEDs foram apagados, sinalizando a vitória do jogador.


## Desenho do circuito 

<img width="698" height="351" alt="image" src="https://github.com/user-attachments/assets/4fbadb6b-ddfa-4b7a-8d99-c9ad575adfcd" />






## Materiais Utilizados
1 × Arduino UNO (com ATMEGA328-PB)

1× Teclado Matricial de Membrana

1 × Matriz de led 8x8

× Resistores de 330 Ω (para os LEDs) e de 100 Ω (para os botões)

× Jumpers

1 × Protoboard

### Equipe
Bruno Emanoel

Gabriel Marcos 

Marcello Lima

Pedro Antônio
