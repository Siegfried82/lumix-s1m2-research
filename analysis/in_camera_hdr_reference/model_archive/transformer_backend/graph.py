"""Execute recovered data-only Transformer graphs using native PyTorch operators."""
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
for directory in ('mac_runtime', 'transformer_runtime'):
    sys.path.insert(0, str(ROOT / directory))
import collections
import hashlib
import json
import operator
import numpy as np
import torch

BASE = Path(__file__).resolve().parent
ASSETS = BASE / 'assets' if (BASE / 'assets').exists() else ROOT / 'carchive/jsr_backend/wgpu/assets_v15_2'
INVENTORY = BASE / 'graph_inventory.json' if (BASE / 'graph_inventory.json').exists() else ROOT / 'transformer_graph_inventory.json'
ALLOW = set(json.loads(INVENTORY.read_text())['operator_counts'])
DTYPES = {'torch.float32': torch.float32, 'torch.int64': torch.int64, 'torch.bool': torch.bool}

def refs(value):
    if isinstance(value, dict):
        if set(value) == {'ref'}:
            yield value['ref']
        else:
            for item in value.values(): yield from refs(item)
    elif isinstance(value, (list, tuple)):
        for item in value: yield from refs(item)

class Transformer:
    def __init__(self, grid=32, device='cpu'):
        self.device = torch.device(device)
        manifest = json.loads((ASSETS / 'MANIFEST.json').read_text())
        for suffix in ('json', 'npz'):
            name = f'backend_{grid}.{suffix}'
            path = ASSETS / name
            if suffix == 'npz' and not path.exists(): path = ASSETS / 'backend_shared.npz'
            if hashlib.sha256(path.read_bytes()).hexdigest() != manifest['files'][name]:
                raise ValueError(f'Asset hash mismatch: {path.name}')
        self.graph = json.loads((ASSETS / f'backend_{grid}.json').read_text())
        weight_path = ASSETS / f'backend_{grid}.npz'
        if not weight_path.exists(): weight_path = ASSETS / 'backend_shared.npz'
        with np.load(weight_path, allow_pickle=False) as archive:
            self.weights = {k: torch.from_numpy(archive[k].copy()).to(self.device) for k in archive.files}
        self.inputs = [n for n in self.graph if n['op'] == 'placeholder']
        self.operations = {}
        for node in self.graph:
            if node['op'] == 'call_function':
                target = node['target']
                if target not in ALLOW: raise ValueError(f'Unsupported operator: {target}')
                if target == '<built-in function getitem>': fn = operator.getitem
                else:
                    namespace, name, overload = target.split('.')
                    if namespace != 'aten': raise ValueError(target)
                    fn = getattr(getattr(torch.ops.aten, name), overload)
                self.operations[node['name']] = fn
        self.uses = collections.Counter(r for n in self.graph for r in refs([n['args'], n['kwargs']]))

    @torch.inference_mode()
    def __call__(self, *inputs):
        if len(inputs) != len(self.inputs): raise ValueError('Expected five input tensors')
        values = {}
        for node, value in zip(self.inputs, inputs):
            value = value.to(device=self.device, dtype=DTYPES[node['meta']['dtype']])
            if list(value.shape) != node['meta']['shape']: raise ValueError(f"Wrong shape: {node['name']}")
            values[node['name']] = value
        uses = self.uses.copy()
        def resolve(value):
            if isinstance(value, dict):
                if set(value) == {'ref'}: return values[value['ref']]
                return {k: resolve(v) for k, v in value.items()}
            if isinstance(value, list): return [resolve(v) for v in value]
            if isinstance(value, str):
                if value in DTYPES: return DTYPES[value]
                if value == 'torch.strided': return torch.strided
            return value
        for node in self.graph:
            kind = node['op']
            if kind == 'placeholder': continue
            if kind == 'get_attr': result = self.weights[node['target']]
            else:
                args, kwargs = resolve(node['args']), resolve(node['kwargs'])
                if kind == 'output': return args[0]
                if kind != 'call_function': raise ValueError(kind)
                if 'device' in kwargs: kwargs['device'] = self.device
                try: result = self.operations[node['name']](*args, **kwargs)
                except Exception as error: raise RuntimeError(f"Node {node['name']}: {node['target']}") from error
            values[node['name']] = result
            for ref in refs([node['args'], node['kwargs']]):
                uses[ref] -= 1
                if not uses[ref]: del values[ref]
        raise ValueError('Missing output')
