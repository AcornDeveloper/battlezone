; line draw
; draw a line between x0, y0 and x1, y1
;
; 08 bit routine for lines within window 0,0 - 255,255 offset 32 to the right to center the window
; 16 bit routine for lines within window 0,0 - 319,255 that have been clipped and coordinates
; have been sorted ascending on the x coordinate
; 16 bit routine for lines that are guarded for out of the viewport, specifically used
; for landscape draw where clipping changes the slope of the line drawn
; using bresenham's algorithm
;
; 16 bit faster routine for lines that have been clipped to the viewport and coordinates
; have been sorted ascending on the x coordinate
;
; window x coordinates, outer/inner
; |   |     |   |
; 0   32    288 320
;
; line clipping to viewport
; setting up viewport coordinates
; screen line draw origin 0,0 at top left hand corner
; graphics window
; mode 4 window is 0, 0, &13F, &FF so define window as 0, 0, &140, &100
; left x   = x coordinate
; bottom y = y coordinate
; right x  = x coordinate
; top y    = y coordinate
;
; constants

 viewport_x_00_model                    = &20
 viewport_y_00_model                    = &20
 viewport_x_01_model                    = &120
 viewport_y_01_model                    = &E0

 viewport_x_00_game                     = &00
 viewport_y_00_game                     = &38
 viewport_x_01_game                     = &140
 viewport_y_01_game                     = &F0

 game_screen_origin_x                   = &A0
 game_screen_origin_y                   = &7E

 text_screen_origin_x                   = &A0
 text_screen_origin_y                   = &70

 model_screen_origin_x                  = &A0
 model_screen_origin_y                  = &80

; cohen-sutherland operation code for window clipping table values

MACRO cs_line_clip_immediate_x_only x0, xmin, xmax, result

 cs_clip_code_xmax_immediate x0, xmax, result
 cs_clip_code_xmin_immediate x0, xmin, result

ENDMACRO

MACRO cs_line_clip_window x0, y0, xmin, xmax, ymin, ymax, result
 LDA #&00
 STA result

 cs_clip_code_ymax_address y0, ymax, result
 cs_clip_code_ymin_address y0, ymin, result
 cs_clip_code_xmax_address x0, xmax, result
 cs_clip_code_xmin_address x0, xmin, result

ENDMACRO

MACRO cs_clip_code_xmin_address x0, x_lo, result
 LDA x0
 CMP x_lo
 LDA x0 + &01
 SBC x_lo + &01
 BVC no_eor_xmin
 EOR #&80
.no_eor_xmin
 ASL A                                  ;c=1 when a<num, c=0 a>=num
 ROL result                             ;bit 0
ENDMACRO

MACRO cs_clip_code_xmax_address x0, x_hi, result
 LDA x0
 CMP x_hi
 LDA x0 + &01
 SBC x_hi + &01
 BVS no_eor_xmax
 EOR #&80
.no_eor_xmax
 ASL A                                  ;c=0 when a < num, c=1 a>=num
 ROL result                             ;bit 1
ENDMACRO

MACRO cs_clip_code_xmin_immediate x0, xmin, result
 LDA x0
 CMP #LO(xmin)
 LDA x0 + &01
 SBC #HI(xmin)
 BVC no_eor_xmin
 EOR #&80
.no_eor_xmin
 ASL A                                  ;c=1 when a<num, c=0 a>=num
 ROL result                             ;bit 0
ENDMACRO

MACRO cs_clip_code_xmax_immediate x0, xmax, result
 LDA x0
 CMP #LO(xmax)
 LDA x0 + &01
 SBC #HI(xmax)
 BVS no_eor_xmax
 EOR #&80
.no_eor_xmax
 ASL A                                  ;c=0 when a<num, c=1 a>=num
 ROL result                             ;bit 1
ENDMACRO

MACRO cs_clip_code_ymin_address y0, y_lo, result
 LDA y0
 CMP y_lo
 LDA y0 + &01
 SBC y_lo + &01
 BVC no_eor_ymin_addr
 EOR #&80
.no_eor_ymin_addr
 ASL A                                  ;c=1 when a < num, c=0 a>=num
 ROL result                             ;bit 2
ENDMACRO

MACRO cs_clip_code_ymax_address y0, y_hi, result
 LDA y0
 CMP y_hi
 LDA y0 + &01
 SBC y_hi + &01
 BVS no_eor_ymax
 EOR #&80
.no_eor_ymax
 ASL A                                  ;c=0 when a<num, c=1 a>=num
 ROL result                             ;bit 3
ENDMACRO

.horizontal_line
 LDX graphic_x_00                       ;compare x coordinates and swap if necessary
 CPX graphic_x_01
 LDA graphic_x_00 + &01
 SBC graphic_x_01 + &01
 BCC no_swap_coors_horizontal_boundary
 LDA graphic_x_01                       ;x already has lsb x0
 STA graphic_x_00
 STX graphic_x_01
 LDA graphic_x_00 + &01                 ;swap x0, x1
 LDX graphic_x_01 + &01
 STA graphic_x_01 + &01
 STX graphic_x_00 + &01
 CLC
