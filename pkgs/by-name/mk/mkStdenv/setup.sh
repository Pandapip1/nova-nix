set -eu

# Bootstrap-sized nixpkgs generic setup. Inputs are discovered before they are
# activated: propagated dependency files are followed recursively, then each
# input's nix-support/setup-hook is sourced.

runHook() {
    local hookName="$1" hookValue hooksName hookValues hook
    shift

    if test "$(type -t "$hookName" 2>/dev/null || :)" = function; then
        "$hookName" "$@"
    else
        eval "hookValue=\${$hookName-}"
        if test -n "$hookValue"; then
            eval "$hookValue"
        fi
    fi

    hooksName="${hookName%Hook}Hooks"
    eval "hookValues=\${$hooksName-}"
    for hook in $hookValues; do
        if test "$(type -t "$hook" 2>/dev/null || :)" = function; then
            "$hook" "$@"
        else
            eval "$hook"
        fi
    done
}

addHook() {
    local hookName="${1%Hook}Hooks" hook="$2"
    eval "$hookName=\"\${$hookName-} $hook\""
}

addToSearchPath() {
    local varName="$1" path="$2" oldPath
    test -d "$path" || return 0
    eval "oldPath=\${$varName-}"
    if test -n "$oldPath"; then
        eval "$varName=\"$oldPath:$path\""
    else
        eval "$varName=\"$path\""
    fi
    export "$varName"
}

# Store paths cannot contain whitespace. These six accumulators correspond to
# nixpkgs' build/build, build/host, build/target, host/host, host/target and
# target/target dependency roles, but also work with the bootstrap's Bash 2.05.
pkgsBuildBuild=""
pkgsBuildHost=""
pkgsBuildTarget=""
pkgsHostHost=""
pkgsHostTarget=""
pkgsTargetTarget=""

setAccumVar() {
    case "$1:$2" in
        -1:-1) accumVar=pkgsBuildBuild ;;
        -1:0) accumVar=pkgsBuildHost ;;
        -1:1) accumVar=pkgsBuildTarget ;;
        0:0) accumVar=pkgsHostHost ;;
        0:1) accumVar=pkgsHostTarget ;;
        1:1) accumVar=pkgsTargetTarget ;;
        *) echo "invalid dependency role $1:$2" >&2; exit 1 ;;
    esac
}

inputSeen() {
    local roleInputs
    setAccumVar "$2" "$3"
    eval "roleInputs=\${$accumVar-}"
    case " $roleInputs " in
        *" $1 "*) return 0 ;;
        *) return 1 ;;
    esac
}

findInputs() {
    local pkg="$1" hostOffset="$2" targetOffset="$3"
    local depSpec relHost depRest relTarget depFile nextHost nextTarget propagatedLine propagatedInput
    inputSeen "$pkg" "$hostOffset" "$targetOffset" && return 0
    test -e "$pkg" || {
        echo "build input $pkg does not exist" >&2
        exit 1
    }
    setAccumVar "$hostOffset" "$targetOffset"
    eval "$accumVar=\"\${$accumVar-} $pkg\""

    for depSpec in \
        '-1:-1:propagated-build-build-deps' \
        '-1:0:propagated-native-build-inputs' \
        '-1:1:propagated-build-target-deps' \
        '0:0:propagated-host-host-deps' \
        '0:1:propagated-build-inputs' \
        '1:1:propagated-target-target-deps'
    do
        relHost=${depSpec%%:*}
        depRest=${depSpec#*:}
        relTarget=${depRest%%:*}
        depFile=${depRest#*:}

        if test "$relHost" -le 0; then nextHost=$((relHost + hostOffset)); else nextHost=$((relHost - 1 + targetOffset)); fi
        if test "$relTarget" -le 0; then nextTarget=$((relTarget + hostOffset)); else nextTarget=$((relTarget - 1 + targetOffset)); fi
        test "$nextHost" -ge -1 && test "$nextHost" -le 1 || continue
        test "$nextTarget" -ge -1 && test "$nextTarget" -le 1 || continue
        test "$nextHost" -le "$nextTarget" || continue

        if test -f "$pkg/nix-support/$depFile"; then
            while read propagatedLine; do
                for propagatedInput in $propagatedLine; do
                    findInputs "$propagatedInput" "$nextHost" "$nextTarget"
                done
            done < "$pkg/nix-support/$depFile"
        fi
    done
}

: "${depsBuildBuild=}" "${depsBuildBuildPropagated=}" \
  "${nativeBuildInputs=}" "${propagatedNativeBuildInputs=}" \
  "${depsBuildTarget=}" "${depsBuildTargetPropagated=}" \
  "${depsHostHost=}" "${depsHostHostPropagated=}" \
  "${buildInputs=}" "${propagatedBuildInputs=}" \
  "${depsTargetTarget=}" "${depsTargetTargetPropagated=}" \
  "${defaultNativeBuildInputs=}" "${defaultBuildInputs=}"

for pkg in $depsBuildBuild $depsBuildBuildPropagated; do findInputs "$pkg" -1 -1; done
for pkg in $nativeBuildInputs $propagatedNativeBuildInputs; do findInputs "$pkg" -1 0; done
for pkg in $depsBuildTarget $depsBuildTargetPropagated; do findInputs "$pkg" -1 1; done
for pkg in $depsHostHost $depsHostHostPropagated; do findInputs "$pkg" 0 0; done
for pkg in $buildInputs $propagatedBuildInputs; do findInputs "$pkg" 0 1; done
for pkg in $depsTargetTarget $depsTargetTargetPropagated; do findInputs "$pkg" 1 1; done
# Default inputs are intentionally discovered last, exactly as in nixpkgs.
for pkg in $defaultNativeBuildInputs; do findInputs "$pkg" -1 0; done
for pkg in $defaultBuildInputs; do findInputs "$pkg" 0 1; done

activatePackage() {
    local pkg="$1" hostOffset="$2"
    # Match nixpkgs' native-input PATH rule. In non-strict builds every input
    # remains visible for compatibility; strict cross builds expose only tools
    # whose host is the build platform.
    if test -z "${strictDeps-}" || test "$hostOffset" -le -1; then
        addToSearchPath PATH "$pkg/bin"
    fi
    if test -f "$pkg/nix-support/setup-hook"; then
        setupHookPath="$pkg/nix-support/setup-hook"
        . "$setupHookPath"
    fi
}

for pkg in $pkgsBuildBuild $pkgsBuildHost $pkgsBuildTarget; do activatePackage "$pkg" -1; done
for pkg in $pkgsHostHost $pkgsHostTarget; do activatePackage "$pkg" 0; done
for pkg in $pkgsTargetTarget; do activatePackage "$pkg" 1; done

unpackPhase() {
    runHook preUnpack
    if test -d "$src"; then
        cp -R "$src" source
        chmod -R u+w source
        sourceRoot=source
    else
        case "$src" in
            *.tar) tar xf "$src" ;;
            # The stage2 tar is GNU tar 1.12.  It predates compression
            # autodetection, so feed compressed archives to it explicitly.
            *.tar.gz|*.tgz) gzip -dc "$src" | tar xf - ;;
            *.tar.xz|*.txz) unxz -c "$src" | tar xf - ;;
            *) echo "mkStdenv: do not know how to unpack $src" >&2; exit 1 ;;
        esac
        if test -z "${sourceRoot-}"; then
            set -- *
            if test "$#" -ne 1 || ! test -d "$1"; then
                echo "mkStdenv: unpacking $src did not produce one directory" >&2
                exit 1
            fi
            sourceRoot="$1"
        fi
    fi
    cd "$sourceRoot"
    runHook postUnpack
}

