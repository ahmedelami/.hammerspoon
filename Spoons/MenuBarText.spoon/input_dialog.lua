--- Input Dialog Module
--- Handles creating a focused text input dialog
---
--- This dialog auto-focuses and allows immediate typing

local M = {}

--- Show an input dialog with auto-focus
--- @param callback function Called with the entered text (or nil if cancelled)
--- @param currentText string Optional current text to pre-fill
--- @param maxLength number Maximum character length
function M.show(callback, currentText, maxLength)
    -- Create a webview-based dialog for better control
    local webview = hs.webview.new({x = 0, y = 0, w = 400, h = 150})
    
    -- Get screen dimensions to center the dialog
    local screenFrame = hs.screen.mainScreen():frame()
    local dialogX = (screenFrame.w - 400) / 2
    local dialogY = (screenFrame.h - 150) / 2
    webview:frame({x = dialogX, y = dialogY, w = 400, h = 150})
    
    -- HTML content with auto-focus
    local html = [[
<!DOCTYPE html>
<html>
<head>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            padding: 20px;
            margin: 0;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h3 {
            margin: 0 0 15px 0;
            font-size: 16px;
            color: #333;
        }
        input {
            width: 100%;
            padding: 8px;
            font-size: 14px;
            border: 2px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
            margin-bottom: 15px;
            text-transform: uppercase;
        }
        input:focus {
            outline: none;
            border-color: #007AFF;
        }
        .buttons {
            display: flex;
            gap: 10px;
            justify-content: flex-end;
        }
        button {
            padding: 6px 16px;
            border: none;
            border-radius: 4px;
            font-size: 14px;
            cursor: pointer;
        }
        .ok-btn {
            background-color: #007AFF;
            color: white;
        }
        .ok-btn:hover {
            background-color: #0056b3;
        }
        .cancel-btn {
            background-color: #e0e0e0;
            color: #333;
        }
        .cancel-btn:hover {
            background-color: #d0d0d0;
        }
        .char-count {
            font-size: 12px;
            color: #666;
            margin-bottom: 10px;
            text-align: right;
        }
    </style>
</head>
<body>
    <div class="container">
        <h3>Menu Bar Text</h3>
        <input type="text" id="textInput" maxlength="]] .. maxLength .. [[" value="]] .. (currentText or "") .. [[" placeholder="Enter text (ALL CAPS)">
        <div class="char-count"><span id="charCount">0</span>/]] .. maxLength .. [[</div>
        <div class="buttons">
            <button class="cancel-btn" onclick="cancel()">Cancel</button>
            <button class="ok-btn" onclick="submit()">OK</button>
        </div>
    </div>
    <script>
        const input = document.getElementById('textInput');
        const charCount = document.getElementById('charCount');
        
        // Auto-focus and select all text
        input.focus();
        input.select();
        
        // Update character count
        function updateCount() {
            charCount.textContent = input.value.length;
        }
        updateCount();
        
        input.addEventListener('input', function() {
            this.value = this.value.toUpperCase();
            updateCount();
        });
        
        // Submit on Enter key
        input.addEventListener('keydown', function(e) {
            if (e.key === 'Enter') {
                submit();
            } else if (e.key === 'Escape') {
                cancel();
            }
        });
        
        function submit() {
            window.location.href = 'submit:' + encodeURIComponent(input.value);
        }
        
        function cancel() {
            window.location.href = 'cancel:';
        }
    </script>
</body>
</html>
    ]]
    
    webview:html(html)
    webview:windowStyle({"titled", "closable", "nonactivating"})
    webview:closeOnEscape(true)
    webview:allowTextEntry(true)
    webview:level(hs.drawing.windowLevels.floating)
    
    -- Handle navigation (form submission)
    webview:navigationCallback(function(action, webView, navAction)
        if action == "didFinishNavigation" then
            return
        end
        
        local url = navAction.request.URL
        if url:match("^submit:") then
            local text = url:gsub("^submit:", "")
            text = hs.http.urlDecode(text)
            webview:delete()
            callback(text)
            return false
        elseif url:match("^cancel:") then
            webview:delete()
            callback(nil)
            return false
        end
    end)
    
    webview:show()
end

return M