.no_swap_coors_horizontal_boundary
 LDY graphic_y_00                       ;start cell address
 LDA graphic_x_00
 AND #&F8
 ADC screen_access_y_lo,Y
 STA graphic_video
 LDA graphic_x_00 + &01
 ADC screen_access_y_hi,Y
 ADC screen_hidden
 STA graphic_video + &01
 LDY #&00                               ;index set up
 LDA graphic_x_00
 AND #&07
 TAX
 LDA pixel_mask,X                       ;line start
 STA graphic_accumulator
 LDA graphic_x_01                       ;calculate horizontal line length
 SEC
 SBC graphic_x_00
 TAX
.short_pixel_loop
 LDA (graphic_video),Y
 ORA graphic_accumulator
 STA (graphic_video),Y
 LSR graphic_accumulator
 BCS horizontal_next_column             ;hit a byte boundary?
 DEX
 BNE short_pixel_loop
 RTS                                    ;short line done
.horizontal_next_column
 LDY #&08                               ;next cell
 CPX #&08
 BCC horizontal_tail
.horizontal_boundary_loop               ;write 8 pixels at a time until less than 8 to write
 LDA #&FF                               ;write 8 pixels
 STA (graphic_video),Y
 TYA                                    ;next cell
 CLC
 ADC #&08
 TAY
 TXA                                    ;subtract 8 from length
 SBC #&07                               ;c=0
 BEQ horizontal_finished                ;line ends on a boundary so exit
 TAX
 CPX #&08
 BCS horizontal_boundary_loop           ;another 8 pixels
.horizontal_tail                        ;1-7 pixels in length starts on a byte boundary
 LDA (graphic_video),Y
 ORA short_horizontal - &01,X
 STA (graphic_video),Y
.horizontal_finished
 RTS

.short_horizontal
 EQUB &80
 EQUB &C0
 EQUB &E0
 EQUB &F0
 EQUB &F8
 EQUB &FC
 EQUB &FE

.vertical_line                          ;draw a vertical line
 LDA graphic_x_00
 AND #&07                               ;get pixel mask
 TAX
 LDA pixel_mask,X
 STA vertical_pixel + &01
 LDA graphic_y_00                       ;which y coordinate smallest?
 CMP graphic_y_01
 BCC correct_vertical
 LDY graphic_y_01                       ;swap y coordinates
 STA graphic_y_01
 STY graphic_y_00
 TYA
.correct_vertical
 TAY
 AND #&F8                               ;get row/column start address
 TAX
 LDA graphic_x_00
 AND #&F8
 CLC
 ADC screen_access_y_lo,X
 STA graphic_video
 LDA screen_access_y_hi,X
 ADC graphic_x_00 + &01
 ADC screen_hidden
 STA graphic_video + &01
 TYA                                    ;offset into column
 AND #&07
 TAY
 LDA graphic_y_01                       ;number of pixels
 SEC
 SBC graphic_y_00
 TAX
.vertical
 LDA (graphic_video),Y
.vertical_pixel
 ORA #&00
 STA (graphic_video),Y
 INY
 CPY #&08
 BEQ cross_row
 DEX
 BNE vertical
 RTS
.cross_row
 LDY #&00                               ;reset index and goto next row
 LDA graphic_video
 ADC #LO(screen_row - &01)              ;c=1
 STA graphic_video
 LDA graphic_video + &01
 ADC #HI(screen_row - &01)
 STA graphic_video + &01
 DEX
 BNE vertical
 RTS

.line_draw_08_6502
 LDA graphic_x_00                       ;check for zero length x line
 CMP graphic_x_01
 BNE b08_unequal
 LDY graphic_y_00
 CPY graphic_y_01                       ;check for zero length y line
 BNE vertical_line
 RTS
.b08_unequal
 LDY graphic_y_00
 CPY graphic_y_01                       ;check for z
 BNE b08_not_horizontal
 JMP horizontal_line
.b08_not_horizontal
 LDA graphic_x_00
 SEC
 SBC #&20
 STA graphic_x_00
 LDA graphic_x_01
 SEC
 SBC #&20
 STA graphic_x_01
 LDA #&80
 STA graphic_video
 LDA graphic_y_00
 AND #&F8
 LSR A
 LSR A
 LSR A
 STA graphic_video + &01
 LSR A
 ROR graphic_video
 LSR A
 ROR graphic_video
 ADC graphic_video + &01
 ADC screen_hidden
 STA graphic_video + &01
 LDA graphic_x_00
 AND #&F8
 CLC
 ADC graphic_video
 STA graphic_video
 BCC b08_no_inc_video_one
 INC graphic_video + &01
.b08_no_inc_video_one
 LDA graphic_y_00
 AND #&07
 TAY
 LDA graphic_x_00
 AND #&07
 TAX
 LDA graphic_x_00
 SEC
 SBC graphic_x_01
 BCS b08_positive_dx
 EOR #&FF
 ADC #&01                               ;c=0
.b08_positive_dx
 STA graphic_dx
 PHP
 LDA graphic_y_00
 SEC
 SBC graphic_y_01
 BCS b08_positive_dy                    ;c=0
 EOR #&FF
 ADC #&01                               ;c=0
