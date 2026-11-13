import argparse
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parent
APP_FILES = (
    "app.py",
    "requirements.txt",
    "Housing_price_model/LinearRegression.joblib",
)


def package(destination, revision):
    destination.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(destination, "w", compression=ZIP_DEFLATED) as archive:
        for relative_path in APP_FILES:
            archive.write(ROOT / relative_path, relative_path)
        archive.writestr("revision.txt", f"{revision}\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("zip_path", type=Path)
    parser.add_argument("revision")
    arguments = parser.parse_args()
    package(arguments.zip_path, arguments.revision)
