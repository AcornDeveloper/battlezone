; animate
; object coordinates
; object positions represented by signed 16 bits
;
; calculate distance
; world coordinates fustrum near &03ff, far &7aff
;
; constants

 object_bounding_box                    = &800
 
 debris_gravity                         = &28

 radar_x_adjust                         = &200 * bz_scale_factor

 missile_height                         = &100
 my_tank_radius                         = &480
 tank_radius                            = &780
 missile_radius                         = &380
 saucer_radius                          = &480
 
 missile_shot_ceiling                   = &10
 saucer_dying_counter                   = &20

 x_offset = &80
 z_offset = &82
 sine     = &84
 cosine   = &86

 obstacle_x_00                          = &2000
 obstacle_x_01                          = &4000
 obstacle_x_02                          = &8000
 obstacle_x_03                          = &8000
 obstacle_x_04                          = &8000
 obstacle_x_05                          = &4000
 obstacle_x_06                          = &0000
 obstacle_x_07                          = &0000
 obstacle_x_08                          = &5000
 obstacle_x_09                          = &1800
 obstacle_x_0A                          = &4400
 obstacle_x_0B                          = &4000
 obstacle_x_0C                          = &8C00
 obstacle_x_0D                          = &0C00
 obstacle_x_0E                          = &E800
 obstacle_x_0F                          = &E400
 obstacle_x_10                          = &9C00
 obstacle_x_11                          = &CC00
 obstacle_x_12                          = &B400
 obstacle_x_13                          = &BC00
 obstacle_x_14                          = &F400

 obstacle_z_00                          = &2000
 obstacle_z_01                          = &0000
 obstacle_z_02                          = &0000
 obstacle_z_03                          = &4000
 obstacle_z_04                          = &8000
 obstacle_z_05                          = &8000
 obstacle_z_06                          = &8000
 obstacle_z_07                          = &4000
 obstacle_z_08                          = &3000
 obstacle_z_09                          = &C000
 obstacle_z_0A                          = &F700
 obstacle_z_0B                          = &C800
 obstacle_z_0C                          = &D800
 obstacle_z_0D                          = &9400
 obstacle_z_0E                          = &9800
 obstacle_z_0F                          = &E800
 obstacle_z_10                          = &7000
 obstacle_z_11                          = &7800
 obstacle_z_12                          = &4000
 obstacle_z_13                          = &2400
 obstacle_z_14                          = &2C00

.debris_x_velocity                      ;pre-determined x/z debris velocities
 EQUW -120
 EQUW -120
 EQUW   20
 EQUW  200
 EQUW    0
 EQUW -160

.debris_y_velocity
 EQUW &00
 EQUW &00
 EQUW &00
 EQUW &00
 EQUW &00
 EQUW &00

.debris_z_velocity
 EQUW  120
 EQUW    0
 EQUW  -20
 EQUW  200
 EQUW -160
 EQUW -160

.debris_y_velocity_initial              ;x4 in original
 EQUW &37 << &02
 EQUW &28 << &02
 EQUW &46 << &02
 EQUW &58 << &02
 EQUW &28 << &02
 EQUW &42 << &02

.debris_parts
.debris_tank                            ;x3 sets of debris
 EQUB object_x0B_ship_chunk_00
 EQUB object_x0C_ship_chunk_01
 EQUB object_x0D_ship_chunk_02
 EQUB object_x0A_tank_radar
 EQUB object_x0C_ship_chunk_01
 EQUB object_x0B_ship_chunk_00
.debris_super_tank
 EQUB object_x0B_ship_chunk_00
 EQUB object_x0C_ship_chunk_01
 EQUB object_x0D_ship_chunk_02
 EQUB object_x0C_ship_chunk_01
 EQUB object_x0C_ship_chunk_01
 EQUB object_x0B_ship_chunk_00
.debris_missile
 EQUB object_x0C_ship_chunk_01
 EQUB object_x0E_ship_chunk_04
 EQUB object_x0B_ship_chunk_00
 EQUB object_x0F_ship_chunk_05
 EQUB object_x0B_ship_chunk_00
 EQUB object_x0B_ship_chunk_00
 
.calculate_movement_deltas              ;x = &00, &08 index into tank/super/missile or my tank
 STX general_x
 LDA tank_or_super_or_missile + &01,X   ;get facing sine angle
 JSR sine_256                           ;compute sin(theta), a=msb
 CMP #&80                               ;divide by 2 with sign extension
 ROR A
 STA movement_vector_x                  ;save as delta X
 CMP #&80                               ;divide by 2 with sign extension
 ROR A
 CLC
 ADC movement_vector_x                  ;add to previous to get 3/4 value
 STA movement_vector_x
 ASL A
 LDA #&00
 ADC #&FF
 EOR #&FF
 STA movement_vector_x + &01
 LDX general_x
 LDA tank_or_super_or_missile + &01,X   ;get facing cosine angle
 JSR cosine_256                         ;compute cos(theta), a=msb
 CMP #&80                               ;divide by 2 with sign extension
 ROR A
 STA movement_vector_z                  ;save as delta Z
 CMP #&80                               ;divide by 2 with sign extension
 ROR A
 CLC
 ADC movement_vector_z                  ;add to previous to get 3/4 value
 STA movement_vector_z
 ASL A
 LDA #&00
 ADC #&FF
 EOR #&FF
 STA movement_vector_z + &01
 LDX general_x                          ;restore x
 RTS

.initialise_unit_chunks                 ;initialise debris positions
 LDX #block_size * &06 - block_size
 SEC
.init_unit_chunks_loop
 LDA tank_or_super_or_missile + &02     ;initialise debris unit x/y/z world coordinates
 STA debris_start + &02,X
 LDA tank_or_super_or_missile + &03
 STA debris_start + &03,X
 LDA #&00                               ;initial height is zero
 STA debris_start + &04,X
 STA debris_start + &05,X
 LDA tank_or_super_or_missile + &06
 STA debris_start + &06,X
 LDA tank_or_super_or_missile + &07
 STA debris_start + &07,X
 TXA
 SBC #block_size
 TAX
 BCS init_unit_chunks_loop
 LDY #&0B                               ;initialise y velocities
.initialise_debris_y_velocity
 LDA debris_y_velocity_initial,Y
 STA debris_y_velocity,Y
 DEY
 BPL initialise_debris_y_velocity
 LDX #debris_missile - debris_parts + &05
 BIT missile_flag
 BMI debris_set
 LDX #debris_tank - debris_parts + &05
 LDA tank_or_super_or_missile
 CMP #object_x04_tank                   ;standard tank?
 BEQ debris_set
 LDX #debris_super_tank - debris_parts + &05
.debris_set                             ;set up debris objects
 LDY #block_size * &06 - block_size
 SEC
.initialise_debris_id
 LDA debris_parts,X                     ;set up debris object ids
 STA debris_start,Y
 DEX
 TYA
 SBC #block_size
 TAY
 BCS initialise_debris_id
 LDA #&FF                               ;remove destroyed unit/my shell
 STA tank_or_super_or_missile
 STA m_shell
 RTS

