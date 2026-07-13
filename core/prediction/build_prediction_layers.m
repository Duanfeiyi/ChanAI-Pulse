function layers = build_prediction_layers(algorithm, featureCount)
%BUILD_PREDICTION_LAYERS Return the App's existing TCN, GRU, or LSTM model.
%   This helper intentionally preserves the layer sizes and ordering from
%   ChannelSimulatorApp so the refactor does not introduce a new model.

arguments
    algorithm {mustBeTextScalar}
    featureCount (1, 1) double {mustBeInteger, mustBePositive}
end

algorithm = upper(string(algorithm));
switch algorithm
    case "TCN"
        numFilters = 64;
        filterSize = 3;
        layers = [ ...
            sequenceInputLayer(featureCount, "Name", "in")
            convolution1dLayer(filterSize, numFilters, "Padding", "causal", "DilationFactor", 1, "Name", "conv1")
            batchNormalizationLayer("Name", "bn1")
            reluLayer("Name", "relu1")
            convolution1dLayer(filterSize, numFilters, "Padding", "causal", "DilationFactor", 2, "Name", "conv2")
            batchNormalizationLayer("Name", "bn2")
            reluLayer("Name", "relu2")
            convolution1dLayer(filterSize, numFilters, "Padding", "causal", "DilationFactor", 4, "Name", "conv3")
            batchNormalizationLayer("Name", "bn3")
            reluLayer("Name", "relu3")
            globalAveragePooling1dLayer("Name", "gap_reducer")
            fullyConnectedLayer(featureCount, "Name", "fc")
            regressionLayer("Name", "out")];
    case "GRU"
        layers = [ ...
            sequenceInputLayer(featureCount, "Name", "in")
            gruLayer(256, "OutputMode", "sequence", "Name", "gru1")
            dropoutLayer(0.2, "Name", "drop1")
            gruLayer(256, "OutputMode", "last", "Name", "gru2")
            dropoutLayer(0.2, "Name", "drop2")
            fullyConnectedLayer(featureCount, "Name", "fc")
            regressionLayer("Name", "out")];
    case "LSTM"
        layers = [ ...
            sequenceInputLayer(featureCount, "Name", "in")
            lstmLayer(256, "OutputMode", "sequence", "Name", "lstm1")
            dropoutLayer(0.2, "Name", "drop1")
            lstmLayer(256, "OutputMode", "last", "Name", "lstm2")
            dropoutLayer(0.2, "Name", "drop2")
            fullyConnectedLayer(featureCount, "Name", "fc")
            regressionLayer("Name", "out")];
    otherwise
        error("build_prediction_layers:UnsupportedAlgorithm", ...
            "Unsupported prediction algorithm: %s", algorithm);
end
end
