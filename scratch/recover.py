import json
import re
import os
import glob

brain_dir = r"C:\Users\LENOVO\.gemini\antigravity\brain"
out_dir = r"d:\godotgame\double-shift\scripts\ui"

files_to_recover = [
    "furnitureUi.gd", "interactProm.gd", "inventoryUi.gd",
    "mapSelectionUi.gd", "travelPanel.gd"
]

file_lines = {f: {} for f in files_to_recover}

# Get all overview.txt files
log_files = glob.glob(os.path.join(brain_dir, "*", ".system_generated", "logs", "overview.txt"))

for log_path in log_files:
    try:
        with open(log_path, 'r', encoding='utf-8') as f:
            for line in f:
                try:
                    data = json.loads(line)
                    content = data.get("content", "")
                    
                    if content:
                        matches = re.finditer(r"File Path: `file:///d:/godotgame/double-shift/scripts/ui/([^`]+)`.*?(?=File Path:|$)", content, re.IGNORECASE | re.DOTALL)
                        for match in matches:
                            filename = match.group(1)
                            if filename in files_to_recover:
                                text = match.group(0)
                                for line_str in text.split('\n'):
                                    line_match = re.match(r"^(\d+):\s(.*)$", line_str)
                                    if line_match:
                                        file_lines[filename][int(line_match.group(1))] = line_match.group(2)
                                    elif re.match(r"^(\d+):$", line_str):
                                        file_lines[filename][int(re.match(r"^(\d+):$", line_str).group(1))] = ""
                                        
                    # write_to_file CodeContent from earlier sessions
                    tool_calls = data.get("tool_calls", [])
                    for call in tool_calls:
                        if call.get("name") == "write_to_file":
                            args = call.get("args", {})
                            target = args.get("TargetFile", "")
                            for fname in files_to_recover:
                                if fname in target:
                                    code_content = args.get("CodeContent", "")
                                    for idx, line_str in enumerate(code_content.split('\n')):
                                        file_lines[fname][idx + 1] = line_str
                                        
                    # tool outputs view_file
                    if data.get("source") == "TOOL" and data.get("type") == "TOOL_RESPONSE":
                        tool_outputs = data.get("tool_outputs", [])
                        for out in tool_outputs:
                            if "view_file" in out.get("name", ""):
                                output = out.get("output", "")
                                matches = re.finditer(r"File Path: `file:///d:/godotgame/double-shift/scripts/ui/([^`]+)`.*?(?=File Path:|$)", output, re.IGNORECASE | re.DOTALL)
                                for match in matches:
                                    filename = match.group(1)
                                    if filename in files_to_recover:
                                        text = match.group(0)
                                        for line_str in text.split('\n'):
                                            line_match = re.match(r"^(\d+):\s(.*)$", line_str)
                                            if line_match:
                                                file_lines[filename][int(line_match.group(1))] = line_match.group(2)
                                            elif re.match(r"^(\d+):$", line_str):
                                                file_lines[filename][int(re.match(r"^(\d+):$", line_str).group(1))] = ""
                except:
                    pass
    except:
        pass

for filename, lines_dict in file_lines.items():
    if not lines_dict:
        print(f"Could not recover {filename}")
        continue
    
    max_line = max(lines_dict.keys())
    recovered_text = []
    for i in range(1, max_line + 1):
        recovered_text.append(lines_dict.get(i, ""))
    
    out_path = os.path.join(out_dir, filename)
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write("\n".join(recovered_text))
    print(f"Recovered {filename} ({max_line} lines)")







