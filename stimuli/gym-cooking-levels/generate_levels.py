#!/usr/bin/env python3
import os

# ─── CONFIG ────────────────────────────────────────────────────────────────────

# design‐intent combos (dir names)
agent_intents  = ['1agent', 'either_agents', '2agent']
recipe_intents = ['onion', 'either_recipe', 'tomato']

# actual task combos (file names)
actual_agents  = ['1agent', '2agent']
actual_recipes = ['onion', 'tomato']

# layout for each (design_agent, design_recipe)
layouts = {
    ('1agent', 'onion'): """\
-----/-
-  -l /
-  -o -
*   - -
-     -
t     -
-p-----""",

    ('either_agents', 'onion'): """\
-------
-  l  -
- / / -
*     o
- - - -
-     -
--p-t--""",

    ('2agent', 'onion'): """\
--/-/--
-  o  -
-     -
*     -
----- -
t     -
-lp----""",

    ('1agent', 'either_recipe'): """\
-----/-
-  -l /
-  -p -
*   - -
-     -
t     -
-o-----""",

    ('either_agents', 'either_recipe'): """\
-------
-  l  -
- / / -
*     p
- - - -
-     -
--o-t--""",

    ('2agent', 'either_recipe'): """\
--/-/--
-  -  -
-     -
*     -
----- -
t     -
-olp---""",

    ('1agent', 'tomato'): """\
-----/-
-  -l /
-  -t -
*   - -
-     -
o     -
-p-----""",

    ('either_agents', 'tomato'): """\
-------
-  l  -
- / / -
*     t
- - - -
-     -
--p-o--""",

    ('2agent', 'tomato'): """\
--/-/--
-  t  -
-     -
*     -
----- -
o     -
-lp----""",
}

# map actual recipe → class name
recipe_map = {
    'onion':  'SaladOL',
    'tomato': 'Salad',
}

# start locations for each design_agent, then for each actual_agent
start_locs = {
    '1agent': {
        '1agent': [(1,1), (4,4), (4,4), (4,4)],
        '2agent': [(1,1), (2,1), (4,4), (4,4)],
    },
    'either_agents': {
        '1agent': [(3,2), (4,4), (4,4), (4,4)],
        '2agent': [(2,1), (4,1), (4,4), (4,4)],
    },
    '2agent': {
        '1agent': [(3,2), (4,4), (4,4), (4,4)],
        '2agent': [(1,1), (5,1), (4,4), (4,4)],
    },
}

# ─── SCRIPT ────────────────────────────────────────────────────────────────────

if __name__ == '__main__':
    base_dir = os.path.dirname(os.path.abspath(__file__))
    for ai in agent_intents:
        for ri in recipe_intents:
            dir_path = os.path.join(base_dir, f'{ai}-{ri}')
            os.makedirs(dir_path, exist_ok=True)

            layout = layouts[(ai, ri)]
            for aa in actual_agents:
                for ar in actual_recipes:
                    fn = f'{aa}-{ar}.txt'
                    path = os.path.join(dir_path, fn)
                    with open(path, 'w') as f:
                        # Phase 1: layout
                        f.write(layout)
                        f.write('\n\n')
                        # Phase 2: recipe
                        f.write(recipe_map[ar])
                        f.write('\n\n')
                        # Phase 3: up to 4 start locations
                        for x, y in start_locs[ai][aa]:
                            f.write(f'{x} {y}\n')

    print("All folders and files generated under", base_dir)
