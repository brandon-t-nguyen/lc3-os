.ORIG   x2000       ;

__JUMP_TABLE__
; logical and arithmetic
.fill   or
.fill   xor
.fill   lsl
.fill   lsr
.fill   asr
.fill   csl
.fill   csr
.fill   mul
.fill   div
.fill   pow
; data structure
.fill   arrayAccess

;-----------------------------;
;------------Logic------------;
;-----------------------------;

; Subroutine OR: 
; Input: R0=A, R1=B
; Output: R0 = A|B
or
                    ;              |R0         |R1         |
                    ;              |___________|___________|
    NOT R0,R0       ;              |A'         |B          |
    NOT R1,R1       ;              |A'         |B'         |
    AND R0,R0,R1    ;              |A' & B'    |B'         |
    NOT R0,R0       ;              |(A' & B')' |B'         |
    NOT R1,R1       ;R1 restore => |(A' & B')' |B          |
    RET         ;x1005

; Subroutine XOR: 
; Input: R0 = X, R1 = Y
; Output: R0 = X^Y
xor
    ADD  R6,R6,#-3
    STR  R1,R6,#0       ;
    STR  R2,R6,#1       ;
    STR  R7,R6,#2       ; Calls OR
                        ;           |X          |Y          |?          |
                        ;           |R0         |R1         |R2         |
                        ;           |___________|___________|___________|
    ADD R2,R0,#0        ; R2 = X    |X          |Y          |X          |
    NOT R0,R0           ; R0 = X'   |X'         |Y          |X          |
    AND R0,R0,R1        ; R0 = X'&Y |X' & Y     |Y          |X          |
    NOT R1,R1           ; R1 = Y'   |X' & Y     |Y'         |X          |
    AND R1,R1,R2        ; R1 = Y'&X |X' & Y     |Y' & X     |X          |
    JSR or              ; R0 = X^Y  |X ^ Y      |Y' & X     |X          |
                        ;   
    LDR  R1,R6,#0       ;           |X ^ Y      |Y          |X          |
    LDR  R2,R6,#1       ;           |X ^ Y      |Y          |?          |
    LDR  R7,R6,#2       ;
    ADD  R6,R6,#3
    RET                 ;


;-----------------------------;
;-----------Shifts------------;
;-----------------------------;

; LSL (Logical Shift Left) is a subroutine to left shift a number given an input
; Input: R0 = word to be shifted, R1 = number of times to shift
; Output: R0 = shifted word
lsl
    ADD R6,R6,#-1       ;
    STR R1,R6,#0        ;
    ADD R1,R1,#0        ; Update CC for number of times
LSL_OL  
    BRnz    LSL_END     ; If times <= 0 branch to end
    ADD R0,R0,R0        ; Left shift R0
    ADD R1,R1,#-1       ; Decrement times
    BRnzp   LSL_OL      ;
LSL_END                 ;
    LDR R1,R6,#-1       ;
    ADD R6,R6,#1        ;
    RET                 ;

; LSR(Logical Shift Right) is a subroutine to do a right shift a number given an input
; Input: R0 = word to be shifted, R1 = number of times to shift
; Output: R0 = shifted word
; It works by clearing the first "times" bits then doing the CSR
lsr
    ADD R1,R1,#0        ;
    BRz LSR_RET         ; If R1 = 0, do nothing

    ADD R6,R6,#-4
    STR R7,R6,#3
    STR R2,R6,#2
    STR R1,R6,#1
    
    LD  R2,LSR_N16      ;
LSR_FIX 
    ADD R2,R1,R2        ; Add R1 and -16
    BRnz    LSR_CONT    ; If it's negative, that means it doesn't need more subtracting
    ADD R1,R2,#0        ; Move the subtracted result into R1
    BRnzp   LSR_FIX     ; Return to fix to subtract again
LSR_CONT                ; R1 should have a fixed number of times now
    STR R1,R6,#0        ; Temp storage of number of times
    LEA R2,LSR_LU       ;
    ADD R1,R1,R2        ; Get the address of the particular mask into R1
    LDR R2,R1,0         ; Load the mask into R2
    LDR R1,R6,#0        ; Get the fixed times into R1
    AND R0,R0,R2        ; Mask the input with R2
    JSR csr             ; circular right shift the masked input
