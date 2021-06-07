; mathbox variables
; constants
 mathbox_claim_id                       = &28                           ;arbitary number
 mathbox_toggle                         = &13C

; mathbox functions implemented
 mathbox_code_presence                  = &00
 mathbox_code_signed_division16         = &01
 mathbox_code_signed_multiply16         = &02
 mathbox_code_square_root16             = &03
 mathbox_code_rotation_angles08         = &04
 mathbox_code_rotation_vertice16        = &05
 mathbox_code_rotate16                  = &06
 mathbox_code_line_draw16               = &07
 mathbox_code_signed_division24         = &08
 mathbox_code_screen_address            = &09
 mathbox_code_distance16                = &0A
 mathbox_code_window16                  = &0B
 mathbox_code_line_clip16               = &0C

; addresses
 host_control_block_pointer             = &00                           ;+1
 host_register_block                    = &02                           ;invoke function code
 host_r0                                = host_register_block
 host_r1                                = host_register_block + &02
 host_r2                                = host_register_block + &04
 host_r3                                = host_register_block + &06
 host_flags                             = host_register_block + &08
 host_function_code                     = host_register_block + &09
 host_register_block_end                = host_function_code  + &01

 mathbox_workspace                      = host_register_block_end
 mathbox_vector                         = mathbox_workspace + &02

 host_control_block_tube_flag           = &14
 host_control_block_claim_id            = &15

 mathbox_screen_address                 = &9000
 mathbox_register_block                 = &9600
 mathbox_execute_address                = &960C

; mathbox registers optimised at 4 to take a full line segment x0/y0/x1/y1
 mathbox_r0                             = mathbox_register_block
 mathbox_r1                             = mathbox_register_block + &02
 mathbox_r2                             = mathbox_register_block + &04
 mathbox_r3                             = mathbox_register_block + &06
 
; mathbox host flags returned, principally used for line clipping bit 0
 mathbox_host_flags                     = mathbox_register_block + &08

; mathbox function to be invoked
 mathbox_function_code                  = mathbox_register_block + &09
