export SIMPLE_SETTINGS="osmnames.settings_default,osmnames.settings_testing"

python -m pytest ${1:-tests/}
