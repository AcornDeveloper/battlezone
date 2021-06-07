; page zero addresses
; tube addresses
; &00          - control block
; &12 - &13    - control block pointer
; &14          - bit 7 tube free
; &15          - claimant id
; &16 - &7F    - tube code etc
;
; &EE - &EF    - current program
; &F0 - &F1    - hex accumulator
; &F2 - &F3    - top of memory
; &F4 - &F5    - address of byte transfer address, nmi addr or trans
; &F6 - &F7    - data transfer address
; &F8 - &F9    - string pointer, osword control block
; &FA - &FB    - ctrl - osfile, osgbpb control block, prtext string pointer
; &FC          - interrupt accumulator
; &FD - &FE    - brk program counter
; &FF          - escape flag
;
; normal workspace
; &A8 - &AF    - os workspace
; &B0 - &BF    - file system scratch space
; &E4 - &E6    - os workspace
; &E7          - auto repeat countdown byte
; &E8 - &E9    - osword &00 input pointer
; &EC          - last key press
; &ED          - penultimate key press
; &EE - &EF    - current program
; &F2 - &F3    - command line pointer
; &F4          - paged rom
; &FC          - interrupt accumulator
; &FD - &FE    - brk program counter
; &FF          - escape flag

 page_zero                              = &00

 stack_address                          = &80
 clear_counter                          = &82
 clear_row_counter                      = &83
 list_access                            = &84

; multiply
 distance_dx                            = host_r0                       ;<--- host register mapped
 distance_dz                            = host_r1                       ;<--- host register mapped

 multiplier_08                          = &C0
 multiplicand_08                        = &C1
 product_08                             = &C2    ;+&01

 product_16                             = &C0
 multiplier_16                          = &C4
 multiplicand_16                        = &C6
 product_16_t1                          = &C8
 product_16_t2                          = &CA
 result_sign_16                         = &CC

 dividend_24                            = &C0
 division_result_24                     = dividend_24
 division_remainder_24                  = &C3
 divisor_24                             = &C6
 divide_store_24                        = &C9
 division_result_sign_24                = &CA

 divisor_16                             = &C0    ;+&01
 dividend_16                            = &C2    ;+&01
 division_result_16                     = dividend_16
 division_remainder_16                  = &C4    ;+&01

 squared_16                             = host_r0                       ;<--- host register mapped
 squared_work_16                        = host_r1                       ;<--- host register mapped

 square_address                         = &D0    ;+&07
 square1_lo                             = square_address
 square1_hi                             = square_address + &02
 square2_lo                             = square_address + &04
 square2_hi                             = square_address + &06

 m_tank_status                          = &CD
 m_tank_rotation                        = &CE    ;+&01

 cs_value_00                            = &C0
 cs_value_01                            = &C1

; radar
 x_coor_tan_01                          = &C0
 z_coor_tan_01                          = &C1
 octant                                 = &C2

 graphic_x_00                           = &D8    ;+&01 08/16 bit x0, y0 coordinate
 graphic_y_00                           = &DA    ;+&01
 graphic_x_01                           = &DC    ;+&01 08/16 bit x1, y1 coordinate
 graphic_y_01                           = &DE    ;+&01

; line draw
 origin_address                         = &80    ;+&01
 window_address                         = &80    ;+&01

 graphic_x_origin                       = &90    ;+&01
 graphic_y_origin                       = &92    ;+&01

 graphic_window                         = &A0    ;graphic window coordinates
 window_x_00                            = graphic_window          ;+&01
 window_y_00                            = graphic_window + &02    ;+&01
 window_x_01                            = graphic_window + &04    ;+&01
 window_y_01                            = graphic_window + &06    ;+&01

 graphic_dx                             = &C0    ;+&01
 graphic_dy                             = &C2    ;+&01
 graphic_video                          = &C4    ;+&01
 graphic_accumulator                    = &C6    ;+&01
 graphic_count                          = &C8
 graphic_store                          = &C9
 graphic_line_leave                     = &CA
 graphic_y_sign                         = &CB    ;+&01

