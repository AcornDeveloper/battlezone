; mathbox mathbox
; invokes mathbox arm v2 second processor or above to leverage the power of a co-processor
;
; the functions provided by the original atari mathbox were uncomplicated, essentially
; providing access to multiplication and division, something a later generation of
; microprocessors to the 6502 would provide with ease
;
; host code will check for presence of a second processor, load mathbox code into it's
; memory space and execute causing the second processor, if the arm mathbox, to return a flag to
; the host indicating presence and a flag indicating speed, it then enters a service loop waiting
; for function requests from the host
;
; portions of the tube control code are taken from the bbc master 6502 dnfs rom and adapted
; to serve the limited requirements of the mathbox and also free up the host language work space
; residing at &0400 - &07FF for user programs and zero page
;
; in general the mathbox function sequence is:-
; host     - populate host register(s) with data and function code
; host     - send all host registers and function code to mathbox
; mathbox  - executes function and populates internal mathbox register(s) with result(s)
; mathbox  - enters service loop polling for the next request
; host     - retrieve result(s) from internal mathbox register(s) to host register(s)/zero page address
; host     - uses result(s) passed back
;

MACRO release_tube                      ;tested and works/saved as a macro if required, not used here
.mathbox_release_tube_direct            ;as no clean exit
 BIT mathbox_flag
 BVC mathbox_exit_routine
 LDA #&C0 + mathbox_claim_id            ;release the tube
 CMP host_control_block_claim_id        ;compare release to claim
 BNE mathbox_exit_routine               ;exit as different
 PHP
 SEI
 LDA #&05
 STA host_data_register_04
 LDA host_control_block_claim_id
 STA host_data_register_04
 PLP                                    ;restore irq status
 LDA #&80
 STA host_control_block_claim_id        ;store tube id
 STA host_control_block_tube_flag       ;set tube status
.mathbox_exit_routine
 RTS
ENDMACRO

.mathbox_retrieve_data_length           ;bytes to transfer from mathbox indexed by function code
 EQUB &00                               ;00 08 bit mathbox presence flag/mathbox will push flags back
 EQUB &02                               ;01 16 bit signed division
 EQUB &04                               ;02 16 bit signed multiplication
 EQUB &01                               ;03 16 bit square root
 EQUB &00                               ;04 16 bit rotation angles x/y/z      - write
 EQUB &06                               ;05 16 bit rotation around x/y/z
 EQUB &06                               ;06 16 bit rotation
 EQUB &00                               ;07 16 bit line draw
 EQUB &02                               ;08 24 bit signed division
 EQUB &00                               ;09 08 bit screen address             - write
 EQUB &02                               ;0A 16 bit distance
 EQUB &00                               ;0B 16 bit graphic window x0/y0/x1/y1 - write
 EQUB &09                               ;0C 16 bit line clip

.mathbox_command_code
 EQUB &86                               ;parasite to host bytes
 EQUB &88                               ;host to parasite bytes

.mathbox_vectors                        ;<--- vector table start

.mathbox_vector_division_16             ;initialised with 6502 vectors
 EQUW division_16_signed_6502
.mathbox_vector_multiplication_16
 EQUW multiply_16_signed_6502
.mathbox_vector_square_root_16
 EQUW square_root_16_6502
.mathbox_vector_line_draw_08
 EQUW line_draw_08_6502
.mathbox_vector_line_draw_16
 EQUW line_draw_16_6502
.mathbox_vector_line_draw_16c
 EQUW line_draw_16c_6502
.mathbox_vector_division_24
 EQUW division_24_signed_6502
.mathbox_vector_distance_16
 EQUW distance_16_6502
.mathbox_vector_line_clip_16
 EQUW line_clip_16_6502

.mathbox_vectors_end                    ;<--- vector table end

.mathbox_6502_vector_table              ;6502 vectors
 EQUW division_16_signed_6502
 EQUW multiply_16_signed_6502
 EQUW square_root_16_6502
 EQUW line_draw_08_6502
 EQUW line_draw_16_6502
 EQUW line_draw_16c_6502
 EQUW division_24_signed_6502
 EQUW distance_16_6502
 EQUW line_clip_16_6502

