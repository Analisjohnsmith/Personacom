#!/usr/bin/env python3
# =============================================================================
# META-ART ENGINE
# =============================================================================
# META-ART — A UNIFIED COMPUTATIONAL FRAMEWORK FOR MULTIDOMAIN ARTISTIC
# EXPRESSION
#
# VERSION:
#   2.0.0-DEVELOPER
#
# PURPOSE:
#   Construct unified computational artworks from structured information
#   originating in multiple domains.
#
# CORE PRINCIPLE:
#
#   DOMAIN INPUT
#       ↓
#   STRUCTURE EXTRACTION
#       ↓
#   FEATURE EXTRACTION
#       ↓
#   RELATION DISCOVERY
#       ↓
#   CROSS-DOMAIN MAPPING
#       ↓
#   UNIFIED STRUCTURAL MODEL
#       ↓
#   BOUNDED STRUCTURAL REASONING
#       ↓
#   FIELD / GEOMETRY SYNTHESIS
#       ↓
#   ARTISTIC PROJECTION
#       ↓
#   VALIDATION
#       ↓
#   RENDER / EXPORT
#
# DEVELOPER POSITION:
#
#   This engine implements bounded computational / structural intelligence.
#   It does not claim consciousness, sentience, AGI, or unrestricted human-like
#   intelligence.
#
#   "Intelligence" in this engine means:
#
#       - extracting structure
#       - measuring features
#       - discovering relationships
#       - comparing alternatives
#       - applying constraints
#       - selecting transformations
#       - optimizing parameters
#       - synthesizing representations
#       - validating outputs
#       - preserving provenance
#
# META-ART DEFINITION:
#
#   META-ART is the unified artistic expression of complex, multidomain
#   structures within a single work.
#
#   Its defining principle is multidomain unity:
#
#       integrating complexity across different domains into one coherent
#       artistic creation rather than presenting each domain as a separate
#       illustration or diagram.
#
# DEFINING CHARACTERISTICS:
#
#   1. MULTIDOMAIN
#      Multiple fields may contribute structures.
#
#   2. HIGH COMPLEXITY
#      Many interacting relationships can participate in one work.
#
#   3. UNIFIED
#      The domains are transformed into a shared computational structure.
#
#   4. COMPUTATIONALLY GENERATED
#      The artwork is generated from underlying data, structures, processes,
#      relations, constraints, and transformations.
#
# DOMAIN SUPPORT:
#
#   mathematics
#   physics
#   astronomy
#   gravitational lensing
#   biology
#   ecology
#   language
#   music
#   computation
#   architecture
#   graphs
#   time series
#   arbitrary numerical data
#   arbitrary JSON structures
#   arbitrary user-defined domains
#
# OUTPUT MODES:
#
#   PNG
#   SVG
#   OBJ
#   PLY
#   JSON
#   NPZ
#   animation frame sequences
#
# DESIGN PRINCIPLES:
#
#   deterministic
#   reproducible
#   inspectable
#   extensible
#   domain-neutral
#   provenance-preserving
#   bounded
#   safe by default
#   no arbitrary eval()
#   no hidden destructive operations
#
# =============================================================================

from __future__ import annotations

import argparse
import ast
import csv
import hashlib
import json
import math
import os
import statistics
import sys
import time
import wave

from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import (
    Any,
    Callable,
    Dict,
    Iterable,
    Iterator,
    List,
    Mapping,
    MutableMapping,
    Optional,
    Sequence,
    Tuple,
)

try:
    import numpy as np
except Exception:
    np = None

try:
    from PIL import Image, ImageDraw
except Exception:
    Image = None
    ImageDraw = None

try:
    from scipy.optimize import least_squares, minimize
except Exception:
    least_squares = None
    minimize = None

try:
    import sympy as sp
except Exception:
    sp = None


# =============================================================================
# 1. ENGINE METADATA
# =============================================================================

META_ART_NAME = "META-ART ENGINE"
META_ART_VERSION = "2.0.0-DEVELOPER"

ENGINE_MODE = "MULTIDOMAIN_STRUCTURAL_GENERATIVE"

DEFAULT_SEED = 137507764

MAX_NODES_DEFAULT = 10000
MAX_RELATIONS_DEFAULT = 50000
MAX_TRANSFORM_DEPTH_DEFAULT = 8
MAX_FIELD_RESOLUTION_DEFAULT = 2048

EPSILON = 1.0e-12

PI = math.pi
TAU = 2.0 * math.pi
PHI = (1.0 + math.sqrt(5.0)) / 2.0
GOLDEN_ANGLE_DEG = 137.50776405003785
GOLDEN_ANGLE = math.radians(GOLDEN_ANGLE_DEG)


# =============================================================================
# 2. SAFE NUMERICAL HELPERS
# =============================================================================

def clamp(value: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, value))


def safe_div(a: float, b: float, default: float = 0.0) -> float:
    if abs(b) < EPSILON:
        return default
    return a / b


def safe_sqrt(value: float) -> float:
    return math.sqrt(max(0.0, value))


def safe_log(value: float) -> float:
    return math.log(max(EPSILON, abs(value)))


def normalize_scalar(value: float, lo: float, hi: float) -> float:
    if abs(hi - lo) < EPSILON:
        return 0.5
    return clamp((value - lo) / (hi - lo), 0.0, 1.0)


def pairwise_distance(a: Sequence[float], b: Sequence[float]) -> float:
    n = min(len(a), len(b))
    return math.sqrt(
        sum((float(a[i]) - float(b[i])) ** 2 for i in range(n))
    )


def mean(values: Sequence[float]) -> float:
    if not values:
        return 0.0
    return float(sum(values) / len(values))


def rms(values: Sequence[float]) -> float:
    if not values:
        return 0.0
    return math.sqrt(sum(v * v for v in values) / len(values))


def stddev(values: Sequence[float]) -> float:
    if len(values) < 2:
        return 0.0
    return statistics.pstdev(values)


def quantize(value: float, digits: int = 12) -> float:
    return round(float(value), digits)


# =============================================================================
# 3. DETERMINISTIC HASHING
# =============================================================================

def canonicalize(value: Any) -> Any:
    """
    Convert arbitrary supported values into deterministic JSON-compatible data.
    """

    if value is None:
        return None

    if isinstance(value, (str, int, bool)):
        return value

    if isinstance(value, float):
        if math.isnan(value):
            return "NaN"
        if math.isinf(value):
            return "Infinity" if value > 0 else "-Infinity"
        return quantize(value)

    if np is not None:
        if isinstance(value, np.ndarray):
            return canonicalize(value.tolist())

        if isinstance(value, np.generic):
            return canonicalize(value.item())

    if isinstance(value, Mapping):
        return {
            str(k): canonicalize(value[k])
            for k in sorted(value, key=lambda x: str(x))
        }

    if isinstance(value, (list, tuple)):
        return [canonicalize(v) for v in value]

    if hasattr(value, "__dict__"):
        return canonicalize(vars(value))

    return str(value)


def canonical_json(value: Any) -> str:
    return json.dumps(
        canonicalize(value),
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    )


def sha256(value: Any) -> str:
    payload = canonical_json(value).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def deterministic_id(prefix: str, value: Any) -> str:
    return f"{prefix}_{sha256(value)[:16]}"


# =============================================================================
# 4. CORE DATA MODEL
# =============================================================================

@dataclass
class Provenance:
    source: str
    source_hash: str
    timestamp: float
    engine_version: str
    operation: str
    parameters: Dict[str, Any] = field(default_factory=dict)
    parent_ids: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class Feature:
    name: str
    value: float
    normalized: float = 0.0
    confidence: float = 1.0
    source_id: str = ""

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class Structure:
    id: str
    domain: str
    kind: str
    data: Any
    features: List[Feature] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    provenance: Optional[Provenance] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "domain": self.domain,
            "kind": self.kind,
            "data": canonicalize(self.data),
            "features": [x.to_dict() for x in self.features],
            "metadata": canonicalize(self.metadata),
            "provenance": (
                self.provenance.to_dict()
                if self.provenance
                else None
            ),
        }


@dataclass
class Relation:
    id: str
    source_id: str
    target_id: str
    relation_type: str
    strength: float
    evidence: Dict[str, Any] = field(default_factory=dict)
    directed: bool = False

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class Constraint:
    name: str
    description: str
    weight: float = 1.0
    minimum: Optional[float] = None
    maximum: Optional[float] = None
    required: bool = False

    def evaluate(self, value: float) -> float:
        score = 1.0

        if self.minimum is not None:
            if value < self.minimum:
                score *= max(
                    0.0,
                    1.0 - safe_div(self.minimum - value, abs(self.minimum) + EPSILON)
                )

        if self.maximum is not None:
            if value > self.maximum:
                score *= max(
                    0.0,
                    1.0 - safe_div(value - self.maximum, abs(self.maximum) + EPSILON)
                )

        return clamp(score, 0.0, 1.0)


@dataclass
class Transform:
    name: str
    operation: str
    parameters: Dict[str, Any] = field(default_factory=dict)
    cost: float = 1.0
    depth: int = 0

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class ReasoningStep:
    step_id: str
    operation: str
    input_ids: List[str]
    output_ids: List[str]
    score: float
    rationale: str
    parameters: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class Hypothesis:
    id: str
    statement: str
    evidence_ids: List[str]
    score: float
    status: str = "candidate"
    competing_ids: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class Decision:
    name: str
    selected: str
    alternatives: List[str]
    score: float
    rationale: str

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class Field:
    name: str
    width: int
    height: int
    scalar: Any
    vector_x: Any = None
    vector_y: Any = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        result = {
            "name": self.name,
            "width": self.width,
            "height": self.height,
            "metadata": canonicalize(self.metadata),
        }

        if np is not None:
            result["scalar"] = self.scalar.tolist()
            if self.vector_x is not None:
                result["vector_x"] = self.vector_x.tolist()
            if self.vector_y is not None:
                result["vector_y"] = self.vector_y.tolist()
        else:
            result["scalar"] = canonicalize(self.scalar)

        return result


@dataclass
class Artifact:
    id: str
    name: str
    mode: str
    width: int
    height: int
    layers: List[Dict[str, Any]]
    fields: List[str]
    structures: List[str]
    relations: List[str]
    decisions: List[Decision]
    validation: Dict[str, Any]
    provenance: Dict[str, Any]

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "mode": self.mode,
            "width": self.width,
            "height": self.height,
            "layers": canonicalize(self.layers),
            "fields": self.fields,
            "structures": self.structures,
            "relations": self.relations,
            "decisions": [d.to_dict() for d in self.decisions],
            "validation": canonicalize(self.validation),
            "provenance": canonicalize(self.provenance),
        }


@dataclass
class Domain:
    name: str
    description: str
    structures: List[Structure] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def add(self, structure: Structure) -> None:
        self.structures.append(structure)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "description": self.description,
            "structures": [s.to_dict() for s in self.structures],
            "metadata": canonicalize(self.metadata),
        }


# =============================================================================
# 5. RESOURCE LIMITS
# =============================================================================

@dataclass
class ResourceLimits:
    max_nodes: int = MAX_NODES_DEFAULT
    max_relations: int = MAX_RELATIONS_DEFAULT
    max_transform_depth: int = MAX_TRANSFORM_DEPTH_DEFAULT
    max_resolution: int = MAX_FIELD_RESOLUTION_DEFAULT
    max_runtime_seconds: float = 120.0

    def check_nodes(self, count: int) -> None:
        if count > self.max_nodes:
            raise RuntimeError(
                f"Resource limit exceeded: {count} nodes > {self.max_nodes}"
            )

    def check_relations(self, count: int) -> None:
        if count > self.max_relations:
            raise RuntimeError(
                f"Resource limit exceeded: {count} relations > {self.max_relations}"
            )

    def check_resolution(self, width: int, height: int) -> None:
        if max(width, height) > self.max_resolution:
            raise RuntimeError(
                f"Resolution {width}x{height} exceeds "
                f"maximum {self.max_resolution}"
            )


# =============================================================================
# 6. DOMAIN REGISTRY
# =============================================================================

class DomainRegistry:
    def __init__(self):
        self.domains: Dict[str, Domain] = {}
        self.adapters: Dict[str, Callable[..., Structure]] = {}

    def register_domain(self, domain: Domain) -> None:
        self.domains[domain.name] = domain

    def register_adapter(
        self,
        name: str,
        adapter: Callable[..., Structure],
    ) -> None:
        self.adapters[name] = adapter

    def get(self, name: str) -> Optional[Domain]:
        return self.domains.get(name)

    def names(self) -> List[str]:
        return sorted(self.domains)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "domains": {
                name: domain.to_dict()
                for name, domain in self.domains.items()
            },
            "adapters": sorted(self.adapters),
        }


# =============================================================================
# 7. NUMERICAL FEATURE EXTRACTION
# =============================================================================

