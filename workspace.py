import os
import datetime
import pathlib

def collect_files(root_dir):
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f"workspace_snapshot_{timestamp}.md"
    
    # Define excluded directories and files
    excluded_dirs = {'.git', 'node_modules'}
    excluded_files = {'package-lock.json', 'collect_workspace.py', 'workspace.py'}
    
    with open(output_file, "w", encoding="utf-8") as f:
        for root, dirs, files in os.walk(root_dir):
            # Remove excluded directories
            for excluded in excluded_dirs:
                if excluded in dirs:
                    f.write(f"\n### Directory: {os.path.join(root, excluded)}\n")
                    f.write(f"*{excluded} directory present but contents excluded*\n")
                    dirs.remove(excluded)
            
            for file in sorted(files):
                if file in excluded_files:
                    f.write(f"\n### File: {os.path.relpath(os.path.join(root, file), root_dir)}\n")
                    f.write(f"*{file} present but contents excluded*\n")
                    continue
                
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, root_dir)
                
                # Skip binary, large, and git files
                if (pathlib.Path(file).suffix.lower() in 
                    ['.exe', '.dll', '.bin', '.o', '.pack', '.idx']):
                    continue
                    
                try:
                    with open(full_path, "r", encoding="utf-8") as source:
                        content = source.read()
                        
                    f.write(f"\n### File: {rel_path}\n")
                    f.write("```" + get_language(file) + "\n")
                    f.write(content)
                    f.write("\n```\n")
                except:
                    f.write(f"\n### File: {rel_path}\n")
                    f.write("*Binary or unreadable file*\n")

def get_language(filename):
    ext = pathlib.Path(filename).suffix.lower()
    languages = {
        '.py': 'python',
        '.js': 'javascript',
        '.ts': 'typescript', 
        '.ps1': 'powershell',
        '.psm1': 'powershell',
        '.json': 'json',
        '.md': 'markdown',
        '.yml': 'yaml',
        '.yaml': 'yaml',
        '.txt': '',
        '': ''
    }
    return languages.get(ext, '')

if __name__ == "__main__":
    collect_files(".")