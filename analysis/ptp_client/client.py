"""Strict PTP container transactions; transport injected, no USB auto-connect."""
from __future__ import annotations
import struct
import threading
import time
from dataclasses import dataclass

class ProtocolError(Exception):
    pass

@dataclass(frozen=True)
class Container:
    kind: int
    code: int
    tid: int
    payload: bytes

@dataclass(frozen=True)
class Result:
    tid: int
    response: int
    data: bytes | None
    parameters: tuple

def pack(kind, code, tid, payload=b''):
    return struct.pack('<IHHI', 12 + len(payload), kind, code, tid) + payload

class Client:
    # Session establishment is explicit. Unverified commands stay blocked.
    READ_OPS = {0x1001, 0x9104, 0x9107, 0x9108, 0x940A, 0x9414, 0x9421, 0x9921}
    SESSION_OPS = {0x1002, 0x1003, 0x9102, 0x9103}

    def __init__(self, transport, *, allow_writes=False, timeout=15, max_length=32<<20):
        self.transport = transport
        self.allow_writes = allow_writes
        self.timeout = timeout
        self.max_length = max_length
        self.buffer = bytearray()
        self.tid = 0
        self.failed = False
        self.lock = threading.Lock()
        self.events = []
        self.audit = []

    def _receive(self, deadline):
        while True:
            if len(self.buffer) >= 4:
                length = struct.unpack_from('<I', self.buffer)[0]
                if not 12 <= length <= self.max_length:
                    raise ProtocolError('invalid container length')
                if len(self.buffer) >= length:
                    raw = bytes(self.buffer[:length])
                    del self.buffer[:length]
                    _, kind, code, tid = struct.unpack_from('<IHHI', raw)
                    return Container(kind, code, tid, raw[12:])
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError('transaction deadline expired')
            chunk = self.transport.read(remaining)
            if not chunk:
                raise ProtocolError('truncated container or closed transport')
            self.buffer.extend(chunk)
            if len(self.buffer) > self.max_length * 2:
                raise ProtocolError('receive buffer limit exceeded')

    def transact(self, code, params=(), data=None):
        return self._transact(code, params, data)

    def read_lut(self, index):
        """Lab private 17-byte request; returns unmodified DATA payload."""
        if isinstance(index, bool) or not isinstance(index, int) or not 0 <= index <= 40:
            raise ValueError('ordinary LUT index must be 0..40')
        return self._transact(0x9921, _command_payload=struct.pack('<IB', 0x53000012, index))

    def _transact(self, code, params=(), data=None, *, _command_payload=None):
        params = tuple(params)
        if len(params) > 5 or any(not isinstance(x, int) or not 0 <= x <= 0xffffffff for x in params):
            raise ValueError('PTP parameters must be up to five u32 values')
        if not self.allow_writes and (data is not None or code not in self.READ_OPS | self.SESSION_OPS):
            raise PermissionError('write/control operation disabled')
        if data is not None and len(data)+12 > self.max_length:
            raise ValueError('outgoing data too large')
        with self.lock:
            if self.failed:
                raise ProtocolError('previous transaction failed; reopen connection')
            if self.buffer:
                self.failed = True
                raise ProtocolError('unexpected residual container before request')
            self.tid += 1
            tid = self.tid
            if tid >= 0xffffffff:
                raise ProtocolError('transaction ID exhausted; reopen session')
            self.audit.append({'tid': tid, 'opcode': code, 'status': 'started'})
            deadline = time.monotonic() + self.timeout
            try:
                self.transport.write(pack(1, code, tid, (_command_payload if _command_payload is not None else struct.pack('<'+'I'*len(params), *params))), max(0, deadline-time.monotonic()))
                if data is not None:
                    self.transport.write(pack(2, code, tid, bytes(data)), max(0, deadline-time.monotonic()))
                received = None
                for _ in range(64):
                    c = self._receive(deadline)
                    if c.kind == 4:
                        self.events.append(c)
                        continue
                    if c.tid != tid:
                        raise ProtocolError('transaction ID mismatch')
                    if c.kind == 2:
                        if c.code != code or received is not None:
                            raise ProtocolError('wrong data opcode or duplicate data phase')
                        received = c.payload
                    elif c.kind == 3:
                        if len(c.payload)%4 or len(c.payload)>20:
                            raise ProtocolError('invalid response parameters')
                        self.audit[-1].update(status='response', response=c.code)
                        if c.code != 0x2001:
                            raise ProtocolError(f'device response 0x{c.code:04x}')
                        return Result(tid, c.code, received, struct.unpack('<'+'I'*(len(c.payload)//4), c.payload))
                    else:
                        raise ProtocolError('unexpected container type')
                raise ProtocolError('too many containers without final response')
            except Exception as exc:
                self.failed = True
                self.audit[-1].update(status='failed', error=str(exc))
                raise
