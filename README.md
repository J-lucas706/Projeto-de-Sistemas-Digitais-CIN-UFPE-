# Projeto de Sistemas Digitais (CIN-UFPE)

## Integrantes do Grupo
* João Lucas Bezerra Silva (jlbs2@cin.ufpe.br)
* Maria Luiza de Paula Portela (mlpp@cin.ufpe.br)
* Vicente Martins Pereira Loureiro (vmpl@cin.ufpe.br)
* Caio Cesar Souza de Lira (ccsl@cin.ufpe.br)
* Matheus Luiz Teixeira da Silva (mlts@cin.ufpe.br)

## 1. Descrição Detalhada da Implementação

Este projeto segue a proposta da evolução de uma Máquina de Estados Finitos (FSM) para simular o mecanismo de um cofre digital utilizando a placa FPGA Altera DE2-115, O sistema exige a inserção de uma senha de 4 dígitos, compondo um dígito por vez de forma sequencial

**Mapeamento de Hardware:**
* **KEY[3]:** Seta para a esquerda (Decrementa o dígito ativo com lógica wrap-around 0 -> 9)
* **KEY[2]:** Seta para a direita (Incrementa o dígito ativo com lógica wrap-around 9 -> 0)
* **KEY[1]:** Confirmação (Fixa o valor do dígito atual e avança para o próximo)
* **KEY[0]:** Reset assíncrono (Retorna o sistema ao estado inicial)
* **HEX3 a HEX0:** Exibição da senha digitada pelo usuário
* **HEX4:** Exibição do índice do dígito atualmente em edição (0 a 3)
* **LEDG (Verdes):** Indicador de sucesso (Cofre aberto, acesos por 5 segundos)
* **LEDR (Vermelhos):** Indicador de falha (Senha incorreta, acesos por 3 segundos)

**Lógica de Controle:**
Foi implementado um detector de borda de subida para os botões `KEY[3:1]` (que são ativos em nível baixo), garantindo que manter o botão pressionado gere apenas uma única ação na FSM. A temporização de sucesso e falha foi parametrizada com base no clock de 50 MHz da placa, utilizando um contador de 32 bits

## 2. Diagrama de Estados

O fluxo do sistema opera em 7 estados principais

  ```mermaid
  stateDiagram-v2
    [*] --> EDIT_D1
    
    EDIT_D1 --> EDIT_D2 : KEY[1] (Confirm)
    EDIT_D1 --> EDIT_D1 : KEY[2]/KEY[3] (Inc/Dec)
    
    EDIT_D2 --> EDIT_D3 : KEY[1] (Confirm)
    EDIT_D2 --> EDIT_D2 : KEY[2]/KEY[3] (Inc/Dec)
    
    EDIT_D3 --> EDIT_D4 : KEY[1] (Confirm)
    EDIT_D3 --> EDIT_D3 : KEY[2]/KEY[3] (Inc/Dec)
    
    EDIT_D4 --> VERIFY : KEY[1] (Confirm)
    EDIT_D4 --> EDIT_D4 : KEY[2]/KEY[3] (Inc/Dec)
    
    VERIFY --> SUCCESS : Senha Correta
    VERIFY --> FAIL : Senha Incorreta
    
    SUCCESS --> EDIT_D1 : Timer = 5 seg
    FAIL --> EDIT_D1 : Timer = 3 seg

    note right of EDIT_D1 : KEY[0] (Reset) retorna qualquer estado para EDIT_D1

## 3. Bugs Conhecidos (Known Issues)
Debounce Físico dos Botões: O código utiliza uma lógica de detecção de borda síncrona. Em hardware físico, os contatos dos push buttons podem vibrar (bouncing). Como não há um módulo dedicado de debounce por atraso, um pressionamento pode eventualmente ser lido como múltiplos cliques rápidos.

Tempo de Simulação: Para validar os tempos de 5 e 3 segundos no simulador lógico, o parâmetro CLK_FREQ precisa ser drasticamente reduzido no testbench. A simulação com o clock real de 50 MHz exige um tempo de processamento inviável para visualização dos waveforms,usando um numero reduzido podemos visualizar o funcionamento do codigo de forma rapida

## 4. Diagramas de Tempo (Waveforms)

*(inserir as imagens dos gráficos do ModelSim aqui)*
* **Imagem 1:** Navegação de dígitos e wrap-around
* **Imagem 2:** Validação de senha correta (SUCCESS)
* **Imagem 3:** Validação de senha incorreta e retorno ao estado inicial após o timer (FAIL)


## 5. Hardware Físico (DE2-115)

Para ilustrar o funcionamento real além da simulação lógica, abaixo estão registros do sistema operando na FPGA:
*(Inserir as fotos da placa aqui)*


## 6. Demonstração em Vídeo

O arquivo de vídeo contendo a demonstração prática do hardware na placa DE2-115 e a explicação do código pelos integrantes foi anexado e enviado diretamente via Google Drive/Classroom, conforme as orientações de entrega da disciplina