LSR_END
    STR R7,R6,#3
    STR R2,R6,#2
    STR R1,R6,#1
    ADD R6,R6,#4
LSR_RET 
    RET                 ;
LSR_16  .FILL   16      ; 16
LSR_N16 .FILL   -16     ; -16
                        ; Mask lookup table
LSR_LU  
    .FILL   xFFFF       ; 1111 1111 1111 1111
    .FILL   xFFFE       ; 1111 1111 1111 1110
    .FILL   xFFFC       ; 1111 1111 1111 1100
    .FILL   xFFF8       ; 1111 1111 1111 1000
    .FILL   xFFF0       ; 1111 1111 1111 0000
    .FILL   xFFE0       ; 1111 1111 1110 0000
    .FILL   xFFC0       ; 1111 1111 1100 0000
    .FILL   xFF80       ; 1111 1111 1000 0000
    .FILL   xFF00       ; 1111 1111 0000 0000
    .FILL   xFE00       ; 1111 1110 0000 0000
    .FILL   xFC00       ; 1111 1100 0000 0000
    .FILL   xF800       ; 1111 1000 0000 0000
    .FILL   xF000       ; 1111 0000 0000 0000
    .FILL   xE000       ; 1110 0000 0000 0000
    .FILL   xC000       ; 1100 0000 0000 0000
    .FILL   x8000       ; 1000 0000 0000 0000
    .FILL   x0000       ; 0000 0000 0000 0000
    
; CSL (Circular Shift Left) is a subroutine to circular left shift a number given an input
; Input: R0 = word to be shifted, R1 = number of times to shift
; Output: R0 = shifted word
; Note: It's basically LSL with two more lines of code. Didn't want to have too many inputs for LSL
csl
    ADD R6, R6, #-4
    STR R7, R6, #3
    STR R2, R6, #2
    STR R1, R6, #1

    ADD R1,R1,#0        ; Update CC for number of times
CSL_OL  
    BRnz    CSL_END     ; If times <=0, branch to end
    ADD R2,R0,#0        ; R2 = R0
    STR R1,R6,#0        ; Store times in temp storage
    AND R1,R1,#0        ;
    ADD R1,R1,#1        ; Set R1 to 1 (do one left shift)
    JSR lsl             ; Do a logical left shift
    ADD R2,R2,#0        ; Get CC for word pre-shift
    BRzp    CSL_CONT    ; If the word pre-shift was negative, add 1 to replace the lost MSB
    ADD R0,R0,#1        ;
CSL_CONT
    LDR R1,R6,#0        ; Retrieve times from temp storage
    ADD R1,R1,#-1       ; Decrement times
    BRnzp   CSL_OL      ;
CSL_END
    STR R7, R6, #3
    STR R2, R6, #2
    STR R1, R6, #1
    ADD R6, R6, #4
    RET

; CSR (Circular Shift Right) is a subroutine to do a "quick" circular right shift a number given an input, by doing circular left shifts
; Input: R0 = word to be shifted, R1 = number of times to shift
; Output: R0 = shifted word
; # of CSL = 16 - R1
csr
    ADD R1,R1,#0        ; Get CC for times
    BRz CSR_RET         ; If it's zero, no right shifting
    ADD R6, R6, #-3     ; if early return, don't bother allocation
    STR R7, R6, #2
    STR R2, R6, #1
    STR R1, R6, #0
    LD  R2,CSR_N16      ;
CSR_FIX ADD R2,R1,R2    ; Add R1 and -16
    BRz CSR_END         ; If it results in zero, that means the shift ultimately does nothing
    BRn CSR_CONT        ; If it's negative, that means it doesn't need more subtracting
    ADD R1,R2,#0        ; Move the subtracted result into R1
    BRnzp   CSR_FIX     ; Return to fix to subtract again
