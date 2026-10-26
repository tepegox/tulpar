// Preserve the native entry frame until the synchronous V walk returns.
#ifdef TULPAR_ALLOC_TRACK
.text
.global alloc_track
.type alloc_track, @function
alloc_track:
    pushq %rbp
    movq %rsp, %rbp
    movq %rbp, %rdx
    call tulpar_alloc_track_enter
    popq %rbp
    ret
.size alloc_track, .-alloc_track
.section .note.GNU-stack,"",@progbits
#endif
