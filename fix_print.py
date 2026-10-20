import os

def fix_print():
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                
                # Replace print with debugPrint but check if it's actually print()
                if 'print(' in content:
                    # Simple replace, assumes no custom print variable
                    new_content = content.replace('print(', 'debugPrint(')
                    
                    # Add import if needed
                    if 'debugPrint(' in new_content and 'package:flutter/foundation.dart' not in new_content:
                        new_content = "import 'package:flutter/foundation.dart';\n" + new_content
                    
                    with open(path, 'w') as f:
                        f.write(new_content)
                    print(f"Fixed prints in {path}")

if __name__ == '__main__':
    fix_print()
