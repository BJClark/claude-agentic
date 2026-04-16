#!/bin/bash
# jdx-stack-advisor.sh — PreToolUse:Bash hook that nudges Claude to use the
# jdx stack (mise/pitchfork/fnox) when the pending bash command matches a
# legacy pattern the jdx-stack skill can rewrite.
#
# Reads JSON from stdin (Claude Code hook protocol), extracts .tool_input.command,
# and exits 2 (blocking, stderr shown to Claude) if it matches a known legacy
# pattern. Otherwise exits 0 (no-op, command proceeds).

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$CMD" ]; then
  exit 0
fi

# Regex alternation of patterns that have jdx-stack equivalents.
# ERE syntax (grep -E). Keep patterns specific enough to avoid false positives
# on read-only ops like `git log`, `ls`, `grep`, etc.
PATTERNS='(\bkill[[:space:]]+-?[0-9])'
PATTERNS+='|(\bkill[[:space:]]+\$)'
PATTERNS+='|(\bpkill\b)|(\bpgrep\b)'
PATTERNS+='|(\blsof[[:space:]]+-i)'
PATTERNS+='|(\bps[[:space:]]+aux\b)'
PATTERNS+='|(\bnohup\b)'
PATTERNS+='|([[:space:]]&[[:space:]]*($|;))'
PATTERNS+='|(\bpm2[[:space:]]+(start|stop|restart|logs)\b)'
PATTERNS+='|(docker[[:space:]]+compose[[:space:]]+(up|down|ps|logs)\b)'
PATTERNS+='|(>[[:space:]]*/tmp/[^[:space:]]*\.log\b)'
PATTERNS+='|(\btail[[:space:]]+-[fF]\b)'
PATTERNS+='|(\bmake[[:space:]]+[A-Za-z])'
PATTERNS+='|(\bnpm[[:space:]]+run\b)'
PATTERNS+='|(\byarn[[:space:]]+[A-Za-z])'
PATTERNS+='|(\bpnpm[[:space:]]+run\b)'
PATTERNS+='|(\bnvm[[:space:]]+(install|use)\b)'
PATTERNS+='|(\bpyenv\b)|(\brbenv\b)'
PATTERNS+='|(\basdf[[:space:]]+(install|local|global)\b)'
PATTERNS+='|(\bdirenv[[:space:]]+allow\b)'
PATTERNS+='|(\bsource[[:space:]]+\.env(rc)?\b)'
PATTERNS+='|(npm[[:space:]]+(install|i)[[:space:]]+-g\b)'
PATTERNS+='|(\byarn[[:space:]]+global\b)'

if echo "$CMD" | grep -Eq "$PATTERNS"; then
  cat >&2 <<'EOF'
jdx-stack skill applies to this command. Before running it, invoke the Skill tool with skill="jdx-stack" and rewrite using mise/pitchfork/fnox (or, if the legacy form is genuinely required for this one-off, re-issue the same command and it will run).
EOF
  exit 2
fi

exit 0