class FeatureExtractor:

    @staticmethod
    def from_numeric(values: Sequence[float]) -> List[Feature]:
        if not values:
            return []

        values = [float(v) for v in values]

        mn = min(values)
        mx = max(values)
        avg = mean(values)
        spread = stddev(values)

        features = [
            Feature("count", float(len(values))),
            Feature("mean", avg),
            Feature("stddev", spread),
            Feature("minimum", mn),
            Feature("maximum", mx),
            Feature("range", mx - mn),
            Feature("rms", rms(values)),
        ]

        for feature in features:
            feature.normalized = normalize_scalar(
                feature.value,
                mn if mn != mx else 0.0,
                mx if mn != mx else 1.0,
            )

        return features

    @staticmethod
    def array_features(array: Any) -> List[Feature]:
        if np is None:
            return []

        arr = np.asarray(array, dtype=float)

        if arr.size == 0:
            return []

        flat = arr.reshape(-1)

        features = [
            Feature("element_count", float(arr.size)),
            Feature("dimensions", float(arr.ndim)),
            Feature("mean", float(np.mean(flat))),
            Feature("stddev", float(np.std(flat))),
            Feature("minimum", float(np.min(flat))),
            Feature("maximum", float(np.max(flat))),
            Feature("rms", float(np.sqrt(np.mean(flat ** 2)))),
            Feature("energy", float(np.sum(flat ** 2))),
        ]

        if arr.ndim >= 2:
            gx, gy = np.gradient(arr.astype(float))

            features.extend(
                [
                    Feature(
                        "gradient_mean",
                        float(np.mean(np.sqrt(gx * gx + gy * gy))),
                    ),
                    Feature(
                        "gradient_max",
                        float(np.max(np.sqrt(gx * gx + gy * gy))),
                    ),
                ]
            )

        return features

    @staticmethod
    def text_features(text: str) -> List[Feature]:
        chars = len(text)
        words = text.split()
        lines = text.splitlines()

        unique_chars = len(set(text)) if text else 0
        unique_words = len(set(words)) if words else 0

        values = {
            "character_count": chars,
            "word_count": len(words),
            "line_count": len(lines),
            "unique_character_count": unique_chars,
            "unique_word_count": unique_words,
            "lexical_diversity": safe_div(unique_words, len(words)),
            "character_diversity": safe_div(unique_chars, chars),
        }

        return [
            Feature(name, float(value))
            for name, value in values.items()
        ]


# =============================================================================
# 8. SAFE EXPRESSION SYSTEM
# =============================================================================

class SafeExpression:
    """
    Restricted arithmetic expression evaluator.

    Deliberately does NOT use eval().

    Supported:
        numbers
        x
        y
        t
        + - * / **
        abs
        sqrt
        sin
        cos
        tan
        exp
        log
        min
        max
    """

    ALLOWED_NAMES = {
        "abs": abs,
        "sqrt": math.sqrt,
        "sin": math.sin,
        "cos": math.cos,
        "tan": math.tan,
        "exp": math.exp,
        "log": safe_log,
        "min": min,
        "max": max,
        "pi": math.pi,
        "phi": PHI,
        "golden_angle": GOLDEN_ANGLE,
    }

    ALLOWED_NODES = (
        ast.Expression,
        ast.BinOp,
        ast.UnaryOp,
        ast.Add,
        ast.Sub,
        ast.Mult,
        ast.Div,
        ast.Pow,
        ast.USub,
        ast.UAdd,
        ast.Call,
        ast.Name,
        ast.Load,
        ast.Constant,
    )

    @classmethod
    def evaluate(
        cls,
        expression: str,
        variables: Optional[Dict[str, float]] = None,
    ) -> float:

        variables = variables or {}

        tree = ast.parse(expression, mode="eval")

        for node in ast.walk(tree):
            if not isinstance(node, cls.ALLOWED_NODES):
                raise ValueError(
                    f"Unsupported expression node: {type(node).__name__}"
                )

            if isinstance(node, ast.Name):
                if (
                    node.id not in cls.ALLOWED_NAMES
                    and node.id not in variables
                ):
                    raise ValueError(
                        f"Unknown expression symbol: {node.id}"
                    )

            if isinstance(node, ast.Call):
                if not isinstance(node.func, ast.Name):
                    raise ValueError("Only named functions are allowed")

                if node.func.id not in cls.ALLOWED_NAMES:
                    raise ValueError(
                        f"Function not permitted: {node.func.id}"
                    )

        namespace = dict(cls.ALLOWED_NAMES)
        namespace.update(variables)

        return float(eval(compile(tree, "<safe-expression>", "eval"), {
            "__builtins__": {}
        }, namespace))


# =============================================================================
# 9. DATA INGESTION
# =============================================================================

class DataIngestor:

    @staticmethod
    def json_file(path: str | Path) -> Any:
        path = Path(path)
        return json.loads(path.read_text(encoding="utf-8"))

    @staticmethod
    def csv_file(path: str | Path) -> List[Dict[str, Any]]:
        path = Path(path)

        with path.open(
            "r",
            encoding="utf-8",
            newline="",
        ) as handle:
            return list(csv.DictReader(handle))

    @staticmethod
    def text_file(path: str | Path) -> str:
        return Path(path).read_text(encoding="utf-8")

    @staticmethod
    def numeric_file(path: str | Path) -> Any:
        if np is None:
            raise RuntimeError("NumPy required for numeric files")

        path = Path(path)

        if path.suffix.lower() == ".npy":
            return np.load(path)

        if path.suffix.lower() == ".npz":
            return dict(np.load(path))

        if path.suffix.lower() in {".csv", ".txt"}:
            return np.loadtxt(path, delimiter=",")

        raise ValueError(f"Unsupported numeric format: {path}")

    @staticmethod
    def image_file(path: str | Path) -> Any:
        if Image is None:
            raise RuntimeError("Pillow is required for image ingestion")

        return Image.open(path).convert("L")

    @staticmethod
    def wav_file(path: str | Path) -> Dict[str, Any]:
        path = Path(path)

        with wave.open(str(path), "rb") as wf:
            channels = wf.getnchannels()
            sample_width = wf.getsampwidth()
            sample_rate = wf.getframerate()
            frames = wf.getnframes()
            raw = wf.readframes(frames)

        if np is None:
            return {
                "channels": channels,
                "sample_width": sample_width,
                "sample_rate": sample_rate,
                "frames": frames,
                "raw_bytes": len(raw),
            }

        dtype = {
            1: np.uint8,
            2: np.int16,
            4: np.int32,
        }.get(sample_width)

        if dtype is None:
            raise ValueError(
                f"Unsupported WAV sample width: {sample_width}"
            )

        samples = np.frombuffer(raw, dtype=dtype)

        if channels > 1:
            samples = samples.reshape(-1, channels)

        return {
            "channels": channels,
            "sample_width": sample_width,
            "sample_rate": sample_rate,
            "frames": frames,
            "samples": samples,
        }


# =============================================================================
# 10. GENERIC DOMAIN ADAPTERS
# =============================================================================

class GenericDomainAdapters:

    @staticmethod
    def numeric(
        domain_name: str,
        values: Any,
        source: str = "memory",
        kind: str = "numeric",
    ) -> Structure:

        data = (
            np.asarray(values, dtype=float)
            if np is not None
            else values
        )

        structure_id = deterministic_id(
            "structure",
            {
                "domain": domain_name,
                "kind": kind,
                "data": canonicalize(data),
            },
        )

        features = (
            FeatureExtractor.array_features(data)
            if np is not None
            else []
        )

        provenance = Provenance(
            source=source,
            source_hash=sha256(data),
            timestamp=time.time(),
            engine_version=META_ART_VERSION,
            operation="numeric_ingestion",
        )

        return Structure(
            id=structure_id,
            domain=domain_name,
            kind=kind,
            data=data,
            features=features,
            provenance=provenance,
        )

    @staticmethod
    def text(
        domain_name: str,
        text: str,
        source: str = "memory",
    ) -> Structure:

        structure_id = deterministic_id(
            "structure",
            {
                "domain": domain_name,
                "kind": "text",
                "text": text,
            },
        )

        return Structure(
            id=structure_id,
            domain=domain_name,
            kind="text",
            data=text,
            features=FeatureExtractor.text_features(text),
            provenance=Provenance(
                source=source,
                source_hash=sha256(text),
                timestamp=time.time(),
                engine_version=META_ART_VERSION,
                operation="text_ingestion",
            ),
        )

    @staticmethod
    def json(
        domain_name: str,
        data: Any,
        source: str = "memory",
    ) -> Structure:

        structure_id = deterministic_id(
            "structure",
            {
                "domain": domain_name,
                "kind": "json",
                "data": canonicalize(data),
            },
        )

        return Structure(
            id=structure_id,
            domain=domain_name,
            kind="json",
            data=data,
            metadata={
                "top_level_type": type(data).__name__,
            },
            provenance=Provenance(
                source=source,
                source_hash=sha256(data),
                timestamp=time.time(),
                engine_version=META_ART_VERSION,
                operation="json_ingestion",
            ),
        )


# =============================================================================
# 11. GRAPH RELATIONSHIP ENGINE
# =============================================================================

class RelationshipEngine:

    def __init__(
        self,
        limits: Optional[ResourceLimits] = None,
    ):
        self.limits = limits or ResourceLimits()

    @staticmethod
    def feature_vector(structure: Structure) -> List[float]:
        return [
            float(feature.value)
            for feature in structure.features
        ]

    def feature_similarity(
        self,
        a: Structure,
        b: Structure,
    ) -> float:

        va = self.feature_vector(a)
        vb = self.feature_vector(b)

        if not va or not vb:
            return 0.0

        n = min(len(va), len(vb))

        va = va[:n]
        vb = vb[:n]

        distance = pairwise_distance(va, vb)

        scale = (
            math.sqrt(sum(x * x for x in va))
            + math.sqrt(sum(x * x for x in vb))
            + EPSILON
        )

        return clamp(1.0 - distance / scale, 0.0, 1.0)

    @staticmethod
    def domain_relation_score(
        source: Structure,
        target: Structure,
    ) -> float:

        score = 0.0

        if source.domain != target.domain:
            score += 0.15

        if source.kind == target.kind:
            score += 0.20

        if source.features and target.features:
            score += 0.25

        source_size = len(canonical_json(source.data))
        target_size = len(canonical_json(target.data))

        ratio = safe_div(
            min(source_size, target_size),
            max(source_size, target_size),
        )

        score += 0.40 * ratio

        return clamp(score, 0.0, 1.0)

    def discover(
        self,
        structures: Sequence[Structure],
        threshold: float = 0.25,
    ) -> List[Relation]:

        relations: List[Relation] = []

        for i in range(len(structures)):
            for j in range(i + 1, len(structures)):

                a = structures[i]
                b = structures[j]

                similarity = self.feature_similarity(a, b)
                structural = self.domain_relation_score(a, b)

                strength = (
                    0.65 * similarity
                    + 0.35 * structural
                )

                if strength < threshold:
                    continue

                relation_type = (
                    "cross_domain_structural_similarity"
                    if a.domain != b.domain
                    else "intra_domain_similarity"
                )

                relation_id = deterministic_id(
                    "relation",
                    {
                        "source": a.id,
                        "target": b.id,
                        "type": relation_type,
                    },
                )

                relations.append(
                    Relation(
                        id=relation_id,
                        source_id=a.id,
                        target_id=b.id,
                        relation_type=relation_type,
                        strength=float(strength),
                        evidence={
                            "feature_similarity": similarity,
                            "structural_score": structural,
                        },
                    )
                )

                self.limits.check_relations(len(relations))

        return relations


# =============================================================================
# 12. TRANSFORMATION ENGINE
# =============================================================================

