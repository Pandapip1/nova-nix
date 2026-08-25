# BASH_SOURCE subscripting is newer than the Bash 2.05 at this boundary; the
# generic input activator supplies the path being sourced for this purpose.
autotoolsConfigRoot="${setupHookPath%/nix-support/setup-hook}"
preConfigurePhases="${preConfigurePhases-} updateAutotoolsGnuConfigScriptsPhase"

updateAutotoolsGnuConfigScriptsPhase() {
    test -z "${dontUpdateAutotoolsGnuConfigScripts-}" || return 0
    updateAutotoolsDirectory .
}

updateAutotoolsDirectory() {
    local directory="$1" entry
    for entry in "$directory"/* "$directory"/.[!.]* "$directory"/..?*; do
        test -e "$entry" || continue
        if test -d "$entry"; then
            updateAutotoolsDirectory "$entry"
        else
            case "${entry##*/}" in
                config.guess|config.sub)
                    echo "Updating Autotools / GNU config script: $entry"
                    "@rm@" "$entry"
                    "@cp@" "$autotoolsConfigRoot/${entry##*/}" "$entry"
                    ;;
            esac
        fi
    done
}
