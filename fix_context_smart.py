import re

def fix_context():
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
                    fixes_by_file[file_path] = set()
                fixes_by_file[file_path].add(line_num)
    
    for file_path, line_nums in fixes_by_file.items():
        line_nums = sorted(list(line_nums), reverse=True)
        
        with open(file_path, 'r') as f:
            content_lines = f.readlines()
            
        for ln in line_nums:
            idx = ln - 1
            original_line = content_lines[idx]
            
            # Find the start of the statement
            # If it's `context: context,` we need to go up until we find `await ` or `Navigator.` or `ScaffoldMessenger.`
            stmt_idx = idx
            while stmt_idx > 0 and stmt_idx >= idx - 10:
                line_text = content_lines[stmt_idx].strip()
                if 'await showDialog' in line_text or 'await showModalBottomSheet' in line_text or 'ScaffoldMessenger.of' in line_text or 'Navigator.' in line_text or 'showDialog' in line_text or 'showOptionsBottomSheet' in line_text or 'showDeleteBottomSheet' in line_text:
                    break
                stmt_idx -= 1
                
            if stmt_idx < idx - 10:
                stmt_idx = idx # fallback
                
            target_line = content_lines[stmt_idx]
            indent = len(target_line) - len(target_line.lstrip())
            indent_str = ' ' * indent
            
            if 'if (mounted)' in original_line:
                content_lines[idx] = original_line.replace('if (mounted)', 'if (context.mounted)')
            elif 'if (!mounted)' in original_line:
                content_lines[idx] = original_line.replace('if (!mounted)', 'if (!context.mounted)')
            elif 'if (mounted)' in target_line:
                content_lines[stmt_idx] = target_line.replace('if (mounted)', 'if (context.mounted)')
            elif 'if (!mounted)' in target_line:
                content_lines[stmt_idx] = target_line.replace('if (!mounted)', 'if (!context.mounted)')
            else:
                # Insert guard before the statement
                # Use context.mounted if context is the param name, else mounted. But usually context.mounted is safer.
                guard = f"{indent_str}if (!context.mounted) return;\n"
                
                if stmt_idx > 0 and 'if (!context.mounted) return;' in content_lines[stmt_idx-1]:
                    continue
                if 'if (!context.mounted) return;' in content_lines[stmt_idx]:
                    continue
                    
                content_lines.insert(stmt_idx, guard)
                
        with open(file_path, 'w') as f:
            f.writelines(content_lines)
        print(f"Fixed {len(line_nums)} context issues in {file_path}")

if __name__ == '__main__':
    fix_context()