.animated_object_reset_all              ;reset all animated/debris objects
 LDX #object_end - animated_object_start - block_size
 SEC
.animated_object_clear
 LDA #&FF                               ;object off
 STA animated_object_start,X
 TXA
 SBC #block_size
 TAX
 BCS animated_object_clear
 RTS

.copy_position_save                     ;save unit position
 LDA tank_or_super_or_missile + &02,X
 STA unit_x_pos
 LDA tank_or_super_or_missile + &03,X
 STA unit_x_pos + &01
 LDA tank_or_super_or_missile + &06,X
 STA unit_z_pos
 LDA tank_or_super_or_missile + &07,X
 STA unit_z_pos + &01
 RTS

.copy_position_restore                  ;restore unit position
 LDA unit_x_pos
 STA tank_or_super_or_missile + &02,X
 LDA unit_x_pos + &01
 STA tank_or_super_or_missile + &03,X
 LDA unit_z_pos
 STA tank_or_super_or_missile + &06,X
 LDA unit_z_pos + &01
 STA tank_or_super_or_missile + &07,X
 RTS

.obstacle_radius_lsb
 EQUB LO(&0340)                         ;narrow pyramid
 EQUB LO(&0340)                         ;tall cube
 EQUB LO(&03C0)                         ;short cube
 EQUB LO(&0400)                         ;wide pyramid
.obstacle_radius_msb
 EQUB HI(&0340)
 EQUB HI(&0340)
 EQUB HI(&03C0)
 EQUB HI(&0400)

.object_collision_test                  ;collision test of geometrical objects/my tank/tank/super/missile
 STX general_x                          ;exit c=0/1 miss/collision, a=&00/&ff obstacle/unit
 LDY #(object_shot_collision_end - object_start) - block_size
.object_collide_loop
 STY general_y
 LDA object_start + &02,Y               ;calculate delta x distance to object
 SEC
 SBC tank_or_super_or_missile + &02,X
 STA distance_dx
 LDA object_start + &03,Y
 SBC tank_or_super_or_missile + &03,X
 STA distance_dx + &01
 BPL quick_check_x                      ;quick check for x bounding
 EOR #&FF
 CLC
 ADC #&01
.quick_check_x
 CMP #HI(object_bounding_box)
 BCS no_object_collision
 LDA object_start + &06,Y
 SEC
 SBC tank_or_super_or_missile + &06,X
 STA distance_dz
 LDA object_start + &07,Y               ;calculate delta z distance to object
 SBC tank_or_super_or_missile + &07,X
 STA distance_dz + &01
 BPL quick_check_z                      ;quick check for z bounding
 EOR #&FF
 CLC
 ADC #&01
.quick_check_z
 CMP #HI(object_bounding_box)
 BCS no_object_collision
 JSR mathbox_distance16
 LDX general_x                          ;enemy or my tank we are checking?
 BEQ enemy_unit                         ;enemy
 LDA #LO(my_tank_radius)                ;use my tank's radius
 CMP d_object_distance
 LDA #HI(my_tank_radius)
 BNE subtract_distance                  ;always
.enemy_unit
 LDX object_start,Y                     ;get object type
 BIT missile_flag
 BPL not_the_missile
 LDA d_object_distance + &01
 CMP #&80
 ROR A
 TAX
 LDA d_object_distance
 ROR A
 CLC
 ADC d_object_distance
 STA d_object_distance
 TXA
 ADC d_object_distance + &01
 STA d_object_distance + &01
 BCC not_the_missile
 LDX general_x
 BCS no_object_collision                ;always
.not_the_missile
 LDA obstacle_radius_lsb,X
 CMP d_object_distance
 LDA obstacle_radius_msb,X
 LDX general_x
.subtract_distance
 SBC d_object_distance + &01
 BCS hit_obstacle_return
.no_object_collision
 LDA general_y                          ;next object block
 SEC
 SBC #block_size
 TAY
 BCS object_collide_loop
 LDA tank_or_super_or_missile           ;geometrical shapes now done so check my tank/opponent
 ORA m_tank_status                      ;if either dead then exit
 BMI hit_unit_return                    ;no collison as either is off, c=0
 TXA                                    ;flip x to other unit and pass to y
 EOR #block_size
 TAY
 SEC
 LDA tank_or_super_or_missile + &02,X   ;calculate delta x distance between units
 SBC tank_or_super_or_missile + &02,Y
 STA distance_dx
 LDA tank_or_super_or_missile + &03,X
 SBC tank_or_super_or_missile + &03,Y
 STA distance_dx + &01
 SEC
 LDA tank_or_super_or_missile + &06,X   ;calculate delta z distance between units
 SBC tank_or_super_or_missile + &06,Y
 STA distance_dz
 LDA tank_or_super_or_missile + &07,X
 SBC tank_or_super_or_missile + &07,Y
 STA distance_dz + &01
 JSR mathbox_distance16
 LDX general_x
 LDA #HI(tank_radius)                   ;check tank/missile
 BIT missile_flag
 BPL not_missile_again
 LDA #HI(missile_radius)
.not_missile_again
 CMP d_object_distance + &01
.hit_unit_return
 LDA #&FF                               ;hit unit flag
 RTS
.hit_obstacle_return
 LDA #&00                               ;hit obstacle flag
.debris_exit
 RTS

.animate_debris                         ;maintain debris, update in progress flag
 LDA tank_or_super_or_missile           ;enemy unit active?
 BPL debris_exit                        ;yes
 STA debris_present                     ;unit spawned when no debris
 LDX #block_size * &06 - block_size     ;point to last debris entry
.animate_debris_loop
 LDA debris_start,X                     ;test if debris present
 BMI debris_next
 STA debris_present                     ;debris present, positive flag
 TXA                                    ;divide by 4 to get index into x/y/z velocity
 LSR A
 LSR A
 TAY
 LDA debris_start + &04,X               ;update y position
 SBC debris_y_velocity,Y
 STA debris_start + &04,X
 LDA debris_start + &05,X
 SBC debris_y_velocity + &01,Y
 STA debris_start + &05,X
 BMI debris_still_active
 SEC                                    ;remove debris
 ROR debris_start,X
 BMI debris_next                        ;always
.debris_still_active
 LDA debris_start + &02,X               ;update x position
 ADC debris_z_velocity,Y
 STA debris_start + &02,X
 LDA debris_start + &03,X
 ADC debris_z_velocity + &01,Y
 STA debris_start + &03,X
 LDA debris_start + &06,X               ;update z position
 ADC debris_x_velocity,Y
 STA debris_start + &06,X
 LDA debris_start + &07,X
 ADC debris_x_velocity + &01,Y
 STA debris_start + &07,X
 LDA debris_y_velocity,Y
 SBC #LO(debris_gravity)
 STA debris_y_velocity,Y
 LDA debris_y_velocity + &01,Y
 SBC #HI(debris_gravity)
 STA debris_y_velocity + &01,Y
 LDA debris_y_velocity,Y                ;rotate chunk
 AND #&3F
 ADC debris_start + &01,X
 STA debris_start + &01,X
