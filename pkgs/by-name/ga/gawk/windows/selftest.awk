# The build-time test for the gawk this package produces, run as the last
# thing before installation.
#
# It is written as an awk program that checks its own answers because kaem
# has no pipelines, no comparisons and no conditionals: there is nothing on
# this side of the bootstrap that could compare a program's output against an
# expected one, so the checking has to happen inside the program being
# checked.  It exits 1 on the first wrong answer, and kaem is --strict, so a
# wrong answer fails the build.
#
# What it covers is what a ./configure script actually asks an awk to do:
# field splitting under a non-default FS, an END block with an accumulator,
# associative arrays and `for (k in a)', a regexp match, sub and gsub,
# printf with %s/%d/%f, and NR and FNR across more than one input file.  It is
# invoked as `gawk -F : -f selftest.awk data1.txt data2.txt'.

function check(name, got, want) {
	checks++
	if (got "" != want "") {
		printf "gawk selftest FAILED: %s: got [%s], wanted [%s]\n",
		    name, got, want
		fails++
	}
}

{
	# Field splitting under -F : -- three colon-separated fields per line.
	lines++
	total += $2			# accumulator, checked in END
	last_field = $NF
	first_of_last = $1
	kind[$1] = $3			# associative array, string subscripts

	# NR counts every record; FNR restarts at each file.  Both are
	# recorded so that the two-file case is checked rather than assumed.
	order = order NR "/" FNR " "
	files[FILENAME] = FNR
}

# A regexp match on a field, which is the form configure uses most.
$1 ~ /^[ag]/ { matched = matched $1 " " }

END {
	check("record count", lines, 5)
	check("accumulated $2", total, 150)
	check("$NF of the last record", last_field, "v")
	check("$1 of the last record", first_of_last, "epsilon")

	# for (k in a): the iteration order is unspecified, so what is checked
	# is the set, not the sequence -- how many keys there are and the
	# total length of what they map to.
	for (k in kind) {
		keys++
		vallen += length(kind[k])
	}
	check("array key count", keys, 5)
	check("array value length", vallen, 11)
	check("array lookup", kind["gamma"], "zzz")

	check("regexp match with ~", matched, "alpha gamma ")

	s = "a-b-c-d"
	n = gsub(/-/, "+", s)
	check("gsub return", n, 3)
	check("gsub result", s, "a+b+c+d")

	t = "hello world"
	n = sub(/world/, "there", t)
	check("sub return", n, 1)
	check("sub result", t, "hello there")

	check("sprintf", sprintf("%s|%d|%5.2f", "x", 42, 3.14159), "x|42| 3.14")
	check("substr/index/length", substr("abcdef", index("abcdef", "c"), 3) length("abcdef"), "cde6")

	check("NR and FNR over two files", order, "1/1 2/2 3/3 4/1 5/2 ")
	check("FNR of file 1", files["data1.txt"], 3)
	check("FNR of file 2", files["data2.txt"], 2)

	if (fails > 0) {
		printf "gawk selftest: %d of %d checks failed\n", fails, checks
		exit 1
	}
	printf "gawk selftest: %d checks passed\n", checks
}
