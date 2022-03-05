// control unit

`include "defines.v"

module ControlUnit (
    input [`INSTR_SIZE-1:0] instr,

    output reg [4:0] immCtrl,             // for the ID stage
    output reg [3:0] ALUCtrl,             // for the EX stage
    output           ALUSrcA,
    output           ALUSrcB,
    output           branch,
    output     [2:0] funct3,
    output reg [1:0] jumpType,
    output           memWrite,            // for the MEM stage
    output reg [1:0] memtoReg,
    output           regWrite             // for the WB stage
);
    // extract fields from instruction
    wire [6:0] opcode = instr[6:0];
    assign funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];
    wire [4:0] rs1 = instr[19:15];
    wire [4:0] rs2 = instr[24:20];
    wire [4:0] rd = instr[11:7];

    // MUX control signals
    assign ALUSrcA = (opcode == `OP_AUIPC);
    assign ALUSrcB = (opcode == `OP_I_TYPE
                     | opcode == `OP_LUI
                     | opcode == `OP_AUIPC
                     | opcode == `OP_LOAD
                     | opcode == `OP_STORE);
    assign branch = (opcode == `OP_BRANCH);
    assign memWrite = (opcode == `OP_STORE);
    assign regWrite = (opcode == `OP_R_TYPE
                      | opcode == `OP_I_TYPE
                      | opcode == `OP_JAL
                      | opcode == `OP_JALR
                      | opcode == `OP_LUI
                      | opcode == `OP_AUIPC
                      | opcode == `OP_LOAD
                      ) & (rd != `REG_IDX_WIDTH'b0);

    always @(*)
    if (opcode == `OP_JAL | opcode == `OP_JALR)
        begin
            jumpType <= opcode == `OP_JAL ? `JUMP_TYPE_JAL : `JUMP_TYPE_JALR;
            memtoReg <= 2'b10;
        end
    else if (opcode == `OP_LOAD)
        begin
            jumpType <= `JUMP_TYPE_NONE;
            memtoReg <= 2'b01;
        end
    else
        begin
            jumpType <= `JUMP_TYPE_NONE;
            memtoReg <= 2'b00;
        end

    // ALU & immediate generator control signals
    always @(*)
    case(opcode)
        `OP_LUI:
            begin
                immCtrl <= `IMM_CTRL_UTYPE;
                ALUCtrl <= `ALU_CTRL_LUI;
            end
        `OP_AUIPC:
            begin
                immCtrl <= `IMM_CTRL_UTYPE;
                ALUCtrl <= `ALU_CTRL_AUIPC;
            end
        `OP_JAL:
            begin
                immCtrl <= `IMM_CTRL_JTYPE;
                ALUCtrl <= `ALU_CTRL_ZERO;
            end
        `OP_JALR:
            begin
                immCtrl <= `IMM_CTRL_ITYPE;
                ALUCtrl <= `ALU_CTRL_ZERO;
            end
        `OP_BRANCH:
            begin
                immCtrl <= `IMM_CTRL_BTYPE;
                case (funct3)
                    `FUNCT3_BEQ:
                        ALUCtrl <= `ALU_CTRL_SUB;
                    `FUNCT3_BNE:
                        ALUCtrl <= `ALU_CTRL_SUB;
                    `FUNCT3_BLT:
                        ALUCtrl <= `ALU_CTRL_SLT;
                    `FUNCT3_BGE:
                        ALUCtrl <= `ALU_CTRL_SLT;
                    `FUNCT3_BLTU:
                        ALUCtrl <= `ALU_CTRL_SLTU;
                    `FUNCT3_BGEU:
                        ALUCtrl <= `ALU_CTRL_SLTU;
                    default:
                        ALUCtrl <= `ALU_CTRL_ZERO;
                endcase
            end
        `OP_LOAD:
            begin
                immCtrl <= `IMM_CTRL_ITYPE;
                ALUCtrl <= `ALU_CTRL_ADD;
            end
        `OP_STORE:
            begin
                immCtrl <= `IMM_CTRL_STYPE;
                ALUCtrl <= `ALU_CTRL_ADD;
            end
        `OP_I_TYPE:
            begin
                immCtrl <= `IMM_CTRL_ITYPE;
                case (funct3)
                    `FUNCT3_ADDI:
                        ALUCtrl <= `ALU_CTRL_ADD;
                    `FUNCT3_SLTI:
                        ALUCtrl <= `ALU_CTRL_SLT;
                    `FUNCT3_SLTIU:
                        ALUCtrl <= `ALU_CTRL_SLTU;
                    `FUNCT3_XORI:
                        ALUCtrl <= `ALU_CTRL_XOR;
                    `FUNCT3_ORI:
                        ALUCtrl <= `ALU_CTRL_OR;
                    `FUNCT3_ANDI:
                        ALUCtrl <= `ALU_CTRL_AND;
                    `FUNCT3_SLL:
                        ALUCtrl <= `ALU_CTRL_SLL;
                    `FUNCT3_SR:
                        case (funct7)
                            `FUNCT7_SRL:
                                ALUCtrl <= `ALU_CTRL_SRL;
                            `FUNCT7_SRA:
                                ALUCtrl <= `ALU_CTRL_SRA;
                            default:
                                ALUCtrl <= `ALU_CTRL_ZERO;
                        endcase
                    default:
                        ALUCtrl <= `ALU_CTRL_ZERO;
                endcase
            end
        `OP_R_TYPE:
            case (funct3)
                `FUNCT3_ADD:
                    case (funct7)
                        `FUNCT7_ADD:
                            ALUCtrl <= `ALU_CTRL_ADD;
                        `FUNCT7_SUB:
                            ALUCtrl <= `ALU_CTRL_SUB;
                        default:
                            ALUCtrl <= `ALU_CTRL_ZERO;
                    endcase
                `FUNCT3_SL:
                    ALUCtrl <= `ALU_CTRL_SLL;
                `FUNCT3_SLT:
                    ALUCtrl <= `ALU_CTRL_SLT;
                `FUNCT3_SLTU:
                    ALUCtrl <= `ALU_CTRL_SLTU;
                `FUNCT3_XOR:
                    ALUCtrl <= `ALU_CTRL_XOR;
                `FUNCT3_SR:
                    case (funct7)
                        `FUNCT7_SRL:
                            ALUCtrl <= `ALU_CTRL_SRL;
                        `FUNCT7_SRA:
                            ALUCtrl <= `ALU_CTRL_SRA;
                        default:
                            ALUCtrl <= `ALU_CTRL_ZERO;
                    endcase
                `FUNCT3_OR:
                    ALUCtrl <= `ALU_CTRL_OR;
                `FUNCT3_AND:
                    ALUCtrl <= `ALU_CTRL_AND;
            endcase
        default:    ALUCtrl <= `ALU_CTRL_ZERO;
	endcase
endmodule