.debris_next
 TXA
 SEC
 SBC #block_size
 TAX
 BCS animate_debris_loop
 BIT debris_present                     ;debris still active?
 BPL debris_exit                        ;roll into routine below if no unit

.create_opponent                        ;create unit
 LDA game_mode                          ;playing game?
 BNE create_tank                        ;no, so spawn a tank
 LDA player_score + &01                 ;score >= 100K?
 BNE maybe_missile                      ;yes, think about a missile
 LDX missile_appears_at_index           ;from service menu
 LDA player_score                       ;get low byte of score
 CMP missile_appears_at_score,X         ;compare to missile threshold
 BCC create_tank                        ;score too low so create a tank after all
.maybe_missile
 LDY random                             ;get a random number
 TYA
 EOR missile_rand                       ;xor with previous random value
 STY missile_rand                       ;save new random value
 LSR A                                  ;shift low bit into carry
 BCC create_tank
 LDA #&02                               ;init clock used for missed-missile retry timeout
 STA ai_clock
 BCS create_missile                     ;always

.create_tank
 JSR get_tank_type                      ;standard/super
 STA tank_or_super_or_missile
 INC sound_enemy_alert                  ;alert player
 LDA random + &01
 STA enemy_turn_to                      ;random heading
 LDX #&00
 STX missile_flag                       ;not a missile
 STX enemy_state                        ;unit alive
 INX
 STX ai_clock                           ;wait 1 second
 LDA game_mode                          ;are we playing the game?
 BNE be_nice                            ;no
 LDA player_score + &01                 ;over 100K points?
 BNE be_mean                            ;yes
 LDA player_score
 SEC                                    ;compare player score to enemy score
 SBC enemy_score
 BCC be_nice
 BEQ be_nice
 CMP #&07                               ;is player_score - enemy_score < 7000?
 BCC be_meh                             ;yes, be sort of nice
.be_mean                                ;get value from &00-78 that affects the angle at which the enemy unit is placed
 LDA #&07                               ;smaller values place the enemy closer to where the player is facing
.be_meh                                 ;so we use those when playing nice
 LSR A                                  ;1-7 becomes 0-3
 BEQ be_nice                            ;player barely ahead of enemy
 TAX                                    ;x is now left-shift counter (1-3)
 LDA #&0F
.rotate
 SEC
 ROL A
 DEX
 BNE rotate
 BEQ create_common                      ;always
.be_nice
 LDA #&0F
 BNE create_common                      ;always

.create_missile
 LDA #object_x07_missile                ;set type to missile
 STA tank_or_super_or_missile
 INC missile_count                      ;increment missile counter
 INC sound_missile_hum                  ;missile sound
 SEC
 ROR missile_flag                       ;missile active
 LDA #&18                               ;set altitude = &1800
 STA tank_or_super_or_missile + &05
 LDA #&00
 STA tank_or_super_or_missile + &04
 LDA random + &02                       ;get a random value for angle adjustment
 AND #&0F                               ;reduce to 0-15

.create_common                          ;creates common features of the opponent
 STA angle_adjustment                   ;pass an angle adjustment in and add to the player's facing
 LDA random + &03                       ;to determine the angle at which the new unit will appear
 AND angle_adjustment                   ;small values will put enemy unit to the front, large to side/rear
 BIT random + &05                       ;reduce angle adjustment value by zeroing random bits
 BVS no_invert                          ;test bit 6
 EOR #&FF                               ;flip the bits
.no_invert
 CLC
 ADC m_tank_rotation_256                ;add to player facing
 STA angle_adjustment                   ;compute the z coordinate using cos(angle_adjustment)
 JSR cosine_256                         ;compute cos(angle_adjustment)
 STX z_offset                           ;value from &0000-&7fff
 STX cosine
 STA cosine + &01
 CMP #&80                               ;divide by 4 with sign extension
 ROR A                                  ;gives +/- 8191
 ROR z_offset
 CMP #&80
 ROR A
 ROR z_offset
 STA z_offset + &01
 LDA cosine                             ;compute z_offset = cos(angle_adjustment) - z_offset
 SEC                                    ;which leaves us with 3/4 cos(angle_adjustment)
 SBC z_offset                           ;about &6000 units away
 STA z_offset
 LDA cosine + &01
 SBC z_offset + &01
 TAX                                    ;z_offset high to x
 BIT missile_flag                       ;is this a missile?
 BMI max_range                          ;yes, use max range
 LDA random + &01
 LSR A                                  ;put low bit of random number in carry
 TXA                                    ;retrieve z_offset high
 BCC max_range
 CMP #&80                               ;divide by 2 bringing the enemy closer
 ROR A
 ROR z_offset
.max_range
 STA z_offset + &01
 LDA angle_adjustment                   ;repeat the process for sin(angle_adjustment) and the X coordinate
 JSR sine_256                           ;compute sin(angle_adjustment)
 STX x_offset                           ;this is a value from &0000-&7fff
 STX sine
 STA sine + &01
 CMP #&80                               ;divide by 4 with sign extension
 ROR A                                  ;yields essentially +/- 8191
 ROR x_offset
 CMP #&80
 ROR A
 ROR x_offset
 STA x_offset + &01
 SEC                                    ;compute x_offset = sin(angle_adjustment) - z_offset
 LDA sine                               ;which leaves us with 3/4 sin(angle_adjustment)
 SBC x_offset                           ;about &6000 units away
 STA x_offset
 LDA sine + &01
 SBC x_offset + &01
 BIT missile_flag                       ;are we creating a missile?
 BMI real_max_range                     ;yes, use max range
 TAX                                    ;x_offset high to x
 LDA random + &01                       ;get the random carry bit from earlier
 LSR A
 TXA                                    ;retrieve x_offset high
 BCC real_max_range
 CMP #&80                               ;divide by two with sign extension
 ROR A                                  ;to bring the enemy closer
 ROR x_offset
.real_max_range
 STA x_offset + &01                     ;use x/z offsets from my tank position
 LDA m_tank_z_00                        ;add z_offset to player z position
 CLC
 ADC z_offset
 STA tank_or_super_or_missile + &06     ;save as enemy z position
 LDA m_tank_z_00 + &01
 ADC z_offset + &01
 STA tank_or_super_or_missile + &07
 LDA m_tank_x_00                        ;same for x
 CLC
 ADC x_offset
 STA tank_or_super_or_missile + &02
 LDA m_tank_x_00 + &01
 ADC x_offset + &01
 STA tank_or_super_or_missile + &03

 BIT missile_flag                       ;spawning missile?
 BPL not_a_missile                      ;no
 SEC
 ROR tank_shell                         ;remove tank shell as spawning missile
 LDA angle_to_player                    ;point the missile at the player
 EOR #&80
 STA tank_or_super_or_missile + &01     ;set facing
 STA enemy_turn_to                      ;set desired heading
