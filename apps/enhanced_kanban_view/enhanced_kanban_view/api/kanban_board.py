import frappe

@frappe.whitelist()
def quick_kanban_board(doctype, board_name, field_name, project=None):
	"""Create new KanbanBoard quickly with default options"""

	doc = frappe.new_doc("Kanban Board")
	meta = frappe.get_meta(doctype)

	doc.kanban_board_name = board_name
	doc.reference_doctype = doctype
	doc.field_name = field_name

	if project:
		doc.filters = f'[["Task","project","=","{project}"]]'

	options = ""
	select_field = False
	link_field = False
	for field in meta.fields:
		same_field = field.fieldname == field_name
		select_field = field.fieldtype == "Select"
		link_field = field.fieldtype == "Link"
		if same_field and select_field:
			options = field.options
			break
		elif same_field and link_field:
			options = frappe.db.get_list(field.options, fields=["name"], limit_page_length=15)
			break

	columns = []
	if options and select_field:
		columns = options.split("\n")
	elif options and link_field:
		columns = [f"{item.name}" for item in options]

	print("columns")
	print(columns)
	for column in columns:
		if not column:
			continue
		doc.append("columns", dict(column_name=column))

	if doctype in ["Note", "ToDo"]:
		doc.private = 1

	doc.save()
	return doc
