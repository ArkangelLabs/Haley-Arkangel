# Haley - ERPNext v16 + Enhanced Kanban View
# Zero-downtime deployment image

FROM frappe/erpnext:v16

# Copy enhanced_kanban_view app
COPY apps/enhanced_kanban_view /home/frappe/frappe-bench/apps/enhanced_kanban_view

# Install the app (register in apps.txt with proper newline)
RUN echo "" >> /home/frappe/frappe-bench/sites/apps.txt && \
    echo "enhanced_kanban_view" >> /home/frappe/frappe-bench/sites/apps.txt

# Install Python dependencies for the app
RUN cd /home/frappe/frappe-bench/apps/enhanced_kanban_view && \
    pip install -e .

# Build assets for the app
RUN cd /home/frappe/frappe-bench && \
    bench build --app enhanced_kanban_view
