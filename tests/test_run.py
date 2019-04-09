from run import run
import os.path
from osmnames.export_osmnames.export_osmnames import geonames_export_path, housenumbers_export_path


# this test runs the osmnames process from importing a small pbf file to
# exporting the resulting tsv file. Downloading the PBF file and importing the
# wikipedia dump is skipped
def test_run():
    run()

    assert os.path.isfile(geonames_export_path())
    assert os.path.isfile(housenumbers_export_path())
