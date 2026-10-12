import socket, unittest
def blocked(*args, **kwargs):
    raise AssertionError("Network access forbidden by offline review")
socket.create_connection = blocked
socket.socket.connect = blocked
socket.socket.connect_ex = blocked
import test_lumix_hidden_format
r = unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromModule(test_lumix_hidden_format))
raise SystemExit(0 if r.wasSuccessful() else 1)
