from itertools import combinations

ingredients = [
    "Asparagus", "Bread", "Broccoli", "Carrot", "Chicken Breast",
    "Lettuce", "Peas", "Potato", "Rice", "Salmon", "Spinach", "Steak", "Tofu"
]

existing_combos = set()
with open(r"c:\Users\willi\OneDrive\Documents\Microwavr\scripts\data\recipes.gd", "r", encoding="utf-8") as f:
    for line in f:
        if line.strip().startswith('"') and line.count('|') == 4:
            if '": "' in line:
                key = line.strip().split('": "')[0].strip('"')
                existing_combos.add(key)

all_combos = []
for combo in combinations(ingredients, 5):
    key = "|".join(sorted(combo))
    if key not in existing_combos:
        all_combos.append(key)

all_combos.sort()

# Print 244-444 (200 more)
for combo in all_combos[:200]:
    print(f'		"{combo}": "",')
