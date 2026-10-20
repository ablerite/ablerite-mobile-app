import re

def fix_context():
    # Read analyze output
    with open('analyze_output.txt', 'r') as f:
        lines = f.readlines()
    
    fixes_by_file = {}
    for line in lines:
        if 'use_build_context_synchronously' in line:
            parts = line.split(' • ')
            if len(parts) >= 3:
                file_info = parts[2].split(':')
                file_path = file_info[0]
                line_num = int(file_info[1])
                
                if file_path not in fixes_by_file:
                    fixes_by_file[file_path] = []
                fixes_by_file[file_path].append(line_num)
    
    for file_path, line_nums in fixes_by_file.items():
        # sort descending to not mess up earlier line numbers when inserting
        line_nums.sort(reverse=True)
        
        with open(file_path, 'r') as f:
            content_lines = f.readlines()
            
        for ln in line_nums:
            # ln is 1-indexed
            idx = ln - 1
            original_line = content_lines[idx]
            
            # Find indentation
            indent = len(original_line) - len(original_line.lstrip())
            indent_str = ' ' * indent
            
            # Special case: if line has `if (mounted)`
            if 'if (mounted)' in original_line:
                content_lines[idx] = original_line.replace('if (mounted)', 'if (context.mounted)')
            elif 'if (!mounted)' in original_line:
                content_lines[idx] = original_line.replace('if (!mounted)', 'if (!context.mounted)')
            else:
                # Insert the guard before the line
                guard = f"{indent_str}if (!context.mounted) return;\n"
                
                # Check if we already inserted it right above (due to multiple warnings on same line/adjacent lines)
                if idx > 0 and 'if (!context.mounted) return;' in content_lines[idx-1]:
                    continue
                    
                content_lines.insert(idx, guard)
                
        with open(file_path, 'w') as f:
            f.writelines(content_lines)
        print(f"Fixed {len(line_nums)} context issues in {file_path}")

if __name__ == '__main__':
    fix_context()
