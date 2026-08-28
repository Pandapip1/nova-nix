/* Native compiler wrapper for the bootstrap Windows stdenv.
 *
 * The bootstrap gcc driver can emit assembly, but its compile-to-object
 * temporary-file path and its driver-mediated linker are not usable yet.
 * Compile mode therefore runs gcc -S followed by tcc -c; link mode compiles
 * C sources the same way and links the resulting objects with tcc.
 *
 * This must be a PE executable.  A script found through PATH either is not
 * executable on Windows or escapes Wine through host-side shebang handling.
 */

#define _GNU_SOURCE 1

#include <errno.h>
#include <libgen.h>
#include <spawn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

enum mode {
  MODE_LINK,
  MODE_COMPILE,
  MODE_PASSTHROUGH
};

static const char *program_name;

static void die(const char *message)
{
  fprintf(stderr, "%s: %s\n", program_name, message);
  exit(1);
}

static void *xmalloc(size_t size)
{
  void *result = malloc(size);
  if (!result)
    die("out of memory");
  return result;
}

static char *join2(const char *left, const char *right)
{
  size_t left_len = strlen(left);
  size_t right_len = strlen(right);
  char *result = xmalloc(left_len + right_len + 1);
  memcpy(result, left, left_len);
  memcpy(result + left_len, right, right_len + 1);
  return result;
}

static const char *required_env(const char *name)
{
  const char *value = getenv(name);
  if (!value || !*value) {
    fprintf(stderr, "%s: required environment variable %s is unset\n",
            program_name, name);
    exit(1);
  }
  return value;
}

static int run(const char *path, char *const argv[])
{
  pid_t pid;
  int status;
  int error = posix_spawn(&pid, path, 0, 0, argv, environ);

  if (error) {
    fprintf(stderr, "%s: cannot run %s: %s\n",
            program_name, path, strerror(error));
    return 127;
  }
  if (waitpid(pid, &status, 0) < 0) {
    fprintf(stderr, "%s: waiting for %s: %s\n",
            program_name, path, strerror(errno));
    return 127;
  }
  if (WIFEXITED(status))
    return WEXITSTATUS(status);
  if (WIFSIGNALED(status))
    return 128 + WTERMSIG(status);
  return 127;
}

static int is_c_source(const char *arg)
{
  size_t len = strlen(arg);
  return len >= 2 && strcmp(arg + len - 2, ".c") == 0;
}

static char *object_basename(const char *source)
{
  char *copy = join2(source, "");
  char *base = basename(copy);
  size_t len = strlen(base);
  char *result;

  if (len >= 2 && strcmp(base + len - 2, ".c") == 0)
    len -= 2;
  result = xmalloc(len + 3);
  memcpy(result, base, len);
  memcpy(result + len, ".o", 3);
  free(copy);
  return result;
}

static void remove_temporaries(char **files, int count, const char *directory)
{
  int i;
  for (i = 0; i < count; ++i) {
    if (files[i]) {
      unlink(files[i]);
      free(files[i]);
    }
  }
  rmdir(directory);
}