CSR_CONT                ; R1 should have a fixed number of times now
    NOT R1,R1           ; Negate R1
    ADD R1,R1,#1
    LD  R2,CSR_16       ; R2 = 16
    ADD R1,R1,R2        ; R1 = 16 - times
    JSR csl             ; Do a circular left shift 16-R1 times
CSR_END
    STR R7, R6, #2
    STR R2, R6, #1
    STR R1, R6, #0
    ADD R6, R6, #3
CSR_RET
    RET
CSR_16  .FILL   16      ;
CSR_N16 .FILL   -16     ;
    
; ASR (Arithmetic Shift Right) is a subroutine to arithmetic right shift a number given an input
; Input: R0 = word to be shifted, R1 = number of times to shift
; Output: R0 = shifted word
; Note:
asr
    ADD R6, R6, #-3
    STR R7, R6, #2
    STR R1, R6, #1

    ADD R1,R1,#0        ; Update CC for number of times
ASR_OL  
    BRnz    ASR_END     ; If times <=0, branch to end
    STR R1,R6,#0        ; Store times in temp storage
    AND R1,R1,#0        ;
    ADD R1,R1,#1        ; Set R1 to 1 (do one left shift)
    JSR lsr             ; Do a logical right shift
    LD  R1,ASR_MSB      ;
    ADD R0,R0,R1        ; Fill the void with a 1
ASR_CONT    
    LDR R1,R6,#0        ; Retrieve times from temp storage
    ADD R1,R1,#-1       ; Decrement times
    BRnzp   ASR_OL      ;
ASR_END
    LDR R7, R6, #2
    LDR R1, R6, #1
    ADD R6, R6, #3
    RET
ASR_MSB     .FILL   x8000   ;

;-----------------------------;
;------------Math ------------;
;-----------------------------;

; Subroutine Multiply
; Input: R0 = A, R1 = B
; Output: R0 = A * B
; This multiply subroutine works like a long multiplication problem

; R0 = A    Number A
; R1 = 0    
; R2 = B    Number B
; R3 = 01   Mask
; R4 = 0000 Output
; R5 = temp
; A * B 
mul
    ADD R6, R6, #-7
    STR R7, R6, #6
    STR R5, R6, #5
    STR R4, R6, #4
    STR R3, R6, #3
    STR R2, R6, #2
    STR R1, R6, #1
    STR R0, R6, #0
    
    ; Set up values
    ADD R2,R1,#0    ; R2 = B
    AND R1,R1,#0    ; R1 = 0
    LD  R3,MUL_MASK ; R3 = 01
    AND R4,R4,#0    ; R4 = 0000
MUL_REPEAT
    AND R5,R2,R3    ; Check the current mask against B to see if A should be added
    BRz MUL_SKIP    ; If there is a 0, skip
    JSR lsl         ; Left shift A by R1 times to get a summation thing
    ADD R4,R0,R4    ; Add the shifted A to the output
    LDR R0,R6,#0    ; The original A into R0
MUL_SKIP
    ADD R1,R1,#1    ; Increment number of shift times
    ADD R3,R3,R3    ; Left shift the mask
    LD  R5,MUL_N15  ; Load the comparison 15
    ADD R5,R1,R5    ; Compare R1 times to 15
    BRn MUL_REPEAT  ; If R1 is less than 15 (R1 - 15 < 0) result is good; else repeat
    ADD R0,R4,#0    ; Move R4 output into R0
    
    LDR R7, R6, #6
    LDR R5, R6, #5
    LDR R4, R6, #4
    LDR R3, R6, #3
    LDR R2, R6, #2
    LDR R1, R6, #1
    LDR R0, R6, #0
    ADD R6, R6, #7
    RET
MUL_N15 .FILL   -15 ;
MUL_MASK .FILL   1  ;

