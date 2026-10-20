import os

def fix_mounted():
    for root, dirs, files in os.walk('lib/ui'):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                
                original = content
                content = content.replace('if (mounted)', 'if (context.mounted)')
                content = content.replace('if (!mounted)', 'if (!context.mounted)')
                
                if original != content:
                    with open(path, 'w') as f:
                        f.write(content)
                    print(f"Fixed mounted in {path}")

if __name__ == '__main__':
    fix_mounted()
