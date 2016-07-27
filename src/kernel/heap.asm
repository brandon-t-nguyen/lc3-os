.orig x2500

__JUMP_TABLE__
.fill heapInit
.fill malloc
.fill free

heapInit
    add r6, r6, #-2
    str r1, r6, #1
    str r0, r6, #0

    ; body
    ; setup the heap start and end ptrs
    lea r0, _heap_array
    st  r0, _heap_start
    ld  r1, _heap_size
    add r0, r0, r1      ; get to the end of the heap
    st  r0, _heap_end

    ; setup the header and footer of the initial block
    ld  r0, _heap_size
    add r0, r0, #-2     ; take into account the header and footer
    
    ld  r1, _heap_start
    str r0, r1, #0      ; store the initial header

    ld  r1, _heap_end
    str r0, r1, #-1     ; store the initial footer

    ; setup our free list
    ld  r0, _heap_start
    add r0, r0, #1
    st  r0, _heap_free_ptr  ; setup free ptr
    and r1, r1, #0      ; get a null for our first free block to point to
    str r1, r0, #0      ; freePtr->block#0->null

    ldr r1, r6, #1
    ldr r0, r6, #0
    add r6, r6, #2
	ret

; Inputs: R0=size in words to allocate
; Output: R0=pointer to block of memory of at least requested size, or 0 if failed
malloc
    ; this implementation: malloc(0) returns NULL
    add r0, r0, #0
    brz _m_return

    add r6, r6, #-2
    str r7, r6, #1
    str r1, r6, #0
 
    ; check to see if requested amount is less than 2
    ; if it is, set it to 2
    add r1, r0, #-2
    brzp _m_alloc       ; if it's >=2, proceed
    and r0, r0, #0      ; fix the allocation size
    add r0, r0, #2
_m_alloc
    jsr heapLock

    add r1, r0, #0      ; save the size in r1
    jsr findBestBlock
    add r0, r0, #0
    brz _m_fail         ; if null, we have failed
    brnzp _m_succeed    ; otherwise yay!
_m_fail
    and r0, r0, #0
    brnzp _m_endalloc
_m_succeed
    jsr allocBlock      ; size already in r1
    brnzp _m_endalloc

_m_endalloc
    jsr heapUnlock
_m_restore
    ldr r7, r6, #1
    ldr r1, r6, #0
    add r6, r6, #2
_m_return
    ret

free
    jsr heapLock
    jsr heapUnlock
	ret

; findBestBlock
; Assume the free list is sorted from shortest to longest
; Inputs: R0=size in words to get the block for
; Output: R0 is the best block
findBestBlock
    add r6, r6, #-2
    str r2, r6, #1
    str r1, r6, #0

    ld r1, _heap_free_ptr
_fbb_loop
    brz _fbb_fail       ; loop through list, if we reach the end we fail
    ldr r2, r1, #-1     ; get the size
    not r2, r2
    add r2, r2, #1
    add r2, r0, r2      ; compare the reqSize and blockSize: block-req
    brnz _fbb_succeed
    ldr r1, r1, #0      ; next node
_fbb_fail
    and r0, r0, #0
    brnzp _fbb_return
_fbb_succeed
    ; r1 is the block pointer
    add r0, r1, #0  ; move to r0 to return

_fbb_return
    ldr r2, r6, #1
    ldr r1, r6, #0
    add r6, r6, #2
    ret

; allocBlock
; allocate the pointed to block, can break the block into smaller parts
; Inputs: R0=block ptr, R1=size
; Outputs: R0=blockptr
allocBlock
    add r6, r6, #-6
    str r7, r6, #5
    str r4, r6, #4
    str r3, r6, #3
    str r2, r6, #2
    str r1, r6, #1
    str r0, r6, #0

    ; in order to split a block, reqSize <= blocksize-4 (or chunkcsize -6)
    ldr r2, r0, #-1 ; get the block size
    add r2, r2, #-4 ; blocksize-4
    not r2, r2
    add r2, r2, #1
    add r2, r1, r2  ; r2= reqSize - (blocksize-4)
    brp _ab_mark_busy   ; if reqSize is greater, then we can't split the block. proceed onwards!
    ; we can split it
    ldr r2, r0, #-1 ; original block size
    not r3, r1
    add r3, r3, #1  ; neg size in r3
    str r1, r0, #-1 ; store header
    add r4, r1, r0  ; r4=metadata pointer
    str r1, r4, #0  ; store the footer
    add r4, r4, #2  ; point to the next block
    add r2, r2, r3  ; get the new size+2
    add r2, r2, #-2 ; subtract the header
    str r2, r4, #-1 ; store new header
    add r4, r2, r4  ; get to footer
    str r2, r4, #0  ; store footer
    not r1, r2
    add r1, r1, #1
    add r4, r1, r4  ; point r4 back to the second block

    add r2, r0, #0  ; move original block pointer to r2
    add r0, r4, #0  ; move next block to r0
    jsr addFreeBlock
    add r0, r2, #0  ; move original block pointer back

