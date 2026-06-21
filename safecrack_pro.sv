module safecrack_pro #(
    // Senha padrao
    parameter logic [3:0] SECRET_PASS [0:3] = '{4'd1, 4'd2, 4'd3, 4'd4},
    // Frequencia real da placa DE2-115 (50 MHz). Altere para 10 no testbench se necessário.
    parameter int CLK_FREQ = 50_000_000 
)(
    input  logic        clk,      
    input  logic [3:0]  KEY,      
    output logic [6:0]  HEX0,     
    output logic [6:0]  HEX1,     
    output logic [6:0]  HEX2,     
    output logic [6:0]  HEX3,     
    output logic [6:0]  HEX4,     
    output logic [8:0]  LEDG,     
    output logic [17:0] LEDR      
);

    // Parametros de temporizacao baseados no parametro CLK_FREQ
    logic [31:0] TIME_5SEC;
    logic [31:0] TIME_3SEC;
    assign TIME_5SEC = CLK_FREQ * 5; 
    assign TIME_3SEC = CLK_FREQ * 3; 

    // Estados da FSM
    typedef enum logic [2:0] {
        EDIT_D1,    
        EDIT_D2,    
        EDIT_D3,    
        EDIT_D4,    
        VERIFY,     
        SUCCESS,    
        FAIL        
    } state_t;

    state_t state, next_state;

    // Registradores
    logic [3:0] user_pass [0:3];       
    logic [3:0] next_user_pass [0:3];  
    logic [31:0] timer, next_timer; // Aumentado para 32-bits para suportar 50M * 5 de forma segura

    // Edge detection (Ativo em alto)
    logic [3:1] key_pos, key_prev, key_edge;
    
    always_comb begin
        key_pos = ~KEY[3:1]; 
        key_edge = key_pos & ~key_prev;
    end

    logic rstn;
    assign rstn = KEY[0]; 

    // Sinais de controle
    logic dec_btn, inc_btn, confirm_btn;
    assign dec_btn     = key_edge[3]; 
    assign inc_btn     = key_edge[2]; 
    assign confirm_btn = key_edge[1]; 

    // Bloco Sequencial
    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            state        <= EDIT_D1;
            key_prev     <= 3'b000;
            timer        <= 32'd0;
            user_pass[0] <= 4'd0;
            user_pass[1] <= 4'd0;
            user_pass[2] <= 4'd0;
            user_pass[3] <= 4'd0;
        end else begin
            state        <= next_state;
            key_prev     <= key_pos;
            
            // Zera o timer automaticamente se houver mudança de estado para evitar lixo acumulado
            if (state != next_state)
                timer    <= 32'd0;
            else
                timer    <= next_timer;
                
            user_pass    <= next_user_pass;
        end
    end

    // Logica Combinacional (Next State / Datapath)
    always_comb begin
        // Valores default para evitar latches
        next_state     = state;
        next_timer     = timer;
        next_user_pass = user_pass;

        case (state)
            EDIT_D1: begin
                if (inc_btn) next_user_pass[0] = (user_pass[0] == 4'd9) ? 4'd0 : user_pass[0] + 1;
                else if (dec_btn) next_user_pass[0] = (user_pass[0] == 4'd0) ? 4'd9 : user_pass[0] - 1;
                
                if (confirm_btn) next_state = EDIT_D2;
            end

            EDIT_D2: begin
                if (inc_btn) next_user_pass[1] = (user_pass[1] == 4'd9) ? 4'd0 : user_pass[1] + 1;
                else if (dec_btn) next_user_pass[1] = (user_pass[1] == 4'd0) ? 4'd9 : user_pass[1] - 1;
                
                if (confirm_btn) next_state = EDIT_D3;
            end

            EDIT_D3: begin
                if (inc_btn) next_user_pass[2] = (user_pass[2] == 4'd9) ? 4'd0 : user_pass[2] + 1;
                else if (dec_btn) next_user_pass[2] = (user_pass[2] == 4'd0) ? 4'd9 : user_pass[2] - 1;
                
                if (confirm_btn) next_state = EDIT_D4;
            end

            EDIT_D4: begin
                if (inc_btn) next_user_pass[3] = (user_pass[3] == 4'd9) ? 4'd0 : user_pass[3] + 1;
                else if (dec_btn) next_user_pass[3] = (user_pass[3] == 4'd0) ? 4'd9 : user_pass[3] - 1;
                
                if (confirm_btn) next_state = VERIFY;
            end

            VERIFY: begin
                if ((user_pass[0] == SECRET_PASS[0]) &&
                    (user_pass[1] == SECRET_PASS[1]) &&
                    (user_pass[2] == SECRET_PASS[2]) &&
                    (user_pass[3] == SECRET_PASS[3])) begin
                    next_state = SUCCESS;
                end else begin
                    next_state = FAIL;
                end
            end

            SUCCESS: begin
                if (timer < TIME_5SEC - 1) begin
                    next_timer = timer + 1;
                end else begin
                    next_state = EDIT_D1;
                    next_user_pass = '{4'd0, 4'd0, 4'd0, 4'd0};
                end
            end

            FAIL: begin
                if (timer < TIME_3SEC - 1) begin
                    next_timer = timer + 1;
                end else begin
                    next_state = EDIT_D1;
                    next_user_pass = '{4'd0, 4'd0, 4'd0, 4'd0};
                end
            end

            default: next_state = EDIT_D1;
        endcase
    end

    // Logica de Saida (LEDs e HEX4)
    logic [3:0] active_digit_val;

    always_comb begin
        LEDG             = 9'b0;
        LEDR             = 18'b0;
        active_digit_val = 4'hF; // Valor fora do escopo (Desliga o display caso não editando)

        case (state)
            // Ajustado para os índices corretos solicitados na especificação (0 a 3)
            EDIT_D1: active_digit_val = 4'd0;
            EDIT_D2: active_digit_val = 4'd1;
            EDIT_D3: active_digit_val = 4'd2;
            EDIT_D4: active_digit_val = 4'd3;
            SUCCESS: LEDG             = 9'h1FF; 
            FAIL:    LEDR             = 18'h3FFFF; 
            default: ;
        endcase
    end

    // Decodificador 7 segmentos (Anodo comum - Ativo em Baixo)
    function automatic logic [6:0] sseg_decode(input logic [3:0] num);
        case (num)
            4'd0: sseg_decode = 7'b1000000;
            4'd1: sseg_decode = 7'b1111001;
            4'd2: sseg_decode = 7'b0100100;
            4'd3: sseg_decode = 7'b0110000;
            4'd4: sseg_decode = 7'b0011001;
            4'd5: sseg_decode = 7'b0010010;
            4'd6: sseg_decode = 7'b0000010;
            4'd7: sseg_decode = 7'b1111000;
            4'd8: sseg_decode = 7'b0000000;
            4'd9: sseg_decode = 7'b0010000;
            default: sseg_decode = 7'b1111111; // Tudo apagado
        endcase
    endfunction

    assign HEX3 = sseg_decode(user_pass[0]);
    assign HEX2 = sseg_decode(user_pass[1]);
    assign HEX1 = sseg_decode(user_pass[2]);
    assign HEX0 = sseg_decode(user_pass[3]);
    assign HEX4 = sseg_decode(active_digit_val);

endmodule