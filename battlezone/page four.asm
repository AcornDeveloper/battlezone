; constants
 block_size                             = &08
 vertices_number                        = &1A

; addresses
 PRINT " page four : ", ~vertices_x_lsb,   "vertice start"
 PRINT "           : ", ~object_workspace, "object workspace"
 PRINT "           : ", ~object_start,     "object start"
 PRINT "           : ", ~page_four_end,    "page four end"
 PRINT ""

.vertices_x_lsb                         SKIP vertices_number
.vertices_x_msb                         SKIP vertices_number
.vertices_y_lsb                         SKIP vertices_number
.vertices_y_msb                         SKIP vertices_number
.vertices_z_lsb                         SKIP vertices_number
.vertices_z_msb                         SKIP vertices_number

MACRO object id, angle, xcr, ycr, zcr
 EQUB id                                ;+00 identity
 EQUB angle                             ;+01 object y axis rotation
 EQUW xcr                               ;+02 object x coordinate
 EQUW ycr                               ;+04 object y coordinate
 EQUW zcr                               ;+06 object z coordinate
ENDMACRO

MACRO object_workspace visible, xwork, ywork, zwork
 EQUW visible                           ;+00 visible
 EQUW xwork                             ;+02 object x work
 EQUW ywork                             ;+04 object y work
 EQUW zwork                             ;+06 object z work
ENDMACRO

.object_workspace                       ;object workspace
 object_workspace &FF, &00, &FF, &00    ;x +&02/&03 rotated around my tank, full value
 object_workspace &FF, &00, &FF, &00    ;z +&06/&07 rotated around my tank, half value
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00

.object_workspace_collision
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00

.object_workspace_animated
 object_workspace &FF, &00, &FF, &00    ;object_animated_workspace
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00
 object_workspace &FF, &00, &FF, &00

.object_saucer_workspace
 object_workspace &FF, &00, &FF, &00

.object_tank_or_super_or_missile_workspace
 object_workspace &FF, &00, &FF, &00

.object_start                           ;short cubes are not checked by my shot/enemy shot collision
 object object_x02_short_cube,     &10, obstacle_x_01, &00, obstacle_z_01
 object object_x02_short_cube,     &40, obstacle_x_03, &00, obstacle_z_03
 object object_x02_short_cube,     &48, obstacle_x_09, &00, obstacle_z_09
 object object_x02_short_cube,     &68, obstacle_x_0D, &00, obstacle_z_0D
 object object_x02_short_cube,     &88, obstacle_x_11, &00, obstacle_z_11

.object_shot_collision_start
 object object_x00_narrow_pyramid, &28, obstacle_x_05, &00, obstacle_z_05
 object object_x00_narrow_pyramid, &38, obstacle_x_07, &00, obstacle_z_07
 object object_x00_narrow_pyramid, &58, obstacle_x_0B, &00, obstacle_z_0B
 object object_x00_narrow_pyramid, &78, obstacle_x_0F, &00, obstacle_z_0F
 object object_x00_narrow_pyramid, &98, obstacle_x_13, &00, obstacle_z_13
 object object_x01_tall_cube,      &30, obstacle_x_06, &00, obstacle_z_06
 object object_x01_tall_cube,      &40, obstacle_x_08, &00, obstacle_z_08
 object object_x01_tall_cube,      &60, obstacle_x_0C, &00, obstacle_z_0C
 object object_x01_tall_cube,      &80, obstacle_x_10, &00, obstacle_z_10
 object object_x01_tall_cube,      &A0, obstacle_x_14, &00, obstacle_z_14
 object object_x03_wide_pyramid,   &00, obstacle_x_00, &00, obstacle_z_00
 object object_x03_wide_pyramid,   &18, obstacle_x_04, &00, obstacle_z_04
 object object_x03_wide_pyramid,   &20, obstacle_x_02, &00, obstacle_z_02
 object object_x03_wide_pyramid,   &50, obstacle_x_0A, &00, obstacle_z_0A
 object object_x03_wide_pyramid,   &70, obstacle_x_0E, &00, obstacle_z_0E
 object object_x03_wide_pyramid,   &90, obstacle_x_12, &00, obstacle_z_12