.not_a_missile
 LDA #&00
 STA enemy_known_flag                   ;new enemy, clear flag
 STA rez_protect                        ;suppress aggression briefly
 RTS

.missile_count
 EQUB &00
.missile_rand
 EQUB &00
.enemy_turn_to
 EQUB &00
.enemy_state
 EQUB &00

.angle_adjustment
 EQUB &00

.enemy_known_flag
 EQUB &00
.rez_protect
 EQUB &00

.get_tank_type
 CLC
 LDA missile_count                      ;check number of missiles launched
 BMI slow_tank                          ;&80-ff, want slow tanks
 CMP #&05                               ;super tank if it's &05 <= n < &80
.slow_tank
 BCC normal_tank
 LDA #object_x05_super_tank
 RTS
.normal_tank
 LDA #object_x04_tank
 RTS                                    ;a = tank type

.my_projectile                          ;maintain my shot
 BIT m_shell                            ;in flight?
 BPL my_projectile_in_flight            ;yes
 BIT m_tank_status
 BMI dead_so_cannot_fire
 BIT combined_space                     ;fire shot?
 BMI take_a_shot                        ;yes
.dead_so_cannot_fire
 RTS
.take_a_shot
 INC sound_tank_shot_loud
 LDA m_tank_rotation                    ;my tank rotation and calculate sine/cosine
 LDX m_tank_rotation + &01              ;x/z projectile vectors
 JSR sine_1280
 STX workspace
 STA m_shell_x_vector
 ASL A                                  ;sign extend x
 LDA #&00
 ADC #&FF
 EOR #&FF
 ASL workspace
 ROL m_shell_x_vector
 ROL A
 STA m_shell_x_vector + &01
 LDA m_tank_rotation
 LDX m_tank_rotation + &01
 JSR cosine_1280
 STX workspace
 STA m_shell_z_vector
 ASL A                                  ;sign extend z
 LDA #&00
 ADC #&FF
 EOR #&FF
 ASL workspace
 ROL m_shell_z_vector
 ROL A
 STA m_shell_z_vector + &01
 LDA #object_x09_m_shell                ;spawn my shell
 STA m_shell
 LDA m_tank_rotation_256                ;my shell facing angle
 EOR #&80
 STA m_shell + &01
 LDA m_tank_x_00                        ;initialise x coordinate
 STA m_shell + &02
 LDA m_tank_x_00 + &01
 STA m_shell + &03
 LDA m_tank_z_00                        ;initialise z coordinate
 STA m_shell + &06
 LDA m_tank_z_00 + &01
 STA m_shell + &07
 LDA #&7F / 4                           ;time to live counter
 STA m_shell_time_to_live
 RTS

.my_projectile_in_flight                ;move my shot and test for objects/unit collision
 DEC m_shell_time_to_live
 BEQ m_shell_deactivate
 LDX #&04
.move_my_shell
 STX object_counter
 LDA m_shell + &02
 CLC
 ADC m_shell_x_vector
 STA m_shell + &02
 LDA m_shell + &03
 ADC m_shell_x_vector + &01
 STA m_shell + &03
 LDA m_shell + &06
 CLC
 ADC m_shell_z_vector
 STA m_shell + &06
 LDA m_shell + &07
 ADC m_shell_z_vector + &01
 STA m_shell + &07                      ;test if hit anything
 LDX #m_shell - object_shot_collision_start
 JSR projectile_object_collision_test   ;test collision my shot ---> geometrical object
 BCS my_shell_hit_geometrical_object
 JSR projectile_unit_collision_test     ;test collision my shot ---> tank/super/missile
 BCS my_shell_hit_unit
 LDX object_counter
 DEX
 BNE move_my_shell
 RTS

.my_shell_hit_unit
 BIT missile_flag
 BMI check_missile_height
 LDA #tank_score
 LDX tank_or_super_or_missile
 CPX #object_x04_tank
 BEQ standard_tank_or_missile
 LDA #super_tank_score
.standard_tank_or_missile
 JSR score_increase
 JMP initialise_unit_chunks

.check_missile_height
 LDA tank_or_super_or_missile + &04     ;missile height
 CMP #missile_shot_ceiling
 LDA #missile_score
 BNE standard_tank_or_missile           ;always

.my_shell_hit_geometrical_object
 LDA #&07
 JSR oswrch
 LDA #&00
 STA explosion_block
 LDA #&A0
 STA explosion_block + &01
 LDA #&03
 STA explosion_block + &02
 JSR explosion_on_screen
.m_shell_deactivate
 SEC                                    ;reset my shot
 ROR m_shell
 RTS

.control_saucer                         ;move saucer, my shot -> saucer
 LDA saucer_dying                       ;saucer dying?
 BEQ saucer_not_dying                   ;no
 DEC saucer_dying
 BNE saucer_return                      ;still dying so don't move and exit
 LDA random                             ;random delay until new saucer appears
 STA saucer_time_to_live                ;approx 0-17 seconds
 SEC                                    ;set saucer to inactive and exit
 ROR saucer
 RTS

.saucer_inactive
 LDA player_score                       ;get current score
 LSR A                                  ;divide by 2
 BNE saucer_score_greater               ;if score >= 2000, see if we want to add a saucer
.saucer_return
 RTS

.saucer_score_greater
 LDA saucer_time_to_live                ;is it time?
 BNE saucer_not_yet                     ;not yet
 LDA random                             ;spawn saucer in random location
 STA saucer + &07                       ;saucer z
 LDA random + &01
 STA saucer + &03                       ;saucer x
 LDA #object_x08_saucer
 STA saucer
.saucer_randomize                       ;saucer random direction
 LDA random + &02                       ;set low byte of z velocity to a random value
 STA saucer_velocity_z
 ASL A                                  ;sign-extend into z high byte
 LDA #&00
 ADC #&FF
 EOR #&FF
 STA saucer_velocity_z + &01
 LDA random + &03                       ;set low byte of x velocity to random value
 STA saucer_velocity_x
 ASL A                                  ;sign-extend into x high byte
 LDA #&00
 ADC #&FF
 EOR #&FF
 STA saucer_velocity_x + &01
 LDA random + &04                       ;random time until direction change
 LSR A                                  ;0-127
 STA saucer_time_to_live
.saucer_exit
 RTS

.saucer_not_dying
 BIT saucer                             ;saucer active?
 BMI saucer_inactive                    ;no, see if we want to spawn one
 LDA saucer + &01                       ;update facing angle so saucer spins
 CLC
 ADC #object_saucer_spin                ;saucer spin speed
 STA saucer + &01
 LDA saucer_time_to_live                ;time to change direction?
 BEQ saucer_randomize                   ;yes
 CLC
 LDA saucer_velocity_z                  ;add x/z velocity to current position
 CLC
 ADC saucer + &06
 STA saucer + &06
 LDA saucer + &07
 ADC saucer_velocity_z + &01
 STA saucer + &07
 LDA saucer + &02
 CLC
 ADC saucer_velocity_x
 STA saucer + &02
 LDA saucer + &03
 ADC saucer_velocity_x + &01
 STA saucer + &03