; battlezone
 PRINT ""
 PRINT " page zero : ",
 PRINT "           : ", ~mathbox_workspace,           "  mathbox_workspace"
 PRINT "           : ", ~mathbox_vector,              "  mathbox_vector"
 PRINT "           : ", ~combined_block_start,        " combined_block_start"
 PRINT "           : ", ~combined_block_end,          " combined_block_end"
 PRINT "           : ", ~console_refresh,             " console_refresh"
 PRINT "           : ", ~console_refresh_end,         " console_refresh_end"
 PRINT "           : ", ~mode_clock,                  " mode_clock"
 PRINT "           : ", ~ai_clock,                    " ai_clock"
 PRINT "           : ", ~seconds,                     " seconds"
 PRINT "           : ", ~x_sine,                      " x_sine"
 PRINT "           : ", ~x_cosine,                    " x_cosine"
 PRINT "           : ", ~y_sine,                      " y_sine"
 PRINT "           : ", ~y_cosine,                    " y_cosine"
 PRINT "           : ", ~z_sine,                      " z_sine"
 PRINT "           : ", ~z_cosine,                    " z_cosine"
 PRINT "           : ", ~y_sine_tank,                 " y_sine_tank"
 PRINT "           : ", ~y_cosine_tank,               " y_cosine_tank"
 PRINT "           : ", ~game_mode,                   " game_mode"
 PRINT "           : ", ~new_game_mode,               " new_game_mode"
 PRINT "           : ", ~random,                      " random"
 PRINT "           : ", ~player_score,                " player_score"
 PRINT "           : ", ~motion_counter,              " motion_counter"
 PRINT "           : ", ~enemy_score,                 " enemy_score"
 PRINT "           : ", ~recent_collision_flag,       " recent_collision_flag"
 PRINT "           : ", ~b_object_bounce_near,        " b_object_bounce_near"
 PRINT "           : ", ~b_object_bounce_far,         " b_object_bounce_far"
 PRINT "           : ", ~game_number_of_tanks,        " game_number_of_tanks"
 PRINT "           : ", ~extra_tank,                  " extra_tank"
 PRINT "           : ", ~crack_counter,               " crack_counter"
 PRINT "           : ", ~on_target,                   " on_target"
 PRINT "           : ", ~radar_arm_position,          " radar_arm_position"
 PRINT "           : ", ~m_tank_speed_of_rotation,    " m_tank_speed_of_rotation"
 PRINT "           : ", ~m_tank_rotation_256,         " m_tank_rotation_256"
 PRINT "           : ", ~missile_flag,                " missile_flag"
 PRINT "           : ", ~angle_to_player,             " angle_to_player"
 PRINT "           : ", ~object_counter,              " object_counter"
 PRINT "           : ", ~saucer_velocity_x,           " saucer_velocity_x"
 PRINT "           : ", ~saucer_velocity_z,           " saucer_velocity_z"
 PRINT "           : ", ~saucer_dying,                " saucer_dying"
 PRINT "           : ", ~saucer_time_to_live,         " saucer_time_to_live"
 PRINT "           : ", ~m_shell_x_vector,            " m_shell_x_vector"
 PRINT "           : ", ~m_shell_z_vector,            " m_shell_z_vector"
 PRINT "           : ", ~m_shell_time_to_live,        " m_shell_time_to_live"
 PRINT "           : ", ~enemy_projectile_velocity_x, " enemy_projectile_velocity_x"
 PRINT "           : ", ~enemy_projectile_velocity_z, " enemy_projectile_velocity_z"

 PRINT "           : ", ~enemy_projectile_velocity_z + &02," page zero end"
 PRINT ""

 combined_block_start                   = &16                           ;<--- key start

 combined_x                             = combined_block_start + &00
 combined_t                             = combined_block_start + &01
 combined_r                             = combined_block_start + &02
 combined_b                             = combined_block_start + &03
 combined_c                             = combined_block_start + &04
 combined_d                             = combined_block_start + &05
 combined_n                             = combined_block_start + &06
 combined_arrow_up                      = combined_block_start + &07
 combined_arrow_down                    = combined_block_start + &08
 combined_arrow_left                    = combined_block_start + &09
 combined_arrow_right                   = combined_block_start + &0A
 combined_a                             = combined_block_start + &0B
 combined_z                             = combined_block_start + &0C
 combined_k                             = combined_block_start + &0D
 combined_m                             = combined_block_start + &0E
 combined_f                             = combined_block_start + &0F
 combined_escape                        = combined_block_start + &10
 combined_space                         = combined_block_start + &11

 combined_block_end                     = combined_block_start + &11    ;<--- key end

 console_refresh                        = combined_block_end + &01

 console_radar                          = console_refresh + &00         ;radar
 console_print                          = console_refresh + &01         ;print large/small score text and score
 console_press_start_etc                = console_refresh + &02         ;press start etc
 console_tanks                          = console_refresh + &03         ;tanks
 console_sights_flashing                = console_refresh + &04         ;sights flashing
 console_synchronise_message_flashing   = console_refresh + &05         ;synchronise message flashing
 console_enemy_in_range                 = console_refresh + &06         ;"enemy in range"
 console_motion_blocked                 = console_refresh + &07         ;"motion blocked"
 console_enemy_to_left                  = console_refresh + &08         ;"enemy to left"
 console_enemy_to_right                 = console_refresh + &09         ;"enemy to right"
 console_enemy_to_rear                  = console_refresh + &0A         ;"enemy to rear"

 console_refresh_end                    = console_refresh + &0A

 mode_clock                             = console_refresh_end + &01
 ai_clock                               = mode_clock + &01
 seconds                                = ai_clock + &01
 x_sine                                 = seconds + &01
 x_cosine                               = x_sine + &02
 y_sine                                 = x_cosine + &02
 y_cosine                               = y_sine + &02
 z_sine                                 = y_cosine + &02
 z_cosine                               = z_sine + &02
 y_sine_tank                            = z_cosine + &02
 y_cosine_tank                          = y_sine_tank + &02

 game_mode                              = y_cosine_tank + &02
 ;                                      ;0 main game
 ;                                      ;1 attract mode
 ;                                      ;2 high score table
 ;                                      ;3 service menu
 ;                                      ;4 new high score
 ;                                      ;5 battlezone text
 ;                                      ;6 model test
 new_game_mode                          = game_mode + &01
 random                                 = new_game_mode + &01
 player_score                           = random + &06
 motion_counter                         = player_score + &02
 enemy_score                            = motion_counter + &01
 recent_collision_flag                  = enemy_score + &01
 hundred_thousand                       = recent_collision_flag + &01
 b_object_bounce_near                   = hundred_thousand + &01
 b_object_bounce_far                    = b_object_bounce_near + &01
 game_number_of_tanks                   = b_object_bounce_far + &01
 extra_tank                             = game_number_of_tanks + &01
 crack_counter                          = extra_tank + &01
 on_target                              = crack_counter + &01
 radar_arm_position                     = on_target + &01
 m_tank_speed_of_rotation               = radar_arm_position + &01
 m_tank_rotation_256                    = m_tank_speed_of_rotation + &01
 missile_flag                           = m_tank_rotation_256 + &01
 angle_to_player                        = missile_flag + &01
 object_counter                         = angle_to_player + &01
 saucer_velocity_x                      = object_counter + &01
 saucer_velocity_z                      = saucer_velocity_x + &02
 saucer_dying                           = saucer_velocity_z + &01
 saucer_time_to_live                    = saucer_dying + &01
 m_shell_x_vector                       = saucer_time_to_live + &01
 m_shell_z_vector                       = m_shell_x_vector + &02
 m_shell_time_to_live                   = m_shell_z_vector + &02
 enemy_projectile_velocity_x            = m_shell_time_to_live + &01
 enemy_projectile_velocity_z            = enemy_projectile_velocity_x + &02

 angle_address                          = &80
 angle_bits                             = &82
 angle_index                            = &83

 rotation_divide                        = &80
 result_shifted                         = &82

 text_counter                           = &7F

