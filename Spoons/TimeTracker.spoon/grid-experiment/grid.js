// ============== DATA STRUCTURES ==============

// Cell data: { "2025-10-23T09": { taskId: 123, taskName: "Do homework", note: "" } }
let cellData = {};
let currentCell = null;
let isDragging = false;
let draggedTask = null;
let dragFromCell = null;
let cellFillMode = false;
let fillStartCell = null;
let filledCells = new Set();
let fillTaskData = null;

// ============== TIME LABELS ==============

function generateTimeLabels(containerId) {
    const container = document.getElementById(containerId);
    container.innerHTML = '<div class="time-label" style="height: 60px;"></div>'; // Header spacer
    
    for (let hour = 6; hour < 24; hour++) {
        const label = document.createElement('div');
        label.className = 'time-label';
        const ampm = hour < 12 ? 'am' : 'pm';
        const displayHour = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
        label.textContent = `${displayHour}${ampm}`;
        container.appendChild(label);
    }
    
    // Add midnight+ cells for staying up late
    for (let hour = 0; hour < 6; hour++) {
        const label = document.createElement('div');
        label.className = 'time-label';
        label.style.color = '#ef4444';
        const displayHour = hour === 0 ? 12 : hour;
        label.textContent = `${displayHour}am+`;
        container.appendChild(label);
    }
}

// ============== GRID GENERATION ==============

function generateGrid(containerId, startOffset, numDays) {
    const container = document.getElementById(containerId);
    const today = new Date();
    
    for (let i = 0; i < numDays; i++) {
        const dayOffset = startOffset + i;
        const date = new Date(today);
        date.setDate(today.getDate() + dayOffset);
        
        const column = document.createElement('div');
        column.className = 'day-column';
        
        // Add visual separation after first week
        if (i === 7) {
            column.style.borderLeft = '3px solid #404040';
        }
        
        // Header
        const header = document.createElement('div');
        header.className = 'day-header';
        const weekNum = Math.floor(dayOffset / 7) + 1;
        const dayInWeek = (dayOffset % 7) + 1;
        header.innerHTML = `
            <div class="day-name">${date.toLocaleDateString('en-US', { weekday: 'short' })}</div>
            <div class="day-number">W${weekNum} D${dayInWeek}</div>
        `;
        column.appendChild(header);
        
        // Cells (6am to 11pm + midnight overflow)
        for (let hour = 6; hour < 24; hour++) {
            const cell = createCell(date, hour);
            column.appendChild(cell);
        }
        
        // Overtime cells (midnight to 6am)
        for (let hour = 0; hour < 6; hour++) {
            const cell = createCell(date, hour, true);
            column.appendChild(cell);
        }
        
        container.appendChild(column);
    }
}

// ============== CELL CREATION ==============

function createCell(date, hour, isOvertime = false) {
    const cell = document.createElement('div');
    cell.className = 'cell';
    if (isOvertime) cell.style.opacity = '0.6';
    
    const dateStr = date.toISOString().split('T')[0];
    const cellKey = `${dateStr}T${String(hour).padStart(2, '0')}`;
    
    cell.dataset.key = cellKey;
    cell.dataset.date = dateStr;
    cell.dataset.hour = hour;
    
    // Load saved data
    const data = cellData[cellKey];
    if (data && data.taskName) {
        cell.classList.add('filled-task');
        cell.textContent = data.taskName;
        cell.draggable = true;
        
        // Drag from filled cell to copy to other cells
        cell.addEventListener('dragstart', (e) => {
            dragFromCell = cellKey;
            draggedTask = data;
            e.dataTransfer.effectAllowed = 'copy';
            cell.style.opacity = '0.5';
        });
        
        cell.addEventListener('dragend', () => {
            cell.style.opacity = '1';
            dragFromCell = null;
        });
        
        // Hold and drag to fill multiple cells
        cell.addEventListener('mousedown', (e) => {
            // Only for left click, not if clicking delete button or in modal
            if (e.button !== 0 || e.target.closest('.modal')) return;
            
            cellFillMode = true;
            fillStartCell = cellKey;
            fillTaskData = data;
            filledCells = new Set([cellKey]);
            e.preventDefault();
        });
        
        // Handle dragging over already-filled cells to clear them
        cell.addEventListener('mouseenter', (e) => {
            if (cellFillMode && fillTaskData && cellKey !== fillStartCell) {
                // Check if this cell has the same task
                const currentData = cellData[cellKey];
                if (currentData && currentData.taskId === fillTaskData.taskId) {
                    // Mark for deletion
                    cell.style.background = 'rgba(64, 64, 64, 0.6)';
                    cell.style.textDecoration = 'line-through';
                    filledCells.add(cellKey);
                }
            }
        });
        
        // Click to edit note or clear (only if not dragging)
        cell.addEventListener('click', (e) => {
            if (!cellFillMode) {
                openTaskModal(cellKey);
            }
        });
    } else {
        // Empty cell - accept task drops
        cell.addEventListener('dragover', (e) => {
            e.preventDefault();
            cell.classList.add('drag-over');
        });
        
        cell.addEventListener('dragleave', () => {
            cell.classList.remove('drag-over');
        });
        
        cell.addEventListener('drop', (e) => {
            e.preventDefault();
            cell.classList.remove('drag-over');
            
            if (draggedTask) {
                // Copy task to this cell
                cellData[cellKey] = {
                    taskId: draggedTask.taskId,
                    taskName: draggedTask.taskName,
                    note: ''
                };
                localStorage.setItem('timegrid', JSON.stringify(cellData));
                refreshAllGrids();
            }
        });
        
        // Handle mouseover during fill mode
        cell.addEventListener('mouseenter', (e) => {
            if (cellFillMode && fillTaskData) {
                // Preview fill
                if (!filledCells.has(cellKey)) {
                    cell.style.background = 'rgba(59, 130, 246, 0.5)';
                    cell.textContent = fillTaskData.taskName;
                    filledCells.add(cellKey);
                }
            }
        });
    }
    
    return cell;
}

