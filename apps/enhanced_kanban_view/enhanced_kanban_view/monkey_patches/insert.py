import frappe
from json import loads, JSONDecodeError
from frappe import _
import frappe.model.document

orig_insert = frappe.model.document.Document.insert

def custom_insert(self, *args, **kwargs):
    result = orig_insert(self, *args, **kwargs)
    frappe.get_attr("enhanced_kanban_view.enhanced_kanban_view.utils.update_kanban_columns_after_insert")(self)
    return result

frappe.model.document.Document.insert = custom_insert