.b08_positive_dy
 STA graphic_dy
 PHP
 ORA graphic_dx
 BEQ b08_exit_line
 LDA graphic_dy
 CMP graphic_dx
 BCS b08_steep_line
 JMP b08_shallow_line
.b08_steep_line
 PLP
 LDA #b08_going_down - b08_branch_up_down - &02
 BCC b08_branch_carry_clear_one
 LDA #b08_going_up - b08_branch_up_down - &02
.b08_branch_carry_clear_one
 STA b08_branch_up_down + &01
 PLP
 LDA #b08_going_right - b08_branch_left_right - &02
 BCC b08_branch_carry_clear_two
 LDA #b08_going_left - b08_branch_left_right - &02
.b08_branch_carry_clear_two
 STA b08_branch_left_right + &01
 LDA graphic_dy
 STA graphic_count
 INC graphic_count
 LSR A
.b08_steep_line_loop
 STA graphic_accumulator
.b08_steep_line_loop_two
 LDA (graphic_video),Y
 ORA pixel_mask,X
 STA (graphic_video),Y
 DEC graphic_count
.b08_branch_up_down
 BNE b08_branch_up_down                 ;self-modified to going down or going up
.b08_exit_line
 RTS
.b08_going_up
 DEY
 BPL b08_move_to_next_column
 LDA graphic_video
 SEC
 SBC #LO(screen_row)
 STA graphic_video
 LDA graphic_video + &01
 SBC #HI(screen_row)
 STA graphic_video + &01
 LDY #&07
 BNE b08_move_to_next_column	        ;always
.b08_going_down
 INY
 CPY #&08
 BCC b08_move_to_next_column
 LDA graphic_video
 ADC #LO(screen_row - &01)              ;use video size - 1 as c=1
 STA graphic_video
 LDA graphic_video + &01
 ADC #HI(screen_row - &01)
 STA graphic_video + &01
 LDY #&00
.b08_move_to_next_column
 LDA graphic_accumulator
 SEC
 SBC graphic_dx
 BCS b08_steep_line_loop
 ADC graphic_dy
.b08_branch_left_right
 BCS b08_branch_left_right			    ;self-modified to going right or going left
.b08_going_left
 DEX
 BPL b08_steep_line_loop
 STA graphic_accumulator
 LDA graphic_video
 SBC #&08					            ;c=1
 STA graphic_video
 BCS b08_no_dec_video
 DEC graphic_video + &01
.b08_no_dec_video
 LDX #&07
 BNE b08_steep_line_loop_two		    ;always
.b08_going_right
 INX
 CPX #&08
 BCC b08_steep_line_loop
 STA graphic_accumulator
 LDA graphic_video
 ADC #&07
 STA graphic_video
 BCC b08_no_inc_video_two
 INC graphic_video + &01
.b08_no_inc_video_two
 LDX #&00
 BEQ b08_steep_line_loop_two		    ;always
.b08_shallow_line
 PLP
 LDA #b08_going_down_two - b08_branch_up_down_two - &02
 BCC b08_choose_one
 LDA #b08_going_up_two - b08_branch_up_down_two - &02
.b08_choose_one
 STA b08_branch_up_down_two + &01
 PLP
 LDA #b08_going_right_two - b08_branch_left_right_two - &02
 BCC b08_choose_two
 LDA #b08_going_left_two - b08_branch_left_right_two - &02
.b08_choose_two
 STA b08_branch_left_right_two + &01
 LDA graphic_dx
 STA graphic_count
 INC graphic_count
 LSR A
 STA graphic_accumulator
.b08_shallow_line_loop
 LDA (graphic_video),Y
.b08_shallow_line_loop_two
 ORA pixel_mask,X
 DEC graphic_count                      ;check if done
.b08_branch_left_right_two
 BNE b08_branch_left_right_two			;self-modified to going left two or going right two
 STA (graphic_video),Y
 RTS
.b08_going_left_two                     ;move left to next pixel column
 DEX
 BPL b08_move_to_next_line
 STA (graphic_video),Y			        ;store cached byte, advance screen address, and cache new byte
 LDA graphic_video
 SEC
 SBC #&08
 STA graphic_video
 BCS b08_no_dec_video_two
 DEC graphic_video + &01
.b08_no_dec_video_two
 LDA (graphic_video),Y
 LDX #&07
 BNE b08_move_to_next_line		        ;always
.b08_going_right_two	                ;move right to next pixel column
 INX
 CPX #&08
 BCC b08_move_to_next_line
 STA (graphic_video),Y
 LDA graphic_video
 ADC #&07                               ;c=1
 STA graphic_video
 BCC b08_no_inc_video_three
 INC graphic_video + &01
.b08_no_inc_video_three
 LDA (graphic_video),Y
 LDX #&00
.b08_move_to_next_line                  ;check whether we move to the next line
 STA graphic_store
 LDA graphic_accumulator
 SEC
 SBC graphic_dy
.b08_branch_up_down_two
 BCC b08_branch_up_down_two			    ;self-modified to going down two or going up two
 STA graphic_accumulator
 LDA graphic_store
 BCS b08_shallow_line_loop_two	        ;always
