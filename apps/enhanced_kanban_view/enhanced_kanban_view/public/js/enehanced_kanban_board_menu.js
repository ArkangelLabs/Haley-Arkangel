const original_KanbanView_class = frappe.views.KanbanView;
frappe.views.KanbanView = class KanbanView extends original_KanbanView_class {
	push_menu_items() {
		if (this.board_perms.write) {
			this.menu_items.push({
				label: __("Save filters"),
				action: () => {
					this.save_kanban_board_filters();
				},
			});
		}

		if (this.board_perms.delete) {
			this.menu_items.push({
				label: __("Delete Kanban Board"),
				action: () => {
					frappe.confirm(__("Are you sure you want to proceed?"), () => {
						frappe.db.delete_doc("Kanban Board", this.board_name).then(() => {
							frappe.show_alert(`Kanban Board ${this.board_name} deleted.`);
							frappe.set_route("List", this.doctype, "List");
						});
					});
				},
			});
		}
        if (this.board_perms.create) {
            this.menu_items.push({
                label: __("Create Kanban Board Rule"),
                action: () => {
                    frappe.new_doc("Kanban Board Rule", {
                        kanban_board: this.board_name,
                        rule_type: "Filter",
                        filter_conditions: this.filters,
                    });
                },
            });
        }
	}
}