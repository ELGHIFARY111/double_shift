import json
import re
import os

log_path = r"C:\Users\LENOVO\.gemini\antigravity\brain\979fc4ce-6d72-4ae7-bcd2-7f5d74dbaad0\.system_generated\logs\overview.txt"
out_dir = r"d:\godotgame\double-shift\scripts\ui"

files_to_recover = [
    "cleaningUi.gd", "cookingUi.gd", "dialogueUi.gd", "emailUi.gd",
    "furnitureUi.gd", "interactProm.gd", "inventoryUi.gd", "jobPortalUi.gd",
    "mapSelectionUi.gd", "questTrackerUi.gd", "shopUi.gd", "travelPanel.gd"
]

file_contents = {f: None for f in files_to_recover}

with open(log_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            data = json.loads(line)
            tool_calls = data.get("tool_calls", [])
            for call in tool_calls:
                if call.get("name") == "write_to_file":
                    args = call.get("args", {})
                    target = args.get("TargetFile", "")
                    for fname in files_to_recover:
                        if fname in target:
                            file_contents[fname] = args.get("CodeContent", "")
        except:
            pass

for fname, content in file_contents.items():
    if content:
        out_path = os.path.join(out_dir, fname)
        with open(out_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Recovered FULL {fname} from write_to_file")
    else:
        print(f"Could not find write_to_file for {fname}")
