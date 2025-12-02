import frappe
import frappe.model.rename_doc
from types import SimpleNamespace

orig_rename = frappe.model.rename_doc.update_document_title

@frappe.whitelist()
def custom_rename(*, doctype: str, docname: str, title: str | None = None, name: str | None = None, merge: bool = False, enqueue: bool = False, **kwargs):
	old_name = docname
	new_name = name

	result = orig_rename(
		doctype=doctype, docname=docname, title=title, name=name, merge=merge, enqueue=enqueue, **kwargs
	)

	if new_name and old_name != new_name:
		# Create a mock object because `update_kanban_columns_after_rename` expects an object with a `doctype` attribute.
		doc_mock = SimpleNamespace(doctype=doctype)
		frappe.get_attr("enhanced_kanban_view.enhanced_kanban_view.utils.update_kanban_columns_after_rename")(doc_mock, old_name, new_name)

	return result

frappe.model.rename_doc.update_document_title = custom_rename
