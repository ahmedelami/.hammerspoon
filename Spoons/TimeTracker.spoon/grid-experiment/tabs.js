// ============== TAB SYSTEM ==============

let currentTab = 'grid';

function switchTab(tabName) {
    // Hide all pages
    document.querySelectorAll('.page').forEach(page => {
        page.classList.remove('active');
    });
    
    // Show selected page
    const selectedPage = document.getElementById(`page-${tabName}`);
    if (selectedPage) {
        selectedPage.classList.add('active');
    }
    
    // Update tab buttons
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    
    event.target.classList.add('active');
    
    currentTab = tabName;
}

