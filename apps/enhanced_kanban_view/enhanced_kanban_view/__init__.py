from __future__ import unicode_literals
import os
import importlib

import frappe

__version__ = "0.0.1"

app_name = "enhanced_kanban_view"
patches_loaded = False

def load_monkey_patches():
    """
    Loads all modules present in monkey_patches to override some logic
    in Frappe / ERPNext. Returns if patches have already been loaded earlier.
    """
    global patches_loaded

    if patches_loaded:
        return

    patches_loaded = True

    try:
        if app_name not in frappe.get_installed_apps():
            return
    except RuntimeError:
        # During bench commands, we can't check installed_apps, so we'll just assume it is installed
        pass

    for module_name in os.listdir(frappe.get_app_path(app_name, "monkey_patches")):
        if not module_name.endswith(".py") or module_name == "__init__.py":
            continue

        importlib.import_module(app_name + ".monkey_patches." + module_name[:-3])


old_get_hooks = frappe.get_hooks


def get_hooks(*args, **kwargs):
    load_monkey_patches()
    return old_get_hooks(*args, **kwargs)


frappe.get_hooks = get_hooks