.b08_going_down_two	                    ;move down to next line
 ADC graphic_dx
 STA graphic_accumulator                ;store new graphic accumulator
 LDA graphic_store
 STA (graphic_video),Y
 INY
 CPY #&08
 BCC b08_shallow_line_loop
 LDA graphic_video
 ADC #LO(screen_row - &01)              ;use video size - 1 as c=1
 STA graphic_video
 LDA graphic_video + &01
 ADC #HI(screen_row - &01)
 STA graphic_video + &01
 LDY #&00
 BEQ b08_shallow_line_loop		        ;always
.b08_going_up_two
 ADC graphic_dx
 STA graphic_accumulator
 LDA graphic_store
 STA (graphic_video),Y
 DEY
 BPL b08_shallow_line_loop
 LDA graphic_video
 SEC
 SBC #LO(screen_row)
 STA graphic_video
 LDA graphic_video + &01
 SBC #HI(screen_row)
 STA graphic_video + &01
 LDY #&07
 BNE b08_shallow_line_loop		        ;always

.pixel_mask
 EQUD &10204080
 EQUD &01020408

.double_pixel_mask
 EQUD &183060C0
 EQUD &0303060C

.line_draw_16_6502
 LDY #&00
 STY graphic_line_leave                 ;plot point flag
 LDX graphic_x_00
 CPX graphic_x_01
 LDA graphic_x_00 + &01
 SBC graphic_x_01 + &01
 BVC b16_01_no_eor
 EOR #&80
.b16_01_no_eor
 BMI b16_01_no_swap_coors
 LDA graphic_x_01                       ;x already has lsb x0
 STA graphic_x_00
 STX graphic_x_01
 LDA graphic_x_00 + &01                 ;swap x0, x1, y0, y1
 LDX graphic_x_01 + &01
 STA graphic_x_01 + &01
 STX graphic_x_00 + &01
 LDA graphic_y_00
 LDX graphic_y_01
 STA graphic_y_01
 STX graphic_y_00
 LDA graphic_y_00 + &01
 LDX graphic_y_01 + &01
 STA graphic_y_01 + &01
 STX graphic_y_00 + &01
.b16_01_no_swap_coors
 LDA graphic_x_01                       ;dx = x2 - x1 (+ve because of swap)
 SEC
 SBC graphic_x_00
 STA graphic_dx
 LDA graphic_x_01 + &01
 SBC graphic_x_00 + &01
 STA graphic_dx + &01
 LDX #&01                               ;x = 1, y = 0
 LDA graphic_y_01                       ;dy = abs(y2 - y1)
 SEC
 SBC graphic_y_00
 STA graphic_dy
 LDA graphic_y_01 + &01
 SBC graphic_y_00 + &01
 STA graphic_dy + &01
 BPL b16_01_dy_positive
 TYA                                    ;+dy
 SEC
 SBC graphic_dy
 STA graphic_dy
 TYA
 SBC graphic_dy + &01
 STA graphic_dy + &01
 LDX #&FF
 DEY                                    ;y = &ff
.b16_01_dy_positive
 STX graphic_y_sign
 STY graphic_y_sign + &01
 LDX graphic_dx                         ;compare dx with dy
 CPX graphic_dy
 LDA graphic_dx + &01
 SBC graphic_dy + &01
 BCC b16_01_dx_less_than_dy
 LDA graphic_dx + &01                   ;e = dx / 2, y = graphic_dx + &01
 LSR A
 STA graphic_accumulator + &01
 TXA                                    ;x  = graphic_dx
 ROR A
 STA graphic_accumulator
.b16_01_loop
 LDA graphic_x_00 + &01
 LDX graphic_x_00
 CPX #LO(screen_row)                    ;test x screen coordinate
 SBC #HI(screen_row)
 BCS b16_01_do_not_plot_point
 LDY graphic_y_00
 TXA                                    ;x = graphic_x_00
 AND #&F8
 CLC
 ADC screen_access_y_lo,Y
 STA graphic_video
 LDA graphic_x_00 + &01
 ADC screen_access_y_hi,Y
 ADC screen_hidden
 STA graphic_video + &01
 STA graphic_line_leave                 ;plot flag
 TXA                                    ;x = graphic_x_00
 AND #&07
 TAX                                    ;bit mask
 LDY #&00
 LDA (graphic_video),Y
 ORA pixel_mask,X
 STA (graphic_video),Y
 BNE b16_01_inc_x                       ;always
.b16_01_line_exit
 RTS
.b16_01_do_not_plot_point
 LDA graphic_line_leave                 ;<>0 draw flag, now leave
 BNE b16_01_line_exit
.b16_01_inc_x
 LDA graphic_x_00 + &01                 ;x major axis
 CMP graphic_x_01 + &01
 BNE b16_02_x_still_on
 LDX graphic_x_00
 CPX graphic_x_01
 BEQ b16_01_line_exit                   ;plotted last point
.b16_02_x_still_on
 INC graphic_x_00                       ;x++
 BNE b16_01_no_inc_graphic_x
 INC graphic_x_00 + &01