; render
 vertice_a                              = &70
 vertice_b                              = &72
 object_relative_x                      = &74    ;+&01
 object_relative_y                      = &76    ;+&01
 object_relative_z                      = &78    ;+&01
 z_absolute                             = &7A    ;+&01

 graphic_temp                           = &80

 i_object_identity                      = &94
 x_object_rotation                      = &95
 y_object_rotation                      = &96
 z_object_rotation                      = &97
 d_object_distance                      = &98    ;+&01

 model_vertices_address                 = &9A    ;+&01
 model_segment_counter                  = &9C
 model_vertices_counter                 = &9D
 model_vertices_work                    = &9E

 ta                                     = &80    ;+&03
 tb                                     = &83    ;+&03
 sine_a                                 = &86    ;+&01
 cosine_a                               = &88    ;+&01

 x_prime                                = &A8    ;+&01
 y_prime                                = &AA    ;+&01
 z_prime                                = &AC    ;+&01

 machine_flag                           = &8C
 mathbox_speed                          = &8D
 mathbox_flag                           = &9F

 working_crack_counter                  = &80
 screen_work                            = &80

 first_entry                            = &80
 small_address                          = &80
 workspace                              = &80
 working_crack_storage                  = &81

 destination                            = &82
 sprite_work                            = &82
 second_entry                           = &82
 char_index                             = &82

 char_counter                           = &83

 read_rom                               = &84
 screen_index                           = &84

 convert_small                          = &85

