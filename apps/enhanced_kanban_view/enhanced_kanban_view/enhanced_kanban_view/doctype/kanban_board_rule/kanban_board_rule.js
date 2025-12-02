frappe.ui.form.on("Kanban Board Rule", {
	refresh: function (frm) {
		if (frm.doc.kanban_board) {
			frm.trigger("kanban_board");
		}
	},

	kanban_board: function (frm) {

		// If no board is selected, stop.
		if (!frm.doc.kanban_board) {
			return;
		}

		// Make a single call to get all the data we need.
		frm.call({
			doc: frm.doc,
			method: "get_kanban_board_data",
			args: {
				board_name: frm.doc.kanban_board,
			},
			callback: function (r) {
				if (r.message) {
					// Populate the 'kanban_board_column' Select field
					frm.set_query("kanban_board_column", function () {
						return {
							filters: [["column_name", "in", r.message.columns || []]],
						};
					});
					frm.refresh_field("kanban_board_column");

					// After receiving r.message.fields from the server, update the Select options for the child table
					if (r.message) {
					    // Store the mapping globally on the frm for later use
					    frm._kanban_field_label_to_value = {};
					    (r.message.fields || []).forEach(f => {
					        frm._kanban_field_label_to_value[f.label] = f.value;
					    });

					    // Debug: log all labels being set as options
					    const allLabels = (r.message.fields || []).map(f => f.label);

					    // Set options for the 'fieldname' Select field in the 'required_fields' child table
					    let child_grid = frm.get_field("required_fields").grid;
					    child_grid.update_docfield_property(
					        "field_name", // The fieldname in your child table
					        "options", // The property to change
					        allLabels // List of 'Label (fieldname)' strings
					    );
					    frm.refresh_field("required_fields");
					}
				}
			},
		});
	},
});

// Helper function to extract fieldname from 'Label (fieldname)' string
function extract_fieldname(label) {
    const match = label.match(/\(([^)]+)\)$/);
    return match ? match[1] : label;
}

// When validating or saving, use the mapping to get the actual fieldname
frappe.ui.form.on('Kanban Rule Field', {
    fieldname: function(frm, cdt, cdn) {
        let row = locals[cdt][cdn];
        if (frm._kanban_field_label_to_value) {
            row._actual_fieldname = frm._kanban_field_label_to_value[row.fieldname];
        } else {
            row._actual_fieldname = row.fieldname;
        }
        // You can now use row._actual_fieldname for your logic
    }
});
