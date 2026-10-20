import os, re

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original = content
    # Fix withOpacity
    content = content.replace('.withOpacity(', '.withValues(alpha: ')
    
    # Fix surfaceVariant
    content = content.replace('colorScheme.surfaceVariant', 'colorScheme.surfaceContainerHighest')

    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Fixed {filepath}")

for root, _, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            fix_file(os.path.join(root, f))
