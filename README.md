# Projeto: SafeCrack FSM - Fechadura Digital (DE2-115)

## Integrantes do Grupo
* Nome do Integrante 1 (Email)
* Nome do Integrante 2 (Email)
* Nome do Integrante 3 (Email)
* Nome do Integrante 4 (Email)
* Nome do Integrante 5 (Email)

## 1. Descrição Detalhada da Implementação

Este projeto segue a proposta da evolução de uma Máquina de Estados Finitos (FSM) para simular o mecanismo de um cofre digital utilizando a placa FPGA Altera DE2-115. O sistema pede que insira uma senha de 4 dígitos, onde ele navega em qualquer posição

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

  mermaid
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
