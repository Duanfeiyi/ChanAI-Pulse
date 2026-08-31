"""v3.2-4a experimental online-fit neural forecast for three-axis tasks.

For the time/space axes the prediction is DS/KF sequence extrapolation; for
the frequency axis it is [Re, Im] sequence recovery along the frequency
axis. All share the same structure: known index/value sequence -> target
index forecast. The neural models (gru/lstm/tcn/dlinear/nlinear) are fitted
online on the known sequence (no pretrained checkpoint exists for axis
sequences) and rolled forward, mirroring v3.1's experimental-model posture.

Input/output is plain JSON exchanged with MATLAB:
  input:  {"model","known_values":[[...]],"known_index":[...],
           "target_index":[...],"lookback","epochs","seed","side"}
  output: {"prediction":[[...]],"schema_version",...}

"side" is "left" (known before targets) or "right" (known after targets);
MATLAB combines both sides with distance weighting, exactly like the
classical family (v32_axis_manual_forecast).

This is experimental research plumbing; results are deterministic per seed
and never read target truth.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
import torch
from torch import nn

MODELS = ("gru", "lstm", "tcn", "dlinear", "nlinear")
LOOKBACK_DEFAULT = 8
EPOCHS_DEFAULT = 200
SEED_DEFAULT = 7


class SequenceHead(nn.Module):
    """Shared decoder for recurrent models."""

    def __init__(self, hidden: int, lookback: int, features: int) -> None:
        super().__init__()
        self.net = None  # set by subclass
        self.head = nn.Linear(hidden, features)
        self.lookback = lookback
        self.features = features

    def forward(self, x: torch.Tensor) -> torch.Tensor:  # [B, lookback, P]
        out = self.net(x)
        if isinstance(out, tuple):          # GRU/LSTM -> (output, state)
            out = out[0]
        if out.dim() == 3:
            out = out[:, -1, :]             # last time step
        return self.head(out)


class GRUFit(SequenceHead):
    def __init__(self, lookback: int, features: int, hidden: int = 32) -> None:
        super().__init__(hidden, lookback, features)
        self.net = nn.GRU(features, hidden, batch_first=True)


class LSTMFit(SequenceHead):
    def __init__(self, lookback: int, features: int, hidden: int = 32) -> None:
        super().__init__(hidden, lookback, features)
        self.net = nn.LSTM(features, hidden, batch_first=True)


class TCNFit(nn.Module):
    """Small dilated-convolution temporal stack (causal)."""

    def __init__(self, lookback: int, features: int, channels: int = 16) -> None:
        super().__init__()
        layers = []
        in_channels = features
        for dilation in (1, 2, 4):
            layers.append(
                nn.Conv1d(in_channels, channels, 3, padding=dilation, dilation=dilation)
            )
            layers.append(nn.ReLU())
            in_channels = channels
        self.stack = nn.Sequential(*layers)
        self.head = nn.Linear(channels, features)
        self.lookback = lookback

    def forward(self, x: torch.Tensor) -> torch.Tensor:  # [B, L, P]
        out = self.stack(x.transpose(1, 2))  # [B, C, L]
        return self.head(out.mean(dim=2))


class DLinearFit(nn.Module):
    """Decomposition linear: mean trend held flat + residual linear forecast."""

    def __init__(self, lookback: int, features: int) -> None:
        super().__init__()
        self.linear = nn.Linear(lookback, 1)

    def forward(self, x: torch.Tensor) -> torch.Tensor:  # [B, L, P]
        trend = x.mean(dim=1, keepdim=True)               # [B, 1, P]
        residual = x - trend                              # [B, L, P]
        trend_out = trend.squeeze(1)                      # [B, P]
        residual_out = self.linear(
            residual.transpose(1, 2)
        ).squeeze(2)                                      # [B, P]
        return trend_out + residual_out


class NLinearFit(nn.Module):
    """Normalized linear forecast."""

    def __init__(self, lookback: int, features: int) -> None:
        super().__init__()
        self.linear = nn.Linear(lookback, 1)

    def forward(self, x: torch.Tensor) -> torch.Tensor:  # [B, L, P]
        last = x[:, -1:, :]
        normalized = x - last
        return self.linear(normalized.transpose(1, 2)).squeeze(2) + last.squeeze(1)


def build_model(name: str, lookback: int, features: int) -> nn.Module:
    if name == "gru":
        return GRUFit(lookback, features)
    if name == "lstm":
        return LSTMFit(lookback, features)
    if name == "tcn":
        return TCNFit(lookback, features)
    if name == "dlinear":
        return DLinearFit(lookback, features)
    if name == "nlinear":
        return NLinearFit(lookback, features)
    raise ValueError(f"unsupported model {name}")


def sliding_samples(
    values: np.ndarray, lookback: int
) -> tuple[np.ndarray, np.ndarray]:
    """[K, P] -> (x [B, L, P], y [B, P])."""
    count = len(values)
    if count <= lookback:
        return None, None
    x = np.stack([values[i : i + lookback] for i in range(count - lookback)])
    y = values[lookback:]
    return x, y


def fit_and_forecast(
    model_name: str,
    known_values: np.ndarray,
    target_count: int,
    lookback: int = LOOKBACK_DEFAULT,
    epochs: int = EPOCHS_DEFAULT,
    seed: int = SEED_DEFAULT,
) -> np.ndarray:
    """One-sided forecast from KNOWN_VALUES (ordered nearest-first handled by
    the caller) to TARGET_COUNT points."""
    torch.manual_seed(seed)
    np.random.seed(seed)
    values = np.asarray(known_values, dtype=np.float64)
    features = values.shape[1]
    lookback = min(lookback, max(1, len(values) - 1))
    model = build_model(model_name, lookback, features)
    optimizer = torch.optim.Adam(model.parameters(), lr=1e-2)
    criterion = nn.MSELoss()
    if len(values) > lookback:
        x, y = sliding_samples(values, lookback)
        x_t = torch.from_numpy(x).float()
        y_t = torch.from_numpy(y).float()
        for _ in range(epochs):
            optimizer.zero_grad()
            loss = criterion(model(x_t), y_t)
            loss.backward()
            optimizer.step()
    model.eval()
    with torch.no_grad():
        rolling = torch.from_numpy(values).float()  # [K, P]
        predictions = np.zeros((target_count, features), dtype=np.float64)
        for step in range(target_count):
            window = rolling[-lookback:].unsqueeze(0)  # [1, L, P]
            next_value = model(window).squeeze(0).numpy()
            predictions[step] = next_value
            rolling = torch.cat(
                (rolling, torch.from_numpy(next_value).unsqueeze(0)), dim=0
            )
    return predictions


def one_sided(
    model_name: str,
    values: np.ndarray,
    known_indices: np.ndarray,
    target_indices: np.ndarray,
    side: str,
    lookback: int,
    epochs: int,
    seed: int,
) -> np.ndarray:
    """Port of v32_axis_manual_forecast.one_sided ordering semantics."""
    indices = np.asarray(known_indices, dtype=np.float64)
    targets = np.asarray(target_indices, dtype=np.float64)
    if side == "left":
        order = np.arange(len(indices))
        history = values[order]
    else:
        order = np.arange(len(indices) - 1, -1, -1)
        history = values[order]
    return fit_and_forecast(model_name, history, len(targets), lookback, epochs, seed)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    payload = json.loads(Path(args.input).read_text(encoding="utf-8"))
    model_name = str(payload["model"])
    if model_name not in MODELS:
        raise ValueError(f"unsupported model {model_name}")
    known_values = np.asarray(payload["known_values"], dtype=np.float64)
    known_index = np.asarray(payload["known_index"], dtype=np.float64)
    target_index = np.asarray(payload["target_index"], dtype=np.float64)
    side = str(payload.get("side", "left"))
    lookback = int(payload.get("lookback", LOOKBACK_DEFAULT))
    epochs = int(payload.get("epochs", EPOCHS_DEFAULT))
    seed = int(payload.get("seed", SEED_DEFAULT))
    prediction = one_sided(
        model_name, known_values, known_index, target_index, side,
        lookback, epochs, seed,
    )
    report = {
        "schema_version": "v3.2-4a-axis-neural-forecast.1",
        "model": model_name,
        "side": side,
        "prediction": prediction.tolist(),
        "experimental_online_fit": True,
    }
    Path(args.output).write_text(
        json.dumps(report, ensure_ascii=False), encoding="utf-8"
    )
    print(f"forecast {model_name} side={side} -> {prediction.shape}")


if __name__ == "__main__":
    main()
