/* Minimal stress reproducer for intermittent exec failures in an
 * ntlibc-linked GNU make running under Wine.
 *
 * The parent repeatedly creates make-like output and exec-error pipes,
 * forks, redirects the child's stdout/stderr, and execs either itself or
 * an executable supplied on the command line.  The error-pipe write end is
 * FD_CLOEXEC: a successful exec closes it, while a returned execv() sends
 * errno and an immediate stat/access recheck back to the parent.
 *
 * Usage:
 *   ntlibc-fork-exec-stress.exe [iterations [program.exe]]
 *
 * With no program, the executable execs itself in a child-only mode.  To
 * exercise the exact compiler which GNU make failed to start, pass tcc.exe;
 * the reproducer invokes an external program with "-v" and discards output.
 */

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define DEFAULT_ITERATIONS 1000

struct exec_failure {
	int exec_errno;
	int stat_result;
	int stat_errno;
	unsigned int mode;
	int access_result;
	int access_errno;
};

static int write_all(int fd, const void *data, size_t size)
{
	const char *p = data;
	while (size) {
		ssize_t n = write(fd, p, size);
		if (n < 0 && errno == EINTR) continue;
		if (n <= 0) return -1;
		p += n;
		size -= (size_t)n;
	}
	return 0;
}

static ssize_t read_all(int fd, void *data, size_t size)
{
	char *p = data;
	size_t done = 0;
	while (done < size) {
		ssize_t n = read(fd, p + done, size - done);
		if (n < 0 && errno == EINTR) continue;
		if (n < 0) return -1;
		if (n == 0) break;
		done += (size_t)n;
	}
	return (ssize_t)done;
}

static int drain(int fd)
{
	char buf[4096];
	for (;;) {
		ssize_t n = read(fd, buf, sizeof buf);
		if (n < 0 && errno == EINTR) continue;
		if (n < 0) return -1;
		if (n == 0) return 0;
	}
}

int main(int argc, char **argv)
{
	const char *program;
	int iterations = DEFAULT_ITERATIONS;
	int external = 0;
	int failures = 0;
	int abnormal = 0;
	int i;

	if (argc > 1 && strcmp(argv[1], "--child") == 0) return 0;
	if (argc > 1) iterations = atoi(argv[1]);
	if (iterations <= 0) iterations = DEFAULT_ITERATIONS;
	program = argv[0];
	if (argc > 2) {
		program = argv[2];
		external = 1;
	}

	for (i = 0; i < iterations; ++i) {
		int output_pipe[2];
		int error_pipe[2];
		pid_t pid;
		pid_t waited;
		int status = 0;
		struct exec_failure report;
		ssize_t report_size;

		if (pipe(output_pipe) < 0 || pipe(error_pipe) < 0) {
			printf("iteration %d: pipe: %s\n", i, strerror(errno));
			return 2;
		}
		if (fcntl(error_pipe[1], F_SETFD, FD_CLOEXEC) < 0) {
			printf("iteration %d: fcntl(FD_CLOEXEC): %s\n",
			       i, strerror(errno));
			return 2;
		}

		pid = fork();
		if (pid < 0) {
			printf("iteration %d: fork: %s\n", i, strerror(errno));
			return 2;
		}
		if (pid == 0) {
			char *child_argv[3];
			int saved_errno;
			struct stat st;

			close(output_pipe[0]);
			close(error_pipe[0]);
			if (dup2(output_pipe[1], STDOUT_FILENO) < 0 ||
			    dup2(output_pipe[1], STDERR_FILENO) < 0)
				_exit(126);
			if (output_pipe[1] != STDOUT_FILENO &&
			    output_pipe[1] != STDERR_FILENO)
				close(output_pipe[1]);

			child_argv[0] = (char *)program;
			child_argv[1] = external ? (char *)"-v" : (char *)"--child";
			child_argv[2] = 0;
			execv(program, child_argv);

			saved_errno = errno;
			memset(&report, 0, sizeof report);
			report.exec_errno = saved_errno;
			errno = 0;
			report.stat_result = stat(program, &st);
			report.stat_errno = errno;
			if (report.stat_result == 0) report.mode = (unsigned int)st.st_mode;
			errno = 0;
			report.access_result = access(program, X_OK);
			report.access_errno = errno;
			write_all(error_pipe[1], &report, sizeof report);
			_exit(127);
		}

		close(output_pipe[1]);
		close(error_pipe[1]);
		if (drain(output_pipe[0]) < 0) {
			printf("iteration %d: reading child output: %s\n",
			       i, strerror(errno));
			return 2;
		}
		close(output_pipe[0]);
		report_size = read_all(error_pipe[0], &report, sizeof report);
		close(error_pipe[0]);
		waited = waitpid(pid, &status, 0);

		if (report_size == (ssize_t)sizeof report) {
			++failures;
			printf("iteration %d: execv(%s) returned %d (%s); "
			       "stat=%d errno=%d mode=%o; access(X_OK)=%d errno=%d\n",
			       i, program, report.exec_errno, strerror(report.exec_errno),
			       report.stat_result, report.stat_errno, report.mode,
			       report.access_result, report.access_errno);
		} else if (report_size != 0) {
			++abnormal;
			printf("iteration %d: short exec-error report: %ld bytes\n",
			       i, (long)report_size);
		}
		if (waited != pid || !WIFEXITED(status) || WEXITSTATUS(status) != 0) {
			++abnormal;
			printf("iteration %d: waitpid=%ld status=0x%x\n",
			       i, (long)waited, (unsigned int)status);
		}
		if ((i + 1) % 100 == 0)
			printf("completed %d/%d (%d exec failures, %d abnormal exits)\n",
			       i + 1, iterations, failures, abnormal);
	}

	printf("ntlibc-fork-exec-stress: %d iterations, %d exec failures, "
	       "%d abnormal exits\n", iterations, failures, abnormal);
	return failures || abnormal;
}