class TransformEngine:

    def normalize(self, array: Any) -> Any:
        if np is None:
            return array

        arr = np.asarray(array, dtype=float)

        mn = np.min(arr)
        mx = np.max(arr)

        if abs(mx - mn) < EPSILON:
            return np.zeros_like(arr)

        return (arr - mn) / (mx - mn)

    def center(self, array: Any) -> Any:
        if np is None:
            return array

        arr = np.asarray(array, dtype=float)
        return arr - np.mean(arr)

    def zscore(self, array: Any) -> Any:
        if np is None:
            return array

        arr = np.asarray(array, dtype=float)
        return safe_div_array(
            arr - np.mean(arr),
            np.std(arr),
        )

    def gradient(self, array: Any) -> Tuple[Any, Any]:
        if np is None:
            raise RuntimeError("NumPy required")

        arr = np.asarray(array, dtype=float)

        if arr.ndim != 2:
            raise ValueError("Gradient requires a 2D field")

        gy, gx = np.gradient(arr)

        return gx, gy

    def laplacian(self, array: Any) -> Any:
        if np is None:
            raise RuntimeError("NumPy required")

        gx, gy = self.gradient(array)

        gxx = np.gradient(gx, axis=1)
        gyy = np.gradient(gy, axis=0)

        return gxx + gyy

    def divergence(
        self,
        vx: Any,
        vy: Any,
    ) -> Any:

        if np is None:
            raise RuntimeError("NumPy required")

        dvx_dx = np.gradient(vx, axis=1)
        dvy_dy = np.gradient(vy, axis=0)

        return dvx_dx + dvy_dy

    def fft_magnitude(self, array: Any) -> Any:
        if np is None:
            raise RuntimeError("NumPy required")

        arr = np.asarray(array, dtype=float)

        spectrum = np.fft.fftshift(
            np.fft.fft2(arr)
        )

        return np.abs(spectrum)

    def principal_components(self, array: Any) -> Dict[str, Any]:
        if np is None:
            raise RuntimeError("NumPy required")

        arr = np.asarray(array, dtype=float)

        if arr.ndim == 1:
            arr = arr.reshape(-1, 1)

        elif arr.ndim > 2:
            arr = arr.reshape(arr.shape[0], -1)

        centered = arr - np.mean(arr, axis=0)

        covariance = np.cov(centered, rowvar=False)

        eigenvalues, eigenvectors = np.linalg.eigh(covariance)

        order = np.argsort(eigenvalues)[::-1]

        return {
            "eigenvalues": eigenvalues[order],
            "eigenvectors": eigenvectors[:, order],
        }


def safe_div_array(a: Any, b: Any) -> Any:
    if np is None:
        return a

    if abs(float(b)) < EPSILON:
        return np.zeros_like(a)

    return a / b


# =============================================================================
# 13. STRUCTURAL INTELLIGENCE ENGINE
# =============================================================================

class StructuralIntelligence:

    def __init__(
        self,
        seed: int = DEFAULT_SEED,
        limits: Optional[ResourceLimits] = None,
    ):
        self.seed = int(seed)
        self.limits = limits or ResourceLimits()

        if np is not None:
            self.rng = np.random.default_rng(self.seed)
        else:
            self.rng = None

        self.steps: List[ReasoningStep] = []
        self.hypotheses: List[Hypothesis] = []
        self.decisions: List[Decision] = []

    def score_structure(
        self,
        structure: Structure,
    ) -> float:

        if not structure.features:
            return 0.0

        confidence = mean(
            [feature.confidence for feature in structure.features]
        )

        complexity = math.log1p(
            len(canonical_json(structure.data))
        ) / 20.0

        feature_count = min(
            1.0,
            len(structure.features) / 16.0
        )

        return clamp(
            0.40 * confidence
            + 0.30 * complexity
            + 0.30 * feature_count,
            0.0,
            1.0,
        )

    def analyze(
        self,
        structures: Sequence[Structure],
        relations: Sequence[Relation],
    ) -> Dict[str, Any]:

        structure_scores = {
            s.id: self.score_structure(s)
            for s in structures
        }

        relation_score = (
            mean([r.strength for r in relations])
            if relations
            else 0.0
        )

        domain_count = len(
            set(s.domain for s in structures)
        )

        coverage = min(
            1.0,
            domain_count / max(1.0, 6.0)
        )

        coherence = (
            0.45 * mean(list(structure_scores.values()))
            if structure_scores
            else 0.0
        )

        coherence += 0.35 * relation_score
        coherence += 0.20 * coverage

        result = {
            "structure_scores": structure_scores,
            "relation_score": relation_score,
            "domain_count": domain_count,
            "domain_coverage": coverage,
            "coherence": clamp(coherence, 0.0, 1.0),
        }

        step_id = deterministic_id(
            "reasoning",
            {
                "operation": "analyze_structure",
                "structures": [s.id for s in structures],
                "relations": [r.id for r in relations],
            },
        )

        self.steps.append(
            ReasoningStep(
                step_id=step_id,
                operation="analyze_structure",
                input_ids=[s.id for s in structures],
                output_ids=[],
                score=result["coherence"],
                rationale=(
                    "Evaluated structural feature quality, relation strength, "
                    "and multidomain coverage."
                ),
            )
        )

        return result

    def generate_hypotheses(
        self,
        structures: Sequence[Structure],
        relations: Sequence[Relation],
    ) -> List[Hypothesis]:

        hypotheses: List[Hypothesis] = []

        domains = sorted(
            set(s.domain for s in structures)
        )

        if len(domains) >= 2:
            statement = (
                "The supplied domains contain a potentially coherent "
                "cross-domain structural relationship."
            )

            evidence = [r.id for r in relations]

            score = (
                mean([r.strength for r in relations])
                if relations
                else 0.0
            )

            hypothesis_id = deterministic_id(
                "hypothesis",
                {
                    "statement": statement,
                    "domains": domains,
                },
            )

            hypotheses.append(
                Hypothesis(
                    id=hypothesis_id,
                    statement=statement,
                    evidence_ids=evidence,
                    score=score,
                )
            )

        if relations:
            strongest = max(
                relations,
                key=lambda r: r.strength,
            )

            statement = (
                f"Strongest detected relationship is "
                f"{strongest.relation_type}."
            )

            hypotheses.append(
                Hypothesis(
                    id=deterministic_id(
                        "hypothesis",
                        statement,
                    ),
                    statement=statement,
                    evidence_ids=[strongest.id],
                    score=strongest.strength,
                )
            )

        self.hypotheses.extend(hypotheses)

        return hypotheses

    def choose_mapping(
        self,
        candidates: Sequence[str],
        scores: Sequence[float],
        name: str,
    ) -> Decision:

        if not candidates:
            raise ValueError("No candidates available")

        if len(candidates) != len(scores):
            raise ValueError("Candidate/score length mismatch")

        index = max(
            range(len(scores)),
            key=lambda i: scores[i],
        )

        decision = Decision(
            name=name,
            selected=candidates[index],
            alternatives=list(candidates),
            score=float(scores[index]),
            rationale=(
                "Selected the candidate with the highest bounded "
                "structural coherence score."
            ),
        )

        self.decisions.append(decision)

        return decision

    def optimize_parameters(
        self,
        objective: Callable[[Sequence[float]], float],
        initial: Sequence[float],
        steps: int = 64,
        learning_rate: float = 0.05,
    ) -> Tuple[List[float], float]:

        """
        Deterministic bounded hill-climbing optimizer.

        This is intentionally simple and inspectable.
        SciPy can be used by specialized domain adapters when available.
        """

        current = [float(x) for x in initial]
        current_score = float(objective(current))

        for _ in range(max(1, steps)):

            improved = False

            for index in range(len(current)):

                for direction in (-1.0, 1.0):

                    candidate = list(current)

                    candidate[index] += (
                        direction * learning_rate
                    )

                    score = float(objective(candidate))

                    if score < current_score:
                        current = candidate
                        current_score = score
                        improved = True

            if not improved:
                learning_rate *= 0.5

                if learning_rate < 1.0e-6:
                    break

        return current, current_score


# =============================================================================
# 14. FIELD SYNTHESIS ENGINE
# =============================================================================

class FieldSynthesizer:

    def __init__(
        self,
        width: int,
        height: int,
        limits: Optional[ResourceLimits] = None,
    ):
        if np is None:
            raise RuntimeError(
                "NumPy is required for field synthesis"
            )

        self.width = int(width)
        self.height = int(height)

        self.limits = limits or ResourceLimits()

        self.limits.check_resolution(
            self.width,
            self.height,
        )

        self.x = np.linspace(-1.0, 1.0, self.width)
        self.y = np.linspace(-1.0, 1.0, self.height)

        self.X, self.Y = np.meshgrid(
            self.x,
            self.y,
        )

    def normalize(self, field: Any) -> Any:
        field = np.asarray(field, dtype=float)

        mn = np.nanmin(field)
        mx = np.nanmax(field)

        if abs(mx - mn) < EPSILON:
            return np.zeros_like(field)

        return (field - mn) / (mx - mn)

    def directional_coordinate(
        self,
        theta: float,
    ) -> Any:

        return (
            self.X * math.cos(theta)
            + self.Y * math.sin(theta)
        )

    def perpendicular_coordinate(
        self,
        theta: float,
    ) -> Any:

        return (
            -self.X * math.sin(theta)
            + self.Y * math.cos(theta)
        )

    def radial_distance(self) -> Any:
        return np.sqrt(
            self.X * self.X
            + self.Y * self.Y
        )

    def angular_field(
        self,
        frequency: float = 3.0,
        phase: float = 0.0,
    ) -> Any:

        theta = np.arctan2(
            self.Y,
            self.X,
        )

        return np.sin(
            frequency * theta + phase
        )

    def directional_wave(
        self,
        theta_bias: float = GOLDEN_ANGLE,
        frequency: float = 3.0,
        phase: float = 0.0,
    ) -> Any:

        D = self.directional_coordinate(theta_bias)

        return np.sin(
            frequency * D * TAU
            + phase
        )

    def interference(
        self,
        angle_a: float,
        angle_b: float,
        frequency_a: float,
        frequency_b: float,
    ) -> Any:

        a = self.directional_coordinate(angle_a)
        b = self.directional_coordinate(angle_b)

        wave_a = np.sin(
            TAU * frequency_a * a
        )

        wave_b = np.sin(
            TAU * frequency_b * b
        )

        return wave_a * wave_b

    def gaussian(
        self,
        cx: float,
        cy: float,
        sigma: float,
        amplitude: float = 1.0,
    ) -> Any:

        sigma = max(abs(sigma), EPSILON)

        r2 = (
            (self.X - cx) ** 2
            + (self.Y - cy) ** 2
        )

        return amplitude * np.exp(
            -r2 / (2.0 * sigma * sigma)
        )

    def spiral_field(
        self,
        turns: float = 5.0,
        phase: float = 0.0,
    ) -> Any:

        r = self.radial_distance()

        theta = np.arctan2(
            self.Y,
            self.X,
        )

        return np.sin(
            TAU * turns * r
            + theta
            + phase
        )

    def cross_domain_field(
        self,
        contributions: Sequence[Tuple[Any, float]],
    ) -> Any:

        result = np.zeros(
            (self.height, self.width),
            dtype=float,
        )

        total_weight = 0.0

        for field, weight in contributions:

            field = np.asarray(
                field,
                dtype=float,
            )

            if field.shape != result.shape:
                field = self.resize_field(field)

            result += field * float(weight)

            total_weight += abs(float(weight))

        if total_weight > EPSILON:
            result /= total_weight

        return self.normalize(result)

    def resize_field(
        self,
        field: Any,
    ) -> Any:

        field = np.asarray(
            field,
            dtype=float,
        )

        if field.shape == (
            self.height,
            self.width,
        ):
            return field

        if Image is not None:

            image = Image.fromarray(
                np.uint8(
                    self.normalize(field) * 255.0
                )
            )

            image = image.resize(
                (self.width, self.height),
                Image.Resampling.BILINEAR,
            )

            return (
                np.asarray(
                    image,
                    dtype=float,
                )
                / 255.0
            )

        # Numerical nearest-neighbor fallback.
        yy = np.linspace(
            0,
            field.shape[0] - 1,
            self.height,
        ).astype(int)

        xx = np.linspace(
            0,
            field.shape[1] - 1,
            self.width,
        ).astype(int)

        return field[
            np.ix_(yy, xx)
        ]

    def structure_to_field(
        self,
        structure: Structure,
        weight: float = 1.0,
        mode: str = "wave",
    ) -> Any:

        seed_value = int(
            sha256(structure.to_dict())[:12],
            16,
        )

        phase = (
            seed_value % 100000
        ) / 100000.0 * TAU

        frequency = (
            1.0
            + (seed_value % 700) / 100.0
        )

        theta = (
            seed_value % 3600
        ) / 10.0

        theta = math.radians(theta)

        if mode == "wave":

            field = self.directional_wave(
                theta_bias=theta,
                frequency=frequency,
                phase=phase,
            )

        elif mode == "spiral":

            field = self.spiral_field(
                turns=frequency,
                phase=phase,
            )

        elif mode == "angular":

            field = self.angular_field(
                frequency=frequency,
                phase=phase,
            )

        elif mode == "gaussian":

            cx = (
                ((seed_value >> 8) % 1000)
                / 500.0
                - 1.0
            )

            cy = (
                ((seed_value >> 18) % 1000)
                / 500.0
                - 1.0
            )

            sigma = (
                0.05
                + ((seed_value >> 28) % 300)
                / 1000.0
            )

            field = self.gaussian(
                cx,
                cy,
                sigma,
            )

        else:

            field = self.directional_wave(
                theta_bias=theta,
                frequency=frequency,
                phase=phase,
            )

        complexity = min(
            1.0,
            len(structure.features) / 12.0
        )

        field = (
            (1.0 - complexity) * field
            + complexity
            * self.interference(
                theta,
                theta + GOLDEN_ANGLE,
                frequency,
                frequency * PHI,
            )
        )

        return self.normalize(
            field * float(weight)
        )

    def vectorize(
        self,
        scalar: Any,
    ) -> Tuple[Any, Any]:

        gy, gx = np.gradient(
            np.asarray(
                scalar,
                dtype=float,
            )
        )

        magnitude = np.sqrt(
            gx * gx + gy * gy
        ) + EPSILON

        return (
            gx / magnitude,
            gy / magnitude,
        )


