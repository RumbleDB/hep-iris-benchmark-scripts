import glob
from os.path import dirname, join
from socket import getfqdn

def pytest_addoption(parser):
    parser.addoption('-Q', '--query-id', action='append', default=[],
                     help='Folder name of query to run.')
    parser.addoption('-F', '--freeze-result', action='store', default=False,
                     help='Whether the results of the query should be '
                          'persisted to disk.')
    parser.addoption('-U', '--user', action="store",
                        default="user",
                        help="The username required to log into psql")
    parser.addoption('-P', '--password', action="store",
                        default="password",
                        help="The password required to log into psql")
    parser.addoption('-D', '--database', action="store",
                        default="user",
                        help="The database required to log into psql")
    parser.addoption('-N', '--num-events', action='store', default=1000,
                     help='Number of events taken from the input file. '
                          'This influences which reference file should be '
                          'taken.')
    parser.addoption('-I', '--input-table', action='store',
                     help='Name of input table or view.')
    parser.addoption('--plot-histogram', action='store_true', default=False,
                     help='Plot resulting histogram as PNG file.')


def find_queries():
    basedir = join(dirname(__file__), 'queries')
    queryfiles = glob.glob(join(basedir, '**/query.sql'), recursive=True)
    # Lexicographically sort the queries based on their TLD name
    return sorted([s[len(basedir)+1:-len('/query.sql')] for s in queryfiles])


def pytest_generate_tests(metafunc):
    if 'query_id' in metafunc.fixturenames:
      queries = metafunc.config.getoption('query_id') or find_queries()
      metafunc.parametrize('query_id', queries)
