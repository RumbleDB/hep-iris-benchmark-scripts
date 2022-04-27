import json
import numpy as np
import psycopg2
import time

class Psql:
  def __init__(self, user, password, stats_path=None, db_name=None,
    autocommit=True, disk_name="nvme1n1"):
    self.user = user
    self.password = password
    self.db_name = db_name
    self.stats_path = stats_path if stats_path else "/data/query.log"
    self.disk_name = disk_name

    if not self.db_name:
      self.connection = psycopg2.connect(user=self.user,
                                         password=self.password)
    else:
      self.connection = psycopg2.connect(dbname=self.db_name,
                                         user=self.user,
                                         password=self.password)

    self.connection.autocommit = autocommit


  @staticmethod
  def _read_diskstats(disk_name, sector_size_bytes=512):
    with open("/proc/diskstats") as f:
      lines = [x.split() for x in f.readlines()]

    line = [x for x in lines if x[2] == disk_name][0]
    return int(line[5]) * sector_size_bytes, line


  def close(self):
    self.connection.close()


  def run(self, query):
    # Execute the query and get the results
    stats = {}
    with self.connection.cursor() as cursor:
      stats["bytes_prior"], stats["disk_stats_prior"] = \
        self._read_diskstats(self.disk_name)

      start_time = time.time()
      cursor.execute(query)
      stats["internal_elapsed_time_s"] = time.time() - start_time

      stats["bytes_posterior"], stats["disk_stats_posterior"] = \
        self._read_diskstats(self.disk_name)
      stats["internal_read_bytes"] = stats["bytes_posterior"] - \
        stats["bytes_prior"]
      res_query = cursor.fetchall()

    # Get the statistics around this query
    with self.connection.cursor() as cursor:
      cursor.execute("SELECT * FROM pg_stat_statements AS p WHERE p.query LIKE '%ORDER BY x' LIMIT 1;")
      res_stats = cursor.fetchall()
      colnames = [desc[0] for desc in cursor.description]

    res_stats = res_stats[0][:-1]
    for idx, stat in enumerate(res_stats):
      stats[colnames[idx]] = stat
    with open(self.stats_path, "w") as f:
      json.dump(stats, f)

    return (res_query, stats)


  def run_no_results(self, query):
    # Execute the query and get the results
    with self.connection.cursor() as cursor:
      cursor.execute(query)

