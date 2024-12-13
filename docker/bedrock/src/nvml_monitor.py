import torch
from pynvml import *
import psutil

class GPUMonitor:
    def __init__(self):
        self.has_gpu = torch.cuda.is_available()
        if self.has_gpu:
            nvmlInit()
            self.handle = nvmlDeviceGetHandleByIndex(0)

    def get_gpu_info(self):
        if not self.has_gpu:
            return {'gpu_available': False}

        try:
            info = nvmlDeviceGetMemoryInfo(self.handle)
            temp = nvmlDeviceGetTemperature(self.handle, NVML_TEMPERATURE_GPU)
            util = nvmlDeviceGetUtilizationRates(self.handle)

            return {
                'gpu_available': True,
                'device_name': torch.cuda.get_device_name(0),
                'memory': {
                    'total': f"{info.total/1e9:.2f}GB",
                    'used': f"{info.used/1e9:.2f}GB",
                    'free': f"{info.free/1e9:.2f}GB"
                },
                'temperature': f"{temp}°C",
                'utilization': {
                    'gpu': f"{util.gpu}%",
                    'memory': f"{util.memory}%"
                },
                'system': {
                    'cpu_percent': psutil.cpu_percent(),
                    'memory_percent': psutil.virtual_memory().percent
                }
            }
        except Exception as e:
            return {
                'gpu_available': True,
                'error': str(e)
            }

    def __del__(self):
        if self.has_gpu:
            try:
                nvmlShutdown()
            except:
                pass