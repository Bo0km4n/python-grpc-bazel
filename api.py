import os
import sys
from proto.service_pb2 import Empty
from proto.service_pb2_grpc import HealthServicer
import grpc
from logzero import logger as log

class Health(HealthServicer):
    def Heartbeat(self, request, context):
        log.debug("heart beat")
        context.set_code(grpc.StatusCode.OK)
        return Empty()
