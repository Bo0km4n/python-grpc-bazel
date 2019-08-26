import os
import sys
from concurrent import futures
import time
sys.path.append(os.getcwd())

import grpc
from grpc_reflection.v1alpha import reflection
import proto.service_pb2 as service_pb2
import proto.service_pb2_grpc as service_pb2_grpc
import api
from logzero import logger

_ONE_DAY_IN_SECONDS = 60 * 60 * 24

if __name__ == '__main__':
    server = grpc.server(
        futures.ThreadPoolExecutor(max_workers=10)
    )

    # entry services
    service_pb2_grpc.add_HealthServicer_to_server(
        api.Health(), server
    )

    SERVICE_NAMES = (
        service_pb2.DESCRIPTOR.services_by_name["Health"].full_name,
        reflection.SERVICE_NAME,
    )

    reflection.enable_server_reflection(SERVICE_NAMES, server)
    server.add_insecure_port("[::]:%s" % 8000)
    logger.info("Listening server on [::]:%s" % 8000)
    server.start()
    try:
        while True:
            time.sleep(_ONE_DAY_IN_SECONDS)  # one day in seconds
    except KeyboardInterrupt:
        logger.info("shutdown server")
        server.stop(0)