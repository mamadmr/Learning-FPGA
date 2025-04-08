module uart_rx (
    input clk,
    input rst,
    input rx,              
    output reg [7:0] data,
    output reg ready
);

parameter CLK_FREQ = 50000000;
parameter BAUD_RATE = 9600;
parameter BAUD_TICK_COUNT = CLK_FREQ / BAUD_RATE;

reg [15:0] baud_counter = 0;
reg baud_tick = 0;
reg [3:0] bit_index = 0;
reg [7:0] shift_reg = 0;
reg [1:0] state = 0;
reg [3:0] mid_sample = BAUD_TICK_COUNT / 2;

parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        baud_counter <= 0;
        baud_tick <= 0;
        bit_index <= 0;
        shift_reg <= 0;
        state <= IDLE;
        ready <= 0;
    end else begin
        // Baud Tick Generator
        if (baud_counter == BAUD_TICK_COUNT - 1) begin
            baud_counter <= 0;
            baud_tick <= 1;
        end else begin
            baud_counter <= baud_counter + 1;
            baud_tick <= 0;
        end

        case (state)
            IDLE: begin
                ready <= 0;
                if (~rx) begin 
                    state <= START;
                    baud_counter <= 0;
                end
            end
            START: begin
                if (baud_tick) begin
                    if (~rx) begin
                        state <= DATA;
                        bit_index <= 0;
                    end else begin
                        state <= IDLE; 
                    end
                end
            end
            DATA: begin
                if (baud_tick) begin
                    shift_reg[bit_index] <= rx;
                    if (bit_index == 7) begin
                        state <= STOP;
                    end else begin
                        bit_index <= bit_index + 1;
                    end
                end
            end
            STOP: begin
                if (baud_tick) begin
                    if (rx) begin
                        data <= shift_reg;
                        ready <= 1;
                    end
                    state <= IDLE;
                end
            end
        endcase
    end
end

endmodule