; landscape
 landscape_vectors_ix                   = &80
 landscape_visibility                   = &81
 landscape_screen_entry                 = &82
 landscape_result                       = &83

 explosion_block                        = &80    ;+&03

; tank sights
 sight_address_01                       = &80
 sight_address_02                       = &82
 sight_address_03                       = &84
 sight_address_04                       = &86

; moon
 moon_sprite_address                    = &80
 moon_sprite_store                      = &82
 moon_screen_address                    = &84
 moon_new_x_coor                        = &86
 moon_counter                           = &88

; volcano
 particle_address                       = &80    ;+&01
 particle_counter                       = &82
 particle_x_store                       = &83
 particle_y_store                       = &85
 particle_work                          = &86    ;+&01
 particle_explosion                     = &88    ;+&01

; print characters
 print_block_address                    = &C0
 print_screen                           = &C2
 print_screen_work                      = &C4
 print_y_work                           = &C6
 print_y_reg                            = &C7
 print_character_height                 = &C8

; service menu
 service_box_left                       = &80
 service_box_right                      = &82
 service_box_top                        = &80
 service_box_bottom                     = &82
 service_diagonal_left                  = &80
 service_diagonal_right                 = &80
 service_mask                           = &82
 service_diagonal_counter               = &83

 stack_store                            = &90
 service_brkv_store                     = &91

; tank
 tank_workspace                         = &80
 tank_address                           = &82
 tank_screen_x                          = &84
 tank_rotate_bits                       = &85
 tank_working                           = &86

; video/swr ram
 screen_hidden                          = &8E
 found_a_slot                           = &8F

; os
 paged_rom                              = &F4
 interrupt_accumulator                  = &FC

; high score
 zero_blank                             = &80
 bcd_counter                            = &81

 three_number_text                      = &C0    ;+&02
 enter_text_index                       = &C3
 valid_character_index                  = &C4

