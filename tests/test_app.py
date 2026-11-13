import json
from pathlib import Path

import pytest

from app import REVISION, app


@pytest.fixture(name="example")
def sample_payload():
    sample = Path(__file__).resolve().parents[1] / "sample-prediction.json"
    return json.loads(sample.read_text(encoding="utf-8"))


def test_home():
    response = app.test_client().get("/")
    assert response.status_code == 200


def test_predict_with_reference_payload(example):
    response = app.test_client().post("/predict", json=example)
    assert response.status_code == 200
    assert response.json["prediction"] == pytest.approx([2.431574790057212])
    assert response.headers["X-Revision"] == REVISION


def test_predict_keeps_feature_order(example):
    for name, column in example.items():
        column["1"] = column["0"] - 1 if name in {"RM", "B"} else column["0"] + 1
    first = app.test_client().post("/predict", json=example)
    reverse_json = json.dumps(dict(reversed(list(example.items()))))
    second = app.test_client().post("/predict", data=reverse_json, content_type="application/json")
    assert first.status_code == second.status_code == 200
    assert len(first.json["prediction"]) == 2
    assert first.json["prediction"] == second.json["prediction"]


@pytest.mark.parametrize("mode", ["missing", "text", "infinite", "row", "shape", "empty"])
def test_bad_payload_returns_400(example, mode):
    if mode == "missing":
        del example["RM"]
    elif mode == "text":
        example["RM"]["0"] = "invalid"
    elif mode == "infinite":
        example["RM"]["0"] = "inf"
    elif mode == "row":
        example["RM"] = {"1": 1}
    elif mode == "shape":
        example["RM"] = [1]
    else:
        example = {column: {} for column in example}
    response = app.test_client().post("/predict", json=example)
    assert response.status_code == 400
    assert "error" in response.json
