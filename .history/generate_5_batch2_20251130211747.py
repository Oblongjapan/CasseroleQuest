from itertools import combinations

ingredients = [
    "Asparagus", "Bread", "Broccoli", "Carrot", "Chicken Breast",
    "Lettuce", "Peas", "Potato", "Rice", "Salmon", "Spinach", "Steak", "Tofu"
]

# Get existing 5-ingredient combos
existing_combos = set()
with open(r"c:\Users\willi\OneDrive\Documents\Microwavr\scripts\data\recipes.gd", "r", encoding="utf-8") as f:
    for line in f:
        if line.strip().startswith('"') and line.count('|') == 4:
            if '": "' in line:
                key = line.strip().split('": "')[0].strip('"')
                existing_combos.add(key)

# Generate all 5-ingredient combos
all_combos = []
for combo in combinations(ingredients, 5):
    key = "|".join(sorted(combo))
    if key not in existing_combos:
        all_combos.append(key)

all_combos.sort()

# Print next 150 (100-250)
for i, combo in enumerate(all_combos[100:250], 101):
    print(f'{i}. {combo}')