.b16_01_no_inc_graphic_x
 LDA graphic_accumulator                ;e = e - dy
 SEC
 SBC graphic_dy
 STA graphic_accumulator
 LDA graphic_accumulator + &01
 SBC graphic_dy + &01
 STA graphic_accumulator + &01
 BPL b16_01_loop
 LDA graphic_accumulator                ;e = e + dx
 CLC
 ADC graphic_dx
 STA graphic_accumulator
 LDA graphic_accumulator + &01
 ADC graphic_dx + &01
 STA graphic_accumulator + &01
 LDA graphic_y_00
 CLC
 ADC graphic_y_sign
 STA graphic_y_00
 LDA graphic_y_00 + &01
 ADC graphic_y_sign + &01
 STA graphic_y_00 + &01
 JMP b16_01_loop

.b16_01_dx_less_than_dy
 LDA graphic_dy + &01                   ;e = dy / 2
 LSR A
 STA graphic_accumulator + &01
 LDA graphic_dy
 ROR A
 STA graphic_accumulator
.b16_02_loop
 LDX graphic_x_00                       ;test x coordinate
 CPX #LO(screen_row)
 LDA graphic_x_00 + &01
 SBC #HI(screen_row)
 BCS b16_02_do_not_plot_point
 LDY graphic_y_00
 TXA                                    ;x = graphic_x_00
 AND #&F8
 CLC
 ADC screen_access_y_lo,Y               ;y = graphic_y_00
 STA graphic_video
 LDA graphic_x_00 + &01
 ADC screen_access_y_hi,Y
 ADC screen_hidden
 STA graphic_video + &01
 STA graphic_line_leave                 ;plot flag
 TXA                                    ;x = graphic_x_00
 AND #&07
 TAX                                    ;bit mask
 LDA pixel_mask,X
 LDX #&00
 ORA (graphic_video,X)
 STA (graphic_video,X)
 BNE b16_02_inc_x                       ;always
.b16_02_do_not_plot_point
 LDA graphic_line_leave                 ;<>0 draw flag, now leave
 BNE c16_01_line_exit
.b16_02_inc_x
 LDA graphic_y_00                       ;compare y0, y1
 CMP graphic_y_01
 BNE b16_01_y_still_on                  ;plotted last point
 LDY graphic_y_00 + &01                 ;y major axis
 CPY graphic_y_01 + &01
 BEQ c16_01_line_exit
.b16_01_y_still_on
 CLC                                    ;y = y + y_sign, a = graphic_y_00
 ADC graphic_y_sign
 STA graphic_y_00
 LDA graphic_y_00 + &01
 ADC graphic_y_sign + &01
 STA graphic_y_00 + &01
 LDA graphic_accumulator                ;e = e - dx
 SEC
 SBC graphic_dx
 STA graphic_accumulator
 LDA graphic_accumulator + &01
 SBC graphic_dx + &01
 STA graphic_accumulator + &01
 BPL b16_02_loop
 LDA graphic_accumulator                ;e = e + dy
 CLC
 ADC graphic_dy
 STA graphic_accumulator
 LDA graphic_accumulator + &01
 ADC graphic_dy + &01
 STA graphic_accumulator + &01
 INC graphic_x_00                       ;x = x + 1
 BNE b16_02_loop
 INC graphic_x_00 + &01
 JMP b16_02_loop

.c16_01_line_exit
 RTS
.line_draw_16c_6502
 LDY #&00
 LDX graphic_x_00
 LDA graphic_x_01                       ;dx always +ve because of swap
 SEC
 SBC graphic_x_00
 STA graphic_dx
 LDA graphic_x_01 + &01
 SBC graphic_x_00 + &01
 STA graphic_dx + &01
 LDX #&01                               ;x = 1, y = 0
 LDA graphic_y_01                       ;dy = abs(y2 - y1)
 SEC
 SBC graphic_y_00
 STA graphic_dy
 LDA graphic_y_01 + &01
 SBC graphic_y_00 + &01
 STA graphic_dy + &01
 BPL c16_01_dy_positive
 TYA                                    ;+dy
 SEC
 SBC graphic_dy
 STA graphic_dy
 TYA
 SBC graphic_dy + &01
 STA graphic_dy + &01
 LDX #&FF
 DEY                                    ;y = &ff
.c16_01_dy_positive
 STX graphic_y_sign
 STY graphic_y_sign + &01
 LDX graphic_dx                         ;compare dx with dy
 CPX graphic_dy
 LDA graphic_dx + &01
 SBC graphic_dy + &01
 BCC c16_01_dx_less_than_dy
 LDA graphic_dx + &01                   ;e = dx/2, y = graphic_dx + &01
 LSR A
 STA graphic_accumulator + &01
 TXA                                    ;x  = graphic_dx
 ROR A
 STA graphic_accumulator
