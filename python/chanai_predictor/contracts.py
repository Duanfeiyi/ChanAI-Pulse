"""Typed contracts shared by Step 10 training and inference."""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import numpy as np


PREDICTOR_DATA_SCHEMA_VERSION = "v3.0-predictor-data-hdf5.1"
MODEL_MANIFEST_SCHEMA_VERSION = "v3.0-predictor-model-manifest.1"
REGISTRY_SCHEMA_VERSION = "v3.0-predictor-model-registry.1"
REGISTRY_V2_SCHEMA_VERSION = "v3.1-predictor-model-registry.2"
PREDICTION_SCHEMA_VERSION = "v3.0-predicted-channel-parameters.1"
PREDICTION_REQUEST_SCHEMA_VERSION = "v3.0-predictor-request.1"
ADAPTATION_SCHEMA_VERSION = "v3.0-predictor-adaptation-result.1"

SUPPORTED_TASKS = ("interpolation", "extrapolation")
SUPPORTED_NEURAL_MODELS = ("gru", "lstm", "tcn")
SUPPORTED_RESEARCH_NEURAL_MODELS = ("dlinear", "nlinear")
SUPPORTED_TRAINABLE_MODELS = SUPPORTED_NEURAL_MODELS + SUPPORTED_RESEARCH_NEURAL_MODELS
SUPPORTED_BASELINES = ("persistence", "linear", "ar", "kalman")
SUPPORTED_MODELS = SUPPORTED_BASELINES + SUPPORTED_TRAINABLE_MODELS
SUPPORTED_SELECTION_MODES = ("auto", "manual")
SUPPORTED_ADAPTATION_MODES = ("off", "auto", "force")


@dataclass(frozen=True)
class PredictorData:
    """In-memory view of a Step 9 portable predictor-data file."""

    path: Path
    task_type: str
    context_layout: str
    parameter_names: tuple[str, ...]
    parameter_units: tuple[str, ...]
    parameter_bounds: np.ndarray
    inputs: np.ndarray
    targets: np.ndarray
    target_parameter_sample_index: np.ndarray
    partition_codes: np.ndarray
    example_group_ids: tuple[str, ...]
    normalization_mean: np.ndarray
    normalization_std: np.ndarray
    metadata: dict[str, Any]

    def validate(self) -> None:
        if self.task_type not in SUPPORTED_TASKS:
            raise ValueError(f"Unsupported task_type: {self.task_type}")
        if self.inputs.ndim != 3 or self.targets.ndim != 3:
            raise ValueError("Predictor tensors must both be three-dimensional.")
        if self.inputs.shape[0] != self.targets.shape[0]:
            raise ValueError("Input and target example counts must match.")
        if self.inputs.shape[2] != len(self.parameter_names):
            raise ValueError("Input parameter axis does not match parameter_names.")
        if self.targets.shape[2] != len(self.parameter_names):
            raise ValueError("Target parameter axis does not match parameter_names.")
        if self.parameter_bounds.shape != (len(self.parameter_names), 2):
            raise ValueError("Parameter bounds must have shape [P,2].")
        if self.partition_codes.shape[0] != self.inputs.shape[0]:
            raise ValueError("Partition-code count does not match examples.")
        if len(self.example_group_ids) != self.inputs.shape[0]:
            raise ValueError("Example-group count does not match examples.")
        if self.normalization_mean.shape != (len(self.parameter_names),):
            raise ValueError("Normalization mean must have one value per parameter.")
        if self.normalization_std.shape != (len(self.parameter_names),):
            raise ValueError(
                "Normalization standard deviation must have one value per parameter."
            )
        if np.any(~np.isfinite(self.inputs)) or np.any(~np.isfinite(self.targets)):
            raise ValueError("Predictor tensors contain non-finite values.")
        if np.any(self.normalization_std <= 0):
            raise ValueError("Normalization standard deviations must be positive.")

    @property
    def context_length(self) -> int:
        return int(self.inputs.shape[1])

    @property
    def target_length(self) -> int:
        return int(self.targets.shape[1])

    @property
    def parameter_count(self) -> int:
        return int(self.inputs.shape[2])

    def partition_indices(self, name: str) -> np.ndarray:
        code_by_name = {"train": 1, "validation": 2, "test": 3, "all": 0}
        if name not in code_by_name:
            raise ValueError(f"Unsupported partition: {name}")
        code = code_by_name[name]
        if code == 0:
            return np.arange(self.inputs.shape[0], dtype=np.int64)
        return np.flatnonzero(self.partition_codes == code)

    def denormalize(self, values: np.ndarray, project_bounds: bool = True) -> np.ndarray:
        values = np.asarray(values, dtype=np.float64)
        restored = values * self.normalization_std.reshape(1, 1, -1)
        restored = restored + self.normalization_mean.reshape(1, 1, -1)
        if project_bounds:
            lower = self.parameter_bounds[:, 0].reshape(1, 1, -1)
            upper = self.parameter_bounds[:, 1].reshape(1, 1, -1)
            restored = np.maximum(restored, lower)
            restored = np.minimum(restored, upper)
        return restored


