from abc import ABC, abstractmethod
import subprocess

# This superclass might be useful in case other means
# of querying Presto are added in the future
class PrestoProxy(ABC):
  @abstractmethod
  def run(self, query_file, other_params):
    pass


class PrestoCliProxy(PrestoProxy):
  def __init__(self, cmd, server, catalogue, schema):
    self.cmd = cmd
    self.server = server
    self.catalogue = catalogue
    self.schema = schema

  def run(self, query):
    # Assemble command
    cmd = [self.cmd,
           '--server', self.server,
           '--catalog', self.catalogue,
           '--schema', self.schema,
           '--file', '/dev/stdin',
           '--output-format', 'CSV_HEADER']

    # Run query and read result
    return subprocess.check_output(cmd, encoding='utf-8', input=query)
