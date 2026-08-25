# Run by build.kaem before bash is installed.
#
# --version proves the binary loads and runs; this proves it is a shell.
# Between them these are the things every ./configure script above this
# package needs and kaem cannot do: a variable, a loop, a conditional, a
# pipeline and a command substitution.  If one of them is silently broken --
# and on a young C library they can be, without the link ever complaining --
# it is better to find out here than three packages later.
#
# Nothing outside bash is run: there is no coreutils yet, so every command
# below is a shell builtin and the only thing being tested is bash.

n=
for word in one two three; do
	n=${n}x
done

if test "${n}" = xxx; then
	echo "loop, variable and conditional: ok"
else
	echo "loop, variable and conditional: BROKEN (${n})" >&2
	exit 1
fi

# A pipeline into a command substitution.  Both sides are builtins, but bash
# still needs a pipe and a second process for each -- the part most likely to
# be missing on a platform whose process layer is new.
last=$(echo "a b c" | { read x y z; echo "${z}"; })

if test "${last}" = c; then
	echo "pipeline and command substitution: ok"
else
	echo "pipeline and command substitution: BROKEN (${last})" >&2
	exit 1
fi

echo "self-test passed"
