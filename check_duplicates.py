from itertools import combinations
from collections import Counter

# All 13 ingredients
ingredients = [
    "Asparagus", "Bread", "Broccoli", "Carrot", "Chicken Breast",
    "Lettuce", "Peas", "Potato", "Rice", "Salmon", "Spinach", "Steak", "Tofu"
]

# Generate all possible 4-ingredient combinations
all_combos = set()
for combo in combinations(ingredients, 4):
    # Sort alphabetically and join with |
    key = "|".join(sorted(combo))
    all_combos.add(key)

print(f"Total possible 4-ingredient combinations: {len(all_combos)}")

# Read existing recipes from the file
existing_combos = []
line_numbers = {}
with open(r"c:\Users\willi\OneDrive\Documents\Microwavr\scripts\data\recipes.gd", "r", encoding="utf-8") as f:
    for line_num, line in enumerate(f, 1):
        # Look for 4-ingredient recipe lines
        if line.strip().startswith('"') and line.count('|') == 3:
            # Extract the key (ingredients before the colon)
            if '": "' in line:
                key = line.strip().split('": "')[0].strip('"')
                existing_combos.append(key)
                if key not in line_numbers:
                    line_numbers[key] = []
                line_numbers[key].append(line_num)

# Find duplicates
combo_counts = Counter(existing_combos)
duplicates = {k: v for k, v in combo_counts.items() if v > 1}

print(f"Existing 4-ingredient combinations: {len(existing_combos)}")
print(f"Unique 4-ingredient combinations: {len(set(existing_combos))}")
print(f"Duplicates found: {len(duplicates)}")

if duplicates:
    print("\nDuplicate combinations:")
    for combo, count in sorted(duplicates.items()):
        print(f"{combo} appears {count} times at lines: {line_numbers[combo]}")

# Find missing combinations
existing_set = set(existing_combos)
missing = sorted(all_combos - existing_set)

print(f"\nMissing combinations: {len(missing)}")
if missing:
    print("\nMissing 4-ingredient combinations:")
    for combo in missing:
        print(combo)