.mathbox_arm_vector_table               ;arm vectors  
 EQUW mathbox_division_16_signed
 EQUW mathbox_multiply_16_signed
 EQUW mathbox_square_root
 EQUW mathbox_line_draw_16
 EQUW mathbox_line_draw_16
 EQUW mathbox_line_draw_16
 EQUW mathbox_division_24_signed
 EQUW mathbox_distance_16
 EQUW line_clip_16_6502                 ;unresolved problem with mathbox line clip at present

.mathbox_division16                     ;mathbox vectors
 JMP (mathbox_vector_division_16)
.mathbox_multiplication16
 JMP (mathbox_vector_multiplication_16)
.mathbox_square_root16
 JMP (mathbox_vector_square_root_16)
.mathbox_line_draw08
 JMP (mathbox_vector_line_draw_08)
.mathbox_line_draw16
 JMP (mathbox_vector_line_draw_16)
.mathbox_line_draw16c
 JMP (mathbox_vector_line_draw_16c)
.mathbox_division24
 JMP (mathbox_vector_division_24)
.mathbox_distance16
 JMP (mathbox_vector_distance_16)
.mathbox_line_clip16
 JMP (mathbox_vector_line_clip_16)

.mathbox_vector_index_low
 EQUB LO(mathbox_6502_vector_table)
 EQUB LO(mathbox_arm_vector_table)
.mathbox_vector_index_high
 EQUB HI(mathbox_6502_vector_table)
 EQUB HI(mathbox_arm_vector_table)

.mathbox_transfer_block                 ;host where to send bytes in mathbox
 EQUD mathbox_register_block            ;pointer parasite registers/function code

.mathbox_line_block                     ;host where to receive bytes in mathbox
 EQUD mathbox_screen_address + &03      ;pointer parasite line flag, then line data

.mathbox_toggle_activated               ;toggle mathbox status if activated
 BIT mathbox_flag
 BVC no_mathbox                         ;no mathbox at all
 LDA #LO(mathbox_toggle)
 STA workspace
 LDA screen_hidden
 CLC
 ADC #HI(mathbox_toggle)
 STA workspace + &01
 BIT combined_f
 BPL display_mathbox
 INC sound_key_click                    ;causing screen corruption
 LDA mathbox_flag                       ;toggle mathbox status
 EOR #&80
 STA mathbox_flag
 ASL A                                  ;a = mathbox flag, bit 6 = mathbox presence, get into x
 ROL A
 TAX
 LDA mathbox_vector_index_low,X
 STA mathbox_vector
 LDA mathbox_vector_index_high,X
 STA mathbox_vector + &01
 LDY #mathbox_vectors_end - mathbox_vectors - &01
.mathbox_populate_table                 ;copy vector table
 LDA (mathbox_vector),Y
 STA mathbox_vectors,Y
 DEY
 BPL mathbox_populate_table
.display_mathbox
 LDY #&00
 BIT mathbox_flag
 BPL mathbox_clear_indicator            ;mathbox off
 LDA #&18
 BNE mathbox_square_on
.mathbox_clear_indicator
 TYA
.mathbox_square_on
 STA (workspace),Y
 INY
 STA (workspace),Y
.no_mathbox
 RTS

.mathbox_command_tube_direct
 STY host_control_block_pointer + &01   ;control block pointer
 STX host_control_block_pointer
 STA host_data_register_04              ;send action code using r4 to parasite
 TAX                                    ;save action code
 LDA host_control_block_claim_id        ;send tube id using r4
 STA host_data_register_04
 LDY #&03                               ;send control block
.mathbox_send_control_block
 LDA (host_control_block_pointer),Y
 STA host_data_register_04
 DEY
 BPL mathbox_send_control_block
 LDY #&18
 STY host_status_register_01            ;disable fifo/nmi, set sr1
 LDA mathbox_command_code,X             ;get action code and set sr1
 STA host_status_register_01
 LSR A
 LSR A
 BCC mathbox_no_wait
 BIT host_data_register_03              ;delay
