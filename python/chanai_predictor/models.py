"""Small, auditable multihorizon predictors for Step 10."""

from __future__ import annotations

from dataclasses import asdict
from typing import Any

import numpy as np
import torch
from torch import nn
from torch.nn import functional as F

from .contracts import PredictorData, TrainingConfig


def persistence_predict(data: PredictorData, inputs: np.ndarray) -> np.ndarray:
    """Last-value extrapolation and two-sided constant interpolation baseline."""
    inputs = np.asarray(inputs, dtype=np.float32)
    if data.task_type == "extrapolation":
        anchor = inputs[:, -1:, :]
    else:
        left_length = inputs.shape[1] // 2
        left = inputs[:, left_length - 1 : left_length, :]
        right = inputs[:, left_length : left_length + 1, :]
        anchor = (left + right) / 2.0
    return np.repeat(anchor, data.target_length, axis=1)


def linear_predict(data: PredictorData, inputs: np.ndarray) -> np.ndarray:
    """Independent least-squares trend baseline using known sample coordinates."""
    inputs = np.asarray(inputs, dtype=np.float64)
    batch, context, parameters = inputs.shape
    outputs = np.empty((batch, data.target_length, parameters), dtype=np.float64)
    if data.task_type == "extrapolation":
        known_x = np.arange(context, dtype=np.float64)
        target_x = context + np.arange(data.target_length, dtype=np.float64)
    else:
        left = context // 2
        known_x = np.concatenate(
            (
                np.arange(left, dtype=np.float64),
                left
                + data.target_length
                + np.arange(context - left, dtype=np.float64),
            )
        )
        target_x = left + np.arange(data.target_length, dtype=np.float64)
    design = np.column_stack((known_x, np.ones_like(known_x)))
    target_design = np.column_stack((target_x, np.ones_like(target_x)))
    for sample in range(batch):
        coefficients, *_ = np.linalg.lstsq(design, inputs[sample], rcond=None)
        outputs[sample] = target_design @ coefficients
    return outputs.astype(np.float32)


class CausalConv1d(nn.Module):
    def __init__(self, in_channels: int, out_channels: int, kernel: int, dilation: int):
        super().__init__()
        self.left_padding = (kernel - 1) * dilation
        self.conv = nn.Conv1d(
            in_channels,
            out_channels,
            kernel_size=kernel,
            dilation=dilation,
        )

    def forward(self, values: torch.Tensor) -> torch.Tensor:
        return self.conv(F.pad(values, (self.left_padding, 0)))


class ResidualTCNBlock(nn.Module):
    def __init__(self, in_channels: int, out_channels: int, kernel: int, dilation: int):
        super().__init__()
        self.conv1 = CausalConv1d(in_channels, out_channels, kernel, dilation)
        self.conv2 = CausalConv1d(out_channels, out_channels, kernel, dilation)
        self.activation = nn.ReLU()
        self.projection = (
            nn.Identity()
            if in_channels == out_channels
            else nn.Conv1d(in_channels, out_channels, kernel_size=1)
        )

    def forward(self, values: torch.Tensor) -> torch.Tensor:
        residual = self.projection(values)
        values = self.activation(self.conv1(values))
        values = self.conv2(values)
        return self.activation(values + residual)


class TCNEncoder(nn.Module):
    def __init__(self, parameter_count: int, channels: int, kernel_size: int):
        super().__init__()
        self.network = nn.Sequential(
            ResidualTCNBlock(parameter_count, channels, kernel_size, 1),
            ResidualTCNBlock(channels, channels, kernel_size, 2),
            ResidualTCNBlock(channels, channels, kernel_size, 4),
        )

    def forward(self, values: torch.Tensor) -> torch.Tensor:
        encoded = self.network(values.transpose(1, 2))
        return encoded[:, :, -1]


class SequenceRegressor(nn.Module):
    """GRU/LSTM/TCN with a two-sided encoder for interpolation."""

    def __init__(
        self,
        model_type: str,
        task_type: str,
        parameter_count: int,
        context_length: int,
        target_length: int,
        config: TrainingConfig,
    ):
        super().__init__()
        self.model_type = model_type
        self.task_type = task_type
        self.parameter_count = parameter_count
        self.context_length = context_length
        self.target_length = target_length
        self.config = config
        if model_type in ("gru", "lstm"):
            layer = nn.GRU if model_type == "gru" else nn.LSTM
            self.encoder = layer(
                input_size=parameter_count,
                hidden_size=config.hidden_size,
                num_layers=config.num_layers,
                dropout=config.dropout if config.num_layers > 1 else 0.0,
                batch_first=True,
            )
            encoded_size = config.hidden_size
        elif model_type == "tcn":
            self.encoder = TCNEncoder(
                parameter_count, config.tcn_channels, config.kernel_size
            )
            encoded_size = config.tcn_channels
        else:
            raise ValueError(f"Unsupported model type: {model_type}")
        if task_type == "interpolation":
            encoded_size *= 2
        self.head = nn.Linear(encoded_size, target_length * parameter_count)

    def _encode(self, values: torch.Tensor) -> torch.Tensor:
        if self.model_type == "tcn":
            return self.encoder(values)
        _, hidden = self.encoder(values)
        if self.model_type == "lstm":
            hidden = hidden[0]
        return hidden[-1]

    def forward(self, values: torch.Tensor) -> torch.Tensor:
        if self.task_type == "interpolation":
            left_length = self.context_length // 2
            left = values[:, :left_length, :]
            right = torch.flip(values[:, left_length:, :], dims=(1,))
            encoded = torch.cat((self._encode(left), self._encode(right)), dim=1)
        else:
            encoded = self._encode(values)
        output = self.head(encoded)
        return output.reshape(
            values.shape[0], self.target_length, self.parameter_count
        )

    def architecture_dict(self) -> dict[str, Any]:
        return {
            "model_type": self.model_type,
            "task_type": self.task_type,
            "parameter_count": self.parameter_count,
            "context_length": self.context_length,
            "target_length": self.target_length,
            "training_config": asdict(self.config),
            "parameter_count_total": sum(
                parameter.numel() for parameter in self.parameters()
            ),
            "interpolation_encoder": (
                "shared_two_sided"
                if self.task_type == "interpolation"
                else "not_applicable"
            ),
            "causal_extrapolation": self.task_type == "extrapolation",
        }


def build_model(data: PredictorData, config: TrainingConfig) -> SequenceRegressor:
    config.validate()
    return SequenceRegressor(
        config.model_type,
        data.task_type,
        data.parameter_count,
        data.context_length,
        data.target_length,
        config,
    )


def build_model_from_manifest(manifest: dict[str, Any]) -> SequenceRegressor:
    training = TrainingConfig(**manifest["architecture"]["training_config"])
    architecture = manifest["architecture"]
    return SequenceRegressor(
        architecture["model_type"],
        architecture["task_type"],
        int(architecture["parameter_count"]),
        int(architecture["context_length"]),
        int(architecture["target_length"]),
        training,
    )
