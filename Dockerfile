# Haley - ERPNext v16 + Enhanced Kanban View
# Zero-downtime deployment image

FROM frappe/erpnext:v16

# Copy enhanced_kanban_view app
COPY apps/enhanced_kanban_view /home/frappe/frappe-bench/apps/enhanced_kanban_view

# Install the app properly using bench's virtual environment
RUN cd /home/frappe/frappe-bench && \
    echo "" >> sites/apps.txt && \
    echo "enhanced_kanban_view" >> sites/apps.txt && \
    /home/frappe/frappe-bench/env/bin/pip install -e apps/enhanced_kanban_view

# Build assets for the app
RUN cd /home/frappe/frappe-bench && \
    bench build --app enhanced_kanban_view