.mathbox_no_wait
 STA host_data_register_04              ;send flag synchronise using r4
 BCC mathbox_command_tube_direct_exit
 LSR A
 BCC mathbox_command_tube_direct_exit
 LDY #&88
 STY host_status_register_01
.mathbox_command_tube_direct_exit
 RTS

.mathbox_claim_tube                     ;claim tube for duration
 BIT mathbox_flag
 BVC mathbox_return
 LDA #&C0 + mathbox_claim_id
.mathbox_keep_claiming
 JSR mathbox_claim_tube_direct
 BCC mathbox_keep_claiming
.mathbox_return
 RTS

.mathbox_claim_tube_direct              ;claim tube directly
 ASL host_control_block_tube_flag
 BCS mathbox_claim_it
 CMP host_control_block_claim_id
 BEQ mathbox_claim_tube_direct_exit     ;already claimed
 CLC                                    ;can't claim it yet
.mathbox_claim_tube_direct_exit
 RTS
.mathbox_claim_it
 STA host_control_block_claim_id
.mathbox_exit
 RTS

.mathbox_window_16                      ;x/y point to graphics window
 STX window_address
 STY window_address + &01
 LDY #&07
 LDX #&07
.mathbox_window_setup
 LDA (window_address),Y
 STA host_r0,X
 STA graphic_window,X
 DEX
 DEY
 BPL mathbox_window_setup
 BIT mathbox_flag
 BVC mathbox_exit                       ;update mathbox regardless if active
 LDA #mathbox_code_window16             ;result destination not required
 BNE mathbox_function_a_only            ;always

.mathbox_line_clip_16
 LDA graphic_x_00
 STA host_r0
 LDA graphic_x_00 + &01
 STA host_r0 + &01
 LDA graphic_y_00
 STA host_r1
 LDA graphic_y_00 + &01
 STA host_r1 + &01
 LDA graphic_x_01
 STA host_r2
 LDA graphic_x_01 + &01
 STA host_r2 + &01
 LDA graphic_y_01
 STA host_r3
 LDA graphic_y_01 + &01
 STA host_r3 + &01
 LDA #mathbox_code_line_clip16
 LDX #host_register_block
 JSR mathbox_function_ax
 LSR host_flags                         ;c=0 segment on else c=1 segment off
 BCS mathbox_leave                      ;leave early as off screen
 LDX #&07
.mathbox_clip_results
 LDA host_r0,X
 STA graphic_x_00,X
 DEX
 BPL mathbox_clip_results
.mathbox_leave
 RTS

.mathbox_division_16_signed
 LDA dividend_16
 STA host_r0
 LDA dividend_16 + &01
 STA host_r0 + &01
 LDA divisor_16
 STA host_r1
 LDA divisor_16 + &01
 STA host_r1 + &01
 LDA #mathbox_code_signed_division16
 LDX #division_result_16                ;result destination
 BNE mathbox_function_ax                ;always

.mathbox_multiply_16_signed
 LDA multiplier_16
 STA host_r0
 LDA multiplier_16 + &01
 STA host_r0 + &01
 LDA multiplicand_16
 STA host_r1
 LDA multiplicand_16 + &01
 STA host_r1 + &01
 LDA #mathbox_code_signed_multiply16
 LDX #product_16                        ;result destination
 BNE mathbox_function_ax                ;always

.mathbox_square_root
 LDA #mathbox_code_square_root16
 LDX #squared_16                        ;result destination
 BNE mathbox_function_ax                ;always

.mathbox_rotation_angles                ;copy object rotation angles to mathbox
 BIT mathbox_flag
 BPL mathbox_leave
 LDA x_object_rotation                  ;store x/y/z rotation angles
 STA host_r0
 LDA y_object_rotation
 STA host_r1
 LDA z_object_rotation
 STA host_r2
 LDA #mathbox_code_rotation_angles08    ;result destination not required

