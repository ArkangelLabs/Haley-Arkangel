// fix kanban view to render the right board columns on switch
const original_KanbanView_class = frappe.views.KanbanView;
frappe.views.KanbanView = class KanbanView extends original_KanbanView_class {
	render() {
		const board_name = this.board_name;
		if (!this.kanban) {
			this.kanban = new frappe.views.KanbanBoard({
				doctype: this.doctype,
				board: this.board,
				board_name: board_name,
				cards: this.data,
				card_meta: this.card_meta,
				wrapper: this.$result,
				cur_list: this,
				user_settings: this.view_user_settings,
			});
		} else if (board_name === this.kanban.board_name) {
			this.$result.empty();
			this.kanban.update(this.data);
		}
	}
}