; Subroutine Divide
; Input: R0 = C: Dividend, R1 = D:Divisor
; Output: R0 = C / D : Quotient, R1 = Remainder
; This divide routine is a slow divider. Aww. I can't into long division
div
    ADD R6,R6,#-2       ; allocation
    STR R2,R6,#0        ;
    STR R3,R6,#1        ;
                        ;Count number of negative numbers
                        ;It works by NOT, since negative/positive is a binary thing
    AND R3,R3,#0        ; Clear R3
    ADD R0,R0,#0        ; Get CC of R0
    BRzp    DIV_1       ; If it's negative, NOT R3
    NOT R3,R3           ;
    NOT R0,R0           ; Negate R0 so division works
    ADD R0,R0,#1        ;
DIV_1
    ADD R1,R1,#0        ; Get CC of R1
    BRp DIV_2           ; If it's negative, NOT R3
    BRz DIV_END         ; R1 CAN NOT BE 0
    NOT R3,R3           ;
    NOT R1,R1           ; Negate R0 so division works
    ADD R1,R1,#1        ;
DIV_2
    STR R3,R6,#2        ;
    ADD R2,R0,#0        ; R2 = C
    ADD R3,R1,#0        ; R3 = D
    NOT R3,R3           ; R3 = (-D)
    ADD R3,R3,#1        ;
    AND R0,R0,#0        ; Clear R0 for output
DIV_LOOP    
    ADD R2,R2,#0        ; update CC for R2
    BRz DIV_LOOPZ       ;
    BRn DIV_LOOPN       ; If it extends too far, subtract 1 from quotient
    ADD R2,R2,R3        ; R2 += (-D)
    ADD R0,R0,#1        ;
    BRnzp   DIV_LOOP    ;
DIV_LOOPN
    ADD R0,R0,#-1       ;
    ADD R1,R2,#0        ; Move leftover into R1
    NOT R3,R3           ; Negate R3 (Divisor) so now it's D
    ADD R3,R3,#1        ; 
    ADD R1,R1,R3        ; Form the remainder
    BRnzp   DIV_LOOPE   ;
DIV_LOOPZ
    AND R1,R1,#0        ; clear remainder
DIV_LOOPE
    LDR R3,R6,#2        ; Get whether or not it was negative
    BRzp    DIV_END     ; CC = R3
    NOT R0,R0           ; Negate R0
    ADD R0,R0,#1        ;
    NOT R1,R1           ; Negate R1
    ADD R1,R1,#1        ;
DIV_END
    LDR R2,R6,#0        ;
    LDR R3,R6,#1        ;
    ADD R6,R6,#2        ;
    RET

; Subroutine Power
; Input:  R0 = X, R1 = Y
; Output: R0 = X exp(Y)
; Note: Calls MUL, uses LC3-Extended
pow
    ADD R6, R6, #-3
    STR R7, R6, #2
    STR R2, R6, #1
    STR R1, R6, #0
    
    ADD R2,R1,#0        ; R2 = Y
    ADD R1,R0,#0        ; R1 = X
    ADD R2,R2,#-1       ; Update CC for R2, decrement once because X^1 = X
    BRz POW_ZERO        ;
POW_LOOP    
    BRnz    POW_END     ; Once Y is 0, end
    JSR mul             ;
    ADD R2,R2,#-1       ; Decrement Y
    BRnzp   POW_LOOP    ; Loop back again
POW_ZERO
    AND R0,R0,#0        ; Set R0 to 1 if Y is 0
    ADD R0,R0,#1        ;
POW_END 
    LDR R7, R6, #2
    LDR R2, R6, #1
    LDR R1, R6, #0
    ADD R6, R6, #3
    RET

; Array Access
; void *arrayAccess(void *arr, size_t elementSize (words), int index)
; Inputs: R0=array pointer, R1=elementSize, R2=index
; Output: Pointer to array element
arrayAccess
    add r6, r6, #-4
    str r7, r6, #3
    str r3, r6, #2
    str r2, r6, #1
    str r1, r6, #0

    add r3, r0, #0  ; move ptr to r3
    add r0, r2, #0  ; mul(index,elementSize)
    jsr mul         ; calculate the address offset
    add r0, r3, r0  ; add the offset to the array base and return it

    ldr r7, r6, #3
    ldr r3, r6, #2
    ldr r2, r6, #1
    ldr r1, r6, #0
    add r6, r6, #4

    ret
.END