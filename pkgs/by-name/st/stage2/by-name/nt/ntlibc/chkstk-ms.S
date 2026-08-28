/* GCC's i386 PE stack probe.  Unlike ntlibc's __chkstk entry point for
 * TCC, this ABI only touches the prospective frame and returns; GCC emits
 * the actual stack adjustment itself after the call. */

.text
.globl ___chkstk_ms
___chkstk_ms:
	push	%ecx
	push	%eax
	cmp	$4096,%eax
	lea	12(%esp),%ecx
	jb	2f
1:
	sub	$4096,%ecx
	orl	$0,(%ecx)
	sub	$4096,%eax
	cmp	$4096,%eax
	ja	1b
2:
	sub	%eax,%ecx
	orl	$0,(%ecx)
	pop	%eax
	pop	%ecx
	ret
