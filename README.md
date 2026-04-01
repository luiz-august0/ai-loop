# ai-loop

A shell script that runs an AI agent in a loop, feeding its own output back as context until a completion condition is met or a maximum number of iterations is reached.

## How it works

1. Sends the prompt to the chosen CLI agent
2. Captures the output
3. Checks if the `completion-promise` string is present in the output
4. If not, appends the output as context and runs again with "Refine, improve, and continue."
5. Stops when the condition is met, the loop gets stuck (output == previous output), or the iteration limit is reached

## Usage

```bash
chmod +x ai-loop.sh

./ai-loop.sh "<prompt>" "<completion-promise>" <max-iterations> <mode> <save-history>
```

| Argument             | Description                                              | Default   |
|----------------------|----------------------------------------------------------|-----------|
| `prompt`             | The initial task description                             | required  |
| `completion-promise` | String to look for in output to consider the task done   | `""`      |
| `max-iterations`     | Maximum number of loop iterations                        | `10`      |
| `mode`               | Agent to use: `claude`, `devin`, or `multi`              | `claude`  |
| `save-history`       | Save each iteration to a log file (`true`/`false`)       | `true`    |

## Examples

**Single agent (Claude):**
```bash
./ai-loop.sh \
  "Build a hello world API" \
  "DONE" \
  10 \
  claude
```

**Single agent (Devin):**
```bash
./ai-loop.sh \
  "Create a Python CLI tool" \
  "DONE" \
  8 \
  devin
```

**Multi-agent mode (Claude ↔ Devin alternating):**
```bash
./ai-loop.sh \
  "Refactor this codebase for readability" \
  "DONE" \
  6 \
  multi
```

## Modes

- **`claude`** — runs every iteration with `claude code --print --dangerously-skip-permissions`
- **`devin`** — runs every iteration with `devin --permission-mode dangerous -p`
- **`multi`** — alternates between Devin (odd iterations) and Claude (even iterations)

## History & Logs

When `save-history` is `true` (default), each iteration is appended to a timestamped log file:

```
ai-loop-20240401-153000.log
```

Each entry includes the iteration number, the agent used, and the full output.

## Exit codes

| Code | Meaning                                      |
|------|----------------------------------------------|
| `0`  | Completion promise was found in output       |
| `1`  | Loop ended without reaching the condition    |

## Requirements

- [`claude`](https://github.com/anthropics/claude-code) CLI installed and authenticated
- [`devin`](https://devin.ai) CLI installed and authenticated (only needed for `devin` or `multi` mode)