.object_shot_collision_end

.animated_object_start                  ;<--- start block to reset
.m_shell                                ;my shell and unit shells reversed compared with
 object &FF, &00, &00, &00, &00         ;my tank and unit for sub-routine indexing
.tank_shell
 object &FF, &00, &00, &00, &00

.debris_start                           ;debris block
 object &FF, &00, &00, &00, &00
 object &FF, &00, &00, &00, &00
 object &FF, &00, &00, &00, &00
 object &FF, &00, &00, &00, &00
 object &FF, &00, &00, &00, &00
 object &FF, &00, &00, &00, &00
.debris_end

.saucer
 object &FF, &00, &00, &00, &00
.tank_or_super_or_missile               ;opponent placed here to index in for movement
 object &FF, &00, &00, &00, &00

.object_end                             ;<--- end block to reset                  

.m_tank                                 ;index x = &00 tank/super/missile, x = &08 my tank
 EQUW &00                               ;my tank placed here to index in for movement
.m_tank_x_00
 EQUW &00
.m_tank_y_00
 EQUW &00
.m_tank_z_00
 EQUW &00

.reset_refresh                          ;reset console messages and key block
 LDX #&06
 LDA #console_double
.refresh_all
 STA console_refresh - &01,X
 DEX
 BNE refresh_all 
 LDY #&04                               ;x=0
.zero_combat_messages
 STX console_refresh + &06,Y            ;turn off combat messages
 DEY
 BPL zero_combat_messages
.reset_keyboard_block
 LDY #combined_block_end - combined_block_start
.clear_combined_block                   ;clear keys pressed
 STX combined_block_start,Y
 DEY
 BPL clear_combined_block
 RTS

.random_number
 ASL random                             ;provides six random number bytes as pokey is accessed several
 ROL random + &01                       ;times for random numbers in one routine and changes value every
 ROL random + &02                       ;machine cycle, something that cannot be done here
 ROL random + &03
 ROL random + &04
 ROL random + &05
 BCC nofeedback
 LDA random
 EOR #&B7
 STA random
 LDA random + &01
 EOR #&1D
 STA random + &01
 LDA random + &02
 EOR #&C1
 STA random + &02
 LDA random + &03
 EOR #&04
 STA random + &03
.nofeedback
 RTS

.clear_all_screen                       ;full screen clear
 LDA screen_hidden
 STA clear_a_page + &02
 LDA #&00
 TAX
 LDY #&28
.clear_a_page
 STA dummy,X
 DEX
 BNE clear_a_page
 INC clear_a_page + &02
 DEY
 BNE clear_a_page
 RTS

.divide_rotation
 LDA m_tank_rotation + &01              ;entry number in range 0-&4ff
 LSR A                                  ;/4
 STA result_shifted + &01
 STA rotation_divide + &01
 LDA m_tank_rotation
 ROR A
 LSR result_shifted + &01
 LSR rotation_divide + &01
 ROR A
 TAX
 LSR result_shifted + &01               ;/16
 ROR A
 LSR A
 STA result_shifted
 TXA                                    ;- 1/16
 SEC
 SBC result_shifted
 LSR result_shifted                     ;/64
 LSR result_shifted
 CLC                                    ;+ 1/64
 ADC result_shifted
 LSR result_shifted                     ;/256
 LSR result_shifted
 SEC                                    ;- 1/256
 SBC result_shifted
 LSR result_shifted                     ;/1024
 LSR result_shifted
 CLC                                    ;+ 1/1024
 ADC result_shifted
 STA m_tank_rotation_256                ;sum in range 0-&ff
 STA m_tank + &01                       ;facing angle
 RTS

