#!/usr/bin/python3

from pathlib import Path
import yaml
import argparse

parser = argparse.ArgumentParser("convert libpostal yaml to to stdin for sql")
parser.add_argument("path", help="path where the yaml files are located")
args = parser.parse_args()

print("admin_level_type_mapping:")
yaml_file_paths = Path(args.path).glob('*.yaml')
for yaml_file_path in yaml_file_paths:
    with yaml_file_path.open(encoding='utf-8') as yaml_file:
        country_code = yaml_file_path.stem

        yaml_data = yaml.load(yaml_file, Loader=yaml.FullLoader)
        for admin_level, mapped_type in yaml_data['admin_level'].items():
            line = '\t'.join([country_code, admin_level, mapped_type])

            print(line)

print("")
print("admin_level_type_mapping_override")
yaml_file_paths = Path(args.path).glob('*.yaml')
for yaml_file_path in yaml_file_paths:
    with yaml_file_path.open(encoding='utf-8') as yaml_file:
        country_code = yaml_file_path.stem

        yaml_data = yaml.load(yaml_file, Loader=yaml.FullLoader)
        if ('overrides' in yaml_data and 'id' in yaml_data['overrides'] and 'relation' in yaml_data['overrides']['id']):
            for osm_id, mapped_type in yaml_data['overrides']['id']['relation'].items():
                if (mapped_type is not None):
                    line = '\t'.join([country_code, -osm_id, mapped_type])

                    print(line)