int main(int argc, char **argv)
{
  enum mode mode = MODE_LINK;
  const char *out_file = 0;
  const char *tmp = getenv("TMPDIR");
  const char *tcc;
  const char *gcc_dir;
  const char *gcc_libdir;
  const char *libc_lib;
  const char *include;
  const char *source_include;
  const char *arch_i386;
  const char *arch_generic;
  char *real_gcc;
  char *crt1;
  char *stack_probe;
  char *inc_flags[4];
  char **sources = xmalloc((size_t)argc * sizeof(*sources));
  char **other = xmalloc((size_t)argc * sizeof(*other));
  char **temporary_files = xmalloc((size_t)argc * sizeof(*temporary_files));
  char **objects = xmalloc((size_t)argc * sizeof(*objects));
  int source_count = 0;
  int other_count = 0;
  int object_count = 0;
  int temporary_count = 0;
  int i;
  int status = 0;
  char temp_dir[1024];

  program_name = argc > 0 ? argv[0] : "cc-wrapper";
  tcc = required_env("NN_TCC");
  gcc_dir = required_env("NN_GCC");
  gcc_libdir = required_env("NN_GCC_LIBDIR");
  libc_lib = required_env("NN_NTLIBC_LIB");
  include = required_env("NN_NTLIBC_INCLUDE");
  source_include = required_env("NN_NTLIBC_SRC_INCLUDE");
  arch_i386 = required_env("NN_NTLIBC_ARCH_I386");
  arch_generic = required_env("NN_NTLIBC_ARCH_GENERIC");
  real_gcc = join2(gcc_dir, "/gcc.exe");
  crt1 = join2(libc_lib, "/crt1.o");
  stack_probe = join2(libc_lib, "/chkstk-ms.o");
  if (!tmp || !*tmp)
    tmp = ".";

  inc_flags[0] = join2("-I", source_include);
  inc_flags[1] = join2("-I", arch_i386);
  inc_flags[2] = join2("-I", arch_generic);
  inc_flags[3] = join2("-I", include);

  for (i = 1; i < argc; ++i) {
    if (strcmp(argv[i], "-c") == 0) {
      if (mode == MODE_LINK)
        mode = MODE_COMPILE;
    } else if (strcmp(argv[i], "-S") == 0
               || strcmp(argv[i], "-E") == 0
               || strcmp(argv[i], "-M") == 0
               || strcmp(argv[i], "-MM") == 0) {
      mode = MODE_PASSTHROUGH;
    } else if (strcmp(argv[i], "-o") == 0) {
      if (++i >= argc)
        die("missing argument after -o");
      out_file = argv[i];
    } else {
      other[other_count++] = argv[i];
      if (is_c_source(argv[i]))
        sources[source_count++] = argv[i];
    }
  }

  if (mode == MODE_PASSTHROUGH) {
    char **command = xmalloc((size_t)(argc + 5) * sizeof(*command));
    int n = 0;
    command[n++] = real_gcc;
    for (i = 1; i < argc; ++i)
      command[n++] = argv[i];
    for (i = 0; i < 4; ++i)
      command[n++] = inc_flags[i];
    command[n] = 0;
    return run(real_gcc, command);
  }

  if (snprintf(temp_dir, sizeof(temp_dir), "%s/cc-wrapper.%ld",
               tmp, (long)getpid()) >= (int)sizeof(temp_dir))
    die("temporary directory path is too long");
  if (mkdir(temp_dir, 0700) < 0 && errno != EEXIST) {
    fprintf(stderr, "%s: cannot create %s: %s\n",
            program_name, temp_dir, strerror(errno));
    return 1;
  }

  for (i = 0; i < source_count; ++i) {
    char asm_file[1200];
    char *object;
    char **gcc_command;
    char *tcc_command[6];
    int n = 0;
    int j;

    if (snprintf(asm_file, sizeof(asm_file), "%s/source.%d.s",
                 temp_dir, i) >= (int)sizeof(asm_file))
      die("temporary assembly path is too long");
    temporary_files[temporary_count++] = join2(asm_file, "");

    gcc_command = xmalloc((size_t)(other_count + 12) * sizeof(*gcc_command));
    gcc_command[n++] = real_gcc;
    for (j = 0; j < other_count; ++j)
      if (!is_c_source(other[j]))
        gcc_command[n++] = other[j];
    for (j = 0; j < 4; ++j)
      gcc_command[n++] = inc_flags[j];
    gcc_command[n++] = "-S";
    gcc_command[n++] = "-o";
    gcc_command[n++] = asm_file;
    gcc_command[n++] = sources[i];
    gcc_command[n] = 0;

    status = run(real_gcc, gcc_command);
    free(gcc_command);
    if (status)
      goto out;

    object = mode == MODE_COMPILE && out_file && source_count == 1
      ? join2(out_file, "") : object_basename(sources[i]);
    objects[object_count++] = object;
    tcc_command[0] = (char *)tcc;
    tcc_command[1] = "-c";
    tcc_command[2] = "-o";
    tcc_command[3] = object;
    tcc_command[4] = asm_file;
    tcc_command[5] = 0;
    status = run(tcc, tcc_command);
    if (status)
      goto out;
  }

  if (mode == MODE_COMPILE)
    goto out;

  {
    char **command = xmalloc((size_t)(object_count + other_count + 20)
                             * sizeof(*command));
    int n = 0;
    command[n++] = (char *)tcc;
    command[n++] = "-B";
    command[n++] = (char *)libc_lib;
    command[n++] = "-nostdlib";
    command[n++] = crt1;
    command[n++] = "-o";
    command[n++] = (char *)(out_file ? out_file : "a.exe");
    for (i = 0; i < object_count; ++i)
      command[n++] = objects[i];
    for (i = 0; i < other_count; ++i)
      if (!is_c_source(other[i]))
        command[n++] = other[i];
    command[n++] = stack_probe;
    command[n++] = "-L";
    command[n++] = (char *)libc_lib;
    command[n++] = "-lc";
    command[n++] = "-L";
    command[n++] = (char *)gcc_libdir;
    command[n++] = "-lgcc";
    command[n++] = "-L";
    command[n++] = (char *)libc_lib;
    command[n++] = "-lntdll";
    command[n] = 0;
    status = run(tcc, command);
    free(command);
  }

out:
  remove_temporaries(temporary_files, temporary_count, temp_dir);
  for (i = 0; i < object_count; ++i)
    free(objects[i]);
  return status;
}