@dataclass(frozen=True)
class PredictionRequest:
    """Target-free product request containing only known parameters."""

    path: Path
    task_type: str
    context_layout: str
    parameter_names: tuple[str, ...]
    parameter_units: tuple[str, ...]
    input_parameters: np.ndarray
    input_parameter_sample_index: np.ndarray
    target_parameter_sample_index: np.ndarray
    example_group_ids: tuple[str, ...]

    def validate(self) -> None:
        if self.task_type not in SUPPORTED_TASKS:
            raise ValueError(f"Unsupported task_type: {self.task_type}")
        if self.input_parameters.ndim != 3:
            raise ValueError("input_parameters must have shape [N,context,P].")
        examples, context, parameters = self.input_parameters.shape
        if context != 16:
            raise ValueError("Step 10 reference models require context length 16.")
        if parameters != len(self.parameter_names):
            raise ValueError("Request parameter axis does not match names.")
        if self.input_parameter_sample_index.shape != (examples, context):
            raise ValueError("Input sample-index shape does not match input parameters.")
        if self.target_parameter_sample_index.shape != (examples, 4):
            raise ValueError("Step 10 target sample indices must have shape [N,4].")
        if len(self.example_group_ids) != examples:
            raise ValueError("Request example-group count does not match examples.")
        if np.any(~np.isfinite(self.input_parameters)):
            raise ValueError("Prediction request contains non-finite known values.")

    @property
    def context_length(self) -> int:
        return int(self.input_parameters.shape[1])

    @property
    def target_length(self) -> int:
        return int(self.target_parameter_sample_index.shape[1])

    @property
    def parameter_count(self) -> int:
        return int(self.input_parameters.shape[2])


@dataclass(frozen=True)
class TrainingConfig:
    """Small reproducible training configuration for one model run."""

    model_type: str
    seed: int = 20260730
    hidden_size: int = 32
    num_layers: int = 1
    kernel_size: int = 3
    tcn_channels: int = 32
    dropout: float = 0.0
    learning_rate: float = 1e-3
    weight_decay: float = 0.0
    batch_size: int = 16
    max_epochs: int = 80
    patience: int = 12
    min_delta: float = 1e-6
    device: str = "auto"
    deterministic: bool = True
    loss_weights: tuple[float, ...] = field(default_factory=tuple)

    def validate(self) -> None:
        if self.model_type not in SUPPORTED_TRAINABLE_MODELS:
            raise ValueError(f"Unsupported trainable model: {self.model_type}")
        if self.hidden_size < 1 or self.num_layers < 1:
            raise ValueError("RNN sizes must be positive.")
        if self.kernel_size < 2 or self.tcn_channels < 1:
            raise ValueError("TCN sizes are invalid.")
        if not 0 <= self.dropout < 1:
            raise ValueError("dropout must be in [0,1).")
        if self.learning_rate <= 0 or self.batch_size < 1:
            raise ValueError("Training rate and batch size must be positive.")
        if self.max_epochs < 1 or self.patience < 1:
            raise ValueError("Epoch and patience values must be positive.")
        if self.loss_weights and any(weight <= 0 for weight in self.loss_weights):
            raise ValueError("All parameter loss weights must be positive.")

    def to_dict(self) -> dict[str, Any]:
        return {
            "model_type": self.model_type,
            "seed": self.seed,
            "hidden_size": self.hidden_size,
            "num_layers": self.num_layers,
            "kernel_size": self.kernel_size,
            "tcn_channels": self.tcn_channels,
            "dropout": self.dropout,
            "learning_rate": self.learning_rate,
            "weight_decay": self.weight_decay,
            "batch_size": self.batch_size,
            "max_epochs": self.max_epochs,
            "patience": self.patience,
            "min_delta": self.min_delta,
            "device": self.device,
            "deterministic": self.deterministic,
            "loss_weights": list(self.loss_weights),
        }


@dataclass(frozen=True)
class AdaptationPolicy:
    """Rules for leakage-safe last-head adaptation."""

    mode: str = "off"
    min_adaptation_examples: int = 12
    min_validation_examples: int = 4
    min_relative_improvement: float = 0.01
    max_epochs: int = 20
    patience: int = 5
    learning_rate: float = 5e-4
    max_seconds: float = 30.0
    seed: int = 20260730
    actual_target_sample_index: tuple[float, ...] = field(default_factory=tuple)
    actual_target_group_id: tuple[str, ...] = field(default_factory=tuple)

    def validate(self) -> None:
        if self.mode not in SUPPORTED_ADAPTATION_MODES:
            raise ValueError(f"Unsupported adaptation mode: {self.mode}")
        if self.min_adaptation_examples < 1 or self.min_validation_examples < 1:
            raise ValueError("Adaptation example thresholds must be positive.")
        if self.min_relative_improvement < 0:
            raise ValueError("Minimum improvement cannot be negative.")
        if self.max_epochs < 1 or self.patience < 1 or self.max_seconds <= 0:
            raise ValueError("Adaptation stop limits must be positive.")
        if len(self.actual_target_group_id) != len(
            self.actual_target_sample_index
        ):
            raise ValueError("Actual target groups and sample indices must align.")
