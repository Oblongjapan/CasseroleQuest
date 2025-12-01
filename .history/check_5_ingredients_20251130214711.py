from itertools import combinations

# All 13 ingredients
ingredients = [
    "Asparagus", "Bread", "Broccoli", "Carrot", "Chicken Breast",
    "Lettuce", "Peas", "Potato", "Rice", "Salmon", "Spinach", "Steak", "Tofu"
]

# Generate all possible 5-ingredient combinations
all_combos = set()
for combo in combinations(ingredients, 5):
    key = "|".join(sorted(combo))
    all_combos.add(key)

print(f"Total possible 5-ingredient combinations: {len(all_combos)}")

# Read existing recipes
existing_combos = set()
with open(r"c:\Users\willi\OneDrive\Documents\Microwavr\scripts\data\recipes.gd", "r", encoding="utf-8") as f:
    for line in f:
        if line.strip().startswith('"') and line.count('|') == 4:
            if '": "' in line:
                key = line.strip().split('": "')[0].strip('"')
                existing_combos.add(key)

print(f"Existing 5-ingredient combinations: {len(existing_combos)}")
print(f"Missing combinations: {len(all_combos - existing_combos)}")
