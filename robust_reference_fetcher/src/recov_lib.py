import os
import shutil


def attempt_recovery(name, old_dir_path, output_path, recovery_map=None):
    """
    Attempts to find a file matching 'name' in 'old_dir_path'.
    Prioritizes 'recovery_map' (name -> [filenames]), then fuzzy search.
    """
    if not os.path.exists(old_dir_path):
        return False, None

    # 1. Explicit Map
    if recovery_map and name in recovery_map:
        candidates = recovery_map[name]
        for candidate in candidates:
            # Try recursive search for this specific filename
            for root, dirs, files in os.walk(old_dir_path):
                if candidate in files:
                    src = os.path.join(root, candidate)
                    try:
                        shutil.copy2(src, output_path)
                        return True, candidate
                    except:
                        pass

    # 2. Fuzzy Search
    keywords = [k for k in name.split() if len(k) > 3 and not k.startswith("(")]
    if not keywords:
        return False, None

    for root, dirs, files in os.walk(old_dir_path):
        for file in files:
            # Match strictly on significant keywords
            match_count = sum(1 for k in keywords if k.lower() in file.lower())
            if match_count >= 2:  # Arbitrary threshold, adjustable
                src = os.path.join(root, file)
                try:
                    shutil.copy2(src, output_path)
                    return True, file
                except:
                    continue

    return False, None