.c16_01_loop
 LDX graphic_x_00
 LDY graphic_y_00
 TXA                                    ;x = graphic_x_00
 AND #&F8
 CLC
 ADC screen_access_y_lo,Y
 STA graphic_video
 LDA graphic_x_00 + &01
 ADC screen_access_y_hi,Y
 ADC screen_hidden
 STA graphic_video + &01
 TXA                                    ;x = graphic_x_00
 AND #&07
 TAX                                    ;bit mask
 LDY #&00
 LDA (graphic_video),Y
 ORA pixel_mask,X
 STA (graphic_video),Y
 LDA graphic_x_00 + &01                 ;x major axis
 CMP graphic_x_01 + &01
 BNE c16_02_x_still_on
 LDX graphic_x_00
 CPX graphic_x_01
 BEQ c16_01_line_exit                   ;plotted last point
.c16_02_x_still_on
 INC graphic_x_00                       ;x++
 BNE c16_01_no_inc_graphic_x
 INC graphic_x_00 + &01
.c16_01_no_inc_graphic_x
 LDA graphic_accumulator                ;e = e - dy
 SEC
 SBC graphic_dy
 STA graphic_accumulator
 LDA graphic_accumulator + &01
 SBC graphic_dy + &01
 STA graphic_accumulator + &01
 BPL c16_01_loop
 LDA graphic_accumulator                ;e = e + dx
 CLC
 ADC graphic_dx
 STA graphic_accumulator
 LDA graphic_accumulator + &01
 ADC graphic_dx + &01
 STA graphic_accumulator + &01
 LDA graphic_y_00
 CLC
 ADC graphic_y_sign
 STA graphic_y_00
 LDA graphic_y_00 + &01
 ADC graphic_y_sign + &01
 STA graphic_y_00 + &01
 JMP c16_01_loop
.c16_01_dx_less_than_dy
 LDA graphic_dy + &01                   ;e = dy/2
 LSR A
 STA graphic_accumulator + &01
 LDA graphic_dy
 ROR A
 STA graphic_accumulator
.c16_02_loop
 LDX graphic_x_00
 LDY graphic_y_00
 TXA                                    ;x = graphic_x_00
 AND #&F8
 CLC
 ADC screen_access_y_lo,Y               ;y = graphic_y_00
 STA graphic_video
 LDA graphic_x_00 + &01
 ADC screen_access_y_hi,Y
 ADC screen_hidden
 STA graphic_video + &01
 TXA                                    ;x = graphic_x_00
 AND #&07
 TAX                                    ;bit mask
 LDY #&00
 LDA (graphic_video),Y
 ORA pixel_mask,X
 STA (graphic_video),Y
 LDA graphic_y_00
 CMP graphic_y_01
 BNE c16_01_y_still_on                  ;plotted last point
 LDY graphic_y_00 + &01                 ;y major axis
 CPY graphic_y_01 + &01
 BEQ c16_02_line_exit
.c16_01_y_still_on
 CLC                                    ;y = y + y_sign, a = graphic_y_00
 ADC graphic_y_sign
 STA graphic_y_00
 LDA graphic_y_00 + &01
 ADC graphic_y_sign + &01
 STA graphic_y_00 + &01
 LDA graphic_accumulator                ;e = e - dx
 SEC
 SBC graphic_dx
 STA graphic_accumulator
 LDA graphic_accumulator + &01
 SBC graphic_dx + &01
 STA graphic_accumulator + &01
 BPL c16_02_loop
 LDA graphic_accumulator                ;e = e + dx
 CLC
 ADC graphic_dy
 STA graphic_accumulator
 LDA graphic_accumulator + &01
 ADC graphic_dy + &01
 STA graphic_accumulator + &01
 INC graphic_x_00                       ;x = x + 1
 BNE c16_02_loop
 INC graphic_x_00 + &01
 JMP c16_02_loop
.c16_02_line_exit
 RTS

.screen_access_y_lo
 FOR number, 0, 255
   EQUB LO(((number DIV 8) * screen_row) + (number AND &07))
 NEXT
.screen_access_y_hi
 FOR number, 0, 255
   EQUB HI(((number DIV 8) * screen_row) + (number AND &07))
 NEXT

.line_clip_16_6502                      ;clip line to viewport
 LDX graphic_x_00
 CPX graphic_x_01
 LDA graphic_x_00 + &01
 SBC graphic_x_01 + &01
 BVC swap_no_eor
 EOR #&80
.swap_no_eor
 BMI full_cs_test
 LDA graphic_x_01                       ;x already has lsb x0
 STA graphic_x_00
 STX graphic_x_01
 LDA graphic_x_00 + &01                 ;swap x0/x1, y0/y1
 LDX graphic_x_01 + &01
 STA graphic_x_01 + &01
 STX graphic_x_00 + &01
 LDA graphic_y_00
 LDX graphic_y_01
 STA graphic_y_01
 STX graphic_y_00
 LDA graphic_y_00 + &01
 LDX graphic_y_01 + &01
 STA graphic_y_01 + &01
 STX graphic_y_00 + &01
.full_cs_test

 cs_line_clip_window graphic_x_00, graphic_y_00, window_x_00, window_x_01, window_y_00, window_y_01, cs_value_00
 cs_line_clip_window graphic_x_01, graphic_y_01, window_x_00, window_x_01, window_y_00, window_y_01, cs_value_01

 LDA cs_value_00
 ORA cs_value_01
 BEQ line_segment_visible               ;line within viewport
 LDA cs_value_00
 AND cs_value_01
 BNE line_segment_invisible             ;line outside of viewport
 LSR cs_value_00                        ;check x0 minimum, test bit 0
 BCC no_clip_left_x
 JSR min_x_clip
 JMP full_cs_test