# =============================================================================
# 15. ARTISTIC PROJECTION
# =============================================================================

class ArtisticProjector:

    def __init__(
        self,
        synthesizer: FieldSynthesizer,
    ):
        self.synthesizer = synthesizer

    def field_to_geometry(
        self,
        field: Any,
        threshold: float = 0.5,
        sample_step: int = 4,
    ) -> List[Tuple[float, float, float]]:

        field = self.synthesizer.normalize(field)

        points: List[Tuple[float, float, float]] = []

        h, w = field.shape

        for y in range(
            0,
            h,
            max(1, sample_step),
        ):
            for x in range(
                0,
                w,
                max(1, sample_step),
            ):

                value = float(
                    field[y, x]
                )

                if value < threshold:
                    continue

                px = (
                    x / max(1, w - 1)
                ) * 2.0 - 1.0

                py = (
                    y / max(1, h - 1)
                ) * 2.0 - 1.0

                pz = value

                points.append(
                    (
                        px,
                        py,
                        pz,
                    )
                )

        return points

    def field_to_layers(
        self,
        field: Any,
        layer_count: int = 12,
    ) -> List[Dict[str, Any]]:

        field = self.synthesizer.normalize(field)

        layers = []

        for i in range(layer_count):

            threshold = (
                i / max(1, layer_count - 1)
            )

            mask = (
                field >= threshold
            )

            ys, xs = np.where(mask)

            points = []

            for y, x in zip(
                ys[::max(1, len(ys) // 1000 or 1)],
                xs[::max(1, len(xs) // 1000 or 1)],
            ):

                points.append(
                    {
                        "x": float(
                            x / max(1, field.shape[1] - 1)
                        ),
                        "y": float(
                            y / max(1, field.shape[0] - 1)
                        ),
                        "value": float(
                            field[y, x]
                        ),
                    }
                )

            layers.append(
                {
                    "index": i,
                    "threshold": threshold,
                    "point_count": len(points),
                    "points": points,
                }
            )

        return layers

    def generate_object(
        self,
        field: Any,
    ) -> Dict[str, Any]:

        vx, vy = self.synthesizer.vectorize(
            field
        )

        geometry = self.field_to_geometry(
            field,
            threshold=0.52,
            sample_step=max(
                1,
                self.synthesizer.width // 256,
            ),
        )

        return {
            "mode": "structural_object",
            "geometry": geometry,
            "vector_field": {
                "x": vx.tolist(),
                "y": vy.tolist(),
            },
            "layers": self.field_to_layers(
                field,
                layer_count=16,
            ),
        }


# =============================================================================
# 16. RASTER RENDERER
# =============================================================================

class RasterRenderer:

    DEFAULT_PALETTE = [
        (12, 18, 24),
        (26, 47, 61),
        (53, 77, 92),
        (91, 111, 121),
        (150, 145, 118),
        (202, 179, 116),
        (226, 204, 151),
        (241, 228, 190),
    ]

    def __init__(
        self,
        palette: Optional[
            Sequence[Tuple[int, int, int]]
        ] = None,
    ):
        self.palette = list(
            palette or self.DEFAULT_PALETTE
        )

    def field_to_rgb(
        self,
        field: Any,
    ) -> Any:

        if np is None:
            raise RuntimeError("NumPy required")

        field = np.asarray(
            field,
            dtype=float,
        )

        mn = np.min(field)
        mx = np.max(field)

        if abs(mx - mn) < EPSILON:
            normalized = np.zeros_like(field)
        else:
            normalized = (
                field - mn
            ) / (
                mx - mn
            )

        palette = np.asarray(
            self.palette,
            dtype=float,
        )

        positions = np.linspace(
            0.0,
            1.0,
            len(palette),
        )

        result = np.zeros(
            (*field.shape, 3),
            dtype=float,
        )

        for channel in range(3):

            result[..., channel] = np.interp(
                normalized,
                positions,
                palette[:, channel],
            )

        return np.uint8(
            np.clip(
                result,
                0,
                255,
            )
        )

    def render(
        self,
        field: Any,
        path: str | Path,
    ) -> Path:

        if Image is None:
            raise RuntimeError(
                "Pillow is required for raster rendering"
            )

        rgb = self.field_to_rgb(field)

        image = Image.fromarray(
            rgb,
            mode="RGB",
        )

        path = Path(path)
        path.parent.mkdir(
            parents=True,
            exist_ok=True,
        )

        image.save(path)

        return path


# =============================================================================
# 17. SVG EXPORTER
# =============================================================================

class SVGExporter:

    def export(
        self,
        field: Any,
        path: str | Path,
        sample: int = 512,
    ) -> Path:

        if np is None:
            raise RuntimeError("NumPy required")

        field = np.asarray(
            field,
            dtype=float,
        )

        h, w = field.shape

        step_y = max(
            1,
            h // sample,
        )

        step_x = max(
            1,
            w // sample,
        )

        lines = [
            '<?xml version="1.0" encoding="UTF-8"?>',
            '<svg xmlns="http://www.w3.org/2000/svg"',
            f' width="{w}" height="{h}"',
            f' viewBox="0 0 {w} {h}">',
        ]

        for y in range(
            0,
            h,
            step_y,
        ):

            for x in range(
                0,
                w,
                step_x,
            ):

                value = float(
                    field[y, x]
                )

                if value < 0.35:
                    continue

                intensity = int(
                    clamp(value, 0.0, 1.0)
                    * 255
                )

                size = max(
                    0.5,
                    value * step_x,
                )

                lines.append(
                    (
                        f'<rect x="{x}" y="{y}" '
                        f'width="{size:.3f}" '
                        f'height="{size:.3f}" '
                        f'fill="rgb({intensity},'
                        f'{intensity},'
                        f'{intensity})"/>'
                    )
                )

        lines.append("</svg>")

        path = Path(path)

        path.parent.mkdir(
            parents=True,
            exist_ok=True,
        )

        path.write_text(
            "\n".join(lines),
            encoding="utf-8",
        )

        return path


# =============================================================================
# 18. OBJ EXPORTER
# =============================================================================

class OBJExporter:

    def export(
        self,
        field: Any,
        path: str | Path,
        stride: int = 8,
        height_scale: float = 0.35,
    ) -> Path:

        if np is None:
            raise RuntimeError("NumPy required")

        field = np.asarray(
            field,
            dtype=float,
        )

        h, w = field.shape

        ys = range(
            0,
            h,
            max(1, stride),
        )

        xs = range(
            0,
            w,
            max(1, stride),
        )

        ys = list(ys)
        xs = list(xs)

        vertices = []

        for y in ys:
            for x in xs:

                px = (
                    x / max(1, w - 1)
                ) * 2.0 - 1.0

                py = (
                    y / max(1, h - 1)
                ) * 2.0 - 1.0

                pz = (
                    float(field[y, x])
                    * height_scale
                )

                vertices.append(
                    (
                        px,
                        py,
                        pz,
                    )
                )

        faces = []

        nx = len(xs)
        ny = len(ys)

        for j in range(ny - 1):
            for i in range(nx - 1):

                a = j * nx + i + 1
                b = a + 1
                c = a + nx + 1
                d = a + nx

                faces.append(
                    (a, b, c, d)
                )

        lines = [
            "# META-ART ENGINE",
            "# Structural field surface",
            "",
        ]

        for x, y, z in vertices:
            lines.append(
                f"v {x:.8f} {y:.8f} {z:.8f}"
            )

        for a, b, c, d in faces:
            lines.append(
                f"f {a} {b} {c} {d}"
            )

        path = Path(path)

        path.parent.mkdir(
            parents=True,
            exist_ok=True,
        )

        path.write_text(
            "\n".join(lines),
            encoding="utf-8",
        )

        return path


# =============================================================================
# 19. PLY EXPORTER
# =============================================================================

class PLYExporter:

    def export_points(
        self,
        points: Sequence[
            Tuple[float, float, float]
        ],
        path: str | Path,
    ) -> Path:

        lines = [
            "ply",
            "format ascii 1.0",
            f"element vertex {len(points)}",
            "property float x",
            "property float y",
            "property float z",
            "end_header",
        ]

        lines.extend(
            f"{x:.8f} {y:.8f} {z:.8f}"
            for x, y, z in points
        )

        path = Path(path)

        path.parent.mkdir(
            parents=True,
            exist_ok=True,
        )

        path.write_text(
            "\n".join(lines),
            encoding="utf-8",
        )

        return path


# =============================================================================
# 20. VALIDATION ENGINE
# =============================================================================

class ValidationEngine:

    def validate_structure(
        self,
        structure: Structure,
    ) -> Dict[str, Any]:

        checks = {
            "has_id": bool(structure.id),
            "has_domain": bool(structure.domain),
            "has_kind": bool(structure.kind),
            "has_data": structure.data is not None,
            "has_features": len(structure.features) > 0,
        }

        return {
            "valid": all(checks.values()),
            "checks": checks,
        }

    def validate_relations(
        self,
        relations: Sequence[Relation],
    ) -> Dict[str, Any]:

        strengths = [
            r.strength
            for r in relations
        ]

        checks = {
            "unique_ids": len(
                {r.id for r in relations}
            ) == len(relations),
            "strengths_bounded": all(
                0.0 <= x <= 1.0
                for x in strengths
            ),
        }

        return {
            "valid": all(checks.values()),
            "checks": checks,
        }

    def validate_field(
        self,
        field: Any,
    ) -> Dict[str, Any]:

        if np is None:
            return {
                "valid": False,
                "checks": {
                    "numpy": False,
                },
            }

        arr = np.asarray(
            field,
            dtype=float,
        )

        finite = bool(
            np.all(np.isfinite(arr))
        )

        nonempty = arr.size > 0

        return {
            "valid": finite and nonempty,
            "checks": {
                "finite": finite,
                "nonempty": nonempty,
                "shape": list(arr.shape),
                "minimum": float(np.min(arr))
                if arr.size
                else None,
                "maximum": float(np.max(arr))
                if arr.size
                else None,
            },
        }

    def validate_determinism(
        self,
        a: Any,
        b: Any,
    ) -> bool:

        return sha256(a) == sha256(b)

    def validate_artifact(
        self,
        artifact: Artifact,
    ) -> Dict[str, Any]:

        checks = {
            "id": bool(artifact.id),
            "name": bool(artifact.name),
            "mode": bool(artifact.mode),
            "dimensions": (
                artifact.width > 0
                and artifact.height > 0
            ),
            "fields": len(artifact.fields) > 0,
            "structures": len(artifact.structures) > 0,
        }

        return {
            "valid": all(checks.values()),
            "checks": checks,
        }


# =============================================================================
# 21. GRAVITATIONAL LENSING DOMAIN
# =============================================================================
#
# This preserves the core capability of META-ART v1.14:
#
#   observed Q2237+0305 / Einstein Cross astrometry
#   SIS model
#   SIS + external shear
#   source-plane fitting
#
# It is now a domain module rather than the entire engine.
#
# =============================================================================

@dataclass
class LensObservation:
    name: str
    x: float
    y: float
    sigma: float


class GravitationalLensingDomain:

    Q2237_OBSERVATIONS = [
        LensObservation(
            "A",
            0.0000,
            0.0000,
            0.0015,
        ),
        LensObservation(
            "B",
            0.6710,
            1.6970,
            0.0015,
        ),
        LensObservation(
            "C",
            -0.6340,
            1.2100,
            0.0015,
        ),
        LensObservation(
            "D",
            0.8660,
            0.5280,
            0.0015,
        ),
    ]

    LENS_CENTER = (
        0.0810,
        0.9370,
    )

    LENS_CENTER_SIGMA = 0.0100

    def __init__(self):
        self.observations = list(
            self.Q2237_OBSERVATIONS
        )

    def centered_positions(self) -> Any:

        if np is None:
            return [
                (
                    obs.x - self.LENS_CENTER[0],
                    obs.y - self.LENS_CENTER[1],
                )
                for obs in self.observations
            ]

        return np.asarray(
            [
                [
                    obs.x - self.LENS_CENTER[0],
                    obs.y - self.LENS_CENTER[1],
                ]
                for obs in self.observations
            ],
            dtype=float,
        )

    @staticmethod
    def sis_source(
        x: float,
        y: float,
        einstein_radius: float,
    ) -> Tuple[float, float]:

        r = math.sqrt(
            x * x + y * y
        )

        if r < EPSILON:
            return (
                x,
                y,
            )

        alpha_x = (
            einstein_radius
            * x
            / r
        )

        alpha_y = (
            einstein_radius
            * y
            / r
        )

        return (
            x - alpha_x,
            y - alpha_y,
        )

    @staticmethod
    def shear_deflection(
        x: float,
        y: float,
        gamma: float,
        angle: float,
    ) -> Tuple[float, float]:

        cos2 = math.cos(
            2.0 * angle
        )

        sin2 = math.sin(
            2.0 * angle
        )

        alpha_x = (
            gamma
            * (
                x * cos2
                + y * sin2
            )
        )

        alpha_y = (
            gamma
            * (
                x * sin2
                - y * cos2
            )
        )

        return (
            alpha_x,
            alpha_y,
        )

    def sis_shear_source(
        self,
        x: float,
        y: float,
        einstein_radius: float,
        gamma: float,
        angle: float,
    ) -> Tuple[float, float]:

        sis_x, sis_y = self.sis_source(
            x,
            y,
            einstein_radius,
        )

        sx, sy = self.shear_deflection(
            x,
            y,
            gamma,
            angle,
        )

        return (
            sis_x - sx,
            sis_y - sy,
        )

    def fit_sis(
        self,
    ) -> Dict[str, Any]:

        if least_squares is None:
            return self._fit_sis_fallback()

        positions = self.centered_positions()

        def residual(params):

            source_x, source_y, einstein_radius = params

            result = []

            for (
                x,
                y,
            ), obs in zip(
                positions,
                self.observations,
            ):

                bx, by = self.sis_source(
                    float(x),
                    float(y),
                    float(einstein_radius),
                )

                result.extend(
                    [
                        (
                            bx - source_x
                        ) / obs.sigma,
                        (
                            by - source_y
                        ) / obs.sigma,
                    ]
                )

            return np.asarray(
                result,
                dtype=float,
            )

        result = least_squares(
            residual,
            x0=np.array(
                [
                    0.0,
                    0.0,
                    0.9,
                ]
            ),
            bounds=(
                [
                    -5.0,
                    -5.0,
                    0.0,
                ],
                [
                    5.0,
                    5.0,
                    5.0,
                ],
            ),
        )

        residuals = residual(
            result.x
        )

        return {
            "model": "SIS",
            "source_x": float(result.x[0]),
            "source_y": float(result.x[1]),
            "einstein_radius": float(result.x[2]),
            "chi_square": float(
                np.sum(
                    residuals ** 2
                )
            ),
            "success": bool(result.success),
        }

    def fit_sis_shear(
        self,
    ) -> Dict[str, Any]:

        if least_squares is None:
            return self._fit_sis_shear_fallback()

        positions = self.centered_positions()

        def residual(params):

            source_x = params[0]
            source_y = params[1]
            einstein_radius = params[2]
            gamma = params[3]
            angle = params[4]

            result = []

            for (
                x,
                y,
            ), obs in zip(
                positions,
                self.observations,
            ):

                bx, by = self.sis_shear_source(
                    float(x),
                    float(y),
                    float(einstein_radius),
                    float(gamma),
                    float(angle),
                )

                result.extend(
                    [
                        (
                            bx - source_x
                        ) / obs.sigma,
                        (
                            by - source_y
                        ) / obs.sigma,
                    ]
                )

            return np.asarray(
                result,
                dtype=float,
            )

        result = least_squares(
            residual,
            x0=np.array(
                [
                    0.0,
                    0.0,
                    0.9,
                    0.05,
                    0.5,
                ]
            ),
            bounds=(
                [
                    -5.0,
                    -5.0,
                    0.0,
                    -1.0,
                    -math.pi,
                ],
                [
                    5.0,
                    5.0,
                    5.0,
                    1.0,
                    math.pi,
                ],
            ),
        )

        residuals = residual(
            result.x
        )

        return {
            "model": "SIS+external_shear",
            "source_x": float(result.x[0]),
            "source_y": float(result.x[1]),
            "einstein_radius": float(result.x[2]),
            "gamma": float(result.x[3]),
            "angle": float(result.x[4]),
            "chi_square": float(
                np.sum(
                    residuals ** 2
                )
            ),
            "rms_source_plane": float(
                np.sqrt(
                    np.mean(
                        residuals ** 2
                    )
                )
            ),
            "success": bool(result.success),
        }

    def _fit_sis_fallback(self) -> Dict[str, Any]:
        """
        Deterministic coarse fallback when SciPy is unavailable.
        """

        positions = self.centered_positions()

        best = None

        for radius in np.linspace(
            0.5,
            1.2,
            100,
        ):

            sources = [
                self.sis_source(
                    float(x),
                    float(y),
                    float(radius),
                )
                for x, y in positions
            ]

            sx = mean(
                [p[0] for p in sources]
            )

            sy = mean(
                [p[1] for p in sources]
            )

            chi = 0.0

            for (
                bx,
                by,
            ), obs in zip(
                sources,
                self.observations,
            ):

                chi += (
                    ((bx - sx) / obs.sigma) ** 2
                    + ((by - sy) / obs.sigma) ** 2
                )

            candidate = (
                chi,
                sx,
                sy,
                radius,
            )

            if best is None or candidate[0] < best[0]:
                best = candidate

        assert best is not None

        return {
            "model": "SIS",
            "source_x": best[1],
            "source_y": best[2],
            "einstein_radius": best[3],
            "chi_square": best[0],
            "success": True,
            "solver": "deterministic_fallback",
        }

    def _fit_sis_shear_fallback(self) -> Dict[str, Any]:
        """
        Coarse bounded search fallback.
        """

        positions = self.centered_positions()

        best = None

        radii = np.linspace(
            0.7,
            1.1,
            12,
        )

        gammas = np.linspace(
            0.0,
            0.15,
            10,
        )

        angles = np.linspace(
            -math.pi,
            math.pi,
            24,
        )

        for radius in radii:

            for gamma in gammas:

                for angle in angles:

                    sources = [
                        self.sis_shear_source(
                            float(x),
                            float(y),
                            float(radius),
                            float(gamma),
                            float(angle),
                        )
                        for x, y in positions
                    ]

                    sx = mean(
                        [p[0] for p in sources]
                    )

                    sy = mean(
                        [p[1] for p in sources]
                    )

                    chi = 0.0

                    for (
                        bx,
                        by,
                    ), obs in zip(
                        sources,
                        self.observations,
                    ):

                        chi += (
                            ((bx - sx) / obs.sigma) ** 2
                            + ((by - sy) / obs.sigma) ** 2
                        )

                    candidate = (
                        chi,
                        sx,
                        sy,
                        radius,
                        gamma,
                        angle,
                    )

                    if (
                        best is None
                        or candidate[0] < best[0]
                    ):
                        best = candidate

        assert best is not None

        return {
            "model": "SIS+external_shear",
            "source_x": best[1],
            "source_y": best[2],
            "einstein_radius": best[3],
            "gamma": best[4],
            "angle": best[5],
            "chi_square": best[0],
            "success": True,
            "solver": "deterministic_fallback",
        }

    def to_structure(self) -> Structure:

        sis = self.fit_sis()
        shear = self.fit_sis_shear()

        data = {
            "observations": [
                asdict(obs)
                for obs in self.observations
            ],
            "lens_center": self.LENS_CENTER,
            "sis_fit": sis,
            "sis_shear_fit": shear,
        }

        return GenericDomainAdapters.json(
            domain_name="astronomy",
            data=data,
            source="Q2237+0305_observed_astrometry",
        )


# =============================================================================
# 22. MATHEMATICS DOMAIN
# =============================================================================

class MathematicsDomain:

    def expression_structure(
        self,
        expression: str,
    ) -> Structure:

        if sp is not None:

            try:
                symbolic = sp.sympify(
                    expression
                )

                data = {
                    "expression": expression,
                    "symbols": sorted(
                        str(s)
                        for s in symbolic.free_symbols
                    ),
                    "operations": str(
                        symbolic.count_ops()
                    ),
                }

            except Exception:

                data = {
                    "expression": expression,
                    "symbols": [],
                    "operations": "unparsed",
                }

        else:

            data = {
                "expression": expression,
            }

        return GenericDomainAdapters.json(
            domain_name="mathematics",
            data=data,
            source="symbolic_expression",
        )


# =============================================================================
# 23. LANGUAGE DOMAIN
# =============================================================================

class LanguageDomain:

    def analyze_text(
        self,
        text: str,
    ) -> Structure:

        words = text.split()

        word_lengths = [
            len(word)
            for word in words
        ]

        data = {
            "text": text,
            "word_count": len(words),
            "sentence_count": max(
                1,
                sum(
                    text.count(x)
                    for x in ".!?"
                )
            ),
            "word_lengths": word_lengths,
        }

        structure = GenericDomainAdapters.json(
            domain_name="language",
            data=data,
            source="language_input",
        )

        structure.features.extend(
            FeatureExtractor.text_features(
                text
            )
        )

        return structure


# =============================================================================
# 24. MUSIC / AUDIO DOMAIN
# =============================================================================

class MusicDomain:

    def analyze_samples(
        self,
        samples: Any,
        sample_rate: float,
    ) -> Structure:

        if np is None:
            raise RuntimeError(
                "NumPy required for audio analysis"
            )

        samples = np.asarray(
            samples,
            dtype=float,
        )

        if samples.ndim > 1:
            mono = np.mean(
                samples,
                axis=1,
            )
        else:
            mono = samples

        spectrum = np.abs(
            np.fft.rfft(
                mono
            )
        )

        frequencies = np.fft.rfftfreq(
            len(mono),
            d=1.0 / sample_rate,
        )

        peak_index = (
            int(
                np.argmax(
                    spectrum[1:]
                )
            ) + 1
            if len(spectrum) > 1
            else 0
        )

        data = {
            "sample_rate": float(
                sample_rate
            ),
            "sample_count": int(
                len(mono)
            ),
            "dominant_frequency": float(
                frequencies[peak_index]
            ),
            "spectral_energy": float(
                np.sum(
                    spectrum ** 2
                )
            ),
            "waveform": mono.tolist(),
        }

        return GenericDomainAdapters.json(
            domain_name="music",
            data=data,
            source="audio_analysis",
            kind="audio_structure",
        )


# =============================================================================
# 25. BIOLOGY / ECOLOGY DOMAIN
# =============================================================================

class BiologyDomain:

    def interaction_matrix(
        self,
        matrix: Any,
        labels: Optional[
            Sequence[str]
        ] = None,
    ) -> Structure:

        if np is None:
            raise RuntimeError(
                "NumPy required"
            )

        matrix = np.asarray(
            matrix,
            dtype=float,
        )

        labels = list(
            labels
            or [
                f"node_{i}"
                for i in range(
                    matrix.shape[0]
                )
            ]
        )

        data = {
            "matrix": matrix.tolist(),
            "labels": labels,
            "node_count": int(
                matrix.shape[0]
            ),
            "interaction_energy": float(
                np.sum(
                    np.abs(matrix)
                )
            ),
        }

        return GenericDomainAdapters.json(
            domain_name="biology",
            data=data,
            source="biological_interaction_matrix",
            kind="interaction_network",
        )


# =============================================================================
# 26. ARCHITECTURE DOMAIN
# =============================================================================

class ArchitectureDomain:

    def spatial_graph(
        self,
        nodes: Sequence[
            Tuple[float, float]
        ],
        edges: Sequence[
            Tuple[int, int]
        ],
    ) -> Structure:

        graph = {
            "nodes": [
                {
                    "id": i,
                    "x": float(x),
                    "y": float(y),
                }
                for i, (
                    x,
                    y,
                ) in enumerate(nodes)
            ],
            "edges": [
                {
                    "source": int(a),
                    "target": int(b),
                }
                for a, b in edges
            ],
        }

        return GenericDomainAdapters.json(
            domain_name="architecture",
            data=graph,
            source="architectural_spatial_graph",
            kind="spatial_graph",
        )


# =============================================================================
# 27. COMPUTATION DOMAIN
# =============================================================================

class ComputationDomain:

    def execution_structure(
        self,
        operations: Sequence[str],
    ) -> Structure:

        data = {
            "operations": list(
                operations
            ),
            "operation_count": len(
                operations
            ),
            "dependency_depth": self._estimate_depth(
                operations
            ),
        }

        return GenericDomainAdapters.json(
            domain_name="computation",
            data=data,
            source="computation_pipeline",
            kind="program_structure",
        )

    @staticmethod
    def _estimate_depth(
        operations: Sequence[str],
    ) -> int:

        depth = 0

        for operation in operations:
            if (
                "loop" in operation.lower()
                or "recursive" in operation.lower()
                or "dependency" in operation.lower()
            ):
                depth += 1

        return max(
            1,
            depth,
        )


# =============================================================================
# 28. CROSS-DOMAIN MAPPING ENGINE
# =============================================================================

class CrossDomainMapper:

    def __init__(
        self,
        synthesizer: FieldSynthesizer,
    ):
        self.synthesizer = synthesizer

    def map_numeric_structure(
        self,
        structure: Structure,
    ) -> Any:

        if np is None:
            raise RuntimeError("NumPy required")

        data = structure.data

        if not isinstance(
            data,
            np.ndarray,
        ):
            try:
                data = np.asarray(
                    data,
                    dtype=float,
                )
            except Exception:
                data = np.asarray(
                    [
                        f.value
                        for f in structure.features
                    ],
                    dtype=float,
                )

        if data.size == 0:
            return np.zeros(
                (
                    self.synthesizer.height,
                    self.synthesizer.width,
                )
            )

        data = data.reshape(-1)

        if len(data) == 1:
            return np.full(
                (
                    self.synthesizer.height,
                    self.synthesizer.width,
                ),
                float(data[0]),
            )

        # Convert arbitrary 1D structure to a 2D field.
        x = np.linspace(
            0.0,
            1.0,
            len(data),
        )

        target_x = np.linspace(
            0.0,
            1.0,
            self.synthesizer.width,
        )

        interpolated = np.interp(
            target_x,
            x,
            data,
        )

        field = np.tile(
            interpolated,
            (
                self.synthesizer.height,
                1,
            ),
        )

        return self.synthesizer.normalize(
            field
        )

    def map_structure(
        self,
        structure: Structure,
        mode: str = "adaptive",
    ) -> Any:

        if mode == "adaptive":

            if structure.domain == "astronomy":
                mode = "angular"

            elif structure.domain == "mathematics":
                mode = "wave"

            elif structure.domain == "language":
                mode = "spiral"

            elif structure.domain == "music":
                mode = "wave"

            elif structure.domain == "biology":
                mode = "interference"

            elif structure.domain == "architecture":
                mode = "gaussian"

            elif structure.domain == "computation":
                mode = "directional"

            else:
                mode = "wave"

        if mode == "numeric":
            return self.map_numeric_structure(
                structure
            )

        if mode == "interference":

            seed = int(
                sha256(
                    structure.to_dict()
                )[:12],
                16,
            )

            angle_a = (
                seed % 3600
            ) / 10.0

            angle_b = (
                (seed // 17) % 3600
            ) / 10.0

            return self.synthesizer.interference(
                math.radians(angle_a),
                math.radians(angle_b),
                1.0 + seed % 10,
                1.0 + (seed // 11) % 13,
            )

        if mode == "directional":

            seed = int(
                sha256(
                    structure.to_dict()
                )[:12],
                16,
            )

            return self.synthesizer.directional_wave(
                theta_bias=math.radians(
                    seed % 360
                ),
                frequency=1.0 + seed % 9,
            )

        return self.synthesizer.structure_to_field(
            structure,
            weight=1.0,
            mode=mode,
        )


# =============================================================================
# 29. UNIFIED STRUCTURAL MODEL
# =============================================================================

@dataclass
class UnifiedModel:

    domains: Dict[str, Domain] = field(
        default_factory=dict
    )

    structures: Dict[str, Structure] = field(
        default_factory=dict
    )

    relations: Dict[str, Relation] = field(
        default_factory=dict
    )

    fields: Dict[str, Field] = field(
        default_factory=dict
    )

    transforms: List[Transform] = field(
        default_factory=list
    )

    reasoning_steps: List[ReasoningStep] = field(
        default_factory=list
    )

    hypotheses: List[Hypothesis] = field(
        default_factory=list
    )

    decisions: List[Decision] = field(
        default_factory=list
    )

    metadata: Dict[str, Any] = field(
        default_factory=dict
    )

    def add_structure(
        self,
        structure: Structure,
    ) -> None:

        self.structures[
            structure.id
        ] = structure

        if structure.domain not in self.domains:
            self.domains[
                structure.domain
            ] = Domain(
                name=structure.domain,
                description=(
                    f"Domain: {structure.domain}"
                ),
            )

        self.domains[
            structure.domain
        ].add(
            structure
        )

    def add_relation(
        self,
        relation: Relation,
    ) -> None:

        self.relations[
            relation.id
        ] = relation

    def to_dict(self) -> Dict[str, Any]:

        return {
            "domains": {
                name: domain.to_dict()
                for name, domain in self.domains.items()
            },
            "structures": {
                key: value.to_dict()
                for key, value in self.structures.items()
            },
            "relations": {
                key: value.to_dict()
                for key, value in self.relations.items()
            },
            "fields": {
                key: value.to_dict()
                for key, value in self.fields.items()
            },
            "transforms": [
                t.to_dict()
                for t in self.transforms
            ],
            "reasoning_steps": [
                x.to_dict()
                for x in self.reasoning_steps
            ],
            "hypotheses": [
                x.to_dict()
                for x in self.hypotheses
            ],
            "decisions": [
                x.to_dict()
                for x in self.decisions
            ],
            "metadata": canonicalize(
                self.metadata
            ),
        }


# =============================================================================
# 30. META-ART ENGINE
# =============================================================================

class MetaArtEngine:

    def __init__(
        self,
        width: int = 1024,
        height: int = 1024,
        seed: int = DEFAULT_SEED,
        limits: Optional[ResourceLimits] = None,
    ):

        self.limits = (
            limits
            or ResourceLimits()
        )

        self.seed = int(seed)

        self.registry = DomainRegistry()

        self.model = UnifiedModel()

        self.relationship_engine = (
            RelationshipEngine(
                self.limits
            )
        )

        self.transform_engine = (
            TransformEngine()
        )

        self.intelligence = (
            StructuralIntelligence(
                seed=self.seed,
                limits=self.limits,
            )
        )

        self.synthesizer = (
            FieldSynthesizer(
                width=width,
                height=height,
                limits=self.limits,
            )
        )

        self.mapper = (
            CrossDomainMapper(
                self.synthesizer
            )
        )

        self.projector = (
            ArtisticProjector(
                self.synthesizer
            )
        )

        self.validator = (
            ValidationEngine()
        )

        self.raster = RasterRenderer()

        self.svg = SVGExporter()

        self.obj = OBJExporter()

        self.ply = PLYExporter()

        self.started = time.time()

        self._register_builtin_domains()

    # -------------------------------------------------------------------------
    # REGISTRATION
    # -------------------------------------------------------------------------

    def _register_builtin_domains(self):

        builtin = [
            (
                "mathematics",
                "Mathematical structures and symbolic relationships.",
            ),
            (
                "physics",
                "Physical laws, measurements, and models.",
            ),
            (
                "astronomy",
                "Astronomical observations and physical structures.",
            ),
            (
                "biology",
                "Biological and ecological structures.",
            ),
            (
                "language",
                "Linguistic and textual structures.",
            ),
            (
                "music",
                "Audio, waveform, rhythm, and spectral structures.",
            ),
            (
                "architecture",
                "Spatial, geometric, and architectural structures.",
            ),
            (
                "computation",
                "Programs, algorithms, graphs, and computational processes.",
            ),
            (
                "custom",
                "Arbitrary user-defined structures.",
            ),
        ]

        for name, description in builtin:
            self.registry.register_domain(
                Domain(
                    name=name,
                    description=description,
                )
            )

    # -------------------------------------------------------------------------
    # INGESTION
    # -------------------------------------------------------------------------

    def ingest(
        self,
        structure: Structure,
    ) -> str:

        self.limits.check_nodes(
            len(self.model.structures) + 1
        )

        self.model.add_structure(
            structure
        )

        return structure.id

    def ingest_numeric(
        self,
        domain: str,
        values: Any,
        source: str = "memory",
    ) -> str:

        return self.ingest(
            GenericDomainAdapters.numeric(
                domain,
                values,
                source,
            )
        )

    def ingest_text(
        self,
        domain: str,
        text: str,
        source: str = "memory",
    ) -> str:

        return self.ingest(
            GenericDomainAdapters.text(
                domain,
                text,
                source,
            )
        )

    def ingest_json(
        self,
        domain: str,
        data: Any,
        source: str = "memory",
    ) -> str:

        return self.ingest(
            GenericDomainAdapters.json(
                domain,
                data,
                source,
            )
        )

    # -------------------------------------------------------------------------
    # RELATIONSHIP DISCOVERY
    # -------------------------------------------------------------------------

    def relate(
        self,
        threshold: float = 0.20,
    ) -> List[Relation]:

        structures = list(
            self.model.structures.values()
        )

        relations = (
            self.relationship_engine.discover(
                structures,
                threshold=threshold,
            )
        )

        for relation in relations:
            self.model.add_relation(
                relation
            )

        return relations

    # -------------------------------------------------------------------------
    # STRUCTURAL ANALYSIS
    # -------------------------------------------------------------------------

    def analyze(self) -> Dict[str, Any]:

        structures = list(
            self.model.structures.values()
        )

        relations = list(
            self.model.relations.values()
        )

        analysis = self.intelligence.analyze(
            structures,
            relations,
        )

        hypotheses = (
            self.intelligence.generate_hypotheses(
                structures,
                relations,
            )
        )

        self.model.reasoning_steps.extend(
            self.intelligence.steps
        )

        self.model.hypotheses.extend(
            hypotheses
        )

        self.model.decisions.extend(
            self.intelligence.decisions
        )

        return {
            "analysis": analysis,
            "hypotheses": [
                h.to_dict()
                for h in hypotheses
            ],
        }

    # -------------------------------------------------------------------------
    # FIELD GENERATION
    # -------------------------------------------------------------------------

    def generate_fields(
        self,
        mapping_mode: str = "adaptive",
    ) -> Dict[str, Field]:

        fields = {}

        structures = list(
            self.model.structures.values()
        )

        if not structures:
            raise RuntimeError(
                "No structures have been ingested"
            )

        mapped = []

        for structure in structures:

            field_data = (
                self.mapper.map_structure(
                    structure,
                    mode=mapping_mode,
                )
            )

            field_id = deterministic_id(
                "field",
                {
                    "structure": structure.id,
                    "engine": META_ART_VERSION,
                    "seed": self.seed,
                },
            )

            vx, vy = (
                self.synthesizer.vectorize(
                    field_data
                )
            )

            field = Field(
                name=field_id,
                width=self.synthesizer.width,
                height=self.synthesizer.height,
                scalar=field_data,
                vector_x=vx,
                vector_y=vy,
                metadata={
                    "source_structure": structure.id,
                    "source_domain": structure.domain,
                    "mapping_mode": mapping_mode,
                },
            )

            self.model.fields[
                field_id
            ] = field

            fields[
                field_id
            ] = field

            mapped.append(
                (
                    field_data,
                    self._structure_weight(
                        structure
                    ),
                )
            )

        unified = (
            self.synthesizer.cross_domain_field(
                mapped
            )
        )

        unified_id = deterministic_id(
            "field",
            {
                "type": "unified",
                "fields": sorted(fields),
                "seed": self.seed,
            },
        )

        vx, vy = (
            self.synthesizer.vectorize(
                unified
            )
        )

        unified_field = Field(
            name=unified_id,
            width=self.synthesizer.width,
            height=self.synthesizer.height,
            scalar=unified,
            vector_x=vx,
            vector_y=vy,
            metadata={
                "type": "unified_cross_domain_field",
                "source_fields": sorted(fields),
                "domain_count": len(
                    set(
                        s.domain
                        for s in structures
                    )
                ),
            },
        )

        self.model.fields[
            unified_id
        ] = unified_field

        fields[
            unified_id
        ] = unified_field

        return fields

    @staticmethod
    def _structure_weight(
        structure: Structure,
    ) -> float:

        if not structure.features:
            return 1.0

        confidence = mean(
            [
                f.confidence
                for f in structure.features
            ]
        )

        complexity = min(
            1.0,
            len(
                canonical_json(
                    structure.data
                )
            ) / 10000.0,
        )

        return (
            0.65 * confidence
            + 0.35 * complexity
        )

    # -------------------------------------------------------------------------
    # ART GENERATION
    # -------------------------------------------------------------------------

    def generate_artifact(
        self,
        name: str = "META-ART_WORK",
        field_id: Optional[str] = None,
    ) -> Artifact:

        if not self.model.fields:
            self.generate_fields()

        if field_id is None:

            candidates = [
                field
                for field in self.model.fields.values()
                if field.metadata.get("type")
                == "unified_cross_domain_field"
            ]

            if candidates:
                field = candidates[-1]
            else:
                field = list(
                    self.model.fields.values()
                )[-1]

        else:
            field = self.model.fields[
                field_id
            ]

        layers = (
            self.projector.generate_object(
                field.scalar
            )
        )

        validation = (
            self.validator.validate_field(
                field.scalar
            )
        )

        artifact_id = deterministic_id(
            "artifact",
            {
                "name": name,
                "field": field.name,
                "structures": sorted(
                    self.model.structures
                ),
                "relations": sorted(
                    self.model.relations
                ),
                "seed": self.seed,
            },
        )

        provenance = {
            "engine": META_ART_NAME,
            "version": META_ART_VERSION,
            "seed": self.seed,
            "source_structures": sorted(
                self.model.structures
            ),
            "source_relations": sorted(
                self.model.relations
            ),
            "source_fields": sorted(
                self.model.fields
            ),
            "field": field.name,
            "generated_at": time.time(),
        }

        artifact = Artifact(
            id=artifact_id,
            name=name,
            mode="META_ART_UNIFIED_STRUCTURAL_OBJECT",
            width=self.synthesizer.width,
            height=self.synthesizer.height,
            layers=[
                layers
            ],
            fields=[
                field.name
            ],
            structures=list(
                self.model.structures
            ),
            relations=list(
                self.model.relations
            ),
            decisions=list(
                self.model.decisions
            ),
            validation=validation,
            provenance=provenance,
        )

        return artifact

    # -------------------------------------------------------------------------
    # RENDER
    # -------------------------------------------------------------------------

    def render_png(
        self,
        artifact: Artifact,
        path: str | Path,
    ) -> Path:

        field_id = artifact.fields[0]

        field = self.model.fields[
            field_id
        ]

        return self.raster.render(
            field.scalar,
            path,
        )

    def render_svg(
        self,
        artifact: Artifact,
        path: str | Path,
    ) -> Path:

        field_id = artifact.fields[0]

        field = self.model.fields[
            field_id
        ]

        return self.svg.export(
            field.scalar,
            path,
        )

    def render_obj(
        self,
        artifact: Artifact,
        path: str | Path,
    ) -> Path:

        field_id = artifact.fields[0]

        field = self.model.fields[
            field_id
        ]

        return self.obj.export(
            field.scalar,
            path,
        )

    def render_ply(
        self,
        artifact: Artifact,
        path: str | Path,
    ) -> Path:

        field_id = artifact.fields[0]

        field = self.model.fields[
            field_id
        ]

        points = (
            self.projector.field_to_geometry(
                field.scalar,
                threshold=0.50,
                sample_step=max(
                    1,
                    self.synthesizer.width // 256,
                ),
            )
        )

        return self.ply.export_points(
            points,
            path,
        )

    # -------------------------------------------------------------------------
    # COMPLETE PIPELINE
    # -------------------------------------------------------------------------

    def run(
        self,
        name: str = "META-ART_WORK",
        relate_threshold: float = 0.20,
    ) -> Artifact:

        self.relate(
            threshold=relate_threshold
        )

        self.analyze()

        self.generate_fields()

        artifact = (
            self.generate_artifact(
                name=name
            )
        )

        return artifact

    # -------------------------------------------------------------------------
    # EXPORT STATE
    # -------------------------------------------------------------------------

    def export_state(
        self,
        path: str | Path,
    ) -> Path:

        state = {
            "engine": {
                "name": META_ART_NAME,
                "version": META_ART_VERSION,
                "mode": ENGINE_MODE,
                "seed": self.seed,
            },
            "model": self.model.to_dict(),
            "registry": self.registry.to_dict(),
            "runtime_seconds": (
                time.time()
                - self.started
            ),
        }

        path = Path(path)

        path.parent.mkdir(
            parents=True,
            exist_ok=True,
        )

        path.write_text(
            json.dumps(
                state,
                indent=2,
                ensure_ascii=False,
            ),
            encoding="utf-8",
        )

        return path

    # -------------------------------------------------------------------------
    # VALIDATE
    # -------------------------------------------------------------------------

    def validate(self) -> Dict[str, Any]:

        structure_results = {
            sid: self.validator.validate_structure(
                structure
            )
            for sid, structure
            in self.model.structures.items()
        }

        relation_result = (
            self.validator.validate_relations(
                list(
                    self.model.relations.values()
                )
            )
        )

        field_results = {
            fid: self.validator.validate_field(
                field.scalar
            )
            for fid, field
            in self.model.fields.items()
        }

        return {
            "structures": structure_results,
            "relations": relation_result,
            "fields": field_results,
            "domain_count": len(
                self.model.domains
            ),
            "structure_count": len(
                self.model.structures
            ),
            "relation_count": len(
                self.model.relations
            ),
            "field_count": len(
                self.model.fields
            ),
            "overall_valid": (
                all(
                    x["valid"]
                    for x in structure_results.values()
                )
                and relation_result["valid"]
                and all(
                    x["valid"]
                    for x in field_results.values()
                )
            ),
        }


# =============================================================================
# 31. DEMONSTRATION DATASET
# =============================================================================

def build_demo_engine(
    width: int = 1024,
    height: int = 1024,
) -> MetaArtEngine:

    engine = MetaArtEngine(
        width=width,
        height=height,
        seed=DEFAULT_SEED,
    )

    # -------------------------------------------------------------------------
    # MATHEMATICS
    # -------------------------------------------------------------------------

    mathematics = MathematicsDomain()

    engine.ingest(
        mathematics.expression_structure(
            "sin(x) * exp(-x**2) + cos(phi*x)"
        )
    )

    # -------------------------------------------------------------------------
    # PHYSICS / ASTRONOMY
    # -------------------------------------------------------------------------

    lensing = (
        GravitationalLensingDomain()
    )

    engine.ingest(
        lensing.to_structure()
    )

    # -------------------------------------------------------------------------
    # LANGUAGE
    # -------------------------------------------------------------------------

    language = LanguageDomain()

    engine.ingest(
        language.analyze_text(
            """
            A structure may contain relationships.
            Relationships may become transformations.
            Transformations may become a unified computational field.
            The field becomes an artwork without requiring the domains
            to remain separate.
            """
        )
    )

    # -------------------------------------------------------------------------
    # BIOLOGY
    # -------------------------------------------------------------------------

    biology = BiologyDomain()

    biological_matrix = np.array(
        [
            [0.0, 0.8, 0.2, 0.1],
            [0.4, 0.0, 0.7, 0.3],
            [0.2, 0.5, 0.0, 0.9],
            [0.1, 0.3, 0.8, 0.0],
        ],
        dtype=float,
    )

    engine.ingest(
        biology.interaction_matrix(
            biological_matrix,
            labels=[
                "A",
                "B",
                "C",
                "D",
            ],
        )
    )

    # -------------------------------------------------------------------------
    # ARCHITECTURE
    # -------------------------------------------------------------------------

    architecture = (
        ArchitectureDomain()
    )

    engine.ingest(
        architecture.spatial_graph(
            nodes=[
                (-1.0, -1.0),
                (1.0, -1.0),
                (1.0, 1.0),
                (-1.0, 1.0),
                (0.0, 0.0),
            ],
            edges=[
                (0, 1),
                (1, 2),
                (2, 3),
                (3, 0),
                (0, 4),
                (1, 4),
                (2, 4),
                (3, 4),
            ],
        )
    )

    # -------------------------------------------------------------------------
    # COMPUTATION
    # -------------------------------------------------------------------------

    computation = (
        ComputationDomain()
    )

    engine.ingest(
        computation.execution_structure(
            [
                "ingest",
                "normalize",
                "extract_features",
                "discover_relations",
                "optimize",
                "synthesize_field",
                "project_geometry",
                "validate",
                "render",
            ]
        )
    )

    # -------------------------------------------------------------------------
    # MUSIC-LIKE NUMERIC STRUCTURE
    # -------------------------------------------------------------------------

    t = np.linspace(
        0.0,
        2.0,
        4096,
        endpoint=False,
    )

    audio = (
        np.sin(
            2.0
            * math.pi
            * 220.0
            * t
        )
        + 0.45
        * np.sin(
            2.0
            * math.pi
            * 330.0
            * t
        )
        + 0.20
        * np.sin(
            2.0
            * math.pi
            * 440.0
            * t
        )
    )

    music = MusicDomain()

    engine.ingest(
        music.analyze_samples(
            audio,
            sample_rate=2048.0,
        )
    )

    return engine


# =============================================================================
# 32. SELF TEST
# =============================================================================

def self_test() -> Dict[str, Any]:

    results: Dict[str, Any] = {}

    # -------------------------------------------------------------------------
    # Basic numerical tests
    # -------------------------------------------------------------------------

    results["clamp"] = (
        clamp(
            2.0,
            0.0,
            1.0,
        )
        == 1.0
    )

    results["safe_div"] = (
        safe_div(
            1.0,
            0.0,
        )
        == 0.0
    )

    # -------------------------------------------------------------------------
    # Hash determinism
    # -------------------------------------------------------------------------

    value = {
        "a": 1,
        "b": [
            2,
            3,
        ],
    }

    results["hash_determinism"] = (
        sha256(value)
        == sha256(value)
    )

    # -------------------------------------------------------------------------
    # Safe expression
    # -------------------------------------------------------------------------

    expression_value = (
        SafeExpression.evaluate(
            "sin(x) + cos(y)",
            {
                "x": 0.0,
                "y": 0.0,
            },
        )
    )

    results["safe_expression"] = (
        abs(expression_value - 1.0)
        < 1.0e-9
    )

    # -------------------------------------------------------------------------
    # Engine construction
    # -------------------------------------------------------------------------

    engine = MetaArtEngine(
        width=128,
        height=128,
    )

    engine.ingest_numeric(
        "mathematics",
        np.linspace(
            0.0,
            1.0,
            64,
        ),
    )

    engine.ingest_text(
        "language",
        "structure relation transformation",
    )

    engine.relate()

    analysis = engine.analyze()

    results["multidomain"] = (
        analysis["analysis"]["domain_count"]
        >= 2
    )

    fields = engine.generate_fields()

    results["field_generation"] = (
        len(fields)
        >= 3
    )

    artifact = engine.generate_artifact()

    results["artifact_generation"] = (
        bool(artifact.id)
        and len(artifact.fields) > 0
    )

    validation = engine.validate()

    results["validation"] = (
        validation["overall_valid"]
    )

    results["all_pass"] = all(
        results.values()
    )

    return results


# =============================================================================
# 33. COMMAND-LINE INTERFACE
# =============================================================================

def create_parser() -> argparse.ArgumentParser:

    parser = argparse.ArgumentParser(
        prog="meta-art",
        description=(
            "META-ART multidomain structural generative engine."
        ),
    )

    parser.add_argument(
        "--version",
        action="version",
        version=(
            f"{META_ART_NAME} "
            f"{META_ART_VERSION}"
        ),
    )

    parser.add_argument(
        "--width",
        type=int,
        default=1024,
    )

    parser.add_argument(
        "--height",
        type=int,
        default=1024,
    )

    parser.add_argument(
        "--seed",
        type=int,
        default=DEFAULT_SEED,
    )

    subparsers = parser.add_subparsers(
        dest="command"
    )

    subparsers.add_parser(
        "self-test",
        help="Run internal tests.",
    )

    subparsers.add_parser(
        "demo",
        help="Run the multidomain demonstration.",
    )

    run_parser = subparsers.add_parser(
        "run",
        help="Run the complete demo pipeline.",
    )

    run_parser.add_argument(
        "--output",
        default="meta_art_output",
    )

    run_parser.add_argument(
        "--name",
        default="META-ART_WORK",
    )

    return parser


# =============================================================================
# 34. CLI COMMANDS
# =============================================================================

def command_self_test() -> int:

    results = self_test()

    print(
        json.dumps(
            results,
            indent=2,
        )
    )

    return 0 if results["all_pass"] else 1


def command_demo(
    width: int,
    height: int,
) -> int:

    engine = build_demo_engine(
        width=width,
        height=height,
    )

    engine.relate()

    analysis = engine.analyze()

    print(
        json.dumps(
            analysis,
            indent=2,
            ensure_ascii=False,
        )
    )

    return 0


def command_run(
    width: int,
    height: int,
    seed: int,
    output: str,
    name: str,
) -> int:

    output_path = Path(output)

    output_path.mkdir(
        parents=True,
        exist_ok=True,
    )

    engine = MetaArtEngine(
        width=width,
        height=height,
        seed=seed,
    )

    # -------------------------------------------------------------------------
    # Construct multidomain input
    # -------------------------------------------------------------------------

    engine = build_demo_engine(
        width=width,
        height=height,
    )

    # -------------------------------------------------------------------------
    # Relationship discovery
    # -------------------------------------------------------------------------

    relations = engine.relate()

    print(
        f"[META-ART] relations discovered: "
        f"{len(relations)}"
    )

    # -------------------------------------------------------------------------
    # Structural analysis
    # -------------------------------------------------------------------------

    analysis = engine.analyze()

    print(
        f"[META-ART] domains: "
        f"{analysis['analysis']['domain_count']}"
    )

    print(
        f"[META-ART] coherence: "
        f"{analysis['analysis']['coherence']:.6f}"
    )

    # -------------------------------------------------------------------------
    # Field generation
    # -------------------------------------------------------------------------

    fields = engine.generate_fields()

    print(
        f"[META-ART] fields generated: "
        f"{len(fields)}"
    )

    # -------------------------------------------------------------------------
    # Artifact
    # -------------------------------------------------------------------------

    artifact = engine.generate_artifact(
        name=name
    )

    # -------------------------------------------------------------------------
    # Render
    # -------------------------------------------------------------------------

    png_path = engine.render_png(
        artifact,
        output_path / "meta_art.png",
    )

    svg_path = engine.render_svg(
        artifact,
        output_path / "meta_art.svg",
    )

    obj_path = engine.render_obj(
        artifact,
        output_path / "meta_art.obj",
    )

    ply_path = engine.render_ply(
        artifact,
        output_path / "meta_art.ply",
    )

    # -------------------------------------------------------------------------
    # State
    # -------------------------------------------------------------------------

    state_path = engine.export_state(
        output_path / "meta_art_state.json"
    )

    validation = engine.validate()

    artifact_path = (
        output_path
        / "meta_artifact.json"
    )

    artifact_path.write_text(
        json.dumps(
            artifact.to_dict(),
            indent=2,
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )

    validation_path = (
        output_path
        / "validation.json"
    )

    validation_path.write_text(
        json.dumps(
            validation,
            indent=2,
        ),
        encoding="utf-8",
    )

    print(
        "\n[META-ART] COMPLETE"
    )

    print(
        f"[META-ART] artifact: "
        f"{artifact.id}"
    )

    print(
        f"[META-ART] PNG: {png_path}"
    )

    print(
        f"[META-ART] SVG: {svg_path}"
    )

    print(
        f"[META-ART] OBJ: {obj_path}"
    )

    print(
        f"[META-ART] PLY: {ply_path}"
    )

    print(
        f"[META-ART] STATE: {state_path}"
    )

    print(
        f"[META-ART] VALID: "
        f"{validation['overall_valid']}"
    )

    return 0


# =============================================================================
# 35. MAIN
# =============================================================================

def main(
    argv: Optional[
        Sequence[str]
    ] = None,
) -> int:

    parser = create_parser()

    args = parser.parse_args(
        argv
    )

    if args.command == "self-test":
        return command_self_test()

    if args.command == "demo":
        return command_demo(
            width=args.width,
            height=args.height,
        )

    if args.command == "run":

        return command_run(
            width=args.width,
            height=args.height,
            seed=args.seed,
            output=args.output,
            name=args.name,
        )

    parser.print_help()

    return 0


# =============================================================================
# 36. PROGRAM ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    raise SystemExit(
        main()
    )


# =============================================================================
# 37. ARCHITECTURAL REFERENCE
# =============================================================================
#
# The complete engine can be understood as the following system:
#
#
#                         META-ART ENGINE
#                                │
#             ┌──────────────────┼──────────────────┐
#             │                  │                  │
#             ▼                  ▼                  ▼
#        DOMAIN INPUTS       DOMAIN REGISTRY    RESOURCE LIMITS
#             │
#             ├──────── mathematics
#             ├──────── physics
#             ├──────── astronomy
#             ├──────── gravitational lensing
#             ├──────── biology
#             ├──────── language
#             ├──────── music
#             ├──────── architecture
#             ├──────── computation
#             └──────── custom domains
#                                │
#                                ▼
#                       STRUCTURE EXTRACTION
#                                │
#                                ▼
#                         FEATURE EXTRACTION
#                                │
#                                ▼
#                       RELATIONSHIP ENGINE
#                                │
#             ┌──────────────────┼──────────────────┐
#             │                  │                  │
#             ▼                  ▼                  ▼
#        similarity          topology          semantics
#             │                  │                  │
#             └──────────────────┼──────────────────┘
#                                │
#                                ▼
#                     STRUCTURAL INTELLIGENCE
#                                │
#             ┌──────────────────┼──────────────────┐
#             │                  │                  │
#             ▼                  ▼                  ▼
#         analysis          hypotheses         decisions
#             │                  │                  │
#             └──────────────────┼──────────────────┘
#                                │
#                                ▼
#                     CROSS-DOMAIN MAPPING
#                                │
#                                ▼
#                       FIELD SYNTHESIS
#                                │
#                 ┌──────────────┼──────────────┐
#                 │              │              │
#                 ▼              ▼              ▼
#             scalar field   vector field   interference
#                 │              │              │
#                 └──────────────┼──────────────┘
#                                │
#                                ▼
#                       ARTISTIC PROJECTION
#                                │
#                 ┌──────────────┼──────────────┐
#                 │              │              │
#                 ▼              ▼              ▼
#              geometry       layers          object
#                 │              │              │
#                 └──────────────┼──────────────┘
#                                │
#                                ▼
#                            VALIDATION
#                                │
#                                ▼
#                           PROVENANCE
#                                │
#             ┌──────────────────┼──────────────────┐
#             │                  │                  │
#             ▼                  ▼                  ▼
#             PNG               SVG                OBJ
#             │                  │                  │
#             └──────────────────┼──────────────────┘
#                                │
#                                ▼
#                              PLY
#
#
# =============================================================================
# 38. WHAT MAKES THIS DIFFERENT FROM A NORMAL IMAGE GENERATOR
# =============================================================================
#
# A conventional image generator can be represented as:
#
#     prompt → model → image
#
# This engine is instead:
#
#     domain data
#          ↓
#     structure
#          ↓
#     features
#          ↓
#     relationships
#          ↓
#     reasoning
#          ↓
#     transformations
#          ↓
#     unified representation
#          ↓
#     field
#          ↓
#     geometry
#          ↓
#     artifact
#
# Therefore the image is an OUTPUT of the structural process rather than the
# entire computational object.
#
#
# =============================================================================
# 39. MULTIDOMAIN UNITY
# =============================================================================
#
# Example:
#
#     mathematics
#         │
#         ├── frequency
#         ├── symmetry
#         └── transformation
#
#     physics
#         │
#         ├── lensing
#         ├── position
#         └── field
#
#     biology
#         │
#         ├── network
#         ├── interaction
#         └── connectivity
#
#     language
#         │
#         ├── repetition
#         ├── density
#         └── sequence
#
#     music
#         │
#         ├── frequency
#         ├── amplitude
#         └── spectrum
#
#     architecture
#         │
#         ├── spatial relation
#         ├── geometry
#         └── topology
#
#                     ↓
#
#              RELATIONSHIP ENGINE
#                     ↓
#
#            COMMON STRUCTURAL SPACE
#                     ↓
#
#              UNIFIED FIELD
#                     ↓
#
#                ONE WORK
#
#
# The domains are therefore not required to remain visually separate.
#
# The engine can transform their underlying relationships into a shared
# computational representation.
#
#
# =============================================================================
# 40. STRUCTURAL INTELLIGENCE MODEL
# =============================================================================
#
# The engine's bounded intelligence can be summarized as:
#
#     PERCEIVE
#        ↓
#     REPRESENT
#        ↓
#     COMPARE
#        ↓
#     RELATE
#        ↓
#     HYPOTHESIZE
#        ↓
#     SCORE
#        ↓
#     SELECT
#        ↓
#     TRANSFORM
#        ↓
#     SYNTHESIZE
#        ↓
#     VALIDATE
#        ↓
#     REVISE / EXPORT
#
# This is computational reasoning over structured inputs.
#
# It is NOT a claim that the engine possesses subjective experience or general
# human intelligence.
#
#
# =============================================================================
# 41. ARTISTIC REPRESENTATION MODEL
# =============================================================================
#
# The engine deliberately separates:
#
#     SOURCE STRUCTURE
#             ↓
#     COMPUTATIONAL FIELD
#             ↓
#     ARTISTIC REPRESENTATION
#
# This allows a structure to become:
#
#     field
#     surface
#     curve
#     density
#     topology
#     geometry
#     layer
#     temporal state
#     spatial object
#
# rather than merely becoming a conventional chart.
#
#
# =============================================================================
# 42. DETERMINISM
# =============================================================================
#
# The engine uses:
#
#     source structure hashes
#     deterministic IDs
#     deterministic seeds
#     canonical serialization
#
# so that:
#
#     SAME INPUT
#        +
#     SAME ENGINE VERSION
#        +
#     SAME PARAMETERS
#        +
#     SAME SEED
#
# should produce the same structural result.
#
# This makes the artwork computationally inspectable and reproducible.
#
#
# =============================================================================
# 43. PROVENANCE
# =============================================================================
#
# Each major object can preserve:
#
#     source
#     source hash
#     operation
#     parameters
#     parent IDs
#     engine version
#     seed
#     transformation path
#
# This means the artwork can retain a computational lineage:
#
#     SOURCE
#       ↓
#     STRUCTURE
#       ↓
#     RELATION
#       ↓
#     FIELD
#       ↓
#     ARTIFACT
#
#
# =============================================================================
# 44. SECURITY MODEL
# =============================================================================
#
# The engine does NOT require arbitrary Python eval() for user expressions.
#
# SafeExpression provides a restricted expression grammar.
#
# Resource limits constrain:
#
#     node count
#     relation count
#     transform depth
#     field resolution
#     runtime budget
#
# The engine should still be sandboxed at the application/process level when
# accepting untrusted files.
#
#
# =============================================================================
# 45. EXTENSION MODEL
# =============================================================================
#
# New domains can be implemented as:
#
#     class NewDomain:
#
#         def analyze(...):
#             ...
#
#         def to_structure(...):
#             ...
#
# Then registered through:
#
#     engine.registry.register_domain(...)
#
# or by adding a domain adapter.
#
# This means the core engine does not need to know every possible domain.
#
#
# =============================================================================
# 46. FUTURE DEVELOPER EXTENSIONS
# =============================================================================
#
# The architecture intentionally leaves room for:
#
#     graph neural representations
#     learned embeddings
#     transformer-based semantic adapters
#     symbolic theorem systems
#     richer constraint solvers
#     probabilistic inference
#     evolutionary search
#     reinforcement learning
#     GPU field synthesis
#     Vulkan / CUDA / Metal backends
#     Rust rendering
#     C++ high-performance kernels
#     WGSL compute shaders
#     Blender geometry nodes
#     procedural mesh generation
#     volumetric fields
#     3D field synthesis
#     temporal / animation fields
#     interactive exploration
#     multimodal ingestion
#     experimental scientific datasets
#
# These are extension points, not claims that every one is already implemented
# by this file.
#
#
# =============================================================================
# 47. DEVELOPER-GRADE STATUS
# =============================================================================
#
# The architecture contains the fundamental components expected from a serious
# extensible computational framework:
#
#     typed data model
#     domain registry
#     adapters
#     deterministic IDs
#     canonical hashing
#     relationship discovery
#     structural analysis
#     hypothesis representation
#     decision representation
#     transformation engine
#     field synthesis
#     artistic projection
#     raster rendering
#     vector export
#     3D export
#     validation
#     provenance
#     resource limits
#     CLI
#     self-test
#     domain plugins
#
# "Developer-grade" here means the architecture is structured for development,
# inspection, extension, testing, and integration.
#
# It does NOT mean that every optional dependency, renderer, numerical model,
# GPU backend, or production deployment concern has been exhaustively certified.
#
#
# =============================================================================
# 48. CURRENT GRAVITATIONAL-LENSING CAPABILITY
# =============================================================================
#
# The astronomy module retains the original v1.14 concept:
#
#     observed Q2237+0305 astrometry
#                ↓
#          lens-centered coordinates
#                ↓
#              SIS model
#                ↓
#        optional external shear
#                ↓
#          source-plane residuals
#                ↓
#          numerical optimization
#                ↓
#             fit metrics
#
# It is now one domain among many.
#
# The lensing module should NOT be interpreted as evidence that META-ART has
# discovered new physics.
#
# It is a computational modeling / benchmark capability.
#
#
# =============================================================================
# 49. FINAL CONCEPT
# =============================================================================
#
# META-ART is therefore not defined by a particular visual style.
#
# It is defined by the computational relationship:
#
#     MANY DOMAINS
#          ↓
#     MANY STRUCTURES
#          ↓
#     MANY RELATIONSHIPS
#          ↓
#     ONE UNIFIED STRUCTURAL MODEL
#          ↓
#     ONE COMPUTATIONAL ARTIFACT
#
# The engine's central object is not merely the image.
#
# The central object is:
#
#                 STRUCTURE
#
# and the artwork is the rendered expression of that structure.
#
#
# =============================================================================
# END META-ART ENGINE
# =============================================================================