; animate
 debris_present                         = &80

 unit_x_pos                             = &C0    ;+&02
 unit_z_pos                             = &C2    ;+&02
 movement_vector_x                      = &C4    ;+&02
 movement_vector_z                      = &C6    ;+&02
 general_x                              = &C8
 general_y                              = &C9

 stack                                  = &100

; tube
; mathbox only uses &00/&01
 tube_reason_code_00                    = &00  ;parasite ---> host - multiple byte transfer
 tube_reason_code_01                    = &01  ;host     ---> parasite - multiple byte transfer
 tube_reason_code_02                    = &02  ;multiple pairs of byte transfers
 tube_reason_code_03                    = &03  ;host     ---> parasite - multiple double byte transfer
 tube_reason_code_04                    = &04  ;execute in parasite
 tube_reason_code_05                    = &05  ;reserved
 tube_reason_code_06                    = &06  ;parasite ---> host - 256 byte transfer
 tube_reason_code_07                    = &07  ;host     ---> parasite - 256 byte transfer

 tube_code_entry_point                  = &406

; op codes
 bit_op                                 = &2C
 nop_op                                 = &EA
 ora_op                                 = &11

; ascii characters
 ascii_space                            = 32
 ascii_pling                            = 33
 ascii_00                               = 48
 ascii_01                               = 49
 ascii_02                               = 50
 ascii_03                               = 51
 ascii_04                               = 52
 ascii_05                               = 53
 ascii_06                               = 54
 ascii_07                               = 55
 ascii_08                               = 56
 ascii_09                               = 57

 ascii_under_score                      = 60
 ascii_equals                           = 61
 ascii_greater_than                     = 62
 ascii_upper_a                          = 65
 ascii_upper_z                          = 90
 ascii_a                                = 97
 ascii_z                                = 122

; ascii top bit set codes
 bit_ascii_space                        = 32 + &80
 bit_ascii_pling                        = 33 + &80
 bit_ascii_00                           = 48 + &80
 bit_ascii_01                           = 49 + &80
 bit_ascii_02                           = 50 + &80
 bit_ascii_03                           = 51 + &80
 bit_ascii_04                           = 52 + &80
 bit_ascii_05                           = 53 + &80
 bit_ascii_06                           = 54 + &80
 bit_ascii_07                           = 55 + &80
 bit_ascii_08                           = 56 + &80
 bit_ascii_09                           = 57 + &80
 bit_ascii_semi_colon                   = 59 + &80
 bit_ascii_less_than                    = 60 + &80
 bit_ascii_greater_than                 = 62 + &80
 bit_ascii_a                            = 65 + &80
 bit_ascii_b                            = 66 + &80
 bit_ascii_c                            = 67 + &80
 bit_ascii_d                            = 68 + &80
 bit_ascii_e                            = 69 + &80
 bit_ascii_f                            = 70 + &80
 bit_ascii_g                            = 71 + &80
 bit_ascii_h                            = 72 + &80
 bit_ascii_i                            = 73 + &80
 bit_ascii_j                            = 74 + &80
 bit_ascii_k                            = 75 + &80
 bit_ascii_l                            = 76 + &80
 bit_ascii_m                            = 77 + &80
 bit_ascii_n                            = 78 + &80
 bit_ascii_o                            = 79 + &80
 bit_ascii_p                            = 80 + &80
 bit_ascii_q                            = 81 + &80
 bit_ascii_r                            = 82 + &80
 bit_ascii_s                            = 83 + &80
 bit_ascii_t                            = 84 + &80
 bit_ascii_u                            = 85 + &80
 bit_ascii_v                            = 86 + &80
 bit_ascii_w                            = 87 + &80
 bit_ascii_x                            = 88 + &80
 bit_ascii_y                            = 89 + &80
 bit_ascii_z                            = 90 + &80
 bit_ascii_under_score                  = 95 + &80
