// ============== TASK PANEL ==============

let tasks = [];

function togglePanel() {
    const panel = document.getElementById('taskPanel');
    const container = document.querySelector('.container');
    const toggleBtn = document.querySelector('.toggle-panel-btn');
    
    panel.classList.toggle('hidden');
    container.classList.toggle('panel-open');
    toggleBtn.classList.toggle('panel-open');
}

function loadTasks() {
    const saved = localStorage.getItem('tasks');
    if (saved) {
        tasks = JSON.parse(saved);
        renderTasks();
    }
}

function saveTasks() {
    localStorage.setItem('tasks', JSON.stringify(tasks));
}

function addTask() {
    const input = document.getElementById('taskInput');
    const taskName = input.value.trim();
    
    if (!taskName) return;
    
    const newTask = {
        id: Date.now(),
        name: taskName,
        created: new Date().toISOString()
    };
    
    tasks.push(newTask);
    input.value = '';
    saveTasks();
    renderTasks();
}

function deleteTask(id) {
    tasks = tasks.filter(t => t.id !== id);
    saveTasks();
    renderTasks();
}

function renderTasks() {
    const container = document.getElementById('taskList');
    
    if (tasks.length === 0) {
        container.innerHTML = `
            <div class="empty-task-state">
                <div style="font-size: 48px; opacity: 0.5; margin-bottom: 12px;">📝</div>
                <div>No tasks yet. Add one above!</div>
            </div>
        `;
        return;
    }
    
    container.innerHTML = tasks.map(task => {
        const date = new Date(task.created);
        const now = new Date();
        const diffMs = now - date;
        const diffMins = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMs / 3600000);
        const diffDays = Math.floor(diffMs / 86400000);
        
        let timeAgo;
        if (diffMins < 1) timeAgo = 'just now';
        else if (diffMins < 60) timeAgo = `${diffMins}m ago`;
        else if (diffHours < 24) timeAgo = `${diffHours}h ago`;
        else if (diffDays < 7) timeAgo = `${diffDays}d ago`;
        else timeAgo = date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
        
        return `
            <div class="task-item" draggable="true" data-task-id="${task.id}" data-task-name="${escapeHtml(task.name)}">
                <div class="task-name">${escapeHtml(task.name)}</div>
                <div class="task-meta">
                    <span>${timeAgo}</span>
                    <button class="task-delete" onclick="deleteTask(${task.id})" title="Delete">×</button>
                </div>
            </div>
        `;
    }).join('');
    
    // Add drag listeners to task items
    document.querySelectorAll('.task-item').forEach(item => {
        item.addEventListener('dragstart', (e) => {
            const taskId = parseInt(item.dataset.taskId);
            const taskName = item.dataset.taskName;
            draggedTask = { taskId, taskName };
            item.classList.add('dragging');
            e.dataTransfer.effectAllowed = 'copy';
        });
        
        item.addEventListener('dragend', () => {
            item.classList.remove('dragging');
            draggedTask = null;
        });
    });
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Initialize tasks
loadTasks();