.mathbox_function_ax
 STX mathbox_retrieve_destination + &01 ;x = results destination
.mathbox_function_a_only
 STA host_function_code                 ;a = function required
 LDX #LO(mathbox_transfer_block)
 LDY #HI(mathbox_transfer_block)
 LDA #tube_reason_code_01               ;command for host ---> parasite - multiple byte transfer
 JSR mathbox_command_tube_direct
 LDY #host_register_block_end - host_register_block
 LDX #&00
.mathbox_send_data_command_01_loop      ;send r0-r3 registers, flag and function code
 LDA host_register_block,X
 STA host_data_register_03
 INX
 DEY
 BNE mathbox_send_data_command_01_loop
 LDX host_function_code                 ;get function code and index into bytes to bring back
 LDA mathbox_retrieve_data_length,X
 BEQ mathbox_function_exit              ;nothing to retrieve, call only so exit
 PHA                                    ;save length
 LDX #LO(mathbox_transfer_block)
 LDY #HI(mathbox_transfer_block)
 LDA #tube_reason_code_00               ;command for parasite ---> host - multiple byte transfer
 JSR mathbox_command_tube_direct
 PLA                                    ;retrieve length
 TAY
 LDX #&00
.mathbox_retrieve_data_02
 LDA host_data_register_03
.mathbox_retrieve_destination
 STA host_register_block,X
 INX
 DEY
 BNE mathbox_retrieve_data_02
.mathbox_function_exit
 RTS

.mathbox_division_24_signed
 LDA dividend_24
 STA host_r0
 LDA dividend_24 + &01
 STA host_r0 + &01
 LDA dividend_24 + &02
 STA host_r1
 LDA divisor_24
 STA host_r2
 LDA divisor_24 + &01
 STA host_r2 + &01
 LDA divisor_24 + &02
 STA host_r3
 LDA #mathbox_code_signed_division24
 LDX #division_result_24                ;result destination
 BNE mathbox_function_ax                ;always

.mathbox_distance_16
 LDA #mathbox_code_distance16
 LDX #d_object_distance                 ;result destination
 BNE mathbox_function_ax                ;always

.mathbox_line_draw_16                   ;copy x0/y0/x1/y1 to host registers
 LDA graphic_x_00
 STA host_r0
 LDA graphic_x_00 + &01
 STA host_r0 + &01
 LDA graphic_y_00
 STA host_r1
 LDA graphic_y_00 + &01
 STA host_r1 + &01
 LDA graphic_x_01
 STA host_r2
 LDA graphic_x_01 + &01
 STA host_r2 + &01
 LDA graphic_y_01
 STA host_r3
 LDA graphic_y_01 + &01
 STA host_r3 + &01
 LDA #mathbox_code_line_draw16
 JSR mathbox_function_a_only
.mathbox_wait_for_line
 LDX #LO(mathbox_line_block)            ;retrieve line done flag
 LDY #HI(mathbox_line_block)
 LDA #tube_reason_code_00               ;command for parasite ---> host - multiple byte transfer
 JSR mathbox_command_tube_direct
 LDX host_data_register_03              ;read line ready flag
 LDA mathbox_speed                      ;arm fast/slow
 BEQ mathbox_fast_arm                   ;it be fast!
 TXA
 BMI mathbox_wait_for_line              ;loop until ready
.mathbox_fast_arm
 STA mathbox_workspace                  ;a=0, clear workspace
.mathbox_transfer_line
 LDY host_data_register_03              ;4 screen low address
 LDA host_data_register_03              ;4 screen high address
 BMI mathbox_function_exit              ;2 screen high address bit 7 = 1 then exit
 STA mathbox_workspace + &01            ;3
 LDA host_data_register_03              ;4 screen byte
 ORA (mathbox_workspace),Y              ;5
 STA (mathbox_workspace),Y              ;5
 JMP mathbox_transfer_line              ;3 = 30 cycles = 66.7kps/533.3kps min/max approx. best case