.saucer_not_yet
 DEC saucer_time_to_live                ;decrement time-to-live / time-until-velocity-changes
 BIT m_shell                            ;my shot in flight?
 BMI saucer_return                      ;not on
 LDA saucer_time_to_live
 BNE saucer_exit                        ;saucer dying
 LDA m_shell + &02                      ;calculate distance between my shot and saucer
 SEC                                    ;do once due to size of saucer
 SBC saucer + &02                       ;delta x
 STA distance_dx
 BPL quick_check_saucer_x               ;quick check for x bounding
 EOR #&FF
 CLC
 ADC #&01
.quick_check_saucer_x
 CMP #HI(object_bounding_box)
 BCS saucer_exit
 LDA m_shell + &03                      ;delta x
 SBC saucer + &03
 STA distance_dx + &01
 LDA m_shell + &06
 SEC
 SBC saucer + &06
 STA distance_dz                        ;delta z
 LDA m_shell + &07
 SBC saucer + &07
 STA distance_dz + &01
 BPL quick_check_saucer_z               ;quick check for z bounding
 EOR #&FF
 CLC
 ADC #&01
.quick_check_saucer_z
 CMP #HI(object_bounding_box)
 BCS saucer_exit
 JSR mathbox_distance16
 LDA d_object_distance + &01
 CMP #HI(saucer_radius)
 BCS saucer_missed                      ;missed saucer
 LDA #saucer_dying_counter              ;saucer dying counter
 STA saucer_dying
 INC sound_saucer_shot
 LDA #saucer_score
 JMP score_increase
.saucer_missed
 RTS

.update_enemy_unit
 LDA enemy_state                        ;is enemy alive?
 BEQ alive                              ;yes, keep going
 RTS

.alive
 BIT missile_flag                       ;is it a missile?
 BPL update_tank                        ;no, do tank update
 JMP update_missile                     ;yes, do missile update

.enemy_rev_flags
 EQUB &00

.close_firing_angle
 EQUB &00

.update_tank
 SEC                                    ;turn tracks off, in case we have stopped
 ROR tracks_active                      ;maybe turned on later
 LDX #&00
 JSR copy_position_save
 LDA enemy_rev_flags                    ;check the in-reverse flag
 LSR A
 BCC not_reverse
 LSR A                                  ;shift once more to get turn direction
 PHP
 JSR move_backward_one                  ;back up one step, regardless of tank type
 PLP
 BCC back_right
 INC tank_or_super_or_missile + &01     ;increase angle
 JMP back_common

.back_right
 DEC tank_or_super_or_missile + &01     ;decrease angle
.back_common
 LDA #&01                               ;tracks going backwards
 STA tracks_active
 LDA ai_clock                           ;still going?
 BEQ reverse_done                       ;no, find something new to do
 RTS

.reverse_done
 LDA enemy_rev_flags
 AND #%11111100                         ;clear move-backward flag
 STA enemy_rev_flags
 LDA tank_or_super_or_missile + &01     ;set desired direction to current direct
 STA enemy_turn_to
 LDA #&03                               ;set move counter to 3 seconds
 STA ai_clock        
 RTS

.not_reverse
 LDA ai_clock                           ;time to update heading?
 BNE continue_move                      ;not yet, branch
 JMP set_tank_turn_to

 ; Rotate toward the facing in &bc, moving forward if we're pointed toward the
 ; player and not too close.  If the facing is within a few degrees of the
 ; player's position, fire the cannon.
.continue_move
 LDA tank_or_super_or_missile + &01     ;compute difference between current and
 SEC
 SBC enemy_turn_to
 TAY                                    ;copy to y
 BPL IsPos                              ;get absolute value
 EOR #&FF
 CLC
 ADC #&01
.IsPos
 CMP close_firing_angle                 ;are we close to the correct angle?
 BCC small_angle                        ;yes, turn and move
 ; Angle is too large, rotate without moving forward.
 TYA                                    ;get signed angle delta from Y-reg
 BPL turn_right_multi                   ;sign says to turn right
 INC tank_or_super_or_missile + &01     ;increase angle
 JSR try_shoot_player
 INC tank_or_super_or_missile + &01     ;increase angle
 JSR try_shoot_player
 JSR get_tank_type
 BCS turn_left_fast
.Return
 RTS

.turn_left_fast
 INC tank_or_super_or_missile + &01     ;increase angle, super tanks rotate at 2x
 JSR try_shoot_player
 INC tank_or_super_or_missile + &01     ;increase angle
 JMP try_shoot_player