.score_increase                         ;a = opponent scoring
 SED
 CLC
 ADC player_score                       ;add to player score
 STA player_score
 LDA player_score + &01
 ADC #&00
 STA player_score + &01
 CLD                                    ;exit decimal mode
 LDY #console_double                    ;refresh screen score
 STY console_print
 BIT extra_tank                         ;had extra tank?
 BMI test_for_music                     ;yes, so lets check score for music
 LDY bonus_tank_index                   ;any bonus tank?
 BEQ test_for_music                     ;bonus tank not set up
 LDA player_score
 CMP bonus_tank_scores - &01,Y
 LDA player_score + &01
 SBC #&00
 BCC no_bonus_tank_yet                  ;no bonus tank yet
 DEC extra_tank                         ;extra tank given, set flag for given
 INC sound_extra_life                   ;extra life sound
 BNE increment_tanks                    ;always
.test_for_music
 BIT hundred_thousand                   ;check for 100,000 score
 BMI already_past_hundred_thousand      ;bit 7 = 1 music played
 TAX                                    ;a = high byte, reached score?              
 BEQ not_reached_hundred_thousand
 DEC hundred_thousand                   ;set flag to &ff for 100,000 reached
 LDA #&80
 STA sound_music                        ;enable music
 STA sound_mute                         ;disable sound
 JSR sound_flush_buffers
 LDY bonus_tank_index                   ;any bonus tanks?
 BEQ not_reached_hundred_thousand       ;none
.increment_tanks
 LDA #console_double
 STA console_tanks                      ;refresh screen tanks
 INC game_number_of_tanks               ;+1 tank
.no_bonus_tank_yet
.not_reached_hundred_thousand
.already_past_hundred_thousand
 RTS

.bonus_tank_scores
 EQUB &15
 EQUB &25
 EQUB &50

.clear_cells                            ;use a list to clear screen objects to avoid a full refresh
 STX list_access                        ;list pointer
 STY list_access + &01
 LDY #&00
.more_blocks
 LDA (list_access),Y
 STA clear_access + &01                 ;self modify address for speed
 INY
 LDA (list_access),Y
 CLC
 ADC screen_hidden                      ;hidden screen address
 STA clear_access + &02
 INY
 LDA (list_access),Y
 TAX                                    ;number of bytes to clear
 INY
 LDA #&00                               ;write byte
.clear_access
 STA clear_access,X
 DEX
 BNE clear_access
 RTS

.select_swr_ram_slot
 SEI
 LDX found_a_slot
 BIT machine_flag
 BMI select_electron
 STX bbc_romsel
 BPL paged                              ;always
.select_electron
 CPX #&08
 BCS just_select_swr
 LDA #&0C                               ;de-select basic
 STA paged_rom
 STA electron_romsel
.just_select_swr
 STX electron_romsel
.paged
 STX paged_rom
 CLI
 RTS

.cosine_256                             ;cosine, entry a = angle 0-&ff
 CLC
 ADC #&40
.sine_256                               ;sine, entry a = angle 0-&ff
 TAY
 BPL sine_positive
 EOR #&80                               ;bring into +ve range
 TAY
 LDA #&00                               ;invert table value
 SEC
 SBC sine_table_128_lsb,Y
 TAX
 LDA #&00
 SBC sine_table_128_msb,Y
 RTS                                    ;exit x/a lo/hi trig value
.sine_positive
 LDX sine_table_128_lsb,Y
 LDA sine_table_128_msb,Y
 RTS

.game_initialisation                    ;initialise
 LDA #mode_01_attract_mode
 STA game_mode
 STA new_game_mode
 BIT machine_flag
 BPL no_colour_change                   ;beeb
 LDA #&FB                               ;change electron colour to green
 STA sheila + &08
 LDA #&FF
 STA sheila + &09
.no_colour_change
 LDA #14                                ;enable vertical sync event
 LDX #&04
 JSR osbyte
 JMP change_mode                        ;start up in attract mode

.page_four_end
