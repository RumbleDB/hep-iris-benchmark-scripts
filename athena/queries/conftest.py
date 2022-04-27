import glob
from os.path import dirname, join

def pytest_addoption(parser):
  parser.addoption('-Q', '--query-id', action='append', default=[],
                   help='Folder name of query to run.')
  parser.addoption('-F', '--freeze-result', action='store_true',
                   help='Whether the results of the query should be '
                        'persisted to disk.')
  parser.addoption('--plot-histogram', action='store_true',
                   help='Plot resulting histogram as PNG file.')
  parser.addoption('-N', '--num-events', action='store', default=1000,
                   help='Number of events taken from the input file. '
                        'This influences which reference file should be '
                        'taken.')
  parser.addoption('--work-group', action='store',
                   help='Name of the work group to use for Athena.')
  parser.addoption('-S', '--staging-dir', action='store',
                   help='Directory on S3 used as output location by Athena.')
  parser.addoption('-P', '--database', action='store',
                   help='Name of the schema ("database") in Athena.')
  parser.addoption('-I', '--input-table', action='store',
                   help='Name of input table or view.')


def find_queries():
  basedir = join(dirname(__file__), 'queries')
  queryfiles = glob.glob(join(basedir, '**/query.sql'), recursive=True)
  # Lexicographically sort the queries based on their TLD name
  return sorted([s[len(basedir)+1:-len('/query.sql')] for s in queryfiles])


def pytest_generate_tests(metafunc):
  if 'query_id' in metafunc.fixturenames:
    queries = metafunc.config.getoption('query_id') or find_queries()
    metafunc.parametrize('query_id', queries)
