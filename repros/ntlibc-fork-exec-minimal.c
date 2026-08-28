/* Minimal reproducer for ntlibc fork()+execv() failures under patched Wine.
 *
 * Build this as a PE linked with ntlibc, then run it under Wine.  The parent
 * repeatedly forks; the child execs this same executable; and the exec'd
 * image exits zero.  If execv returns, the forked child exits with errno so
 * the parent can count the failure without an error-reporting pipe.
 *
 * Pass "cloexec" as the second argument to keep one FD_CLOEXEC pipe open
 * across fork.  That is closer to GNU make and greatly amplifies the bug.
 */

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define DEFAULT_ITERATIONS 1000

int main(int argc, char **argv)
{
	int iterations = DEFAULT_ITERATIONS;
	int use_cloexec = 0;
	int failures = 0;
	int i;

	if (argc > 1 && strcmp(argv[1], "--child") == 0) return 0;
	if (argc > 1) iterations = atoi(argv[1]);
	if (iterations <= 0) iterations = DEFAULT_ITERATIONS;
	if (argc > 2 && strcmp(argv[2], "cloexec") == 0) use_cloexec = 1;

	for (i = 0; i < iterations; ++i) {
		int p[2] = { -1, -1 };
		if (use_cloexec &&
		    (pipe(p) < 0 || fcntl(p[1], F_SETFD, FD_CLOEXEC) < 0)) {
			printf("iteration %d: pipe/fcntl returned %d (%s)\n",
			       i, errno, strerror(errno));
			return 2;
		}
		pid_t pid = fork();
		int status;

		if (pid < 0) {
			printf("iteration %d: fork returned %d (%s)\n",
			       i, errno, strerror(errno));
			return 2;
		}
		if (pid == 0) {
			char *child_argv[3];
			child_argv[0] = argv[0];
			child_argv[1] = (char *)"--child";
			child_argv[2] = 0;
			execv(argv[0], child_argv);
			_exit(errno > 0 && errno < 256 ? errno : 255);
		}
		if (p[0] >= 0) close(p[0]);
		if (p[1] >= 0) close(p[1]);

		if (waitpid(pid, &status, 0) != pid) {
			printf("iteration %d: waitpid returned %d (%s)\n",
			       i, errno, strerror(errno));
			return 2;
		}
		if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) {
			++failures;
			printf("iteration %d: child status=0x%x",
			       i, (unsigned int)status);
			if (WIFEXITED(status))
				printf(" (execv errno %d: %s)", WEXITSTATUS(status),
				       strerror(WEXITSTATUS(status)));
			printf("\n");
		}
	}

	printf("ntlibc-fork-exec-minimal: %d iterations, %d failures\n",
	       iterations, failures);
	return failures != 0;
}
