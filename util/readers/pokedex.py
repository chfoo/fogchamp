import collections
import re

from util.readers.base import Reader


DAMAGE_CATEGORY_MAP = {
    1: 'status',
    2: 'physical',
    3: 'special',
}


class PokedexReader(Reader):
    def read_types_map(self):
        types_map = {}

        with self.read_csv('types.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                id_num = int(row[0])
                slug = row[1]

                types_map[id_num] = slug

        return types_map

    def read_moves(self):
        types_map = self.read_types_map()
        move_name_map = self.read_move_names()
        move_desc_map = self.read_move_descriptions()
        move_effects_map = self.read_move_effects()
        move_meta_map = self.read_move_meta()

        with self.read_csv('moves.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                move_id = int(row[0])
                slug = row[1]
                move_type = types_map[int(row[3])]

                # Downgrade to gen 4
                if move_type == 'fairy':
                    move_type = 'normal'

                power = int(row[4]) if row[4] else None
                pp = int(row[5]) if row[5] else None
                accuracy = int(row[6]) if row[6] else None
                priority = int(row[7]) if row[7] else None
                damage_category = DAMAGE_CATEGORY_MAP[int(row[9])]
                effect_id = int(row[10])
                effect_chance = int(row[11]) if row[11] else None

                effect_short = move_effects_map.get(effect_id, (None, None))[0]
                effect_long = move_effects_map.get(effect_id, (None, None))[1]

                if effect_short:
                    effect_short = self.strip_hyperlink(effect_short)

                if effect_long:
                    effect_long = self.strip_hyperlink(effect_long)

                doc = {
                    'slug': slug,
                    'move_type': move_type,
                    'power': power,
                    'pp': pp,
                    'accuracy': accuracy,
                    'damage_category': damage_category,
                    'priority': priority,
                    'name': move_name_map[move_id],
                    'description': move_desc_map.get(move_id),
                    'effect_short': effect_short,
                    'effect_long': effect_long,
                    'effect_chance': effect_chance,
                }

                doc.update(move_meta_map.get(move_id, {}))

                yield doc

    def read_move_names(self, lang=9):
        move_name_map = {}

        with self.read_csv('move_names.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                move_id, row_lang, name = row
                move_id = int(move_id)
                row_lang = int(row_lang)

                if row_lang != lang:
                    continue

                move_name_map[move_id] = name

        return move_name_map

    def read_move_meta(self):
        move_meta_map = {}

        with self.read_csv('move_meta.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                move_id = int(row[0])
                min_hits = int(row[3]) if row[3] else None
                max_hits = int(row[4]) if row[4] else None

                move_meta_map[move_id] = {
                    'min_hits': min_hits,
                    'max_hits': max_hits,
                }

        return move_meta_map

    def read_move_descriptions(self, lang=9):
        move_desc_map = {}

        with self.read_csv('move_flavor_text.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                effect_id = int(row[0])
                lang_id = int(row[2])
                description = row[3]

                if lang_id != lang:
                    continue

                move_desc_map[effect_id] = description

        return move_desc_map

    def read_move_effects(self, lang=9):
        move_desc_map = {}

        with self.read_csv('move_effect_prose.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                effect_id = int(row[0])
                language = int(row[1])
                short_effect = row[2]
                long_effect = row[3]

                if language != lang:
                    continue

                move_desc_map[effect_id] = short_effect, long_effect

        return move_desc_map

    def read_pokemon_types(self):
        types_map = self.read_types_map()
        pokemon_types = {}

        with self.read_csv('pokemon_types.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                pokemon_num = int(row[0])
                pokemon_type = types_map[int(row[1])]

                if pokemon_num not in pokemon_types:
                    pokemon_types[pokemon_num] = []

                pokemon_types[pokemon_num].append(pokemon_type)

        # Downgrade to gen 4
        for type_list in pokemon_types.values():
            for index in range(len(type_list)):
                pokemon_type = type_list[index]

                if pokemon_type == 'fairy' and index == 1:
                    type_list.pop()
                elif pokemon_type == 'fairy':
                    type_list[index] = 'normal'

            # Ensure no duplicates
            if len(type_list) > 1 and type_list[0] == type_list[1]:
                type_list.pop()

        return pokemon_types

    def read_abilities(self):
        name_map = self.read_ability_names()
        desc_map = self.read_ability_descriptions()

        with self.read_csv('abilities.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                ability_id = int(row[0])
                slug = row[1]

                yield {
                    'slug': slug,
                    'name': name_map[ability_id],
                    'description': desc_map.get(ability_id)
                }

    def read_ability_names(self, lang=9):
        name_map = {}

        with self.read_csv('ability_names.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                ability_id, row_lang, name = row
                ability_id = int(ability_id)
                row_lang = int(row_lang)

                if row_lang != lang:
                    continue

                name_map[ability_id] = name

        return name_map

    def read_ability_descriptions(self, lang=9):
        desc_map = {}

        with self.read_csv('ability_flavor_text.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                ability_id = int(row[0])
                lang_id = int(row[2])
                description = row[3]

                if lang_id != lang:
                    continue

                desc_map[ability_id] = description

        return desc_map

    def read_type_efficacy(self):
        types_map = self.read_types_map()
        efficacy_map = collections.defaultdict(dict)

        with self.read_csv('type_efficacy.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                user = types_map[int(row[0])]
                foe = types_map[int(row[1])]
                damage_factor = int(row[2])

                # Downgrade to gen 4
                if foe == 'steel' and user in ('ghost', 'dark'):
                    damage_factor = 50

                efficacy_map[user][foe] = damage_factor

        return efficacy_map

    def read_pokemon_weights(self):
        weight_map = {}

        with self.read_csv('pokemon.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                pokemon_num = int(row[0])
                weight = int(row[4]) / 10

                weight_map[pokemon_num] = weight

        return weight_map

    def read_item_names(self, lang=9):
        name_map = {}

        with self.read_csv('item_names.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                item_id, row_lang, name = row
                item_id = int(item_id)
                row_lang = int(row_lang)

                if row_lang != lang:
                    continue

                name_map[item_id] = name

        return name_map

    def read_item_descriptions(self, lang=9):
        desc_map = {}

        with self.read_csv('item_flavor_text.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                ability_id = int(row[0])
                lang_id = int(row[2])
                description = row[3]

                if lang_id != lang:
                    continue

                desc_map[ability_id] = description

        return desc_map

    def read_items(self):
        name_map = self.read_item_names()
        desc_map = self.read_item_descriptions()

        with self.read_csv('items.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                ability_id = int(row[0])
                slug = row[1]

                yield {
                    'slug': slug,
                    'name': name_map[ability_id],
                    'description': desc_map.get(ability_id)
                }

    @classmethod
    def strip_hyperlink(cls, text) -> str:
        def rep(match):
            if match.group(1):
                return match.group(1)
            else:
                return match.group(2).split(':', 1)[-1]

        return re.sub(r'\[(.*?)\]{(.*?)}', rep, text)