patchPhase() {
    runHook prePatch
    for patch in ${patches-}; do
        patch ${patchFlags--p1} < "$patch"
    done
    runHook postPatch
}

configurePhase() {
    runHook preConfigure
    if test -f ./configure; then
        "$SHELL" ./configure --prefix="$out" ${configureFlags-}
    fi
    runHook postConfigure
}

buildPhase() {
    runHook preBuild
    if test -n "${buildScript-}"; then
        "$SHELL" -e "$buildScript"
    else
        make ${makeFlags-}
    fi
    runHook postBuild
}

checkPhase() {
    runHook preCheck
    make ${checkTarget-check} ${checkFlags-}
    runHook postCheck
}

installPhase() {
    runHook preInstall
    make install ${installFlags-}
    runHook postInstall
}

fixupPhase() {
    runHook preFixup
    runHook fixupOutput
    recordPropagatedDependencies
    if test -n "${setupHook-}"; then
        mkdir -p "$out/nix-support"
        cp "$setupHook" "$out/nix-support/setup-hook"
    fi
    runHook postFixup
}

installCheckPhase() {
    runHook preInstallCheck
    make ${installCheckTarget-installcheck} ${installCheckFlags-}
    runHook postInstallCheck
}

distPhase() {
    runHook preDist
    make ${distTarget-dist} ${distFlags-}
    runHook postDist
}

recordPropagatedDependency() {
    local varName="$1" fileName="$2" values
    eval "values=\${$varName-}"
    test -n "$values" || return 0
    mkdir -p "$out/nix-support"
    printf '%s\n' $values > "$out/nix-support/$fileName"
}

recordPropagatedDependencies() {
    recordPropagatedDependency depsBuildBuildPropagated propagated-build-build-deps
    recordPropagatedDependency propagatedNativeBuildInputs propagated-native-build-inputs
    recordPropagatedDependency depsBuildTargetPropagated propagated-build-target-deps
    recordPropagatedDependency depsHostHostPropagated propagated-host-host-deps
    recordPropagatedDependency propagatedBuildInputs propagated-build-inputs
    recordPropagatedDependency depsTargetTargetPropagated propagated-target-target-deps
}

runPhase() {
    local curPhase="$1" phaseBody
    echo "Running phase: $curPhase"
    case "$curPhase" in
        unpackPhase) test -z "${dontUnpack-}" || return 0 ;;
        patchPhase) test -z "${dontPatch-}" || return 0 ;;
        configurePhase) test -z "${dontConfigure-}" || return 0 ;;
        buildPhase) test -z "${dontBuild-}" || return 0 ;;
        checkPhase) test -n "${doCheck-}" || return 0 ;;
        installPhase) test -z "${dontInstall-}" || return 0 ;;
        fixupPhase) test -z "${dontFixup-}" || return 0 ;;
        installCheckPhase) test -n "${doInstallCheck-}" || return 0 ;;
        distPhase) test -n "${doDist-}" || return 0 ;;
    esac
    eval "phaseBody=\${$curPhase-}"
    if test -n "$phaseBody"; then eval "$phaseBody"; else "$curPhase"; fi
}

genericBuild() {
    if test -n "${buildCommand-}"; then
        eval "$buildCommand"
        return
    fi
    if test -z "${phases-}"; then
        phases="${prePhases-} unpackPhase patchPhase ${preConfigurePhases-} configurePhase ${preBuildPhases-} buildPhase checkPhase ${preInstallPhases-} installPhase ${preFixupPhases-} fixupPhase installCheckPhase ${preDistPhases-} distPhase ${postPhases-}"
    fi
    for curPhase in $phases; do runPhase "$curPhase"; done
}

runHook preHook
genericBuild
runHook postHook
