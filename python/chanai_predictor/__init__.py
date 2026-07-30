"""ChanAI Pulse v3 parameter-prediction package."""

from .contracts import (
    AdaptationPolicy,
    PredictionRequest,
    PredictorData,
    TrainingConfig,
)
from .data import load_predictor_data_hdf5
from .models import linear_predict, persistence_predict
from .registry import train_model_family
from .request import load_prediction_request, write_request_from_dataset
from .service import (
    predict_from_files,
    predict_request_from_files,
    run_prediction,
    run_prediction_request,
)

__all__ = [
    "AdaptationPolicy",
    "PredictionRequest",
    "PredictorData",
    "TrainingConfig",
    "linear_predict",
    "load_predictor_data_hdf5",
    "load_prediction_request",
    "persistence_predict",
    "predict_from_files",
    "predict_request_from_files",
    "run_prediction",
    "run_prediction_request",
    "train_model_family",
    "write_request_from_dataset",
]