_ab_mark_busy
    ldr r1, r0, #-1 ; get the size
    not r2, r1
    add r2, r2, #1  ; set the size to negative to mark busy
    str r2, r0, #-1 ; store the header
    add r3, r0, r1  ; point to the end of the block
    str r2, r3, #0  ; store the footer
    ; remove it from the list
    jsr removeBlock ; remove it from the list

_ab_return
    ldr r7, r6, #5
    ldr r4, r6, #4
    ldr r3, r6, #3
    ldr r2, r6, #2
    ldr r1, r6, #1
    ldr r0, r6, #0
    add r6, r6, #6
    ret

; inputs: r0 points to block
; free list is sorted from smallest to largest
addFreeBlock
    add r6, r6, #-5
    str r4, r6, #4
    str r3, r6, #3
    str r2, r6, #2
    str r1, r6, #1
    str r0, r6, #0
    
    ldr r1, r0, #-1         ; get the size into r1
    not r1, r1
    add r1, r1, #1          ; negate the size to do comparisons
    ld  r2, _heap_free_ptr  ; r2=currentptr
    ; initial check: is it smaller than the first free block?
    ldr r3, r2, #-1     ; get current free block size
    add r3, r1, r3      ; r3=currSize - freeSize
    brn _afb_traverse   ; if freesize is bigger, skip this step
                        ; if it's smaller or same, stuff it in the front
    str r0, r2, #1      ; head->back = free, store freeptr into the head's back ptr
    str r2, r0, #0      ; free->fwd = head, store the headptr into the freeptr's forward ptr
    and r3, r3, #0
    str r3, r0, #1          ; nullify the backptr of the head
    st  r0, _heap_free_ptr  ; free is the new head
    brnzp _afb_return
_afb_traverse
    ldr r4, r2, #0          ; r4=next ptr
    brz _afb_add_to_end
    ldr r3, r2, #-1         ; r3=curr size
    add r3, r1, r3          ; r3=curr size - free size
    brp _afb_traverse       ; if if free size < curr size, next
    ; add node
    str r4, r0, #0          ; store nextptr into free fwd
    str r2, r0, #1          ; store currptr into free bck
    str r0, r4, #1          ; store freeptr into next bck
    str r0, r2, #0          ; store freeptr into curr fwd
    brnzp _afb_return
_afb_add_to_end
    str r0, r2, #0  ; store free ptr into last ptr
    str r2, r0, #1  ; store lastptr into free bck
    and r3, r3, #0
    str r3, r0, #0  ; store null into free fwd

_afb_return
    ldr r4, r6, #4
    ldr r3, r6, #3
    ldr r2, r6, #2
    ldr r1, r6, #1
    ldr r0, r6, #0
    add r6, r6, #5
    ret

; removes block from list
; inputs: r0 points to block to remove from list
removeBlock
    add r6, r6, #-2
    str r2, r6, #1
    str r1, r6, #0

    ldr r1, r0, #0  ; r1=fwd
    ldr r2, r0, #1  ; r2=bck

    ; if the back is null, it's the head
    brz _rb_head
    ; we have a valid back pointer
    str r1, r2, #0  ; bck->fwd = fwd

    add r1, r1, #0  ;
    brz _rb_return  ; if (!fwd), return
    str r2, r1, #1  ; fwd->bck = bck
    brnzp _rb_return

_rb_head
    add r1, r1, #0
    brz _rb_head_empty
    ; if the head isn't empty, move the fwd ptr into it
    st  r1, _heap_free_ptr
    brnzp _rb_return

_rb_head_empty
    and r1, r1, #0
    st  r1, _heap_free_ptr

_rb_return
    ldr r2, r6, #1
    ldr r1, r6, #0
    add r6, r6, #2
    ret

heapLock
    ret
heapUnlock
    ret

_heap_free_ptr  .blkw 1
_heap_start     .blkw 1 ; pointer to start of the heap, inclusive
_heap_end       .blkw 1 ; pointer to the end of the heap, exclusive
_heap_size .fill 20
_heap_array .blkw 20
;_heap_size .fill x0A00
;_heap_array .blkw x0A00
.end