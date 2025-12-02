import frappe

@frappe.whitelist()
def get_additional_fields(kanban_board_name, column_name):
    """
    Fetches field_name values using a raw SQL query.
    """
    # The SQL query with placeholders for security
    sql_query = """
        SELECT
            child.field_name
        FROM
            `tabKanban Board Rule` as parent
        JOIN
            `tabKanban Rule Field` as child ON child.parent = parent.name
        WHERE
            parent.kanban_board = %(kanban_board)s
            AND parent.kanban_board_column LIKE %(column_name)s
        """

    # Execute the query with LIKE pattern for partial matching
    # as_dict=True returns a list of dictionaries, e.g., [{'field_name': 'status'}]
    results = frappe.db.sql(sql_query, values={
        "kanban_board": kanban_board_name,
        "column_name": f"%{column_name}%"
    }, as_dict=True)

    # Convert the list of dictionaries to a simple list of strings
    field_names = []
    if results:
        for result in results:
            if isinstance(result, dict) and 'field_name' in result:
              #result['field_name'] wil be like this "City (city)" so we need to get the fieldname  
              # by getting what is between the last "(" ")"
              import re
              match = re.search(r'\(([^)]+)\)$', result['field_name'])
              field_name = match.group(1).strip() if match else result['field_name'].strip()
              field_names.append(field_name)
    return field_names