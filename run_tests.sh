export SIMPLE_SETTINGS="osmnames.settings_default,osmnames.settings_testing"

python3 -m pytest ${1:-tests/}
