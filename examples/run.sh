#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
PYTHONPATH=src python -m gbt_policy_gate info
PYTHONPATH=src python -m gbt_policy_gate check --payload '{}'
PYTHONPATH=src python -m gbt_policy_gate run   --payload '{}'
