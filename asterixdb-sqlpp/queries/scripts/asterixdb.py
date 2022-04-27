import json
import logging

import requests


class AsterixDB:
    def __init__(self, server_uri, dataverse):
        self.server_uri = server_uri
        self.dataverse = dataverse

    def run(self, query):
        query_uri = 'http://{server_uri}/query/service'.format(
            server_uri=self.server_uri)
        logging.info('Running query against %s', query_uri)

        # Use given dataverse
        if self.dataverse:
            # Create if not exists
            dataverse_query = 'CREATE DATAVERSE {} IF NOT EXISTS' \
                .format(self.dataverse)
            response = requests.post(query_uri,
                                     {'statement': dataverse_query})

            # Modify query
            logging.info('Using dataverse %s', self.dataverse)
            query = 'USE {};'.format(self.dataverse) + query

        # Send request
        logging.debug('Sending query:\n%s', query)
        response = requests.post(query_uri, {'statement': query})

        result = json.loads(response.text)
        logging.debug('Got result:\n%s', result)

        # Print some statistics
        metrics = result.get('metrics', {})
        logging.info('Request ID: %s', result.get('requestID', '(unknown)'))
        logging.info('Status: %s', result.get('status', '(unknown)'))
        logging.info('Elapsed time: %s', metrics.get('elapsedTime', '(unknown)'))
        logging.info('Execution time: %s', metrics.get('executionTime', '(unknown)'))
        logging.info('Result count: %s', metrics.get('resultCount', '(unknown)'))
        logging.info('Result size %s', metrics.get('resultSize', '(unknown)'))
        logging.info('Processed objects: %s', metrics.get('processedObjects', '(unknown)'))

        # Handle warnings
        warnings = result.get('warnings', [])
        for warning in warnings:
            if 'code' not in warning:
                warning['code'] = '(none)'
            if 'msg' not in warning:
                warning['msg'] = '(none)'
        for warning in warnings:
            logging.warning('AsterixDB warning (%i): %s',
                            warning['code'], warning['msg'])

        # Handle errors
        errors = result.get('errors', [])
        for error in errors:
            if 'code' not in error:
                error['code'] = '(none)'
            if 'msg' not in error:
                error['msg'] = '(none)'
        for error in errors:
            logging.error('Error (%i): %s', error['code'], error['msg'])

        if errors:
            raise RuntimeError('AsterixDB error (%i): %s',
                               error['code'], error['msg'])

        # Return result (if any)
        if 'results' in result:
            return result['results']
