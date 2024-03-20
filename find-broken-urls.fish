#!/usr/bin/env fish

# given a certian prefix to check, check that packages with that prefix don't have any proken urls

# this piecewise method is needed because otherwise nix uses too much memory

# use sudo because we need to be a privalaged user
# -j 1 to make our log output linear
sudo nix-build --keep-going -j 1 --show-trace --no-sandbox -E '(import ./. {}).lib.testers.checkMetaUrlsPkgPrefix "'$argv[1]'"' 2>/tmp/url-log-err >/tmp/url-log-out

# for every derivation that failed to build, we find the previous
# log entry that says a url is being fetched
tac /tmp/url-log-err | awk '
BEGIN { FS = "\t" }
/error: builder for/ { r = 1 };
/^checking if url exists:/ {
  if(r == 1) { print }; r = 0
}
' | sed 's/^checking if url exists: //'