.no_clip_left_x
 LDA cs_value_01                        ;check x1 maximum
 AND #&02
 BEQ no_clip_right_x
 JSR max_x_clip
 JMP full_cs_test
.no_clip_right_x
 LDA cs_value_00                        ;check y0 minimum
 AND #&04 >> &01
 BEQ no_clip_bottom_y0
 JSR min_y_clip_y0
 JMP full_cs_test
.no_clip_bottom_y0
 LDA cs_value_01                        ;check y1 minimum
 AND #&04
 BEQ no_clip_bottom_y1
 JSR min_y_clip_y1
 JMP full_cs_test
.no_clip_bottom_y1
 LDA cs_value_00                        ;check y0 maximum
 AND #&08 >> &01
 BEQ no_clip_top_y0
 JSR max_y_clip_y0
 JMP full_cs_test
.no_clip_top_y0
 LDA cs_value_01                        ;check y1 maximum
 AND #&08
 BEQ no_clip_top_y1
 JSR max_y_clip_y1
.no_clip_top_y1
 JMP full_cs_test
.line_segment_invisible
 SEC
 RTS

.line_segment_visible                   ;line within larger clip window

 cs_line_clip_immediate_x_only graphic_x_00, 32, 288, cs_value_00
 cs_line_clip_immediate_x_only graphic_x_01, 32, 288, cs_value_01

 LDA cs_value_00                        ;test for inner window
 ORA cs_value_01                        ;z=1
 CLC                                    ;c=0
 RTS

.min_x_clip                             ;x0 is left of viewport
 LDA graphic_y_01                       ;x = xmin
 SEC                                    ;y = y0 + (y1 - y0) * (xmin - x0) / (x1 - x0)
 SBC graphic_y_00
 STA multiplier_16
 LDA graphic_y_01 + &01
 SBC graphic_y_00 + &01
 STA multiplier_16 + &01
 LDA window_x_00
 SEC
 SBC graphic_x_00
 STA multiplicand_16
 LDA window_x_00 + &01
 SBC graphic_x_00 + &01
 STA multiplicand_16 + &01
 JSR mathbox_multiplication16
 LDA graphic_x_01
 SEC
 SBC graphic_x_00
 STA divisor_24
 LDA graphic_x_01 + &01
 SBC graphic_x_00 + &01
 STA divisor_24 + &01
 ASL A
 LDA #&00
 ADC #&FF
 EOR #&FF
 STA divisor_24 + &02
 JSR mathbox_division24
 LDA graphic_y_00
 CLC
 ADC division_result_24
 STA graphic_y_00
 LDA graphic_y_00 + &01
 ADC division_result_24 + &01
 STA graphic_y_00 + &01
 LDA window_x_00                        ;copy viewport left x
 STA graphic_x_00                       ;to main x
 LDA window_x_00 + &01
 STA graphic_x_00 + &01
 RTS

.max_x_clip                             ;x1 is right of viewport
 LDA graphic_y_01                       ;x = xmax
 SEC                                    ;y = y0 + (y1 - y0) * (xmax - x0) / (x1 - x0)
 SBC graphic_y_00
 STA multiplier_16
 LDA graphic_y_01 + &01
 SBC graphic_y_00 + &01
 STA multiplier_16 + &01
 LDY window_x_01 + &01                  ;copy viewport right x
 LDX window_x_01                        ;to main x
 BNE max_x_clip_00
 DEY
.max_x_clip_00
 DEX
 TXA
 SEC
 SBC graphic_x_00
 STA multiplicand_16
 TYA
 SBC graphic_x_00 + &01
 STA multiplicand_16 + &01
 JSR mathbox_multiplication16
 LDA graphic_x_01
 SEC
 SBC graphic_x_00
 STA divisor_24
 LDA graphic_x_01 + &01
 SBC graphic_x_00 + &01
 STA divisor_24 + &01
 ASL A
 LDA #&00
 ADC #&FF
 EOR #&FF
 STA divisor_24 + &02
 JSR mathbox_division24
 LDA graphic_y_00
 CLC
 ADC division_result_24
 STA graphic_y_01
 LDA graphic_y_00 + &01
 ADC division_result_24 + &01
 STA graphic_y_01 + &01
 LDY window_x_01 + &01                  ;copy viewport right x
 LDX window_x_01                        ;to main x
 BNE max_x_clip_01
 DEY
.max_x_clip_01
 DEX
 STX graphic_x_01
 STY graphic_x_01 + &01
 RTS

.min_y_clip_y0                          ;y0 is to bottom of viewport
 JSR common_y_clip_bottom
 STA graphic_x_00
 LDA graphic_x_00 + &01
 ADC division_result_24 + &01
 STA graphic_x_00 + &01
 LDA window_y_00                        ;copy viewport bottom y
 STA graphic_y_00                       ;to main y
 LDA window_y_00 + &01
 STA graphic_y_00 + &01
 RTS

