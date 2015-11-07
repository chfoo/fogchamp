'''Convert CSV files into JSON files needed for the visualizer page.'''
import argparse
import json
import os
import functools
from util.readers.addarash1 import AddarashReader
from util.readers.bulbapedia import BulbapediaReader
from util.readers.chfoo import ChfooReader

from util.readers.nkekev import NkekevReader
from util.readers.pokedex import PokedexReader


def main():
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('--output-dir', default='./')
    arg_parser.add_argument('--metadata-dir', default='metadata/')
    args = arg_parser.parse_args()

    nkekev_dir = os.path.join(args.metadata_dir, 'nkekev')
    chfoo_dir = os.path.join(args.metadata_dir, 'chfoo')
    addarash1_dir = os.path.join(args.metadata_dir, 'addarash1')
    pokedex_dir = os.path.join(args.metadata_dir, 'pokedex', 'pokedex', 'data', 'csv')
    bulbapedia_dir = os.path.join(args.metadata_dir, 'bulbapedia')
    output_dir = args.output_dir

    pokedex_reader = PokedexReader(pokedex_dir)
    nkekev_reader = NkekevReader(nkekev_dir)
    chfoo_reader = ChfooReader(chfoo_dir)
    addarash1_reader = AddarashReader(addarash1_dir)
    bulbapedia_reader = BulbapediaReader(bulbapedia_dir)

    # Build each Pokemon's stats
    movesets_funcs = [
        ('pbr-gold-1.2-2015-11-07', functools.partial(
            addarash1_reader.read_pbr_gold_1_2_2015_11_07,
            nkekev_reader, chfoo_reader)),
        ('pbr-gold-1.2', functools.partial(addarash1_reader.read_pbr_gold_1_2,
                                           nkekev_reader, chfoo_reader)),
        ('pbr-seel', functools.partial(chfoo_reader.read_pbr_seel, nkekev_reader)),
        ('pbr-platinum', nkekev_reader.read_pbr_platinum),
        ('pbr-gold', nkekev_reader.read_pbr_gold),
    ]
    for move_slug, func in movesets_funcs:
        pokemon_stats = {}
        pokemon_slugs = []
        pokemon_types = pokedex_reader.read_pokemon_types()
        pokemon_weights = pokedex_reader.read_pokemon_weights()

        for pokemon_stat in func():
            slug = pokemon_stat.pop('slug')
            pokemon_slugs.append(slug)
            pokemon_stats[slug] = pokemon_stat
            pokemon_stats[slug]['types'] = pokemon_types[pokemon_stat['number']]
            pokemon_stats[slug]['weight'] = pokemon_weights[pokemon_stat['number']]

        json_path = os.path.join(output_dir, '{}.json'.format(move_slug))

        with open(json_path, 'w') as file:
            file.write(json.dumps({
                 'stats': pokemon_stats,
                 'pokemon_slugs': pokemon_slugs
            }, indent=2, sort_keys=True))

    # Build all the moves
    move_stats = {}

    for move in pokedex_reader.read_moves():
        slug = move.pop('slug')
        move_stats[slug] = move

    bulbapedia_reader.downgrade_move_changes(move_stats)

    json_path = os.path.join(output_dir, 'moves.json')

    with open(json_path, 'w') as file:
        file.write(json.dumps(move_stats, indent=2, sort_keys=True))

    # Build descriptions and misc
    abilities = {}

    for ability in pokedex_reader.read_abilities():
        slug = ability.pop('slug')
        abilities[slug] = ability

    types_efficacy = pokedex_reader.read_type_efficacy()

    json_path = os.path.join(output_dir, 'descriptions.json')

    with open(json_path, 'w') as file:
        file.write(json.dumps({
            'abilities': abilities,
            'types_efficacy': types_efficacy,
        }, indent=2, sort_keys=True))

if __name__ == '__main__':
    main()
