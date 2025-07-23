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

#


## Em relação ao Código

#### Rotina de Interrupção
Foi implementada uma rotina de interrupção no código(BOTAO_APERTADO) com o objetivo de verificar se um botão foi pressionado.
Sempre que ocorre uma mudança no pino configurado (uma borda de subida), 
a interrupção é acionada automaticamente, desviando o fluxo do programa principal para a rotina de tratamento.


#### Tratamento dos botões

O teclado de membrana 4x4 é tratado no código por meio de uma técnica de multiplexação, que permite identificar qual tecla foi pressionada utilizando um número reduzido de pinos do microcontrolador. 
Esse teclado possui 4 linhas e 4 colunas permitindo 16 botões.

No funcionamento, colunas são declaradas como saída recebendo sinal "1" ( nível lógico alto) e as linhas recebem sinal "0" (colocadas em nível lógico baixo). 
Quando uma tecla é pressionada, ela conecta uma linha a uma coluna, fazendo assim com que a coluna vá para o nível lógico baixo, assim é salvo qual coluna foi pressionada 
e logo após é invertido o sinal lógico das linhas e colunas com isso chama-se uma outra rotina para detectar qual linha foi pressionada(verificar qual linha está em "0", assim detectando 
qual botão foi pressionado através de qual coluna e linha.

Essa varredura ocorre de forma sequencial e rápida, 
simulando a leitura simultânea de todas as teclas com apenas 8 pinos de I/O.

### Funcionamento dos Leds

O código contém duas rotinas principais, Acender_Up e Acender_Down, responsáveis por alternar o LED correspondente ao botão pressionado, assim como seus vizinhos (acima, abaixo, à esquerda e à direita), 
respeitando os limites da matriz. 

A identificação da posição é feita com base no valor do registrador count, que representa o índice do botão. 
O uso de máscaras binárias permite alterar os bits individualmente com eficiência por meio da operação XOR. 

Com as celúlas que vão ser alteradas identificadas a função main chama o método desenha para passar os valores para as saídas acendendo e apagando as células necessárias e também verifica se todos os LEDs foram apagados, sinalizando a vitória do jogador.




















## Materiais Utilizados
1 × Arduino UNO (com ATMEGA328-PB)

1× Teclado Matricial de Membrana

1 × Matriz de led 8x8

× Resistores de 330 Ω (para os LEDs) e de 100 Ω (para os botões)
× Jumpers

1 × Protoboard