// ============== MODAL FUNCTIONS ==============

function openTaskModal(cellKey) {
    currentCell = cellKey;
    const data = cellData[cellKey] || {};
    
    const [date, time] = cellKey.split('T');
    const hour = parseInt(time);
    const ampm = hour < 12 ? 'am' : 'pm';
    const displayHour = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
    
    document.getElementById('modalHeader').textContent = `${data.taskName || 'Task'} - ${displayHour}${ampm} ${new Date(date).toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })}`;
    document.getElementById('noteInput').value = data.note || '';
    document.getElementById('noteInput').focus();
    document.getElementById('modal').classList.add('visible');
}

function clearCell() {
    delete cellData[currentCell];
    localStorage.setItem('timegrid', JSON.stringify(cellData));
    refreshAllGrids();
    document.getElementById('modal').classList.remove('visible');
}

function refreshAllGrids() {
    document.getElementById('grid1').innerHTML = '';
    document.getElementById('grid2').innerHTML = '';
    generateGrid('grid1', 0, 14);
    generateGrid('grid2', 14, 14);
}

function saveCell() {
    const note = document.getElementById('noteInput').value.trim();
    
    if (cellData[currentCell]) {
        cellData[currentCell].note = note;
    }
    
    // Save to localStorage
    localStorage.setItem('timegrid', JSON.stringify(cellData));
    
    // Refresh all grids
    refreshAllGrids();
    
    // Close modal
    document.getElementById('modal').classList.remove('visible');
}

// ============== TOOLTIP ==============

function showTooltip(event, cellKey) {
    const data = cellData[cellKey];
    if (!data || !data.note) return;
    
    const [date, time] = cellKey.split('T');
    const hour = parseInt(time);
    const ampm = hour < 12 ? 'am' : 'pm';
    const displayHour = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
    
    document.getElementById('tooltipTime').textContent = `${displayHour}${ampm}`;
    document.getElementById('tooltipNote').textContent = data.note;
    
    const tooltip = document.getElementById('tooltip');
    tooltip.classList.add('visible');
    tooltip.style.left = event.pageX + 10 + 'px';
    tooltip.style.top = event.pageY + 10 + 'px';
}

function hideTooltip() {
    document.getElementById('tooltip').classList.remove('visible');
}

// ============== EVENT LISTENERS ==============

// Global mouseup to finish cell fill mode
document.addEventListener('mouseup', (e) => {
    if (cellFillMode) {
        cellFillMode = false;
        
        // Process all cells that were dragged over
        if (fillTaskData && filledCells.size > 1) {
            let modified = false;
            
            filledCells.forEach(key => {
                if (key !== fillStartCell) {
                    const existingData = cellData[key];
                    
                    // If cell already has the same task, clear it (undo)
                    if (existingData && existingData.taskId === fillTaskData.taskId) {
                        delete cellData[key];
                        modified = true;
                    } 
                    // If cell is empty or has a different task, fill with current task
                    else if (!existingData || !existingData.taskName) {
                        cellData[key] = {
                            taskId: fillTaskData.taskId,
                            taskName: fillTaskData.taskName,
                            note: ''
                        };
                        modified = true;
                    }
                }
            });
            
            if (modified) {
                localStorage.setItem('timegrid', JSON.stringify(cellData));
                refreshAllGrids();
            }
        }
        
        // Reset
        fillStartCell = null;
        fillTaskData = null;
        filledCells = new Set();
    }
});

// Close modal on click outside
document.getElementById('modal').onclick = (e) => {
    if (e.target.id === 'modal') {
        document.getElementById('modal').classList.remove('visible');
    }
};

// ============== INITIALIZATION ==============

// Load data from localStorage
const saved = localStorage.getItem('timegrid');
if (saved) cellData = JSON.parse(saved);

// Initialize all grids
// Row 1: Week 1 (days 0-6) | Week 2 (days 7-13)
generateTimeLabels('timeLabels1');
generateGrid('grid1', 0, 14);

// Row 2: Week 3 (days 14-20) | Week 4 (days 21-27)
generateTimeLabels('timeLabels2');
generateGrid('grid2', 14, 14);

