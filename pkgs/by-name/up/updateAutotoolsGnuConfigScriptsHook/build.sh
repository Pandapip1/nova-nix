set -eu

"$mkdir" "$out"
"$mkdir" "$out/nix-support"
"$cp" "$configGuess" "$out/config.guess"
"$cp" "$configSub" "$out/config.sub"
"$replace" --file "$setupHook" --output setup-hook-cp --match-on @cp@ --replace-with "$cp"
"$replace" --file setup-hook-cp --output "$out/nix-support/setup-hook" --match-on @rm@ --replace-with "$rm"
