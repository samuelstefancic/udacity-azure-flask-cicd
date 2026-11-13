from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from flask import Flask, jsonify, request
from sklearn.preprocessing import StandardScaler

ROOT = Path(__file__).resolve().parent
FEATURES = ["CHAS", "RM", "TAX", "PTRATIO", "B", "LSTAT"]
MODEL = joblib.load(ROOT / "Housing_price_model" / "LinearRegression.joblib")
revision_file = ROOT / "revision.txt"
REVISION = revision_file.read_text(encoding="utf-8").strip() if revision_file.is_file() else "local"
app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 64 * 1024
app.logger.setLevel("INFO")


@app.get("/")
def home():
    return "<h3>Sklearn Prediction Home</h3>"


@app.post("/predict")
def predict():
    payload = request.get_json(silent=True)
    if not isinstance(payload, dict) or set(payload) != set(FEATURES):
        return jsonify(error=f"Expected JSON columns: {', '.join(FEATURES)}"), 400

    if any(not isinstance(payload[column], dict) for column in FEATURES):
        return jsonify(error="Each column must map row IDs to numbers."), 400

    row_ids = set(payload[FEATURES[0]])
    if not row_ids or any(set(payload[column]) != row_ids for column in FEATURES):
        return jsonify(error="Columns must contain the same non-empty set of row IDs."), 400

    try:
        frame = pd.DataFrame(payload, columns=FEATURES).astype(float)
    except (TypeError, ValueError, OverflowError):
        return jsonify(error="Features must contain finite numeric values."), 400

    if not np.isfinite(frame.to_numpy()).all():
        return jsonify(error="Features must contain finite numeric values."), 400

    scaled = StandardScaler().fit_transform(frame)
    predictions = MODEL.predict(scaled).tolist()
    app.logger.info("Prediction completed revision=%s rows=%d", REVISION, len(predictions))
    response = jsonify(prediction=predictions)
    response.headers["X-Revision"] = REVISION
    return response