.turn_right_multi
 DEC tank_or_super_or_missile + &01     ;decrease angle
 JSR try_shoot_player
 DEC tank_or_super_or_missile + &01     ;decrease angle
 JSR try_shoot_player
 JSR get_tank_type
 BCC Return
 DEC tank_or_super_or_missile + &01     ;decrease angle, super tanks rotate at 2x
 JSR try_shoot_player
 DEC tank_or_super_or_missile + &01     ;decrease angle
 JMP try_shoot_player

 ; The angle is nearly correct.  Turn slowly (so we don't overshoot) and move
 ; forward if we're not right in the player's face.
.small_angle
 CMP #&00                               ;are we lined up on the player?
 BEQ small_angleCom                     ;yes, try to shoot
 TYA                                    ;no, rotate one step then try to shoot
 BPL go_right
 INC tank_or_super_or_missile + &01     ;increase angle
 JMP small_angleCom

.abs_delta_z        EQUW &00
.abs_delta_x        EQUW &00
.enemy_ang_delt_abs EQUB &00
.enemy_dist_hi      EQUB &00
.projectile_state_0 EQUB &00
.projectile_state_1 EQUB &00

.go_right
 DEC tank_or_super_or_missile + &01     ;decrease angle
.small_angleCom
 JSR try_shoot_player
 LDA abs_delta_x                        ;calculate distance of enemy tank
 STA distance_dx
 LDA abs_delta_x + &01
 STA distance_dx + &01
 LDA abs_delta_z
 STA distance_dz
 LDA abs_delta_z + &01
 STA distance_dz + &01
 JSR mathbox_distance16
 JSR get_tank_type
 LDA d_object_distance + &01            ;get high byte of distance
 BCC this_slow_tank
 CMP #&08                               ;is distance >= &800
 BCS go_forward                         ;yes, move
 RTS

.this_slow_tank
 CMP #&05                               ;is distance >= &500?
 BCS go_forward                         ;yes
 RTS

.go_forward                             ;move towards my tank
 LDX #&00                               ;enemy unit = &00
 JSR calculate_movement_deltas          ;compute movement distance
 JSR get_tank_type                      ;get tank type
 BCC move_slow                          ;slow tank, move at base rate
 ASL movement_vector_x                  ;super tank so double the movement rate
 ROL movement_vector_x + &01
 ASL movement_vector_z
 ROL movement_vector_z + &01
.move_slow
 JSR move_forward                       ;update the unit's position
; JSR check_obstacle_unit_collision      ;did we drive into something?
 BCS hit_something                      ;yes, handle it
 LDA #&00                               ;move tracks forward
 STA tracks_active
 LDA tank_or_super_or_missile + &01     ;are we moving without turning?
 CMP enemy_turn_to
 BEQ move_again                         ;yes, both treads fwd, move again
 RTS

.move_again
 JSR move_forward                       ;update unit position
; JSR check_obstacle_unit_collision      ;did we drive into something?
 BCS hit_something                      ;yes
 RTS

.hit_something
 LDA game_mode                          ;are we playing now?
 BNE not_playing                        ;no, branch with a = 0 (don't reverse)
 ORA #&00                               ;set flags for a (&00=obstacle, &ff=
 BMI hit_player
 LDA random                             ;get random value
 AND #&02                               ;0 or 2 (determines direction turned)
 ORA #&01                               ;1 or 3 (&01 = reversing)

.not_playing
 ORA enemy_rev_flags
 STA enemy_rev_flags                    ;set flags
 LDA #&03                               ;repeat for 3 seconds
 STA ai_clock        
.hit_player
 LDX #&00
 JMP copy_position_restore              ;restore original position

 ;
 ; The move counter expired.  Pick a new direction to move toward.  If we're
 ; being nice we'll drive a bit randomly, but once the game gets going we just
 ; use the angle to the player
 ;
.set_tank_turn_to
 LDA game_mode                          ;are we playing the game?
 BNE go_mild                            ;then attract mode
 LDA rez_protect                        ;has summoning sickness worn off?
 CMP #&FF
 BEQ go_hard                            ;yes, don't be nice
 LDA random + &01                       ;get a random number
 LSR A                                  ;shift low bit into carry flag
 BCC go_hard                            ;50/50 chance
 LDA player_score + &01                 ;score >= 100K?
 BNE go_hard                            ;yes
 LDA player_score                       ;compare player score to enemy score to gauge enemy ai
; SEC
; SBC enemy_score                        ;decimal mode not required
 CMP enemy_score
 BEQ go_medium
 BCC go_mild
 BCS go_hard

.go_medium                              ;after a recent rez the player is winning, but just barely,  pick an off-target angle
 LDA random + &03
 AND #&07                               ;0-7
 BNE seven_of_eight                     ;7 out of 8 times, branch
 LDA #&01                               ;set the move-backward flag
 ORA enemy_rev_flags
 STA enemy_rev_flags
 BNE set_counter                        ;always

.seven_of_eight
 LDA #&00
 STA enemy_rev_flags                    ;clear move-backward flag

 LDA angle_to_player                    ;get the angle to the player
 EOR #&C0                               ;pick a direction 90 degrees off (&80, &40)
 STA enemy_turn_to                      ;head that way
.set_counter
 LDA #&04                               ;move this way for 4 seconds
 STA ai_clock        
 RTS

.go_mild                                ;enemy out scoring my tank so go easy
 LDA random + &02                       ;get random value for angle offset
 AND #&1F                               ;reduce to 45 degrees
 BIT random + &03
 BMI is_negative
 SBC enemy_turn_to                      ;offset previous turn-to
 BNE TurnComm
.is_negative
 ADC enemy_turn_to
.TurnComm
 STA enemy_turn_to                      ;set new direction
 LDA #&00
 STA enemy_rev_flags                    ;clear reverse flag
 JMP update_move_control_and_angle

.go_hard                                ;head directly at my tank
 LDA angle_to_player                    ;get angle to player
 EOR #&80
 STA enemy_turn_to                      ;use that
 LDA #&80
 STA enemy_rev_flags                    ;clear reverse flag
 JMP update_move_control_and_angle

 ; Attempts to shoot the player.  Does not fire if the player or enemy is
 ; newly-spawned, if the angle is too large, or the relative scores indicate that
 ; we should be mellow
 ;
 ; On exit if we thought about taking a shot.
 ;   &08/09. abs(deltaZ)
 ;   &0a/0b. abs(deltaX)
 ;
.tmp_08 EQUB &08

.try_shoot_player
 LDA rez_protect                        ;check frames since player or unit spawn
 CMP #&20                               ;> 2 seconds?
 BCS not_new_result                     ;yes
.return_tank
 RTS                                    ;no, don't be unfair

.not_new_result
 LDA ai_clock                           ;has it been 17 seconds?
 BEQ shoot_okay                         ;yes
 LDA player_score + &01                 ;score >= 100K points?
 BNE shoot_okay                         ;yes
 LDA player_score
 LSR A                                  ;score >= 2000 points?
 BNE shoot_okay                         ;yes
 LDA enemy_ang_delt_abs                 ;check angle to player
 CMP #&20                               ;within 45 degrees?
 BCS return_tank                        ;no, don't shoot
 LDA enemy_dist_hi                      ;are they somewhat close?
 CMP #&24
 BCS return_tank                        ;no, don't shoot
.shoot_okay
 LDA angle_to_player                    ;get angle to player
 EOR #&80
 SEC                                    ;compute difference of enemy facing and angle
 SBC tank_or_super_or_missile + &01
 BPL is_pos_tank
 CLC                                    ;negative value, invert
 EOR #&FF
 ADC #&02                               ;add 2 instead of 1
.is_pos_tank
 CMP #&02                               ;off by >= 2 angle units?
 BCS return_tank                        ;yes, don't fire
 LDA projectile_state_1                 ;are we ready to fire?
 BNE return_tank                        ;no, our projectile is active
 LDA m_tank_status                      ;player alive?
 BPL return_tank                        ;no

 LDA #&7F / &04                         ;init time-to-live, shoot at my tank
 STA projectile_state_1
 INC sound_tank_shot_soft

 LDA tank_or_super_or_missile + &01     ;get enemy tank's facing angle
 JSR cosine_256                         ;compute cosine
 STX tmp_08                             ;save low byte
 STA enemy_projectile_velocity_z        ;save high byte in low byte z velocity
 ASL A
 LDA #&00
 ADC #&FF
 EOR #&FF
 ASL tmp_08                             ;multiply by 2 to get >> 7 overall
 ROL enemy_projectile_velocity_z
 ROL A
 STA enemy_projectile_velocity_z + &01

 LDA tank_or_super_or_missile + &01
 JSR sine_256
 STX tmp_08
 STA enemy_projectile_velocity_x
 ASL A
 LDA #&00
 ADC #&FF
 EOR #&FF
 ASL tmp_08
 ROL enemy_projectile_velocity_x
 ROL A
 STA enemy_projectile_velocity_x + &01

 LDA #object_x06_tank_shot              ;enable enemy shot
 STA tank_shell
 LDA m_tank_x_00                        ;copy enemy position to enemy projectile
 STA tank_shell + &02
 LDA m_tank_x_00 + &01
 STA tank_shell + &03
 LDA m_tank_z_00
 STA tank_shell + &06
 LDA m_tank_z_00 + &01
 STA tank_shell + &07
 RTS

.update_move_control_and_angle
 PHA
 LDA game_mode
 BEQ do_play                            ;playing
 LDA #&03                               ;no, just use basic movement for 3 seconds
 STA ai_clock        
 LDA #&0A
 ASL A                                  ;multiply by 2 (so &01 -> &02, &08 -> &10)
 STA close_firing_angle
 PLA
 RTS

.do_play
 CMP #&05                               ;a = &00 or (usually &80)
 BCS greater_than_five
 STA ai_clock                           ;set counter to zero
 LDA #&05
 SBC ai_clock                           ;note carry is clear, so this yields 4
 ASL A
 ASL A
 ASL A
 ASL A                                  ;&40
 BNE long                               ;always

.greater_than_five
 LDA #&04                               ;move 4 steps then re-evaluate
.long
 STA ai_clock                           ;cause &CF to alternate between &02 and &10?
 BIT close_firing_angle                 ;high bit set? (never see this)
 BMI use_ten
 LDA #&0A                               ;value = &0a - value
 SEC
 SBC close_firing_angle
 BCS do_shift_one                       ;if value was &02, a holds &08
 LDA #&01                               ;value was &10
 BNE do_shift_one                       ;always

.use_ten
 LDA #&0A
.do_shift_one
 ASL A                                  ;multiply by 2 (so &01 -> &02, &08 -> &10)
 STA close_firing_angle
 PLA
 RTS

.temp_a6          EQUB &00
.missile_hop_flag EQUB &00

.update_missile
 LDA #&00                               ;is the altitude < &200?
 STA tracks_active                      ;move tracks forward/missile drip counter
 CMP tank_or_super_or_missile + &04
 LDA #&02
 SBC tank_or_super_or_missile + &05     ;carry is set if near ground
 LDA #&00
 ROL A
 STA temp_a6                            ;set to &01 for low altitude
 AND missile_hop_flag                   ;clear it if we're hopping
 BEQ no_hop                             ;not hopping, do regular stuff

.fly_up                                 ;low altitude, hopping, fly up
 INC tank_or_super_or_missile + &05     ;inc high byte y
 RTS

.no_hop
 LDA m_tank_rotation_256                ;compute the difference between the direction
 SEC                                    ;player is facing and the direction we're
 SBC enemy_turn_to                      ;heading (should be close to &80)
 STA workspace                          ;save it
 BPL is_pos_missile
 CLC                                    ;get absolute value
 EOR #&FF
 ADC #&01
.is_pos_missile
 CMP #&40                               ;>= 90 degrees?
 BCS big_angle                          ;yes
 BIT workspace                          ;check sign
 BPL turn_right_two                     ;turn right or left
 BMI turn_left_two                      ;always

.big_angle
 LDA angle_to_player                    ;get angle from missile to player
 EOR #&80
 STA workspace
 LDA enemy_turn_to                      ;get direction we're currently heading
 SEC
 SBC workspace                          ;subtract angle
 BEQ turn_common                        ;headed straight at player
 BPL big_push
 CMP #&FD                               ;turn left once or twice depending on angle
 BCC turn_left_one
.turn_left_two
 INC enemy_turn_to
.turn_left_one
 INC enemy_turn_to
 JMP turn_common

.big_push
 CMP #&03                               ;turn right once or twice
 BCC turn_right_one
.turn_right_two
 DEC enemy_turn_to
.turn_right_one
 DEC enemy_turn_to
.turn_common
 LDA missile_count                      ;first missile ever
 BEQ final_turn                         ;yes, fly straight in
 ; check the score to see if missiles should be nastier, which happens at 25k
 ; points beyond the initial missile threshold.  in this context, "nasty"
 ; determines how far the missile is from the player when it stops swerving.
 LDA player_score + &01                 ;over 100k points?
 BNE harsh
 LDX missile_appears_at_index           ;get the missiles first appear at value
 LDA missile_appears_at_score,X
 CLC
 SED
 ADC #&25                               ;add bcd 25 (30 / 35 / 45 / 55)
 CLD
 SEC
 SBC player_score                       ;subtract score (BUG? not in decimal mode
 BMI harsh                              ;score is higher than second threshold, b
 CMP #&08                               ;is it getting close?
 BCS sub_harsh                          ;no, use score diff as distance threshold
.harsh
 LDA #&08                               ;use distance threshold of &0800 - very close
.sub_harsh
 CMP enemy_dist_hi                      ;are we within threshold?
 BCC not_point_blank                    ;no, still far away
.final_turn
 LDA enemy_turn_to                      ;head at player
 JMP move_missile

 ; make the missile swerve
 ;
 ; the big swerves aren't done by changing the missile's desired direction -- the
 ; small rotations performed earlier update the desired facing to match changes
 ; in the position of the player and the missile.  the big swerves are done by
 ; setting the missile's facing to an angle offset from the desired angle.
 ;
 ; the amount of swerve is determined by the low 5 bits of the game frame
 ; counter, which cycle in the span of 2 seconds.
.not_point_blank
 LDA random
 LSR A                                  ;shift bit 3 (&08) into the carry flag
 LSR A                                  ;will be set for 0.5 sec, clear for 0.5 s
 LSR A                                  ;this determines whether we swerve left or right
 LSR A
 LDA random                             ;get counter again
 AND #%00011111                         ;keep the low 5 bits
 STA tmp_08
 LDA enemy_turn_to                      ;get desired facing
 BCS desired_facing
 ADC tmp_08                             ;add or subtract the bits
 JMP move_missile

.desired_facing
 SBC tmp_08
.move_missile                           ;move missile forward in facing firection
 STA tank_or_super_or_missile + &01     ;set the facing direction
 ; move the missile forward in the direction it's currently facing.  we take the
 ; sin/cos values (&0000-7fff) and right-shift them 6x with sign extension (+/-
 ; 512), which is easiest to do by shifting a byte right and then 2 bits left.

 JSR sine_256                           ;compute sine
 STA movement_vector_x                  ;save the high byte
 ASL A
 LDA #&00
 ADC #&FF
 EOR #&FF
 STA movement_vector_x + &01
 TXA                                    ;low cosine byte
 ASL A                                  ;shift left
 ROL movement_vector_x                  ;roll the bit in
 ROL movement_vector_x + &01
 ASL A
 ROL movement_vector_x
 ROL movement_vector_x + &01

 LDA tank_or_super_or_missile + &01
 JSR cosine_256                         ;compute cosine
 STA movement_vector_z                  ;save the high byte
 ASL A
 LDA #&00
 ADC #&FF
 EOR #&FF
 STA movement_vector_z + &01
 TXA                                    ;low cosine byte
 ASL A
 ROL movement_vector_z
 ROL movement_vector_z + &01
 ASL A
 ROL movement_vector_z
 ROL movement_vector_z + &01

 LDX #&00                               ;save tank/super tank/missile position
 JSR copy_position_save                 ;x = &00 for enemy unit
 JSR move_forward                       ;x preserved from above call
; JSR projectile_unit_collision_test     ;did the player shoot us?
; BCS missile_return                     ;yes, blow up soon
; LDX #&00
; JSR check_obstacle_unit_collision      ;see if we collided with an obstacle or player
 BCC no_collision
 LDX temp_a6                            ;at low altitude?
 BNE handle_collision                   ;yes, we didn't fly over, handle it
 RTS                                    ;no, we flew over it

.no_collision
 LDA #&00
 STA missile_hop_flag                   ;no longer colliding, clear hop flag
 LDA tank_or_super_or_missile + &04     ;check the current altitude
 ORA tank_or_super_or_missile + &05
 BEQ missile_return                     ;at ground level so leave
 DEC tank_or_super_or_missile + &05     ;decrement high byte
.missile_return
 RTS

.handle_collision
 ORA #&00                               ;set flags for a (&00=obstacle, &ff=player)
 BMI player_really_dead
 INC missile_hop_flag                   ;set hop flag
 LDX #&00                               ;restore tank/super tank/missile position
 JMP copy_position_restore

.player_really_dead                     ;missile and player collided
 LDA #&20                               ;player and missile both die
 STA enemy_state

 LDA #&80
 STA m_tank_status                      ;my tank dead
 LDA #&07
 STA b_object_bounce_near               ;object bounce
 INC b_object_bounce_far                ;horizon movement
 INC enemy_score                        ;no decimal add as max player tanks is 7 so cannot overflow, use below to exit

.clc_return00
 CLC
 RTS

.projectile_unit_collision_test         ;test projectile collision, my shot -> enemy tank/super/missile, enemy shot -> my tank
 LDA m_shell,X                          ;x = projectile owner, = &00 my tank = &08 enemy, c=1 collision
 BMI clc_return00                       ;not in flight so return
 SEC
 LDA m_shell + &02,X                    ;delta x
 SBC tank_or_super_or_missile + &02,X
 STA distance_dx
 LDA m_shell + &03,X
 SBC tank_or_super_or_missile + &03,X
 STA distance_dx + &01
 SEC
 LDA m_shell + &06,X                    ;delta z
 SBC tank_or_super_or_missile + &06,X
 STA distance_dz
 LDA m_shell + &07,X
 SBC tank_or_super_or_missile + &07,X
 STA distance_dz + &01
 JSR mathbox_distance16
 LDA d_object_distance + &01            ;too large
 BMI clc_return00
 LSR A
 ROR workspace
 LSR A

 BNE clc_return                         ;still missed
 ROR workspace

 BIT missile_flag                       ;by design if missile in flight then no enemy shot in flight
 BPL not_test_for_missile

 LDA tank_or_super_or_missile + &05     ;missile y coordinate
 CMP #&02
 BCS clc_return                         ;missile altitude too high so missed

.not_test_for_missile
 LDA tank_or_super_or_missile + &01,X   ;subtract angle projectile owner from
 SEC
 SBC tank_or_super_or_missile + &01,Y
 ASL A
 BPL not_negate_angle
 EOR #&FF
 CLC
 ADC #&01
.not_negate_angle
 LSR A
 LSR A
 BIT missile_flag
 BMI is_a_missile
 LSR A
 BPL comm
.is_a_missile
 CLC
 ADC #24
.comm
 STA workspace + &01
 LSR A
 CLC
 ADC workspace + &01
 ADC #56
 STA workspace + &01
 CMP d_object_distance
 BCC clc_return
 RTS

.clc_return
 CLC
 RTS

.move_backward_one
 LDX #&00
 JSR calculate_movement_deltas          ;calculate forward movement
 LDA tank_or_super_or_missile + &06,X   ;subtract movement delta from position
 SEC
 SBC movement_vector_z
 STA tank_or_super_or_missile + &06,X
 LDA tank_or_super_or_missile + &07,X
 SBC movement_vector_z + &01
 STA tank_or_super_or_missile + &07,X
 SEC
 LDA tank_or_super_or_missile + &02,X
 SBC movement_vector_x
 STA tank_or_super_or_missile + &02,X
 LDA tank_or_super_or_missile + &03,X
 SBC movement_vector_x + &01
 STA tank_or_super_or_missile + &03,X
 RTS

.projectile_object_collision_test       ;test collision of projectile with geometrical objects, x = projectile offset
 STX general_x                          ;from object start, no short cubes tested
 LDY #(object_shot_collision_end - object_shot_collision_start) - block_size
.projectile_collide_loop                ;colliding with objects
 STY general_y
 SEC
 LDA object_shot_collision_start + &02,Y;calculate delta x distance to object
 SBC object_shot_collision_start + &02,X
 STA distance_dx
 LDA object_shot_collision_start + &03,Y
 SBC object_shot_collision_start + &03,X
 STA distance_dx + &01
 BPL projectile_quick_check_x           ;quick check for x bounding
 EOR #&FF
 CLC
 ADC #&01
.projectile_quick_check_x
 CMP #HI(object_bounding_box)
 BCS no_projectile_collision            ;not in x range
 SEC
 LDA object_shot_collision_start + &06,Y
 SBC object_shot_collision_start + &06,X
 STA distance_dz                        ;calculate delta z distance to object
 LDA object_shot_collision_start + &07,Y
 SBC object_shot_collision_start + &07,X
 STA distance_dz + &01
 BPL projectile_quick_check_z           ;quick check for z bounding
 EOR #&FF
 CLC
 ADC #&01
.projectile_quick_check_z
 CMP #HI(object_bounding_box)
 BCS no_projectile_collision            ;not in z range
 JSR mathbox_distance16
 LDY general_y
 LDX object_shot_collision_start,Y      ;geometrical object id
 LDA obstacle_radius_lsb,X
 CMP d_object_distance
 LDA obstacle_radius_msb,X
 SBC d_object_distance + &01
 LDX general_x
 BCS projectile_collision_exit
.no_projectile_collision
 LDA general_y                          ;next object block
 SEC
 SBC #block_size
 TAY
 BCS projectile_collide_loop
.projectile_collision_exit
 RTS

.enemy_projectile                       ;maintain enemy shot
 BIT tank_shell
 BMI tank_shell_not_in_flight_exit
 LDX #tank_shell - object_shot_collision_start
 JSR projectile_object_collision_test
 LDX #block_size                        ;enemy shot
 JSR projectile_unit_collision_test
 BCC enemy_projectile_saucer
 INC sound_explosion_loud               ;loud for my tank destroyed
 INC enemy_score                        ;chalk one up to enemy tank
 DEC m_tank_status                      ;kill player
 RTS
.enemy_projectile_saucer
 BIT saucer                             ;saucer on?
 BMI tank_shell_not_in_flight_exit
 LDA saucer_dying                       ;saucer dying?
 BNE tank_shell_not_in_flight_exit      ;yes
.tank_shell_not_in_flight_exit
 RTS

.print_variables
 LDY #&00
 LDA hex
 JSR print_it_in_hex
 LDY #&08
 LDA hex + &01
 JMP print_it_in_hex

.hex EQUW &FFFF
