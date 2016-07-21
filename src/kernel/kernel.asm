; yay os space!
; "My Little Kernel" ABI:
; R0->R3 are return registers
; NO scratch registers
; R5 as a frame pointer
; R0->R3 for the first 4 function inputs
; stack takes the rest
; Stack Frame on function call:
; func(p1,p2,p3,p4,p5,p6)
; r0=p1,r1=p2,r2=p3,r3=p4
; 0x0000
; ======
; ------
; extra local 2
; ------
; extra local 1
; ------
; save regs
; ------
; r5/FP
; ------
; p7
; ------
; p8
; ======
; 0xFFFF
;
; for speed's sake, when a frame pointer is not used
; the locals below the regs

; for libraries, maintain a libtable, so we don't have to constantly maintain everyone's calling


; OS memory map:
; 0x0000
; ======
; TVT
; IVT
; ====== 0x0200
; Kernel procedures
; Hardware drivers
; Drivers
; Syscalls
; kernel lib space x2000 -> x24FF
; Heap	x2500->x2FFF
; ====== 0x3000
; 
; ====== 
; ======
; 0xFFFF


.orig   x0200


kernelmain
    ld  r4, _jtable_thread
    ldr r3, r4, #0  ; get pointer to threadInit

    ; threadInit
    jsrr r3

    ; theadCreate(t2_task, _t2_string)
    ldr r3, r4, #1  ; get pointer to threadCreate
    lea r0, t2_task
    lea r1, _t2_string
    jsrr r3

t1_task
    ldr r3, r4, #2      ; load the pinter to threadYield
    lea r0, _t1_string
_t1_loop
    puts
    jsrr r3 ; yield
    brnzp _t1_loop

_jtable_thread  .fill   x0600

_t1_string  .stringz "I'm the parent thread\n"
_t2_string  .stringz "I'm the child thread\n"

kernelshutdown
	HALT

; inputs: r0 is string ptr
t2_task
    ld  r2, _jtable_thread
    ldr r1, r2, #2  ; load the pointer to yield
_t2_loop
    puts    ;
    jsrr r1 ; yield
    brnzp _t2_loop
    ret

.end