.common_y_clip_bottom
 LDA graphic_x_01                       ;x = x0 + (x1 - x0) * (ymin - y0) / (y1 - y0)
 SEC                                    ;y = ymin
 SBC graphic_x_00
 STA multiplier_16
 LDA graphic_x_01 + &01
 SBC graphic_x_00 + &01
 STA multiplier_16 + &01
 LDA window_y_00
 SEC
 SBC graphic_y_00
 STA multiplicand_16
 LDA window_y_00 + &01
 SBC graphic_y_00 + &01
 STA multiplicand_16 + &01
 JSR mathbox_multiplication16
 LDA graphic_y_01
 SEC
 SBC graphic_y_00
 STA divisor_24
 LDA graphic_y_01 + &01
 SBC graphic_y_00 + &01
 STA divisor_24 + &01
 ASL A
 LDA #&00
 ADC #&FF
 EOR #&FF
 STA divisor_24 + &02
 JSR mathbox_division24
 LDA graphic_x_00
 CLC
 ADC division_result_24
 RTS

.min_y_clip_y1                          ;y1 is to bottom of viewport
 JSR common_y_clip_bottom
 STA graphic_x_01
 LDA graphic_x_00 + &01
 ADC division_result_24 + &01
 STA graphic_x_01 + &01
 LDA window_y_00                        ;copy viewport bottom y
 STA graphic_y_01                       ;to main y
 LDA window_y_00 + &01
 STA graphic_y_01 + &01
 RTS

.max_y_clip_y0                          ;y0 is to top of viewport
 JSR common_y_clip_top
 STA graphic_x_00
 LDA graphic_x_00 + &01
 ADC division_result_24 + &01
 STA graphic_x_00 + &01
 LDY window_y_01 + &01                  ;copy viewport top y
 LDX window_y_01                        ;to main y
 BNE max_y_clip_01
 DEY
.max_y_clip_01
 DEX
 STX graphic_y_00
 STY graphic_y_00 + &01
 RTS

.common_y_clip_top
 LDA graphic_x_01                       ;x = x0 + (x1 - x0) * (ymax - y0) / (y1 - y0)
 SEC                                    ;y = ymax
 SBC graphic_x_00
 STA multiplier_16
 LDA graphic_x_01 + &01
 SBC graphic_x_00 + &01
 STA multiplier_16 + &01
 LDA window_y_01
 SEC
 SBC graphic_y_00
 STA multiplicand_16
 LDA window_y_01 + &01
 SBC graphic_y_00 + &01
 STA multiplicand_16 + &01
 JSR mathbox_multiplication16
 LDA graphic_y_01
 SEC
 SBC graphic_y_00
 STA divisor_24
 LDA graphic_y_01 + &01
 SBC graphic_y_00 + &01
 STA divisor_24 + &01
 ASL A
 LDA #&00
 ADC #&FF
 EOR #&FF
 STA divisor_24 + &02
 JSR mathbox_division24
 LDA graphic_x_00
 CLC
 ADC division_result_24
 RTS

.max_y_clip_y1                          ;y1 is to top of viewport
 JSR common_y_clip_top
 STA graphic_x_01
 LDA graphic_x_00 + &01
 ADC division_result_24 + &01
 STA graphic_x_01 + &01
 LDY window_y_01 + &01                  ;copy viewport top y
 LDX window_y_01                        ;to main y
 BNE max_y_clip_02
 DEY
.max_y_clip_02
 DEX
 STX graphic_y_01
 STY graphic_y_01 + &01
 RTS

.game_window_coordinates                ;two graphic windows for game/model
 EQUW viewport_x_00_game
 EQUW viewport_y_00_game
 EQUW viewport_x_01_game
 EQUW viewport_y_01_game

.model_window_coordinates
 EQUW viewport_x_00_model
 EQUW viewport_y_00_model
 EQUW viewport_x_01_model
 EQUW viewport_y_01_model

.model_window
 LDX #LO(model_window_coordinates)
 LDY #HI(model_window_coordinates)
 JMP mathbox_window_16

.game_window
 LDX #LO(game_window_coordinates)
 LDY #HI(game_window_coordinates)
 JMP mathbox_window_16

.game_origin_coordinates
 EQUW game_screen_origin_x
 EQUW game_screen_origin_y

.text_origin_coordinates
 EQUW text_screen_origin_x
 EQUW text_screen_origin_y

.model_origin_coordinates
 EQUW model_screen_origin_x
 EQUW model_screen_origin_y

.graphics_origin_game
 LDX #LO(game_origin_coordinates)
 LDY #HI(game_origin_coordinates)
 BNE graphics_origin

.graphics_origin_text
 LDX #LO(text_origin_coordinates)
 LDY #HI(text_origin_coordinates)
 BNE graphics_origin

.graphics_origin_model
 LDX #LO(model_origin_coordinates)
 LDY #HI(model_origin_coordinates)

.graphics_origin
 STX origin_address
 STY origin_address + &01
 LDY #&03
.graphics_origin_setup
 LDA (origin_address),Y
 STA graphic_x_origin,Y
 DEY
 BPL graphics_origin_setup
 RTS
