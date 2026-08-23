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
# The first half is the 3.0.6 sibling's test, unchanged, and it covers what a
# ./configure script actually asks an awk to do: field splitting under a
# non-default FS, an END block with an accumulator, associative arrays and
# `for (k in a)', a regexp match, sub and gsub, printf, and NR and FNR across
# more than one input file.  It is invoked the same way, as
# `gawk -F : -f selftest.awk data1.txt data2.txt'.
#
# The second half is the part that would fail against 3.0.6, and it is here
# so that this package cannot silently install a slower seed awk: gensub,
# asort/asorti, true arrays of arrays, switch, BEGINFILE/ENDFILE, PROCINFO's
# sorted_in, indirect function calls, typeof/isarray, patsplit and the bit
# operators are all gawk 3.1-or-later.  None of them parses in 3.0.6.
#
# Two things are deliberately NOT checked here.  system() is not, even though
# this port has to patch gawk's own C to keep it working -- see
# patches/nt-system-via-libc.patch -- because every route to it runs /bin/sh,
# and a build-time gate should not depend on a shell existing at a POSIX path
# on a Windows target.  It was verified outside the build instead.  And
# `"cmd" | getline' / `print | "cmd"' are not, because they do not work here
# at all; see the head of default.nix.

function check(name, got, want) {
	checks++
	if (got "" != want "") {
		printf "gawk selftest FAILED: %s: got [%s], wanted [%s]\n",
		    name, got, want
		fails++
	}
}

function double(x) { return x * 2 }

BEGINFILE { beginfiles = beginfiles FILENAME " " }
ENDFILE   { endfiles = endfiles FILENAME ":" FNR " " }

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

	# An array of arrays, which 3.0.6 has no syntax for at all.
	byfile[FILENAME][$1] = $2
}

# A regexp match on a field, which is the form configure uses most.
$1 ~ /^[ag]/ { matched = matched $1 " " }

END {
	# ---- the part 3.0.6 also passes ----

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

	check("sprintf %s %d %f", sprintf("%s|%d|%5.2f", "x", 42, 3.14159), "x|42| 3.14")
	check("sprintf %c %x %e", sprintf("%c|%x|%e", 65, 48879, 1234.5678),
	    "A|beef|1.234568e+03")
	check("substr/index/length", substr("abcdef", index("abcdef", "c"), 3) length("abcdef"), "cde6")
	check("split/toupper", split("one two three", parts, " ") toupper(parts[3]), "3THREE")

	check("match/RSTART/RLENGTH", match("foobarbaz", /bar+/) "," RSTART "," RLENGTH, "4,4,3")
	check("failed match", match("foobarbaz", /zzz/) "," RSTART "," RLENGTH, "0,0,-1")

	check("NR and FNR over two files", order, "1/1 2/2 3/3 4/1 5/2 ")
	check("FNR of file 1", files["data1.txt"], 3)
	check("FNR of file 2", files["data2.txt"], 2)

	while ((getline line < "data2.txt") > 0)
		got = got line "|"
	close("data2.txt")
	check("getline < file", got, "delta:40:wwww|epsilon:50:v|")

	# ---- the part that needs 5.x (or at least 3.1) ----

	check("gensub", gensub(/(b)(a)/, "[\\2\\1]", "g", "foo bar baz"),
	    "foo [ab]r [ab]z")
	check("gensub Nth", gensub(/o/, "0", 2, "foo boo"), "fo0 boo")

	split("pear apple fig", arr, " ")
	n = asort(arr)
	check("asort", n "," arr[1] "," arr[2] "," arr[3], "3,apple,fig,pear")

	delete idx
	idx["zulu"] = 1; idx["alpha"] = 2; idx["mike"] = 3
	n = asorti(idx, sorted)
	check("asorti", n "," sorted[1] "," sorted[2] "," sorted[3],
	    "3,alpha,mike,zulu")

	# Arrays of arrays: two levels, walked with a nested for-in and
	# flattened through asorti so that the answer does not depend on
	# iteration order.
	delete flat
	for (f in byfile)
		for (k in byfile[f])
			flat[f "/" k] = byfile[f][k]
	n = asorti(flat, fkeys)
	check("arrays of arrays: count", n, 5)
	check("arrays of arrays: lookup", byfile["data2.txt"]["epsilon"], 50)
	check("arrays of arrays: isarray", isarray(byfile["data1.txt"]) isarray(flat["data1.txt/alpha"]), "10")

	sw = ""
	for (i = 1; i <= 4; i++)
		switch (i) {
		case 1:
			sw = sw "one "
			break
		case 2:
		case 3:
			sw = sw "two-or-three "
			break
		default:
			sw = sw "other "
		}
	check("switch/case/default", sw, "one two-or-three two-or-three other ")

	check("BEGINFILE", beginfiles, "data1.txt data2.txt ")
	check("ENDFILE", endfiles, "data1.txt:3 data2.txt:2 ")

	# PROCINFO["sorted_in"] makes for-in ordered, which is the one way an
	# awk program can depend on iteration order at all.
	PROCINFO["sorted_in"] = "@ind_str_asc"
	ordered = ""
	for (k in kind)
		ordered = ordered k " "
	check("PROCINFO sorted_in", ordered, "alpha beta delta epsilon gamma ")
	PROCINFO["sorted_in"] = ""

	fn = "double"
	check("indirect function call", @fn(21), 42)

	check("typeof", typeof(kind) "," typeof(lines) "," typeof(matched) "," typeof(nothing),
	    "array,number,string,untyped")

	n = patsplit("a1b22c333", pieces, /[0-9]+/, seps)
	# seps[0] is what came before the first piece; seps[i] is what
	# separates piece i from piece i+1.
	check("patsplit", n "," pieces[1] "," pieces[3] "," seps[0] "," seps[1],
	    "3,1,333,a,b")

	check("bit operators", and(12, 10) "," or(12, 10) "," xor(12, 10) "," lshift(1, 4) "," rshift(16, 2),
	    "8,14,6,16,4")
	check("strtonum", strtonum("0x1f") "," strtonum("011"), "31,9")

	check("length of an array", length(kind), 5)
	delete kind["alpha"]
	check("delete one element", length(kind), 4)
	delete kind
	check("delete whole array", length(kind), 0)

	if (fails > 0) {
		printf "gawk selftest: %d of %d checks failed\n", fails, checks
		exit 1
	}
	printf "gawk selftest: %d checks passed\n", checks
}
