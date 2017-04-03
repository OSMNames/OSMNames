import os
import simple_settings

os.environ.setdefault('SIMPLE_SETTINGS', 'osmnames.settings_default')


def get(key):
    return getattr(simple_settings.settings, key)
