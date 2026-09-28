/**
 * HostelStay.in - Owner Dashboard Client Interactions
 */

document.addEventListener('DOMContentLoaded', function() {
    // 1. Auto-dismiss alerts after 5 seconds
    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(function(alert) {
        setTimeout(function() {
            alert.style.transition = 'opacity 0.3s ease, transform 0.3s ease';
            alert.style.opacity = '0';
            alert.style.transform = 'translateY(-6px)';
            setTimeout(function() {
                alert.remove();
            }, 300);
        }, 5000);
    });

    // 2. Escape key closes modals and dropdowns
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            document.querySelectorAll('.modal-overlay').forEach(function(modal) {
                modal.style.display = 'none';
            });
            const quickMenu = document.getElementById('quickAddMenu');
            if (quickMenu) quickMenu.style.display = 'none';
            const propMenu = document.getElementById('propertyDropdownMenu');
            if (propMenu) propMenu.style.display = 'none';
        }
    });

    // 3. Confirm dangerous actions
    const confirmButtons = document.querySelectorAll('[data-confirm]');
    confirmButtons.forEach(function(button) {
        button.addEventListener('click', function(e) {
            const message = button.getAttribute('data-confirm') || 'Are you sure you want to proceed?';
            if (!confirm(message)) {
                e.preventDefault();
            }
        });
    });

    // 4. Quick filter on tables if search input exists
    const searchInput = document.getElementById('globalSearchInput');
    if (searchInput) {
        searchInput.addEventListener('input', function(e) {
            const query = e.target.value.toLowerCase().trim();
            const tableRows = document.querySelectorAll('table tbody tr');
            tableRows.forEach(function(row) {
                const text = row.innerText.toLowerCase();
                if (!query || text.indexOf(query) !== -1) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        });
    }
});

/**
 * Global Modal Helpers
 */
function openModal(id) {
    const modal = document.getElementById(id);
    if (modal) modal.style.display = 'flex';
}

function closeModal(id) {
    const modal = document.getElementById(id);
    if (modal) modal.style.display = 'none';
}
