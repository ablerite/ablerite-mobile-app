import os, re

def fix():
    # Remove unnecessary imports
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                
                original = content
                content = content.replace("import 'package:flutter/foundation.dart';\n", "")
                
                if original != content:
                    with open(path, 'w') as f:
                        f.write(content)
                    print(f"Fixed import in {path}")

    # Fix specific files
    def comment_out(filepath, search_str):
        if not os.path.exists(filepath): return
        with open(filepath, 'r') as f: content = f.read()
        if search_str in content:
            content = content.replace(search_str, '// ' + search_str)
            with open(filepath, 'w') as f: f.write(content)
            print(f"Commented out {search_str} in {filepath}")

    comment_out('lib/ui/voice_chat_page.dart', "String _aiResponse = '';")
    comment_out('lib/ui/widgets/session_timer_widget.dart', "String get _timeLabel {")
    comment_out('lib/ui/affirmations_page.dart', "Widget _buildSavedSetsSection")
    comment_out('lib/ui/mbs_pages.dart', "void _deleteLog")
    comment_out('lib/ui/mbs_pages.dart', "void _editLog")
    comment_out('lib/ui/mbs_overview_page.dart', "bool _isInCurrentWeek")
    comment_out('lib/ui/learn_page.dart', "class _TopicDetailPage")
    comment_out('lib/ui/notebooks_page.dart', "String _pageTitle")

    # Fix surfaceVariant
    with open('lib/main.dart', 'r') as f: content = f.read()
    if 'colorScheme.surfaceVariant' in content:
        content = content.replace('colorScheme.surfaceVariant', 'colorScheme.surfaceContainerHighest')
        with open('lib/main.dart', 'w') as f: f.write(content)

    # Fix main_scaffold.dart WillPopScope
    with open('lib/ui/main_scaffold.dart', 'r') as f: content = f.read()
    if 'WillPopScope' in content:
        content = content.replace('WillPopScope(', 'PopScope(')
        # Note: PopScope needs `canPop: false, onPopInvokedWithResult: ...`
        # I'll do this manually via multi_replace_file_content.
    
if __name__ == '__main__':
    fix()
